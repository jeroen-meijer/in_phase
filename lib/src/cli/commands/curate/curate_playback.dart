import 'package:spotify/spotify.dart';

/// Starts curate tracks on the user's active Spotify device at a position.
///
/// Spotify's desktop app can accept a play request for bare track URIs
/// (HTTP 204) and then play nothing. The first [start] of a session sends
/// such a request and checks that the track plays. When it does not, that
/// start and every later one play the track inside its album instead, which
/// takes a single request.
final class CuratePlayback {
  CuratePlayback(this._player);

  final PlayerEndpoint _player;

  /// Whether bare track-URI requests start playback; `null` until the first
  /// start of the session has checked.
  bool? _trackUrisPlay;

  Future<void> start(Track track, {required int positionMs}) async {
    final trackUri = 'spotify:track:${track.id}';
    final albumUri = track.album?.uri;
    if (albumUri == null || albumUri.isEmpty) {
      await _startTrack(trackUri, positionMs);
      return;
    }
    switch (_trackUrisPlay) {
      case true:
        await _startTrack(trackUri, positionMs);
      case false:
        await _startInAlbum(albumUri, trackUri, positionMs);
      case null:
        await _startTrack(trackUri, positionMs);
        final plays = _trackUrisPlay = await _isPlaying(track.id!);
        if (!plays) {
          await _startInAlbum(albumUri, trackUri, positionMs);
        }
    }
  }

  Future<void> _startTrack(String trackUri, int positionMs) =>
      _player.startWithTracks(
        [trackUri],
        positionMs: positionMs,
        retrievePlaybackState: false,
      );

  Future<void> _startInAlbum(
    String albumUri,
    String trackUri,
    int positionMs,
  ) =>
      // spotify 0.16.1's startWithContext cannot send position_ms.
      // ignore: deprecated_member_use
      _player.startOrResume(
        options: _AlbumTrackOptions(
          albumUri: albumUri,
          trackUri: trackUri,
          positionMs: positionMs,
        ),
        retrievePlaybackState: false,
      );

  Future<bool> _isPlaying(String trackId) async {
    for (var attempt = 0; attempt < 10; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      try {
        final playback = await _player.currentlyPlaying();
        if (playback.isPlaying == true && playback.item?.id == trackId) {
          return true;
        }
      } catch (_) {
        // The player can briefly report no state while changing tracks.
      }
    }
    return false;
  }
}

final class _AlbumTrackOptions extends StartOrResumeOptions {
  _AlbumTrackOptions({
    required this.albumUri,
    required this.trackUri,
    required this.positionMs,
  });

  final String albumUri;
  final String trackUri;
  final int positionMs;

  @override
  Map<String, dynamic> toJson() => {
    'context_uri': albumUri,
    'offset': {'uri': trackUri},
    'position_ms': positionMs,
  };
}
