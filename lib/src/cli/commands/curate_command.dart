import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart_console/dart_console.dart';
import 'package:dcli/dcli.dart';
import 'package:in_phase/src/cli/commands/curate/curate.dart';
import 'package:in_phase/src/entities/entities.dart';
import 'package:in_phase/src/logger/logger.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:in_phase/src/spotify/spotify.dart';
import 'package:io/io.dart';
import 'package:spotify/spotify.dart';

/// Max tracks fetched per playlist request (Spotify API pagination).
const _maxPlaylistTracksPerPage = 100;

/// Max items per page for [SpotifyApi.me.tracks.saved] (Spotify API cap).
const _maxSavedTracksPerPage = 50;

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
        final context = await _setupContext(args, addTeardown);
        return await _runLoop(context);
      } on CurateExit catch (e) {
        return e.code;
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Argument parsing
  // ---------------------------------------------------------------------------

  ({
    SpotifyPlaylistId playlistId,
    int skipCount,
    File configFile,
    bool usesCustomConfigPath,
  })
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

    final customConfigPath = argResults!['config'] as String?;
    final usesCustomConfigPath = customConfigPath != null;
    final configFile = usesCustomConfigPath
        ? resolveConfigPath(customConfigPath)
        : Constants.curateConfigFile;

    return (
      playlistId: playlistId,
      skipCount: skipCount,
      configFile: configFile,
      usesCustomConfigPath: usesCustomConfigPath,
    );
  }

  // ---------------------------------------------------------------------------
  // Setup
  // ---------------------------------------------------------------------------

  Future<CurateContext> _setupContext(
    ({
      SpotifyPlaylistId playlistId,
      int skipCount,
      File configFile,
      bool usesCustomConfigPath,
    })
    args,
    void Function(TeardownFn) addTeardown,
  ) async {
    log.info('Loading curate config from: ${args.configFile.path}');
    final config = await CurateConfig.fromFile(
      args.configFile,
      createFileIfNotExists: !args.usesCustomConfigPath,
    );
    if (config.targets.isEmpty) {
      log.warning(
        'No target playlists configured. Add targets to your curate '
        'config to add tracks to playlists (keys 1-N).\n'
        'Config path: ${args.configFile.path}',
      );
    }

    final api = await spotifyLogin();
    // TODO(jeroen-meijer): Create issue for this lint ignore and refactor
    // ignore: invalid_use_of_visible_for_testing_member
    addTeardown(() async => (await api.client).close());

    final targetTrackIdsFuture = config.targets.isNotEmpty
        ? _fetchTargetTrackIds(api, config.targets)
        : Future<Map<String, Set<String>>>.value({});
    final likedTrackIdsFuture = _fetchLikedTrackIds(api);

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
      throw CurateExit(ExitCode.noInput.code);
    }

    final startIndex = args.skipCount.clamp(0, tracks.length);
    final tracksToCurate = tracks.sublist(startIndex);

    if (tracksToCurate.isEmpty) {
      log.info('No tracks left after --skip=${args.skipCount}');
      throw CurateExit(ExitCode.success.code);
    }

    return CurateContext(
      api: api,
      config: config,
      playlistName: playlistName,
      tracks: tracks,
      tracksToCurate: tracksToCurate,
      startIndex: startIndex,
      targetTrackIdsFuture: targetTrackIdsFuture,
      likedTrackIdsFuture: likedTrackIdsFuture,
    );
  }

  // ---------------------------------------------------------------------------
  // Main loop
  // ---------------------------------------------------------------------------

  Future<int> _runLoop(CurateContext context) async {
    await _waitForPlayback(context.api);

    log.raw(
      '${green(context.playlistName)}: '
      '${context.tracksToCurate.length} track(s) to curate',
    );
    printKeyHints(context.config);
    log.raw('');

    final console = Console();
    final keyHandler = CurateKeyHandler(context);
    var index = 0;

    while (index < context.tracksToCurate.length) {
      final track = context.tracksToCurate[index];
      final absoluteIndex = context.startIndex + index;
      final trackUri = 'spotify:track:${track.id}';
      final durationMs = track.durationMs ?? 0;

      printTrackLine(
        absoluteIndex + 1,
        context.tracks.length,
        context.config.startPositionMs,
        durationMs,
        track,
      );

      var playbackState = TrackPlaybackState(
        positionMs: context.config.startPositionMs.clamp(0, durationMs),
        startedAt: DateTime.now(),
      );

      try {
        await context.api.player.startWithTracks(
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
      final currentTrack = CurrentTrackInfo(
        track: track,
        trackUri: trackUri,
        durationMs: durationMs,
        index: index,
        tracksToCurateLength: context.tracksToCurate.length,
      );

      keyLoop:
      while (true) {
        final key = console.readKey();
        final result = await keyHandler.handleKey(
          key,
          currentTrack,
          playbackState,
        );

        switch (result) {
          case KeyResultQuit():
            log.raw('\n${blue('Quit.')}');
            return ExitCode.success.code;

          case KeyResultNext():
            statusMessage = ''; // Don't re-print prior status
            index++;
            advanced = true;
            break keyLoop;

          case KeyResultNextWithStatus(:final status):
            statusMessage = status;
            index++;
            advanced = true;
            break keyLoop;

          case KeyResultStay(:final status, :final updatedState):
            if (status != null) {
              statusMessage = status;
              log.raw('  $statusMessage');
            }
            if (updatedState != null) {
              playbackState = updatedState;
            }

          case KeyResultIgnore():
        }
      }

      if (advanced && statusMessage.isNotEmpty) {
        log.raw('  $statusMessage');
      }
    }

    log.raw('\n${green('Done.')}');
    return ExitCode.success.code;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

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

  Future<Set<String>> _fetchLikedTrackIds(SpotifyApi api) async {
    final saved = await api.me.tracks.saved().all(_maxSavedTracksPerPage);
    return saved.map((ts) => ts.track?.id).nonNulls.toSet();
  }

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
}
