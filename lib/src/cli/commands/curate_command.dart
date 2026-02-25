import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart_console/dart_console.dart';
import 'package:dcli/dcli.dart';
import 'package:in_phase/src/entities/entities.dart';
import 'package:in_phase/src/logger/logger.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:in_phase/src/spotify/spotify.dart';
import 'package:io/io.dart';
import 'package:spotify/spotify.dart';

/// Max tracks fetched per playlist request (Spotify API pagination).
const _maxPlaylistTracksPerPage = 100;

/// Max target playlist key (1-9).
const _maxTargetKey = 9;

class CurateCommand extends Command<int> {
  CurateCommand() {
    argParser
      ..addOption(
        'config',
        abbr: 'c',
        help: 'Path to curate config file.',
        valueHelp: 'path',
      )
      ..addOption(
        'skip',
        help: 'Skip the first N tracks (e.g. --skip=5 when resuming).',
        valueHelp: 'N',
        defaultsTo: '0',
      );
  }

  @override
  final String name = 'curate';

  @override
  final String description =
      'Preview playlist tracks, add to target playlists or go to next. '
      'Requires Spotify Premium and an active device.';

  @override
  Future<int> run() async {
    final args = _parseArgs();
    return withTeardown((addTeardown) async {
      try {
        final context = await _setupCurateContext(args, addTeardown);
        return await _runCurateLoop(context);
      } on _CurateExit catch (e) {
        return e.code;
      }
    });
  }

  /// Parses and validates playlist, skip count, and config file from args.
  ({SpotifyPlaylistId playlistId, int skipCount, File configFile})
  _parseArgs() {
    final playlistArg = argResults!.rest.isNotEmpty
        ? argResults!.rest.first
        : null;
    if (playlistArg == null) {
      usageException('A playlist is required (ID, URI, or share URL).');
    }
    final arg = playlistArg.trim();
    if (arg.isEmpty) {
      usageException('A playlist is required.');
    }

    final playlistId = SpotifyPlaylistId.tryExtract(arg);
    if (playlistId == null) {
      usageException('Invalid playlist: $playlistArg');
    }

    final skipStr = argResults!['skip'] as String? ?? '0';
    final skipCount = int.tryParse(skipStr) ?? 0;
    if (skipCount < 0) {
      usageException('--skip must be >= 0');
    }

    final configPath = argResults!['config'] as String?;
    final configFile = configPath != null
        ? File(configPath)
        : Constants.curateConfigFile;

    return (
      playlistId: playlistId,
      skipCount: skipCount,
      configFile: configFile,
    );
  }

  /// Loads config, connects to Spotify, fetches playlist and tracks.
  Future<_CurateContext> _setupCurateContext(
    ({SpotifyPlaylistId playlistId, int skipCount, File configFile}) args,
    void Function(TeardownFn) addTeardown,
  ) async {
    // Load configuration
    log.info('Loading curate config from: ${args.configFile.path}');
    final config = await CurateConfig.fromFile(args.configFile);
    if (config.targets.isEmpty) {
      log.warning(
        'No target playlists configured. Add targets to your curate '
        'config to add tracks to playlists (keys 1-N).\n'
        'Config path: ${args.configFile.path}',
      );
    }

    // Login to Spotify
    final api = await spotifyLogin();
    // TODO(jeroen-meijer): Create issue for this lint ignore and refactor
    // ignore: invalid_use_of_visible_for_testing_member
    addTeardown(() async => (await api.client).close());

    final targetTrackIdsFuture = config.targets.isNotEmpty
        ? _fetchTargetTrackIds(api, config.targets)
        : Future<Map<String, Set<String>>>.value({});

    // Fetch playlist and tracks
    final playlist = await api.playlists.get(args.playlistId);
    final playlistName = playlist.name ?? args.playlistId.toString();
    final playlistTracks = await api.playlists
        .getPlaylistTracks(args.playlistId.toString())
        .all(_maxPlaylistTracksPerPage);
    final tracks = playlistTracks
        .map((pt) => pt.track)
        .whereType<Track>()
        .where((t) => t.id != null)
        .toList();

    if (tracks.isEmpty) {
      log.error('No tracks in playlist.');
      throw _CurateExit(ExitCode.noInput.code);
    }

    final startIndex = args.skipCount.clamp(0, tracks.length);
    final tracksToCurate = tracks.sublist(startIndex);

    if (tracksToCurate.isEmpty) {
      log.info('No tracks left after --skip=${args.skipCount}');
      throw _CurateExit(ExitCode.success.code);
    }

    return _CurateContext(
      api: api,
      config: config,
      playlistName: playlistName,
      tracks: tracks,
      tracksToCurate: tracksToCurate,
      startIndex: startIndex,
      targetTrackIdsFuture: targetTrackIdsFuture,
    );
  }

  /// Runs the interactive curating loop.
  Future<int> _runCurateLoop(_CurateContext context) async {
    final api = context.api;
    final config = context.config;

    await _waitForPlayback(api);

    log.raw(
      '${green(context.playlistName)}: '
      '${context.tracksToCurate.length} track(s) to curate',
    );
    _printKeyHints(config);
    log.raw('');

    final console = Console();
    var index = 0;

    while (index < context.tracksToCurate.length) {
      final track = context.tracksToCurate[index];
      final absoluteIndex = context.startIndex + index;
      final trackUri = 'spotify:track:${track.id}';
      final durationMs = track.durationMs ?? 0;

      _printTrackLine(
        absoluteIndex + 1,
        context.tracks.length,
        config.startPositionMs,
        durationMs,
        track,
      );

      var playbackState = _TrackPlaybackState(
        positionMs: config.startPositionMs.clamp(0, durationMs),
        startedAt: DateTime.now(),
      );

      try {
        await api.player.startWithTracks(
          [trackUri],
          positionMs: playbackState.positionMs,
          retrievePlaybackState: false,
        );
      } catch (e) {
        _handleSpotifyError(e);
        return ExitCode.software.code;
      }

      var statusMessage = '';
      var advanced = false;

      final currentTrack = _CurrentTrackInfo(
        track: track,
        trackUri: trackUri,
        durationMs: durationMs,
        index: index,
        tracksToCurateLength: context.tracksToCurate.length,
      );

      keyLoop:
      while (true) {
        final key = console.readKey();
        final result = await _handleKey(
          key,
          context,
          currentTrack,
          playbackState,
        );

        switch (result) {
          case _KeyResultQuit():
            _logQuit();
            return ExitCode.success.code;

          case _KeyResultNext():
            index++;
            advanced = true;
            break keyLoop;

          case _KeyResultNextWithStatus(:final status):
            statusMessage = status;
            index++;
            advanced = true;
            break keyLoop;

          case _KeyResultStay(:final status, :final updatedState):
            if (status != null) {
              statusMessage = status;
              log.raw('  $statusMessage');
            }
            if (updatedState != null) {
              playbackState = updatedState;
            }

          case _KeyResultIgnore():
        }
      }

      if (advanced && statusMessage.isNotEmpty) {
        log.raw('  $statusMessage');
      }
    }

    log.raw('\n${green('Done.')}');
    return ExitCode.success.code;
  }

  Future<_KeyResult> _handleKey(
    Key key,
    _CurateContext context,
    _CurrentTrackInfo currentTrack,
    _TrackPlaybackState playbackState,
  ) async {
    if (key.isControl) {
      return _handleControlKey(
        key,
        context,
        currentTrack.durationMs,
        playbackState,
      );
    }

    final config = context.config;
    final char = key.char.isEmpty ? '' : key.char.toLowerCase();
    if (char == 'q') return _KeyResultQuit();

    if (char == ' ' || char == 's' || char == 'n') return _KeyResultNext();

    if (char == 'r') {
      final newState = _TrackPlaybackState(
        positionMs: config.startPositionMs.clamp(0, currentTrack.durationMs),
        startedAt: DateTime.now(),
      );
      await context.api.player.seek(
        newState.positionMs,
        retrievePlaybackState: false,
      );
      return _KeyResultStay(
        '${cyan('↺')} ${config.startPosition}',
        newState,
      );
    }

    final targetNum = int.tryParse(char);
    if (targetNum != null &&
        targetNum >= 1 &&
        targetNum <= _maxTargetKey &&
        targetNum <= config.targets.length) {
      return _handleAddToTarget(context, currentTrack, targetNum);
    }

    return _KeyResultIgnore();
  }

  Future<_KeyResult> _handleControlKey(
    Key key,
    _CurateContext context,
    int durationMs,
    _TrackPlaybackState playbackState,
  ) async {
    final config = context.config;
    switch (key.controlChar) {
      case ControlCharacter.arrowLeft:
      case ControlCharacter.arrowRight:
        final deltaMs = key.controlChar == ControlCharacter.arrowLeft
            ? -config.seekStep * 1000
            : config.seekStep * 1000;
        final result = await _seek(
          context.api,
          deltaMs,
          durationMs,
          playbackState.positionMs,
          playbackState.startedAt,
        );
        return result != null
            ? _KeyResultStay(
                null,
                _TrackPlaybackState(
                  positionMs: result.$1,
                  startedAt: result.$2,
                ),
              )
            : _KeyResultIgnore();

      case ControlCharacter.ctrlC:
        return _KeyResultQuit();

      case ControlCharacter.enter:
      case _:
        return _KeyResultIgnore();
    }
  }

  Future<_KeyResult> _handleAddToTarget(
    _CurateContext context,
    _CurrentTrackInfo currentTrack,
    int targetNum,
  ) async {
    final config = context.config;
    final target = config.targets[targetNum - 1];
    final targetTrackIds = await context.targetTrackIdsFuture;
    if (targetTrackIds[target.playlistId]?.contains(currentTrack.track.id) ??
        false) {
      return _KeyResultStay(
        '${orange('-')} Already in ${bold(target.name)}',
        null,
      );
    }

    try {
      await context.api.playlists.addTracks(
        [currentTrack.trackUri],
        target.playlistId,
      );
      targetTrackIds[target.playlistId] ??= {};
      targetTrackIds[target.playlistId]!.add(currentTrack.track.id!);
      final status = '${green('✓')} Added to ${bold(target.name)}';
      if (config.nextAfterAdd &&
          currentTrack.index + 1 < currentTrack.tracksToCurateLength) {
        return _KeyResultNextWithStatus(status);
      }
      return _KeyResultStay(status, null);
    } catch (e) {
      return _KeyResultStay(
        '${red('✗')} ${bold(target.name)}: $e',
        null,
      );
    }
  }

  void _logQuit() {
    log.raw('\n${blue('Quit.')}');
  }

  void _printKeyHints(CurateConfig config) {
    final targetHints = config.targets
        .asMap()
        .entries
        .map((e) => '${green("[${e.key + 1}]")} ${e.value.name}')
        .join('  ');
    log.raw(
      '$targetHints  ${cyan("[n/s]")} next  '
      '${cyan("[←][→]")} seek ±${config.seekStep}s  '
      '${cyan("[r]")} restart  ${cyan("[q]")} quit',
    );
  }

  void _printTrackLine(
    int position,
    int total,
    int progressMs,
    int durationMs,
    Track track,
  ) {
    final progress = formatDurationMs(progressMs.clamp(0, durationMs));
    final duration = formatDurationMs(durationMs);
    final artists = track.artists?.map((a) => a.name).join(', ') ?? '?';
    log.raw(
      '${cyan('[$position/$total]')} $progress/$duration  ${track.name} - $artists',
    );
  }

  Future<void> _waitForPlayback(
    SpotifyApi api, {
    Duration pollInterval = const Duration(seconds: 1),
  }) async {
    var messageShown = false;
    while (true) {
      try {
        final state = await api.player.currentlyPlaying();
        if (state.item != null) return;
      } catch (_) {
        // NO_ACTIVE_DEVICE etc. - treat as not playing
      }
      if (!messageShown) {
        log.raw(
          orange(
            'Please start playing any song on Spotify to start curating.',
          ),
        );
        messageShown = true;
      }
      await Future<void>.delayed(pollInterval);
    }
  }

  /// Seeks by [deltaMs] from the computed current position. Returns the new
  /// (positionMs, startedAt) for the caller to update tracked state, or null
  /// if the seek failed.
  Future<(int, DateTime)?> _seek(
    SpotifyApi api,
    int deltaMs,
    int durationMs,
    int startPositionMs,
    DateTime startedAt,
  ) async {
    final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
    final currentMs = startPositionMs + elapsedMs;
    final newPos = (currentMs + deltaMs).clamp(0, durationMs);
    try {
      await api.player.seek(newPos, retrievePlaybackState: false);
      return (newPos, DateTime.now());
    } catch (_) {
      return null;
    }
  }

  void _handleSpotifyError(Object e) {
    final msg = e.toString();
    if (msg.contains('Premium') || msg.contains('PREMIUM_REQUIRED')) {
      log.error('Spotify Premium is required for playback.');
    } else if (msg.contains('NO_ACTIVE_DEVICE') || msg.contains('404')) {
      log.error('Open Spotify (app or web player) and try again.');
    } else {
      log.error('Error: $e');
    }
  }

  /// Fetches track IDs for each target playlist in parallel.
  /// Used to pre-fetch in background and to skip duplicate adds.
  Future<Map<String, Set<String>>> _fetchTargetTrackIds(
    SpotifyApi api,
    List<CurateTarget> targets,
  ) async {
    final trackSets = await Future.wait([
      for (final t in targets)
        api.playlists
            .getPlaylistTracks(t.playlistId)
            .all(_maxPlaylistTracksPerPage)
            .then(
              (pts) => pts
                  .map((pt) => pt.track)
                  .nonNulls
                  .map((t) => t.id)
                  .nonNulls
                  .toSet(),
            ),
    ]);
    return {
      for (var i = 0; i < targets.length; i++)
        targets[i].playlistId: trackSets[i],
    };
  }
}

class _CurateExit implements Exception {
  _CurateExit(this.code);
  final int code;
}

/// Bundles track-specific data needed by key handlers.
class _CurrentTrackInfo {
  _CurrentTrackInfo({
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

class _CurateContext {
  _CurateContext({
    required this.api,
    required this.config,
    required this.playlistName,
    required this.tracks,
    required this.tracksToCurate,
    required this.startIndex,
    required this.targetTrackIdsFuture,
  });

  final SpotifyApi api;
  final CurateConfig config;
  final String playlistName;
  final List<Track> tracks;
  final List<Track> tracksToCurate;
  final int startIndex;
  final Future<Map<String, Set<String>>> targetTrackIdsFuture;
}

class _TrackPlaybackState {
  _TrackPlaybackState({required this.positionMs, required this.startedAt});
  final int positionMs;
  final DateTime startedAt;
}

sealed class _KeyResult {}

class _KeyResultQuit extends _KeyResult {
  _KeyResultQuit();
}

class _KeyResultNext extends _KeyResult {
  _KeyResultNext();
}

class _KeyResultNextWithStatus extends _KeyResult {
  _KeyResultNextWithStatus(this.status);
  final String status;
}

class _KeyResultStay extends _KeyResult {
  _KeyResultStay(this.status, this.updatedState);
  final String? status;
  final _TrackPlaybackState? updatedState;
}

class _KeyResultIgnore extends _KeyResult {
  _KeyResultIgnore();
}
