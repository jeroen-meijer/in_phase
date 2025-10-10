import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'package:rkdb_dart/src/misc/misc.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_codec/yaml_codec.dart';

part 'crawl_config.g.dart';

/// Main configuration for the crawl command.
///
/// NOTE(jeroen-meijer): The YAML parser automatically resolves anchors
/// (e.g., *playlist_id) during parsing, so we receive the actual values
/// and don't need to handle reference resolution.
@JsonSerializable(fieldRename: FieldRename.snake)
class CrawlConfig {
  const CrawlConfig({
    required this.jobs,
  });

  const CrawlConfig.empty() : this(jobs: const []);

  factory CrawlConfig.fromJson(Map<String, dynamic> json) =>
      _$CrawlConfigFromJson(json);

  Map<String, dynamic> toJson() => _$CrawlConfigToJson(this);

  static Future<CrawlConfig> fromFile(
    File file, {
    bool createFileIfNotExists = true,
  }) async {
    // ignore: avoid_slow_async_io
    if (!await file.exists()) {
      if (createFileIfNotExists) {
        await file.create(recursive: true);
        const config = CrawlConfig.empty();
        await config.write(file);
        return config;
      } else {
        throw Exception('Crawl config file not found at ${file.path}');
      }
    }

    final content = await file.readAsString();
    final yaml = yamlDecode(content) as YamlMap;
    return CrawlConfig.fromJson(yaml.toMap());
  }

  Future<void> write(File file) async {
    await file.create(recursive: true);
    await file.writeAsString(yamlEncode(toJson()));
  }

  final List<CrawlJob> jobs;
}

/// A single crawl job configuration.
@JsonSerializable(fieldRename: FieldRename.snake)
class CrawlJob {
  const CrawlJob({
    required this.name,
    required this.outputPlaylist,
    required this.filters,
    required this.inputs,
    this.cover,
    this.options,
  });

  factory CrawlJob.fromJson(Map<String, dynamic> json) =>
      _$CrawlJobFromJson(json);

  Map<String, dynamic> toJson() => _$CrawlJobToJson(this);

  final String name;
  final CrawlOutputPlaylist outputPlaylist;
  final CrawlFilters filters;
  final CrawlInputs inputs;

  @JsonKey(includeIfNull: false)
  final CrawlCover? cover;

  @JsonKey(includeIfNull: false)
  final CrawlOptions? options;
}

/// Output playlist configuration.
@JsonSerializable(fieldRename: FieldRename.snake)
class CrawlOutputPlaylist {
  const CrawlOutputPlaylist({
    required this.name,
    this.description,
    this.public = false,
  });

  factory CrawlOutputPlaylist.fromJson(Map<String, dynamic> json) =>
      _$CrawlOutputPlaylistFromJson(json);

  Map<String, dynamic> toJson() => _$CrawlOutputPlaylistToJson(this);

  /// Template string for playlist name (supports variables like {week_num}).
  final String name;

  /// Template string for playlist description.
  @JsonKey(includeIfNull: false)
  final String? description;

  /// Whether the playlist should be public.
  @JsonKey(defaultValue: false)
  final bool public;
}

/// Playlist cover configuration.
@JsonSerializable(fieldRename: FieldRename.snake)
class CrawlCover {
  const CrawlCover({
    required this.image,
    this.caption,
  });

  factory CrawlCover.fromJson(Map<String, dynamic> json) =>
      _$CrawlCoverFromJson(json);

  Map<String, dynamic> toJson() => _$CrawlCoverToJson(this);

  /// Path to cover image file.
  final String image;

  /// Template string for caption text.
  @JsonKey(includeIfNull: false)
  final String? caption;
}

/// Filters for track selection.
@JsonSerializable(fieldRename: FieldRename.snake)
class CrawlFilters {
  const CrawlFilters({
    required this.addedBetweenDays,
  });

  factory CrawlFilters.fromJson(Map<String, dynamic> json) =>
      _$CrawlFiltersFromJson(json);

  Map<String, dynamic> toJson() => _$CrawlFiltersToJson(this);

  /// Number of days to look back for tracks.
  /// Tracks added/released in the last N days will be included.
  final int addedBetweenDays;
}

/// Processing options for the job.
@JsonSerializable(fieldRename: FieldRename.snake)
class CrawlOptions {
  const CrawlOptions({
    this.deduplicate,
    this.appendToExisting = false,
    this.addPlaylistTracksBasedOn = PlaylistTrackDateMode.releaseDate,
  });

  factory CrawlOptions.fromJson(Map<String, dynamic> json) =>
      _$CrawlOptionsFromJson(json);

  Map<String, dynamic> toJson() => _$CrawlOptionsToJson(this);

  /// Deduplication mode.
  @JsonKey(includeIfNull: false)
  final DeduplicateMode? deduplicate;

  /// Whether to append to existing playlist or create new.
  @JsonKey(defaultValue: false)
  final bool appendToExisting;

  /// Determines which date to use for filtering playlist tracks.
  /// - `added_date`: Use when track was added to playlist
  /// - `release_date`: Use track's album release date (default)
  @JsonKey(defaultValue: PlaylistTrackDateMode.releaseDate)
  final PlaylistTrackDateMode addPlaylistTracksBasedOn;
}

/// Input sources for the job.
@JsonSerializable(fieldRename: FieldRename.snake)
class CrawlInputs {
  const CrawlInputs({
    this.playlists,
    this.artists,
    this.labels,
  });

  factory CrawlInputs.fromJson(Map<String, dynamic> json) =>
      _$CrawlInputsFromJson(json);

  Map<String, dynamic> toJson() => _$CrawlInputsToJson(this);

  /// List of Spotify playlist IDs (can include YAML anchor references).
  @JsonKey(includeIfNull: false)
  final List<String>? playlists;

  /// List of Spotify artist IDs (can include YAML anchor references).
  @JsonKey(includeIfNull: false)
  final List<String>? artists;

  /// List of label names (can include YAML anchor references).
  @JsonKey(includeIfNull: false)
  final List<String>? labels;
}

/// Deduplication modes.
@JsonEnum()
enum DeduplicateMode {
  /// Remove tracks with duplicate IDs.
  @JsonValue('on_id')
  onId,

  /// Remove tracks with matching artist names and track titles.
  @JsonValue('on_match')
  onMatch,
}

/// Playlist track date mode - determines which date to use for filtering
/// playlist tracks.
@JsonEnum()
enum PlaylistTrackDateMode {
  /// Use the date when the track was added to the playlist.
  @JsonValue('added_date')
  addedDate,

  /// Use the release date of the track's album.
  @JsonValue('release_date')
  releaseDate,
}
