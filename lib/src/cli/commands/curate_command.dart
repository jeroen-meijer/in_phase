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

/// Max target playlist keys (1-9).
const _maxTargetPlaylists = 9;

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
      'Playlist: ID, URI, URL, or name. '
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
        Navigator(
          home: CurateSessionView(
            session: active,
            onExit: (code) async {
              await active.dispose();
              shutdownApp(code);
            },
          ),
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
    String playlistInput,
    int skipCount,
    File configFile,
    bool usesCustomConfigPath,
  })
  _parseArgs() {
    final playlistArg = argResults!.rest.isNotEmpty
        ? argResults!.rest.first
        : null;
    if (playlistArg == null) {
      usageException(
        'A playlist is required (ID, URI, share URL, or name).',
      );
    }
    final arg = playlistArg.trim();
    if (arg.isEmpty) {
      usageException('A playlist is required.');
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
      playlistInput: arg,
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
      String playlistInput,
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
        'config to add tracks to playlists (keys 1-N), or press f to '
        'search your library.\n'
        'Config path: ${args.configFile.path}',
      );
    } else if (config.targets.length > _maxTargetPlaylists) {
      log.error(
        'Too many target playlists (${config.targets.length}). '
        'Maximum is $_maxTargetPlaylists (keys 1-9).',
      );
      throw CurateExit(ExitCode.config.code);
    }

    final api = await spotifyLogin();
    final requestPool = Zonable.fromZone<RequestPool>();

    try {
      final likedCache = CurateLikedTracksCache(api, requestPool)
        ..startPreload();
      final userPlaylists = CurateUserPlaylistsCache()..start(api, requestPool);

      log.info('Prefetching your Spotify playlists for add-to-playlist…');
      await userPlaylists.ready;

      final resolvedTargets = await _resolveTargets(
        api: api,
        inputs: config.targets,
        userPlaylists: userPlaylists.savedPlaylists,
      );

      final targetPlaylists = CurateTargetPlaylistsCache();
      if (resolvedTargets.isNotEmpty) {
        targetPlaylists.start(
          _fetchTargetTrackIds(api, requestPool, resolvedTargets),
        );
      } else {
        targetPlaylists.loaded = true;
      }

      log.info('Resolving playlist to curate: "${args.playlistInput}"');
      final sourcePlaylist = await _resolveSourcePlaylist(
        api: api,
        input: args.playlistInput,
        userPlaylists: userPlaylists.savedPlaylists,
      );
      final playlistId = SpotifyPlaylistId(sourcePlaylist.playlistId);
      final resolvedName = sourcePlaylist.name;

      final playlistTracks = await requestPool.fetchAllPages(
        api.playlists.getPlaylistTracks(playlistId.toString()),
        limit: _maxPlaylistTracksPerPage,
        pageIdentifier: (offset) => SpotifyCacheIdentifier.playlistTracksPage(
          playlistId,
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
          sourcePlaylistId: playlistId.toString(),
          playlistName: resolvedName,
          resolvedTargets: resolvedTargets,
          tracks: tracks,
          tracksToCurate: tracksToCurate,
          startIndex: startIndex,
          targetPlaylists: targetPlaylists,
          likedCache: likedCache,
          userPlaylists: userPlaylists,
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

  Future<List<CurateResolvedTarget>> _resolveTargets({
    required SpotifyApi api,
    required List<String> inputs,
    required List<PlaylistSimple> userPlaylists,
  }) async {
    if (inputs.isEmpty) {
      return [];
    }

    log.info('Resolving ${inputs.length} target playlist(s)…');
    final resolved = <CurateResolvedTarget>[];

    for (final input in inputs) {
      final result = await resolvePlaylistTarget(
        api: api,
        input: input,
        userPlaylists: userPlaylists,
      );

      switch (result) {
        case PlaylistSpotifyTarget(:final playlist):
          final playlistId = playlist.id;
          if (playlistId == null || playlistId.isEmpty) {
            log.error('Target "$input" resolved but has no playlist id.');
            throw CurateExit(ExitCode.config.code);
          }
          final name = playlist.name ?? input;
          log.info('  ✓ "$input" → "$name"');
          resolved.add(
            CurateResolvedTarget(
              input: input,
              playlistId: playlistId,
              name: name,
            ),
          );
        case LikedSongsSpotifyTarget():
          log.error(
            'Target "$input" resolved to Liked Songs. Use key l during '
            'curate, or pick a playlist target.',
          );
          throw CurateExit(ExitCode.config.code);
        case null:
          log.error('Could not resolve target playlist: "$input"');
          throw CurateExit(ExitCode.config.code);
      }
    }

    return resolved;
  }

  Future<({String playlistId, String name})> _resolveSourcePlaylist({
    required SpotifyApi api,
    required String input,
    required List<PlaylistSimple> userPlaylists,
  }) async {
    final result = await resolvePlaylistTarget(
      api: api,
      input: input,
      userPlaylists: userPlaylists,
    );

    switch (result) {
      case PlaylistSpotifyTarget(:final playlist):
        final playlistId = playlist.id;
        if (playlistId == null || playlistId.isEmpty) {
          log.error('Playlist "$input" resolved but has no playlist id.');
          throw CurateExit(ExitCode.config.code);
        }
        final name = playlist.name ?? input;
        log.info('  ✓ "$input" → "$name"');
        return (playlistId: playlistId, name: name);
      case LikedSongsSpotifyTarget():
        log.error(
          'Playlist "$input" resolved to Liked Songs. '
          'Curate requires a playlist.',
        );
        throw CurateExit(ExitCode.config.code);
      case null:
        log.error('Could not resolve playlist to curate: "$input"');
        throw CurateExit(ExitCode.config.code);
    }
  }

  Future<Map<String, Set<String>>> _fetchTargetTrackIds(
    SpotifyApi api,
    RequestPool requestPool,
    List<CurateResolvedTarget> targets,
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
