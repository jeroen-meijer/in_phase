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
  customTracks: _customTracksFromJson(json['custom_tracks'] as Map?),
);

Map<String, dynamic> _$SyncConfigToJson(SyncConfig instance) =>
    <String, dynamic>{
      'playlists': _globListToJson(instance.playlists),
      'folders': instance.folders,
      'overwrite_song_keys': instance.overwriteSongKeys,
      'custom_tracks': _customTracksToJson(instance.customTracks),
    };

SyncConfigFolder _$SyncConfigFolderFromJson(Map<String, dynamic> json) =>
    SyncConfigFolder(playlists: _globListFromJson(json['playlists'] as List));

Map<String, dynamic> _$SyncConfigFolderToJson(SyncConfigFolder instance) =>
    <String, dynamic>{'playlists': _globListToJson(instance.playlists)};

CustomTrack _$CustomTrackFromJson(Map<String, dynamic> json) => CustomTrack(
  rekordboxId: _rekordboxSongIdFromJson(json['rekordbox_id'] as Object),
  type:
      $enumDecodeNullable(_$CustomTrackTypeEnumMap, json['type']) ??
      CustomTrackType.insert,
  index: (json['index'] as num?)?.toInt(),
  position: (json['position'] as num?)?.toInt(),
  target: _nullableRekordboxSongIdFromJson(json['target']),
);

Map<String, dynamic> _$CustomTrackToJson(CustomTrack instance) =>
    <String, dynamic>{
      'rekordbox_id': _rekordboxSongIdToJson(instance.rekordboxId),
      'type': _$CustomTrackTypeEnumMap[instance.type]!,
      'index': instance.index,
      'position': instance.position,
      'target': _nullableRekordboxSongIdToJson(instance.target),
    };

const _$CustomTrackTypeEnumMap = {
  CustomTrackType.insert: 'insert',
  CustomTrackType.replace: 'replace',
};
