import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';
import 'package:in_phase/in_phase_api.dart';
import 'package:in_phase/src/logger/logger.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:in_phase/src/reports/sync_report_generator.dart';
import 'package:io/io.dart';

class SyncCommand extends Command<int> {
  SyncCommand();

  @override
  final String name = 'sync';

  @override
  final String description =
      'Syncs playlists on Spotify with Rekordbox. '
      'Place a list of playlist IDs or glob patterns to sync.';

  @override
  Future<int> run() async {
    return withTeardown((addTeardown) async {
      // Create InPhase instance
      final inPhase = await InPhase.create();
      addTeardown(inPhase.dispose);

      // Authenticate with Spotify
      final spotifyApi = await spotifyLogin();
      // ignore: invalid_use_of_visible_for_testing_member
      addTeardown(() async => (await spotifyApi.client).close());
      await inPhase.authenticate(spotifyApi);

      // Get playlist IDs from args (if provided)
      final List<String>? playlistIds;
      if (argResults!.rest case final rest when rest.isNotEmpty) {
        playlistIds = rest;
      } else {
        playlistIds = null; // Will use sync config patterns
      }

      // Start sync and listen to progress stream
      SyncReport? syncReport;
      await for (final progress in inPhase.syncPlaylists(
        playlistIds: playlistIds,
      )) {
        switch (progress) {
          case SyncProgressStarted(:final playlistCount):
            log.info('Starting sync of $playlistCount playlists');
          case SyncProgressPlaylistStarted(:final playlistName):
            log.info('[${green(playlistName)}] Syncing playlist');
          case SyncProgressTrackProcessed(:final trackEntry):
            switch (trackEntry) {
              case SyncTrackAdded(:final trackName, :final artistNames):
                log.debug(
                  '  ✓ Added: ${artistNames.join(', ')} - $trackName',
                );
              case SyncTrackCustom(:final trackName, :final artistNames):
                log.debug(
                  '  ⚙ Custom: ${artistNames.join(', ')} - $trackName',
                );
              case SyncTrackMissing(:final trackName, :final artistNames):
                log.warning(
                  '  ✗ Missing: ${artistNames.join(', ')} - $trackName',
                );
            }
          case SyncProgressPlaylistCompleted(:final report):
            final addedCount = report.tracks.whereType<SyncTrackAdded>().length;
            final customCount = report.tracks
                .whereType<SyncTrackCustom>()
                .length;
            final missingCount = report.tracks
                .whereType<SyncTrackMissing>()
                .length;
            log.info(
              '[${green(report.playlistName)}] Completed: '
              '$addedCount added, '
              '$customCount custom, '
              '$missingCount missing',
            );
          case SyncProgressCompleted(:final report):
            syncReport = report;
            log.info(
              'Sync completed: ${report.playlistReports.length} playlists, '
              '${report.totalTracks} tracks, '
              '${report.totalAdded} added, '
              '${report.totalCustom} custom, '
              '${report.totalMissing} missing',
            );
          case SyncProgressError(:final message, :final error):
            log.error('Sync error: $message${error != null ? '\n$error' : ''}');
            return ExitCode.software.code;
        }
      }

      // Generate report if sync completed successfully
      if (syncReport != null) {
        final reportGenerator = SyncReportGenerator();
        final reportFile = await reportGenerator.generate(syncReport);
        log.info('Report saved to: ${reportFile.path}');
      }

      return ExitCode.success.code;
    });
  }
}
