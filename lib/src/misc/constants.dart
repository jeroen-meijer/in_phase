import 'dart:io';

import 'package:path/path.dart' as path;

class Constants {
  static const appName = 'InPhase';
  static const version = '1.0.1';

  static final appDataDir = File(path.join(_getUserDir(), '.in_phase'));

  static final cacheFile = File(path.join(appDataDir.path, '.in_phase_cache'));
  static final cacheDbFile = File(path.join(appDataDir.path, 'cache.db'));

  static final syncConfigFile = File(
    path.join(appDataDir.path, 'sync_config.yaml'),
  );

  static final syncCacheFile = File(
    path.join(appDataDir.path, 'sync_cache.yaml'),
  );

  static final crawlConfigFile = File(
    path.join(appDataDir.path, 'crawl_config.yaml'),
  );

  static final crawlCacheFile = File(
    path.join(appDataDir.path, 'crawl_cache.yaml'),
  );

  static final buildDir = Directory(
    path.join(appDataDir.path, 'build'),
  );

  static final generatedCoversDir = Directory(
    path.join(buildDir.path, 'generated_covers'),
  );
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
