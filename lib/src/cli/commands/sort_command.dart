import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:collection/collection.dart';
import 'package:dcli/dcli.dart';
import 'package:in_phase/src/cli/commands/sort/sort_relative_moves.dart';
import 'package:in_phase/src/database/database.exports.dart';
import 'package:in_phase/src/logger/logger.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:in_phase/src/spotify/spotify.dart';
import 'package:io/io.dart';
import 'package:rekorddart/rekorddart.dart';

const _unknownKeySortOrder = 999;

class SortCommand extends Command<int> {
  SortCommand() {
    argParser
      ..addFlag(
        'dry-run',
        help: 'Preview the sorted order without updating the playlist.',
        negatable: false,
      )
      ..addFlag(
        'yes',
        abbr: 'y',
        help: 'Apply the sort without confirmation.',
        negatable: false,
      );
  }

  @override
  final String name = 'sort';

  @override
  final String description =
      'Sort a Spotify playlist by Rekordbox Camelot keys (1A, 1B, 2A, …). '
      'Playlist: ID, URI, share URL, or name.';

  @override
  Future<int> run() async {
    final playlistInput = _parsePlaylistInput();
    final isDryRun = argResults!['dry-run'] as bool;
    final skipConfirm = argResults!['yes'] as bool;

    return withTeardown((addTeardown) async {
      final api = await spotifyLogin();
      // ignore: invalid_use_of_visible_for_testing_member
      addTeardown(() async => (await api.client).close());

      final requestPool = Zonable.fromZone<RequestPool>();
      addTeardown(requestPool.clear);

      final rbDb = await RekordboxDatabase.connect(
        allowConnectionWhenRunning: true,
      );
      addTeardown(rbDb.close);

      final syncDb = db();

      log.debug('Fetching user playlists...');
      final userPlaylists = await requestPool.fetchAllPages(
        api.me.playlists.saved(),
        limit: 50,
        pageIdentifier: SpotifyCacheIdentifier.savedPlaylistsPage,
      );

      final resolvedTarget = await resolvePlaylistTarget(
        api: api,
        input: playlistInput,
        userPlaylists: userPlaylists,
      );
      final targetPlaylist = switch (resolvedTarget) {
        PlaylistSpotifyTarget(:final playlist) => playlist,
        _ => null,
      };
      if (targetPlaylist == null) {
        usageException('Could not resolve playlist: $playlistInput');
      }

      final playlistId = SpotifyPlaylistId(targetPlaylist.id!);
      final playlistName = targetPlaylist.name ?? playlistInput;

      log.debug('Fetching tracks from "$playlistName"...');
      final playlistTracks = await requestPool.fetchAllPages(
        api.playlists.getPlaylistTracks(playlistId),
        limit: 100,
        pageIdentifier: (offset) =>
            SpotifyCacheIdentifier.playlistTracksPage(playlistId, offset),
      );

      final tracks = playlistTracks
          .where((entry) => entry.track?.id != null && entry.track!.uri != null)
          .toList();

      if (tracks.isEmpty) {
        log.info('Playlist is empty, nothing to sort.');
        return ExitCode.success.code;
      }

      final mappings = await syncDb.syncMappingsDao.getAllMappings();
      final rbSongKeys = await _loadRekordboxSongKeys(rbDb);

      final entries = <_SortEntry>[];
      var unmappedCount = 0;
      var noKeyCount = 0;

      for (final (index, playlistTrack) in tracks.indexed) {
        final track = playlistTrack.track!;
        final trackId = SpotifyTrackId(track.id!);
        final artistNames =
            track.artists?.map((a) => a.name ?? '').toList() ??
            const <String>[];

        final mappedSongId = mappings[trackId];
        final keyName = mappedSongId != null ? rbSongKeys[mappedSongId] : null;

        if (mappedSongId == null) {
          unmappedCount++;
        } else if (keyName == null) {
          noKeyCount++;
        }

        final camelotName = mapKeyToCamelot(keyName);
        final camelotKey = camelotName != null
            ? CamelotKey.fromString(camelotName)
            : null;
        entries.add(
          _SortEntry(
            uri: track.uri!,
            trackName: track.name ?? 'Unknown',
            artistNames: artistNames,
            camelotKey: camelotKey?.title,
            sortOrder:
                mapKeyToCamelotPlaylistOrder(keyName) ?? _unknownKeySortOrder,
            originalIndex: index,
          ),
        );
      }

      final sortedEntries = entries.sorted((a, b) {
        final orderCompare = a.sortOrder.compareTo(b.sortOrder);
        if (orderCompare != 0) return orderCompare;
        return a.originalIndex.compareTo(b.originalIndex);
      });

      final alreadySorted = const ListEquality<String>().equals(
        entries.map((e) => e.uri).toList(),
        sortedEntries.map((e) => e.uri).toList(),
      );

      _logSortedPreview(
        playlistName: playlistName,
        sortedEntries: sortedEntries,
        unmappedCount: unmappedCount,
        noKeyCount: noKeyCount,
        alreadySorted: alreadySorted,
      );

      if (alreadySorted) {
        log.info('Already sorted by Camelot key (1A → 1B → … → 12B).');
        return ExitCode.success.code;
      }

      if (isDryRun) {
        log.info('Dry run: playlist was not updated.');
        return ExitCode.success.code;
      }

      if (!skipConfirm && !_confirmReorder()) {
        log.info('Cancelled.');
        return ExitCode.success.code;
      }

      log.debug('Updating playlist order...');
      await api.playlists.clear(playlistId);
      final uris = sortedEntries.map((e) => e.uri).toList();
      for (var i = 0; i < uris.length; i += 100) {
        final batch = uris.skip(i).take(100).toList();
        await api.playlists.addTracks(batch, playlistId);
      }

      log.info('Done. ${green(playlistName)} sorted by Camelot key.');
      if (targetPlaylist.externalUrls?.spotify case final url?) {
        log.info(url);
      }

      return ExitCode.success.code;
    });
  }

  String _parsePlaylistInput() {
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
    return arg;
  }
}

class _SortEntry {
  const _SortEntry({
    required this.uri,
    required this.trackName,
    required this.artistNames,
    required this.camelotKey,
    required this.sortOrder,
    required this.originalIndex,
  });

  final String uri;
  final String trackName;
  final List<String> artistNames;
  final String? camelotKey;
  final int sortOrder;
  final int originalIndex;
}

Future<Map<String, String?>> _loadRekordboxSongKeys(
  RekordboxDatabase rbDb,
) async {
  final keyById = {
    for (final key in await rbDb.select(rbDb.djmdKey).get())
      if (key.id != null && key.scaleName != null) key.id!: key.scaleName!,
  };

  final contents = await (rbDb.select(
    rbDb.djmdContent,
  )..where((c) => c.rbLocalDeleted.equals(0))).get();

  return {
    for (final content in contents)
      if (content.id != null)
        content.id!: content.keyID != null ? keyById[content.keyID] : null,
  };
}

void _logSortedPreview({
  required String playlistName,
  required List<_SortEntry> sortedEntries,
  required int unmappedCount,
  required int noKeyCount,
  required bool alreadySorted,
}) {
  final trackCount = sortedEntries.length;
  final mappedCount = trackCount - unmappedCount;
  final status = alreadySorted ? 'already sorted' : 'sorted preview';

  final stablePositions = relativeStablePositions(
    sortedEntries.map((e) => e.originalIndex).toList(),
  );
  final relativeMoveCount = trackCount - stablePositions.length;

  log
    ..info('${green(playlistName)} — $trackCount tracks ($status)')
    ..info('');

  final posWidth = trackCount.toString().length;
  for (final (newIndex, entry) in sortedEntries.indexed) {
    final moved = !stablePositions.contains(newIndex);
    log.info(
      _formatSortTrackLine(
        position: newIndex + 1,
        entry: entry,
        posWidth: posWidth,
        moved: moved,
      ),
    );
  }

  log
    ..info('')
    ..info(
      'Coverage: $mappedCount/$trackCount mapped · '
      '$unmappedCount unmapped (sort last, run sync) · '
      '$noKeyCount missing key',
    )
    ..info('Within each key, original playlist order is preserved.');

  if (alreadySorted) {
    return;
  }

  log
    ..info('')
    ..info(
      '$relativeMoveCount relative move(s) highlighted '
      '(↑/↓); grey tracks kept relative order.',
    )
    ..info(
      'Will clear playlist and re-add $trackCount tracks in the order above.',
    );
}

String _formatSortTrackLine({
  required int position,
  required _SortEntry entry,
  required int posWidth,
  required bool moved,
}) {
  final pos = position.toString().padLeft(posWidth);
  final keyRaw = (entry.camelotKey ?? '?').padRight(3);
  final artists = entry.artistNames.where((a) => a.isNotEmpty).join(', ');
  final artistPart = artists.isEmpty ? 'Unknown Artist' : artists;
  final titlePart = '$artistPart — ${entry.trackName}';
  // Same width for arrow / blank so moved and stable lines stay aligned.
  final marker = moved
      ? (position - 1 < entry.originalIndex ? '↑' : '↓')
      : ' ';

  if (!moved) {
    return grey('  $pos. $marker  $keyRaw  $titlePart');
  }

  final keyDisplay = entry.camelotKey != null
      ? magenta(keyRaw)
      : yellow(keyRaw);
  return '  $pos. $marker  $keyDisplay  $titlePart';
}

bool _confirmReorder() {
  if (!stdin.hasTerminal) {
    log.warning(
      'Not a TTY; use --yes to apply without confirmation.',
    );
    return false;
  }

  final answer = ask(
    'Press Y to reorder, anything else to cancel: ',
  ).trim();
  return answer == 'Y' || answer == 'y';
}
