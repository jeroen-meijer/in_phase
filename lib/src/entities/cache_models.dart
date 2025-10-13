import 'package:json_annotation/json_annotation.dart';
import 'package:rkdb_dart/src/spotify/spotify.dart';

part 'cache_models.g.dart';

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

// Conversion functions for extension types

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

SpotifyArtistId _spotifyArtistIdFromJsonRequired(Object json) =>
    SpotifyArtistId(json as String);

String _spotifyArtistIdToJsonRequired(SpotifyArtistId id) => id.toString();

List<SpotifyAlbumId> _albumIdListFromJson(List<dynamic> json) =>
    json.map((e) => SpotifyAlbumId(e as String)).toList();

List<String> _albumIdListToJson(List<SpotifyAlbumId> ids) =>
    ids.map((id) => id.toString()).toList();

// ============================================================================
// SYNC CACHE MODELS
// ============================================================================

extension type const RekordboxSongId(String value) implements String {}
