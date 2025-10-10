import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'package:rkdb_dart/src/misc/misc.dart';
import 'package:rkdb_dart/src/spotify/spotify.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_codec/yaml_codec.dart';

part 'sync_cache.g.dart';

extension type const RekordboxSongId(String value) implements String {}

@JsonSerializable(fieldRename: FieldRename.snake)
class SyncCache {
  const SyncCache({
    required this.mappings,
    required this.missingTracks,
    required this.playlists,
  });

  const SyncCache.empty()
    : this(
        mappings: const {},
        missingTracks: const {},
        playlists: const {},
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

  @JsonKey(
    fromJson: _cachedPlaylistsFromJson,
    toJson: _cachedPlaylistsToJson,
  )
  final Map<SpotifyPlaylistId, CachedSyncPlaylist> playlists;

  /// Checks if a playlist has changed by comparing snapshot IDs.
  bool isPlaylistChanged(SpotifyPlaylistId playlistId, String snapshotId) {
    final cached = playlists[playlistId];
    if (cached == null) return true;
    return cached.snapshotId != snapshotId;
  }

  /// Updates the cache with a new/updated playlist.
  SyncCache withPlaylist(
    SpotifyPlaylistId playlistId,
    CachedSyncPlaylist playlist,
  ) {
    return SyncCache(
      mappings: mappings,
      missingTracks: missingTracks,
      playlists: {...playlists, playlistId: playlist},
    );
  }
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

/// Cached playlist data for sync command.
@JsonSerializable(fieldRename: FieldRename.snake)
class CachedSyncPlaylist {
  const CachedSyncPlaylist({
    required this.snapshotId,
    required this.name,
    required this.tracks,
    required this.cachedAt,
  });

  factory CachedSyncPlaylist.fromJson(Map<String, dynamic> json) =>
      _$CachedSyncPlaylistFromJson(json);

  Map<String, dynamic> toJson() => _$CachedSyncPlaylistToJson(this);

  final String snapshotId;
  final String name;

  @JsonKey(fromJson: _cachedTracksFromJson, toJson: _cachedTracksToJson)
  final List<CachedSyncTrack> tracks;

  final DateTime cachedAt;
}

/// Cached track data for sync command.
@JsonSerializable(fieldRename: FieldRename.snake)
class CachedSyncTrack {
  const CachedSyncTrack({
    required this.id,
    required this.name,
    required this.artistNames,
  });

  factory CachedSyncTrack.fromJson(Map<String, dynamic> json) =>
      _$CachedSyncTrackFromJson(json);

  Map<String, dynamic> toJson() => _$CachedSyncTrackToJson(this);

  @JsonKey(fromJson: _spotifyTrackIdFromJson, toJson: _spotifyTrackIdToJson)
  final SpotifyTrackId id;

  final String name;
  final List<String> artistNames;
}

List<CachedSyncTrack> _cachedTracksFromJson(List<dynamic> json) => json
    .map((e) => CachedSyncTrack.fromJson(e as Map<String, dynamic>))
    .toList();

List<Map<String, dynamic>> _cachedTracksToJson(List<CachedSyncTrack> tracks) =>
    tracks.map((e) => e.toJson()).toList();

SpotifyTrackId _spotifyTrackIdFromJson(Object json) =>
    SpotifyTrackId(json as String);

String _spotifyTrackIdToJson(SpotifyTrackId id) => id.toString();

Map<SpotifyTrackId, RekordboxSongId> _trackMappingFromJson(
  Map<dynamic, dynamic> json,
) => json.map(
  (key, value) =>
      MapEntry(SpotifyTrackId(key as String), RekordboxSongId(value as String)),
);

Map<String, dynamic> _trackMappingToJson(
  Map<SpotifyTrackId, RekordboxSongId> data,
) => data.map((key, value) => MapEntry(key.toString(), value.toString()));

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
) => data.map((key, value) => MapEntry(key.toString(), value.toJson()));

Map<SpotifyPlaylistId, CachedSyncPlaylist> _cachedPlaylistsFromJson(
  Map<dynamic, dynamic> json,
) => json.map(
  (key, value) => MapEntry(
    SpotifyPlaylistId(key as String),
    CachedSyncPlaylist.fromJson(value as Map<String, dynamic>),
  ),
);

Map<String, dynamic> _cachedPlaylistsToJson(
  Map<SpotifyPlaylistId, CachedSyncPlaylist> data,
) => data.map((key, value) => MapEntry(key.toString(), value.toJson()));
