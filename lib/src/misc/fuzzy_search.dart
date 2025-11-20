import 'dart:isolate';

import 'package:collection/collection.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:rekorddart/rekorddart.dart';

typedef RbArtistAndSong = ({DjmdArtistData? artist, DjmdContentData song});

/// Normalizes a query string for fuzzy matching.
///
/// Combines artist names and title, converts to lowercase, removes
/// punctuation, and normalizes whitespace.
String normalizeQuery(List<String> artists, String title) {
  return '${artists.join(' ')} $title'
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Represents a fuzzy match result with a score.
class FuzzyFindMatch<T> {
  const FuzzyFindMatch({
    required this.value,
    required this.score,
  });

  final T value;
  final int score;
}

/// Finds the best fuzzy match for a query against a list of tracks.
///
/// Uses token sort ratio for matching. Supports multi-threaded search
/// for large libraries.
Future<FuzzyFindMatch<RbArtistAndSong>> findFuzzyTrackMatch({
  required String query,
  required List<RbArtistAndSong> tracks,
  int threads = 4,
}) async {
  if (tracks.isEmpty) {
    throw Exception('No tracks to search');
  }

  FuzzyFindMatch<RbArtistAndSong> findFuzzyMatchForChunk(
    List<RbArtistAndSong> tracks,
  ) {
    final normalizedQuery = query.toLowerCase().trim();

    var bestScore = 0;
    var bestMatch = tracks.first;

    for (final track in tracks) {
      final target = normalizeQuery(
        [track.artist?.name ?? ''],
        track.song.title ?? '',
      );
      final score = tokenSortRatio(normalizedQuery, target);

      if (score > bestScore) {
        bestScore = score;
        bestMatch = track;
      }
    }

    return FuzzyFindMatch(value: bestMatch, score: bestScore);
  }

  if (threads == 1) {
    return findFuzzyMatchForChunk(tracks);
  }

  final itemsPerThread = (tracks.length / threads).ceil();
  final chunks = tracks.slices(itemsPerThread);

  final results = await Future.wait([
    for (final chunk in chunks)
      Isolate.run(() => findFuzzyMatchForChunk(chunk)),
  ]);

  return maxBy<FuzzyFindMatch<RbArtistAndSong>, int>(
    results,
    (e) => e.score,
  )!;
}

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

  final normalizedQuery = query.toLowerCase().trim();
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
      final allTermsPresent = queryTerms.every((term) => target.contains(term));
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
