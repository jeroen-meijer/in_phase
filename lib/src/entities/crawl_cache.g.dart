// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crawl_cache.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CrawlCache _$CrawlCacheFromJson(Map<String, dynamic> json) => CrawlCache(
  playlists: json['playlists'] == null
      ? {}
      : _playlistMapFromJson(json['playlists'] as Map),
  albums: json['albums'] == null
      ? {}
      : _albumMapFromJson(json['albums'] as Map),
  trackAlbumMappings: json['track_album_mappings'] == null
      ? {}
      : _trackAlbumMapFromJson(json['track_album_mappings'] as Map),
  artists: json['artists'] == null
      ? {}
      : _artistMapFromJson(json['artists'] as Map),
  artistAlbums: json['artist_albums'] == null
      ? {}
      : _artistAlbumsMapFromJson(json['artist_albums'] as Map),
  labelSearches: json['label_searches'] == null
      ? {}
      : _labelSearchMapFromJson(json['label_searches'] as Map),
  metadata: CrawlCacheMetadata.fromJson(
    json['metadata'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$CrawlCacheToJson(CrawlCache instance) =>
    <String, dynamic>{
      'playlists': _playlistMapToJson(instance.playlists),
      'albums': _albumMapToJson(instance.albums),
      'track_album_mappings': _trackAlbumMapToJson(instance.trackAlbumMappings),
      'artists': _artistMapToJson(instance.artists),
      'artist_albums': _artistAlbumsMapToJson(instance.artistAlbums),
      'label_searches': _labelSearchMapToJson(instance.labelSearches),
      'metadata': instance.metadata,
    };

CachedPlaylist _$CachedPlaylistFromJson(Map<String, dynamic> json) =>
    CachedPlaylist(
      snapshotId: json['snapshot_id'] as String,
      name: json['name'] as String,
      tracks: (json['tracks'] as List<dynamic>)
          .map((e) => CachedPlaylistTrack.fromJson(e as Map<String, dynamic>))
          .toList(),
      cachedAt: DateTime.parse(json['cached_at'] as String),
    );

Map<String, dynamic> _$CachedPlaylistToJson(CachedPlaylist instance) =>
    <String, dynamic>{
      'snapshot_id': instance.snapshotId,
      'name': instance.name,
      'tracks': instance.tracks,
      'cached_at': instance.cachedAt.toIso8601String(),
    };

CachedPlaylistTrack _$CachedPlaylistTrackFromJson(Map<String, dynamic> json) =>
    CachedPlaylistTrack(
      trackId: _spotifyTrackIdFromJson(json['track_id'] as Object),
      uri: json['uri'] as String,
      name: json['name'] as String,
      artistNames: (json['artist_names'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      addedAt: DateTime.parse(json['added_at'] as String),
      albumId: _spotifyAlbumIdFromJson(json['album_id']),
    );

Map<String, dynamic> _$CachedPlaylistTrackToJson(
  CachedPlaylistTrack instance,
) => <String, dynamic>{
  'track_id': _spotifyTrackIdToJson(instance.trackId),
  'uri': instance.uri,
  'name': instance.name,
  'artist_names': instance.artistNames,
  'added_at': instance.addedAt.toIso8601String(),
  'album_id': ?_spotifyAlbumIdToJson(instance.albumId),
};

CachedAlbum _$CachedAlbumFromJson(Map<String, dynamic> json) => CachedAlbum(
  id: _spotifyAlbumIdFromJsonRequired(json['id'] as Object),
  name: json['name'] as String,
  cachedAt: DateTime.parse(json['cached_at'] as String),
  releaseDate: json['release_date'] as String?,
  label: json['label'] as String?,
  artistNames: (json['artist_names'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$CachedAlbumToJson(CachedAlbum instance) =>
    <String, dynamic>{
      'id': _spotifyAlbumIdToJsonRequired(instance.id),
      'name': instance.name,
      'cached_at': instance.cachedAt.toIso8601String(),
      'release_date': ?instance.releaseDate,
      'label': ?instance.label,
      'artist_names': ?instance.artistNames,
    };

CachedArtist _$CachedArtistFromJson(Map<String, dynamic> json) => CachedArtist(
  id: _spotifyArtistIdFromJsonRequired(json['id'] as Object),
  name: json['name'] as String,
  cachedAt: DateTime.parse(json['cached_at'] as String),
);

Map<String, dynamic> _$CachedArtistToJson(CachedArtist instance) =>
    <String, dynamic>{
      'id': _spotifyArtistIdToJsonRequired(instance.id),
      'name': instance.name,
      'cached_at': instance.cachedAt.toIso8601String(),
    };

CachedArtistAlbums _$CachedArtistAlbumsFromJson(Map<String, dynamic> json) =>
    CachedArtistAlbums(
      artistId: _spotifyArtistIdFromJsonRequired(json['artist_id'] as Object),
      albumIds: _albumIdListFromJson(json['album_ids'] as List),
      cachedAt: DateTime.parse(json['cached_at'] as String),
    );

Map<String, dynamic> _$CachedArtistAlbumsToJson(CachedArtistAlbums instance) =>
    <String, dynamic>{
      'artist_id': _spotifyArtistIdToJsonRequired(instance.artistId),
      'album_ids': _albumIdListToJson(instance.albumIds),
      'cached_at': instance.cachedAt.toIso8601String(),
    };

CachedLabelTrack _$CachedLabelTrackFromJson(Map<String, dynamic> json) =>
    CachedLabelTrack(
      trackId: _spotifyTrackIdFromJsonRequired(json['track_id'] as Object),
      uri: json['uri'] as String,
      name: json['name'] as String,
      artistNames: (json['artist_names'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      albumId: _spotifyAlbumIdFromJson(json['album_id']),
      albumName: json['album_name'] as String?,
      releaseDate: json['release_date'] as String?,
    );

Map<String, dynamic> _$CachedLabelTrackToJson(CachedLabelTrack instance) =>
    <String, dynamic>{
      'track_id': _spotifyTrackIdToJsonRequired(instance.trackId),
      'uri': instance.uri,
      'name': instance.name,
      'artist_names': instance.artistNames,
      'album_id': _spotifyAlbumIdToJson(instance.albumId),
      'album_name': instance.albumName,
      'release_date': instance.releaseDate,
    };

CachedLabelSearch _$CachedLabelSearchFromJson(Map<String, dynamic> json) =>
    CachedLabelSearch(
      labelName: json['label_name'] as String,
      tracks: (json['tracks'] as List<dynamic>)
          .map((e) => CachedLabelTrack.fromJson(e as Map<String, dynamic>))
          .toList(),
      cachedAt: DateTime.parse(json['cached_at'] as String),
    );

Map<String, dynamic> _$CachedLabelSearchToJson(CachedLabelSearch instance) =>
    <String, dynamic>{
      'label_name': instance.labelName,
      'tracks': instance.tracks,
      'cached_at': instance.cachedAt.toIso8601String(),
    };

CrawlCacheMetadata _$CrawlCacheMetadataFromJson(Map<String, dynamic> json) =>
    CrawlCacheMetadata(
      created: json['created'] == null
          ? null
          : DateTime.parse(json['created'] as String),
      lastUpdated: json['last_updated'] == null
          ? null
          : DateTime.parse(json['last_updated'] as String),
    );

Map<String, dynamic> _$CrawlCacheMetadataToJson(CrawlCacheMetadata instance) =>
    <String, dynamic>{
      'created': ?instance.created?.toIso8601String(),
      'last_updated': ?instance.lastUpdated?.toIso8601String(),
    };
