import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:in_phase/src/entities/entities.dart';
import 'package:in_phase/src/library/library.dart';
import 'package:in_phase/src/logger/logger.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as p;
import 'package:rekorddart/rekorddart.dart';
import 'package:tilde_expansion/tilde_expansion.dart';

class LibrarySyncEngineCommand extends Command<int> {
  LibrarySyncEngineCommand() {
    argParser
      ..addFlag(
        'dry-run',
        help: 'Print a change report without writing to the Engine database.',
        negatable: false,
      )
      ..addFlag(
        'prune',
        help:
            'Remove Engine tracks and playlists that are absent from '
            'Rekordbox. Use --no-prune to only add and update.',
        defaultsTo: true,
      )
      ..addFlag(
        'memory-cues-to-hot-cues',
        help:
            'Spill memory cues into empty hot cue slots (Engine has no '
            'memory cue concept).',
        negatable: false,
      )
      ..addOption(
        'config',
        abbr: 'c',
        help: 'Path to the engine sync config file.',
      );
  }

  @override
  final String name = 'engine';

  @override
  final String description =
      'Syncs the Rekordbox library (tracks, beat grids, cues, loops, '
      'playlists) one-way into the Engine DJ desktop library.';

  @override
  Future<int> run() async {
    final args = argResults!;
    final dryRun = args['dry-run'] == true;

    final configFile = args['config'] != null
        ? resolveConfigPath(args['config'] as String)
        : Constants.engineSyncConfigFile;
    final config = await EngineSyncConfig.fromFile(configFile);

    final prune = args.wasParsed('prune')
        ? args['prune'] == true
        : config.prune;
    final memoryCuesToHotCues =
        args['memory-cues-to-hot-cues'] == true || config.memoryCuesToHotCues;

    // Locate Rekordbox.
    final rekordboxConfig = getMostRecentRekordboxConfig();
    if (rekordboxConfig == null || !rekordboxConfig.dbExists) {
      log.error('No Rekordbox database found. Is Rekordbox installed?');
      return ExitCode.unavailable.code;
    }
    final anlzRootPath =
        config.anlzRootPath?.expandUser() ??
        p.join(rekordboxConfig.dbDir, 'share');

    // Locate the Engine library.
    final engineLibraryPath =
        config.engineLibraryPath?.expandUser() ??
        defaultEngineLibraryPath(Constants.userHomeDirectory);
    final databasePath = engineDatabasePath(engineLibraryPath);
    if (!File(databasePath).existsSync()) {
      log.error(
        'No Engine database found at $databasePath. Launch Engine DJ once '
        'to create the library, or set engine_library_path in '
        '${configFile.path}.',
      );
      return ExitCode.unavailable.code;
    }

    // Never write while either application is running.
    if (await checkIsEngineDjRunning()) {
      log.error('Engine DJ is running. Please close it before syncing.');
      return ExitCode.tempFail.code;
    }

    return withTeardown((addTeardown) async {
      log.info('Reading Rekordbox library...');
      final rekordboxDb = await RekordboxDatabase.connect();
      addTeardown(rekordboxDb.close);
      final library = await readRekordboxLibrary(
        rekordboxDb,
        anlzRootPath: anlzRootPath,
      );
      log.info(
        '${library.tracks.length} track(s) and '
        '${library.playlistTree.length} root playlist item(s) found.',
      );

      if (!dryRun) {
        final backupPath = await backupEngineDatabase(databasePath);
        log.info('Backed up Engine database to $backupPath');
      }

      final engineDb = EngineDatabase.open(databasePath, readOnly: dryRun);
      addTeardown(engineDb.close);
      log.debug(
        'Engine database schema '
        '${engineDb.schemaVersion.$1}.${engineDb.schemaVersion.$2}'
        '.${engineDb.schemaVersion.$3} (uuid ${engineDb.uuid})',
      );

      final result = await runEngineSync(
        library: library,
        engineDb: engineDb,
        engineLibraryPath: engineLibraryPath,
        rekordboxShareRoot: anlzRootPath,
        dryRun: dryRun,
        prune: prune,
        memoryCuesToHotCues: memoryCuesToHotCues,
        syncArt: config.syncArt,
      );

      _logSyncSummary(
        dryRun: dryRun,
        sourceTrackCount: library.tracks.length,
        syncArt: config.syncArt,
        result: result,
      );

      return ExitCode.success.code;
    });
  }
}

void _logSyncSummary({
  required bool dryRun,
  required int sourceTrackCount,
  required bool syncArt,
  required EngineSyncResult result,
}) {
  final verb = dryRun ? 'Would sync' : 'Synced';
  log
    ..info('')
    ..info(dryRun ? 'Dry run — no changes were made.' : '✅ Sync complete.')
    ..info('$verb $sourceTrackCount track(s) from Rekordbox:')
    ..info('  ${result.tracksAdded} new — inserted into Engine')
    ..info(
      '  ${result.tracksUpdated} rewritten — metadata and/or performance '
      'data changed (beat grid, cues, loops, BPM, etc.)',
    )
    ..info(
      '  ${result.tracksUnchanged} up to date — already matched Rekordbox, '
      'no track write',
    );
  if (result.tracksPruned > 0) {
    log.info('  ${result.tracksPruned} pruned — removed from Engine');
  }
  if (result.tracksSkipped > 0) {
    log.info(
      '  ${result.tracksSkipped} skipped — duplicate audio path in Rekordbox',
    );
  }
  log.info(
    'Beat grids: ${result.tracksWithBeatGrid} of $sourceTrackCount source '
    'track(s) have a Rekordbox grid; '
    '${result.beatGridsWritten} ${dryRun ? 'would be ' : ''}'
    'written this run.',
  );
  if (syncArt) {
    log.info(
      'Artwork: ${result.tracksWithArtwork} of $sourceTrackCount source '
      'track(s) have a resolvable Rekordbox image; '
      '${result.artworkWritten} unique ${dryRun ? 'would be ' : ''}'
      'imported this run.',
    );
  } else {
    log.info('Artwork: skipped (sync_art: false in config).');
  }
  log.info(
    'Playlists: $verb ${result.playlistsSynced} playlist(s) and '
    '${result.foldersSynced} folder(s) (${result.playlistEntries} track '
    'entries${result.playlistsPruned ? ', tree mirrored' : ''}).',
  );
}

/// Copies the Engine database (and any WAL/SHM sidecar files) into a
/// timestamped backup directory. Returns the backup directory path.
Future<String> backupEngineDatabase(String databasePath) async {
  final timestamp = DateTime.now()
      .toIso8601String()
      .replaceAll(':', '-')
      .split('.')
      .first;
  final backupDir = Directory(
    p.join(Constants.engineSyncBackupsDir.path, timestamp),
  );
  await backupDir.create(recursive: true);

  for (final suffix in ['', '-wal', '-shm']) {
    final source = File('$databasePath$suffix');
    // ignore: avoid_slow_async_io
    if (await source.exists()) {
      await source.copy(p.join(backupDir.path, p.basename(source.path)));
    }
  }
  return backupDir.path;
}
