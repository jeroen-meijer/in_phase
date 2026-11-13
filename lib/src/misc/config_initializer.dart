import 'dart:io';

import 'package:in_phase/src/misc/misc.dart';

/// Ensures that default configuration files exist.
///
/// If config files don't exist, creates them with default content.
/// This runs on every command startup to ensure users have working configs.
Future<void> ensureDefaultConfigs() async {
  final appDataDir = Constants.appDataDir;
  final existingType = await FileSystemEntity.type(appDataDir.path);
  if (existingType != FileSystemEntityType.notFound &&
      existingType != FileSystemEntityType.directory) {
    throw FileSystemException(
      'Expected a folder for InPhase settings, but found a file. Move or '
      'rename it and run the command again',
      appDataDir.path,
    );
  }
  await appDataDir.create(recursive: true);

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
