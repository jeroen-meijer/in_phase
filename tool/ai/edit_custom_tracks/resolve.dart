import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:in_phase/src/cli/cli.dart';
import 'package:in_phase/src/database/database.exports.dart';

import 'lib.dart';

/// Resolves a custom_tracks edit; does **not** write sync_config.yaml.
///
/// The agent (or user) must surgically insert the printed YAML so comments
/// and formatting in ~/.in_phase/sync_config.yaml are preserved.
/// `SyncConfig.write` / `yamlEncode` would wipe them.
///
/// Examples:
///   dart run tool/ai/edit_custom_tracks/resolve.dart \
///     --playlist 'SET_2026-07-26_LIQ-FST' \
///     --add 'I Want You' \
///     --after 'https://open.spotify.com/track/2PnqL2dcsaYQjHEkcKQC5m'
///
///   dart run tool/ai/edit_custom_tracks/resolve.dart \
///     -p 5VHb3WLxXDmyhuno4RFYsT -a 77621222 --replace 124269976
Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'playlist',
      abbr: 'p',
      help: 'Spotify playlist id/URI/URL, or cached playlist name (fuzzy).',
      valueHelp: 'NAME|ID',
    )
    ..addOption(
      'add',
      abbr: 'a',
      help:
          'Track to insert/replace with: Rekordbox id, Spotify track '
          'id/URI/URL (via sync_track_mappings), or title (fuzzy). '
          'Must already exist in Rekordbox.',
      valueHelp: 'RB_ID|SPOTIFY|NAME',
    )
    ..addOption(
      'artist',
      help:
          'Optional artist hint for --add / --search name resolution '
          '(e.g. "Unknown Artist").',
      valueHelp: 'NAME',
    )
    ..addOption(
      'type',
      abbr: 't',
      help: 'Custom track operation.',
      allowed: ['insert', 'replace'],
      defaultsTo: 'insert',
    )
    ..addOption(
      'after',
      help:
          'Anchor: insert 1 slot after this track (Rekordbox id, Spotify '
          'id/URL, or name in the playlist). Implies type=insert.',
      valueHelp: 'RB_ID|SPOTIFY|NAME',
    )
    ..addOption(
      'before',
      help:
          'Anchor: insert 1 slot before this track. Implies type=insert '
          'and index=-1.',
      valueHelp: 'RB_ID|SPOTIFY|NAME',
    )
    ..addOption(
      'replace',
      help:
          'Anchor: replace this track with --add. Implies type=replace '
          '(Rekordbox id, Spotify id/URL, or name).',
      valueHelp: 'RB_ID|SPOTIFY|NAME',
    )
    ..addOption(
      'index',
      help: '0-based index (absolute, or offset when used with an anchor).',
      valueHelp: 'N',
    )
    ..addOption(
      'position',
      help: '1-based absolute position (mutually exclusive with --index).',
      valueHelp: 'N',
    )
    ..addOption(
      'search',
      help:
          'List top Rekordbox library matches for a query (no config edit). '
          'Useful when --add / --after name resolution fails.',
      valueHelp: 'QUERY',
    )
    ..addOption(
      'search-limit',
      help: 'Max hits for --search (default 15).',
      defaultsTo: '15',
    )
    ..addFlag(
      'human',
      help: 'Print a human-readable YAML snippet instead of JSON.',
      negatable: false,
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage.');

  final results = parser.parse(args);
  if (results['help'] == true) {
    stdout
      ..writeln(
        'Resolve a custom_tracks entry (does not write sync_config.yaml).',
      )
      ..writeln()
      ..writeln(parser.usage);
    return;
  }

  final searchQuery = results['search'] as String?;
  final artistHint = results['artist'] as String?;
  if (searchQuery != null) {
    final limit = int.parse(results['search-limit'] as String);
    final effectiveQuery = artistHint == null || artistHint.trim().isEmpty
        ? searchQuery
        : '$artistHint $searchQuery';
    await runWithCliDependencies(() async {
      stderr.writeln('Loading Rekordbox library...');
      final rbTracks = await loadRekordboxTracks();
      final hits = searchRekordboxTracks(
        query: effectiveQuery,
        rbTracks: rbTracks,
        limit: limit,
      );
      stdout.writeln(
        const JsonEncoder.withIndent('  ').convert({
          'query': searchQuery,
          'artist_hint': artistHint,
          'effective_query': effectiveQuery,
          'threshold': rbNameMatchThreshold,
          'hits': [
            for (final h in hits)
              {
                'rekordbox_id': h.rekordboxId,
                'title': h.title,
                'artist': h.artist,
                'score': h.score,
                'would_accept': (h.score ?? 0) >= rbNameMatchThreshold,
              },
          ],
        }),
      );
      if (hits.isEmpty) {
        stderr.writeln('No hits.');
        exitCode = 1;
      }
    });
    return;
  }

  final playlistQuery = results['playlist'] as String?;
  final addQuery = results['add'] as String?;
  if (playlistQuery == null || addQuery == null) {
    stderr
      ..writeln('Required: --playlist and --add  (or --search QUERY)')
      ..writeln(parser.usage);
    exitCode = 64;
    return;
  }

  final after = results['after'] as String?;
  final before = results['before'] as String?;
  final replace = results['replace'] as String?;
  final anchorCount = [after, before, replace].whereType<String>().length;
  if (anchorCount > 1) {
    stderr.writeln('Use only one of --after, --before, --replace.');
    exitCode = 64;
    return;
  }

  final indexRaw = results['index'] as String?;
  final positionRaw = results['position'] as String?;
  if (indexRaw != null && positionRaw != null) {
    stderr.writeln('Use only one of --index and --position.');
    exitCode = 64;
    return;
  }

  var type = results['type'] as String;
  String? anchorQuery;
  final indexFromArgs = indexRaw == null ? null : int.parse(indexRaw);
  var index = indexFromArgs;
  final position = positionRaw == null ? null : int.parse(positionRaw);

  if (after != null) {
    type = 'insert';
    anchorQuery = after;
    // Default offset with a target is already 0 ("1 after"); omit index.
  } else if (before != null) {
    type = 'insert';
    anchorQuery = before;
    index ??= -1;
  } else if (replace != null) {
    type = 'replace';
    anchorQuery = replace;
  }

  if (type == 'replace' &&
      anchorQuery == null &&
      index == null &&
      position == null) {
    stderr.writeln(
      'type=replace requires --replace <anchor>, --index, or --position.',
    );
    exitCode = 64;
    return;
  }

  final configFile = defaultSyncConfigFile();
  if (!configFile.existsSync()) {
    stderr.writeln('Config not found: ${configFile.path}');
    exitCode = 1;
    return;
  }

  final human = results['human'] == true;

  await runWithCliDependencies(() async {
    stderr.writeln('Loading sync cache...');
    final cacheDb = db();
    stderr.writeln('Loading Rekordbox library...');
    final rbTracks = await loadRekordboxTracks();

    try {
      final playlist = await resolvePlaylist(
        query: playlistQuery,
        cacheDb: cacheDb,
      );
      stderr.writeln('Playlist: ${playlist.label} [${playlist.source}]');

      final addEffective = artistHint == null || artistHint.trim().isEmpty
          ? addQuery
          : '$addQuery by $artistHint';
      final track = await resolveAddTrack(
        query: addEffective,
        rbTracks: rbTracks,
        cacheDb: cacheDb,
        artistHint: artistHint,
      );
      stderr.writeln(
        'Add: ${track.display} [${track.rekordboxId}] (${track.source})',
      );

      ResolvedTrack? target;
      if (anchorQuery != null) {
        target = await resolveAnchorTrack(
          query: anchorQuery,
          playlistId: playlist.id,
          cacheDb: cacheDb,
          rbTracks: rbTracks,
        );
        final sp = target.spotifyTrackId;
        stderr.writeln(
          'Anchor: ${target.display} [${target.rekordboxId}] '
          '(${target.source}${sp != null ? ', sp:$sp' : ''})',
        );
      }

      final spec = CustomTrackSpec(
        playlist: playlist,
        track: track,
        type: type,
        target: target,
        index: index,
        position: position,
      );
      final entryYaml = formatCustomTrackYaml(spec);

      if (human) {
        stdout
          ..writeln('config: ${configFile.path}')
          ..writeln('playlist_id: ${playlist.id}')
          ..writeln('playlist_name: ${playlist.name}')
          ..writeln('--- YAML entry (insert under this playlist) ---')
          ..write(entryYaml)
          ..writeln('------------------------------------------------');
      } else {
        stdout.writeln(
          const JsonEncoder.withIndent('  ').convert({
            'config_path': configFile.path,
            'playlist': {
              'id': playlist.id,
              'name': playlist.name,
              'source': playlist.source,
            },
            'track': {
              'rekordbox_id': track.rekordboxId,
              'title': track.title,
              'artist': track.artist,
              'source': track.source,
              'spotify_track_id': track.spotifyTrackId,
              'score': track.score,
            },
            'type': type,
            if (target != null)
              'target': {
                'rekordbox_id': target.rekordboxId,
                'title': target.title,
                'artist': target.artist,
                'source': target.source,
                'spotify_track_id': target.spotifyTrackId,
                'score': target.score,
              },
            'index': index,
            'position': position,
            'yaml_entry': entryYaml,
            'instruction':
                'Do not rewrite sync_config.yaml via yamlEncode. Surgically '
                'insert yaml_entry under custom_tracks[<playlist.id>] '
                '(create the playlist key with a # name comment if missing). '
                'Match existing comment style.',
          }),
        );
      }
    } on Object catch (e, st) {
      stderr
        ..writeln('Error: $e')
        ..writeln(st);
      exitCode = 1;
    }
  });
}
