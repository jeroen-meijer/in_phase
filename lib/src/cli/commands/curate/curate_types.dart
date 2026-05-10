import 'package:in_phase/src/entities/entities.dart';
import 'package:spotify/spotify.dart';

/// Thrown to exit the curate command with a specific exit code.
class CurateExit implements Exception {
  CurateExit(this.code);
  final int code;
}

/// Bundles track-specific data needed by key handlers.
class CurrentTrackInfo {
  CurrentTrackInfo({
    required this.track,
    required this.trackUri,
    required this.durationMs,
    required this.index,
    required this.tracksToCurateLength,
  });

  final Track track;
  final String trackUri;
  final int durationMs;
  final int index;
  final int tracksToCurateLength;
}

/// Immutable context for the curate session.
class CurateContext {
  CurateContext({
    required this.api,
    required this.config,
    required this.playlistName,
    required this.tracks,
    required this.tracksToCurate,
    required this.startIndex,
    required this.targetTrackIdsFuture,
    required this.likedTrackIdsFuture,
  });

  final SpotifyApi api;
  final CurateConfig config;
  final String playlistName;
  final List<Track> tracks;
  final List<Track> tracksToCurate;
  final int startIndex;
  final Future<Map<String, Set<String>>> targetTrackIdsFuture;

  /// Spotify Liked Songs at session start, updated when this session saves a
  /// track to the library (key `l` or [CurateConfig.autoAddToLikes]).
  final Future<Set<String>> likedTrackIdsFuture;
}

/// Tracks playback position for a single track.
class TrackPlaybackState {
  TrackPlaybackState({required this.positionMs, required this.startedAt});
  final int positionMs;
  final DateTime startedAt;
}

/// Result of processing a key press.
sealed class KeyResult {}

class KeyResultQuit extends KeyResult {
  KeyResultQuit();
}

class KeyResultNext extends KeyResult {
  KeyResultNext();
}

class KeyResultNextWithStatus extends KeyResult {
  KeyResultNextWithStatus(this.status);
  final String status;
}

class KeyResultStay extends KeyResult {
  KeyResultStay(this.status, this.updatedState);
  final String? status;
  final TrackPlaybackState? updatedState;
}

class KeyResultIgnore extends KeyResult {
  KeyResultIgnore();
}
