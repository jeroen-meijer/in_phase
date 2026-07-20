import 'dart:io';

import 'package:in_phase/src/database/database.dart';
import 'package:in_phase/src/misc/misc.dart';

import 'lib.dart';

Future<void> main(List<String> args) async {
  final parser = buildPlaylistScopeParser();
  final results = parser.parse(args);
  if (results.rest.isNotEmpty) {
    stderr
      ..writeln('Unexpected arguments: ${results.rest.join(' ')}')
      ..writeln(parser.usage);
    exitCode = 64;
    return;
  }

  late final PlaylistScope scope;
  try {
    scope = playlistScopeFromArgs(results);
  } catch (e) {
    if (e is! ArgumentError) rethrow;
    stderr.writeln(e.message);
    exitCode = 64;
    return;
  }

  final db = AppDatabase.fromCacheDbFile();
  try {
    final playlists = await loadPlaylistsWithMissing(db: db, scope: scope);

    if (playlists.isEmpty) {
      stdout.writeln('No missing tracks in synced playlists for this scope.');
      return;
    }

    var total = 0;
    for (final playlist in playlists) {
      total += playlist.missingCount;
      stdout.writeln(
        '${playlist.missingCount.toString().padLeft(4)}  ${playlist.name}',
      );
    }

    stdout
      ..writeln()
      ..writeln(
        '$total missing track rows across ${playlists.length} playlist(s)',
      )
      ..writeln()
      ..writeln('Cache: ${Constants.cacheDbFile.path}');
    if (scope.isUnfiltered) {
      stdout.writeln('Scope: all missing tracks (no playlist filter).');
    } else {
      stdout.writeln('Scope: ${scope.describe()}');
    }
    stdout
      ..writeln()
      ..writeln('Prepare with one or more --playlist-regex flags (OR):')
      ..writeln(
        '  dart run tool/ai/find_missing_tracks/prepare.dart '
        '--playlist-regex ".*DJ.*"',
      );
  } finally {
    await db.close();
  }
}
