import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:in_phase/src/convert/convert.dart';
import 'package:in_phase/src/logger/logger.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:in_phase/src/spotify/spotify.dart';
import 'package:io/io.dart';
import 'package:spotify/spotify.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Playlist;

class ConvertCommand extends Command<int> {
  ConvertCommand() {
    argParser
      ..addOption(
        'add',
        abbr: 'a',
        help:
            'Target playlist: ID, URI, share URL, fuzzy name (≥80% match), '
            'or $likedSongsPlaylistTarget for Liked Songs.',
        valueHelp: 'playlist|$likedSongsPlaylistTarget',
      )
      ..addOption(
        'name',
        help: 'Name for a new Spotify playlist (playlist URL without --add).',
        valueHelp: 'name',
      )
      ..addFlag(
        'public',
        help: 'Create the new playlist as public (default: private).',
        negatable: false,
      )
      ..addFlag(
        'replace',
        help: 'Clear the target playlist before adding tracks.',
        negatable: false,
      )
      ..addFlag(
        'dry-run',
        help: 'Preview matches without writing to Spotify.',
        negatable: false,
      )
      ..addOption(
        'limit',
        help: 'Maximum number of YouTube videos to process.',
        valueHelp: 'number',
      )
      ..addOption(
        'scope',
        help:
            'For watch URLs with both v= and list= (PL playlist or RD mix): '
            '"video" for the single track or "playlist" for the full list.',
        allowed: ['video', 'playlist'],
        valueHelp: 'video|playlist',
      );
  }

  @override
  final String name = 'convert';

  @override
  final String description =
      'Converts YouTube playlists, videos, or text queries to Spotify tracks. '
      'Single video or text query without --add saves to Liked Songs; use '
      '--add for a playlist or $likedSongsPlaylistTarget.';

  @override
  Future<int> run() async {
    final source = argResults!.rest.join(' ').trim();
    if (source.isEmpty) {
      throw UsageException('Missing source argument.', usage);
    }

    final addTarget = argResults!['add'] as String?;
    final playlistName = argResults!['name'] as String?;
    final isPublic = argResults!['public'] as bool;
    final isReplace = argResults!['replace'] as bool;
    final isDryRun = argResults!['dry-run'] as bool;
    final limit = int.tryParse(argResults!['limit'] as String? ?? '');
    final scopeFlag = argResults!['scope'] as String?;

    return withTeardown((addTeardown) async {
      final classified = classifyYoutubeInput(source);
      final scope = _resolveScope(classified, scopeFlag);
      final isPlaylistBatch =
          scope == YoutubeResolveScope.playlist &&
          (classified.kind == YoutubeInputKind.playlistUrl ||
              classified.hasWatchAndList);

      final api = await spotifyLogin();
      final requestPool = Zonable.fromZone<RequestPool>();
      addTeardown(requestPool.clear);

      final yt = YoutubeExplode();
      addTeardown(yt.close);

      var videos = <YoutubeVideoRef>[];
      String? sourcePlaylistTitle;

      try {
        if (classified.kind == YoutubeInputKind.textQuery) {
          log.info(
            '🔍 Searching YouTube for "${classified.textQuery}"...',
          );
          final textQueryMatch = await resolveYoutubeVideoFromTextQuery(
            yt: yt,
            query: classified.textQuery!,
          );
          if (textQueryMatch == null) {
            log.error('❌ No YouTube match for "$source"');
            return ExitCode.software.code;
          }
          final pickedLabel = formatYoutubeVideoLabel(
            author: textQueryMatch.video.author,
            title: textQueryMatch.video.title,
          );
          log.info(
            '  ✅ Picked "$pickedLabel" (score: ${textQueryMatch.score})',
          );
          if (textQueryMatch.runnerUpTitle != null) {
            log.debug(
              '  Runner-up: "${textQueryMatch.runnerUpTitle}" '
              '(score: ${textQueryMatch.runnerUpScore})',
            );
          }
          videos.add(YoutubeVideoRef.fromVideo(textQueryMatch.video));
        } else {
          final resolved = await resolveYoutubeVideos(
            yt: yt,
            classified: classified,
            scope: scope,
            limit: limit,
          );
          videos = resolved.videos;
          sourcePlaylistTitle = resolved.playlistTitle;
        }
      } on Exception catch (e) {
        log.error('❌ YouTube request failed: $e');
        return ExitCode.software.code;
      }

      if (videos.isEmpty) {
        log.error('❌ No YouTube videos resolved from "$source"');
        return ExitCode.software.code;
      }

      log.info(
        '🎵 Matching ${videos.length} video(s) on Spotify '
        '(up to ${requestPool.maxConcurrent} concurrent)...',
      );

      final matchJobs = await matchSpotifyTracksForVideos(
        api: api,
        requestPool: requestPool,
        videos: videos,
      );

      final matchedTracks = <Track>[];
      for (final (index, job) in matchJobs.indexed) {
        final video = job.video;
        final videoLabel = formatYoutubeVideoLabel(
          author: video.author,
          title: video.title,
        );
        log.info('  [${index + 1}/${matchJobs.length}] $videoLabel');

        final match = job.match;
        if (match == null) {
          log.warning(
            '    ⚠️  No Spotify match '
            '(threshold ≥$youtubeSpotifyMatchThreshold)',
          );
          if (!isPlaylistBatch) {
            log.error('❌ Could not find Spotify track for "$source"');
            return ExitCode.software.code;
          }
          continue;
        }

        final artists =
            match.track.artists?.map((a) => a.name).nonNulls.join(', ') ?? '';
        log.info(
          '    ✅ Matched: $artists - ${match.track.name} '
          '(score: ${match.score}, query: "${match.query}")',
        );
        matchedTracks.add(match.track);
      }

      if (matchedTracks.isEmpty) {
        log.error('❌ No Spotify matches found');
        return ExitCode.software.code;
      }

      if (isDryRun) {
        if (isPlaylistBatch && addTarget == null) {
          final dryRunName = _playlistName(
            override: playlistName,
            sourceTitle: sourcePlaylistTitle,
          );
          log.info('🔍 DRY RUN: Would create playlist "$dryRunName"');
        }
        log.info(
          '🔍 DRY RUN: Would import ${matchedTracks.length} track(s)',
        );
        return ExitCode.success.code;
      }

      final isCreatePlaylist = isPlaylistBatch && addTarget == null;

      if (isCreatePlaylist) {
        final name = _playlistName(
          override: playlistName,
          sourceTitle: sourcePlaylistTitle,
        );
        log.info('📤 Creating playlist "$name"...');
        final playlist = await api.me.playlists.create(
          name,
          public: isPublic,
        );
        await _addTracksToPlaylist(
          api: api,
          requestPool: requestPool,
          playlist: playlist,
          tracks: matchedTracks,
          replace: true,
        );
        if (playlist.externalUrls?.spotify != null) {
          log.info('🔗 ${playlist.externalUrls!.spotify}');
        }
        log.info('✅ Convert complete!');
        return ExitCode.success.code;
      }

      ResolvedSpotifyTarget? resolvedTarget;
      if (addTarget != null) {
        log.info('🎯 Resolving target: $addTarget');
        final userPlaylists = await requestPool.fetchAllPages(
          api.me.playlists.saved(),
          limit: 50,
          pageIdentifier: SpotifyCacheIdentifier.savedPlaylistsPage,
        );
        resolvedTarget = await resolvePlaylistTarget(
          api: api,
          input: addTarget,
          userPlaylists: userPlaylists,
          allowLikes: true,
        );
        if (resolvedTarget == null) {
          return ExitCode.software.code;
        }
      } else {
        resolvedTarget = const LikedSongsSpotifyTarget();
      }

      switch (resolvedTarget) {
        case LikedSongsSpotifyTarget():
          log.info('📤 Saving ${matchedTracks.length} track(s) to Liked Songs');
          for (final track in matchedTracks) {
            await api.me.tracks.saveOne(track.id!);
            log.info('  ✅ ${track.name}');
          }
        case PlaylistSpotifyTarget(:final playlist):
          log.info('📤 Adding to playlist "${playlist.name}"');
          await _addTracksToPlaylist(
            api: api,
            requestPool: requestPool,
            playlist: playlist,
            tracks: matchedTracks,
            replace: isReplace,
          );
          if (playlist.externalUrls?.spotify != null) {
            log.info('🔗 ${playlist.externalUrls!.spotify}');
          }
      }

      log.info('✅ Convert complete!');
      return ExitCode.success.code;
    });
  }

  Future<void> _addTracksToPlaylist({
    required SpotifyApi api,
    required RequestPool requestPool,
    required PlaylistSimple playlist,
    required List<Track> tracks,
    required bool replace,
  }) async {
    var tracksToAdd = tracks;

    if (replace) {
      log.info('  🗑️  Clearing existing tracks...');
      await api.playlists.clear(playlist.id!);
    } else {
      final existing = await requestPool.fetchAllPages(
        api.playlists.getPlaylistTracks(playlist.id!),
        limit: 50,
        pageIdentifier: (offset) => SpotifyCacheIdentifier.playlistTracksPage(
          SpotifyPlaylistId(playlist.id!),
          offset,
        ),
      );
      final existingIds = existing
          .map((t) => t.track?.id)
          .whereType<String>()
          .toSet();
      final before = tracksToAdd.length;
      tracksToAdd = tracksToAdd
          .where((t) => !existingIds.contains(t.id))
          .toList();
      final skipped = before - tracksToAdd.length;
      if (skipped > 0) {
        log.info('  ⏭️  Skipping $skipped duplicate track(s)');
      }
    }

    if (tracksToAdd.isEmpty) {
      log.info('  ✅ Nothing new to add');
      return;
    }

    final uris = tracksToAdd.map((t) => t.uri!).toList();
    for (var i = 0; i < uris.length; i += 100) {
      final batch = uris.skip(i).take(100).toList();
      await api.playlists.addTracks(batch, playlist.id!);
    }
    log.info('  ✅ Added ${tracksToAdd.length} track(s)');
  }

  String _playlistName({
    required String? override,
    required String? sourceTitle,
  }) {
    if (override != null && override.isNotEmpty) {
      return override;
    }
    if (sourceTitle != null && sourceTitle.isNotEmpty) {
      return sourceTitle;
    }
    return 'Converted from YouTube';
  }

  YoutubeResolveScope _resolveScope(
    ClassifiedYoutubeInput classified,
    String? scopeFlag,
  ) {
    if (classified.hasWatchAndList) {
      if (scopeFlag == null && !stdin.hasTerminal) {
        log.info(
          'Non-interactive session: defaulting to single video. '
          'Use --scope playlist to convert the full playlist/mix.',
        );
      }
      return resolveWatchAndListScope(
        isMix: classified.isMixPlaylist,
        scopeFlag: scopeFlag,
      );
    }

    if (classified.kind == YoutubeInputKind.playlistUrl) {
      return YoutubeResolveScope.playlist;
    }

    return YoutubeResolveScope.singleVideo;
  }
}
