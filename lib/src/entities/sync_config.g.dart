// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncConfig _$SyncConfigFromJson(Map<String, dynamic> json) => SyncConfig(
  playlists: _globListFromJson(json['playlists'] as List),
  folders: (json['folders'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, SyncConfigFolder.fromJson(e as Map<String, dynamic>)),
  ),
  overwriteSongKeys: json['overwrite_song_keys'] as bool,
  customTracks: json['custom_tracks'] == null
      ? {}
      : const _CustomTracksConverter().fromJson(
          json['custom_tracks'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$SyncConfigToJson(
  SyncConfig instance,
) => <String, dynamic>{
  'playlists': _globListToJson(instance.playlists),
  'folders': instance.folders,
  'overwrite_song_keys': instance.overwriteSongKeys,
  'custom_tracks': const _CustomTracksConverter().toJson(instance.customTracks),
};

SyncConfigFolder _$SyncConfigFolderFromJson(Map<String, dynamic> json) =>
    SyncConfigFolder(playlists: _globListFromJson(json['playlists'] as List));

Map<String, dynamic> _$SyncConfigFolderToJson(SyncConfigFolder instance) =>
    <String, dynamic>{'playlists': _globListToJson(instance.playlists)};

CustomTrack _$CustomTrackFromJson(Map<String, dynamic> json) => CustomTrack(
  rekordboxId: const _RekordboxSongIdConverter().fromJson(
    json['rekordbox_id'] as Object,
  ),
  type:
      $enumDecodeNullable(_$CustomTrackTypeEnumMap, json['type']) ??
      CustomTrackType.insert,
  index: (json['index'] as num?)?.toInt(),
  position: (json['position'] as num?)?.toInt(),
  target: _$JsonConverterFromJson<Object, RekordboxSongId>(
    json['target'],
    const _RekordboxSongIdConverter().fromJson,
  ),
);

Map<String, dynamic> _$CustomTrackToJson(CustomTrack instance) =>
    <String, dynamic>{
      'rekordbox_id': const _RekordboxSongIdConverter().toJson(
        instance.rekordboxId,
      ),
      'type': _$CustomTrackTypeEnumMap[instance.type]!,
      'index': instance.index,
      'position': instance.position,
      'target': _$JsonConverterToJson<Object, RekordboxSongId>(
        instance.target,
        const _RekordboxSongIdConverter().toJson,
      ),
    };

const _$CustomTrackTypeEnumMap = {
  CustomTrackType.insert: 'insert',
  CustomTrackType.replace: 'replace',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
