import 'package:in_phase/src/entities/reports/sync_report.dart';
import 'package:in_phase/src/spotify/types.dart';

/// Progress events for sync operations
sealed class SyncProgress {
  const SyncProgress();
}

class SyncProgressStarted extends SyncProgress {
  const SyncProgressStarted({required this.playlistCount});
  final int playlistCount;
}

class SyncProgressPlaylistStarted extends SyncProgress {
  const SyncProgressPlaylistStarted({
    required this.playlistName,
    required this.playlistId,
  });
  final String playlistName;
  final SpotifyPlaylistId playlistId;
}

class SyncProgressTrackProcessed extends SyncProgress {
  const SyncProgressTrackProcessed({required this.trackEntry});
  final SyncTrackEntry trackEntry;
}

class SyncProgressPlaylistCompleted extends SyncProgress {
  const SyncProgressPlaylistCompleted({required this.report});
  final SyncPlaylistReport report;
}

class SyncProgressCompleted extends SyncProgress {
  const SyncProgressCompleted({required this.report});
  final SyncReport report;
}

class SyncProgressError extends SyncProgress {
  const SyncProgressError({required this.message, this.error});
  final String message;
  final Object? error;
}
