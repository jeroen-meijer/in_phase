import 'dart:convert';
import 'dart:io';

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

      final bestWebUrl = _selectBestTrackWebUrl(
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

  static String? _selectBestTrackWebUrl({
    required String artist,
    required String title,
    required List<dynamic> rawResults,
  }) {
    final normalizedArtist = _normalizeForMatch(artist);
    final normalizedTitle = _normalizeForMatch(title);

    var bestScore = -1;
    String? bestUrl;

    for (final result in rawResults) {
      if (result is! Map<String, dynamic>) continue;

      final trackViewUrl = result['trackViewUrl'] as String?;
      if (trackViewUrl == null || trackViewUrl.isEmpty) continue;

      final candidateArtist = _normalizeForMatch(
        (result['artistName'] as String?) ?? '',
      );
      final candidateTitle = _normalizeForMatch(
        (result['trackName'] as String?) ?? '',
      );

      var score = 0;
      if (candidateArtist == normalizedArtist) score += 3;
      if (candidateTitle == normalizedTitle) score += 3;
      if (candidateArtist.contains(normalizedArtist) ||
          normalizedArtist.contains(candidateArtist)) {
        score += 1;
      }
      if (candidateTitle.contains(normalizedTitle) ||
          normalizedTitle.contains(candidateTitle)) {
        score += 1;
      }

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

  static String _normalizeForMatch(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
