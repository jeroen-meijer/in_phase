// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_cache.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncCache _$SyncCacheFromJson(Map<String, dynamic> json) => SyncCache(
  mappings: _trackMappingFromJson(json['mappings'] as Map),
  missingTracks: _missingTracksFromJson(json['missing_tracks'] as Map),
);

Map<String, dynamic> _$SyncCacheToJson(SyncCache instance) => <String, dynamic>{
  'mappings': _trackMappingToJson(instance.mappings),
  'missing_tracks': _missingTracksToJson(instance.missingTracks),
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
