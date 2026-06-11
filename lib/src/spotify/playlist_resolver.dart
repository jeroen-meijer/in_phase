import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:glob/glob.dart';
import 'package:in_phase/src/logger/logger.dart';
import 'package:in_phase/src/spotify/types.dart';
import 'package:spotify/spotify.dart';

/// Minimum fuzzy match score for playlist name resolution.
const playlistFuzzyMatchThreshold = 80;

/// CLI/config token for Liked Songs when `allowLikes` is enabled on playlist
/// resolution.
const likedSongsPlaylistTarget = 'likes';

/// Returns true when [input] is the Liked Songs target token.
bool isLikedSongsTarget(String input) =>
    input.trim().toLowerCase() == likedSongsPlaylistTarget;

/// Resolved Spotify import target: a playlist or Liked Songs.
sealed class ResolvedSpotifyTarget {
  const ResolvedSpotifyTarget();
}

/// Import target is the user's Liked Songs library.
final class LikedSongsSpotifyTarget extends ResolvedSpotifyTarget {
  const LikedSongsSpotifyTarget();
}

/// Import target is a specific Spotify playlist.
final class PlaylistSpotifyTarget extends ResolvedSpotifyTarget {
  const PlaylistSpotifyTarget(this.playlist);

  final PlaylistSimple playlist;
}

/// Returns true when [input] contains glob pattern characters.
bool isPlaylistGlobPattern(String input) {
  return input.contains('*') ||
      input.contains('?') ||
      input.contains('[') ||
      input.contains(']');
}

int _playlistNameScore(String input, String playlistName) {
  return tokenSortRatio(
    input.toLowerCase().trim(),
    playlistName.toLowerCase().trim(),
  );
}

/// Resolves a single playlist target from [input].
///
/// Resolution order: likes (if allowed) → ID/URI/URL → glob (if allowed) →
/// exact name → fuzzy name (≥ [playlistFuzzyMatchThreshold], unique winner).
Future<ResolvedSpotifyTarget?> resolvePlaylistTarget({
  required SpotifyApi api,
  required String input,
  required List<PlaylistSimple> userPlaylists,
  bool allowLikes = false,
  bool allowGlobs = false,
}) async {
  if (allowLikes && isLikedSongsTarget(input)) {
    log.debug('    ✅ Resolved target as Liked Songs');
    return const LikedSongsSpotifyTarget();
  }

  final playlistId = SpotifyPlaylistId.tryExtract(input);
  if (playlistId != null) {
    try {
      final playlist = await api.playlists.get(playlistId);
      log.debug(
        '    ✅ Resolved target by ID: "$input" → "${playlist.name}"',
      );
      return PlaylistSpotifyTarget(playlist);
    } catch (e) {
      log
        ..error('    ❌ Could not fetch target playlist by ID "$input": $e')
        ..error(
          '    💡 Make sure the playlist ID is correct and you have access '
          'to it (you own it or have collaborative edit access).',
        );
      return null;
    }
  }

  if (allowGlobs && isPlaylistGlobPattern(input)) {
    log.error(
      '    ❌ Glob patterns are not supported for single playlist targets: '
      '"$input"',
    );
    return null;
  }

  final exactMatches = userPlaylists.where((p) => p.name == input).toList();
  if (exactMatches.length > 1) {
    log.error(
      '    ❌ Target playlist "$input" matched ${exactMatches.length} '
      'playlists:',
    );
    for (final match in exactMatches) {
      log.error('      - "${match.name}" (ID: ${match.id})');
    }
    log.error(
      '    💡 Please use a playlist ID, URI, or share URL instead to '
      'uniquely identify the target playlist.',
    );
    return null;
  }
  if (exactMatches.length == 1) {
    log.debug('    ✅ Resolved target by exact name: "$input"');
    return PlaylistSpotifyTarget(exactMatches.first);
  }

  final fuzzyMatches = <({PlaylistSimple playlist, int score})>[];
  for (final playlist in userPlaylists) {
    final name = playlist.name;
    if (name == null || name.isEmpty) continue;
    final score = _playlistNameScore(input, name);
    if (score >= playlistFuzzyMatchThreshold) {
      fuzzyMatches.add((playlist: playlist, score: score));
    }
  }

  if (fuzzyMatches.isEmpty) {
    log
      ..error('    ❌ Target playlist "$input" not found in your playlists.')
      ..error(
        '    💡 Use a playlist ID, URI, share URL, or a name with at least '
        '$playlistFuzzyMatchThreshold% fuzzy match.',
      );
    return null;
  }

  fuzzyMatches.sort((a, b) => b.score.compareTo(a.score));
  final best = fuzzyMatches.first;
  final tied = fuzzyMatches
      .where((m) => m.score == best.score)
      .map((m) => m.playlist)
      .toList();

  if (tied.length > 1) {
    log.error(
      '    ❌ Target playlist "$input" fuzzy-matched ${tied.length} '
      'playlists at score ${best.score}:',
    );
    for (final match in tied) {
      log.error('      - "${match.name}" (ID: ${match.id})');
    }
    log.error(
      '    💡 Please use a playlist ID, URI, or share URL instead.',
    );
    return null;
  }

  log.debug(
    '    ✅ Resolved target by fuzzy name: "$input" → '
    '"${best.playlist.name}" (score: ${best.score})',
  );
  return PlaylistSpotifyTarget(best.playlist);
}

/// Resolves multiple source playlists from [input].
///
/// Supports ID/URI/URL, globs (if [allowGlobs]), exact names, and fuzzy names.
Future<List<PlaylistSimple>> resolvePlaylistSources({
  required SpotifyApi api,
  required String input,
  required List<PlaylistSimple> userPlaylists,
  bool allowGlobs = true,
}) async {
  final playlistId = SpotifyPlaylistId.tryExtract(input);
  if (playlistId != null) {
    try {
      final playlist = await api.playlists.get(playlistId);
      log.debug('    ✅ Resolved ID: "$input" → "${playlist.name}"');
      return [playlist];
    } catch (e) {
      log.warning('    ⚠️  Could not fetch playlist by ID "$input": $e');
      return [];
    }
  }

  if (allowGlobs && isPlaylistGlobPattern(input)) {
    final glob = Glob(input);
    final matches = userPlaylists
        .where((p) => glob.matches(p.name ?? ''))
        .toList();

    if (matches.isEmpty) {
      log.warning('    ⚠️  Glob "$input" matched 0 playlists');
    } else {
      log.info('    ✅ Glob "$input" matched ${matches.length} playlist(s)');
    }
    return matches;
  }

  final exactMatches = userPlaylists.where((p) => p.name == input).toList();
  if (exactMatches.length > 1) {
    log.error(
      '    ❌ Source playlist "$input" matched ${exactMatches.length} '
      'playlists:',
    );
    for (final match in exactMatches) {
      log.error('      - "${match.name}" (ID: ${match.id})');
    }
    log.error(
      '    💡 Please use a playlist ID, URI, or share URL instead.',
    );
    return [];
  }
  if (exactMatches.length == 1) {
    log.debug('    ✅ Resolved source by exact name: "$input"');
    return exactMatches;
  }

  final fuzzyMatches = <({PlaylistSimple playlist, int score})>[];
  for (final playlist in userPlaylists) {
    final name = playlist.name;
    if (name == null || name.isEmpty) continue;
    final score = _playlistNameScore(input, name);
    if (score >= playlistFuzzyMatchThreshold) {
      fuzzyMatches.add((playlist: playlist, score: score));
    }
  }

  if (fuzzyMatches.isEmpty) {
    log.warning('    ⚠️  Source "$input" matched 0 playlists');
    return [];
  }

  fuzzyMatches.sort((a, b) => b.score.compareTo(a.score));
  final bestScore = fuzzyMatches.first.score;
  final winners = fuzzyMatches
      .where((m) => m.score == bestScore)
      .map((m) => m.playlist)
      .toList();

  if (winners.length > 1) {
    log.error(
      '    ❌ Source playlist "$input" fuzzy-matched ${winners.length} '
      'playlists at score $bestScore:',
    );
    for (final match in winners) {
      log.error('      - "${match.name}" (ID: ${match.id})');
    }
    return [];
  }

  log.debug(
    '    ✅ Resolved source by fuzzy name: "$input" → '
    '"${winners.first.name}" (score: $bestScore)',
  );
  return winners;
}
