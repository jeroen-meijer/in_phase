// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'engine_sync_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EngineSyncConfig _$EngineSyncConfigFromJson(Map<String, dynamic> json) =>
    EngineSyncConfig(
      engineLibraryPath: json['engine_library_path'] as String?,
      anlzRootPath: json['anlz_root_path'] as String?,
      prune: json['prune'] as bool? ?? true,
      memoryCuesToHotCues: json['memory_cues_to_hot_cues'] as bool? ?? false,
      syncArt: json['sync_art'] as bool? ?? true,
    );

Map<String, dynamic> _$EngineSyncConfigToJson(EngineSyncConfig instance) =>
    <String, dynamic>{
      'engine_library_path': instance.engineLibraryPath,
      'anlz_root_path': instance.anlzRootPath,
      'prune': instance.prune,
      'memory_cues_to_hot_cues': instance.memoryCuesToHotCues,
      'sync_art': instance.syncArt,
    };
