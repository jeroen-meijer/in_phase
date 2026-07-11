import 'package:in_phase/src/cli/commands/curate/curate_types.dart';

/// Adds the current track to [playlistId] and returns the same [KeyResult]
/// shapes as target-key adds (`next_after_add`, `auto_add_to_likes`, etc.).
Future<KeyResult> curateAddTrackToPlaylist({
  required CurateContext context,
  required CurrentTrackInfo currentTrack,
  required String playlistId,
  required String playlistName,
}) async {
  final trackId = currentTrack.track.id;
  if (trackId == null || trackId.isEmpty) {
    return KeyResultStay(
      '✗ No track id',
      null,
      tone: CurateMessageTone.error,
    );
  }

  final alreadyIn = _alreadyInPlaylist(context, playlistId, trackId);
  if (alreadyIn == true) {
    return KeyResultStay(
      'Already in $playlistName',
      null,
      tone: CurateMessageTone.warning,
    );
  }

  try {
    await context.api.playlists.addTracks(
      [currentTrack.trackUri],
      playlistId,
    );
    _markAdded(context, playlistId, trackId);

    return _finishAddOrMove(
      context: context,
      currentTrack: currentTrack,
      status: '✓ Added to $playlistName',
      tone: CurateMessageTone.success,
    );
  } catch (e) {
    return KeyResultStay(
      '✗ $playlistName: $e',
      null,
      tone: CurateMessageTone.error,
    );
  }
}

/// Moves the current track from the current move source playlist to
/// [playlistId].
///
/// When the target already has the track, only removes from source (idempotent
/// move). Updates the runtime move source to the target on success.
Future<KeyResult> curateMoveTrackToPlaylist({
  required CurateContext context,
  required CurateRuntimeState runtime,
  required CurrentTrackInfo currentTrack,
  required String playlistId,
  required String playlistName,
}) async {
  final trackId = currentTrack.track.id;
  if (trackId == null || trackId.isEmpty) {
    return KeyResultStay(
      '✗ No track id',
      null,
      tone: CurateMessageTone.error,
    );
  }

  final moveSourcePlaylistId = runtime.moveSourcePlaylistId;
  if (playlistId == moveSourcePlaylistId) {
    final sourceName = context.playlistDisplayName(moveSourcePlaylistId);
    return KeyResultStay(
      'Cannot move to the same playlist ($sourceName)',
      null,
      tone: CurateMessageTone.warning,
    );
  }

  final sourceName = context.playlistDisplayName(moveSourcePlaylistId);
  final alreadyIn = _alreadyInPlaylist(context, playlistId, trackId);

  try {
    if (alreadyIn != true) {
      await context.api.playlists.addTracks(
        [currentTrack.trackUri],
        playlistId,
      );
      _markAdded(context, playlistId, trackId);
    }

    await context.api.playlists.removeTracks(
      [currentTrack.trackUri],
      moveSourcePlaylistId,
    );
    _markRemoved(context, moveSourcePlaylistId, trackId);
    runtime.moveSourcePlaylistId = playlistId;

    final status = alreadyIn == true
        ? 'Already in $playlistName — removed from $sourceName'
        : '✓ Moved to $playlistName (from $sourceName)';

    return _finishAddOrMove(
      context: context,
      currentTrack: currentTrack,
      status: status,
      tone: alreadyIn == true
          ? CurateMessageTone.warning
          : CurateMessageTone.success,
    );
  } catch (e) {
    if (alreadyIn != true) {
      return KeyResultStay(
        '✗ Move to $playlistName: $e',
        null,
        tone: CurateMessageTone.error,
      );
    }
    return KeyResultStay(
      '✗ Remove from $sourceName: $e',
      null,
      tone: CurateMessageTone.error,
    );
  }
}

Future<KeyResult> _finishAddOrMove({
  required CurateContext context,
  required CurrentTrackInfo currentTrack,
  required String status,
  required CurateMessageTone tone,
}) async {
  var message = status;
  var resultTone = tone;
  final trackId = currentTrack.track.id!;

  if (context.config.autoAddToLikes) {
    try {
      if (!await context.likedCache.isLiked(trackId)) {
        await context.api.me.tracks.saveOne(trackId);
        context.likedCache.markLiked(trackId);
        message += '  ✓ Liked';
      }
    } catch (e) {
      message += '  ✗ Liked: $e';
      resultTone = CurateMessageTone.error;
    }
  }

  if (context.config.nextAfterAdd &&
      currentTrack.index + 1 < currentTrack.tracksToCurateLength) {
    return KeyResultNextWithStatus(message);
  }
  return KeyResultStay(message, null, tone: resultTone);
}

void _markAdded(CurateContext context, String playlistId, String trackId) {
  context.targetPlaylists.markAdded(playlistId, trackId);
  context.userPlaylists.markAdded(playlistId, trackId);
}

void _markRemoved(CurateContext context, String playlistId, String trackId) {
  context.targetPlaylists.markRemoved(playlistId, trackId);
  context.userPlaylists.markRemoved(playlistId, trackId);
}

bool? _alreadyInPlaylist(
  CurateContext context,
  String playlistId,
  String trackId,
) {
  if (context.targetPlaylists.loaded &&
      context.targetPlaylists.ids.containsKey(playlistId)) {
    return context.targetPlaylists.ids[playlistId]!.contains(trackId);
  }
  if (context.userPlaylists.sessionContains(playlistId, trackId)) {
    return true;
  }
  return null;
}
