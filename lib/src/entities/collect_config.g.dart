// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collect_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CollectConfig _$CollectConfigFromJson(Map<String, dynamic> json) =>
    CollectConfig(
      collections: (json['collections'] as List<dynamic>)
          .map((e) => CollectCollection.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CollectConfigToJson(CollectConfig instance) =>
    <String, dynamic>{'collections': instance.collections};

CollectCollection _$CollectCollectionFromJson(Map<String, dynamic> json) =>
    CollectCollection(
      name: json['name'] as String,
      target: json['target'] as String,
      sources: (json['sources'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      description: json['description'] as String?,
      options: json['options'] == null
          ? null
          : CollectOptions.fromJson(json['options'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CollectCollectionToJson(CollectCollection instance) =>
    <String, dynamic>{
      'name': instance.name,
      'target': instance.target,
      'sources': instance.sources,
      'description': ?instance.description,
      'options': ?instance.options,
    };

CollectOptions _$CollectOptionsFromJson(Map<String, dynamic> json) =>
    CollectOptions(
      deduplicate: $enumDecodeNullable(
        _$DeduplicateModeEnumMap,
        json['deduplicate'],
      ),
      replace: json['replace'] as bool? ?? true,
      trackOrder: $enumDecodeNullable(
        _$CollectTrackOrderEnumMap,
        json['track_order'],
      ),
    );

Map<String, dynamic> _$CollectOptionsToJson(CollectOptions instance) =>
    <String, dynamic>{
      'deduplicate': ?_$DeduplicateModeEnumMap[instance.deduplicate],
      'replace': instance.replace,
      'track_order': ?_$CollectTrackOrderEnumMap[instance.trackOrder],
    };

const _$DeduplicateModeEnumMap = {
  DeduplicateMode.onId: 'on_id',
  DeduplicateMode.onMatch: 'on_match',
};

const _$CollectTrackOrderEnumMap = {
  CollectTrackOrder.oldestFirst: 'oldest_first',
  CollectTrackOrder.newestFirst: 'newest_first',
};
