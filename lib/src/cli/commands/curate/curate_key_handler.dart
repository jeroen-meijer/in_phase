import 'package:in_phase/src/cli/commands/curate/curate.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:nocterm/nocterm.dart';

/// Max target playlist key (1-9).
const _maxTargetKey = 9;

/// Handles keyboard events during curate playback (Nocterm [KeyboardEvent]).
class CurateKeyHandler {
  CurateKeyHandler(this._context);

  final CurateContext _context;

  Future<KeyResult> handleKey(
    KeyboardEvent event,
    CurrentTrackInfo currentTrack,
    TrackPlaybackState playbackState,
  ) async {
    if (event.logicalKey == LogicalKey.arrowLeft ||
        event.logicalKey == LogicalKey.arrowRight) {
      return _handleArrowSeek(
        event.logicalKey == LogicalKey.arrowLeft,
        currentTrack.durationMs,
        playbackState,
      );
    }

    if (event.logicalKey == LogicalKey.space) {
      return KeyResultNext();
    }

    final config = _context.config;

    final digit = _digitFromLogicalKey(event.logicalKey);
    if (digit != null &&
        digit >= 1 &&
        digit <= _maxTargetKey &&
        digit <= config.targets.length) {
      return _handleAddToTarget(currentTrack, digit);
    }

    final ch = event.character?.toLowerCase();
    if (ch == null || ch.isEmpty) {
      return KeyResultIgnore();
    }

    if (ch == 'q' || event.logicalKey == LogicalKey.keyQ) {
      return KeyResultQuit();
    }

    if (ch == 'c') {
      final id = currentTrack.track.id;
      if (id == null || id.isEmpty) {
        return KeyResultStay(
          '✗ No track id for URL',
          null,
          tone: CurateMessageTone.error,
        );
      }
      final url = 'https://open.spotify.com/track/$id';
      final ok = await copyTextToClipboard(url);
      return KeyResultStay(
        ok ? '✓ Copied track URL' : '✗ Clipboard unavailable',
        null,
        tone: ok ? CurateMessageTone.success : CurateMessageTone.error,
      );
    }

    if (ch == ' ' || ch == 's' || ch == 'n') {
      return KeyResultNext();
    }

    if (ch == 'r') {
      final newState = TrackPlaybackState(
        positionMs: config.startPositionMs.clamp(0, currentTrack.durationMs),
        startedAt: DateTime.now(),
      );
      await _context.api.player.seek(
        newState.positionMs,
        retrievePlaybackState: false,
      );
      return KeyResultStay(
        '↺ ${config.startPosition}',
        newState,
        tone: CurateMessageTone.accent,
      );
    }

    if (ch == 'l') {
      final trackId = currentTrack.track.id;
      if (trackId == null || trackId.isEmpty) {
        return KeyResultStay(
          '✗ No track id for Liked Songs',
          null,
          tone: CurateMessageTone.error,
        );
      }
      try {
        final likedIds = await _context.likedTrackIdsFuture;
        if (likedIds.contains(trackId)) {
          return KeyResultStay(
            'Already in Liked Songs',
            null,
            tone: CurateMessageTone.warning,
          );
        }
        await _context.api.me.tracks.saveOne(trackId);
        likedIds.add(trackId);
        return KeyResultStay(
          '✓ Added to Liked Songs',
          null,
          tone: CurateMessageTone.success,
        );
      } catch (e) {
        return KeyResultStay(
          '✗ Liked Songs: $e',
          null,
          tone: CurateMessageTone.error,
        );
      }
    }

    final targetNum = int.tryParse(ch);
    if (targetNum != null &&
        targetNum >= 1 &&
        targetNum <= _maxTargetKey &&
        targetNum <= config.targets.length) {
      return _handleAddToTarget(currentTrack, targetNum);
    }

    return KeyResultIgnore();
  }

  int? _digitFromLogicalKey(LogicalKey key) {
    if (key == LogicalKey.digit1) {
      return 1;
    }
    if (key == LogicalKey.digit2) {
      return 2;
    }
    if (key == LogicalKey.digit3) {
      return 3;
    }
    if (key == LogicalKey.digit4) {
      return 4;
    }
    if (key == LogicalKey.digit5) {
      return 5;
    }
    if (key == LogicalKey.digit6) {
      return 6;
    }
    if (key == LogicalKey.digit7) {
      return 7;
    }
    if (key == LogicalKey.digit8) {
      return 8;
    }
    if (key == LogicalKey.digit9) {
      return 9;
    }
    return null;
  }

  Future<KeyResult> _handleArrowSeek(
    bool left,
    int durationMs,
    TrackPlaybackState playbackState,
  ) async {
    final config = _context.config;
    final deltaMs = left ? -config.seekStep * 1000 : config.seekStep * 1000;
    final result = await _seek(
      deltaMs,
      durationMs,
      playbackState.positionMs,
      playbackState.startedAt,
    );
    return result != null
        ? KeyResultStay(
            null,
            TrackPlaybackState(
              positionMs: result.$1,
              startedAt: result.$2,
            ),
          )
        : KeyResultIgnore();
  }

  Future<KeyResult> _handleAddToTarget(
    CurrentTrackInfo currentTrack,
    int targetNum,
  ) async {
    final config = _context.config;
    final target = config.targets[targetNum - 1];
    final targetTrackIds = await _context.targetTrackIdsFuture;
    if (targetTrackIds[target.playlistId]?.contains(currentTrack.track.id) ??
        false) {
      return KeyResultStay(
        'Already in ${target.name}',
        null,
        tone: CurateMessageTone.warning,
      );
    }

    try {
      await _context.api.playlists.addTracks(
        [currentTrack.trackUri],
        target.playlistId,
      );
      targetTrackIds[target.playlistId] ??= {};
      targetTrackIds[target.playlistId]!.add(currentTrack.track.id!);
      var status = '✓ Added to ${target.name}';
      var tone = CurateMessageTone.success;
      if (config.autoAddToLikes) {
        final trackId = currentTrack.track.id!;
        try {
          final likedIds = await _context.likedTrackIdsFuture;
          if (!likedIds.contains(trackId)) {
            await _context.api.me.tracks.saveOne(trackId);
            likedIds.add(trackId);
            status += '  ✓ Liked';
          }
        } catch (e) {
          status += '  ✗ Liked: $e';
          tone = CurateMessageTone.error;
        }
      }
      if (config.nextAfterAdd &&
          currentTrack.index + 1 < currentTrack.tracksToCurateLength) {
        return KeyResultNextWithStatus(status);
      }
      return KeyResultStay(status, null, tone: tone);
    } catch (e) {
      return KeyResultStay(
        '✗ ${target.name}: $e',
        null,
        tone: CurateMessageTone.error,
      );
    }
  }

  Future<(int, DateTime)?> _seek(
    int deltaMs,
    int durationMs,
    int startPositionMs,
    DateTime startedAt,
  ) async {
    final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
    final currentMs = startPositionMs + elapsedMs;
    final newPos = (currentMs + deltaMs).clamp(0, durationMs);
    try {
      await _context.api.player.seek(newPos, retrievePlaybackState: false);
      return (newPos, DateTime.now());
    } catch (_) {
      return null;
    }
  }
}
