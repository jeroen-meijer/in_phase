import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:in_phase/src/database/database.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:path/path.dart' as p;
import 'package:rekorddart/rekorddart.dart';

typedef RbArtistAndSong = ({DjmdArtistData? artist, DjmdContentData song});

Directory findIncorrectDuplicateTracksReviewDir() => Directory(
  p.join(Constants.appDataDir.path, 'build', 'find_incorrect_duplicate_tracks'),
);

File findIncorrectDuplicateTracksCandidatesFile() => File(
  p.join(findIncorrectDuplicateTracksReviewDir().path, 'candidates.json'),
);

File findIncorrectDuplicateTracksReviewBriefFile() => File(
  p.join(findIncorrectDuplicateTracksReviewDir().path, 'review_brief.md'),
);

File findIncorrectDuplicateTracksProposedFile() => File(
  p.join(findIncorrectDuplicateTracksReviewDir().path, 'proposed_fixes.json'),
);

File findIncorrectDuplicateTracksApprovedFile() => File(
  p.join(findIncorrectDuplicateTracksReviewDir().path, 'approved_fixes.json'),
);

ArgParser buildPrepareParser() {
  return ArgParser()
    ..addOption(
      'limit',
      abbr: 'l',
      help: 'Limit number of duplicate Rekordbox IDs to include (0 = all).',
      defaultsTo: '0',
      valueHelp: 'number',
    )
    ..addFlag(
      'include-clean',
      help:
          'Include groups that look “probably OK” (identical titles/artists).',
    );
}

ArgParser buildApplyParser() {
  return ArgParser()
    ..addFlag(
      'cleanup',
      abbr: 'c',
      help:
          'Remove review artifacts after applying (keeps approved_fixes.json).',
      negatable: false,
    )
    ..addFlag(
      'dry-run',
      help: 'Validate approved fixes without writing to cache.db.',
      negatable: false,
    );
}

Future<List<RbArtistAndSong>> loadRekordboxTracks() async {
  final db = await RekordboxDatabase.connect(
    allowConnectionWhenRunning: true,
  );
  try {
    return await db
        .select(db.djmdContent)
        .join([
          leftOuterJoin(
            db.djmdArtist,
            db.djmdContent.artistID.equalsExp(db.djmdArtist.id),
          ),
        ])
        .map(
          (row) => (
            artist: row.readTableOrNull(db.djmdArtist),
            song: row.readTable(db.djmdContent),
          ),
        )
        .get();
  } finally {
    await db.close();
  }
}

Future<Set<String>> loadRekordboxTrackIds() async {
  final db = await RekordboxDatabase.connect(
    allowConnectionWhenRunning: true,
  );
  try {
    final rows = await db.select(db.djmdContent).get();
    return {for (final row in rows) row.id!};
  } finally {
    await db.close();
  }
}

Future<List<({String rbId, int count, List<String> spotifyIds})>>
loadDuplicateGroups({
  required AppDatabase db,
  int limit = 0,
}) async {
  final rows = await db.customSelect('''
    SELECT
      rekordbox_song_id AS rb_id,
      COUNT(*) AS cnt,
      GROUP_CONCAT(spotify_track_id, ',') AS spotify_ids
    FROM sync_track_mappings
    GROUP BY rekordbox_song_id
    HAVING COUNT(*) > 1
    ORDER BY cnt DESC, rb_id ASC
    ${limit > 0 ? 'LIMIT $limit' : ''}
  ''').get();

  return [
    for (final row in rows)
      (
        rbId: row.read<String>('rb_id'),
        count: row.read<int>('cnt'),
        spotifyIds: row.read<String>('spotify_ids').split(','),
      ),
  ];
}

Future<Map<String, ({String title, List<String> artists})>>
loadSpotifyMetaById({
  required AppDatabase db,
}) async {
  final rows = await db.customSelect('''
    WITH meta AS (
      SELECT track_id AS spotify_id, name, artist_names FROM sync_playlist_tracks
      UNION
      SELECT track_id AS spotify_id, name, artist_names FROM cached_playlist_tracks
      UNION
      SELECT track_id AS spotify_id, name, artist_names FROM cached_label_tracks
    ),
    collapsed AS (
      SELECT spotify_id, name, artist_names FROM meta
      GROUP BY spotify_id, name, artist_names
    )
    SELECT spotify_id, name, artist_names FROM collapsed
  ''').get();

  final result = <String, ({String title, List<String> artists})>{};
  for (final row in rows) {
    final id = row.read<String>('spotify_id');
    final title = row.read<String>('name');
    final artistsJson = row.read<String>('artist_names');
    final artists = _decodeArtistsJson(artistsJson);
    result[id] = (title: title, artists: artists);
  }
  return result;
}

List<String> _decodeArtistsJson(String jsonText) {
  try {
    final decoded = jsonDecode(jsonText);
    if (decoded is List) {
      return decoded
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    }
  } catch (_) {}
  return const [];
}

String normalizeSpotifyQuery(List<String> artists, String title) {
  final a = artists.join(' ').trim();
  final t = title.trim();
  return '$a $t'
      .toLowerCase()
      .replaceAll(RegExp(r'[\[\]\(\)\{\}]'), ' ')
      .replaceAll(RegExp('[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

Future<List<Map<String, Object?>>> searchTopHits({
  required String query,
  required List<RbArtistAndSong> rbTracks,
  int limit = 8,
}) async {
  final matches = await findFuzzyTrackMatches(
    query: query,
    tracks: rbTracks,
    maxResults: limit,
  );

  return [
    for (final match in matches)
      {
        'rb_track_id': match.value.song.id,
        'rb_title': match.value.song.title,
        'rb_artist': match.value.artist?.name,
        'score': match.score,
      },
  ];
}

String? classifyCollision({
  required ({String title, List<String> artists})? a,
  required ({String title, List<String> artists})? b,
}) {
  if (a == null || b == null) return 'missing_spotify_metadata';

  final at = a.title.toLowerCase();
  final bt = b.title.toLowerCase();

  final aRemix = _hasVersionMarker(at);
  final bRemix = _hasVersionMarker(bt);
  if (aRemix != bRemix) return 'version_mismatch';

  if (_stripVersionMarkers(at) == _stripVersionMarkers(bt) &&
      _normalizeArtists(a.artists) == _normalizeArtists(b.artists)) {
    return null; // probably OK
  }

  return 'different_titles_or_artists';
}

bool _hasVersionMarker(String s) {
  return RegExp(
    r'\b(remix|vip|edit|bootleg|dub|instrumental|radio edit|extended mix|mix)\b',
    caseSensitive: false,
  ).hasMatch(s);
}

String _stripVersionMarkers(String s) {
  return s
      .replaceAll(
        RegExp(
          r'\b(remix|vip|edit|bootleg|dub|instrumental|radio edit|extended mix|original mix|mix)\b',
          caseSensitive: false,
        ),
        '',
      )
      .replaceAll(RegExp(r'[\[\]\(\)]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _normalizeArtists(List<String> artists) => artists
    .map((a) => a.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim())
    .where((a) => a.isNotEmpty)
    .join(', ');

Future<Map<String, Object?>> readApprovedFixes() async {
  final file = findIncorrectDuplicateTracksApprovedFile();
  if (!file.existsSync()) {
    throw StateError(
      'Approved fixes not found: ${file.path}\n'
      'Save your reviewed fixes as approved_fixes.json.',
    );
  }
  return jsonDecode(await file.readAsString()) as Map<String, Object?>;
}

({Map<String, String> remap, List<String> delete}) parseApprovedFixes(
  Map<String, Object?> doc,
) {
  final remap = <String, String>{};
  final delete = <String>[];

  final remapNode = doc['remap'];
  if (remapNode is Map) {
    for (final entry in remapNode.entries) {
      remap[entry.key.toString()] = entry.value.toString();
    }
  }

  final deleteNode = doc['delete'];
  if (deleteNode is List) {
    for (final v in deleteNode) {
      final id = v.toString().trim();
      if (id.isNotEmpty) delete.add(id);
    }
  }

  final entries = doc['entries'];
  if (entries is List) {
    for (final entry in entries) {
      if (entry is! Map) continue;
      final sp = entry['spotify_track_id']?.toString().trim();
      final rb = entry['rekordbox_track_id']?.toString().trim();
      final action = entry['action']?.toString().trim();

      if (sp == null || sp.isEmpty) continue;
      if (action == 'delete') {
        delete.add(sp);
        continue;
      }
      if (rb != null && rb.isNotEmpty) {
        remap[sp] = rb;
      }
    }
  }

  return (remap: remap, delete: delete);
}

Future<void> applyFixesToCache({
  required Map<String, String> remap,
  required List<String> delete,
}) async {
  final db = AppDatabase.fromCacheDbFile();
  try {
    final now = DateTime.now();

    if (remap.isNotEmpty) {
      await db.batch((batch) {
        for (final entry in remap.entries) {
          batch.insert(
            db.syncTrackMappings,
            SyncTrackMappingsCompanion.insert(
              spotifyTrackId: entry.key,
              rekordboxSongId: entry.value,
              createdAt: now,
            ),
            onConflict: DoUpdate(
              (old) => SyncTrackMappingsCompanion(
                rekordboxSongId: Value(entry.value),
                createdAt: Value(now),
              ),
            ),
          );
        }
      });
    }

    if (delete.isNotEmpty) {
      await (db.delete(
        db.syncTrackMappings,
      )..where((t) => t.spotifyTrackId.isIn(delete))).go();
    }
  } finally {
    await db.close();
  }
}

Future<void> cleanupReviewArtifacts({bool keepApproved = true}) async {
  final dir = findIncorrectDuplicateTracksReviewDir();
  if (!dir.existsSync()) return;

  for (final entity in dir.listSync()) {
    if (entity is! File) continue;
    if (keepApproved &&
        entity.path == findIncorrectDuplicateTracksApprovedFile().path) {
      continue;
    }
    await entity.delete();
  }

  if (!keepApproved ||
      !findIncorrectDuplicateTracksApprovedFile().existsSync()) {
    if (dir.existsSync() && dir.listSync().isEmpty) {
      await dir.delete();
    }
  }
}
