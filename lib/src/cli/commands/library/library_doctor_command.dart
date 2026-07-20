import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';
import 'package:in_phase/src/entities/entities.dart';
import 'package:in_phase/src/library/library.dart';
import 'package:in_phase/src/logger/logger.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as p;
import 'package:rekorddart/rekorddart.dart';
import 'package:tilde_expansion/tilde_expansion.dart';

class LibraryDoctorCommand extends Command<int> {
  @override
  final String name = 'doctor';

  @override
  final String description =
      'Checks that Rekordbox and Engine DJ libraries are ready for syncing.';

  @override
  Future<int> run() async {
    var healthy = true;

    void check(String label, {required bool ok, String? detail}) {
      final mark = ok ? green('✓') : red('✗');
      log.info('$mark $label${detail != null ? ' — $detail' : ''}');
      if (!ok) healthy = false;
    }

    final config = await EngineSyncConfig.fromFile(
      Constants.engineSyncConfigFile,
    );

    // Rekordbox.
    final rekordboxConfig = getMostRecentRekordboxConfig();
    check(
      'Rekordbox installation found',
      ok: rekordboxConfig != null,
      detail: rekordboxConfig?.dbDir,
    );
    if (rekordboxConfig != null) {
      check(
        'Rekordbox database exists',
        ok: rekordboxConfig.dbExists,
        detail: rekordboxConfig.dbPath,
      );

      final anlzRootPath =
          config.anlzRootPath?.expandUser() ??
          p.join(rekordboxConfig.dbDir, 'share');
      check(
        'Rekordbox analysis (ANLZ) directory exists',
        ok: Directory(anlzRootPath).existsSync(),
        detail: anlzRootPath,
      );
    }

    final rekordboxRunning = await checkIsRekordboxRunning();
    check(
      'Rekordbox is not running',
      ok: !rekordboxRunning,
      detail: rekordboxRunning ? 'close it before syncing' : null,
    );

    // Engine DJ.
    final engineLibraryPath =
        config.engineLibraryPath?.expandUser() ??
        defaultEngineLibraryPath(Constants.userHomeDirectory);
    final databasePath = engineDatabasePath(engineLibraryPath);
    check(
      'Engine database exists',
      ok: File(databasePath).existsSync(),
      detail: databasePath,
    );

    if (File(databasePath).existsSync()) {
      try {
        final engineDb = EngineDatabase.open(databasePath, readOnly: true);
        check(
          'Engine database schema is supported',
          ok: true,
          detail:
              'schema ${engineDb.schemaVersion.$1}'
              '.${engineDb.schemaVersion.$2}.${engineDb.schemaVersion.$3}, '
              'uuid ${engineDb.uuid}',
        );
        engineDb.close();
      } on Exception catch (e) {
        check('Engine database schema is supported', ok: false, detail: '$e');
      }
    }

    final engineRunning = await checkIsEngineDjRunning();
    check(
      'Engine DJ is not running',
      ok: !engineRunning,
      detail: engineRunning ? 'close it before syncing' : null,
    );

    log.info('');
    if (healthy) {
      log.info('✅ All checks passed. Ready to sync.');
      return ExitCode.success.code;
    } else {
      log.error('Some checks failed. Fix the issues above before syncing.');
      return ExitCode.unavailable.code;
    }
  }
}
