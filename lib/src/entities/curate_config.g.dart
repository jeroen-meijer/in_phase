// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'curate_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CurateConfig _$CurateConfigFromJson(Map<String, dynamic> json) => CurateConfig(
  startPosition: json['start_position'] as String? ?? '1:15',
  seekStep: (json['seek_step'] as num?)?.toInt() ?? 15,
  targets: _targetsFromJson(json['targets']),
  nextAfterAdd: json['next_after_add'] as bool? ?? false,
  autoAddToLikes: json['auto_add_to_likes'] as bool? ?? false,
);

Map<String, dynamic> _$CurateConfigToJson(CurateConfig instance) =>
    <String, dynamic>{
      'start_position': instance.startPosition,
      'seek_step': instance.seekStep,
      'next_after_add': instance.nextAfterAdd,
      'auto_add_to_likes': instance.autoAddToLikes,
      'targets': _targetsToJson(instance.targets),
    };
