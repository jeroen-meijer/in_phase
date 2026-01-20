import 'dart:io';

import 'package:in_phase/src/misc/misc.dart';

/// Ensures that default configuration files exist.
///
/// If config files don't exist, creates them with default content.
/// This runs on every command startup to ensure users have working configs.
Future<void> ensureDefaultConfigs() async {
  final appDataDir = Constants.appDataDir;
  final appDataDirPath = appDataDir.path;

  // Check if .in_phase exists as a file (not a directory) and remove it
  if (await File(appDataDirPath).exists()) {
    final entityType = await FileSystemEntity.type(appDataDirPath);
    if (entityType != FileSystemEntityType.directory) {
      await File(appDataDirPath).delete();
    }
  }

  // Ensure app data directory exists
  if (!await appDataDir.exists()) {
    await appDataDir.create(recursive: true);
  }

  // Initialize sync config if it doesn't exist
  final syncConfigFile = Constants.syncConfigFile;
  if (!await syncConfigFile.exists()) {
    await syncConfigFile.create(recursive: true);
    await syncConfigFile.writeAsString(DefaultConfigs.syncConfig);
  }

  // Initialize crawl config if it doesn't exist
  final crawlConfigFile = Constants.crawlConfigFile;
  if (!await crawlConfigFile.exists()) {
    await crawlConfigFile.create(recursive: true);
    await crawlConfigFile.writeAsString(DefaultConfigs.crawlConfig);
  }
}
