import 'package:in_phase/src/entities/entities.dart';
import 'package:spotify/spotify.dart';

/// Thrown to exit the curate command with a specific exit code (setup phase).
class CurateExit implements Exception {
  CurateExit(this.code);
  final int code;
}

/// Visual emphasis for a one-line [KeyResult] message (Nocterm color mapping).
enum CurateMessageTone {
  neutral,
  success,
  warning,
  error,
  accent,
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

/// Owns the Spotify client for a session; call [dispose] before process exit.
class CurateSession {
  CurateSession({required this.context});

  final CurateContext context;
  var _disposed = false;

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    // TODO(jeroen-meijer): Create issue for this lint ignore and refactor
    // ignore: invalid_use_of_visible_for_testing_member
    final client = await context.api.client;
    client.close();
  }
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
  KeyResultStay(
    this.message,
    this.updatedState, {
    this.tone = CurateMessageTone.neutral,
  });
  final String? message;
  final TrackPlaybackState? updatedState;
  final CurateMessageTone tone;
}

class KeyResultIgnore extends KeyResult {
  KeyResultIgnore();
}
