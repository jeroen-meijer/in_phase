import 'dart:io';

import 'package:path/path.dart' as path;

class Constants {
  static const appName = 'InPhase';
  static const packageName = 'in_phase';
  static const commandName = 'in_phase';
  static const version = '1.5.1';

  static final appDataDir = Directory(path.join(_getUserDir(), '.in_phase'));

  static final cacheFile = File(path.join(appDataDir.path, '.in_phase_cache'));
  static final cacheDbFile = File(path.join(appDataDir.path, 'cache.db'));

  static final syncConfigFile = File(
    path.join(appDataDir.path, 'sync_config.yaml'),
  );

  static final crawlConfigFile = File(
    path.join(appDataDir.path, 'crawl_config.yaml'),
  );

  static final curateConfigFile = File(
    path.join(appDataDir.path, 'curate_config.yaml'),
  );

  static final collectConfigFile = File(
    path.join(appDataDir.path, 'collect_config.yaml'),
  );

  static final engineSyncConfigFile = File(
    path.join(appDataDir.path, 'engine_sync_config.yaml'),
  );

  static final engineSyncBackupsDir = Directory(
    path.join(buildDir.path, 'engine_sync_backups'),
  );

  static final buildDir = Directory(
    path.join(appDataDir.path, 'build'),
  );

  static final generatedCoversDir = Directory(
    path.join(buildDir.path, 'generated_covers'),
  );

  /// User home directory (for CLI path expansion, e.g. `~/foo`).
  static String get userHomeDirectory => _getUserDir();
}

String _getUserDir() {
  String? home;
  if (Platform.isMacOS) {
    home = Platform.environment['HOME'];
  } else if (Platform.isLinux) {
    home = Platform.environment['HOME'];
  } else if (Platform.isWindows) {
    home = Platform.environment['UserProfile'];
  }

  return home ??
      (throw UnsupportedError(
        'Unsupported platform or missing '
        'home environment variable: ${Platform.operatingSystem}',
      ));
}
