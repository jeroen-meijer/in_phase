import 'dart:io';
import 'dart:math' as math;

import 'package:dcli/dcli.dart';
import 'package:in_phase/src/entities/entities.dart';
import 'package:in_phase/src/logger/logger.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:in_phase/src/spotify/spotify.dart';
import 'package:io/io.dart';
import 'package:rekorddart/rekorddart.dart';
import 'package:spotify/spotify.dart' show SpotifyApi, SpotifyException;
import 'package:yaml/yaml.dart';

/// Validates the sync config file: presence, YAML, schema, and when
/// `custom_tracks` is non-empty, Spotify playlists and Rekordbox tracks/files.
///
/// Invoked when argv is `sync validate` (routed by the parent `sync` command).
/// Not an `args` subcommand: branch commands cannot also run as leaf commands.
Future<int> runSyncValidate({String? customConfigPath}) async {
  final usesCustomConfigPath = customConfigPath != null;

  final configFile = usesCustomConfigPath
      ? resolveConfigPath(customConfigPath)
      : Constants.syncConfigFile;

  log.info('Validating sync config: ${configFile.path}');

  // ignore: avoid_slow_async_io
  if (!await configFile.exists()) {
    log.error('Sync config file not found.');
    return ExitCode.config.code;
  }

  final content = await configFile.readAsString();

  late final SyncConfig syncConfig;
  try {
    syncConfig = SyncConfig.fromYamlString(content);
  } on YamlException catch (e) {
    log.error('Invalid YAML: $e');
    return ExitCode.data.code;
  } on FormatException catch (e) {
    log.error('Invalid YAML: $e');
    return ExitCode.data.code;
  } on Exception catch (e) {
    log.error('Invalid sync config: $e');
    return ExitCode.data.code;
  }

  log.info('YAML and sync config schema are valid.');

  if (syncConfig.customTracks.isEmpty) {
    log.info(
      'No custom_tracks configured; skipping Spotify and Rekordbox checks.',
    );
    return ExitCode.success.code;
  }

  return withTeardown((addTeardown) async {
    final api = await spotifyLogin();
    // ignore: invalid_use_of_visible_for_testing_member
    addTeardown(() async => (await api.client).close());

    final rbDb = await RekordboxDatabase.connect();
    addTeardown(rbDb.close);

    final playlistEntries = syncConfig.customTracks.entries.toList();
    final requestPool = RequestPool(
      maxConcurrent: math.min(16, math.max(1, playlistEntries.length)),
      maxRetries: 0,
    );
    addTeardown(() async => requestPool.clear());

    final spotifyResults = await Future.wait([
      for (final entry in playlistEntries)
        _validateSpotifyPlaylist(
          requestPool: requestPool,
          api: api,
          entry: entry,
        ),
    ]);

    final spotifyFailures = spotifyResults.where((r) => !r.ok).toList();
    final spotifyOk = spotifyResults.length - spotifyFailures.length;

    for (final r in spotifyResults) {
      if (r.rawKey != r.normalizedId) {
        log.info(
          'Playlist key "${r.rawKey}" normalized to '
          '"${r.normalizedId}" for Spotify.',
        );
      }
    }

    log.info(
      '${green('✓')} Spotify: '
      '$spotifyOk/${playlistEntries.length} playlist(s) reachable.',
    );

    final rbMissingIds = <RekordboxSongId>[];
    final rbNoPathIds = <RekordboxSongId>[];
    final rbMissingFiles = <({RekordboxSongId id, String path})>[];

    final rbIds = syncConfig.referencedCustomTrackRekordboxIds;

    for (final rbId in rbIds) {
      final song = await (rbDb.select(
        rbDb.djmdContent,
      )..where((c) => c.id.equals(rbId))).getSingleOrNull();

      if (song == null) {
        rbMissingIds.add(rbId);
        continue;
      }

      final audioPath = rekordboxAudioPath(song);
      if (audioPath == null) {
        rbNoPathIds.add(rbId);
        continue;
      }

      if (!File(audioPath).existsSync()) {
        rbMissingFiles.add((id: rbId, path: audioPath));
      }
    }

    final rekordboxOk =
        rbIds.length -
        rbMissingIds.length -
        rbNoPathIds.length -
        rbMissingFiles.length;

    if (rbIds.isNotEmpty) {
      log.info(
        '${green('✓')} Rekordbox: '
        '$rekordboxOk/${rbIds.length} ID(s) with audio on disk.',
      );
    }

    final issueCount =
        spotifyFailures.length +
        rbMissingIds.length +
        rbNoPathIds.length +
        rbMissingFiles.length;

    if (issueCount > 0) {
      _printValidationIssues(
        spotifyFailures: spotifyFailures,
        rbMissingIds: rbMissingIds,
        rbNoPathIds: rbNoPathIds,
        rbMissingFiles: rbMissingFiles,
      );
      log.error(
        'Validation finished with $issueCount issue(s). '
        'See details above.',
      );
      return ExitCode.data.code;
    }

    log.info('Validation successful.');
    return ExitCode.success.code;
  });
}

/// Result of checking one Spotify playlist referenced in `custom_tracks`.
class _SpotifyPlaylistCheck {
  _SpotifyPlaylistCheck({
    required this.ok,
    required this.rawKey,
    required this.normalizedId,
    this.errorDetail,
  });

  final bool ok;
  final SpotifyPlaylistId rawKey;
  final SpotifyPlaylistId normalizedId;
  final String? errorDetail;
}

Future<_SpotifyPlaylistCheck> _validateSpotifyPlaylist({
  required RequestPool requestPool,
  required SpotifyApi api,
  required MapEntry<SpotifyPlaylistId, List<CustomTrack>> entry,
}) async {
  final rawPlaylistId = entry.key;
  final normalizedId =
      SpotifyPlaylistId.tryExtract(rawPlaylistId) ?? rawPlaylistId;

  try {
    await requestPool.request(
      () => api.playlists.get(normalizedId),
      identifier: SpotifyCacheIdentifier.playlist(normalizedId),
      ttl: Duration.zero,
    );
    return _SpotifyPlaylistCheck(
      ok: true,
      rawKey: rawPlaylistId,
      normalizedId: normalizedId,
    );
  } on SpotifyException catch (e) {
    return _SpotifyPlaylistCheck(
      ok: false,
      rawKey: rawPlaylistId,
      normalizedId: normalizedId,
      errorDetail: e.message ?? e.toString(),
    );
  } catch (e) {
    return _SpotifyPlaylistCheck(
      ok: false,
      rawKey: rawPlaylistId,
      normalizedId: normalizedId,
      errorDetail: e.toString(),
    );
  }
}

void _printValidationIssues({
  required List<_SpotifyPlaylistCheck> spotifyFailures,
  required List<RekordboxSongId> rbMissingIds,
  required List<RekordboxSongId> rbNoPathIds,
  required List<({RekordboxSongId id, String path})> rbMissingFiles,
}) {
  final total =
      spotifyFailures.length +
      rbMissingIds.length +
      rbNoPathIds.length +
      rbMissingFiles.length;
  final buf = StringBuffer()
    ..writeln()
    ..writeln(
      '${bold(orange('Validation issues'))} '
      '${grey('($total)', level: 0)}',
    );

  if (spotifyFailures.isNotEmpty) {
    buf
      ..writeln()
      ..writeln(bold('Spotify (${spotifyFailures.length})'));
    for (final f in spotifyFailures) {
      buf.writeln(
        '  ${red('•')} ${cyan(f.normalizedId)} — '
        '${f.errorDetail ?? 'unknown error'}',
      );
    }
  }

  if (rbMissingIds.isNotEmpty) {
    buf
      ..writeln()
      ..writeln(bold('Rekordbox ID not in library (${rbMissingIds.length})'));
    for (final id in rbMissingIds) {
      buf.writeln('  ${red('•')} ${cyan(id)}');
    }
  }

  if (rbNoPathIds.isNotEmpty) {
    buf
      ..writeln()
      ..writeln(
        bold('Rekordbox track has no file path (${rbNoPathIds.length})'),
      );
    for (final id in rbNoPathIds) {
      buf.writeln(
        '  ${red('•')} ${cyan(id)} '
        '${grey('(FolderPath / file name missing)', level: 0)}',
      );
    }
  }

  if (rbMissingFiles.isNotEmpty) {
    buf
      ..writeln()
      ..writeln(bold('Audio file not on disk (${rbMissingFiles.length})'));
    for (final m in rbMissingFiles) {
      buf
        ..writeln('  ${red('•')} ${cyan(m.id)}')
        ..writeln('    ${_truncateForTerminal(m.path)}');
    }
  }

  buf.writeln();
  log.raw(buf.toString());
}

/// Shortens long paths for readable terminal output (middle ellipsis).
String _truncateForTerminal(String path, {int maxChars = 100}) {
  if (path.length <= maxChars) {
    return grey(path, level: 0);
  }
  final keep = maxChars ~/ 2 - 2;
  return grey(
    '${path.substring(0, keep)}…${path.substring(path.length - keep)}',
    level: 0,
  );
}
