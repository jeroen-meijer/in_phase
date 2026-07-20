import 'dart:convert';
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

  final reviewDir = findMissingTracksReviewDir();
  await reviewDir.create(recursive: true);

  stderr
    ..writeln(
      'Loading missing tracks from ${Constants.cacheDbFile.path}...',
    )
    ..writeln('Playlist scope: ${scope.describe()}');
  final cacheDb = AppDatabase.fromCacheDbFile();
  final missingTracks = await loadMissingTracks(
    db: cacheDb,
    scope: scope,
  );
  await cacheDb.close();

  if (missingTracks.isEmpty) {
    stdout.writeln('No missing tracks found for this scope.');
    return;
  }

  stderr.writeln('Loading Rekordbox library...');
  final rbTracks = await loadRekordboxTracks();
  stderr.writeln('Investigating ${missingTracks.length} track(s)...');

  final candidates = <Map<String, Object?>>[];
  for (var i = 0; i < missingTracks.length; i++) {
    final track = missingTracks[i];
    stderr.writeln('[${i + 1}/${missingTracks.length}] ${track.title}');
    candidates.add(
      await investigateTrack(track: track, rbTracks: rbTracks),
    );
  }

  final nearMissCount = candidates.where((t) => t['near_miss'] == true).length;
  final payload = {
    'generated_at': DateTime.now().toIso8601String(),
    'sync_threshold': syncMatchThreshold,
    'near_miss_min': nearMissMinScore,
    'near_miss_max': nearMissMaxScore,
    'playlist_scope': scope.toJson(),
    'track_count': candidates.length,
    'near_miss_count': nearMissCount,
    'tracks': candidates,
  };

  await findMissingTracksCandidatesFile().writeAsString(
    const JsonEncoder.withIndent('  ').convert(payload),
  );

  await findMissingTracksReviewBriefFile().writeAsString(
    buildReviewBrief(tracks: candidates, scope: scope),
  );

  if (findMissingTracksProposedFile().existsSync()) {
    await findMissingTracksProposedFile().delete();
  }
  if (findMissingTracksApprovedFile().existsSync()) {
    await findMissingTracksApprovedFile().delete();
  }

  stdout
    ..writeln(findMissingTracksReviewDir().path)
    ..writeln('tracks=${candidates.length} near_misses=$nearMissCount');
}
