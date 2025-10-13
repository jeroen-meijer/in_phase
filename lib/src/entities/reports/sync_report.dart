import 'package:rkdb_dart/src/entities/entities.dart';
import 'package:rkdb_dart/src/spotify/spotify.dart';

/// A complete sync report for a sync command run.
class SyncReport {
  const SyncReport({
    required this.startTime,
    required this.endTime,
    required this.playlistReports,
  });

  final DateTime startTime;
  final DateTime endTime;
  final List<SyncPlaylistReport> playlistReports;

  Duration get totalDuration => endTime.difference(startTime);

  int get totalTracks => playlistReports.fold(
    0,
    (sum, report) => sum + report.tracks.length,
  );

  int get totalAdded => playlistReports.fold(
    0,
    (sum, report) => sum + report.tracks.whereType<SyncTrackAdded>().length,
  );

  int get totalCustom => playlistReports.fold(
    0,
    (sum, report) => sum + report.tracks.whereType<SyncTrackCustom>().length,
  );

  int get totalMissing => playlistReports.fold(
    0,
    (sum, report) => sum + report.tracks.whereType<SyncTrackMissing>().length,
  );
}

/// Report for a single playlist sync.
class SyncPlaylistReport {
  const SyncPlaylistReport({
    required this.playlistId,
    required this.playlistName,
    required this.snapshotId,
    required this.startTime,
    required this.endTime,
    required this.tracks,
    required this.wasFromCache,
  });

  final SpotifyPlaylistId playlistId;
  final String playlistName;
  final String snapshotId;
  final DateTime startTime;
  final DateTime endTime;
  final List<SyncTrackEntry> tracks;
  final bool wasFromCache;

  Duration get duration => endTime.difference(startTime);
}

/// Base class for sync track entries.
sealed class SyncTrackEntry {
  const SyncTrackEntry({
    required this.trackId,
    required this.trackName,
    required this.artistNames,
  });

  final SpotifyTrackId trackId;
  final String trackName;
  final List<String> artistNames;
}

/// A track that was successfully added to Rekordbox.
class SyncTrackAdded extends SyncTrackEntry {
  const SyncTrackAdded({
    required super.trackId,
    required super.trackName,
    required super.artistNames,
    required this.rekordboxSongId,
    required this.rekordboxTitle,
  });

  final RekordboxSongId rekordboxSongId;
  final String rekordboxTitle;
}

/// A custom track that was inserted (not from Spotify playlist).
class SyncTrackCustom extends SyncTrackEntry {
  const SyncTrackCustom({
    required super.trackId,
    required super.trackName,
    required super.artistNames,
    required this.rekordboxSongId,
    required this.rekordboxTitle,
    required this.position,
  });

  final RekordboxSongId rekordboxSongId;
  final String rekordboxTitle;
  final int position;
}

/// A track that couldn't be matched in Rekordbox.
class SyncTrackMissing extends SyncTrackEntry {
  const SyncTrackMissing({
    required super.trackId,
    required super.trackName,
    required super.artistNames,
    this.itunesUrl,
  });

  final String? itunesUrl;
}

