import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'package:rkdb_dart/src/misc/misc.dart';
import 'package:rkdb_dart/src/spotify/spotify.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_codec/yaml_codec.dart';

part 'crawl_cache.g.dart';

/// Cache for crawl command to reduce API calls.
@JsonSerializable(fieldRename: FieldRename.snake)
class CrawlCache {
  const CrawlCache({
    required this.playlists,
    required this.albums,
    required this.trackAlbumMappings,
    required this.metadata,
  });

  const CrawlCache.empty()
    : this(
        playlists: const {},
        albums: const {},
        trackAlbumMappings: const {},
        metadata: const CrawlCacheMetadata.empty(),
      );

  factory CrawlCache.fromJson(Map<String, dynamic> json) =>
      _$CrawlCacheFromJson(json);

  Map<String, dynamic> toJson() => _$CrawlCacheToJson(this);

  static Future<CrawlCache> fromFile(
    File file, {
    bool createFileIfNotExists = true,
  }) async {
    // ignore: avoid_slow_async_io
    if (!await file.exists()) {
      if (createFileIfNotExists) {
        await file.create(recursive: true);
        const cache = CrawlCache.empty();
        await cache.write(file);
        return cache;
      } else {
        throw Exception('Crawl cache file not found at ${file.path}');
      }
    }

    final content = await file.readAsString();
    final yaml = yamlDecode(content) as YamlMap;
    return CrawlCache.fromJson(yaml.toMap());
  }

  Future<void> write(File file) async {
    await file.create(recursive: true);
    await file.writeAsString(yamlEncode(toJson()));
  }

  @JsonKey(fromJson: _playlistMapFromJson, toJson: _playlistMapToJson)
  final Map<SpotifyPlaylistId, CachedPlaylist> playlists;

  @JsonKey(fromJson: _albumMapFromJson, toJson: _albumMapToJson)
  final Map<SpotifyAlbumId, CachedAlbum> albums;

  @JsonKey(fromJson: _trackAlbumMapFromJson, toJson: _trackAlbumMapToJson)
  final Map<SpotifyTrackId, SpotifyAlbumId> trackAlbumMappings;

  final CrawlCacheMetadata metadata;

  /// Returns a new cache with updated metadata timestamp.
  CrawlCache withUpdatedMetadata() {
    return CrawlCache(
      playlists: playlists,
      albums: albums,
      trackAlbumMappings: trackAlbumMappings,
      metadata: CrawlCacheMetadata(
        created: metadata.created,
        lastUpdated: DateTime.now(),
      ),
    );
  }

  /// Returns a new cache with an additional playlist.
  CrawlCache withPlaylist(
    SpotifyPlaylistId playlistId,
    CachedPlaylist playlist,
  ) {
    return CrawlCache(
      playlists: {...playlists, playlistId: playlist},
      albums: albums,
      trackAlbumMappings: trackAlbumMappings,
      metadata: metadata,
    );
  }

  /// Returns a new cache with additional albums.
  CrawlCache withAlbums(Map<SpotifyAlbumId, CachedAlbum> newAlbums) {
    return CrawlCache(
      playlists: playlists,
      albums: {...albums, ...newAlbums},
      trackAlbumMappings: trackAlbumMappings,
      metadata: metadata,
    );
  }

  /// Returns a new cache with additional track-album mappings.
  CrawlCache withTrackAlbumMappings(
    Map<SpotifyTrackId, SpotifyAlbumId> newMappings,
  ) {
    return CrawlCache(
      playlists: playlists,
      albums: albums,
      trackAlbumMappings: {...trackAlbumMappings, ...newMappings},
      metadata: metadata,
    );
  }

  /// Checks if a playlist has changed by comparing snapshot IDs.
  bool isPlaylistChanged(SpotifyPlaylistId playlistId, String snapshotId) {
    final cached = playlists[playlistId];
    if (cached == null) return true;
    return cached.snapshotId != snapshotId;
  }

  /// Gets album IDs that are not in the cache.
  List<SpotifyAlbumId> getMissingAlbumIds(List<SpotifyAlbumId> albumIds) {
    return albumIds.where((id) => !albums.containsKey(id)).toList();
  }
}

/// Cached playlist data.
@JsonSerializable(fieldRename: FieldRename.snake)
class CachedPlaylist {
  const CachedPlaylist({
    required this.snapshotId,
    required this.name,
    required this.tracks,
    required this.cachedAt,
  });

  factory CachedPlaylist.fromJson(Map<String, dynamic> json) =>
      _$CachedPlaylistFromJson(json);

  Map<String, dynamic> toJson() => _$CachedPlaylistToJson(this);

  final String snapshotId;
  final String name;
  final List<CachedPlaylistTrack> tracks;
  final DateTime cachedAt;
}

/// Cached playlist track data.
@JsonSerializable(fieldRename: FieldRename.snake)
class CachedPlaylistTrack {
  const CachedPlaylistTrack({
    required this.trackId,
    required this.uri,
    required this.name,
    required this.artistNames,
    required this.addedAt,
    this.albumId,
  });

  factory CachedPlaylistTrack.fromJson(Map<String, dynamic> json) =>
      _$CachedPlaylistTrackFromJson(json);

  Map<String, dynamic> toJson() => _$CachedPlaylistTrackToJson(this);

  @JsonKey(fromJson: _spotifyTrackIdFromJson, toJson: _spotifyTrackIdToJson)
  final SpotifyTrackId trackId;

  final String uri;
  final String name;
  final List<String> artistNames;
  final DateTime addedAt;

  @JsonKey(
    includeIfNull: false,
    fromJson: _spotifyAlbumIdFromJson,
    toJson: _spotifyAlbumIdToJson,
  )
  final SpotifyAlbumId? albumId;
}

/// Cached album data.
@JsonSerializable(fieldRename: FieldRename.snake)
class CachedAlbum {
  const CachedAlbum({
    required this.id,
    required this.name,
    required this.cachedAt,
    this.releaseDate,
    this.label,
    this.artistNames,
  });

  factory CachedAlbum.fromJson(Map<String, dynamic> json) =>
      _$CachedAlbumFromJson(json);

  Map<String, dynamic> toJson() => _$CachedAlbumToJson(this);

  @JsonKey(
    fromJson: _spotifyAlbumIdFromJsonRequired,
    toJson: _spotifyAlbumIdToJsonRequired,
  )
  final SpotifyAlbumId id;

  final String name;
  final DateTime cachedAt;

  @JsonKey(includeIfNull: false)
  final String? releaseDate;

  @JsonKey(includeIfNull: false)
  final String? label;

  @JsonKey(includeIfNull: false)
  final List<String>? artistNames;
}

/// Cache metadata.
@JsonSerializable(fieldRename: FieldRename.snake)
class CrawlCacheMetadata {
  const CrawlCacheMetadata({
    required this.created,
    required this.lastUpdated,
  });

  const CrawlCacheMetadata.empty() : created = null, lastUpdated = null;

  factory CrawlCacheMetadata.fromJson(Map<String, dynamic> json) =>
      _$CrawlCacheMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$CrawlCacheMetadataToJson(this);

  @JsonKey(includeIfNull: false)
  final DateTime? created;

  @JsonKey(includeIfNull: false)
  final DateTime? lastUpdated;
}

// Conversion functions for extension types

Map<SpotifyPlaylistId, CachedPlaylist> _playlistMapFromJson(
  Map<dynamic, dynamic> json,
) => json.map(
  (key, value) => MapEntry(
    SpotifyPlaylistId(key as String),
    CachedPlaylist.fromJson(value as Map<String, dynamic>),
  ),
);

Map<String, dynamic> _playlistMapToJson(
  Map<SpotifyPlaylistId, CachedPlaylist> data,
) => data.map((key, value) => MapEntry(key, value.toJson()));

Map<SpotifyAlbumId, CachedAlbum> _albumMapFromJson(
  Map<dynamic, dynamic> json,
) => json.map(
  (key, value) => MapEntry(
    SpotifyAlbumId(key as String),
    CachedAlbum.fromJson(value as Map<String, dynamic>),
  ),
);

Map<String, dynamic> _albumMapToJson(
  Map<SpotifyAlbumId, CachedAlbum> data,
) => data.map((key, value) => MapEntry(key, value.toJson()));

Map<SpotifyTrackId, SpotifyAlbumId> _trackAlbumMapFromJson(
  Map<dynamic, dynamic> json,
) => json.map(
  (key, value) => MapEntry(
    SpotifyTrackId(key as String),
    SpotifyAlbumId(value as String),
  ),
);

Map<String, dynamic> _trackAlbumMapToJson(
  Map<SpotifyTrackId, SpotifyAlbumId> data,
) => data.map((key, value) => MapEntry(key.toString(), value.toString()));

SpotifyTrackId _spotifyTrackIdFromJson(Object json) =>
    SpotifyTrackId(json as String);

String _spotifyTrackIdToJson(SpotifyTrackId id) => id.toString();

SpotifyAlbumId? _spotifyAlbumIdFromJson(Object? json) =>
    json == null ? null : SpotifyAlbumId(json as String);

SpotifyAlbumId _spotifyAlbumIdFromJsonRequired(Object json) =>
    SpotifyAlbumId(json as String);

String _spotifyAlbumIdToJsonRequired(SpotifyAlbumId id) => id.toString();

String? _spotifyAlbumIdToJson(SpotifyAlbumId? id) => id?.toString();
