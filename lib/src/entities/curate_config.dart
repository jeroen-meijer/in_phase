import 'dart:io';

import 'package:in_phase/src/misc/misc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_codec/yaml_codec.dart';

part 'curate_config.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class CurateConfig {
  const CurateConfig({
    required this.startPosition,
    required this.seekStep,
    required this.targets,
    this.nextAfterAdd = false,
    this.autoAddToLikes = false,
  });

  const CurateConfig.empty()
    : this(
        startPosition: '1:15',
        seekStep: 15,
        targets: const [],
        nextAfterAdd: false,
        autoAddToLikes: false,
      );

  factory CurateConfig.fromJson(Map<String, dynamic> json) =>
      _$CurateConfigFromJson(json);

  Map<String, dynamic> toJson() => _$CurateConfigToJson(this);

  static Future<CurateConfig> fromFile(
    File file, {
    bool createFileIfNotExists = true,
  }) async {
    // ignore: avoid_slow_async_io
    if (!await file.exists()) {
      if (createFileIfNotExists) {
        await file.create(recursive: true);
        const config = CurateConfig.empty();
        await config.write(file);
        return config;
      } else {
        throw Exception('Curate config file not found at ${file.path}');
      }
    }

    final content = await file.readAsString();
    final yaml = yamlDecode(content) as YamlMap;
    return CurateConfig.fromJson(yaml.toMap());
  }

  Future<void> write(File file) async {
    await file.create(recursive: true);
    await file.writeAsString(yamlEncode(toJson()));
  }

  /// Parsed start position in milliseconds.
  int get startPositionMs =>
      parsePositionToMs(startPosition) ?? 75000; // default 1:15

  @JsonKey(name: 'start_position', defaultValue: '1:15')
  final String startPosition;

  @JsonKey(name: 'seek_step', defaultValue: 15)
  final int seekStep;

  /// When true, advance to next track after adding to one playlist. When false,
  /// stay so the user can add to multiple playlists before continuing.
  @JsonKey(name: 'next_after_add', defaultValue: false)
  final bool nextAfterAdd;

  /// When true, also save the track to Liked Songs whenever you add it to a
  /// target playlist (keys 1–9). The "liked" line is only shown when the track
  /// was not already in Liked Songs before that add.
  @JsonKey(name: 'auto_add_to_likes', defaultValue: false)
  final bool autoAddToLikes;

  /// Playlist identifiers resolved at session start (ID, URI, URL, or name).
  @JsonKey(fromJson: _targetsFromJson, toJson: _targetsToJson)
  final List<String> targets;
}

List<String> _targetsFromJson(dynamic json) {
  if (json == null || json is! List) {
    return [];
  }
  return json.map((e) {
    if (e is String) {
      return e;
    }
    if (e is Map) {
      throw const FormatException(
        'curate targets must be a list of strings (playlist ID, URI, URL, or '
        'name). The old {id, name} object format is no longer supported.',
      );
    }
    throw FormatException(
      'curate targets must be strings; got ${e.runtimeType}',
    );
  }).toList();
}

List<String> _targetsToJson(List<String> data) => data;
