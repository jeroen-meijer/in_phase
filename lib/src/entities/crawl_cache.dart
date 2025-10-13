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
    required this.artists,
    required this.artistAlbums,
    required this.labelSearches,
    required this.metadata,
  });

  const CrawlCache.empty()
    : this(
        playlists: const {},
        albums: const {},
        trackAlbumMappings: const {},
        artists: const {},
        artistAlbums: const {},
        labelSearches: const {},
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

  @JsonKey(
    fromJson: _playlistMapFromJson,
    toJson: _playlistMapToJson,
    defaultValue: {},
  )
  final Map<SpotifyPlaylistId, CachedPlaylist> playlists;

  @JsonKey(
    fromJson: _albumMapFromJson,
    toJson: _albumMapToJson,
    defaultValue: {},
  )
  final Map<SpotifyAlbumId, CachedAlbum> albums;

  @JsonKey(
    fromJson: _trackAlbumMapFromJson,
    toJson: _trackAlbumMapToJson,
    defaultValue: {},
  )
  final Map<SpotifyTrackId, SpotifyAlbumId> trackAlbumMappings;

  @JsonKey(
    fromJson: _artistMapFromJson,
    toJson: _artistMapToJson,
    defaultValue: {},
  )
  final Map<SpotifyArtistId, CachedArtist> artists;

  @JsonKey(
    fromJson: _artistAlbumsMapFromJson,
    toJson: _artistAlbumsMapToJson,
    defaultValue: {},
  )
  final Map<SpotifyArtistId, CachedArtistAlbums> artistAlbums;

  @JsonKey(
    fromJson: _labelSearchMapFromJson,
    toJson: _labelSearchMapToJson,
    defaultValue: {},
  )
  final Map<String, CachedLabelSearch> labelSearches;

  final CrawlCacheMetadata metadata;

  /// Returns a new cache with updated metadata timestamp.
  CrawlCache withUpdatedMetadata() {
    return CrawlCache(
      playlists: playlists,
      albums: albums,
      trackAlbumMappings: trackAlbumMappings,
      artists: artists,
      artistAlbums: artistAlbums,
      labelSearches: labelSearches,
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
      artists: artists,
      artistAlbums: artistAlbums,
      labelSearches: labelSearches,
      metadata: metadata,
    );
  }

  /// Returns a new cache with additional albums.
  CrawlCache withAlbums(Map<SpotifyAlbumId, CachedAlbum> newAlbums) {
    return CrawlCache(
      playlists: playlists,
      albums: {...albums, ...newAlbums},
      trackAlbumMappings: trackAlbumMappings,
      artists: artists,
      artistAlbums: artistAlbums,
      labelSearches: labelSearches,
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
      artists: artists,
      artistAlbums: artistAlbums,
      labelSearches: labelSearches,
      metadata: metadata,
    );
  }

  /// Returns a new cache with an additional artist.
  CrawlCache withArtist(
    SpotifyArtistId artistId,
    CachedArtist artist,
  ) {
    return CrawlCache(
      playlists: playlists,
      albums: albums,
      trackAlbumMappings: trackAlbumMappings,
      artists: {...artists, artistId: artist},
      artistAlbums: artistAlbums,
      labelSearches: labelSearches,
      metadata: metadata,
    );
  }

  /// Returns a new cache with artist albums.
  CrawlCache withArtistAlbums(
    SpotifyArtistId artistId,
    CachedArtistAlbums albums,
  ) {
    return CrawlCache(
      playlists: playlists,
      albums: this.albums,
      trackAlbumMappings: trackAlbumMappings,
      artists: artists,
      artistAlbums: {...artistAlbums, artistId: albums},
      labelSearches: labelSearches,
      metadata: metadata,
    );
  }

  /// Returns a new cache with a label search result.
  CrawlCache withLabelSearch(
    String labelName,
    CachedLabelSearch search,
  ) {
    return CrawlCache(
      playlists: playlists,
      albums: albums,
      trackAlbumMappings: trackAlbumMappings,
      artists: artists,
      artistAlbums: artistAlbums,
      labelSearches: {...labelSearches, labelName: search},
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

/// Cached artist metadata.
@JsonSerializable(fieldRename: FieldRename.snake)
class CachedArtist {
  const CachedArtist({
    required this.id,
    required this.name,
    required this.cachedAt,
  });

  factory CachedArtist.fromJson(Map<String, dynamic> json) =>
      _$CachedArtistFromJson(json);

  Map<String, dynamic> toJson() => _$CachedArtistToJson(this);

  @JsonKey(
    fromJson: _spotifyArtistIdFromJsonRequired,
    toJson: _spotifyArtistIdToJsonRequired,
  )
  final SpotifyArtistId id;

  final String name;
  final DateTime cachedAt;

  /// Returns true if the cache is older than 1 month.
  bool get isStale {
    final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
    return cachedAt.isBefore(oneMonthAgo);
  }
}

/// Cached artist albums list.
@JsonSerializable(fieldRename: FieldRename.snake)
class CachedArtistAlbums {
  const CachedArtistAlbums({
    required this.artistId,
    required this.albumIds,
    required this.cachedAt,
  });

  factory CachedArtistAlbums.fromJson(Map<String, dynamic> json) =>
      _$CachedArtistAlbumsFromJson(json);

  Map<String, dynamic> toJson() => _$CachedArtistAlbumsToJson(this);

  @JsonKey(
    fromJson: _spotifyArtistIdFromJsonRequired,
    toJson: _spotifyArtistIdToJsonRequired,
  )
  final SpotifyArtistId artistId;

  @JsonKey(
    fromJson: _albumIdListFromJson,
    toJson: _albumIdListToJson,
  )
  final List<SpotifyAlbumId> albumIds;

  final DateTime cachedAt;

  /// Returns true if the cache was created today.
  bool get isFreshToday {
    final now = DateTime.now();
    final cacheDate = DateTime(
      cachedAt.year,
      cachedAt.month,
      cachedAt.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    return cacheDate.isAtSameMomentAs(today) ||
        cacheDate.isAfter(today.subtract(const Duration(days: 1)));
  }
}

/// Cached track from label search.
@JsonSerializable(fieldRename: FieldRename.snake)
class CachedLabelTrack {
  const CachedLabelTrack({
    required this.trackId,
    required this.uri,
    required this.name,
    required this.artistNames,
    required this.albumId,
    required this.albumName,
    required this.releaseDate,
  });

  factory CachedLabelTrack.fromJson(Map<String, dynamic> json) =>
      _$CachedLabelTrackFromJson(json);

  Map<String, dynamic> toJson() => _$CachedLabelTrackToJson(this);

  @JsonKey(
    fromJson: _spotifyTrackIdFromJsonRequired,
    toJson: _spotifyTrackIdToJsonRequired,
  )
  final SpotifyTrackId trackId;

  final String uri;
  final String name;
  final List<String> artistNames;

  @JsonKey(
    fromJson: _spotifyAlbumIdFromJson,
    toJson: _spotifyAlbumIdToJson,
  )
  final SpotifyAlbumId? albumId;

  final String? albumName;
  final String? releaseDate;
}

/// Cached label search results.
@JsonSerializable(fieldRename: FieldRename.snake)
class CachedLabelSearch {
  const CachedLabelSearch({
    required this.labelName,
    required this.tracks,
    required this.cachedAt,
  });

  factory CachedLabelSearch.fromJson(Map<String, dynamic> json) =>
      _$CachedLabelSearchFromJson(json);

  Map<String, dynamic> toJson() => _$CachedLabelSearchToJson(this);

  final String labelName;
  final List<CachedLabelTrack> tracks;
  final DateTime cachedAt;

  /// Returns true if the cache was created today.
  bool get isFreshToday {
    final now = DateTime.now();
    final cacheDate = DateTime(
      cachedAt.year,
      cachedAt.month,
      cachedAt.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    return cacheDate.isAtSameMomentAs(today) ||
        cacheDate.isAfter(today.subtract(const Duration(days: 1)));
  }
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

SpotifyTrackId _spotifyTrackIdFromJsonRequired(Object json) =>
    SpotifyTrackId(json as String);

String _spotifyTrackIdToJsonRequired(SpotifyTrackId id) => id.toString();

SpotifyAlbumId? _spotifyAlbumIdFromJson(Object? json) =>
    json == null ? null : SpotifyAlbumId(json as String);

SpotifyAlbumId _spotifyAlbumIdFromJsonRequired(Object json) =>
    SpotifyAlbumId(json as String);

String _spotifyAlbumIdToJsonRequired(SpotifyAlbumId id) => id.toString();

String? _spotifyAlbumIdToJson(SpotifyAlbumId? id) => id?.toString();

// Artist conversions

Map<SpotifyArtistId, CachedArtist> _artistMapFromJson(
  Map<dynamic, dynamic> json,
) => json.map(
  (key, value) => MapEntry(
    SpotifyArtistId(key as String),
    CachedArtist.fromJson(value as Map<String, dynamic>),
  ),
);

Map<String, dynamic> _artistMapToJson(
  Map<SpotifyArtistId, CachedArtist> data,
) => data.map((key, value) => MapEntry(key.toString(), value.toJson()));

SpotifyArtistId _spotifyArtistIdFromJsonRequired(Object json) =>
    SpotifyArtistId(json as String);

String _spotifyArtistIdToJsonRequired(SpotifyArtistId id) => id.toString();

// Artist albums conversions

Map<SpotifyArtistId, CachedArtistAlbums> _artistAlbumsMapFromJson(
  Map<dynamic, dynamic> json,
) => json.map(
  (key, value) => MapEntry(
    SpotifyArtistId(key as String),
    CachedArtistAlbums.fromJson(value as Map<String, dynamic>),
  ),
);

Map<String, dynamic> _artistAlbumsMapToJson(
  Map<SpotifyArtistId, CachedArtistAlbums> data,
) => data.map((key, value) => MapEntry(key.toString(), value.toJson()));

List<SpotifyAlbumId> _albumIdListFromJson(List<dynamic> json) =>
    json.map((e) => SpotifyAlbumId(e as String)).toList();

List<String> _albumIdListToJson(List<SpotifyAlbumId> ids) =>
    ids.map((id) => id.toString()).toList();

// Label search conversions

Map<String, CachedLabelSearch> _labelSearchMapFromJson(
  Map<dynamic, dynamic> json,
) => json.map(
  (key, value) => MapEntry(
    key as String,
    CachedLabelSearch.fromJson(value as Map<String, dynamic>),
  ),
);

Map<String, dynamic> _labelSearchMapToJson(
  Map<String, CachedLabelSearch> data,
) => data.map((key, value) => MapEntry(key, value.toJson()));
