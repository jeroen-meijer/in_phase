import 'dart:io';

import 'package:in_phase/src/misc/misc.dart';
import 'package:json_annotation/json_annotation.dart';

part 'engine_sync_config.g.dart';

/// Configuration for `in_phase library sync engine`.
@JsonSerializable(fieldRename: FieldRename.snake)
class EngineSyncConfig {
  const EngineSyncConfig({
    this.engineLibraryPath,
    this.anlzRootPath,
    this.prune = true,
    this.memoryCuesToHotCues = false,
    this.syncArt = true,
  });

  const EngineSyncConfig.empty() : this();

  factory EngineSyncConfig.fromJson(Map<String, dynamic> json) =>
      _$EngineSyncConfigFromJson(json);

  Map<String, dynamic> toJson() => _$EngineSyncConfigToJson(this);

  static Future<EngineSyncConfig> fromFile(File file) => readYamlConfig(
    file,
    fromJson: EngineSyncConfig.fromJson,
    defaults: const EngineSyncConfig.empty(),
  );

  /// Engine Library directory. Defaults to `~/Music/Engine Library`.
  final String? engineLibraryPath;

  /// Rekordbox analysis share directory containing `PIONEER/`.
  /// Defaults to `<rekordbox db dir>/share`.
  final String? anlzRootPath;

  /// Whether to remove Engine tracks and playlists that are absent from
  /// Rekordbox, making Engine an exact mirror.
  final bool prune;

  /// Whether to spill memory cues into empty hot cue slots.
  final bool memoryCuesToHotCues;

  /// Whether to sync album artwork from Rekordbox into Engine.
  final bool syncArt;
}
