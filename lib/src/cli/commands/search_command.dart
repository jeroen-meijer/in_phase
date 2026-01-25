import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:collection/collection.dart';
import 'package:dcli/dcli.dart';
import 'package:in_phase/src/logger/logger.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:io/io.dart';
import 'package:rekorddart/rekorddart.dart';

class SearchCommand extends Command<int> {
  SearchCommand() {
    argParser.addOption(
      'limit',
      abbr: 'l',
      help: 'Maximum number of results to show.',
      defaultsTo: '20',
      valueHelp: 'number',
    );
  }

  /// Formats milliseconds to MM:SS format.
  static String _formatTime({
    int seconds = 0,
    int milliseconds = 0,
  }) {
    assert(
      seconds > 0 || milliseconds > 0,
      'Either seconds or milliseconds must be provided',
    );

    final totalMs = seconds * 1000 + milliseconds;
    final minutes = totalMs ~/ 60000;
    final remainingSeconds = (totalMs % 60000) ~/ 1000;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  final String name = 'search';

  @override
  final String description =
      'Searches Rekordbox library for tracks. If a numeric ID is provided, '
      'returns that track directly.';

  static const ({
    String Function(String text) hot,
    String Function(String text) memory,
  })
  _cueColors = (
    hot: green,
    memory: yellow,
  );

  @override
  Future<int> run() async {
    final initialQuery = argResults!.rest.join(' ').trim();
    final limit = int.tryParse(argResults!['limit'] as String) ?? 20;

    return withTeardown((addTeardown) async {
      final db = await RekordboxDatabase.connect(
        allowConnectionWhenRunning: true,
      );
      addTeardown(db.close);

      // Load all tracks once for efficiency
      log.info(blue('Loading tracks...'));
      final allTracks = await db
          .select(db.djmdContent)
          .join([
            leftOuterJoin(
              db.djmdArtist,
              db.djmdContent.artistID.equalsExp(db.djmdArtist.id),
            ),
          ])
          .map(
            (e) => (
              artist: e.readTableOrNull(db.djmdArtist),
              song: e.readTable(db.djmdContent),
            ),
          )
          .get();

      if (allTracks.isEmpty) {
        log.error('No tracks found in database.');
        return ExitCode.noInput.code;
      }

      log.info('${green('✓')} Loaded ${allTracks.length} track(s)\n');

      // If initial query provided, process it once and exit
      if (initialQuery.isNotEmpty) {
        await _processQuery(db, allTracks, initialQuery, limit);
        return ExitCode.success.code;
      }

      // Interactive loop
      while (true) {
        try {
          stdout.write('${cyan('Enter search query or rekordbox ID')}: ');
          final query = stdin.readLineSync()?.trim() ?? '';

          if (query.isEmpty) {
            continue;
          }

          // Check for exit commands
          if (query.toLowerCase() == 'exit' || query.toLowerCase() == 'quit') {
            log.info('\n${blue('Goodbye!')}');
            break;
          }

          await _processQuery(db, allTracks, query, limit);
          log.info(''); // Empty line between searches
        } on ProcessException catch (e) {
          // Handle Ctrl+C gracefully
          if (e.message.contains('SIGINT') || e.message.contains('interrupt')) {
            log.info('\n\n${blue('Goodbye!')}');
            break;
          }
          rethrow;
        } catch (e) {
          // Handle any other interruptions
          if (e.toString().contains('SIGINT') ||
              e.toString().contains('interrupt')) {
            log.info('\n\n${blue('Goodbye!')}');
            break;
          }
          log.error('Error: $e');
        }
      }

      return ExitCode.success.code;
    });
  }

  /// Processes a single search query.
  Future<void> _processQuery(
    RekordboxDatabase db,
    List<RbArtistAndSong> allTracks,
    String query,
    int limit,
  ) async {
    // Check if query looks like a rekordbox track ID (numeric)
    if (RegExp(r'^\d+$').hasMatch(query)) {
      final track = await db.getSongById(query);
      if (track == null) {
        log.error(red('Track with ID $query not found.'));
        return;
      }

      await _displayTrackDetails(db, track);
      return;
    }

    // Find matches
    final matches = await findFuzzyTrackMatches(
      query: query,
      tracks: allTracks,
      maxResults: limit,
    );

    if (matches.isEmpty) {
      log.info(yellow('No matches found.'));
      return;
    }

    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      final track = match.value.song;
      final artist = match.value.artist;
      final trackId = track.id!;

      final cues = await (db.select(
        db.djmdCue,
      )..where((c) => c.contentID.equals(trackId))).get();

      // Get key information if available
      DjmdKeyData? key;
      if (track.keyID case final keyID?) {
        key = await (db.select(
          db.djmdKey,
        )..where((k) => k.id.equals(keyID))).getSingleOrNull();
      }

      final artistName = artist?.name ?? 'Unknown Artist';
      final trackTitle = track.title ?? 'Unknown Title';

      // Format: [track_id] Artist - Title (X cues) [4A]
      final idStr = trackId.padLeft(12);
      final formattedCues = _formatCues(cues);
      final indexStr = (i + 1).toString().padLeft(2);

      final keyDisplay = key?.scaleName
          .let(mapKeyToCamelot)
          .let((camelotKey) => ' ${magenta('[$camelotKey]')}')
          .or('');

      log.info(
        '${grey(indexStr)}. [ ${blue(idStr)} ] $artistName - '
        '$trackTitle ($formattedCues)$keyDisplay',
      );
    }
  }

  /// Displays detailed information for a single track.
  Future<void> _displayTrackDetails(
    RekordboxDatabase db,
    DjmdContentData track,
  ) async {
    final trackId = track.id!;

    // Get artist info
    DjmdArtistData? artist;
    if (track.artistID case final artistID?) {
      artist = await (db.select(
        db.djmdArtist,
      )..where((a) => a.id.equals(artistID))).getSingleOrNull();
    }

    // Get album info if available
    DjmdAlbumData? album;
    if (track.albumID case final albumID?) {
      album = await (db.select(
        db.djmdAlbum,
      )..where((a) => a.id.equals(albumID))).getSingleOrNull();
    }

    // Get genre info if available
    DjmdGenreData? genre;
    if (track.genreID case final genreID?) {
      genre = await (db.select(
        db.djmdGenre,
      )..where((g) => g.id.equals(genreID))).getSingleOrNull();
    }

    // Get key info if available
    DjmdKeyData? key;
    if (track.keyID case final keyID?) {
      key = await (db.select(
        db.djmdKey,
      )..where((k) => k.id.equals(keyID))).getSingleOrNull();
    }

    // Get cue counts and details
    final allCues =
        await (db.select(db.djmdCue)
              ..where((c) => c.contentID.equals(trackId))
              ..orderBy([(c) => OrderingTerm.asc(c.inMsec)]))
            .get();
    final memoryCues = allCues
        .where((c) => CueKind.fromKind(c.kind)?.isMemoryCue ?? false)
        .toList();
    final hotCues = allCues
        .where((c) => CueKind.fromKind(c.kind)?.isHotCue ?? false)
        .toList();

    final artistName = artist?.name ?? 'Unknown Artist';
    final trackTitle = track.title ?? 'Unknown Title';
    final albumName = album?.name;
    final genreName = genre?.name;
    final bpm = switch (track.bpm) {
      final bpm? => (bpm / 100).toStringAsFixed(2),
      _ => null,
    };
    final length = switch (track.length) {
      final lengthInSec? => _formatTime(seconds: lengthInSec),
      _ => null,
    };

    // Display structured overview
    log
      ..info('')
      ..info(
        cyan('═══════════════════════════════════════════════════════'),
      )
      ..info(cyan('Track Details'))
      ..info(
        cyan('═══════════════════════════════════════════════════════'),
      )
      ..info('');

    // Build key-value pairs for the table
    final rows = <List<String>>[
      ['ID', blue(trackId)],
      ['Title', trackTitle],
      ['Artist', artistName],
      if (albumName != null) ['Album', albumName],
      if (genreName != null) ['Genre', genreName],
      if (bpm != null) ['BPM', bpm],
      if (length != null) ['Length', length],
      if (key?.scaleName case final scaleName?)
        ['Key', mapKeyToCamelot(scaleName) ?? scaleName],
      [
        'Cues',
        if (allCues.isNotEmpty) _formatCues(allCues) else 'None',
      ],
    ];

    final maxHeaderLength = rows.map((row) => row.first.length).max;

    for (final row in rows) {
      final header = row.first;
      final value = row.last;
      log.info('${cyan(header.padRight(maxHeaderLength))}: $value');
    }

    // Show cue details if any exist
    if (allCues.isNotEmpty) {
      log
        ..info('')
        ..info(cyan('Cue Details:'));
      if (hotCues.isNotEmpty) {
        log.info('  Hot Cues: ${_cueColors.hot(hotCues.length.toString())}');
        for (final cue in hotCues) {
          final timeStr = switch (cue.inMsec) {
            final inMsec? => _formatTime(milliseconds: inMsec),
            _ => 'N/A',
          };
          final cueKind = CueKind.fromKind(cue.kind);
          final slotDisplay = cueKind?.letter ?? cueKind?.displayName ?? 'N/A';

          log.info('  ${grey(slotDisplay)}. $timeStr');
        }
      }
      if (memoryCues.isNotEmpty) {
        log.info(
          '  Memory Cues: ${_cueColors.memory(memoryCues.length.toString())}',
        );
        for (final (i, cue) in memoryCues.indexed) {
          final timeStr = switch (cue.inMsec) {
            final inMsec? => _formatTime(milliseconds: inMsec),
            _ => 'N/A',
          };

          log.info('  ${grey((i + 1).toString())}. $timeStr');
        }
      }
    }

    log
      ..info('')
      ..info(
        cyan('═══════════════════════════════════════════════════════'),
      )
      ..info('');
  }

  /// Formats the cues as such: "*hot_cues*/*memory_cues*"
  /// E.g. "2/1"
  ///
  /// - The hot cues number is grey if 0, otherwise green.
  /// - The memory cues number is grey if 0, otherwise yellow.
  String _formatCues(List<DjmdCueData> cues) {
    final hotCuesCount = cues
        .where((c) => CueKind.fromKind(c.kind)?.isHotCue ?? false)
        .length;
    final hotCuesNumber = hotCuesCount == 0
        ? grey(hotCuesCount.toString())
        : _cueColors.hot(hotCuesCount.toString());

    final memoryCuesCount = cues.where((c) => c.kind == 0).length;
    final memoryCuesNumber = memoryCuesCount == 0
        ? grey(memoryCuesCount.toString())
        : _cueColors.memory(memoryCuesCount.toString());

    return '$hotCuesNumber${grey('/')}$memoryCuesNumber';
  }
}
