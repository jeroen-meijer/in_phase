import 'dart:isolate';

import 'package:args/command_runner.dart';
import 'package:collection/collection.dart';
import 'package:dcli/dcli.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:io/io.dart';
import 'package:rekorddart/rekorddart.dart';
import 'package:rkdb_dart/src/entities/entities.dart';
import 'package:rkdb_dart/src/logger/logger.dart';
import 'package:rkdb_dart/src/misc/misc.dart';
import 'package:rkdb_dart/src/spotify/spotify.dart';
import 'package:spotify/spotify.dart';

class SyncCommand extends Command<int> {
  SyncCommand();

  @override
  final String name = 'sync';

  @override
  final String description =
      'Syncs playlists on Spotify with Rekordbox. '
      'Place  a list of playlist IDs to sync.';

  /// Regex for Camelot keys (4A, 12B, etc.)
  ///
  /// Anywhere in the given string:
  /// - One digit (1-9)
  /// - Optionally one digit (0-2)
  /// - One of two letters: A or B
  static final _camelotKeyRegex = RegExp('([1-9]|1[0-2])[AB]');

  static Future<List<DjmdPlaylistData>> rbPlaylists(
    RekordboxDatabase db,
  ) async => db.select(db.djmdPlaylist).get();

  static Future<List<DjmdPlaylistData>> rbPlaylistFolders(
    RekordboxDatabase db,
  ) async => (await rbPlaylists(db)).where((e) => e.attribute == 1).toList();

  static Future<List<DjmdPlaylistData>> rbRealPlaylists(
    RekordboxDatabase db,
  ) async => (await rbPlaylists(db)).where((e) => e.attribute == 0).toList();

  @override
  Future<int> run() async {
    final teardown = <Future<void> Function()>[];
    try {
      final syncConfig = await SyncConfig.fromFile(Constants.syncConfigFile);

      var syncCache = await SyncCache.fromFile(Constants.syncCacheFile);
      teardown.add(() => syncCache.write(Constants.syncCacheFile));

      final api = await spotifyLogin();
      teardown.add(() async => (await api.client).close());

      final db = await RekordboxDatabase.connect();
      teardown.add(db.close);

      final requestPool = Zonable.fromZone<RequestPool>();
      teardown.add(() async => requestPool.clear());

      final List<PlaylistSimple> spPlaylists;

      if (argResults!.rest case final rest when rest.isNotEmpty) {
        spPlaylists = await _getPlaylistsFromArgs(api, rest);
      } else {
        spPlaylists = await _getPlaylistsFromConfig(api, syncConfig);
      }

      // Check which playlists need fetching and start all requests concurrently
      final playlistFetchFutures =
          <SpotifyPlaylistId, Future<Iterable<PlaylistTrack>>>{};
      for (final spPlaylist in spPlaylists) {
        final spPlaylistId = SpotifyPlaylistId(spPlaylist.id!);
        final spSnapshotId = spPlaylist.snapshotId ?? '';

        // Only fetch if snapshot has changed or not cached
        if (syncCache.isPlaylistChanged(spPlaylistId, spSnapshotId)) {
          playlistFetchFutures[spPlaylistId] = requestPool.request(
            () => api.playlists.getTracksByPlaylistId(spPlaylistId).all(50),
            identifier: '${spPlaylist.uri!}-tracks',
          );
        }
      }

      final rbAllSongsAndArtists = await db
          .select(db.djmdContent)
          .join([
            leftOuterJoin(
              db.djmdArtist,
              db.djmdContent.artistID.equalsExp(db.djmdArtist.id),
            ),
          ])
          .map(
            (e) => _RbSongAndArtist(
              artist: e.readTableOrNull(db.djmdArtist),
              song: e.readTable(db.djmdContent),
            ),
          )
          .get();

      final rbKeys = await db.select(db.djmdKey).get();
      final rbCamelotKeys = rbKeys
          .where((e) => _camelotKeyRegex.hasMatch(e.scaleName ?? ''))
          .toSet();

      for (final spPlaylist in spPlaylists) {
        final spPlaylistId = SpotifyPlaylistId(spPlaylist.id!);
        final spPlaylistName = spPlaylist.name!;
        final spSnapshotId = spPlaylist.snapshotId ?? '';

        void logPlaylist(String message) {
          log.info('[${green(spPlaylistName)}] $message');
        }

        logPlaylist('Syncing playlist (snapshot: $spSnapshotId)');

        // Check if we have a cached version with matching snapshot ID
        final List<CachedSyncTrack> trackList;
        if (playlistFetchFutures.containsKey(spPlaylistId)) {
          // We started fetching this playlist, await the result
          logPlaylist('Retrieving tracks from Spotify');
          final spPlaylistTrackList = await playlistFetchFutures[spPlaylistId]!;

          logPlaylist(
            'Retrieved ${spPlaylistTrackList.length} tracks from Spotify',
          );

          // Convert and cache tracks
          trackList = spPlaylistTrackList.where((e) => e.track != null).map(
            (e) {
              final track = e.track!;
              return CachedSyncTrack(
                id: SpotifyTrackId(track.id!),
                name: track.name!,
                artistNames: track.artists!.map((Artist a) => a.name!).toList(),
              );
            },
          ).toList();

          // Update cache with this playlist
          syncCache = syncCache.withPlaylist(
            spPlaylistId,
            CachedSyncPlaylist(
              snapshotId: spSnapshotId,
              name: spPlaylistName,
              tracks: trackList,
              cachedAt: DateTime.now(),
            ),
          );
        } else {
          // Use cached data
          final cachedPlaylist = syncCache.playlists[spPlaylistId]!;
          logPlaylist(
            '💾 Using cached playlist data '
            '(${cachedPlaylist.tracks.length} tracks)',
          );
          trackList = cachedPlaylist.tracks;
        }

        DjmdKeyData? rbKey;
        if (syncConfig.overwriteSongKeys) {
          if (_extractCamelotKey(spPlaylistName) case final detectedKey?) {
            rbKey = rbCamelotKeys.firstWhereOrNull(
              (e) => e.scaleName == detectedKey,
            );
          }
        }

        if (rbKey != null) {
          logPlaylist('Detected Camelot key: ${rbKey.scaleName}');
        }

        final targetFolderEntry = syncConfig.folders.entries.firstWhereOrNull(
          (e) => e.value.playlists.any((glob) => glob.matches(spPlaylistName)),
        );
        final targetFolderName = targetFolderEntry?.key;

        DjmdPlaylistData? rbTargetFolder;
        if (targetFolderName != null) {
          rbTargetFolder = (await rbPlaylistFolders(db)).firstWhereOrNull(
            (e) => e.name == targetFolderName,
          );

          if (rbTargetFolder == null) {
            logPlaylist('Creating playlist folder "$targetFolderName"');
            rbTargetFolder = await db.createPlaylistFolder(
              name: targetFolderName,
            );
          }
        }

        var rbPlaylist = (await rbRealPlaylists(db)).firstWhereOrNull(
          (e) => e.name == spPlaylistName,
        );
        if (rbPlaylist != null) {
          logPlaylist('Deleting existing playlist "$spPlaylistName"');
          await db.deletePlaylist(rbPlaylist.id!);
        }

        rbPlaylist = await db.createPlaylist(
          name: spPlaylistName,
          parentId: rbTargetFolder?.id,
        );

        // Build initial tracklist from Spotify
        final rbPlaylistSongQueue = <_TracklistEntry>[];

        for (var i = 0; i < trackList.length; i++) {
          final cachedTrack = trackList[i];
          final spTrackId = cachedTrack.id;

          void logTrack(String message, {bool? first}) {
            const intermediateChar = '├';
            const finalChar = '└';
            logPlaylist(
              [
                '<${cyan(spTrackId)}>',
                switch (first) {
                  true => ' ',
                  null => ' $intermediateChar ',
                  false => ' $finalChar ',
                },
                message,
              ].join(),
            );
          }

          logTrack(
            // ignore: lines_longer_than_80_chars
            'Syncing track "${cachedTrack.artistNames.join(', ')} - ${cachedTrack.name}"',
            first: true,
          );

          var rbSong = await _findTrack(
            spTrackId: spTrackId,
            spTrackName: cachedTrack.name,
            spArtistNames: cachedTrack.artistNames,
            rbSongsAndArtists: rbAllSongsAndArtists,
            mappings: syncCache.mappings,
          );

          if (rbSong != null) {
            final rbSongId = RekordboxSongId(rbSong.id!);

            logTrack('Found match in Rekordbox: ${rbSong.title}');
            syncCache.mappings[spTrackId] = rbSongId;

            if (rbKey != null) {
              logTrack('Updating song key to ${rbKey.scaleName}');
              rbSong = await db.updateSong(rbSongId, keyId: rbKey.id);
            }

            logTrack('Added to playlist queue', first: false);
            rbPlaylistSongQueue.add(
              _TracklistEntry(
                originalIndex: i + 1,
                trackId: rbSongId,
                isCustom: false,
              ),
            );
          } else {
            logTrack('No match found, adding to missing tracks', first: false);
            syncCache.missingTracks[spTrackId] = MissingTrack(
              id: spTrackId,
              artist: cachedTrack.artistNames.join(', '),
              title: cachedTrack.name,
              itunesUrl: null,
              lastInsertedAt: DateTime.now(),
            );
          }
        }

        // Apply custom tracks if configured
        final customTracks = syncConfig.customTracks[spPlaylistId] ?? [];
        if (customTracks.isNotEmpty) {
          logPlaylist('Applying ${customTracks.length} custom track(s)...');

          final rbPlaylistTracksById = <String, _TracklistEntry>{
            for (final entry in rbPlaylistSongQueue) entry.trackId.value: entry,
          };

          final updatedTracklist = await _applyCustomTracks(
            customTracks: customTracks,
            initialTracklist: rbPlaylistTracksById.values.toList(),
            rbAllSongsAndArtists: rbAllSongsAndArtists,
            logPlaylist: logPlaylist,
          );

          rbPlaylistSongQueue
            ..clear()
            ..addAll(updatedTracklist);
        }

        // Add all tracks to playlist
        logPlaylist(
          'Adding ${rbPlaylistSongQueue.length} track(s) to playlist...',
        );
        for (final entry in rbPlaylistSongQueue) {
          await db.addSongToPlaylist(
            playlistId: rbPlaylist.id!,
            contentId: entry.trackId,
          );
        }
      }

      return ExitCode.success.code;
    } finally {
      await Future.wait([
        for (final fn in teardown)
          fn().catchError((Object e) => printerr('Error in teardown: $e')),
      ]);
    }
  }

  static Future<List<PlaylistSimple>> _getPlaylistsFromArgs(
    SpotifyApi spotifyApi,
    List<String> args,
  ) async {
    final playlistIds = args
        .map((e) => e.trim())
        .map((e) => Uri.tryParse(e)?.pathSegments.last ?? e)
        .map(
          (e) =>
              SpotifyPlaylistId.tryParse(e) ??
              (throw Exception('Invalid playlist ID: $e')),
        );

    final requestPool = Zonable.fromZone<RequestPool>();

    log
      ..info('Fetching ${playlistIds.length} playlists from Spotify')
      ..debug('Playlist IDs: ${playlistIds.join(', ')}');

    final playlists = await Future.wait([
      for (final playlistId in playlistIds)
        requestPool.request(
          () => spotifyApi.playlists.get(playlistId),
          identifier: playlistId.uri,
        ),
    ]);

    return playlists;
  }

  static Future<List<PlaylistSimple>> _getPlaylistsFromConfig(
    SpotifyApi spotifyApi,
    SyncConfig syncConfig,
  ) async {
    log.info('Fetching all user playlists');
    final allPlaylists = await spotifyApi.playlists.me.all(50);

    log.info('Filtering ${allPlaylists.length} playlists by sync config');
    final filteredPlaylists = allPlaylists
        .where(
          (playlist) => syncConfig.playlists.any(
            (glob) => glob.matches(playlist.name ?? ''),
          ),
        )
        .toList();

    log
      ..info('Found ${filteredPlaylists.length} playlists to sync')
      ..debug(
        'Filtered playlists: '
        '${filteredPlaylists.map((e) => e.name).join(', ')}',
      );

    return filteredPlaylists;
  }

  static Future<DjmdContentData?> _findTrack({
    required SpotifyTrackId spTrackId,
    required String spTrackName,
    required List<String> spArtistNames,
    required List<_RbSongAndArtist> rbSongsAndArtists,
    required Map<SpotifyTrackId, RekordboxSongId> mappings,
    int threshold = 80,
  }) async {
    if (mappings[spTrackId] case final rbSongId?) {
      if (rbSongsAndArtists.firstWhereOrNull((e) => e.song.id == rbSongId)
          case _RbSongAndArtist(song: final rbSong)) {
        return rbSong;
      } else {
        log.warning(
          'Sync cache contains an invalid Rekordbox song ID: $rbSongId',
        );
      }
    }

    const threads = 4;

    log.info('Finding fuzzy match for $spTrackName ($threads threads)');
    final fuzzyMatch = await _findFuzzyMatch(
      spTrackName: spTrackName,
      spArtistNames: spArtistNames,
      rbSongsAndArtists: rbSongsAndArtists,
      // ignore: avoid_redundant_argument_values
      threads: threads,
    );

    final _RbSongAndArtist(:artist, :song) = fuzzyMatch.value;

    log.info(
      'Best match: "${artist?.name ?? 'Unknown artist'} - ${song.title}" '
      '(score: ${fuzzyMatch.score})',
    );
    if (fuzzyMatch.score < threshold) {
      log.info('Threshold not met, skipping');
      return null;
    }

    log.info('Returning match');
    return song;
  }

  String? _extractCamelotKey(String playlistName) {
    return playlistName
        .toUpperCase()
        .split('_')
        .expand((e) => e.split('-'))
        .expand((e) => e.split(' '))
        .where((e) => e.isNotEmpty)
        .firstWhereOrNull(_camelotKeyRegex.hasMatch);
  }

  static Future<FuzzyFindMatch<_RbSongAndArtist>> _findFuzzyMatch({
    required String spTrackName,
    required List<String> spArtistNames,
    required List<_RbSongAndArtist> rbSongsAndArtists,
    int threads = 4,
  }) async {
    if (rbSongsAndArtists.isEmpty) {
      throw Exception('No Rekordbox songs and artists to find match for');
    }

    FuzzyFindMatch<_RbSongAndArtist> findFuzzyMatchForChunk(
      List<_RbSongAndArtist> rbSongsAndArtists,
    ) {
      final query = _normalizeQuery(
        spArtistNames,
        spTrackName,
      );

      var bestScore = 0;
      var bestMatch = rbSongsAndArtists.first;

      for (final rbSongAndArtist in rbSongsAndArtists) {
        final target = _normalizeQuery(
          [rbSongAndArtist.artist?.name ?? ''],
          rbSongAndArtist.song.title!,
        );
        final score = tokenSortRatio(query, target);

        if (score > bestScore) {
          bestScore = score;
          bestMatch = rbSongAndArtist;
        }
      }

      return FuzzyFindMatch(value: bestMatch, score: bestScore);
    }

    if (threads == 1) {
      return findFuzzyMatchForChunk(rbSongsAndArtists);
    }

    final itemsPerThread = (rbSongsAndArtists.length / threads).ceil();
    final chunks = rbSongsAndArtists.slices(itemsPerThread);

    final results = await Future.wait([
      for (final chunk in chunks)
        Isolate.run(() => findFuzzyMatchForChunk(chunk)),
    ]);

    return maxBy<FuzzyFindMatch<_RbSongAndArtist>, int>(
      results,
      (e) => e.score,
    )!;
  }

  static String _normalizeQuery(List<String> artists, String title) {
    return '${artists.join(' ')} $title'
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _RbSongAndArtist {
  const _RbSongAndArtist({
    required this.artist,
    required this.song,
  });

  final DjmdArtistData? artist;
  final DjmdContentData song;
}

class FuzzyFindMatch<T> {
  const FuzzyFindMatch({
    required this.value,
    required this.score,
  });

  final T value;
  final int score;
}

class _TracklistEntry {
  const _TracklistEntry({
    required this.originalIndex,
    required this.trackId,
    required this.isCustom,
  });

  final int? originalIndex;
  final RekordboxSongId trackId;
  final bool isCustom;
}

/// Applies custom tracks (insert and replace operations) to the initial
/// tracklist.
Future<List<_TracklistEntry>> _applyCustomTracks({
  required List<CustomTrack> customTracks,
  required List<_TracklistEntry> initialTracklist,
  required List<_RbSongAndArtist> rbAllSongsAndArtists,
  required void Function(String) logPlaylist,
}) async {
  // Separate inserts and replaces
  final insertsToProcess = <CustomTrack>[];
  final replacesToProcess = <CustomTrack>[];

  for (final customTrack in customTracks) {
    // Validate that the rekordbox track exists
    final rbSong = rbAllSongsAndArtists.firstWhereOrNull(
      (e) => e.song.id == customTrack.rekordboxId,
    );

    if (rbSong == null) {
      logPlaylist(
        '  ⚠️  WARNING: Custom track with Rekordbox ID '
        '${customTrack.rekordboxId} not found. Skipping.',
      );
      continue;
    }

    switch (customTrack.type) {
      case CustomTrackType.insert:
        insertsToProcess.add(customTrack);
      case CustomTrackType.replace:
        replacesToProcess.add(customTrack);
    }
  }

  var workingTracklist = List<_TracklistEntry>.from(initialTracklist);

  // Process inserts first
  if (insertsToProcess.isNotEmpty) {
    workingTracklist = _processInserts(
      inserts: insertsToProcess,
      tracklist: workingTracklist,
      logPlaylist: logPlaylist,
    );
  }

  // Process replacements
  if (replacesToProcess.isNotEmpty) {
    workingTracklist = _processReplacements(
      replacements: replacesToProcess,
      tracklist: workingTracklist,
      logPlaylist: logPlaylist,
    );
  }

  return workingTracklist;
}

/// Processes insert-type custom tracks.
List<_TracklistEntry> _processInserts({
  required List<CustomTrack> inserts,
  required List<_TracklistEntry> tracklist,
  required void Function(String) logPlaylist,
}) {
  final result = List<_TracklistEntry>.from(tracklist);

  // Group inserts by their target index
  final insertsByIndex = <int?, List<String>>{};

  for (final insert in inserts) {
    int? targetIndex;

    if (insert.target != null) {
      // Find the target track and calculate index
      final offset =
          insert.index ?? (insert.position != null ? insert.position! - 1 : 0);

      for (var i = 0; i < result.length; i++) {
        if (result[i].trackId.value == insert.target) {
          targetIndex = (result[i].originalIndex ?? 0) + offset;
          break;
        }
      }

      if (targetIndex == null) {
        logPlaylist(
          '  ⚠️  WARNING: Custom track ${insert.rekordboxId} references '
          'missing target track ID ${insert.target}. Skipping.',
        );
        continue;
      }
    } else if (insert.position != null) {
      targetIndex = insert.position! - 1; // Convert 1-based to 0-based
    } else {
      targetIndex = insert.index; // Already 0-based or null
    }

    // Validate index bounds
    if (targetIndex != null &&
        (targetIndex < 0 || targetIndex > result.length)) {
      logPlaylist(
        '  ⚠️  WARNING: Custom track ${insert.rekordboxId} specifies '
        'out-of-bounds index $targetIndex. Appending to end.',
      );
      targetIndex = null;
    }

    insertsByIndex.putIfAbsent(targetIndex, () => []).add(insert.rekordboxId);
  }

  // Insert tracks at the end (null index) first
  final tracksToAppend = insertsByIndex.remove(null) ?? [];
  for (final trackId in tracksToAppend) {
    logPlaylist('  ├ Appending custom track [$trackId] to end of playlist');
    result.add(
      _TracklistEntry(
        originalIndex: null,
        trackId: RekordboxSongId(trackId),
        isCustom: true,
      ),
    );
  }

  // Sort indices in descending order to insert from end to start
  final sortedIndices = insertsByIndex.keys.toList()
    ..sort((a, b) => b!.compareTo(a!));

  for (final targetIndex in sortedIndices) {
    final tracksToInsert = insertsByIndex[targetIndex]!;

    // Find insertion position in the working list
    var insertionPos = 0;
    for (var i = 0; i < result.length; i++) {
      if (result[i].originalIndex != null &&
          result[i].originalIndex! > targetIndex!) {
        insertionPos = i;
        break;
      }
      insertionPos = i + 1;
    }

    logPlaylist(
      '  ├ Inserting ${tracksToInsert.length} custom track(s) at '
      'index $targetIndex: $tracksToInsert',
    );

    // Insert tracks in order, incrementing position to maintain sequence
    for (final trackId in tracksToInsert) {
      result.insert(
        insertionPos,
        _TracklistEntry(
          originalIndex: targetIndex,
          trackId: RekordboxSongId(trackId),
          isCustom: true,
        ),
      );
      insertionPos++; // Next track goes after this one
    }
  }

  return result;
}

/// Processes replace-type custom tracks.
List<_TracklistEntry> _processReplacements({
  required List<CustomTrack> replacements,
  required List<_TracklistEntry> tracklist,
  required void Function(String) logPlaylist,
}) {
  final result = List<_TracklistEntry>.from(tracklist);

  for (final replacement in replacements) {
    var replaced = false;

    if (replacement.target != null) {
      // Replace by target track ID
      for (var i = 0; i < result.length; i++) {
        if (result[i].trackId.value == replacement.target &&
            !result[i].isCustom) {
          logPlaylist(
            '  ├ Replacing track with ID ${result[i].trackId.value} '
            'with custom track ${replacement.rekordboxId}',
          );
          result[i] = _TracklistEntry(
            originalIndex: result[i].originalIndex,
            trackId: RekordboxSongId(replacement.rekordboxId),
            isCustom: true,
          );
          replaced = true;
          break;
        }
      }
    } else {
      // Replace by index or position
      final targetIndex = replacement.position != null
          ? replacement.position! - 1
          : replacement.index;

      if (targetIndex != null) {
        for (var i = 0; i < result.length; i++) {
          if (result[i].originalIndex == targetIndex + 1 &&
              !result[i].isCustom) {
            logPlaylist(
              '  ├ Replacing track with ID ${result[i].trackId.value} at '
              'index $targetIndex with custom track ${replacement.rekordboxId}',
            );
            result[i] = _TracklistEntry(
              originalIndex: targetIndex,
              trackId: RekordboxSongId(replacement.rekordboxId),
              isCustom: true,
            );
            replaced = true;
            break;
          }
        }
      }
    }

    if (!replaced) {
      if (replacement.target != null) {
        logPlaylist(
          '  ⚠️  WARNING: Could not replace track with target ID '
          '${replacement.target} (not found). Custom track '
          '${replacement.rekordboxId} not inserted.',
        );
      } else {
        final targetIndex = replacement.position != null
            ? replacement.position! - 1
            : replacement.index;
        logPlaylist(
          '  ⚠️  WARNING: Could not replace track at index $targetIndex '
          '(not found). Custom track ${replacement.rekordboxId} not inserted.',
        );
      }
    }
  }

  return result;
}
