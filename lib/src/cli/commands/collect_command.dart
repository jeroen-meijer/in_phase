import 'package:args/command_runner.dart';
import 'package:in_phase/src/crawl/crawl.dart';
import 'package:in_phase/src/entities/entities.dart';
import 'package:in_phase/src/logger/logger.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:in_phase/src/spotify/spotify.dart';
import 'package:io/io.dart';
import 'package:spotify/spotify.dart';

class CollectCommand extends Command<int> {
  CollectCommand() {
    argParser
      ..addOption(
        'config',
        abbr: 'c',
        help: 'Path to collect config file.',
        valueHelp: 'path',
      )
      ..addFlag(
        'dry-run',
        help: "Don't update playlists, just show what would be done.",
        negatable: false,
      )
      ..addMultiOption(
        'collection',
        abbr: 'j',
        help:
            'Run specific collection(s) by name. '
            'If not specified, runs all collections.',
        valueHelp: 'name',
      );
  }

  @override
  final String name = 'collect';

  @override
  final String description =
      'Aggregates tracks from multiple Spotify playlists '
      'into a single target playlist. '
      'Playlist targets and sources in config accept ID, URI, URL, or fuzzy '
      'name; sources also support glob patterns (`*`). '
      'To add tracks to Liked Songs, use `in_phase convert --add '
      '$likedSongsPlaylistTarget`.';

  @override
  Future<int> run() async {
    final customConfigPath = argResults!['config'] as String?;
    final usesCustomConfigPath = customConfigPath != null;
    final configFile = usesCustomConfigPath
        ? resolveConfigPath(customConfigPath)
        : Constants.collectConfigFile;

    log.info('Loading collect config from: ${configFile.path}');
    final config = await CollectConfig.fromFile(configFile);

    if (config.collections.isEmpty) {
      log.warning('No collections found in configuration');
      return ExitCode.config.code;
    }

    final requestedCollections = argResults!['collection'] as List<String>;
    final collectionsToRun = requestedCollections.isEmpty
        ? config.collections
        : config.collections
              .where((c) => requestedCollections.contains(c.name))
              .toList();
    if (collectionsToRun.isEmpty) {
      usageException(
        'No matching collections found for: '
        '${requestedCollections.join(', ')}',
      );
    }

    final isDryRun = argResults!['dry-run'] as bool;

    return withTeardown((addTeardown) async {
      final api = await spotifyLogin();
      addTeardown(() => closeSpotifyApi(api));

      final requestPool = Zonable.fromZone<RequestPool>();
      addTeardown(requestPool.clear);

      final user = await api.me.get();
      log
        ..info('Logged in as: ${user.displayName}')
        ..info('Found ${collectionsToRun.length} collection(s) to process')
        ..info('');

      if (isDryRun) {
        log
          ..info('🔍 DRY RUN MODE - No playlists will be updated')
          ..info('');
      }

      log.info('Fetching user playlists for source resolution...');
      final userPlaylists = await fetchSavedPlaylists(
        api: api,
        requestPool: requestPool,
      );
      log.info('Found ${userPlaylists.length} user playlist(s)');

      final failedCollections = <String>[];
      for (final (index, collection) in collectionsToRun.indexed) {
        log.info(
          '🔄 Processing collection ${index + 1}/${collectionsToRun.length}: '
          '${collection.name}',
        );

        try {
          await _processCollection(
            api: api,
            collection: collection,
            requestPool: requestPool,
            userPlaylists: userPlaylists,
            isDryRun: isDryRun,
          );
        } on Exception catch (e, stackTrace) {
          failedCollections.add(collection.name);
          log
            ..error('  ❌ Collection "${collection.name}" failed: $e')
            ..error('     The target playlist was not changed.')
            ..debug('Stack trace: $stackTrace');
        }

        log.info('');
      }

      if (failedCollections.isNotEmpty) {
        log.error(
          '❌ ${failedCollections.length} collection(s) failed: '
          '${failedCollections.join(', ')}',
        );
        return ExitCode.software.code;
      }

      log.info('✅ Collect complete!');
      return ExitCode.success.code;
    });
  }

  /// Collects tracks for [collection] and writes them to its target.
  ///
  /// Throws when a source or the target cannot be read, before anything is
  /// written to Spotify.
  Future<void> _processCollection({
    required SpotifyApi api,
    required CollectCollection collection,
    required RequestPool requestPool,
    required List<PlaylistSimple> userPlaylists,
    required bool isDryRun,
  }) async {
    log.info('  📋 Resolving source playlists...');
    final resolvedPlaylists = await _resolveSources(
      sources: collection.sources,
      userPlaylists: userPlaylists,
      api: api,
    );

    if (resolvedPlaylists.isEmpty) {
      log.warning('  ⚠️  No source playlists resolved');
      return;
    }

    log
      ..info('  ✅ Resolved ${resolvedPlaylists.length} source playlist(s)')
      ..info('  📥 Fetching tracks from source playlists...');
    final allTracks = <CollectedTrack>[];

    for (final (index, playlist) in resolvedPlaylists.indexed) {
      log.info(
        '    [${index + 1}/${resolvedPlaylists.length}] '
        'Fetching from "${playlist.name}"...',
      );

      final playlistTracks = await fetchPlaylistTracks(
        api: api,
        requestPool: requestPool,
        playlistId: SpotifyPlaylistId(playlist.id!),
      );

      for (final playlistTrack in playlistTracks.spotifyTracks) {
        final track = playlistTrack.track!;
        allTracks.add(
          CollectedTrack(
            id: SpotifyTrackId(track.id!),
            uri: track.uri!,
            name: track.name!,
            artistNames: track.artists?.map((a) => a.name ?? '').toList() ?? [],
            addedAt: playlistTrack.addedAt ?? DateTime.now(),
            source: CollectedTrackSourcePlaylist(
              id: playlist.id!,
              name: playlist.name ?? '',
            ),
            albumId: track.album?.id != null
                ? SpotifyAlbumId(track.album!.id!)
                : null,
          ),
        );
      }

      log.info(
        '    ✅ Found ${playlistTracks.length} track(s) from '
        '"${playlist.name}"',
      );
    }

    log.info('  📊 Collected ${allTracks.length} total tracks');

    if (allTracks.isEmpty) {
      log.warning('  ⚠️  No tracks found for this collection');
      return;
    }

    // Deduplicate tracks, keeping the latest addedAt per dedupe key.
    final deduplicateMode =
        collection.options?.deduplicate ?? DeduplicateMode.onId;
    final trackOrder =
        collection.options?.trackOrder ?? CollectTrackOrder.oldestFirst;
    final dedupedTracks = _deduplicateKeepingLatest(allTracks, deduplicateMode)
      ..sort((a, b) {
        switch (trackOrder) {
          case CollectTrackOrder.oldestFirst:
            return a.addedAt.compareTo(b.addedAt);
          case CollectTrackOrder.newestFirst:
            return b.addedAt.compareTo(a.addedAt);
        }
      });

    if (dedupedTracks.length < allTracks.length) {
      log.info(
        '  🔄 Deduplicated: ${allTracks.length} → '
        '${dedupedTracks.length} tracks',
      );
    }

    log.info('  🎯 Resolving target playlist...');
    final resolvedTarget = await resolvePlaylistTarget(
      api: api,
      input: collection.target,
      userPlaylists: userPlaylists,
    );
    final targetPlaylist = switch (resolvedTarget) {
      PlaylistSpotifyTarget(:final playlist) => playlist,
      _ => null,
    };
    if (targetPlaylist == null) {
      throw Exception(
        'Could not resolve target playlist "${collection.target}"',
      );
    }
    final targetPlaylistId = SpotifyPlaylistId(targetPlaylist.id!);

    log.info('  ✅ Target playlist: "${targetPlaylist.name}"');

    final replaceMode = collection.options?.replace ?? true;
    final uris = dedupedTracks.map((t) => t.uri).toList();

    if (isDryRun) {
      log.info(
        replaceMode
            ? '  🔍 DRY RUN: Would replace playlist with ${uris.length} tracks'
            : '  🔍 DRY RUN: Would append the new ones of ${uris.length} '
                  'tracks',
      );
      return;
    }

    if (replaceMode) {
      log.info(
        '  📤 Replacing playlist contents with ${uris.length} track(s)...',
      );
      await replacePlaylistTracks(
        api: api,
        playlistId: targetPlaylistId,
        uris: uris,
      );
    } else {
      log.info('  📤 Appending new tracks to existing playlist...');
      final added = await appendNewPlaylistTracks(
        api: api,
        requestPool: requestPool,
        playlistId: targetPlaylistId,
        uris: uris,
      );
      log.info(
        '  ➕ Added ${added.length} new track(s), '
        '${uris.length - added.length} already in playlist',
      );
    }

    log.info('  ✅ Successfully updated playlist');

    if (collection.description != null) {
      log.info('  📝 Updating playlist description...');
      try {
        final renderedDescription = _renderDescription(
          template: collection.description!,
          trackCount: dedupedTracks.length,
          sourceCount: resolvedPlaylists.length,
        );
        await api.playlists.updatePlaylist(
          targetPlaylistId,
          targetPlaylist.name ?? '',
          description: renderedDescription,
        );
        log.info('  ✅ Updated description: $renderedDescription');
      } catch (e) {
        log.warning('  ⚠️  Failed to update description: $e');
      }
    }

    if (targetPlaylist.externalUrls?.spotify != null) {
      log.info('  🔗 Playlist URL: ${targetPlaylist.externalUrls!.spotify}');
    }
  }

  /// Resolves source playlists from a list of identifiers.
  Future<List<PlaylistSimple>> _resolveSources({
    required SpotifyApi api,
    required List<String> sources,
    required List<PlaylistSimple> userPlaylists,
  }) async {
    final resolvedPlaylists = <String, PlaylistSimple>{};

    for (final source in sources) {
      final matches = await resolvePlaylistSources(
        api: api,
        input: source,
        userPlaylists: userPlaylists,
      );
      for (final match in matches) {
        if (match.id != null) {
          resolvedPlaylists[match.id!] = match;
        }
      }
    }

    return resolvedPlaylists.values.toList();
  }

  /// Renders a description template with collect-specific variables.
  ///
  /// Supported variables:
  /// - `{real_date}` - Current date (YYYY-MM-DD)
  /// - `{real_datetime}` - Current date and time (YYYY-MM-DD HH:MM)
  /// - `{real_datetime_full}` - Current date and time (YYYY-MM-DD HH:MM:SS)
  /// - `{real_time}` - Current time (HH:MM)
  /// - `{real_time_with_seconds}` - Current time (HH:MM:SS)
  /// - `{track_count}` - Number of tracks in the collection
  /// - `{source_count}` - Number of source playlists
  String _renderDescription({
    required String template,
    required int trackCount,
    required int sourceCount,
  }) {
    final now = DateTime.now();
    final placeholderPattern = RegExp(r'\{([^}]+)\}');

    return template.replaceAllMapped(placeholderPattern, (match) {
      final placeholder = match.group(1)!;

      switch (placeholder) {
        case 'real_date':
          return formatDate(now);
        case 'real_datetime':
          final date = formatDate(now);
          final hour = now.hour.toString().padLeft(2, '0');
          final minute = now.minute.toString().padLeft(2, '0');
          return '$date $hour:$minute';
        case 'real_datetime_full':
          final date = formatDate(now);
          final hour = now.hour.toString().padLeft(2, '0');
          final minute = now.minute.toString().padLeft(2, '0');
          final second = now.second.toString().padLeft(2, '0');
          return '$date $hour:$minute:$second';
        case 'real_time':
          final hour = now.hour.toString().padLeft(2, '0');
          final minute = now.minute.toString().padLeft(2, '0');
          return '$hour:$minute';
        case 'real_time_with_seconds':
          final hour = now.hour.toString().padLeft(2, '0');
          final minute = now.minute.toString().padLeft(2, '0');
          final second = now.second.toString().padLeft(2, '0');
          return '$hour:$minute:$second';
        case 'track_count':
          return trackCount.toString();
        case 'source_count':
          return sourceCount.toString();
        default:
          throw FormatException(
            'Invalid template variable: {$placeholder}\n'
            'Valid variables are: {real_date}, {real_datetime}, '
            '{real_datetime_full}, {real_time}, {real_time_with_seconds}, '
            '{track_count}, {source_count}',
          );
      }
    });
  }

  /// Deduplicates tracks while keeping the entry with the latest `addedAt`
  /// timestamp for each dedupe key.
  List<CollectedTrack> _deduplicateKeepingLatest(
    List<CollectedTrack> tracks,
    DeduplicateMode mode,
  ) {
    final latestByKey = <String, CollectedTrack>{};

    for (final track in tracks) {
      final key = switch (mode) {
        DeduplicateMode.onId => track.id.toString(),
        DeduplicateMode.onMatch => _normalizeForMatch(
          '${track.artistNames.join(' ')} ${track.name}',
        ),
      };

      final existing = latestByKey[key];
      if (existing == null || track.addedAt.isAfter(existing.addedAt)) {
        latestByKey[key] = track;
      }
    }

    return latestByKey.values.toList();
  }

  String _normalizeForMatch(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
