import 'dart:convert';
import 'dart:io';

import 'package:in_phase/src/misc/fuzzy_search.dart';

/// iTunes Store URL helpers and lightweight lookup.
class ItunesStore {
  /// Looks up a track URL in the iTunes Search API and returns an `itmss://`
  /// link when possible.
  static Future<String?> lookupTrackUrl({
    required String artist,
    required String title,
  }) async {
    final client = HttpClient();
    try {
      final term = Uri.encodeQueryComponent('$artist $title');
      final uri = Uri.parse(
        'https://itunes.apple.com/search?media=music&entity=song&limit=10&term=$term',
      );
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        return null;
      }

      final body = await utf8.decoder.bind(response).join();
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;
      final results = decoded['results'];
      if (results is! List || results.isEmpty) return null;

      final bestWebUrl = bestTrackWebUrl(
        artist: artist,
        title: title,
        rawResults: results,
      );
      if (bestWebUrl == null) return null;
      return toStoreAppUrl(bestWebUrl);
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  /// Converts Apple Music / iTunes web URLs into `itmss://` Store links.
  ///
  /// If conversion is not possible, returns the original URL.
  static String toStoreAppUrl(String url) {
    final parsed = Uri.tryParse(url);
    if (parsed == null) return url;

    final trackIdFromQuery = parsed.queryParameters['i'];
    final trackIdFromPath = _extractTrackIdFromPath(parsed.pathSegments);
    final trackId = trackIdFromQuery ?? trackIdFromPath;

    final host = parsed.host.replaceFirst(
      'music.apple.com',
      'itunes.apple.com',
    );
    if (trackId == null || host.isEmpty) {
      return url;
    }

    return Uri(
      scheme: 'itmss',
      host: host,
      path: parsed.path,
      queryParameters: {'app': 'itunes', 'i': trackId},
      fragment: 'songs',
    ).toString();
  }

  /// Picks the iTunes Search API result that best matches [artist] and
  /// [title], or null when no result matches both.
  ///
  /// A field matches when the normalized strings are equal or one contains
  /// the other; equal matches rank higher.
  static String? bestTrackWebUrl({
    required String artist,
    required String title,
    required List<dynamic> rawResults,
  }) {
    final normalizedArtist = normalizeForMatch(artist);
    final normalizedTitle = normalizeForMatch(title);

    int? fieldScore(String wanted, String candidate) {
      if (candidate.isEmpty) return null;
      if (candidate == wanted) return 2;
      if (candidate.contains(wanted) || wanted.contains(candidate)) return 1;
      return null;
    }

    var bestScore = 0;
    String? bestUrl;
    for (final result in rawResults.whereType<Map<String, dynamic>>()) {
      final trackViewUrl = result['trackViewUrl'] as String?;
      if (trackViewUrl == null || trackViewUrl.isEmpty) continue;

      final artistScore = fieldScore(
        normalizedArtist,
        normalizeForMatch((result['artistName'] as String?) ?? ''),
      );
      final titleScore = fieldScore(
        normalizedTitle,
        normalizeForMatch((result['trackName'] as String?) ?? ''),
      );
      if (artistScore == null || titleScore == null) continue;

      final score = artistScore + titleScore;
      if (score > bestScore) {
        bestScore = score;
        bestUrl = trackViewUrl;
      }
    }

    return bestUrl;
  }

  static String? _extractTrackIdFromPath(List<String> segments) {
    final idSegment = segments.cast<String?>().firstWhere(
      (segment) => segment != null && segment.startsWith('id'),
      orElse: () => null,
    );
    if (idSegment == null) return null;
    final value = idSegment.replaceFirst('id', '');
    return value.isEmpty ? null : value;
  }
}
