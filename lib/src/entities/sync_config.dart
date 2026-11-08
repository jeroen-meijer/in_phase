import 'dart:io';

import 'package:glob/glob.dart';
import 'package:in_phase/src/entities/entities.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:in_phase/src/spotify/spotify.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sync_config.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class SyncConfig {
  const SyncConfig({
    required this.playlists,
    required this.folders,
    required this.overwriteSongKeys,
    required this.customTracks,
  });

  const SyncConfig.empty()
    : this(
        playlists: const [],
        folders: const {},
        overwriteSongKeys: false,
        customTracks: const {},
      );

  factory SyncConfig.fromJson(Map<String, dynamic> json) =>
      _$SyncConfigFromJson(json);

  /// Parses [content] as YAML and deserializes a [SyncConfig].
  ///
  /// Throws if YAML is invalid, if the root value is not a map, or if the data
  /// does not match the sync config schema (same rules as `fromJson`).
  factory SyncConfig.fromYamlString(String content) => parseYamlConfig(
    content,
    fromJson: SyncConfig.fromJson,
    defaults: const SyncConfig.empty(),
  );

  Map<String, dynamic> toJson() => _$SyncConfigToJson(this);

  static Future<SyncConfig> fromFile(File file) => readYamlConfig(
    file,
    fromJson: SyncConfig.fromJson,
    defaults: const SyncConfig.empty(),
  );

  /// Every [CustomTrack.rekordboxId] and [CustomTrack.target] in
  /// [customTracks].
  Set<RekordboxSongId> get referencedCustomTrackRekordboxIds {
    final ids = <RekordboxSongId>{};
    for (final t in customTracks.values.expand((list) => list)) {
      ids.add(t.rekordboxId);
      if (t.target != null) {
        ids.add(t.target!);
      }
    }
    return ids;
  }

  @JsonKey(fromJson: _globListFromJson, toJson: _globListToJson)
  final List<Glob> playlists;

  final Map<String, SyncConfigFolder> folders;

  final bool overwriteSongKeys;

  @JsonKey(fromJson: _customTracksFromJson, toJson: _customTracksToJson)
  final Map<SpotifyPlaylistId, List<CustomTrack>> customTracks;
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

/// Type of custom track operation.
enum CustomTrackType {
  insert,
  replace,
}

/// Custom track configuration for syncing playlists.
@JsonSerializable(fieldRename: FieldRename.snake)
class CustomTrack {
  CustomTrack({
    required this.rekordboxId,
    this.type = CustomTrackType.insert,
    this.index,
    this.position,
    this.target,
  }) {
    // Validate that only one of index OR position is specified (not both)
    // But target can be combined with either index or position
    final hasIndex = index != null;
    final hasPosition = position != null;

    if (hasIndex && hasPosition) {
      throw ArgumentError(
        'Cannot specify both index and position. Use either index (0-based) '
        'or position (1-based) for track $rekordboxId.',
      );
    }
  }

  factory CustomTrack.fromJson(Map<String, dynamic> json) =>
      _$CustomTrackFromJson(json);

  Map<String, dynamic> toJson() => _$CustomTrackToJson(this);

  @JsonKey(fromJson: _rekordboxSongIdFromJson, toJson: _rekordboxSongIdToJson)
  final RekordboxSongId rekordboxId;

  final CustomTrackType type;

  /// 0-based index for positioning.
  final int? index;

  /// 1-based position for positioning (converted to 0-based index internally).
  final int? position;

  /// Target Rekordbox track ID for relative positioning.
  @JsonKey(
    fromJson: _nullableRekordboxSongIdFromJson,
    toJson: _nullableRekordboxSongIdToJson,
  )
  final RekordboxSongId? target;
}

RekordboxSongId _rekordboxSongIdFromJson(Object json) => switch (json) {
  num() || String() => RekordboxSongId(json.toString()),
  _ => throw ArgumentError(
    'Invalid Rekordbox song ID: $json. Expected a number or string.',
  ),
};

String _rekordboxSongIdToJson(RekordboxSongId id) => id.toString();

RekordboxSongId? _nullableRekordboxSongIdFromJson(Object? json) =>
    json == null ? null : _rekordboxSongIdFromJson(json);

String? _nullableRekordboxSongIdToJson(RekordboxSongId? id) =>
    id == null ? null : _rekordboxSongIdToJson(id);

Map<SpotifyPlaylistId, List<CustomTrack>> _customTracksFromJson(
  Map<dynamic, dynamic>? json,
) {
  if (json == null) return {};

  return json.map(
    (key, value) => MapEntry(
      SpotifyPlaylistId(key as String),
      (value as List<dynamic>)
          .map((e) => CustomTrack.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
}

Map<String, dynamic> _customTracksToJson(
  Map<SpotifyPlaylistId, List<CustomTrack>> data,
) => data.map(
  (key, value) => MapEntry(
    key.toString(),
    value.map((e) => e.toJson()).toList(),
  ),
);
