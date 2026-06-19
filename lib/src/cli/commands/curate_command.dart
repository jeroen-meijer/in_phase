import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';
import 'package:in_phase/src/cli/commands/curate/curate.dart';
import 'package:in_phase/src/entities/entities.dart';
import 'package:in_phase/src/logger/logger.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:in_phase/src/spotify/spotify.dart';
import 'package:io/io.dart';
import 'package:nocterm/nocterm.dart';
import 'package:spotify/spotify.dart';

/// Max tracks fetched per playlist request (Spotify API pagination).
const _maxPlaylistTracksPerPage = 100;

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
    CurateSession? session;
    try {
      final active = await _loadSession(args);
      session = active;
      await _waitForPlayback(active.context.api);
      log.raw(
        '${green(active.context.playlistName)}: '
        '${active.context.tracksToCurate.length} track(s) to curate',
      );
      await runApp(
        CurateSessionView(
          session: active,
          onExit: (code) async {
            await active.dispose();
            shutdownApp(code);
          },
        ),
        enableHotReload: false,
      );
      return ExitCode.success.code;
    } on CurateExit catch (e) {
      return e.code;
    } catch (e, st) {
      printerr('Curate failed: $e');
      if (log.debugMode) {
        printerr(st);
      }
      return ExitCode.software.code;
    } finally {
      await session?.dispose();
    }
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
  // Session load
  // ---------------------------------------------------------------------------

  Future<CurateSession> _loadSession(
    ({
      SpotifyPlaylistId playlistId,
      int skipCount,
      File configFile,
      bool usesCustomConfigPath,
    })
    args,
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
    final requestPool = Zonable.fromZone<RequestPool>();

    try {
      final targetPlaylists = CurateTargetPlaylistsCache();
      if (config.targets.isNotEmpty) {
        targetPlaylists.start(
          _fetchTargetTrackIds(api, requestPool, config.targets),
        );
      } else {
        targetPlaylists.loaded = true;
      }
      final likedCache = CurateLikedTracksCache(api, requestPool)
        ..startPreload();

      final playlist = await api.playlists.get(args.playlistId);
      final playlistName = playlist.name ?? args.playlistId.toString();
      final playlistTracks = await requestPool.fetchAllPages(
        api.playlists.getPlaylistTracks(args.playlistId.toString()),
        limit: _maxPlaylistTracksPerPage,
        pageIdentifier: (offset) => SpotifyCacheIdentifier.playlistTracksPage(
          args.playlistId,
          offset,
        ),
      );
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

      return CurateSession(
        context: CurateContext(
          api: api,
          config: config,
          playlistName: playlistName,
          tracks: tracks,
          tracksToCurate: tracksToCurate,
          startIndex: startIndex,
          targetPlaylists: targetPlaylists,
          likedCache: likedCache,
        ),
      );
    } on CurateExit {
      // TODO(jeroen-meijer): Create issue for this lint ignore and refactor
      // ignore: invalid_use_of_visible_for_testing_member
      final client = await api.client;
      client.close();
      rethrow;
    } catch (e, st) {
      log.error('Curate setup failed: $e');
      if (log.debugMode) {
        log.error(st);
      }
      // TODO(jeroen-meijer): Create issue for this lint ignore and refactor
      // ignore: invalid_use_of_visible_for_testing_member
      final client = await api.client;
      client.close();
      rethrow;
    }
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
        if (state.item != null) {
          return;
        }
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

  Future<Map<String, Set<String>>> _fetchTargetTrackIds(
    SpotifyApi api,
    RequestPool requestPool,
    List<CurateTarget> targets,
  ) async {
    final trackSets = await Future.wait([
      for (final t in targets)
        requestPool
            .fetchAllPages(
              api.playlists.getPlaylistTracks(t.playlistId),
              limit: _maxPlaylistTracksPerPage,
              pageIdentifier: (offset) =>
                  SpotifyCacheIdentifier.playlistTracksPage(
                    SpotifyPlaylistId(t.playlistId),
                    offset,
                  ),
            )
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
