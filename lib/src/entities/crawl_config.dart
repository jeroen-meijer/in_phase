import 'dart:io';

import 'package:in_phase/src/crawl/crawl.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:json_annotation/json_annotation.dart';
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
    this.id,
  });

  factory CrawlOutputPlaylist.fromJson(Map<String, dynamic> json) =>
      _$CrawlOutputPlaylistFromJson(json);

  Map<String, dynamic> toJson() => _$CrawlOutputPlaylistToJson(this);

  /// Template string for playlist name (supports variables like {week_num}).
  final String name;

  /// Template string for playlist description.
  @JsonKey(includeIfNull: false)
  final String? description;

  /// Whether the playlist should be public (only used when creating new
  /// playlist).
  @JsonKey(defaultValue: false)
  final bool public;

  /// Playlist ID, URI, or share URL to update instead of creating new.
  /// If provided, the existing playlist will be updated with new tracks, name,
  /// description, and cover image.
  @JsonKey(includeIfNull: false)
  final String? id;
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
@JsonSerializable(
  fieldRename: FieldRename.snake,
  createFactory: false,
  createToJson: false,
)
class CrawlFilters {
  const CrawlFilters({
    @Deprecated('Use dateRange instead') this.addedBetweenDays,
    this.dateRange,
  });

  factory CrawlFilters.fromJson(Map<String, dynamic> json) {
    // Custom parsing for date_range field
    final dateRangeValue = json['date_range'];
    CrawlDateRange? dateRange;

    if (dateRangeValue != null) {
      dateRange = _parseDateRange(dateRangeValue);
    }

    return CrawlFilters(
      // ignore: deprecated_member_use_from_same_package
      addedBetweenDays: json['added_between_days'] as int?,
      dateRange: dateRange,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    // ignore: deprecated_member_use_from_same_package
    if (addedBetweenDays != null) {
      // ignore: deprecated_member_use_from_same_package
      map['added_between_days'] = addedBetweenDays;
    }
    if (dateRange != null) {
      map['date_range'] = _serializeDateRange(dateRange!);
    }
    return map;
  }

  /// Deprecated: Use dateRange instead.
  @Deprecated('Use dateRange instead')
  @JsonKey(includeIfNull: false)
  final int? addedBetweenDays;

  /// Flexible date range configuration.
  @JsonKey(includeIfNull: false)
  final CrawlDateRange? dateRange;

  /// Parses a date_range value from JSON (supports multiple formats).
  static CrawlDateRange? _parseDateRange(dynamic value) {
    if (value == null) return null;

    // Integer format: date_range: 7
    if (value is int) {
      return CrawlDateRangeDays(value);
    }

    // String format: date_range: "current_month"
    if (value is String) {
      return CrawlDateRangeShortcut(value);
    }

    // Object format
    if (value is Map) {
      // Absolute range: { start: "...", end: "..." }
      if (value.containsKey('start') && value.containsKey('end')) {
        final startStr = value['start'] as String;
        final endStr = value['end'] as String;
        return CrawlDateRangeAbsolute(
          start: DateTime.parse(startStr),
          end: DateTime.parse(endStr),
        );
      }

      // Time unit: { days: 7 } or { weeks: 2 } or { months: 1 }
      if (value.containsKey('days') ||
          value.containsKey('weeks') ||
          value.containsKey('months')) {
        return CrawlDateRangeTimeUnit(
          days: value['days'] as int?,
          weeks: value['weeks'] as int?,
          months: value['months'] as int?,
        );
      }
    }

    throw FormatException('Invalid date_range format: $value');
  }

  /// Serializes a date_range to JSON.
  static dynamic _serializeDateRange(CrawlDateRange range) {
    return switch (range) {
      CrawlDateRangeDays(:final days) => days,
      CrawlDateRangeShortcut(:final shortcut) => shortcut,
      CrawlDateRangeTimeUnit(:final days, :final weeks, :final months) => {
        'days': days,
        'weeks': weeks,
        'months': months,
      }..removeWhere((key, value) => value == null),
      CrawlDateRangeAbsolute(:final start, :final end) => {
        'start': start.toIso8601String().split('T')[0],
        'end': end.toIso8601String().split('T')[0],
      },
    };
  }
}

/// Processing options for the job.
@JsonSerializable(fieldRename: FieldRename.snake)
class CrawlOptions {
  const CrawlOptions({
    this.deduplicate,
    this.addPlaylistTracksBasedOn = PlaylistTrackDateMode.releaseDate,
    this.updateMode = CrawlUpdateMode.replace,
    this.includeArtistAppearances = true,
  });

  factory CrawlOptions.fromJson(Map<String, dynamic> json) =>
      _$CrawlOptionsFromJson(json);

  Map<String, dynamic> toJson() => _$CrawlOptionsToJson(this);

  /// Deduplication mode.
  @JsonKey(includeIfNull: false)
  final DeduplicateMode? deduplicate;

  /// Determines which date to use for filtering playlist tracks.
  /// - `added_date`: Use when track was added to playlist
  /// - `release_date`: Use track's album release date (default)
  @JsonKey(defaultValue: PlaylistTrackDateMode.releaseDate)
  final PlaylistTrackDateMode addPlaylistTracksBasedOn;

  /// How to update the target playlist (only applies when output_playlist.id is
  /// specified).
  /// - `replace`: Clear and replace all tracks (default)
  /// - `append`: Add new tracks without clearing existing ones
  @JsonKey(defaultValue: CrawlUpdateMode.replace)
  final CrawlUpdateMode updateMode;

  /// Whether to include tracks from releases where the artist appears as a
  /// featured artist (e.g., remixes, features, collaborations on other
  /// artists' albums). When enabled, the crawl fetches albums in the
  /// `appears_on` group and filters tracks to only include those where the
  /// artist is credited.
  @JsonKey(defaultValue: true)
  final bool includeArtistAppearances;
}

/// Input sources for the job.
@JsonSerializable(fieldRename: FieldRename.snake)
class CrawlInputs {
  const CrawlInputs({
    this.playlists,
    this.artists,
    this.labels,
    this.youtubeChannels,
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

  /// List of YouTube channel handles or IDs (e.g., '@SkankandbassUK' or
  /// 'UCCXCgbZcT7rjU0vS0POSWIQ').
  /// Can include YAML anchor references.
  @JsonKey(includeIfNull: false)
  final List<String>? youtubeChannels;
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

/// Update modes for target playlists.
@JsonEnum()
enum CrawlUpdateMode {
  /// Clear and replace all tracks in the playlist.
  @JsonValue('replace')
  replace,

  /// Add new tracks without clearing existing ones.
  @JsonValue('append')
  append,
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
