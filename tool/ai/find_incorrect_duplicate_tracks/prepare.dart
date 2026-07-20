import 'dart:convert';
import 'dart:io';

import 'package:in_phase/src/database/database.dart';
import 'package:in_phase/src/misc/misc.dart';

import 'lib.dart';

Future<void> main(List<String> args) async {
  final parser = buildPrepareParser();
  final results = parser.parse(args);
  if (results.rest.isNotEmpty) {
    stderr
      ..writeln('Unexpected arguments: ${results.rest.join(' ')}')
      ..writeln(parser.usage);
    exitCode = 64;
    return;
  }

  final limit = int.tryParse(results['limit'] as String? ?? '') ?? 0;
  final includeClean = results['include-clean'] as bool? ?? false;

  final reviewDir = findIncorrectDuplicateTracksReviewDir();
  await reviewDir.create(recursive: true);

  stderr.writeln(
    'Loading duplicate mappings from ${Constants.cacheDbFile.path}...',
  );
  final cacheDb = AppDatabase.fromCacheDbFile();
  final groups = await loadDuplicateGroups(db: cacheDb, limit: limit);
  final spotifyMeta = await loadSpotifyMetaById(db: cacheDb);
  await cacheDb.close();

  if (groups.isEmpty) {
    stdout.writeln('No duplicate Rekordbox mappings found.');
    return;
  }

  stderr.writeln('Loading Rekordbox library...');
  final rbTracks = await loadRekordboxTracks();
  final rbById = {for (final t in rbTracks) t.song.id!: t};

  stderr.writeln('Building review candidates...');
  final candidates = <Map<String, Object?>>[];
  var suspiciousCount = 0;

  for (var i = 0; i < groups.length; i++) {
    final g = groups[i];
    stderr.writeln(
      '[${i + 1}/${groups.length}] rb=${g.rbId} spotify=${g.count}',
    );

    final rb = rbById[g.rbId];
    final rbTitle = rb?.song.title ?? '';
    final rbArtist = rb?.artist?.name ?? 'Unknown Artist';

    final spotifyEntries = <Map<String, Object?>>[];
    String? groupReason;
    for (final spId in g.spotifyIds) {
      final meta = spotifyMeta[spId];
      final title = meta?.title ?? '';
      final artists = meta?.artists ?? const <String>[];

      final query = normalizeSpotifyQuery(artists, title);
      final topHits = query.isEmpty
          ? const <Map<String, Object?>>[]
          : await searchTopHits(query: query, rbTracks: rbTracks);

      spotifyEntries.add({
        'spotify_track_id': spId,
        'spotify_title': title.isEmpty ? null : title,
        'spotify_artists': artists,
        'search_query': query.isEmpty ? null : query,
        'top_hits': topHits,
      });
    }

    // Heuristic: look at pairwise classification inside the group.
    // If any pair looks suspicious, mark group suspicious.
    final metas = [
      for (final spId in g.spotifyIds) spotifyMeta[spId],
    ];
    final reasons = <String>{};
    for (var a = 0; a < metas.length; a++) {
      for (var b = a + 1; b < metas.length; b++) {
        final r = classifyCollision(a: metas[a], b: metas[b]);
        if (r != null) reasons.add(r);
      }
    }
    groupReason = reasons.isEmpty ? null : reasons.join(',');

    final suspicious = groupReason != null;
    if (suspicious) suspiciousCount++;

    if (!includeClean && !suspicious) {
      continue;
    }

    candidates.add({
      'rekordbox_song_id': g.rbId,
      'rekordbox_title': rbTitle,
      'rekordbox_artist': rbArtist,
      'spotify_ids': g.spotifyIds,
      'spotify_entries': spotifyEntries,
      'suspicious': suspicious,
      'suspicious_reason': groupReason,
    });
  }

  // Sort: suspicious first, then larger groups first.
  candidates.sort((a, b) {
    final as = (a['suspicious'] as bool?) ?? false;
    final bs = (b['suspicious'] as bool?) ?? false;
    if (as != bs) return bs ? 1 : -1;
    final ac = (a['spotify_ids']! as List<dynamic>).length;
    final bc = (b['spotify_ids']! as List<dynamic>).length;
    if (ac != bc) return bc.compareTo(ac);
    return (a['rekordbox_song_id']?.toString() ?? '').compareTo(
      b['rekordbox_song_id']?.toString() ?? '',
    );
  });

  final payload = <String, Object?>{
    'generated_at': DateTime.now().toIso8601String(),
    'group_count_total': groups.length,
    'group_count_written': candidates.length,
    'group_count_suspicious_total': suspiciousCount,
    'include_clean': includeClean,
    'limit': limit,
    'groups': candidates,
  };

  await findIncorrectDuplicateTracksCandidatesFile().writeAsString(
    const JsonEncoder.withIndent('  ').convert(payload),
  );

  await findIncorrectDuplicateTracksReviewBriefFile().writeAsString(
    _buildReviewBrief(payload),
  );

  if (findIncorrectDuplicateTracksProposedFile().existsSync()) {
    await findIncorrectDuplicateTracksProposedFile().delete();
  }
  if (findIncorrectDuplicateTracksApprovedFile().existsSync()) {
    await findIncorrectDuplicateTracksApprovedFile().delete();
  }

  stdout
    ..writeln(findIncorrectDuplicateTracksReviewDir().path)
    ..writeln('groups=${candidates.length} suspicious_total=$suspiciousCount');
}

String _buildReviewBrief(Map<String, Object?> payload) {
  final groups = (payload['groups']! as List<dynamic>)
      .cast<Map<String, Object?>>();
  final total = payload['group_count_total'];
  final written = payload['group_count_written'];
  final suspiciousTotal = payload['group_count_suspicious_total'];

  final b = StringBuffer()
    ..writeln('# Find incorrect duplicate tracks — review')
    ..writeln()
    ..writeln('- Source DB: `${Constants.cacheDbFile.path}`')
    ..writeln('- Duplicate groups found: **$total**')
    ..writeln('- Groups written: **$written**')
    ..writeln('- Suspicious groups (heuristic): **$suspiciousTotal**')
    ..writeln()
    ..writeln(
      'A “duplicate group” means multiple Spotify IDs map to the same',
    )
    ..writeln('Rekordbox ID.')
    ..writeln('This can be OK (same track, multiple Spotify IDs), but often')
    ..writeln('indicates a')
    ..writeln('version mismatch (original vs remix/VIP/etc).')
    ..writeln()
    ..writeln('## How to fix')
    ..writeln()
    ..writeln('- If a Spotify ID is wrong:')
    ..writeln(
      '  - **remap** it to the correct Rekordbox ID (or **delete** the mapping',
    )
    ..writeln('    to force re-match next sync).')
    ..writeln(
      '- You can apply fixes by creating `approved_fixes.json` in this folder.',
    )
    ..writeln()
    ..writeln('Schema:')
    ..writeln('```json')
    ..writeln('{')
    ..writeln('  "approved_at": "ISO-8601",')
    ..writeln('  "remap": { "spotify_track_id": "rekordbox_track_id" },')
    ..writeln('  "delete": ["spotify_track_id"],')
    ..writeln('  "entries": [')
    ..writeln(
      '    { "spotify_track_id": "...", "rekordbox_track_id": "...", '
      '"action": "remap", "reason": "..." },',
    )
    ..writeln(
      '    { "spotify_track_id": "...", "action": "delete", "reason": "..." }',
    )
    ..writeln('  ]')
    ..writeln('}')
    ..writeln('```')
    ..writeln()
    ..writeln('## Groups')
    ..writeln();

  for (final group in groups) {
    final rbId = group['rekordbox_song_id'];
    final rbTitle = group['rekordbox_title'] ?? '';
    final rbArtist = group['rekordbox_artist'] ?? '';
    final suspicious = group['suspicious'] == true;
    final reason = group['suspicious_reason'];

    b
      ..writeln('---')
      ..writeln('### Rekordbox `$rbId`')
      ..writeln('- Rekordbox: $rbArtist - $rbTitle')
      ..writeln(
        '- Suspicious: **${suspicious ? 'yes' : 'no'}**'
        '${reason != null ? ' (`$reason`)' : ''}',
      )
      ..writeln('- Spotify IDs:');

    final entries = (group['spotify_entries']! as List<dynamic>)
        .cast<Map<String, Object?>>();
    for (final e in entries) {
      final spId = e['spotify_track_id'];
      final spTitle = e['spotify_title'] ?? '(no cached title)';
      final spArtists = (e['spotify_artists'] as List?)?.join(', ') ?? '';
      b.writeln('  - `$spId` — $spArtists - $spTitle');

      final hits =
          (e['top_hits'] as List<dynamic>?)?.cast<Map<String, Object?>>() ??
          const <Map<String, Object?>>[];
      if (hits.isNotEmpty) {
        final best = hits.first;
        b.writeln(
          '    - Best Rekordbox hit (${best['score']}): ${best['rb_artist']} - '
          '${best['rb_title']} [`${best['rb_track_id']}`]',
        );
      } else {
        b.writeln(
          '    - Best Rekordbox hit: (no query; missing cached Spotify '
          'metadata)',
        );
      }
    }
    b.writeln();
  }

  return b.toString();
}
