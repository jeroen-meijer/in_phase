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
);

Map<String, dynamic> _$SyncConfigToJson(SyncConfig instance) =>
    <String, dynamic>{
      'playlists': _globListToJson(instance.playlists),
      'folders': instance.folders,
      'overwrite_song_keys': instance.overwriteSongKeys,
    };

SyncConfigFolder _$SyncConfigFolderFromJson(Map<String, dynamic> json) =>
    SyncConfigFolder(playlists: _globListFromJson(json['playlists'] as List));

Map<String, dynamic> _$SyncConfigFolderToJson(SyncConfigFolder instance) =>
    <String, dynamic>{'playlists': _globListToJson(instance.playlists)};
