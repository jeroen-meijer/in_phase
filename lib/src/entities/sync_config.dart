import 'dart:io';

import 'package:glob/glob.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:rkdb_dart/src/misc/misc.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_codec/yaml_codec.dart';

part 'sync_config.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class SyncConfig {
  const SyncConfig({
    required this.playlists,
    required this.folders,
    required this.overwriteSongKeys,
  });

  const SyncConfig.empty()
    : this(
        playlists: const [],
        folders: const {},
        overwriteSongKeys: false,
      );

  factory SyncConfig.fromJson(Map<String, dynamic> json) =>
      _$SyncConfigFromJson(json);

  Map<String, dynamic> toJson() => _$SyncConfigToJson(this);

  static Future<SyncConfig> fromFile(
    File file, {
    bool createFileIfNotExists = true,
  }) async {
    // ignore: avoid_slow_async_io
    if (!await file.exists()) {
      if (createFileIfNotExists) {
        await file.create(recursive: true);
        const config = SyncConfig.empty();
        await config.write(file);
        return config;
      } else {
        throw Exception('Sync config file not found at ${file.path}');
      }
    }

    final content = await file.readAsString();
    final yaml = yamlDecode(content) as YamlMap;
    return SyncConfig.fromJson(yaml.toMap());
  }

  Future<void> write(File file) async {
    await file.create(recursive: true);
    await file.writeAsString(yamlEncode(toJson()));
  }

  @JsonKey(fromJson: _globListFromJson, toJson: _globListToJson)
  final List<Glob> playlists;

  final Map<String, SyncConfigFolder> folders;

  final bool overwriteSongKeys;
}

@JsonSerializable()
class SyncConfigFolder {
  const SyncConfigFolder({
    required this.playlists,
  });

  factory SyncConfigFolder.fromJson(Map<String, dynamic> json) =>
      _$SyncConfigFolderFromJson(json);

  Map<String, dynamic> toJson() => _$SyncConfigFolderToJson(this);

  @JsonKey(fromJson: _globListFromJson, toJson: _globListToJson)
  final List<Glob> playlists;
}

List<Glob> _globListFromJson(List<dynamic> json) =>
    json.map((e) => Glob(e as String)).toList();

List<dynamic> _globListToJson(List<Glob> data) =>
    data.map((e) => e.pattern).toList();
