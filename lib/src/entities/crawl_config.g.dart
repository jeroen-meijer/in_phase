// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crawl_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CrawlConfig _$CrawlConfigFromJson(Map<String, dynamic> json) => CrawlConfig(
  jobs: (json['jobs'] as List<dynamic>)
      .map((e) => CrawlJob.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CrawlConfigToJson(CrawlConfig instance) =>
    <String, dynamic>{'jobs': instance.jobs};

CrawlJob _$CrawlJobFromJson(Map<String, dynamic> json) => CrawlJob(
  name: json['name'] as String,
  outputPlaylist: CrawlOutputPlaylist.fromJson(
    json['output_playlist'] as Map<String, dynamic>,
  ),
  filters: CrawlFilters.fromJson(json['filters'] as Map<String, dynamic>),
  inputs: CrawlInputs.fromJson(json['inputs'] as Map<String, dynamic>),
  cover: json['cover'] == null
      ? null
      : CrawlCover.fromJson(json['cover'] as Map<String, dynamic>),
  options: json['options'] == null
      ? null
      : CrawlOptions.fromJson(json['options'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CrawlJobToJson(CrawlJob instance) => <String, dynamic>{
  'name': instance.name,
  'output_playlist': instance.outputPlaylist,
  'filters': instance.filters,
  'inputs': instance.inputs,
  'cover': ?instance.cover,
  'options': ?instance.options,
};

CrawlOutputPlaylist _$CrawlOutputPlaylistFromJson(Map<String, dynamic> json) =>
    CrawlOutputPlaylist(
      name: json['name'] as String,
      description: json['description'] as String?,
      public: json['public'] as bool? ?? false,
      id: json['id'] as String?,
    );

Map<String, dynamic> _$CrawlOutputPlaylistToJson(
  CrawlOutputPlaylist instance,
) => <String, dynamic>{
  'name': instance.name,
  'description': ?instance.description,
  'public': instance.public,
  'id': ?instance.id,
};

CrawlCover _$CrawlCoverFromJson(Map<String, dynamic> json) => CrawlCover(
  image: json['image'] as String,
  caption: json['caption'] as String?,
  font: json['font'] as String?,
);

Map<String, dynamic> _$CrawlCoverToJson(CrawlCover instance) =>
    <String, dynamic>{
      'image': instance.image,
      'caption': ?instance.caption,
      'font': ?instance.font,
    };

CrawlOptions _$CrawlOptionsFromJson(Map<String, dynamic> json) => CrawlOptions(
  deduplicate: $enumDecodeNullable(
    _$DeduplicateModeEnumMap,
    json['deduplicate'],
  ),
  addPlaylistTracksBasedOn:
      $enumDecodeNullable(
        _$PlaylistTrackDateModeEnumMap,
        json['add_playlist_tracks_based_on'],
      ) ??
      PlaylistTrackDateMode.releaseDate,
  updateMode:
      $enumDecodeNullable(_$CrawlUpdateModeEnumMap, json['update_mode']) ??
      CrawlUpdateMode.replace,
  includeArtistAppearances: json['include_artist_appearances'] as bool? ?? true,
);

Map<String, dynamic> _$CrawlOptionsToJson(CrawlOptions instance) =>
    <String, dynamic>{
      'deduplicate': ?_$DeduplicateModeEnumMap[instance.deduplicate],
      'add_playlist_tracks_based_on':
          _$PlaylistTrackDateModeEnumMap[instance.addPlaylistTracksBasedOn]!,
      'update_mode': _$CrawlUpdateModeEnumMap[instance.updateMode]!,
      'include_artist_appearances': instance.includeArtistAppearances,
    };

const _$DeduplicateModeEnumMap = {
  DeduplicateMode.onId: 'on_id',
  DeduplicateMode.onMatch: 'on_match',
};

const _$PlaylistTrackDateModeEnumMap = {
  PlaylistTrackDateMode.addedDate: 'added_date',
  PlaylistTrackDateMode.releaseDate: 'release_date',
};

const _$CrawlUpdateModeEnumMap = {
  CrawlUpdateMode.replace: 'replace',
  CrawlUpdateMode.append: 'append',
};

CrawlInputs _$CrawlInputsFromJson(Map<String, dynamic> json) => CrawlInputs(
  playlists: (json['playlists'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  artists: (json['artists'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  labels: (json['labels'] as List<dynamic>?)?.map((e) => e as String).toList(),
  youtubeChannels: (json['youtube_channels'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$CrawlInputsToJson(CrawlInputs instance) =>
    <String, dynamic>{
      'playlists': ?instance.playlists,
      'artists': ?instance.artists,
      'labels': ?instance.labels,
      'youtube_channels': ?instance.youtubeChannels,
    };
