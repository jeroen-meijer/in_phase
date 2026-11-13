import 'dart:io';

import 'package:in_phase/src/cli/cli.dart';
import 'package:rekorddart/rekorddart.dart';

/// Prints song count + aggregate playtime (HH:MM) for a Rekordbox playlist.
///
/// Usage:
///   dart run tool/playlist_length.dart "playlist name"
///   dart run tool/playlist_length.dart "playlist name" 13-36
Future<void> main(List<String> args) async {
  if (args.isEmpty || args.length > 2) {
    stderr.writeln(
      'Usage: dart run tool/playlist_length.dart '
      '"playlist name" [start-end]',
    );
    exitCode = 64;
    return;
  }

  final playlistName = args[0];
  final range = args.length == 2 ? _parseRange(args[1]) : null;
  if (args.length == 2 && range == null) {
    stderr.writeln('Invalid range "${args[1]}". Expected e.g. 13-36.');
    exitCode = 64;
    return;
  }

  await runWithCliDependencies(() async {
    final db = await RekordboxDatabase.connect(
      allowConnectionWhenRunning: true,
    );
    try {
      final playlists =
          await (db.select(db.djmdPlaylist)..where(
                (p) =>
                    p.name.equals(playlistName) &
                    p.rbLocalDeleted.equals(0) &
                    p.attribute.isNotValue(1),
              ))
              .get();

      if (playlists.isEmpty) {
        stderr.writeln('No Rekordbox playlist named "$playlistName".');
        exitCode = 1;
        return;
      }
      if (playlists.length > 1) {
        stderr.writeln(
          'Ambiguous: ${playlists.length} playlists named "$playlistName".',
        );
        exitCode = 1;
        return;
      }

      final playlist = playlists.single;
      final playlistId = playlist.id!;

      final songs =
          await (db.select(db.djmdSongPlaylist)
                ..where(
                  (s) =>
                      s.playlistID.equals(playlistId) &
                      s.rbLocalDeleted.equals(0),
                )
                ..orderBy([(s) => OrderingTerm.asc(s.trackNo)]))
              .get();

      final contentIds = [
        for (final song in songs)
          if (song.contentID != null) song.contentID!,
      ];

      final sliced = _sliceInclusive(contentIds, range);
      if (sliced.isEmpty) {
        stdout.writeln(
          range == null
              ? '"$playlistName": 0 songs, 00:00'
              : '"$playlistName" tracks ${range.$1}-${range.$2}: '
                    '0 songs (playlist has ${contentIds.length}), 00:00',
        );
        return;
      }

      final lengths = <String, int?>{};
      for (final chunk in _chunks(sliced.toSet().toList(), 400)) {
        final rows = await (db.select(
          db.djmdContent,
        )..where((c) => c.id.isIn(chunk))).get();
        for (final row in rows) {
          if (row.id != null) lengths[row.id!] = row.length;
        }
      }

      var totalSeconds = 0;
      var missing = 0;
      for (final id in sliced) {
        final length = lengths[id];
        if (length == null) {
          missing++;
          continue;
        }
        totalSeconds += length;
      }

      final label = range == null
          ? '"$playlistName"'
          : '"$playlistName" tracks ${range.$1}-${range.$2}';
      stdout.writeln(
        '$label: ${sliced.length} songs, ${_formatHhMm(totalSeconds)}',
      );
      if (missing > 0) {
        stderr.writeln('warning: $missing track(s) missing Length');
      }
    } finally {
      await db.close();
    }
  });
}

(int, int)? _parseRange(String raw) {
  final match = RegExp(r'^(\d+)-(\d+)$').firstMatch(raw.trim());
  if (match == null) return null;
  final start = int.parse(match.group(1)!);
  final end = int.parse(match.group(2)!);
  if (start < 1 || end < start) return null;
  return (start, end);
}

List<String> _sliceInclusive(List<String> ids, (int, int)? range) {
  if (range == null) return ids;
  final (start, end) = range;
  if (start > ids.length) return const [];
  final endClamped = end > ids.length ? ids.length : end;
  return ids.sublist(start - 1, endClamped);
}

String _formatHhMm(int totalSeconds) {
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}';
}

Iterable<List<T>> _chunks<T>(List<T> items, int size) sync* {
  for (var i = 0; i < items.length; i += size) {
    final end = i + size > items.length ? items.length : i + size;
    yield items.sublist(i, end);
  }
}
