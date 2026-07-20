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

  await _ensureConfig(Constants.syncConfigFile, DefaultConfigs.syncConfig);
  await _ensureConfig(Constants.crawlConfigFile, DefaultConfigs.crawlConfig);
  await _ensureConfig(Constants.curateConfigFile, DefaultConfigs.curateConfig);
  await _ensureConfig(
    Constants.collectConfigFile,
    DefaultConfigs.collectConfig,
  );
  await _ensureConfig(
    Constants.engineSyncConfigFile,
    DefaultConfigs.engineSyncConfig,
  );
}

Future<void> _ensureConfig(File file, String defaultContent) async {
  if (!await file.exists()) {
    await file.create(recursive: true);
    await file.writeAsString(defaultContent);
  }
}
