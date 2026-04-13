import 'package:args/command_runner.dart';
import 'package:glob/glob.dart';
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
      'into a single target playlist.';

  @override
  Future<int> run() async {
    final teardown = <Future<void> Function()>[];

    try {
      // Load configuration
      final customConfigPath = argResults!['config'] as String?;
      final usesCustomConfigPath = customConfigPath != null;

      final configFile = usesCustomConfigPath
          ? resolveConfigPath(customConfigPath)
          : Constants.collectConfigFile;

      log.info('Loading collect config from: ${configFile.path}');
      final config = await CollectConfig.fromFile(
        configFile,
        createFileIfNotExists: !usesCustomConfigPath,
      );

      if (config.collections.isEmpty) {
        log.warning('No collections found in configuration');
        return ExitCode.config.code;
      }

      // Login to Spotify
      final api = await spotifyLogin();

      // TODO(jeroen-meijer): Create issue for this lint ignore and refactor
      // ignore: invalid_use_of_visible_for_testing_member
      teardown.add(() async => (await api.client).close());

      // Initialize request pool
      final requestPool = Zonable.fromZone<RequestPool>();
      teardown.add(() async => requestPool.clear());

      // Get current user
      final user = await api.me.get();
      log.info('Logged in as: ${user.displayName}');

      // Filter collections if specific ones were requested
      final requestedCollections = argResults!['collection'] as List<String>;
      var collectionsToRun = config.collections;
      if (requestedCollections.isNotEmpty) {
        collectionsToRun = config.collections
            .where(
              (collection) => requestedCollections.contains(collection.name),
            )
            .toList();

        if (collectionsToRun.isEmpty) {
          usageException(
            'No matching collections found for: '
            '${requestedCollections.join(', ')}',
          );
        }
      }

      log
        ..info('Found ${collectionsToRun.length} collection(s) to process')
        ..info('');

      // Check if dry run
      final isDryRun = argResults!['dry-run'] as bool;
      if (isDryRun) {
        log
          ..info('🔍 DRY RUN MODE - No playlists will be updated')
          ..info('');
      }

      // Fetch user playlists once (for glob/name resolution)
      log.info('Fetching user playlists for source resolution...');
      final userPlaylists = [...await api.me.playlists.saved().all(50)];
      log.info('Found ${userPlaylists.length} user playlist(s)');

      // Process each collection
      for (final (index, collection) in collectionsToRun.indexed) {
        log.info(
          '🔄 Processing collection ${index + 1}/${collectionsToRun.length}: '
          '${collection.name}',
        );

        await _processCollection(
          api: api,
          user: user,
          collection: collection,
          requestPool: requestPool,
          userPlaylists: userPlaylists,
          isDryRun: isDryRun,
        );

        log.info('');
      }

      log.info('✅ Collect complete!');

      return ExitCode.success.code;
    } catch (e, stackTrace) {
      log
        ..error('❌ Fatal error: $e')
        ..debug('Stack trace: $stackTrace');
      return ExitCode.software.code;
    } finally {
      await Future.wait([
        for (final fn in teardown)
          fn().catchError((Object e) {
            log.error('Error in teardown: $e');
          }),
      ]);
    }
  }

  Future<void> _processCollection({
    required SpotifyApi api,
    required User user,
    required CollectCollection collection,
    required RequestPool requestPool,
    required List<PlaylistSimple> userPlaylists,
    required bool isDryRun,
  }) async {
    // Resolve source playlists
    log.info('  📋 Resolving source playlists...');
    final resolvedPlaylists = await _resolveSources(
      api: api,
      sources: collection.sources,
      userPlaylists: userPlaylists,
      requestPool: requestPool,
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

      try {
        final playlistTracks = await requestPool.request(
          () => api.playlists.getPlaylistTracks(playlist.id!).all(50),
          identifier: SpotifyCacheIdentifier.playlistTracks(
            SpotifyPlaylistId(playlist.id!),
          ),
        );

        // Convert to CollectedTrack (no date filtering for collect)
        for (final playlistTrack in playlistTracks) {
          if (playlistTrack.track?.id == null) continue;

          final track = playlistTrack.track!;
          final collectedTrack = CollectedTrack(
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
          );

          allTracks.add(collectedTrack);
        }

        log.info(
          '    ✅ Found ${playlistTracks.length} track(s) from '
          '"${playlist.name}"',
        );
      } catch (e) {
        log.error('    ❌ Error fetching from "${playlist.name}": $e');
      }
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

    // Resolve target playlist
    log.info('  🎯 Resolving target playlist...');
    final targetPlaylist = await _resolveTarget(
      api: api,
      target: collection.target,
      userPlaylists: userPlaylists,
      collectionName: collection.name,
    );

    if (targetPlaylist == null) {
      log.error(
        '  ❌ Could not resolve target playlist: ${collection.target}',
      );
      throw Exception(
        'Failed to resolve target playlist for collection '
        '"${collection.name}". See errors above.',
      );
    }

    log.info('  ✅ Target playlist: "${targetPlaylist.name}"');

    if (isDryRun) {
      final replaceMode = collection.options?.replace ?? true;
      if (replaceMode) {
        log.info(
          '  🔍 DRY RUN: Would replace playlist with '
          '${dedupedTracks.length} tracks',
        );
      } else {
        log.info(
          '  🔍 DRY RUN: Would check existing tracks and append new ones '
          '(${dedupedTracks.length} tracks to check)',
        );
      }
      return;
    }

    // Determine mode: replace or append
    final replaceMode = collection.options?.replace ?? true;

    // Get tracks to add
    List<String> trackUris;
    if (replaceMode) {
      log.info(
        '  📤 Replacing playlist contents with ${dedupedTracks.length} '
        'track(s)...',
      );
      // Convert all tracks to URIs
      trackUris = dedupedTracks.map((t) => t.uri).toList();
    } else {
      log
        ..info(
          '  📤 Appending ${dedupedTracks.length} track(s) to existing '
          'playlist...',
        )
        ..info('  🔍 Checking existing tracks in playlist...');
      final existingPlaylistTracksPages = await requestPool
          .request<List<PlaylistTrack>>(
            () async {
              final pages = await api.playlists
                  .getPlaylistTracks(targetPlaylist.id!)
                  .all(50);
              return pages.toList();
            },
            identifier: SpotifyCacheIdentifier.playlistTracks(
              SpotifyPlaylistId(targetPlaylist.id!),
            ),
          );

      // Extract existing track IDs
      final existingTrackIds = <String>{};
      for (final playlistTrack in existingPlaylistTracksPages) {
        if (playlistTrack.track?.id != null) {
          existingTrackIds.add(playlistTrack.track!.id!);
        }
      }

      log.info('  📊 Found ${existingTrackIds.length} existing track(s)');

      // Filter out tracks that are already in the playlist
      final newTracks = dedupedTracks
          .where((track) => !existingTrackIds.contains(track.id.toString()))
          .toList();

      final skippedCount = dedupedTracks.length - newTracks.length;
      if (skippedCount > 0) {
        log.info(
          '  ⏭️  Skipping $skippedCount track(s) already in playlist',
        );
      }

      if (newTracks.isEmpty) {
        log.info('  ✅ All tracks already in playlist, nothing to add');
        return;
      }

      log.info(
        '  ➕ Adding ${newTracks.length} new track(s) to playlist',
      );

      // Convert new tracks to URIs
      trackUris = newTracks.map((t) => t.uri).toList();
    }

    // Clear playlist first if replacing
    if (replaceMode) {
      await api.playlists.clear(targetPlaylist.id!);
    }

    // Add tracks in batches of 100 (Spotify API limit)
    for (var i = 0; i < trackUris.length; i += 100) {
      final batch = trackUris.skip(i).take(100).toList();
      await api.playlists.addTracks(batch, targetPlaylist.id!);
    }

    log.info('  ✅ Successfully updated playlist');

    // Update playlist description if configured
    if (collection.description != null) {
      log.info('  📝 Updating playlist description...');
      try {
        final renderedDescription = _renderDescription(
          template: collection.description!,
          trackCount: dedupedTracks.length,
          sourceCount: resolvedPlaylists.length,
        );
        await api.playlists.updatePlaylist(
          targetPlaylist.id!,
          targetPlaylist.name ?? '',
          description: renderedDescription,
        );
        log.info('  ✅ Updated description: $renderedDescription');
      } catch (e) {
        log.warning('  ⚠️  Failed to update description: $e');
      }
    }

    // Show playlist URL
    if (targetPlaylist.externalUrls?.spotify != null) {
      log.info('  🔗 Playlist URL: ${targetPlaylist.externalUrls!.spotify}');
    }
  }

  /// Resolves source playlists from a list of identifiers.
  ///
  /// Supports:
  /// - Playlist IDs, URIs, or share URLs (via tryExtract)
  /// - Glob patterns (e.g., "DnB Releases*")
  /// - Exact playlist names
  ///
  /// Returns deduplicated list of resolved playlists.
  Future<List<PlaylistSimple>> _resolveSources({
    required SpotifyApi api,
    required List<String> sources,
    required List<PlaylistSimple> userPlaylists,
    required RequestPool requestPool,
  }) async {
    final resolvedPlaylists = <String, PlaylistSimple>{};

    for (final source in sources) {
      // Try ID/URI/URL first
      final playlistId = SpotifyPlaylistId.tryExtract(source);
      if (playlistId != null) {
        try {
          final playlist = await requestPool.request(
            () => api.playlists.get(playlistId),
            identifier: SpotifyCacheIdentifier.playlist(playlistId),
          );
          resolvedPlaylists[playlist.id!] = playlist;
          log.debug('    ✅ Resolved ID: "$source" → "${playlist.name}"');
          continue;
        } catch (e) {
          log.warning('    ⚠️  Could not fetch playlist by ID "$source": $e');
          continue;
        }
      }

      // Check if it's a glob pattern
      if (_isGlobPattern(source)) {
        final glob = Glob(source);
        final matches = userPlaylists
            .where((p) => glob.matches(p.name ?? ''))
            .toList();

        if (matches.isEmpty) {
          log.warning('    ⚠️  Glob "$source" matched 0 playlists');
        } else {
          log.info(
            '    ✅ Glob "$source" matched ${matches.length} playlist(s)',
          );
          for (final match in matches) {
            if (match.id != null) {
              resolvedPlaylists[match.id!] = match;
            }
          }
        }
        continue;
      }

      // Otherwise, treat as exact name match
      final matches = userPlaylists.where((p) => p.name == source).toList();

      if (matches.isEmpty) {
        log.warning('    ⚠️  Exact name "$source" matched 0 playlists');
      } else if (matches.length > 1) {
        log.warning(
          '    ⚠️  Exact name "$source" matched ${matches.length} '
          'playlists, using first match',
        );
        if (matches.first.id != null) {
          resolvedPlaylists[matches.first.id!] = matches.first;
        }
      } else {
        log.debug('    ✅ Resolved name: "$source"');
        if (matches.first.id != null) {
          resolvedPlaylists[matches.first.id!] = matches.first;
        }
      }
    }

    return resolvedPlaylists.values.toList();
  }

  /// Resolves target playlist from identifier (ID, URI, URL, or exact name).
  ///
  /// Returns null if the playlist cannot be resolved, with appropriate error
  /// messages logged.
  Future<PlaylistSimple?> _resolveTarget({
    required SpotifyApi api,
    required String target,
    required List<PlaylistSimple> userPlaylists,
    required String collectionName,
  }) async {
    // Try ID/URI/URL first
    final playlistId = SpotifyPlaylistId.tryExtract(target);
    if (playlistId != null) {
      try {
        final playlist = await api.playlists.get(playlistId);
        log.debug(
          '    ✅ Resolved target by ID: "$target" → "${playlist.name}"',
        );
        return playlist;
      } catch (e) {
        log
          ..error(
            '    ❌ Could not fetch target playlist by ID "$target": $e',
          )
          ..error(
            '    💡 Make sure the playlist ID is correct and you have access '
            'to it (you own it or have collaborative edit access).',
          );
        return null;
      }
    }

    // Otherwise, treat as exact name match
    final matches = userPlaylists.where((p) => p.name == target).toList();

    if (matches.isEmpty) {
      log
        ..error(
          '    ❌ Target playlist "$target" not found in your playlists.',
        )
        ..error(
          '    💡 Make sure the playlist name matches exactly, or use a '
          'playlist ID, URI, or share URL instead.',
        );
      return null;
    }

    if (matches.length > 1) {
      log.error(
        '    ❌ Target playlist "$target" matched ${matches.length} '
        'playlists:',
      );
      for (final match in matches) {
        log.error('      - "${match.name}" (ID: ${match.id})');
      }
      log.error(
        '    💡 Please use a playlist ID, URI, or share URL instead to '
        'uniquely identify the target playlist.',
      );
      return null;
    }

    log.debug('    ✅ Resolved target by name: "$target"');
    return matches.first;
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

  /// Checks if a string contains glob pattern characters.
  bool _isGlobPattern(String input) {
    return input.contains('*') ||
        input.contains('?') ||
        input.contains('[') ||
        input.contains(']');
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
