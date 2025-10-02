import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'package:rkdb_dart/src/misc/misc.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_codec/yaml_codec.dart';

part 'sync_cache.g.dart';

extension type const SpotifyTrackId(String value) implements String {}

extension type const RekordboxSongId(String value) implements String {}

@JsonSerializable(fieldRename: FieldRename.snake)
class SyncCache {
  const SyncCache({
    required this.mappings,
    required this.missingTracks,
  });

  const SyncCache.empty()
    : this(
        mappings: const {},
        missingTracks: const {},
      );

  factory SyncCache.fromJson(Map<String, dynamic> json) =>
      _$SyncCacheFromJson(json);

  Map<String, dynamic> toJson() => _$SyncCacheToJson(this);

  static Future<SyncCache> fromFile(
    File file, {
    bool createFileIfNotExists = true,
  }) async {
    // ignore: avoid_slow_async_io
    if (!await file.exists()) {
      if (createFileIfNotExists) {
        await file.create(recursive: true);
        const cache = SyncCache.empty();
        await cache.write(file);
        return cache;
      } else {
        throw Exception('Sync cache file not found at ${file.path}');
      }
    }

    final content = await file.readAsString();
    final yaml = yamlDecode(content) as YamlMap;
    return SyncCache.fromJson(yaml.toMap());
  }

  Future<void> write(File file) async {
    await file.create(recursive: true);
    await file.writeAsString(yamlEncode(toJson()));
  }

  @JsonKey(fromJson: _trackMappingFromJson, toJson: _trackMappingToJson)
  final Map<SpotifyTrackId, RekordboxSongId> mappings;

  @JsonKey(fromJson: _missingTracksFromJson, toJson: _missingTracksToJson)
  final Map<SpotifyTrackId, MissingTrack> missingTracks;
}

@JsonSerializable(fieldRename: FieldRename.snake)
class MissingTrack {
  const MissingTrack({
    required this.id,
    required this.artist,
    required this.title,
    required this.itunesUrl,
    required this.lastInsertedAt,
  });

  factory MissingTrack.fromJson(Map<String, dynamic> json) =>
      _$MissingTrackFromJson(json);

  Map<String, dynamic> toJson() => _$MissingTrackToJson(this);

  final SpotifyTrackId id;
  final String artist;
  final String title;
  final String? itunesUrl;
  final DateTime lastInsertedAt;
}

Map<SpotifyTrackId, RekordboxSongId> _trackMappingFromJson(
  Map<dynamic, dynamic> json,
) => json.map(
  (key, value) =>
      MapEntry(SpotifyTrackId(key as String), RekordboxSongId(value as String)),
);

Map<String, dynamic> _trackMappingToJson(
  Map<SpotifyTrackId, RekordboxSongId> data,
) => data.map((key, value) => MapEntry(key.value, value.value));

Map<SpotifyTrackId, MissingTrack> _missingTracksFromJson(
  Map<dynamic, dynamic> json,
) => json.map(
  (key, value) => MapEntry(
    SpotifyTrackId(key as String),
    MissingTrack.fromJson(value as Map<String, dynamic>),
  ),
);

Map<String, dynamic> _missingTracksToJson(
  Map<SpotifyTrackId, MissingTrack> data,
) => data.map((key, value) => MapEntry(key.value, value.toJson()));
