import 'package:in_phase/src/cli/commands/curate/curate_liked_cache.dart';
import 'package:in_phase/src/cli/commands/curate/curate_user_playlists_cache.dart';
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

/// A config target string resolved to a Spotify playlist at session start.
class CurateResolvedTarget {
  const CurateResolvedTarget({
    required this.input,
    required this.playlistId,
    required this.name,
  });

  /// Config string, e.g. `KEYSORT`.
  final String input;

  /// Resolved Spotify playlist ID.
  final String playlistId;

  /// Display name from Spotify after resolution.
  final String name;
}

/// Mutable per-session UI state (move mode, chained move source).
class CurateRuntimeState {
  CurateRuntimeState({required String sourcePlaylistId})
    : moveSourcePlaylistId = sourcePlaylistId;

  bool moveMode = false;

  /// Playlist the next move removes from; resets per track to the curated
  /// playlist id.
  String moveSourcePlaylistId;
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
    required this.sourcePlaylistId,
    required this.playlistName,
    required this.resolvedTargets,
    required this.tracks,
    required this.tracksToCurate,
    required this.startIndex,
    required this.targetPlaylists,
    required this.likedCache,
    required this.userPlaylists,
  });

  final SpotifyApi api;
  final CurateConfig config;

  /// Playlist being curated (move default source).
  final String sourcePlaylistId;

  final String playlistName;

  /// Config targets resolved at session start (keys 1–9).
  final List<CurateResolvedTarget> resolvedTargets;

  final List<Track> tracks;
  final List<Track> tracksToCurate;
  final int startIndex;

  /// Target playlists: duplicate checks once preload has finished.
  final CurateTargetPlaylistsCache targetPlaylists;

  /// Liked Songs: fast per-track checks; full library preload for footer hints.
  final CurateLikedTracksCache likedCache;

  /// User-owned/collaborative playlists for the add-to-playlist picker (`f`).
  final CurateUserPlaylistsCache userPlaylists;

  /// Display name for [playlistId] (resolved targets or curated playlist).
  String playlistDisplayName(String playlistId) {
    if (playlistId == sourcePlaylistId) {
      return playlistName;
    }
    for (final target in resolvedTargets) {
      if (target.playlistId == playlistId) {
        return target.name;
      }
    }
    return playlistId;
  }
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
