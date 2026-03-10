import 'package:dart_console/dart_console.dart';
import 'package:dcli/dcli.dart';
import 'package:in_phase/src/cli/commands/curate/curate.dart';
import 'package:in_phase/src/misc/misc.dart';

/// Max target playlist key (1-9).
const _maxTargetKey = 9;

/// Handles key presses during curate playback.
class CurateKeyHandler {
  CurateKeyHandler(this._context);

  final CurateContext _context;

  Future<KeyResult> handleKey(
    Key key,
    CurrentTrackInfo currentTrack,
    TrackPlaybackState playbackState,
  ) async {
    if (key.isControl) {
      return _handleControlKey(
        key,
        currentTrack.durationMs,
        playbackState,
      );
    }

    final config = _context.config;
    final char = key.char.isEmpty ? '' : key.char.toLowerCase();
    if (char == 'q') return KeyResultQuit();

    if (char == ' ' || char == 's' || char == 'n') return KeyResultNext();

    if (char == 'r') {
      final newState = TrackPlaybackState(
        positionMs: config.startPositionMs.clamp(0, currentTrack.durationMs),
        startedAt: DateTime.now(),
      );
      await _context.api.player.seek(
        newState.positionMs,
        retrievePlaybackState: false,
      );
      return KeyResultStay(
        '${cyan('↺')} ${config.startPosition}',
        newState,
      );
    }

    final targetNum = int.tryParse(char);
    if (targetNum != null &&
        targetNum >= 1 &&
        targetNum <= _maxTargetKey &&
        targetNum <= config.targets.length) {
      return _handleAddToTarget(currentTrack, targetNum);
    }

    return KeyResultIgnore();
  }

  Future<KeyResult> _handleControlKey(
    Key key,
    int durationMs,
    TrackPlaybackState playbackState,
  ) async {
    final config = _context.config;
    switch (key.controlChar) {
      case ControlCharacter.arrowLeft:
      case ControlCharacter.arrowRight:
        final deltaMs = key.controlChar == ControlCharacter.arrowLeft
            ? -config.seekStep * 1000
            : config.seekStep * 1000;
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

      case ControlCharacter.ctrlC:
        return KeyResultQuit();

      case ControlCharacter.enter:
      case _:
        return KeyResultIgnore();
    }
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
        '${orange('-')} Already in ${bold(target.name)}',
        null,
      );
    }

    try {
      await _context.api.playlists.addTracks(
        [currentTrack.trackUri],
        target.playlistId,
      );
      targetTrackIds[target.playlistId] ??= {};
      targetTrackIds[target.playlistId]!.add(currentTrack.track.id!);
      final status = '${green('✓')} Added to ${bold(target.name)}';
      if (config.nextAfterAdd &&
          currentTrack.index + 1 < currentTrack.tracksToCurateLength) {
        return KeyResultNextWithStatus(status);
      }
      return KeyResultStay(status, null);
    } catch (e) {
      return KeyResultStay(
        '${red('✗')} ${bold(target.name)}: $e',
        null,
      );
    }
  }

  /// Seeks by [deltaMs] from the computed current position. Returns the new
  /// (positionMs, startedAt) for the caller to update tracked state, or null
  /// if the seek failed.
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
