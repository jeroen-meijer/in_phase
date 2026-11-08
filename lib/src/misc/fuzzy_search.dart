import 'dart:isolate';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:rekorddart/rekorddart.dart';

typedef RbArtistAndSong = ({DjmdArtistData? artist, DjmdContentData song});

final _nonWordCharacters = RegExp(r'[^\w\s]');
final _whitespace = RegExp(r'\s+');

/// Lowercases [input], turns punctuation into spaces and collapses
/// whitespace, so `S.P.Y - Rock Da House` and `s p y rock da house` compare
/// equal.
String normalizeForMatch(String input) => input
    .toLowerCase()
    .replaceAll(_nonWordCharacters, ' ')
    .replaceAll(_whitespace, ' ')
    .trim();

/// Normalized `artists title` string for fuzzy matching.
String normalizeQuery(List<String> artists, String title) =>
    normalizeForMatch('${artists.join(' ')} $title');

/// Represents a fuzzy match result with a score.
class FuzzyFindMatch<T> {
  const FuzzyFindMatch({
    required this.value,
    required this.score,
  });

  final T value;
  final int score;
}

/// Rekordbox songs prepared for many fuzzy lookups.
///
/// Normalizes every song once; each lookup only sends the normalized strings
/// to the worker isolates.
class RekordboxMatchIndex {
  RekordboxMatchIndex(this.songs)
    : _targets = [
        for (final song in songs)
          normalizeQuery([song.artist?.name ?? ''], song.song.title ?? ''),
      ];

  final List<RbArtistAndSong> songs;
  final List<String> _targets;

  /// The song that best matches [artists] and [title] by token sort ratio,
  /// or null when the library is empty.
  Future<FuzzyFindMatch<RbArtistAndSong>?> bestMatch(
    List<String> artists,
    String title, {
    int threads = 4,
  }) async {
    if (_targets.isEmpty) {
      return null;
    }

    final query = normalizeQuery(artists, title);
    final chunkSize = (_targets.length / threads).ceil();
    final results = await Future.wait([
      for (var start = 0; start < _targets.length; start += chunkSize)
        _bestTargetInIsolate(
          query,
          _targets.sublist(start, min(start + chunkSize, _targets.length)),
          start,
        ),
    ]);

    final best = maxBy(results, (result) => result.score)!;
    return FuzzyFindMatch(value: songs[best.index], score: best.score);
  }
}

/// Top-level so the isolate closure only captures its arguments.
Future<({int index, int score})> _bestTargetInIsolate(
  String query,
  List<String> targets,
  int offset,
) => Isolate.run(() {
  var best = (index: offset, score: -1);
  for (final (i, target) in targets.indexed) {
    final score = tokenSortRatio(query, target);
    if (score > best.score) {
      best = (index: offset + i, score: score);
    }
  }
  return best;
});

/// Finds multiple fuzzy matches for a query, sorted by score descending.
///
/// Returns all matches above the threshold, sorted by score.
Future<List<FuzzyFindMatch<RbArtistAndSong>>> findFuzzyTrackMatches({
  required String query,
  required List<RbArtistAndSong> tracks,
  int threshold = 0,
  int maxResults = 10,
}) async {
  if (tracks.isEmpty) {
    return [];
  }

  final normalizedQuery = normalizeForMatch(query);
  final matches = <FuzzyFindMatch<RbArtistAndSong>>[];

  // Split query into individual terms for multi-term matching
  final queryTerms = normalizedQuery
      .split(RegExp(r'\s+'))
      .where((term) => term.isNotEmpty)
      .toList();
  final isMultiTermQuery = queryTerms.length > 1;

  for (final track in tracks) {
    final target = normalizeQuery(
      [track.artist?.name ?? ''],
      track.song.title ?? '',
    );
    var score = tokenSortRatio(normalizedQuery, target);

    // Boost score significantly if query appears as exact substring
    if (target.contains(normalizedQuery)) {
      score = (score + 100).clamp(0, 100);
    } else if (isMultiTermQuery) {
      // For multi-term queries, boost tracks that contain all terms
      final allTermsPresent = queryTerms.every(target.contains);
      if (allTermsPresent) {
        // Boost tracks that contain all query terms (+30 points)
        score = (score + 30).clamp(0, 100);

        // Additional boost if terms appear in order (+20 points)
        final targetWords = target.split(RegExp(r'\s+'));
        var termsInOrder = true;
        var lastIndex = -1;
        for (final term in queryTerms) {
          final index = targetWords.indexWhere((word) => word.contains(term));
          if (index == -1 || index < lastIndex) {
            termsInOrder = false;
            break;
          }
          lastIndex = index;
        }
        if (termsInOrder) {
          score = (score + 20).clamp(0, 100);
        }
      }
    }

    if (score >= threshold) {
      matches.add(
        FuzzyFindMatch(
          value: track,
          score: score,
        ),
      );
    }
  }

  // Sort by score descending and limit results
  matches.sort((a, b) => b.score.compareTo(a.score));
  return matches.take(maxResults).toList();
}
