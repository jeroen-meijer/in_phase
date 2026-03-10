import 'dart:convert';
import 'dart:isolate';

import 'package:args/command_runner.dart';
import 'package:collection/collection.dart';
import 'package:dcli/dcli.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:in_phase/src/database/database.exports.dart';
import 'package:in_phase/src/entities/entities.dart';
import 'package:in_phase/src/logger/logger.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:in_phase/src/reports/reports.dart';
import 'package:in_phase/src/spotify/spotify.dart';
import 'package:io/io.dart';
import 'package:rekorddart/rekorddart.dart';
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
    RekordboxDatabase rbDb,
  ) async => rbDb.select(rbDb.djmdPlaylist).get();

  static Future<List<DjmdPlaylistData>> rbPlaylistFolders(
    RekordboxDatabase rbDb,
  ) async => (await rbPlaylists(rbDb)).where((e) => e.attribute == 1).toList();

  static Future<List<DjmdPlaylistData>> rbRealPlaylists(
    RekordboxDatabase rbDb,
  ) async => (await rbPlaylists(rbDb)).where((e) => e.attribute == 0).toList();

  @override
  Future<int> run() async {
    final commandStartTime = DateTime.now();
    final playlistReports = <SyncPlaylistReport>[];

    return withTeardown((addTeardown) async {
      final syncConfig = await SyncConfig.fromFile(Constants.syncConfigFile);

      final api = await spotifyLogin();
      // ignore: invalid_use_of_visible_for_testing_member
      addTeardown(() async => (await api.client).close());

      final rbDb = await RekordboxDatabase.connect();
      addTeardown(rbDb.close);

      final requestPool = Zonable.fromZone<RequestPool>();
      addTeardown(() async => requestPool.clear());

      final syncDb = db();

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
        if (await syncDb.syncPlaylistsDao.isPlaylistChanged(
          spPlaylistId,
          spSnapshotId,
        )) {
          playlistFetchFutures[spPlaylistId] = requestPool.request(
            () => api.playlists.getPlaylistTracks(spPlaylistId).all(50),
            identifier: SpotifyCacheIdentifier.playlistTracks(spPlaylistId),
          );
        }
      }

      final rbAllSongsAndArtists = await rbDb
          .select(rbDb.djmdContent)
          .join([
            leftOuterJoin(
              rbDb.djmdArtist,
              rbDb.djmdContent.artistID.equalsExp(rbDb.djmdArtist.id),
            ),
          ])
          .map(
            (e) => (
              artist: e.readTableOrNull(rbDb.djmdArtist),
              song: e.readTable(rbDb.djmdContent),
            ),
          )
          .get();

      final rbKeys = await rbDb.select(rbDb.djmdKey).get();
      final rbCamelotKeys = rbKeys
          .where((e) => _camelotKeyRegex.hasMatch(e.scaleName ?? ''))
          .toSet();

      // Keep one missing-row candidate per Spotify track and retain the latest
      // playlist-added date across all playlists in this sync run.
      final missingTracksById =
          <
            String,
            ({SpotifyTrackId id, String artist, String title, DateTime addedAt})
          >{};
      final foundTrackIds = <SpotifyTrackId>{};

      for (final spPlaylist in spPlaylists) {
        final playlistStartTime = DateTime.now();
        final spPlaylistId = SpotifyPlaylistId(spPlaylist.id!);
        final spPlaylistName = spPlaylist.name!;
        final spSnapshotId = spPlaylist.snapshotId ?? '';
        final playlistTrackEntries = <SyncTrackEntry>[];

        void logPlaylist(String message) {
          log.info('[${green(spPlaylistName)}] $message');
        }

        logPlaylist('Syncing playlist (snapshot: $spSnapshotId)');

        // Check if we have a cached version with matching snapshot ID
        final List<SyncedTrack> trackList;
        final bool wasFromCache;
        if (playlistFetchFutures.containsKey(spPlaylistId)) {
          wasFromCache = false;
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
              return (
                id: SpotifyTrackId(track.id!),
                name: track.name!,
                artistNames: track.artists!.map((a) => a.name!).toList(),
                addedAt: e.addedAt,
              );
            },
          ).toList();

          // Update cache with this playlist
          await syncDb.syncPlaylistsDao.cachePlaylist(
            playlistId: spPlaylistId,
            snapshotId: spSnapshotId,
            tracks: trackList,
            name: spPlaylistName,
          );
        } else {
          wasFromCache = true;
          // Use cached data
          final cachedTracks = await syncDb.syncPlaylistsDao.getPlaylistTracks(
            spPlaylistId,
          );
          logPlaylist(
            '💾 Using cached playlist data '
            '(${cachedTracks.length} tracks)',
          );
          trackList = cachedTracks.map<SyncedTrack>(
            (t) {
              final artistNames = (jsonDecode(t.artistNames) as List)
                  .cast<String>();
              return (
                id: SpotifyTrackId(t.trackId),
                name: t.name,
                artistNames: artistNames,
                addedAt: null,
              );
            },
          ).toList();
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
          rbTargetFolder = (await rbPlaylistFolders(rbDb)).firstWhereOrNull(
            (e) => e.name == targetFolderName,
          );

          if (rbTargetFolder == null) {
            logPlaylist('Creating playlist folder "$targetFolderName"');
            rbTargetFolder = await rbDb.createPlaylistFolder(
              name: targetFolderName,
            );
          }
        }

        var rbPlaylist = (await rbRealPlaylists(rbDb)).firstWhereOrNull(
          (e) => e.name == spPlaylistName,
        );
        if (rbPlaylist != null) {
          logPlaylist('Deleting existing playlist "$spPlaylistName"');
          await rbDb.deletePlaylist(rbPlaylist.id!);
        }

        rbPlaylist = await rbDb.createPlaylist(
          name: spPlaylistName,
          parentId: rbTargetFolder?.id,
        );

        // Build initial tracklist from Spotify
        final rbPlaylistSongQueue = <_TracklistEntry>[];

        // Batch collect mappings, invalid mappings to remove,
        // and missing tracks
        final newMappings = <SpotifyTrackId, String>{};
        final invalidMappingIds = <SpotifyTrackId>[];

        for (var i = 0; i < trackList.length; i++) {
          final cachedTrack = trackList[i];

          void logTrack(String message, {bool? first}) {
            const intermediateChar = '├';
            const finalChar = '└';
            logPlaylist(
              [
                '<${cyan(cachedTrack.id)}>',
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

          // Check if we have a cached mapping for this track
          final cachedMappingId = await syncDb.syncMappingsDao.getMapping(
            cachedTrack.id,
          );
          final cachedMapping = cachedMappingId != null
              ? RekordboxSongId(cachedMappingId)
              : null;

          var rbSong = await _findTrack(
            spTrackId: cachedTrack.id,
            spTrackName: cachedTrack.name,
            spArtistNames: cachedTrack.artistNames,
            rbSongsAndArtists: rbAllSongsAndArtists,
            cachedMapping: cachedMapping,
          );

          if (rbSong != null) {
            final rbSongId = RekordboxSongId(rbSong.id!);
            foundTrackIds.add(cachedTrack.id);

            logTrack('Found match in Rekordbox: ${rbSong.title}');

            // Batch collect mapping for bulk insert later
            newMappings[cachedTrack.id] = rbSongId.toString();

            if (rbKey != null) {
              logTrack('Updating song key to ${rbKey.scaleName}');
              rbSong = await rbDb.updateSong(rbSongId, keyId: rbKey.id);
            }

            logTrack('Added to playlist queue', first: false);
            rbPlaylistSongQueue.add(
              _TracklistEntry(
                originalIndex: i + 1,
                trackId: rbSongId,
                isCustom: false,
              ),
            );

            // Track for report
            playlistTrackEntries.add(
              SyncTrackAdded(
                trackId: cachedTrack.id,
                trackName: cachedTrack.name,
                artistNames: cachedTrack.artistNames,
                rekordboxSongId: rbSongId,
                rekordboxTitle: rbSong.title ?? '',
              ),
            );
          } else {
            logTrack('No match found, adding to missing tracks', first: false);

            // Remove invalid cached mapping if we had one
            // (e.g. Rekordbox track was deleted) so we re-search on next sync
            // instead of retrying stale ID
            if (cachedMappingId != null) {
              invalidMappingIds.add(cachedTrack.id);
            }

            // Aggregate missing tracks globally and keep only the newest
            // playlist-added date for each Spotify track.
            if (cachedTrack.addedAt case final addedAt?) {
              final key = cachedTrack.id.toString();
              final existing = missingTracksById[key];
              if (existing == null || addedAt.isAfter(existing.addedAt)) {
                missingTracksById[key] = (
                  id: cachedTrack.id,
                  artist: cachedTrack.artistNames.join(', '),
                  title: cachedTrack.name,
                  addedAt: addedAt,
                );
              }
            }

            // Track for report
            playlistTrackEntries.add(
              SyncTrackMissing(
                trackId: cachedTrack.id,
                trackName: cachedTrack.name,
                artistNames: cachedTrack.artistNames,
              ),
            );
          }
        }

        // Remove invalid mappings (stale Rekordbox IDs for deleted tracks)
        if (invalidMappingIds.isNotEmpty) {
          logPlaylist(
            'Removing ${invalidMappingIds.length} invalid mapping(s)...',
          );
          await syncDb.syncMappingsDao.deleteMappings(invalidMappingIds);
        }

        // Bulk insert mappings for this playlist.
        if (newMappings.isNotEmpty) {
          logPlaylist('Saving ${newMappings.length} track mapping(s)...');
          await syncDb.syncMappingsDao.setMappingsBatch(newMappings);
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

          // Track custom tracks for report
          for (final entry in updatedTracklist.where((e) => e.isCustom)) {
            final rbSongData = rbAllSongsAndArtists.firstWhereOrNull(
              (s) => s.song.id == entry.trackId.value,
            );
            if (rbSongData != null) {
              playlistTrackEntries.add(
                SyncTrackCustom(
                  trackId: SpotifyTrackId('custom-${entry.trackId}'),
                  trackName: rbSongData.song.title ?? '',
                  artistNames: [rbSongData.artist?.name ?? 'Unknown'],
                  rekordboxSongId: entry.trackId,
                  rekordboxTitle: rbSongData.song.title ?? '',
                  position: entry.originalIndex ?? 0,
                ),
              );
            }
          }
        }

        // Add all tracks to playlist
        logPlaylist(
          'Adding ${rbPlaylistSongQueue.length} track(s) to playlist...',
        );
        for (final entry in rbPlaylistSongQueue) {
          await rbDb.addSongToPlaylist(
            playlistId: rbPlaylist.id!,
            contentId: entry.trackId,
          );
        }

        // Add playlist report
        final playlistEndTime = DateTime.now();
        playlistReports.add(
          SyncPlaylistReport(
            playlistId: spPlaylistId,
            playlistName: spPlaylistName,
            snapshotId: spSnapshotId,
            startTime: playlistStartTime,
            endTime: playlistEndTime,
            tracks: playlistTrackEntries,
            wasFromCache: wasFromCache,
          ),
        );
      }

      if (missingTracksById.isNotEmpty) {
        log.info(
          'Saving ${missingTracksById.length} missing track(s) '
          'with latest playlist-added dates...',
        );
        await syncDb.syncMissingTracksDao.insertMissingTracksBatch(
          missingTracksById.values.toList(),
        );
      }
      if (foundTrackIds.isNotEmpty) {
        log.info(
          'Removing ${foundTrackIds.length} found track(s) '
          'from missing list...',
        );
        await syncDb.syncMissingTracksDao.deleteMissingTracks(foundTrackIds);
      }

      // Generate sync report
      final commandEndTime = DateTime.now();
      final syncReport = SyncReport(
        startTime: commandStartTime,
        endTime: commandEndTime,
        playlistReports: playlistReports,
      );

      final reportFile = await SyncReportGenerator().generate(syncReport);
      log.info('Sync report saved to: ${green(reportFile.path)}');

      return ExitCode.success.code;
    });
  }

  static Future<List<PlaylistSimple>> _getPlaylistsFromArgs(
    SpotifyApi spotifyApi,
    List<String> args,
  ) async {
    final playlistIds = args
        .map((e) => e.trim())
        .map(
          (e) =>
              SpotifyPlaylistId.tryExtract(e) ??
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
    final allPlaylists = await spotifyApi.me.playlists.saved().all(50);

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
    required List<RbArtistAndSong> rbSongsAndArtists,
    required RekordboxSongId? cachedMapping,
    int threshold = 80,
  }) async {
    // Check cached mapping first
    if (cachedMapping case final rbSongId?) {
      if (rbSongsAndArtists.firstWhereOrNull((e) => e.song.id == rbSongId)
          case RbArtistAndSong(song: final rbSong)?) {
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

    final RbArtistAndSong(:artist, :song) = fuzzyMatch.value;

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

  static Future<FuzzyFindMatch<RbArtistAndSong>> _findFuzzyMatch({
    required String spTrackName,
    required List<String> spArtistNames,
    required List<RbArtistAndSong> rbSongsAndArtists,
    int threads = 4,
  }) async {
    if (rbSongsAndArtists.isEmpty) {
      throw Exception('No Rekordbox songs and artists to find match for');
    }

    FuzzyFindMatch<RbArtistAndSong> findFuzzyMatchForChunk(
      List<RbArtistAndSong> rbSongsAndArtists,
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

    return maxBy<FuzzyFindMatch<RbArtistAndSong>, int>(
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
  required List<RbArtistAndSong> rbAllSongsAndArtists,
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
      rbAllSongsAndArtists: rbAllSongsAndArtists,
      logPlaylist: logPlaylist,
    );
  }

  // Process replacements
  if (replacesToProcess.isNotEmpty) {
    workingTracklist = _processReplacements(
      replacements: replacesToProcess,
      tracklist: workingTracklist,
      rbAllSongsAndArtists: rbAllSongsAndArtists,
      logPlaylist: logPlaylist,
    );
  }

  return workingTracklist;
}

/// Helper function to format track name from Rekordbox song data.
String _formatTrackName(RbArtistAndSong? rbSong) {
  if (rbSong == null) return 'Unknown';
  final artist = rbSong.artist?.name ?? 'Unknown Artist';
  final title = rbSong.song.title ?? 'Unknown Title';
  return '$artist - $title';
}

/// Processes insert-type custom tracks.
List<_TracklistEntry> _processInserts({
  required List<CustomTrack> inserts,
  required List<_TracklistEntry> tracklist,
  required List<RbArtistAndSong> rbAllSongsAndArtists,
  required void Function(String) logPlaylist,
}) {
  final result = List<_TracklistEntry>.from(tracklist);

  // Group inserts by their target index, storing offset info for relative
  // positioning
  final insertsByIndex =
      <
        int?,
        List<({CustomTrack insert, int? offset, RekordboxSongId? targetId})>
      >{};

  for (final insert in inserts) {
    int? targetIndex;
    int? offset;
    RekordboxSongId? targetId;

    if (insert.target != null) {
      targetId = insert.target;
      // Find the target track and calculate index
      offset =
          insert.index ?? (insert.position != null ? insert.position! - 1 : 0);

      for (var i = 0; i < result.length; i++) {
        if (result[i].trackId.value == insert.target) {
          targetIndex = (result[i].originalIndex ?? 0) + offset;
          break;
        }
      }

      if (targetIndex == null) {
        final customTrackName = _formatTrackName(
          rbAllSongsAndArtists.firstWhereOrNull(
            (e) => e.song.id == insert.rekordboxId,
          ),
        );
        logPlaylist(
          '  ⚠️  WARNING: Custom track '
          '"$customTrackName" [${insert.rekordboxId}] '
          'references missing target track ID ${insert.target}. Skipping.',
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
      final customTrackName = _formatTrackName(
        rbAllSongsAndArtists.firstWhereOrNull(
          (e) => e.song.id == insert.rekordboxId,
        ),
      );
      logPlaylist(
        '  ⚠️  WARNING: Custom track '
        '"$customTrackName" [${insert.rekordboxId}] '
        'specifies out-of-bounds index $targetIndex. Appending to end.',
      );
      targetIndex = null;
    }

    insertsByIndex.putIfAbsent(targetIndex, () => []).add((
      insert: insert,
      offset: offset,
      targetId: targetId,
    ));
  }

  // Insert tracks at the end (null index) first
  final tracksToAppend = insertsByIndex.remove(null) ?? [];
  for (final entry in tracksToAppend) {
    final customTrackName = _formatTrackName(
      rbAllSongsAndArtists.firstWhereOrNull(
        (e) => e.song.id == entry.insert.rekordboxId,
      ),
    );
    logPlaylist(
      '  ├ Appending custom track '
      '"$customTrackName" [${entry.insert.rekordboxId}] '
      'to end of playlist',
    );
    result.add(
      _TracklistEntry(
        originalIndex: null,
        trackId: entry.insert.rekordboxId,
        isCustom: true,
      ),
    );
  }

  // Sort indices in descending order to insert from end to start
  final sortedIndices = insertsByIndex.keys.toList()
    ..sort((a, b) => b!.compareTo(a!));

  for (final targetIndex in sortedIndices) {
    final insertsToProcess = insertsByIndex[targetIndex]!;

    // Find insertion position in the working list
    var insertionPos = 0;
    _TracklistEntry? targetEntry;
    for (var i = 0; i < result.length; i++) {
      if (result[i].originalIndex != null &&
          result[i].originalIndex! > targetIndex!) {
        insertionPos = i;
        break;
      }
      insertionPos = i + 1;
      // Find the target entry if we're inserting relative to a track
      if (result[i].originalIndex == targetIndex! + 1) {
        targetEntry = result[i];
      }
    }

    // Find target track info for relative positioning
    String? targetTrackName;
    int? relativeOffset;
    for (final entry in insertsToProcess) {
      if (entry.targetId != null) {
        final targetRbSong = rbAllSongsAndArtists.firstWhereOrNull(
          (e) => e.song.id == entry.targetId,
        );
        if (targetRbSong != null) {
          targetTrackName = _formatTrackName(targetRbSong);
          relativeOffset = entry.offset;
          break;
        }
      }
    }

    // Build log message with track names
    final trackNames = insertsToProcess
        .map((entry) {
          final customTrackName = _formatTrackName(
            rbAllSongsAndArtists.firstWhereOrNull(
              (e) => e.song.id == entry.insert.rekordboxId,
            ),
          );
          return '"$customTrackName" [${entry.insert.rekordboxId}]';
        })
        .join(', ');

    String logMessage;
    if (targetTrackName != null && relativeOffset != null) {
      // Format relative position string
      // offset 0 = 1 position after, offset 1 = 2 positions after, etc.
      // offset -1 = 1 position before, offset -2 = 2 positions before, etc.
      String positionStr;
      if (relativeOffset == 0) {
        positionStr = '1 position after';
      } else if (relativeOffset > 0) {
        final positionsAfter = relativeOffset + 1;
        positionStr = positionsAfter == 1
            ? '1 position after'
            : '$positionsAfter positions after';
      } else {
        final absOffset = relativeOffset.abs();
        positionStr = absOffset == 1
            ? '1 position before'
            : '$absOffset positions before';
      }
      logMessage =
          '  ├ Inserting ${insertsToProcess.length} custom track(s) '
          '($trackNames) $positionStr "$targetTrackName"';
    } else if (targetEntry != null) {
      final entryTrackName = _formatTrackName(
        rbAllSongsAndArtists.firstWhereOrNull(
          (e) => e.song.id == targetEntry!.trackId.value,
        ),
      );
      logMessage =
          '  ├ Inserting ${insertsToProcess.length} custom track(s) '
          '($trackNames) at index $targetIndex (relative to "$entryTrackName")';
    } else {
      logMessage =
          '  ├ Inserting ${insertsToProcess.length} custom track(s) '
          '($trackNames) at index $targetIndex';
    }
    logPlaylist(logMessage);

    // Insert tracks in order, incrementing position to maintain sequence
    for (final entry in insertsToProcess) {
      result.insert(
        insertionPos,
        _TracklistEntry(
          originalIndex: targetIndex,
          trackId: entry.insert.rekordboxId,
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
  required List<RbArtistAndSong> rbAllSongsAndArtists,
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
          final targetTrackName = _formatTrackName(
            rbAllSongsAndArtists.firstWhereOrNull(
              (e) => e.song.id == result[i].trackId.value,
            ),
          );
          final customTrackName = _formatTrackName(
            rbAllSongsAndArtists.firstWhereOrNull(
              (e) => e.song.id == replacement.rekordboxId,
            ),
          );
          logPlaylist(
            '  ├ Replacing "$targetTrackName" [${result[i].trackId.value}] '
            'with custom track "$customTrackName" [${replacement.rekordboxId}]',
          );
          result[i] = _TracklistEntry(
            originalIndex: result[i].originalIndex,
            trackId: replacement.rekordboxId,
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
            final targetTrackName = _formatTrackName(
              rbAllSongsAndArtists.firstWhereOrNull(
                (e) => e.song.id == result[i].trackId.value,
              ),
            );
            final customTrackName = _formatTrackName(
              rbAllSongsAndArtists.firstWhereOrNull(
                (e) => e.song.id == replacement.rekordboxId,
              ),
            );
            logPlaylist(
              '  ├ Replacing "$targetTrackName" [${result[i].trackId.value}] '
              'at index $targetIndex with custom track '
              '"$customTrackName" [${replacement.rekordboxId}]',
            );
            result[i] = _TracklistEntry(
              originalIndex: targetIndex,
              trackId: replacement.rekordboxId,
              isCustom: true,
            );
            replaced = true;
            break;
          }
        }
      }
    }

    if (!replaced) {
      final customTrackName = _formatTrackName(
        rbAllSongsAndArtists.firstWhereOrNull(
          (e) => e.song.id == replacement.rekordboxId,
        ),
      );
      if (replacement.target != null) {
        logPlaylist(
          '  ⚠️  WARNING: Could not replace track with target ID '
          '${replacement.target} (not found). Custom track '
          '"$customTrackName" [${replacement.rekordboxId}] not inserted.',
        );
      } else {
        final targetIndex = replacement.position != null
            ? replacement.position! - 1
            : replacement.index;
        logPlaylist(
          '  ⚠️  WARNING: Could not replace track at index $targetIndex '
          '(not found). Custom track "$customTrackName" '
          '[${replacement.rekordboxId}] not inserted.',
        );
      }
    }
  }

  return result;
}
