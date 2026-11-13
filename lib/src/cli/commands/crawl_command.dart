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
import 'package:simple_date/simple_date.dart';
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
            'Overrides the job date_range setting.',
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
    final commandStartTime = DateTime.now();

    final customConfigPath = argResults!['config'] as String?;
    final usesCustomConfigPath = customConfigPath != null;
    final configFile = usesCustomConfigPath
        ? resolveConfigPath(customConfigPath)
        : Constants.crawlConfigFile;

    log.info('Loading crawl config from: ${configFile.path}');
    final config = await CrawlConfig.fromFile(configFile);

    if (config.jobs.isEmpty) {
      log.warning('No jobs found in configuration');
      return ExitCode.config.code;
    }

    for (final job in config.jobs) {
      try {
        DateRangeResolver.validate(job.filters);
      } catch (e) {
        log.error('Invalid date_range configuration in job "${job.name}": $e');
        return ExitCode.config.code;
      }
    }

    final requestedJobs = argResults!['job'] as List<String>;
    final jobsToRun = requestedJobs.isEmpty
        ? config.jobs
        : config.jobs.where((job) => requestedJobs.contains(job.name)).toList();
    if (jobsToRun.isEmpty) {
      usageException('No matching jobs found for: ${requestedJobs.join(', ')}');
    }

    final customStartDate = _parseDateOption('start-date');
    final customEndDate = _parseDateOption('end-date');
    if (customStartDate != null &&
        customEndDate != null &&
        customStartDate.isAfter(customEndDate)) {
      usageException('Start date must be before or equal to end date');
    }

    final isDryRun = argResults!['dry-run'] as bool;

    return withTeardown((addTeardown) async {
      final api = await spotifyLogin();
      addTeardown(() => closeSpotifyApi(api));

      final requestPool = Zonable.fromZone<RequestPool>();
      addTeardown(requestPool.clear);

      final user = await api.me.get();
      log
        ..info('Logged in as: ${user.displayName}')
        ..info('Found ${jobsToRun.length} job(s) to process')
        ..info('');

      if (isDryRun) {
        log
          ..info('🔍 DRY RUN MODE - No playlists will be created')
          ..info('');
      }

      final jobReports = <CrawlJobReport>[];
      final failedJobs = <String>[];
      for (final (index, job) in jobsToRun.indexed) {
        log.info(
          '🔄 Processing job ${index + 1}/${jobsToRun.length}: ${job.name}',
        );

        try {
          jobReports.add(
            await _processJob(
              api: api,
              job: job,
              requestPool: requestPool,
              isDryRun: isDryRun,
              configFile: configFile,
              customStartDate: customStartDate,
              customEndDate: customEndDate,
            ),
          );
        } on Exception catch (e, stackTrace) {
          failedJobs.add(job.name);
          log
            ..error('  ❌ Job "${job.name}" failed: $e')
            ..error('     The output playlist was not changed.')
            ..debug('Stack trace: $stackTrace');
        }

        log.info('');
      }

      if (jobReports.isNotEmpty) {
        try {
          log.info('📊 Generating crawl report...');
          final reportPath = await CrawlReportGenerator.generateReport(
            CrawlReport(
              startTime: commandStartTime,
              endTime: DateTime.now(),
              jobReports: jobReports,
            ),
            Constants.buildDir,
          );
          log.info('✅ Report generated: $reportPath');
        } catch (e, stackTrace) {
          log
            ..error('❌ Error generating report: $e')
            ..debug('Stack trace: $stackTrace');
        }
      }

      final jobsWithFailedSources = jobReports.where(
        (report) => report.failedSources.isNotEmpty,
      );
      if (jobsWithFailedSources.isNotEmpty) {
        log.warning(
          '⚠️  Some sources failed and were left out: '
          '${jobsWithFailedSources.map((r) => r.jobName).join(', ')}',
        );
      }

      if (failedJobs.isNotEmpty) {
        log.error(
          '❌ ${failedJobs.length} job(s) failed: ${failedJobs.join(', ')}',
        );
        return ExitCode.software.code;
      }

      log.info('✅ Crawl complete!');
      return ExitCode.success.code;
    });
  }

  DateTime? _parseDateOption(String name) {
    final value = argResults![name] as String?;
    if (value == null) return null;
    final date = DateTime.tryParse(value);
    if (date == null) {
      usageException('Invalid $name format: $value. Expected YYYY-MM-DD');
    }
    log.info('Using custom $name: ${formatDate(date)}');
    return date;
  }

  /// Collects tracks for [job] and writes them to its output playlist.
  ///
  /// Sources that fail are left out and listed in the report. Throws when
  /// every source or the output playlist cannot be read, before anything is
  /// written to Spotify.
  Future<CrawlJobReport> _processJob({
    required SpotifyApi api,
    required CrawlJob job,
    required RequestPool requestPool,
    required bool isDryRun,
    required File configFile,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    final jobStartTime = DateTime.now();

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

    final rangeLabel = customStartDate != null || customEndDate != null
        ? 'Using custom date range'
        : 'Date range';
    log.info(
      '  📅 $rangeLabel: ${formatSimpleDate(inclusiveStart)} '
      'to ${formatSimpleDate(inclusiveEnd)}',
    );
    if (job.filters.dateRange != null) {
      log.info(
        '  📅 Range type: ${_describeDateRange(job.filters.dateRange!)}',
      );
      // ignore: deprecated_member_use_from_same_package
    } else if (job.filters.addedBetweenDays != null) {
      // ignore: deprecated_member_use_from_same_package
      log.info('  📅 Looking back: ${job.filters.addedBetweenDays} days');
    }
    log.info('');

    final (tracks: allTracks, :failedSources) = await _collectTracks(
      job: job,
      collector: TrackCollector(
        api: api,
        requestPool: requestPool,
        cacheAdapter: getCacheAdapter(),
      ),
      inclusiveStart: inclusiveStart,
      inclusiveEnd: inclusiveEnd,
    );

    log.info('  📊 Collected ${allTracks.length} total tracks');
    if (allTracks.isNotEmpty) {
      final addedDates = allTracks.map((t) => t.addedAt);
      log
        ..debug(
          '  🕒 Track date range: '
          '${formatDate(addedDates.reduce((a, b) => a.isBefore(b) ? a : b))} '
          'to ${formatDate(addedDates.reduce((a, b) => a.isAfter(b) ? a : b))}',
        )
        ..debug(
          '  🎯 Filter range: '
          '${formatSimpleDate(inclusiveStart)} to '
          '${formatSimpleDate(inclusiveEnd)}',
        );
    } else {
      log.warning('  ⚠️  No tracks found for this job');
    }

    final deduplicateMode = job.options?.deduplicate;
    final dedupedTracks = deduplicate(allTracks, deduplicateMode);
    if (deduplicateMode != null && dedupedTracks.length < allTracks.length) {
      log.info(
        '  🔄 Deduplicated: ${allTracks.length} → '
        '${dedupedTracks.length} tracks',
      );
    }

    const templateEngine = TemplateEngine();
    final templateContext = TemplateContext.fromTracks(
      job: job,
      cutoffDate: cutoffDate,
      endDate: inclusiveEnd,
      tracks: dedupedTracks,
    );
    final playlistName = templateEngine.render(
      job.outputPlaylist.name,
      templateContext,
    );
    final playlistDescription = job.outputPlaylist.description.let(
      (description) => templateEngine.render(description, templateContext),
    );

    log.info('  📝 Playlist name: $playlistName');
    if (playlistDescription != null) {
      log.info('  📝 Description: $playlistDescription');
    }

    // Generate cover image if configured (even in dry-run mode)
    String? generatedCoverPath;
    if (job.cover case final cover?) {
      log.info('  🎨 Generating cover image...');
      final outputPath = path.join(
        Constants.generatedCoversDir.path,
        '${job.name}_cover.jpg',
      );
      await Constants.generatedCoversDir.create(recursive: true);

      final generatedImage = await generatePlaylistCover(
        imagePath: cover.image,
        caption: templateEngine.render(
          cover.caption ?? playlistName,
          templateContext,
        ),
        outputPath: outputPath,
        assetsDir: configFile.parent.path,
        size: 512,
        fontPath: cover.font,
      );

      if (generatedImage != null) {
        generatedCoverPath = outputPath;
        log.info('  ✅ Generated cover: $outputPath');
      } else {
        log.warning('  ⚠️  Failed to generate cover image');
      }
    }

    final updateMode = job.options?.updateMode ?? CrawlUpdateMode.replace;
    final targetPlaylistInput = job.outputPlaylist.id;
    if (updateMode == CrawlUpdateMode.append && targetPlaylistInput == null) {
      log.warning(
        '  ⚠️  update_mode is set to "append" but no output_playlist.id is '
        'specified. A new playlist will be created, so append mode has no '
        'effect.',
      );
    }

    CrawlJobReport buildReport() => CrawlJobReport(
      jobName: job.name,
      startTime: jobStartTime,
      endTime: DateTime.now(),
      trackEntries: _buildTrackEntries(dedupedTracks, job),
      failedSources: failedSources,
    );

    PlaylistSimple? targetPlaylist;
    if (targetPlaylistInput != null) {
      log.info('  🎯 Resolving target playlist: $targetPlaylistInput');
      final resolvedTarget = await resolvePlaylistTarget(
        api: api,
        input: targetPlaylistInput,
        userPlaylists: await fetchSavedPlaylists(
          api: api,
          requestPool: requestPool,
        ),
      );
      targetPlaylist = switch (resolvedTarget) {
        PlaylistSpotifyTarget(:final playlist) => playlist,
        _ => throw Exception(
          'Could not resolve target playlist "$targetPlaylistInput"',
        ),
      };
      log.info(
        '  ✅ Target playlist: "${targetPlaylist.name}" '
        '(${targetPlaylist.id})',
      );
    }

    if (isDryRun) {
      log.info(
        targetPlaylist == null
            ? '  🔍 DRY RUN: Would create playlist with '
                  '${dedupedTracks.length} tracks'
            : '  🔍 DRY RUN: Would ${updateMode.name} '
                  'target playlist with ${dedupedTracks.length} tracks',
      );
      if (generatedCoverPath != null) {
        log.info('  🔍 DRY RUN: Would upload cover from $generatedCoverPath');
      }
      return buildReport();
    }

    final PlaylistSimple playlist;
    if (targetPlaylist != null) {
      playlist = targetPlaylist;
    } else {
      final isPublic = job.outputPlaylist.public;
      log.info(
        '  📝 Creating ${isPublic ? 'public' : 'private'} playlist on '
        'Spotify...',
      );
      playlist = await api.me.playlists.create(
        playlistName,
        public: isPublic,
        description: playlistDescription,
      );
      log.info('  ✅ Created playlist: ${playlist.id}');
    }
    final playlistId = SpotifyPlaylistId(playlist.id!);

    for (final track in dedupedTracks) {
      log
        ..info('    🎵 ${track.artistNames.join(', ')} - ${track.name}')
        ..info('      📍 Source: ${_getTrackSourceInfo(track, job)}')
        ..info('      📅 Date: ${formatDate(track.addedAt)}');
    }

    final uris = dedupedTracks.map((t) => t.uri).toList();
    if (updateMode == CrawlUpdateMode.replace) {
      log.info('  📤 Replacing playlist with ${uris.length} tracks...');
      await replacePlaylistTracks(api: api, playlistId: playlistId, uris: uris);
    } else {
      log.info('  📤 Appending to playlist...');
      final added = await appendNewPlaylistTracks(
        api: api,
        requestPool: requestPool,
        playlistId: playlistId,
        uris: uris,
      );
      log.info(
        '  ➕ Added ${added.length} new track(s), '
        '${uris.length - added.length} already in playlist',
      );
    }
    log
      ..info('  ✅ Updated playlist tracks')
      ..info('  📝 Updating playlist name and description...');
    try {
      await api.playlists.updatePlaylist(
        playlistId,
        playlistName,
        description: playlistDescription,
      );
      log.info('  ✅ Updated playlist name and description');
    } catch (e) {
      log.warning('  ⚠️  Failed to update playlist name/description: $e');
    }

    if (generatedCoverPath != null) {
      log.info('  📤 Uploading cover image...');
      // ignore: invalid_use_of_visible_for_testing_member
      final client = await api.client;
      final uploadSuccess = await uploadPlaylistImage(
        spotifyClient: client,
        playlistId: playlistId,
        imagePath: generatedCoverPath,
      );
      if (!uploadSuccess) {
        log.warning('  ⚠️  Failed to upload cover image');
      }
    }

    if (playlist.externalUrls?.spotify != null) {
      log.info('  🔗 Playlist URL: ${playlist.externalUrls!.spotify}');
    }

    return buildReport();
  }

  /// Collects tracks from every input of [job] concurrently.
  ///
  /// See [collectFromSources] for how failing sources are handled.
  Future<CrawlSourcesResult> _collectTracks({
    required CrawlJob job,
    required TrackCollector collector,
    required SimpleDate inclusiveStart,
    required SimpleDate inclusiveEnd,
  }) async {
    final dateMode =
        job.options?.addPlaylistTracksBasedOn ??
        PlaylistTrackDateMode.releaseDate;
    final includeAppearances = job.options?.includeArtistAppearances ?? true;

    final sources = <CrawlSource>[
      for (final id in job.inputs.playlists ?? <String>[])
        (
          label: 'playlist $id',
          collect: (progress) => collector.collectFromPlaylist(
            id,
            inclusiveStart,
            inclusiveEnd,
            dateMode,
            progress: progress,
          ),
        ),
      for (final id in job.inputs.artists ?? <String>[])
        (
          label: 'artist $id',
          collect: (progress) => collector.collectFromArtist(
            id,
            inclusiveStart,
            inclusiveEnd,
            includeAppearances: includeAppearances,
            progress: progress,
          ),
        ),
      for (final name in job.inputs.labels ?? <String>[])
        (
          label: 'label $name',
          collect: (progress) => collector.collectFromLabel(
            name,
            inclusiveStart,
            inclusiveEnd,
            progress: progress,
          ),
        ),
      for (final id in job.inputs.youtubeChannels ?? <String>[])
        (
          label: 'YouTube channel $id',
          collect: (progress) => collector.collectFromYoutubeChannel(
            id,
            inclusiveStart,
            inclusiveEnd,
            progress: progress,
          ),
        ),
    ];
    final display = CrawlProgressDisplay(
      identifiers: [
        ...?job.inputs.playlists,
        ...?job.inputs.artists,
        ...?job.inputs.labels,
        ...?job.inputs.youtubeChannels,
      ],
    )..start();

    final CrawlSourcesResult result;
    try {
      result = await collectFromSources(sources, display: display);
    } finally {
      display.stop();
    }

    for (final failure in result.failedSources) {
      log.warning('  ⚠️  Skipped $failure');
    }
    return result;
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
}
