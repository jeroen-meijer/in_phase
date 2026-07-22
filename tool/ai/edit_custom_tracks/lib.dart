import 'dart:io';

import 'package:collection/collection.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:in_phase/src/database/database.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:in_phase/src/spotify/spotify.dart';
import 'package:rekorddart/rekorddart.dart';
import 'package:spotify/spotify.dart' show Artist;

typedef RbArtistAndSong = ({DjmdArtistData? artist, DjmdContentData song});

/// Minimum fuzzy score to accept a name → Rekordbox match.
const rbNameMatchThreshold = 80;

class ResolvedPlaylist {
  const ResolvedPlaylist({
    required this.id,
    required this.name,
    required this.source,
  });

  final String id;
  final String name;
  final String source;

  String get label => '$name ($id)';
}

class ResolvedTrack {
  const ResolvedTrack({
    required this.rekordboxId,
    required this.title,
    required this.artist,
    required this.source,
    this.spotifyTrackId,
    this.score,
  });

  final String rekordboxId;
  final String title;
  final String artist;
  final String source;
  final String? spotifyTrackId;
  final int? score;

  String get display => '$artist - $title';
}

class CustomTrackSpec {
  const CustomTrackSpec({
    required this.playlist,
    required this.track,
    required this.type,
    this.target,
    this.index,
    this.position,
  });

  final ResolvedPlaylist playlist;
  final ResolvedTrack track;
  final String type; // insert | replace
  final ResolvedTrack? target;
  final int? index;
  final int? position;
}

/// Extracts a Spotify track id from a bare id, URI, or open.spotify.com URL.
String? extractSpotifyTrackId(String input) {
  final s = input.trim();
  if (s.startsWith('spotify:track:')) {
    final id = s.split(':').last.split('?').first;
    return _isSpotifyId(id) ? id : null;
  }
  if (Uri.tryParse(s) case Uri(
    host: 'open.spotify.com' || 'spotify.com',
    pathSegments: ['track', final id, ...],
  )) {
    return _isSpotifyId(id) ? id : null;
  }
  return _isSpotifyId(s) ? s : null;
}

bool _isSpotifyId(String value) => RegExp(r'^[a-zA-Z0-9]{22}$').hasMatch(value);

bool looksLikeRekordboxId(String value) =>
    RegExp(r'^\d+$').hasMatch(value.trim());

/// Best-effort year from playlist names like `SET_2026-07-26_LIQ-FST`.
int _playlistYearHint(String name) {
  final match = RegExp(r'(19|20)\d{2}').firstMatch(name);
  if (match == null) return 0;
  return int.tryParse(match.group(0)!) ?? 0;
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

Future<ResolvedPlaylist> resolvePlaylist({
  required String query,
  required AppDatabase cacheDb,
}) async {
  final asId = SpotifyPlaylistId.tryExtract(query);
  if (asId != null) {
    final rows = await cacheDb
        .customSelect(
          'SELECT playlist_id, name FROM sync_playlists WHERE playlist_id = ?',
          variables: [Variable.withString(asId)],
        )
        .get();
    if (rows.isNotEmpty) {
      return ResolvedPlaylist(
        id: rows.first.read<String>('playlist_id'),
        name: rows.first.read<String>('name'),
        source: 'spotify_id',
      );
    }
    // Still accept unknown-to-cache playlist ids (may be newly created).
    return ResolvedPlaylist(
      id: asId,
      name: asId,
      source: 'spotify_id_uncached',
    );
  }

  final rows = await cacheDb
      .customSelect(
        'SELECT playlist_id, name FROM sync_playlists '
        'ORDER BY name COLLATE NOCASE',
      )
      .get();
  if (rows.isEmpty) {
    throw StateError(
      'No synced playlists in cache.db. Run a sync once so playlist '
      'names/ids are cached.',
    );
  }

  final needle = query.trim().toLowerCase();
  final exact = rows.where(
    (r) => r.read<String>('name').toLowerCase() == needle,
  );
  if (exact.length == 1) {
    return ResolvedPlaylist(
      id: exact.first.read<String>('playlist_id'),
      name: exact.first.read<String>('name'),
      source: 'exact_name',
    );
  }

  // Prefer substring hits (e.g. "liq festival" / "LIQ-FST").
  final substring = [
    for (final r in rows)
      if (r.read<String>('name').toLowerCase().contains(needle)) r,
  ];
  if (substring.length == 1) {
    return ResolvedPlaylist(
      id: substring.first.read<String>('playlist_id'),
      name: substring.first.read<String>('name'),
      source: 'substring_name',
    );
  }

  // Multiple substring hits (e.g. several LIQ-FST years): prefer highest
  // year in the name, skip "(OLD)" aliases.
  if (substring.length > 1) {
    final usable = [
      for (final r in substring)
        if (!r.read<String>('name').toUpperCase().contains('(OLD)')) r,
    ];
    final pool = usable.isNotEmpty ? usable : substring;
    final scored = pool
        .map(
          (r) => (
            row: r,
            year: _playlistYearHint(r.read<String>('name')),
            name: r.read<String>('name'),
          ),
        )
        .sorted((a, b) {
          final byYear = b.year.compareTo(a.year);
          if (byYear != 0) return byYear;
          return b.name.compareTo(a.name);
        });
    final pick = scored.first;
    stderr.writeln(
      'Warning: multiple playlists match "$query"; '
      'using "${pick.name}". Pass a full name or Spotify id to disambiguate.',
    );
    return ResolvedPlaylist(
      id: pick.row.read<String>('playlist_id'),
      name: pick.name,
      source: 'substring_newest',
    );
  }

  var bestScore = 0;
  QueryRow? best;
  for (final r in rows) {
    final score = tokenSortRatio(needle, r.read<String>('name').toLowerCase());
    if (score > bestScore) {
      bestScore = score;
      best = r;
    }
  }
  if (best == null || bestScore < 70) {
    final hint = rows.take(5).map((r) => r.read<String>('name')).join(', ');
    throw StateError(
      'Could not resolve playlist "$query" '
      '(best fuzzy score $bestScore). Candidates: $hint',
    );
  }
  return ResolvedPlaylist(
    id: best.read<String>('playlist_id'),
    name: best.read<String>('name'),
    source: 'fuzzy_name:$bestScore',
  );
}

Future<ResolvedTrack> resolveAddTrack({
  required String query,
  required List<RbArtistAndSong> rbTracks,
  required AppDatabase cacheDb,
  String? artistHint,
}) async {
  final trimmed = query.trim();
  if (looksLikeRekordboxId(trimmed)) {
    final resolved = _lookupRbTrack(
      rekordboxId: trimmed,
      rbTracks: rbTracks,
      source: 'rekordbox_id',
    );
    if (resolved == null) {
      throw StateError(
        'Rekordbox id $trimmed not found in library. '
        'custom_tracks can only reference tracks that exist in Rekordbox '
        '(sync skips missing rekordbox_id values).',
      );
    }
    return resolved;
  }

  final spotifyId = extractSpotifyTrackId(trimmed);
  if (spotifyId != null) {
    return _resolveAddFromSpotify(
      spotifyTrackId: spotifyId,
      rbTracks: rbTracks,
      cacheDb: cacheDb,
    );
  }

  // "Title by Artist" or explicit artistHint.
  var title = trimmed;
  var artists = artistHint == null || artistHint.trim().isEmpty
      ? <String>[]
      : [artistHint.trim()];
  final byMatch = RegExp(
    r'^(.*)\s+by\s+(.+)$',
    caseSensitive: false,
  ).firstMatch(trimmed);
  if (byMatch != null) {
    title = byMatch.group(1)!.trim();
    if (artists.isEmpty) {
      artists = [byMatch.group(2)!.trim()];
    }
  }

  return _fuzzyResolveRbName(
    query: artists.isEmpty ? title : '${artists.join(' ')} $title',
    rbTracks: rbTracks,
    title: title,
    artists: artists.isEmpty ? null : artists,
  );
}

/// Spotify → Rekordbox for `--add`.
///
/// Sync skips custom tracks whose `rekordbox_id` is missing from the library.
/// Lookup order:
/// 1. `sync_track_mappings`
/// 2. Fuzzy name/artist search in Rekordbox (metadata from sync cache, else
///    Spotify API) — often fails if the track was never synced/mapped
Future<ResolvedTrack> _resolveAddFromSpotify({
  required String spotifyTrackId,
  required List<RbArtistAndSong> rbTracks,
  required AppDatabase cacheDb,
}) async {
  final mappingRows = await cacheDb
      .customSelect(
        'SELECT rekordbox_song_id FROM sync_track_mappings '
        'WHERE spotify_track_id = ? LIMIT 1',
        variables: [Variable.withString(spotifyTrackId)],
      )
      .get();

  if (mappingRows.isNotEmpty) {
    final rbId = mappingRows.first.read<String>('rekordbox_song_id');
    final resolved = _lookupRbTrack(
      rekordboxId: rbId,
      rbTracks: rbTracks,
      source: 'spotify_mapping',
      spotifyTrackId: spotifyTrackId,
    );
    if (resolved == null) {
      throw StateError(
        'Spotify track $spotifyTrackId is mapped to Rekordbox id $rbId in '
        'sync_track_mappings, but that id is not in your Rekordbox library. '
        'custom_tracks can only reference tracks that exist in Rekordbox '
        '(sync skips missing rekordbox_id values).',
      );
    }
    return resolved;
  }

  final meta = await _spotifyTrackMeta(cacheDb, spotifyTrackId);
  if (meta == null) {
    throw StateError(
      'Spotify track $spotifyTrackId has no sync_track_mappings entry and '
      'title/artists could not be loaded from cache or Spotify. '
      'Pass a Rekordbox id, or sync a playlist that contains this track. '
      'custom_tracks require the track to already exist in Rekordbox.',
    );
  }

  stderr.writeln(
    'No sync_track_mappings hit for $spotifyTrackId '
    '("${meta.artists.join(', ')} - ${meta.title}"); '
    'trying fuzzy Rekordbox search (often misses).',
  );

  final fuzzy = _tryFuzzyResolveRbName(
    query: '${meta.artists.join(' ')} ${meta.title}',
    rbTracks: rbTracks,
    title: meta.title,
    artists: meta.artists,
  );
  if (fuzzy == null) {
    throw StateError(
      'Spotify track $spotifyTrackId ("${meta.artists.join(', ')} - '
      '${meta.title}") is not in sync_track_mappings and no close '
      'Rekordbox match was found (need ≥$rbNameMatchThreshold). '
      'Import/analyze it in Rekordbox first — custom_tracks only work for '
      'tracks already in your Rekordbox library.',
    );
  }

  return ResolvedTrack(
    rekordboxId: fuzzy.rekordboxId,
    title: fuzzy.title,
    artist: fuzzy.artist,
    source: 'spotify_id→rb:${fuzzy.source}',
    spotifyTrackId: spotifyTrackId,
    score: fuzzy.score,
  );
}

Future<({String title, List<String> artists})?> _spotifyTrackMeta(
  AppDatabase cacheDb,
  String spotifyTrackId,
) async {
  final playlistRows = await cacheDb
      .customSelect(
        'SELECT name, artist_names FROM sync_playlist_tracks '
        'WHERE track_id = ? LIMIT 1',
        variables: [Variable.withString(spotifyTrackId)],
      )
      .get();
  if (playlistRows.isNotEmpty) {
    return (
      title: playlistRows.first.read<String>('name'),
      artists: _parseArtistNames(
        playlistRows.first.read<String>('artist_names'),
      ),
    );
  }

  final missingRows = await cacheDb
      .customSelect(
        'SELECT title, artist FROM sync_missing_tracks '
        'WHERE spotify_track_id = ? LIMIT 1',
        variables: [Variable.withString(spotifyTrackId)],
      )
      .get();
  if (missingRows.isNotEmpty) {
    return (
      title: missingRows.first.read<String>('title'),
      artists: missingRows.first
          .read<String>('artist')
          .split(RegExp(r'\s*,\s*'))
          .where((s) => s.isNotEmpty)
          .toList(),
    );
  }

  // Last resort: Spotify Web API (needs cached OAuth credentials).
  return _spotifyTrackMetaFromApi(spotifyTrackId);
}

Future<({String title, List<String> artists})?> _spotifyTrackMetaFromApi(
  String spotifyTrackId,
) async {
  try {
    final api = await spotifyLogin();
    final track = await api.tracks.get(spotifyTrackId);
    final title = track.name?.trim();
    if (title == null || title.isEmpty) return null;
    final artists = <String>[
      for (final Artist a in track.artists ?? const <Artist>[])
        if (a.name case final name? when name.trim().isNotEmpty) name.trim(),
    ];
    return (title: title, artists: artists);
  } on Object catch (e) {
    stderr.writeln(
      'Could not fetch Spotify track $spotifyTrackId via API: $e',
    );
    return null;
  }
}

ResolvedTrack? _lookupRbTrack({
  required String rekordboxId,
  required List<RbArtistAndSong> rbTracks,
  required String source,
  String? spotifyTrackId,
}) {
  final match = rbTracks.where((t) => t.song.id == rekordboxId).toList();
  if (match.isEmpty) return null;
  final t = match.first;
  return ResolvedTrack(
    rekordboxId: rekordboxId,
    title: t.song.title ?? 'Unknown',
    artist: t.artist?.name ?? 'Unknown Artist',
    source: source,
    spotifyTrackId: spotifyTrackId,
  );
}

/// Score [needle] against a track title (+ optional artist).
///
/// Uses token-sort ratio only (no partial ratios — those false-positive
/// `Twerp`→`Antwerp` and `So Good`→`Something Good`). Boosts title prefix /
/// whole-phrase word hits for WIP filenames like `So Good 2025-12-19 1938`.
int scoreNameMatch({
  required String needle,
  required String title,
  String artist = '',
}) {
  final n = needle.trim().toLowerCase();
  if (n.isEmpty) return 0;
  final t = title.trim().toLowerCase();
  final a = artist.trim().toLowerCase();
  final combined = '$a $t'.trim();

  var best = tokenSortRatio(n, t);
  if (combined.isNotEmpty) {
    final combinedScore = tokenSortRatio(n, combined);
    if (combinedScore > best) best = combinedScore;
  }

  // Title starts with the query (common for dated WIP filenames).
  if (t == n ||
      t.startsWith('$n ') ||
      t.startsWith('$n-') ||
      t.startsWith('${n}_')) {
    if (best < 96) best = 96;
  } else if (_titleHasNeedleAsWord(t, n)) {
    if (best < 90) best = 90;
  }

  return best;
}

bool _titleHasNeedleAsWord(String titleLower, String needleLower) {
  return RegExp(
    '(^|[^a-z0-9])${RegExp.escape(needleLower)}([^a-z0-9]|\$)',
  ).hasMatch(titleLower);
}

/// Top Rekordbox hits for [query] (for `--search` / failure hints).
List<ResolvedTrack> searchRekordboxTracks({
  required String query,
  required List<RbArtistAndSong> rbTracks,
  int limit = 10,
}) {
  final needle = query.trim();
  if (needle.isEmpty || rbTracks.isEmpty) return const [];

  final scored = <({RbArtistAndSong track, int score})>[
    for (final track in rbTracks)
      (
        track: track,
        score: scoreNameMatch(
          needle: needle,
          title: track.song.title ?? '',
          artist: track.artist?.name ?? '',
        ),
      ),
  ];
  // Prefer higher score; on ties, shorter titles (WIP "X 2025-…" over
  // longer unrelated hits that scored equally).
  final sorted = scored.sorted((a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    final aLen = (a.track.song.title ?? '').length;
    final bLen = (b.track.song.title ?? '').length;
    return aLen.compareTo(bLen);
  });
  return [
    for (final hit in sorted.take(limit))
      if (hit.score > 0)
        ResolvedTrack(
          rekordboxId: hit.track.song.id!,
          title: hit.track.song.title ?? 'Unknown',
          artist: hit.track.artist?.name ?? 'Unknown Artist',
          source: 'search:${hit.score}',
          score: hit.score,
        ),
  ];
}

ResolvedTrack _fuzzyResolveRbName({
  required String query,
  required List<RbArtistAndSong> rbTracks,
  String? title,
  List<String>? artists,
}) {
  final resolved = _tryFuzzyResolveRbName(
    query: query,
    rbTracks: rbTracks,
    title: title,
    artists: artists,
  );
  if (resolved == null) {
    final candidates = searchRekordboxTracks(
      query: title ?? query,
      rbTracks: rbTracks,
      limit: 5,
    );
    final hint = candidates.isEmpty
        ? 'No close candidates.'
        : 'Top candidates:\n${candidates.map((c) {
            return '  ${c.score}  ${c.rekordboxId}  ${c.display}';
          }).join('\n')}';
    throw StateError(
      'Could not resolve Rekordbox track for "$query" '
      '(need ≥$rbNameMatchThreshold). $hint\n'
      'Pass an explicit Rekordbox id, or run:\n'
      '  dart run tool/ai/edit_custom_tracks/resolve.dart --search "$query"',
    );
  }
  return resolved;
}

ResolvedTrack? _tryFuzzyResolveRbName({
  required String query,
  required List<RbArtistAndSong> rbTracks,
  String? title,
  List<String>? artists,
}) {
  if (rbTracks.isEmpty) return null;

  // Prefer structured title/artists when provided; also try the raw query.
  final needles = <String>{
    query.trim(),
    if (title != null) title.trim(),
    if (artists != null && title != null) '${artists.join(' ')} $title'.trim(),
  }.where((s) => s.isNotEmpty);

  var bestScore = 0;
  var bestTitleLen = 1 << 30;
  RbArtistAndSong? best;
  for (final track in rbTracks) {
    final trackTitle = track.song.title ?? '';
    final trackArtist = track.artist?.name ?? '';
    for (final needle in needles) {
      final score = scoreNameMatch(
        needle: needle,
        title: trackTitle,
        artist: trackArtist,
      );
      final better =
          score > bestScore ||
          (score == bestScore && trackTitle.length < bestTitleLen);
      if (better) {
        bestScore = score;
        bestTitleLen = trackTitle.length;
        best = track;
      }
    }
  }
  if (best == null || bestScore < rbNameMatchThreshold) return null;
  return ResolvedTrack(
    rekordboxId: best.song.id!,
    title: best.song.title ?? 'Unknown',
    artist: best.artist?.name ?? 'Unknown Artist',
    source: 'fuzzy_name:$bestScore',
    score: bestScore,
  );
}

Future<ResolvedTrack> resolveAnchorTrack({
  required String query,
  required String playlistId,
  required AppDatabase cacheDb,
  required List<RbArtistAndSong> rbTracks,
}) async {
  final trimmed = query.trim();
  if (looksLikeRekordboxId(trimmed)) {
    final match = rbTracks.where((t) => t.song.id == trimmed).toList();
    if (match.isEmpty) {
      throw StateError('Rekordbox id $trimmed not found in library.');
    }
    final t = match.first;
    return ResolvedTrack(
      rekordboxId: trimmed,
      title: t.song.title ?? 'Unknown',
      artist: t.artist?.name ?? 'Unknown Artist',
      source: 'rekordbox_id',
    );
  }

  final spotifyId = extractSpotifyTrackId(trimmed);
  if (spotifyId != null) {
    final rows = await cacheDb
        .customSelect(
          'SELECT name, artist_names FROM sync_playlist_tracks '
          'WHERE playlist_id = ? AND track_id = ? LIMIT 1',
          variables: [
            Variable.withString(playlistId),
            Variable.withString(spotifyId),
          ],
        )
        .get();
    if (rows.isEmpty) {
      throw StateError(
        'Spotify track $spotifyId is not in cached playlist $playlistId. '
        'Sync that playlist once, or pass a Rekordbox id / name for --after.',
      );
    }
    final title = rows.first.read<String>('name');
    final artists = _parseArtistNames(rows.first.read<String>('artist_names'));
    final resolved = _fuzzyResolveRbName(
      query: '${artists.join(' ')} $title',
      rbTracks: rbTracks,
      title: title,
      artists: artists,
    );
    return ResolvedTrack(
      rekordboxId: resolved.rekordboxId,
      title: resolved.title,
      artist: resolved.artist,
      source: 'spotify_id→rb:${resolved.source}',
      spotifyTrackId: spotifyId,
      score: resolved.score,
    );
  }

  // Name: prefer matching against tracks in this playlist's cache, then RB.
  final playlistTracks = await cacheDb
      .customSelect(
        'SELECT track_id, name, artist_names FROM sync_playlist_tracks '
        'WHERE playlist_id = ? ORDER BY order_index',
        variables: [Variable.withString(playlistId)],
      )
      .get();

  if (playlistTracks.isNotEmpty) {
    final needle = trimmed.toLowerCase();
    QueryRow? bestRow;
    var bestScore = 0;
    for (final row in playlistTracks) {
      final title = row.read<String>('name');
      final artists = _parseArtistNames(row.read<String>('artist_names'));
      final score = scoreNameMatch(
        needle: needle,
        title: title,
        artist: artists.join(' '),
      );
      if (score > bestScore) {
        bestScore = score;
        bestRow = row;
      }
    }
    if (bestRow != null && bestScore >= 70) {
      final title = bestRow.read<String>('name');
      final artists = _parseArtistNames(bestRow.read<String>('artist_names'));
      final spotifyTrackId = bestRow.read<String>('track_id');
      final resolved = _fuzzyResolveRbName(
        query: '${artists.join(' ')} $title',
        rbTracks: rbTracks,
        title: title,
        artists: artists,
      );
      return ResolvedTrack(
        rekordboxId: resolved.rekordboxId,
        title: resolved.title,
        artist: resolved.artist,
        source: 'playlist_name→rb:${resolved.source}',
        spotifyTrackId: spotifyTrackId,
        score: resolved.score,
      );
    }
  }

  return _fuzzyResolveRbName(query: trimmed, rbTracks: rbTracks);
}

List<String> _parseArtistNames(String raw) {
  final trimmed = raw.trim();
  if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
    // JSON array from Drift/cache: ["Hoax"]
    try {
      final inner = trimmed.substring(1, trimmed.length - 1);
      if (inner.isEmpty) return const [];
      return inner
          .split(',')
          .map((s) => s.trim().replaceAll(RegExp(r'^"|"$'), ''))
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (_) {
      // fall through
    }
  }
  return trimmed.split(RegExp(r'\s*,\s*')).where((s) => s.isNotEmpty).toList();
}

/// Formats a custom_tracks list entry matching existing sync_config style.
String formatCustomTrackYaml(CustomTrackSpec spec) {
  final buf = StringBuffer()
    ..writeln('    # ${spec.track.display}')
    ..writeln('    - rekordbox_id: ${spec.track.rekordboxId}');

  if (spec.type == 'replace') {
    buf.writeln('      type: replace');
  }

  if (spec.target != null) {
    buf
      ..writeln('      # ${spec.target!.display}')
      ..writeln('      target: ${spec.target!.rekordboxId}');
  }

  if (spec.index != null) {
    buf.writeln('      index: ${spec.index}');
  }
  if (spec.position != null) {
    buf.writeln('      position: ${spec.position}');
  }

  return buf.toString();
}

File defaultSyncConfigFile() => Constants.syncConfigFile;
