import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as path;
import 'package:rkdb_dart/src/crawl/cover_generator.dart';
import 'package:rkdb_dart/src/crawl/date_utils.dart';
import 'package:rkdb_dart/src/crawl/deduplicator.dart';
import 'package:rkdb_dart/src/crawl/template_engine.dart';
import 'package:rkdb_dart/src/crawl/track_collector.dart';
import 'package:rkdb_dart/src/database/database.exports.dart';
import 'package:rkdb_dart/src/entities/entities.dart';
import 'package:rkdb_dart/src/logger/logger.dart';
import 'package:rkdb_dart/src/misc/misc.dart';
import 'package:rkdb_dart/src/reports/reports.dart';
import 'package:rkdb_dart/src/spotify/spotify.dart';
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
      'and creates/updates playlists.';

  @override
  Future<int> run() async {
    final teardown = <Future<void> Function()>[];
    final commandStartTime = DateTime.now();
    final jobReports = <CrawlJobReport>[];

    try {
      // Load configuration
      final configPath = argResults!['config'] as String?;
      final configFile = configPath != null
          ? File(configPath)
          : Constants.crawlConfigFile;

      log.info('Loading crawl config from: ${configFile.path}');
      final config = await CrawlConfig.fromFile(configFile);

      if (config.jobs.isEmpty) {
        log.warning('No jobs found in configuration');
        return ExitCode.config.code;
      }

      // Login to Spotify
      final api = await spotifyLogin();
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
          log.error('No matching jobs found for: ${requestedJobs.join(', ')}');
          return ExitCode.usage.code;
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
          log.error(
            'Invalid start date format: $startDateStr. '
            'Expected YYYY-MM-DD',
          );
          return ExitCode.usage.code;
        }
      }

      if (endDateStr != null) {
        try {
          customEndDate = DateTime.parse(endDateStr);
          log.info('Using custom end date: ${formatDate(customEndDate)}');
        } catch (e) {
          log.error(
            'Invalid end date format: $endDateStr. Expected YYYY-MM-DD',
          );
          return ExitCode.usage.code;
        }
      }

      if (customStartDate != null && customEndDate != null) {
        if (customStartDate.isAfter(customEndDate)) {
          log.error('Start date must be before or equal to end date');
          return ExitCode.usage.code;
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

    // Calculate date range
    final daysBack = job.filters.addedBetweenDays;

    // Use custom end date if provided, otherwise use current time
    final endDate = customEndDate ?? DateTime.now();

    // Use custom start date if provided, otherwise calculate from days_back
    // Note: cutoffDate is exclusive in the filter (added_at > cutoffDate)
    final DateTime cutoffDate;
    if (customStartDate != null) {
      // Subtract 1 day since we use > comparison (exclusive lower bound)
      cutoffDate = customStartDate.subtract(const Duration(days: 1));
    } else {
      cutoffDate = endDate.subtract(Duration(days: daysBack));
    }

    if (customStartDate != null || customEndDate != null) {
      log.info(
        '  📅 Using custom date range: '
        '${formatDate(cutoffDate.add(const Duration(days: 1)))} '
        'to ${formatDate(endDate)}',
      );
    } else {
      log.info(
        '  📅 Date range: '
        '${formatDate(cutoffDate.add(const Duration(days: 1)))} '
        'to ${formatDate(endDate)}',
      );
    }

    log
      ..info('  📅 Looking back: $daysBack days')
      ..info('');

    // Initialize track collector
    final collector = TrackCollector(
      api: api,
      requestPool: requestPool,
      cacheAdapter: getCacheAdapter(),
    );

    // Collect tracks from all sources
    final allTracks = <CollectedTrack>[];

    // Collect from playlists
    final playlistIds = job.inputs.playlists ?? [];
    if (playlistIds.isNotEmpty) {
      final dateMode =
          job.options?.addPlaylistTracksBasedOn ??
          PlaylistTrackDateMode.releaseDate;
      log.info('  📜 Collecting from ${playlistIds.length} playlist(s)...');
      for (final playlistId in playlistIds) {
        try {
          final tracks = await collector.collectFromPlaylist(
            playlistId,
            cutoffDate,
            endDate,
            dateMode,
          );
          allTracks.addAll(tracks);
        } catch (e) {
          log.error('    ❌ Error collecting from playlist $playlistId: $e');
        }
      }
      log.info('');
    }

    // Collect from artists
    final artistIds = job.inputs.artists ?? [];
    if (artistIds.isNotEmpty) {
      log.info('  🎤 Collecting from ${artistIds.length} artist(s)...');
      for (final artistId in artistIds) {
        try {
          final tracks = await collector.collectFromArtist(
            artistId,
            cutoffDate,
            endDate,
          );
          allTracks.addAll(tracks);
        } catch (e) {
          log.error('    ❌ Error collecting from artist $artistId: $e');
        }
      }
      log.info('');
    }

    // Collect from labels
    final labelNames = job.inputs.labels ?? [];
    if (labelNames.isNotEmpty) {
      log.info('  🏷️  Collecting from ${labelNames.length} label(s)...');
      for (final labelName in labelNames) {
        try {
          final tracks = await collector.collectFromLabel(
            labelName,
            cutoffDate,
            endDate,
          );
          allTracks.addAll(tracks);
        } catch (e) {
          log.error('    ❌ Error collecting from label $labelName: $e');
        }
      }
      log.info('');
    }

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
          '${formatDate(cutoffDate.add(const Duration(days: 1)))} to '
          '${formatDate(endDate)}',
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
      endDate: endDate,
      trackCount: dedupedTracks.length,
      realArtistCount: realStats.artistCount,
      realAlbumCount: realStats.albumCount,
      realPlaylistCount: realStats.playlistCount,
      realArtistSourceCount: realStats.artistSourceCount,
      realLabelCount: realStats.labelCount,
    );

    final playlistDescription = job.outputPlaylist.description != null
        ? templateEngine.render(
            job.outputPlaylist.description!,
            job: job,
            cutoffDate: cutoffDate,
            endDate: endDate,
            trackCount: dedupedTracks.length,
            realArtistCount: realStats.artistCount,
            realAlbumCount: realStats.albumCount,
            realPlaylistCount: realStats.playlistCount,
            realArtistSourceCount: realStats.artistSourceCount,
            realLabelCount: realStats.labelCount,
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
        endDate: endDate,
        trackCount: dedupedTracks.length,
        realArtistCount: realStats.artistCount,
        realAlbumCount: realStats.albumCount,
        realPlaylistCount: realStats.playlistCount,
        realArtistSourceCount: realStats.artistSourceCount,
        realLabelCount: realStats.labelCount,
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
      );

      if (generatedImage != null) {
        generatedCoverPath = outputPath;
        log.info('  ✅ Generated cover: $outputPath');
      } else {
        log.warning('  ⚠️  Failed to generate cover image');
      }
    }

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
    final playlist = await api.playlists.createPlaylist(
      user.id!,
      playlistName,
      public: job.outputPlaylist.public,
      description: playlistDescription,
    );

    log.info('  ✅ Created playlist: ${playlist.id}');

    // Add tracks in batches of 100
    if (dedupedTracks.isNotEmpty) {
      log.info('  📤 Adding ${dedupedTracks.length} tracks to playlist...');

      // Log each track with its source and inclusion reason
      for (final track in dedupedTracks) {
        final sourceInfo = _getTrackSourceInfo(track, job);
        log
          ..info('    🎵 ${track.artistNames.join(', ')} - ${track.name}')
          ..info('      📍 Source: $sourceInfo')
          ..info('      📅 Date: ${formatDate(track.addedAt)}');
      }

      final trackUris = dedupedTracks.map((t) => t.uri).toList();
      for (var i = 0; i < trackUris.length; i += 100) {
        final batch = trackUris.skip(i).take(100).toList();
        await api.playlists.addTracks(batch, playlist.id!);
      }

      log.info('  ✅ Added all tracks to playlist');
    }

    // Upload cover image if it was generated
    if (generatedCoverPath != null) {
      log.info('  📤 Uploading cover image...');
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
    }
  }

  /// Calculates real statistics from collected tracks.
  _RealStats _calculateRealStats(List<CollectedTrack> tracks) {
    final uniqueArtists = <String>{};
    final uniqueAlbums = <SpotifyAlbumId>{};
    final uniquePlaylists = <String>{};
    final uniqueArtistSources = <String>{};
    final uniqueLabels = <String>{};

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
      }
    }

    return _RealStats(
      artistCount: uniqueArtists.length,
      albumCount: uniqueAlbums.length,
      playlistCount: uniquePlaylists.length,
      artistSourceCount: uniqueArtistSources.length,
      labelCount: uniqueLabels.length,
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
  });

  final int artistCount;
  final int albumCount;
  final int playlistCount;
  final int artistSourceCount;
  final int labelCount;
}
