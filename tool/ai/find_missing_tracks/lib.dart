import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:in_phase/src/database/database.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:path/path.dart' as p;
import 'package:rekorddart/rekorddart.dart';

typedef RbArtistAndSong = ({DjmdArtistData? artist, DjmdContentData song});

/// Default sync fuzzy-match threshold (see sync command).
const syncMatchThreshold = 80;

/// Near-miss band: sync best scores in this range deserve LLM review.
const nearMissMinScore = 70;
const nearMissMaxScore = 79;

Directory findMissingTracksReviewDir() => Directory(
  p.join(Constants.appDataDir.path, 'build', 'find_missing_tracks'),
);

File findMissingTracksCandidatesFile() =>
    File(p.join(findMissingTracksReviewDir().path, 'candidates.json'));

File findMissingTracksReviewBriefFile() =>
    File(p.join(findMissingTracksReviewDir().path, 'review_brief.md'));

File findMissingTracksProposedFile() =>
    File(p.join(findMissingTracksReviewDir().path, 'proposed_mappings.json'));

File findMissingTracksApprovedFile() =>
    File(p.join(findMissingTracksReviewDir().path, 'approved_mappings.json'));

/// Filters synced Spotify playlist names. Empty scope = all missing tracks.
///
/// Patterns are Dart regexes, combined with OR when `--playlist-regex` is
/// repeated.
class PlaylistScope {
  PlaylistScope._({
    required this.patterns,
    required List<RegExp> regexes,
  }) : _regexes = regexes;

  factory PlaylistScope.fromPatterns(List<String> patterns) {
    if (patterns.isEmpty) {
      return PlaylistScope._(patterns: const [], regexes: const []);
    }
    final regexes = <RegExp>[];
    for (final pattern in patterns) {
      try {
        regexes.add(RegExp(pattern));
      } on FormatException catch (e) {
        throw ArgumentError('Invalid playlist regex /$pattern/: $e');
      }
    }
    return PlaylistScope._(patterns: patterns, regexes: regexes);
  }

  const PlaylistScope.unfiltered() : patterns = const [], _regexes = const [];

  final List<String> patterns;
  final List<RegExp> _regexes;

  bool get isUnfiltered => patterns.isEmpty;

  bool matches(String playlistName) {
    if (isUnfiltered) return true;
    return _regexes.any((regex) => regex.hasMatch(playlistName));
  }

  String describe() {
    if (isUnfiltered) return 'all missing tracks';
    if (patterns.length == 1) {
      return 'playlist name matches /${patterns.single}/';
    }
    return 'playlist name matches any of: '
        '${patterns.map((p) => '/$p/').join(', ')}';
  }

  Map<String, Object?> toJson() => {
    'playlist_regexes': patterns,
    'description': describe(),
  };
}

ArgParser buildPlaylistScopeParser() {
  return ArgParser()..addMultiOption(
    'playlist-regex',
    abbr: 'r',
    help:
        'Synced playlist name matches this regex (repeatable; OR between '
        'patterns). Omit to include all missing tracks.',
    valueHelp: 'REGEX',
  );
}

PlaylistScope playlistScopeFromArgs(ArgResults results) =>
    PlaylistScope.fromPatterns(
      (results['playlist-regex'] as List<String>?) ?? const [],
    );

class MissingTrack {
  MissingTrack({
    required this.spotifyTrackId,
    required this.title,
    required this.artists,
  });

  final String spotifyTrackId;
  final String title;
  final List<String> artists;

  String get display => '${artists.join(', ')} - $title';
}

class SearchHit {
  SearchHit({
    required this.rbTrackId,
    required this.rbTitle,
    required this.rbArtist,
    required this.score,
    required this.query,
  });

  final String rbTrackId;
  final String rbTitle;
  final String rbArtist;
  final int score;
  final String query;

  Map<String, Object?> toJson() => {
    'rb_track_id': rbTrackId,
    'rb_title': rbTitle,
    'rb_artist': rbArtist,
    'score': score,
    'query': query,
  };
}

Future<List<MissingTrack>> loadMissingTracks({
  required AppDatabase db,
  PlaylistScope scope = const PlaylistScope.unfiltered(),
}) async {
  if (scope.isUnfiltered) {
    final rows = await db.customSelect('''
      SELECT
        spotify_track_id AS spotify_track_id,
        title AS title,
        artist AS artist
      FROM sync_missing_tracks
      ORDER BY title COLLATE NOCASE, artist COLLATE NOCASE
    ''').get();

    return [
      for (final row in rows)
        MissingTrack(
          spotifyTrackId: row.read<String>('spotify_track_id'),
          title: row.read<String>('title'),
          artists: row.read<String>('artist').split(', '),
        ),
    ];
  }

  final rows = await db.customSelect('''
    SELECT DISTINCT
      m.spotify_track_id AS spotify_track_id,
      m.title AS title,
      m.artist AS artist,
      p.name AS playlist_name
    FROM sync_missing_tracks m
    JOIN sync_playlist_tracks pt ON pt.track_id = m.spotify_track_id
    JOIN sync_playlists p ON p.playlist_id = pt.playlist_id
    ORDER BY m.title COLLATE NOCASE, m.artist COLLATE NOCASE
  ''').get();

  final seen = <String>{};
  final tracks = <MissingTrack>[];
  for (final row in rows) {
    if (!scope.matches(row.read<String>('playlist_name'))) continue;
    final id = row.read<String>('spotify_track_id');
    if (!seen.add(id)) continue;
    tracks.add(
      MissingTrack(
        spotifyTrackId: id,
        title: row.read<String>('title'),
        artists: row.read<String>('artist').split(', '),
      ),
    );
  }
  return tracks;
}

Future<List<({String name, int missingCount})>> loadPlaylistsWithMissing({
  required AppDatabase db,
  PlaylistScope scope = const PlaylistScope.unfiltered(),
}) async {
  final rows = await db.customSelect('''
    SELECT
      p.name AS playlist_name,
      COUNT(DISTINCT m.spotify_track_id) AS missing_count
    FROM sync_playlists p
    JOIN sync_playlist_tracks pt ON pt.playlist_id = p.playlist_id
    JOIN sync_missing_tracks m ON m.spotify_track_id = pt.track_id
    GROUP BY p.playlist_id, p.name
    ORDER BY missing_count DESC, p.name COLLATE NOCASE
  ''').get();

  return [
    for (final row in rows)
      if (scope.matches(row.read<String>('playlist_name')))
        (
          name: row.read<String>('playlist_name'),
          missingCount: row.read<int>('missing_count'),
        ),
  ];
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

FuzzyFindMatch<RbArtistAndSong> syncStyleMatch({
  required String title,
  required List<String> artists,
  required List<RbArtistAndSong> tracks,
}) {
  final query = normalizeQuery(artists, title);
  var bestScore = 0;
  var bestMatch = tracks.first;

  for (final track in tracks) {
    final target = normalizeQuery(
      [track.artist?.name ?? ''],
      track.song.title ?? '',
    );
    final score = tokenSortRatio(query, target);
    if (score > bestScore) {
      bestScore = score;
      bestMatch = track;
    }
  }

  return FuzzyFindMatch(value: bestMatch, score: bestScore);
}

Future<List<SearchHit>> searchHits({
  required String query,
  required List<RbArtistAndSong> tracks,
  int limit = 50,
}) async {
  final matches = await findFuzzyTrackMatches(
    query: query,
    tracks: tracks,
    maxResults: limit,
  );

  return [
    for (final match in matches)
      SearchHit(
        rbTrackId: match.value.song.id!,
        rbTitle: match.value.song.title ?? '',
        rbArtist: match.value.artist?.name ?? 'Unknown Artist',
        score: match.score,
        query: query,
      ),
  ];
}

String combinedSearchQuery(MissingTrack track) =>
    '${track.artists.join(' ')} ${track.title}';

Future<Map<String, Object?>> investigateTrack({
  required MissingTrack track,
  required List<RbArtistAndSong> rbTracks,
}) async {
  final syncMatch = syncStyleMatch(
    title: track.title,
    artists: track.artists,
    tracks: rbTracks,
  );
  final syncScore = syncMatch.score;

  final combinedQuery = combinedSearchQuery(track);
  final combinedHits = await searchHits(
    query: combinedQuery,
    tracks: rbTracks,
  );

  return {
    'spotify_track_id': track.spotifyTrackId,
    'spotify_title': track.title,
    'spotify_artists': track.artists,
    'spotify_display': track.display,
    'search_query': combinedQuery,
    'near_miss':
        syncScore >= nearMissMinScore && syncScore < syncMatchThreshold,
    'sync_best': {
      'score': syncScore,
      'rb_track_id': syncMatch.value.song.id,
      'rb_title': syncMatch.value.song.title,
      'rb_artist': syncMatch.value.artist?.name,
    },
    'search_combined': combinedHits.take(15).map((e) => e.toJson()).toList(),
  };
}

String buildReviewBrief({
  required List<Map<String, Object?>> tracks,
  required PlaylistScope scope,
}) {
  final buffer = StringBuffer()
    ..writeln('# Find missing tracks — mapping review')
    ..writeln()
    ..writeln('- Sync threshold: **$syncMatchThreshold**')
    ..writeln('- Near-miss band: **$nearMissMinScore–$nearMissMaxScore**')
    ..writeln('- Tracks to review: **${tracks.length}**')
    ..writeln('- Playlist scope: ${scope.describe()}')
    ..writeln()
    ..writeln('Review each track using **artist + title together**.')
    ..writeln()
    ..writeln('**Remixes/versions:** same remix on both sides only.')
    ..writeln(
      '`Artist - Song` ≠ `Artist - Song (Someguy Remix)`. '
      'If Spotify is original, reject Rekordbox remix/VIP/bootleg '
      'titles. If Spotify names a remix, Rekordbox must be that remix '
      '(not original, not another remix).',
    )
    ..writeln(
      'Also reject: acapella stems (`_(Vocals)`), title-only matches.',
    )
    ..writeln();

  final nearMisses = tracks.where((t) => t['near_miss'] == true).toList()
    ..sort(
      (a, b) => (b['sync_best']! as Map)['score']!.toString().compareTo(
        (a['sync_best']! as Map)['score']!.toString(),
      ),
    );

  if (nearMisses.isNotEmpty) {
    buffer
      ..writeln(
        '## Near misses (sync score $nearMissMinScore–$nearMissMaxScore)',
      )
      ..writeln();
    for (final track in nearMisses) {
      _writeTrackSection(buffer, track);
    }
  }

  buffer
    ..writeln('## All missing tracks')
    ..writeln();
  for (final track in tracks) {
    _writeTrackSection(buffer, track);
  }

  return buffer.toString();
}

void _writeTrackSection(StringBuffer buffer, Map<String, Object?> track) {
  final sync = track['sync_best']! as Map<String, Object?>;
  buffer
    ..writeln('---')
    ..writeln('### ${track['spotify_display']}')
    ..writeln('- Spotify ID: `${track['spotify_track_id']}`')
    ..writeln('- Search query: `${track['search_query']}`')
    ..writeln(
      '- Sync best (${sync['score']}): ${sync['rb_artist']} - '
      '${sync['rb_title']} [`${sync['rb_track_id']}`]',
    )
    ..writeln('- Combined search top hits:');

  for (final hit
      in (track['search_combined']! as List).cast<Map<String, Object?>>()) {
    final score = hit['score'];
    final artist = hit['rb_artist'];
    final title = hit['rb_title'];
    final id = hit['rb_track_id'];
    buffer.writeln('  - ($score) $artist - $title [`$id`]');
  }
  buffer.writeln();
}

Future<Map<String, Object?>> readApprovedMappings() async {
  final file = findMissingTracksApprovedFile();
  if (!file.existsSync()) {
    throw StateError(
      'Approved mappings not found: ${file.path}\n'
      'Save proposed mappings as approved_mappings.json after user review.',
    );
  }
  return jsonDecode(await file.readAsString()) as Map<String, Object?>;
}

Map<String, String> parseMappingEntries(Map<String, Object?> doc) {
  final mappings = <String, String>{};

  final flat = doc['mappings'];
  if (flat is Map) {
    for (final entry in flat.entries) {
      mappings[entry.key.toString()] = entry.value.toString();
    }
  }

  final entries = doc['entries'];
  if (entries is List) {
    for (final entry in entries) {
      if (entry is! Map) continue;
      final sp = entry['spotify_track_id']?.toString();
      final rb = entry['rekordbox_track_id']?.toString();
      if (sp != null && rb != null) {
        mappings[sp] = rb;
      }
    }
  }

  if (mappings.isEmpty) {
    throw StateError('No mappings found in approved_mappings.json');
  }

  return mappings;
}

Future<void> applyMappingsToCache(Map<String, String> mappings) async {
  final db = AppDatabase.fromCacheDbFile();
  try {
    final now = DateTime.now();
    await db.batch((batch) {
      for (final entry in mappings.entries) {
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

    final spotifyIds = mappings.keys.toList();
    await (db.delete(
      db.syncMissingTracks,
    )..where((t) => t.spotifyTrackId.isIn(spotifyIds))).go();
  } finally {
    await db.close();
  }
}

Future<void> cleanupReviewArtifacts({bool keepApproved = true}) async {
  final dir = findMissingTracksReviewDir();
  if (!dir.existsSync()) return;

  for (final entity in dir.listSync()) {
    if (entity is! File) continue;
    if (keepApproved && entity.path == findMissingTracksApprovedFile().path) {
      continue;
    }
    await entity.delete();
  }

  if (!keepApproved || !findMissingTracksApprovedFile().existsSync()) {
    if (dir.existsSync() && dir.listSync().isEmpty) {
      await dir.delete();
    }
  }
}
