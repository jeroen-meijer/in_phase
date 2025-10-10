// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_cache.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncCache _$SyncCacheFromJson(Map<String, dynamic> json) => SyncCache(
  mappings: _trackMappingFromJson(json['mappings'] as Map),
  missingTracks: _missingTracksFromJson(json['missing_tracks'] as Map),
  playlists: _cachedPlaylistsFromJson(json['playlists'] as Map),
);

Map<String, dynamic> _$SyncCacheToJson(SyncCache instance) => <String, dynamic>{
  'mappings': _trackMappingToJson(instance.mappings),
  'missing_tracks': _missingTracksToJson(instance.missingTracks),
  'playlists': _cachedPlaylistsToJson(instance.playlists),
};

MissingTrack _$MissingTrackFromJson(Map<String, dynamic> json) => MissingTrack(
  id: json['id'] as SpotifyTrackId,
  artist: json['artist'] as String,
  title: json['title'] as String,
  itunesUrl: json['itunes_url'] as String?,
  lastInsertedAt: DateTime.parse(json['last_inserted_at'] as String),
);

Map<String, dynamic> _$MissingTrackToJson(MissingTrack instance) =>
    <String, dynamic>{
      'id': instance.id,
      'artist': instance.artist,
      'title': instance.title,
      'itunes_url': instance.itunesUrl,
      'last_inserted_at': instance.lastInsertedAt.toIso8601String(),
    };

CachedSyncPlaylist _$CachedSyncPlaylistFromJson(Map<String, dynamic> json) =>
    CachedSyncPlaylist(
      snapshotId: json['snapshot_id'] as String,
      name: json['name'] as String,
      tracks: _cachedTracksFromJson(json['tracks'] as List),
      cachedAt: DateTime.parse(json['cached_at'] as String),
    );

Map<String, dynamic> _$CachedSyncPlaylistToJson(CachedSyncPlaylist instance) =>
    <String, dynamic>{
      'snapshot_id': instance.snapshotId,
      'name': instance.name,
      'tracks': _cachedTracksToJson(instance.tracks),
      'cached_at': instance.cachedAt.toIso8601String(),
    };

CachedSyncTrack _$CachedSyncTrackFromJson(Map<String, dynamic> json) =>
    CachedSyncTrack(
      id: _spotifyTrackIdFromJson(json['id'] as Object),
      name: json['name'] as String,
      artistNames: (json['artist_names'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$CachedSyncTrackToJson(CachedSyncTrack instance) =>
    <String, dynamic>{
      'id': _spotifyTrackIdToJson(instance.id),
      'name': instance.name,
      'artist_names': instance.artistNames,
    };
