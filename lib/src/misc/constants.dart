import 'dart:io';

import 'package:path/path.dart' as path;

class Constants {
  static const appName = 'rkdb';
  static const version = '1.0.0';

  static final appDataDir = File(path.join(_getUserDir(), '.rkdb'));

  static final cacheFile = File(path.join(appDataDir.path, '.rkdb_cache'));

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
