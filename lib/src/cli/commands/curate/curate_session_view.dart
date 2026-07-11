import 'dart:async';

import 'package:dcli/dcli.dart' show printerr;
import 'package:in_phase/src/cli/commands/curate/curate.dart';
import 'package:in_phase/src/logger/logger.dart';
import 'package:io/io.dart';
import 'package:nocterm/nocterm.dart';
import 'package:spotify/spotify.dart';

/// Full-screen Nocterm UI for a curate session.
///
/// [onExit] should dispose the [CurateSession] and call [shutdownApp] (which
/// exits the process).
final class CurateSessionView extends StatefulComponent {
  const CurateSessionView({
    required this.session,
    required this.onExit,
    super.key,
  });

  final CurateSession session;
  final Future<void> Function(int exitCode) onExit;

  @override
  State<CurateSessionView> createState() => _CurateSessionViewState();
}

final class _CurateSessionViewState extends State<CurateSessionView> {
  late final CurateKeyHandler _keyHandler;
  late final CurateRuntimeState _runtime;
  var _trackIndex = 0;
  late TrackPlaybackState _playbackState;
  var _busy = false;
  var _startingPlayback = false;
  var _sessionEnded = false;
  final _activityLog = <String>[];
  Timer? _clock;
  Map<String, Set<String>>? _playlistTrackIds;
  Set<String>? _likedIds;

  CurateContext get _ctx => component.session.context;

  @override
  void initState() {
    super.initState();
    _runtime = CurateRuntimeState(
      sourcePlaylistId: _ctx.sourcePlaylistId,
    );
    _keyHandler = CurateKeyHandler(_ctx, _runtime);
    _playbackState = _playbackStateForIndex(_trackIndex);
    unawaited(_preloadFooterLibraryIds());
    unawaited(_startPlaybackForCurrentTrack());
    _clock = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!_sessionEnded && mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  TrackPlaybackState _playbackStateForIndex(int index) {
    final track = _ctx.tracksToCurate[index];
    final durationMs = track.durationMs ?? 0;
    final pos = _ctx.config.startPositionMs.clamp(0, durationMs);
    return TrackPlaybackState(positionMs: pos, startedAt: DateTime.now());
  }

  int get _absolutePosition => _ctx.startIndex + _trackIndex + 1;

  int _liveProgressMs(int durationMs) {
    final elapsed = DateTime.now()
        .difference(_playbackState.startedAt)
        .inMilliseconds;
    return (_playbackState.positionMs + elapsed).clamp(0, durationMs);
  }

  Future<void> _preloadFooterLibraryIds() async {
    try {
      await _ctx.targetPlaylists.ready;
      final likes = await _ctx.likedCache.idsForFooter;
      if (!mounted) {
        return;
      }
      setState(() {
        _playlistTrackIds = _ctx.targetPlaylists.ids;
        _likedIds = likes;
      });
    } catch (e) {
      _logActivity('✗ Could not load library hints: $e');
    }
  }

  CurrentTrackInfo _currentTrackInfo(Track track, int durationMs) {
    return CurrentTrackInfo(
      track: track,
      trackUri: 'spotify:track:${track.id}',
      durationMs: durationMs,
      index: _trackIndex,
      tracksToCurateLength: _ctx.tracksToCurate.length,
    );
  }

  Future<void> _startPlaybackForCurrentTrack() async {
    if (_sessionEnded) {
      return;
    }
    if (_trackIndex >= _ctx.tracksToCurate.length) {
      await _complete(ExitCode.success.code);
      return;
    }
    final track = _ctx.tracksToCurate[_trackIndex];
    final trackUri = 'spotify:track:${track.id}';
    setState(() => _startingPlayback = true);
    try {
      await _ctx.api.player.startWithTracks(
        [trackUri],
        positionMs: _playbackState.positionMs,
        retrievePlaybackState: false,
      );
    } catch (e) {
      _logActivity(
        '✗ Playback failed: $e — press n/s/space for next or q to quit',
      );
    } finally {
      if (mounted) {
        setState(() => _startingPlayback = false);
      }
    }
  }

  void _logActivity(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _activityLog.add(message);
      while (_activityLog.length > 400) {
        _activityLog.removeAt(0);
      }
    });
  }

  Future<void> _complete(int code, {String? errorMessage}) async {
    if (_sessionEnded) {
      return;
    }
    _sessionEnded = true;
    _clock?.cancel();
    if (errorMessage != null) {
      printerr(errorMessage);
    }
    await component.onExit(code);
  }

  bool _onKeyEvent(KeyboardEvent event) {
    if (event.matches(LogicalKey.keyC, ctrl: true)) {
      unawaited(_complete(ExitCode.success.code));
      return true;
    }
    if (_sessionEnded) {
      return true;
    }
    if (_isFindPlaylistKey(event)) {
      if (_trackIndex < _ctx.tracksToCurate.length) {
        unawaited(_openAddToPlaylistDialog());
      }
      return true;
    }
    if (_startingPlayback && !_allowsDuringPlaybackStart(event)) {
      return true;
    }
    if (_busy && !_allowsDuringBusy(event)) {
      return true;
    }
    if (_trackIndex >= _ctx.tracksToCurate.length) {
      return true;
    }
    _busy = true;
    scheduleMicrotask(() async {
      try {
        await _processKey(event);
      } catch (e, st) {
        _logActivity('✗ $e');
        if (log.debugMode) {
          _logActivity(st.toString());
        }
      } finally {
        if (mounted) {
          setState(() => _busy = false);
        }
      }
    });
    return true;
  }

  bool _allowsDuringBusy(KeyboardEvent event) =>
      _isAdvanceOrQuitKey(event) || event.matches(LogicalKey.keyC, ctrl: true);

  bool _allowsDuringPlaybackStart(KeyboardEvent event) =>
      _isAdvanceOrQuitKey(event) || event.matches(LogicalKey.keyC, ctrl: true);

  bool _isAdvanceOrQuitKey(KeyboardEvent event) {
    if (event.logicalKey == LogicalKey.space ||
        event.logicalKey == LogicalKey.keyQ) {
      return true;
    }
    final ch = event.character?.toLowerCase();
    return ch == ' ' || ch == 's' || ch == 'n' || ch == 'q';
  }

  bool _isFindPlaylistKey(KeyboardEvent event) {
    final ch = event.character?.toLowerCase();
    return ch == 'f' || event.logicalKey == LogicalKey.keyF;
  }

  Future<void> _openAddToPlaylistDialog() async {
    if (_sessionEnded || _trackIndex >= _ctx.tracksToCurate.length) {
      return;
    }
    final track = _ctx.tracksToCurate[_trackIndex];
    final durationMs = track.durationMs ?? 0;
    final navigator = Navigator.maybeOf(context);
    if (navigator == null) {
      return;
    }
    final result = await navigator.showDialog<KeyResult>(
      builder: (dialogContext) => CurateAddToPlaylistDialog(
        context: _ctx,
        runtime: _runtime,
        currentTrack: _currentTrackInfo(track, durationMs),
      ),
      width: 56,
      height: 18,
    );
    if (result != null && mounted) {
      await _applyKeyResult(result, durationMs);
    }
  }

  Future<void> _processKey(KeyboardEvent event) async {
    final track = _ctx.tracksToCurate[_trackIndex];
    final durationMs = track.durationMs ?? 0;
    final result = await _keyHandler.handleKey(
      event,
      _currentTrackInfo(track, durationMs),
      _playbackState,
    );
    await _applyKeyResult(result, durationMs);
  }

  Future<void> _applyKeyResult(KeyResult result, int durationMs) async {
    switch (result) {
      case KeyResultQuit():
        await _complete(ExitCode.success.code);
      case KeyResultNext():
        _advanceTrack();
      case KeyResultNextWithStatus(:final status):
        _advanceTrack(logLine: status);
      case KeyResultStay(:final message, :final updatedState):
        if (!mounted) {
          return;
        }
        setState(() {
          if (updatedState != null) {
            _playbackState = updatedState;
          }
          if (message != null) {
            _activityLog.add(message);
            while (_activityLog.length > 400) {
              _activityLog.removeAt(0);
            }
          }
        });
      case KeyResultIgnore():
        break;
    }
  }

  void _advanceTrack({String? logLine}) {
    if (!mounted) {
      return;
    }
    setState(() {
      // Per-track feedback (like, copy URL, seek, etc.) should not carry over
      // when moving to the next song — same idea as clearing status on "next"
      // in the pre-Nocterm stream UI.
      _activityLog.clear();
      _runtime.moveSourcePlaylistId = _ctx.sourcePlaylistId;
      _trackIndex++;
      if (logLine != null) {
        _activityLog.add(logLine);
      }
      if (_trackIndex < _ctx.tracksToCurate.length) {
        _playbackState = _playbackStateForIndex(_trackIndex);
      }
    });
    if (_trackIndex >= _ctx.tracksToCurate.length) {
      unawaited(_complete(ExitCode.success.code));
    } else {
      unawaited(_startPlaybackForCurrentTrack());
    }
  }

  @override
  Component build(BuildContext context) {
    if (_sessionEnded) {
      return const Center(child: Text('Exiting…'));
    }
    if (_trackIndex >= _ctx.tracksToCurate.length) {
      return const Center(child: Text('Done.'));
    }

    final track = _ctx.tracksToCurate[_trackIndex];
    final durationMs = track.durationMs ?? 0;
    final progressMs = _liveProgressMs(durationMs);
    final trackLine = formatCurateTrackLine(
      position: _absolutePosition,
      total: _ctx.tracks.length,
      progressMs: progressMs,
      durationMs: durationMs,
      track: track,
    );

    final remaining = _ctx.tracksToCurate.length - _trackIndex;

    return Focusable(
      focused: true,
      onKeyEvent: _onKeyEvent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _ctx.playlistName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            '$remaining track(s) to curate · '
            '[$_absolutePosition/${_ctx.tracks.length}] in playlist',
            style: const TextStyle(fontWeight: FontWeight.dim),
          ),
          const Divider(),
          Text(trackLine, style: const TextStyle(color: Colors.cyan)),
          if (_startingPlayback || _busy)
            Text(
              _startingPlayback ? 'Starting playback…' : 'Working…',
              style: const TextStyle(fontWeight: FontWeight.dim),
            ),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                _activityLog.isEmpty ? ' ' : _activityLog.join('\n'),
                style: const TextStyle(fontWeight: FontWeight.dim),
              ),
            ),
          ),
          const Divider(),
          curateFooterTargetsRow(
            _ctx.resolvedTargets,
            trackId: track.id,
            playlistTrackIds: _playlistTrackIds,
          ),
          curateFooterKeysRow(
            _ctx.config,
            trackId: track.id,
            likedIds: _likedIds,
            moveMode: _runtime.moveMode,
          ),
        ],
      ),
    );
  }
}
