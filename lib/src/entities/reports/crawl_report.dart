import 'package:equatable/equatable.dart';

/// {@template crawl_report}
/// Top-level report for a complete crawl command execution.
/// {@endtemplate}
class CrawlReport {
  /// {@macro crawl_report}
  const CrawlReport({
    required this.startTime,
    required this.endTime,
    required this.jobReports,
  });

  /// When the crawl command started.
  final DateTime startTime;

  /// When the crawl command completed.
  final DateTime endTime;

  /// Reports for each job that was processed.
  final List<CrawlJobReport> jobReports;

  /// Total runtime of the crawl command.
  Duration get totalRuntime => endTime.difference(startTime);
}

/// {@template crawl_job_report}
/// Report for a single crawl job.
/// {@endtemplate}
class CrawlJobReport {
  /// {@macro crawl_job_report}
  const CrawlJobReport({
    required this.jobName,
    required this.startTime,
    required this.endTime,
    required this.trackEntries,
  });

  /// Name of the job.
  final String jobName;

  /// When this job started processing.
  final DateTime startTime;

  /// When this job completed processing.
  final DateTime endTime;

  /// All tracks that were added in this job.
  final List<CrawlTrackEntry> trackEntries;

  /// Runtime for this specific job.
  Duration get runtime => endTime.difference(startTime);

  /// Total number of tracks in this job.
  int get trackCount => trackEntries.length;
}

/// {@template crawl_track_entry}
/// Represents a single track that was added during a crawl.
/// {@endtemplate}
class CrawlTrackEntry {
  /// {@macro crawl_track_entry}
  const CrawlTrackEntry({
    required this.trackName,
    required this.artistNames,
    required this.sourceInfo,
    required this.reason,
  });

  /// Name of the track.
  final String trackName;

  /// Names of all artists on the track.
  final List<String> artistNames;

  /// Information about where this track came from.
  final CrawlSourceInfo sourceInfo;

  /// Human-readable reason why this track was included.
  final String reason;

  /// Formatted artist string for display.
  String get artistsString => artistNames.join(', ');
}

/// {@template crawl_source_info}
/// Information about the source of a collected track.
/// {@endtemplate}
sealed class CrawlSourceInfo with EquatableMixin {
  /// {@macro crawl_source_info}
  const CrawlSourceInfo();

  /// Display name for the source.
  String get displayName;

  /// Type name for the source (e.g., "Playlist", "Artist", "Label").
  String get typeName;

  @override
  List<Object?> get props => [];
}

/// {@template crawl_source_info_playlist}
/// Source information for a track from a playlist.
/// {@endtemplate}
class CrawlSourceInfoPlaylist extends CrawlSourceInfo {
  /// {@macro crawl_source_info_playlist}
  const CrawlSourceInfoPlaylist({
    required this.id,
    required this.name,
  });

  /// The Spotify ID of the playlist.
  final String id;

  /// The name of the playlist.
  final String name;

  @override
  String get displayName => name;

  @override
  String get typeName => 'Playlist';

  @override
  List<Object?> get props => [id, name];
}

/// {@template crawl_source_info_artist}
/// Source information for a track from an artist.
/// {@endtemplate}
class CrawlSourceInfoArtist extends CrawlSourceInfo {
  /// {@macro crawl_source_info_artist}
  const CrawlSourceInfoArtist({
    required this.id,
    required this.name,
  });

  /// The Spotify ID of the artist.
  final String id;

  /// The name of the artist.
  final String name;

  @override
  String get displayName => name;

  @override
  String get typeName => 'Artist';

  @override
  List<Object?> get props => [id, name];
}

/// {@template crawl_source_info_label}
/// Source information for a track from a label.
/// {@endtemplate}
class CrawlSourceInfoLabel extends CrawlSourceInfo {
  /// {@macro crawl_source_info_label}
  const CrawlSourceInfoLabel({
    required this.name,
  });

  /// The name of the label.
  final String name;

  @override
  String get displayName => name;

  @override
  String get typeName => 'Label';

  @override
  List<Object?> get props => [name];
}
