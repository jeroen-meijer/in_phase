import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:in_phase/src/crawl/crawl.dart';
import 'package:in_phase/src/database/database.exports.dart';
import 'package:in_phase/src/entities/entities.dart';
import 'package:in_phase/src/logger/logger.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:in_phase/src/reports/reports.dart';
import 'package:in_phase/src/spotify/spotify.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as path;
import 'package:spotify/spotify.dart';

class CrawlCommand extends Command<int> {
  CrawlCommand() {
    argParser
      ..addOption(
        'config',
        abbr: 'c',
        help: 'Path to crawl config file.',
        valueHelp: 'path',
      )
      ..addFlag(
        'dry-run',
        help: "Don't create playlists, just show what would be done.",
        negatable: false,
      )
      ..addMultiOption(
        'job',
        abbr: 'j',
        help: 'Run specific job(s) by name. If not specified, runs all jobs.',
        valueHelp: 'name',
      )
      ..addOption(
        'start-date',
        help:
            'Custom start date (YYYY-MM-DD). '
            'Overrides the job added_between_days setting.',
        valueHelp: 'YYYY-MM-DD',
      )
      ..addOption(
        'end-date',
        help: 'Custom end date (YYYY-MM-DD). Defaults to today.',
        valueHelp: 'YYYY-MM-DD',
      );
  }

  @override
  final String name = 'crawl';

  @override
  final String description =
      'Crawls Spotify for new tracks from configured sources '
      'and creates/updates playlists. '
      '`output_playlist.id` in config accepts ID, URI, URL, or fuzzy name. '
      'To save tracks to Liked Songs, use `in_phase convert --add '
      '$likedSongsPlaylistTarget`.';

  @override
  Future<int> run() async {
    final teardown = <Future<void> Function()>[];
    final commandStartTime = DateTime.now();
    final jobReports = <CrawlJobReport>[];

    try {
      // Load configuration
      final customConfigPath = argResults!['config'] as String?;
      final usesCustomConfigPath = customConfigPath != null;

      final configFile = usesCustomConfigPath
          ? resolveConfigPath(customConfigPath)
          : Constants.crawlConfigFile;

      log.info('Loading crawl config from: ${configFile.path}');
      final config = await CrawlConfig.fromFile(
        configFile,
        createFileIfNotExists: !usesCustomConfigPath,
      );

      if (config.jobs.isEmpty) {
        log.warning('No jobs found in configuration');
        return ExitCode.config.code;
      }

      // Validate all job filters before processing
      for (final job in config.jobs) {
        try {
          DateRangeResolver.validate(job.filters);
        } catch (e) {
          log.error(
            'Invalid date_range configuration in job "${job.name}": $e',
          );
          return ExitCode.config.code;
        }
      }

      // Login to Spotify
      final api = await spotifyLogin();

      // TODO(jeroen-meijer): Create issue for this lint ignore and refactor
      // ignore: invalid_use_of_visible_for_testing_member
      teardown.add(() async => (await api.client).close());

      // Initialize request pool
      final requestPool = Zonable.fromZone<RequestPool>();
      teardown.add(() async => requestPool.clear());

      // Get current user
      final user = await api.me.get();
      log.info('Logged in as: ${user.displayName}');

      // Filter jobs if specific ones were requested
      final requestedJobs = argResults!['job'] as List<String>;
      var jobsToRun = config.jobs;
      if (requestedJobs.isNotEmpty) {
        jobsToRun = config.jobs
            .where((job) => requestedJobs.contains(job.name))
            .toList();

        if (jobsToRun.isEmpty) {
          usageException(
            'No matching jobs found for: ${requestedJobs.join(', ')}',
          );
        }
      }

      log
        ..info('Found ${jobsToRun.length} job(s) to process')
        ..info('');

      // Parse custom dates if provided
      DateTime? customStartDate;
      DateTime? customEndDate;

      final startDateStr = argResults!['start-date'] as String?;
      final endDateStr = argResults!['end-date'] as String?;

      if (startDateStr != null) {
        try {
          customStartDate = DateTime.parse(startDateStr);
          log.info('Using custom start date: ${formatDate(customStartDate)}');
        } catch (e) {
          usageException(
            'Invalid start date format: $startDateStr. Expected YYYY-MM-DD',
          );
        }
      }

      if (endDateStr != null) {
        try {
          customEndDate = DateTime.parse(endDateStr);
          log.info('Using custom end date: ${formatDate(customEndDate)}');
        } catch (e) {
          usageException(
            'Invalid end date format: $endDateStr. Expected YYYY-MM-DD',
          );
        }
      }

      if (customStartDate != null && customEndDate != null) {
        if (customStartDate.isAfter(customEndDate)) {
          usageException(
            'Start date must be before or equal to end date',
          );
        }
      }

      // Check if dry run
      final isDryRun = argResults!['dry-run'] as bool;
      if (isDryRun) {
        log
          ..info('🔍 DRY RUN MODE - No playlists will be created')
          ..info('');
      }

      // Process each job
      for (final (index, job) in jobsToRun.indexed) {
        log.info(
          '🔄 Processing job ${index + 1}/${jobsToRun.length}: ${job.name}',
        );

        final jobReport = await _processJob(
          api: api,
          user: user,
          job: job,
          requestPool: requestPool,
          isDryRun: isDryRun,
          configFile: configFile,
          customStartDate: customStartDate,
          customEndDate: customEndDate,
        );

        if (jobReport != null) {
          jobReports.add(jobReport);
        }

        log.info('');
      }

      log.info('✅ Crawl complete!');

      // Generate report
      if (jobReports.isNotEmpty) {
        try {
          log.info('📊 Generating crawl report...');
          final commandEndTime = DateTime.now();
          final report = CrawlReport(
            startTime: commandStartTime,
            endTime: commandEndTime,
            jobReports: jobReports,
          );

          final reportPath = await CrawlReportGenerator.generateReport(
            report,
            Constants.buildDir,
          );

          log.info('✅ Report generated: $reportPath');
        } catch (e, stackTrace) {
          log
            ..error('❌ Error generating report: $e')
            ..debug('Stack trace: $stackTrace');
          // Don't fail the command if report generation fails
        }
      }

      return ExitCode.success.code;
    } catch (e, stackTrace) {
      log
        ..error('❌ Fatal error: $e')
        ..debug('Stack trace: $stackTrace');
      return ExitCode.software.code;
    } finally {
      await Future.wait([
        for (final fn in teardown)
          fn().catchError((Object e) {
            log.error('Error in teardown: $e');
          }),
      ]);
    }
  }

  Future<CrawlJobReport?> _processJob({
    required SpotifyApi api,
    required User user,
    required CrawlJob job,
    required RequestPool requestPool,
    required bool isDryRun,
    required File configFile,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    final jobStartTime = DateTime.now();

    // Resolve date range using DateRangeResolver
    final resolved = DateRangeResolver.resolve(
      job.filters,
      referenceDate: DateTime.now(),
      cliStartDate: customStartDate,
      cliEndDate: customEndDate,
    );

    // Inclusive calendar range [resolved.start, resolved.end]; templates use
    // exclusive lower cutoff = day before inclusive start.
    final inclusiveEnd = resolved.end;
    final inclusiveStart = resolved.start;
    final cutoffDate = inclusiveStart.subtract(days: 1);

    if (customStartDate != null || customEndDate != null) {
      log.info(
        '  📅 Using custom date range: '
        '${formatSimpleDate(resolved.start)} '
        'to ${formatSimpleDate(inclusiveEnd)}',
      );
    } else {
      log.info(
        '  📅 Date range: '
        '${formatSimpleDate(resolved.start)} '
        'to ${formatSimpleDate(inclusiveEnd)}',
      );
    }

    // Log the date range type for context
    if (job.filters.dateRange != null) {
      final rangeType = _describeDateRange(job.filters.dateRange!);
      log.info('  📅 Range type: $rangeType');
      // ignore: deprecated_member_use_from_same_package
    } else if (job.filters.addedBetweenDays != null) {
      // ignore: deprecated_member_use_from_same_package
      log.info('  📅 Looking back: ${job.filters.addedBetweenDays} days');
    }
    log.info('');

    // Initialize track collector
    final collector = TrackCollector(
      api: api,
      requestPool: requestPool,
      cacheAdapter: getCacheAdapter(),
    );

    // Collect tracks from all sources (all started immediately for max pool
    // use)
    final allTracks = <CollectedTrack>[];
    final dateMode =
        job.options?.addPlaylistTracksBasedOn ??
        PlaylistTrackDateMode.releaseDate;
    final includeAppearances = job.options?.includeArtistAppearances ?? true;

    final playlistIds = job.inputs.playlists ?? [];
    final artistIds = job.inputs.artists ?? [];
    final labelNames = job.inputs.labels ?? [];
    final youtubeChannelIds = job.inputs.youtubeChannels ?? [];

    final identifiers = <String>[
      ...playlistIds,
      ...artistIds,
      ...labelNames,
      ...youtubeChannelIds,
    ];

    final display = identifiers.isNotEmpty
        ? CrawlProgressDisplay(identifiers: identifiers)
        : null;

    if (display != null) {
      display.start();
    }

    final collectionFutures = <Future<List<CollectedTrack>>>[];
    var sourceIndex = 0;

    for (final playlistId in playlistIds) {
      final idx = sourceIndex++;
      final progress = display?.reporterFor(idx);
      collectionFutures.add(
        collector
            .collectFromPlaylist(
              playlistId,
              inclusiveStart,
              inclusiveEnd,
              dateMode,
              progress: progress,
            )
            .then((tracks) {
              display?.setDone(idx, tracks.length);
              return tracks;
            })
            .catchError((Object e) {
              if (display != null) {
                display.setError(idx);
              } else {
                log.error(
                  '    ❌ Error collecting from playlist $playlistId: $e',
                );
              }
              return <CollectedTrack>[];
            }),
      );
    }

    for (final artistId in artistIds) {
      final idx = sourceIndex++;
      final progress = display?.reporterFor(idx);
      collectionFutures.add(
        collector
            .collectFromArtist(
              artistId,
              inclusiveStart,
              inclusiveEnd,
              includeAppearances: includeAppearances,
              progress: progress,
            )
            .then((tracks) {
              display?.setDone(idx, tracks.length);
              return tracks;
            })
            .catchError((Object e) {
              if (display != null) {
                display.setError(idx);
              } else {
                log.error('    ❌ Error collecting from artist $artistId: $e');
              }
              return <CollectedTrack>[];
            }),
      );
    }

    for (final labelName in labelNames) {
      final idx = sourceIndex++;
      final progress = display?.reporterFor(idx);
      collectionFutures.add(
        collector
            .collectFromLabel(
              labelName,
              inclusiveStart,
              inclusiveEnd,
              progress: progress,
            )
            .then((tracks) {
              display?.setDone(idx, tracks.length);
              return tracks;
            })
            .catchError((Object e) {
              if (display != null) {
                display.setError(idx);
              } else {
                log.error('    ❌ Error collecting from label $labelName: $e');
              }
              return <CollectedTrack>[];
            }),
      );
    }

    for (final channelId in youtubeChannelIds) {
      final idx = sourceIndex++;
      final progress = display?.reporterFor(idx);
      collectionFutures.add(
        collector
            .collectFromYoutubeChannel(
              channelId,
              inclusiveStart,
              inclusiveEnd,
              progress: progress,
            )
            .then((tracks) {
              display?.setDone(idx, tracks.length);
              return tracks;
            })
            .catchError((Object e) {
              if (display != null) {
                display.setError(idx);
              } else {
                log.error(
                  '    ❌ Error collecting from YouTube channel $channelId: $e',
                );
              }
              return <CollectedTrack>[];
            }),
      );
    }

    if (display == null) {
      if (playlistIds.isNotEmpty) {
        log.info('  📜 Collecting from ${playlistIds.length} playlist(s)...');
      }
      if (artistIds.isNotEmpty) {
        log.info('  🎤 Collecting from ${artistIds.length} artist(s)...');
      }
      if (labelNames.isNotEmpty) {
        log.info('  🏷️  Collecting from ${labelNames.length} label(s)...');
      }
      if (youtubeChannelIds.isNotEmpty) {
        log.info(
          '  📺 Collecting from ${youtubeChannelIds.length} '
          'YouTube channel(s)...',
        );
      }
      if (collectionFutures.isNotEmpty) {
        log.info('');
      }
    }

    final collectionResults = await Future.wait(collectionFutures);

    display?.stop();
    collectionResults.forEach(allTracks.addAll);

    log.info('  📊 Collected ${allTracks.length} total tracks');

    if (allTracks.isEmpty) {
      log.warning('  ⚠️  No tracks found for this job');
      final jobEndTime = DateTime.now();
      return CrawlJobReport(
        jobName: job.name,
        startTime: jobStartTime,
        endTime: jobEndTime,
        trackEntries: [],
      );
    }

    // Show date range info for debugging
    if (allTracks.isNotEmpty) {
      final oldestTrack = allTracks.reduce(
        (a, b) => a.addedAt.isBefore(b.addedAt) ? a : b,
      );
      final newestTrack = allTracks.reduce(
        (a, b) => a.addedAt.isAfter(b.addedAt) ? a : b,
      );
      log
        ..debug(
          '  🕒 Track date range: '
          '${formatDate(oldestTrack.addedAt)} to '
          '${formatDate(newestTrack.addedAt)}',
        )
        ..debug(
          '  🎯 Filter range: '
          '${formatSimpleDate(inclusiveStart)} to '
          '${formatSimpleDate(inclusiveEnd)}',
        );
    }

    // Deduplicate tracks
    final deduplicateMode = job.options?.deduplicate;
    final dedupedTracks = deduplicate(allTracks, deduplicateMode);

    if (deduplicateMode != null && dedupedTracks.length < allTracks.length) {
      log.info(
        '  🔄 Deduplicated: ${allTracks.length} → '
        '${dedupedTracks.length} tracks',
      );
    }

    // Calculate real stats from collected tracks
    final realStats = _calculateRealStats(dedupedTracks);

    // Generate playlist name and description
    const templateEngine = TemplateEngine();
    final playlistName = templateEngine.render(
      job.outputPlaylist.name,
      job: job,
      cutoffDate: cutoffDate,
      endDate: inclusiveEnd,
      trackCount: dedupedTracks.length,
      realArtistCount: realStats.artistCount,
      realAlbumCount: realStats.albumCount,
      realPlaylistCount: realStats.playlistCount,
      realArtistSourceCount: realStats.artistSourceCount,
      realLabelCount: realStats.labelCount,
      realYoutubeChannelCount: realStats.youtubeChannelCount,
    );

    final playlistDescription = job.outputPlaylist.description != null
        ? templateEngine.render(
            job.outputPlaylist.description!,
            job: job,
            cutoffDate: cutoffDate,
            endDate: inclusiveEnd,
            trackCount: dedupedTracks.length,
            realArtistCount: realStats.artistCount,
            realAlbumCount: realStats.albumCount,
            realPlaylistCount: realStats.playlistCount,
            realArtistSourceCount: realStats.artistSourceCount,
            realLabelCount: realStats.labelCount,
            realYoutubeChannelCount: realStats.youtubeChannelCount,
          )
        : null;

    log.info('  📝 Playlist name: $playlistName');
    if (playlistDescription != null) {
      log.info('  📝 Description: $playlistDescription');
    }

    // Generate cover image if configured (even in dry-run mode)
    String? generatedCoverPath;
    if (job.cover != null) {
      log.info('  🎨 Generating cover image...');

      // Render caption using template engine
      final caption = job.cover!.caption ?? playlistName;
      final renderedCaption = templateEngine.render(
        caption,
        job: job,
        cutoffDate: cutoffDate,
        endDate: inclusiveEnd,
        trackCount: dedupedTracks.length,
        realArtistCount: realStats.artistCount,
        realAlbumCount: realStats.albumCount,
        realPlaylistCount: realStats.playlistCount,
        realArtistSourceCount: realStats.artistSourceCount,
        realLabelCount: realStats.labelCount,
        realYoutubeChannelCount: realStats.youtubeChannelCount,
      );

      // Generate cover (but don't upload yet)
      final configDir = configFile.parent.path;
      final imagePath = job.cover!.image;
      final outputFilename = '${job.name}_cover.jpg';
      final outputPath = path.join(
        Constants.generatedCoversDir.path,
        outputFilename,
      );

      await Directory(
        Constants.generatedCoversDir.path,
      ).create(recursive: true);

      final generatedImage = await generatePlaylistCover(
        imagePath: imagePath,
        caption: renderedCaption,
        outputPath: outputPath,
        assetsDir: configDir,
        size: 512,
        fontPath: job.cover!.font,
      );

      if (generatedImage != null) {
        generatedCoverPath = outputPath;
        log.info('  ✅ Generated cover: $outputPath');
      } else {
        log.warning('  ⚠️  Failed to generate cover image');
      }
    }

    // Warn if append mode is set but no output_playlist.id is specified
    final updateMode = job.options?.updateMode ?? CrawlUpdateMode.replace;
    if (updateMode == CrawlUpdateMode.append && job.outputPlaylist.id == null) {
      log.warning(
        '  ⚠️  update_mode is set to "append" but no output_playlist.id is '
        'specified. A new playlist will be created, so append mode has no '
        'effect.',
      );
    }

    // Resolve target playlist if specified, otherwise create new
    PlaylistSimple playlist;
    final targetPlaylistId = job.outputPlaylist.id;

    if (targetPlaylistId != null) {
      log
        ..info('  🎯 Resolving target playlist: $targetPlaylistId')
        ..info('    🔍 Fetching user playlists to resolve by name...');
      final userPlaylists = [...await api.me.playlists.saved().all(50)];
      final resolvedTarget = await resolvePlaylistTarget(
        api: api,
        input: targetPlaylistId,
        userPlaylists: userPlaylists,
      );
      final resolved = switch (resolvedTarget) {
        PlaylistSpotifyTarget(:final playlist) => playlist,
        _ => null,
      };

      if (resolved == null) {
        throw Exception(
          'Failed to resolve target playlist "$targetPlaylistId" for job '
          '"${job.name}". See errors above.',
        );
      }

      playlist = resolved;
      log.info('  ✅ Target playlist: "${playlist.name}" (${playlist.id})');
    } else {
      if (isDryRun) {
        log.info(
          '  🔍 DRY RUN: Would create playlist with '
          '${dedupedTracks.length} tracks',
        );
        if (generatedCoverPath != null) {
          log.info('  🔍 DRY RUN: Would upload cover from $generatedCoverPath');
        }
        final jobEndTime = DateTime.now();
        final trackEntries = _buildTrackEntries(dedupedTracks, job);
        return CrawlJobReport(
          jobName: job.name,
          startTime: jobStartTime,
          endTime: jobEndTime,
          trackEntries: trackEntries,
        );
      }

      // Create the playlist
      log.info('  📝 Creating playlist on Spotify...');
      final isPublic = job.outputPlaylist.public;
      log.info('  🔒 Playlist visibility: ${isPublic ? "public" : "private"}');
      playlist = await api.me.playlists.create(
        playlistName,
        public: isPublic,
        description: playlistDescription,
      );

      log.info('  ✅ Created playlist: ${playlist.id}');
    }

    if (isDryRun && targetPlaylistId != null) {
      final modeDescription = updateMode == CrawlUpdateMode.append
          ? 'append to'
          : 'replace tracks in';
      log.info(
        '  🔍 DRY RUN: Would $modeDescription target playlist with '
        '${dedupedTracks.length} tracks',
      );
      if (generatedCoverPath != null) {
        log.info('  🔍 DRY RUN: Would upload cover from $generatedCoverPath');
      }
      final jobEndTime = DateTime.now();
      final trackEntries = _buildTrackEntries(dedupedTracks, job);
      return CrawlJobReport(
        jobName: job.name,
        startTime: jobStartTime,
        endTime: jobEndTime,
        trackEntries: trackEntries,
      );
    }

    // Update playlist tracks
    if (dedupedTracks.isNotEmpty) {
      final isReplaceMode = updateMode == CrawlUpdateMode.replace;
      final modeDescription = isReplaceMode ? 'replacing' : 'appending to';
      log.info(
        '  📤 $modeDescription playlist with ${dedupedTracks.length} tracks...',
      );

      // Log each track with its source and inclusion reason
      for (final track in dedupedTracks) {
        final sourceInfo = _getTrackSourceInfo(track, job);
        log
          ..info('    🎵 ${track.artistNames.join(', ')} - ${track.name}')
          ..info('      📍 Source: $sourceInfo')
          ..info('      📅 Date: ${formatDate(track.addedAt)}');
      }

      List<String> trackUris;

      if (isReplaceMode) {
        // Clear existing tracks first
        log.info('  🗑️  Clearing existing tracks...');
        await api.playlists.clear(playlist.id!);
        trackUris = dedupedTracks.map((t) => t.uri).toList();
      } else {
        // Append mode: check existing tracks and filter duplicates
        log.info('  🔍 Checking existing tracks in playlist...');
        final existingPlaylistTracks = await api.playlists
            .getPlaylistTracks(playlist.id!)
            .all(50);

        // Extract existing track IDs
        final existingTrackIds = <String>{};
        for (final playlistTrack in existingPlaylistTracks) {
          if (playlistTrack.track?.id != null) {
            existingTrackIds.add(playlistTrack.track!.id!);
          }
        }

        log.info('  📊 Found ${existingTrackIds.length} existing track(s)');

        // Filter out tracks that are already in the playlist
        final newTracks = dedupedTracks
            .where((track) => !existingTrackIds.contains(track.id.toString()))
            .toList();

        final skippedCount = dedupedTracks.length - newTracks.length;
        if (skippedCount > 0) {
          log.info(
            '  ⏭️  Skipping $skippedCount track(s) already in playlist',
          );
        }

        if (newTracks.isEmpty) {
          log.info('  ✅ All tracks already in playlist, nothing to add');
          trackUris = [];
        } else {
          log.info(
            '  ➕ Adding ${newTracks.length} new track(s) to playlist',
          );
          trackUris = newTracks.map((t) => t.uri).toList();
        }
      }

      // Add tracks in batches of 100
      if (trackUris.isNotEmpty) {
        for (var i = 0; i < trackUris.length; i += 100) {
          final batch = trackUris.skip(i).take(100).toList();
          await api.playlists.addTracks(batch, playlist.id!);
        }
        log.info('  ✅ Updated playlist tracks');
      }
    } else {
      // Even if no tracks, clear the playlist if replacing existing
      if (targetPlaylistId != null && updateMode == CrawlUpdateMode.replace) {
        log.info('  🗑️  Clearing playlist (no tracks to add)...');
        await api.playlists.clear(playlist.id!);
      }
    }

    // Update playlist name and description
    log.info('  📝 Updating playlist name and description...');
    try {
      await api.playlists.updatePlaylist(
        playlist.id!,
        playlistName,
        description: playlistDescription,
      );
      log.info('  ✅ Updated playlist name and description');
    } catch (e) {
      log.warning('  ⚠️  Failed to update playlist name/description: $e');
    }

    // Upload cover image if it was generated
    if (generatedCoverPath != null) {
      log.info('  📤 Uploading cover image...');
      // ignore: invalid_use_of_visible_for_testing_member
      final client = await api.client;
      final uploadSuccess = await uploadPlaylistImage(
        spotifyClient: client,
        playlistId: playlist.id!,
        imagePath: generatedCoverPath,
      );

      if (!uploadSuccess) {
        log.warning('  ⚠️  Failed to upload cover image');
      }
    }

    // Show playlist URL
    if (playlist.externalUrls?.spotify != null) {
      log.info('  🔗 Playlist URL: ${playlist.externalUrls!.spotify}');
    }

    final jobEndTime = DateTime.now();
    final trackEntries = _buildTrackEntries(dedupedTracks, job);

    return CrawlJobReport(
      jobName: job.name,
      startTime: jobStartTime,
      endTime: jobEndTime,
      trackEntries: trackEntries,
    );
  }

  /// Builds track entries for the report from collected tracks.
  List<CrawlTrackEntry> _buildTrackEntries(
    List<CollectedTrack> tracks,
    CrawlJob job,
  ) {
    return tracks.map((track) {
      final sourceInfo = _convertToSourceInfo(track.source);
      final reason = _getInclusionReason(track, job);

      return CrawlTrackEntry(
        trackName: track.name,
        artistNames: track.artistNames,
        sourceInfo: sourceInfo,
        reason: reason,
      );
    }).toList();
  }

  /// Converts a CollectedTrackSource to CrawlSourceInfo.
  CrawlSourceInfo _convertToSourceInfo(CollectedTrackSource source) {
    return switch (source) {
      CollectedTrackSourcePlaylist(:final id, :final name) =>
        CrawlSourceInfoPlaylist(id: id, name: name),
      CollectedTrackSourceArtist(:final id, :final name) =>
        CrawlSourceInfoArtist(id: id, name: name),
      CollectedTrackSourceLabel(:final name) => CrawlSourceInfoLabel(
        name: name,
      ),
      CollectedTrackSourceYoutubeChannel(
        :final id,
        :final name,
        :final videoTitle,
        :final videoId,
      ) =>
        CrawlSourceInfoYoutubeChannel(
          id: id,
          name: name,
          videoTitle: videoTitle,
          videoId: videoId,
        ),
    };
  }

  /// Gets the human-readable reason why a track was included.
  String _getInclusionReason(CollectedTrack track, CrawlJob job) {
    switch (track.source) {
      case CollectedTrackSourcePlaylist():
        final dateMode =
            job.options?.addPlaylistTracksBasedOn ??
            PlaylistTrackDateMode.releaseDate;
        final dateModeText = dateMode == PlaylistTrackDateMode.addedDate
            ? 'added to playlist'
            : 'released';
        return 'Track $dateModeText within date range';

      case CollectedTrackSourceArtist():
        return 'Released within date range';

      case CollectedTrackSourceLabel():
        return 'Released within date range';
      case CollectedTrackSourceYoutubeChannel():
        return 'Uploaded to YouTube channel within date range';
    }
  }

  /// Gets detailed source information for a track.
  String _getTrackSourceInfo(CollectedTrack track, CrawlJob job) {
    switch (track.source) {
      case CollectedTrackSourcePlaylist(:final name):
        final dateMode =
            job.options?.addPlaylistTracksBasedOn ??
            PlaylistTrackDateMode.releaseDate;
        final dateModeText = dateMode == PlaylistTrackDateMode.addedDate
            ? 'added to playlist'
            : 'released';
        return 'Playlist "$name" '
            '(included because $dateModeText within timeframe)';

      case CollectedTrackSourceArtist(:final name):
        return 'Artist "$name" (released within timeframe)';

      case CollectedTrackSourceLabel(:final name):
        return 'Label "$name" (released within timeframe)';
      case CollectedTrackSourceYoutubeChannel(:final name):
        return 'YouTube channel "$name" (uploaded within timeframe)';
    }
  }

  /// Describes a date range for logging purposes.
  String _describeDateRange(CrawlDateRange range) {
    return switch (range) {
      CrawlDateRangeDays(:final days) => 'Last $days days',
      CrawlDateRangeShortcut(:final shortcut) => shortcut.replaceAll('_', ' '),
      CrawlDateRangeTimeUnit(:final days, :final weeks, :final months) =>
        days != null
            ? 'Last $days days'
            : weeks != null
            ? 'Last $weeks weeks'
            : months != null
            ? 'Last $months months'
            : 'Unknown time unit',
      CrawlDateRangeAbsolute(:final start, :final end) =>
        '${formatSimpleDate(start)} to ${formatSimpleDate(end)}',
    };
  }

  /// Calculates real statistics from collected tracks.
  _RealStats _calculateRealStats(List<CollectedTrack> tracks) {
    final uniqueArtists = <String>{};
    final uniqueAlbums = <SpotifyAlbumId>{};
    final uniquePlaylists = <String>{};
    final uniqueArtistSources = <String>{};
    final uniqueLabels = <String>{};
    final uniqueYoutubeChannels = <String>{};

    for (final track in tracks) {
      // Count unique artists
      uniqueArtists.addAll(track.artistNames);

      // Count unique albums
      if (track.albumId != null) {
        uniqueAlbums.add(track.albumId!);
      }

      // Count unique sources
      switch (track.source) {
        case CollectedTrackSourcePlaylist(:final id):
          uniquePlaylists.add(id);
        case CollectedTrackSourceArtist(:final id):
          uniqueArtistSources.add(id);
        case CollectedTrackSourceLabel(:final name):
          uniqueLabels.add(name);
        case CollectedTrackSourceYoutubeChannel(:final id):
          uniqueYoutubeChannels.add(id);
      }
    }

    return _RealStats(
      artistCount: uniqueArtists.length,
      albumCount: uniqueAlbums.length,
      playlistCount: uniquePlaylists.length,
      artistSourceCount: uniqueArtistSources.length,
      labelCount: uniqueLabels.length,
      youtubeChannelCount: uniqueYoutubeChannels.length,
    );
  }
}

/// Real statistics calculated from collected tracks.
class _RealStats {
  const _RealStats({
    required this.artistCount,
    required this.albumCount,
    required this.playlistCount,
    required this.artistSourceCount,
    required this.labelCount,
    required this.youtubeChannelCount,
  });

  final int artistCount;
  final int albumCount;
  final int playlistCount;
  final int artistSourceCount;
  final int labelCount;
  final int youtubeChannelCount;
}
