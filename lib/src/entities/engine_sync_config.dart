import 'dart:io';

import 'package:in_phase/src/misc/misc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_codec/yaml_codec.dart';

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

  /// Parses [content] as YAML and deserializes an [EngineSyncConfig].
  factory EngineSyncConfig.fromYamlString(String content) {
    final decoded = yamlDecode(content);
    if (decoded == null) return const EngineSyncConfig.empty();
    if (decoded is! YamlMap) {
      throw const FormatException('Expected YAML map at the root');
    }
    return EngineSyncConfig.fromJson(decoded.toMap());
  }

  Map<String, dynamic> toJson() => _$EngineSyncConfigToJson(this);

  static Future<EngineSyncConfig> fromFile(
    File file, {
    bool createFileIfNotExists = true,
  }) async {
    // ignore: avoid_slow_async_io
    if (!await file.exists()) {
      if (createFileIfNotExists) {
        await file.create(recursive: true);
        const config = EngineSyncConfig.empty();
        await config.write(file);
        return config;
      } else {
        throw Exception('Engine sync config file not found at ${file.path}');
      }
    }

    final content = await file.readAsString();
    return EngineSyncConfig.fromYamlString(content);
  }

  Future<void> write(File file) async {
    await file.create(recursive: true);
    await file.writeAsString(yamlEncode(toJson()));
  }

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
