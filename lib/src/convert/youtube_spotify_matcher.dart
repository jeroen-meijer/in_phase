import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:in_phase/src/convert/youtube_video_ref.dart';
import 'package:in_phase/src/logger/logger.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:spotify/spotify.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Minimum fuzzy match score when matching YouTube sources to Spotify tracks.
const youtubeSpotifyMatchThreshold = 80;

/// A YouTube video chosen from a text-query search.
class YoutubeTextQueryMatch {
  const YoutubeTextQueryMatch({
    required this.video,
    required this.score,
    this.runnerUpTitle,
    this.runnerUpScore,
    this.ambiguous = false,
  });

  final Video video;
  final int score;
  final String? runnerUpTitle;
  final int? runnerUpScore;

  /// True when top candidates tied after tie-breaking.
  final bool ambiguous;
}

/// A Spotify track matched to a YouTube video.
class SpotifyTrackMatch {
  const SpotifyTrackMatch({
    required this.track,
    required this.score,
    required this.query,
  });

  final Track track;
  final int score;
  final String query;
}

/// Strips common YouTube noise from titles; keeps remix/mix parentheticals.
String cleanYoutubeTitle(String title) {
  var result = title.trim();

  const noisePatterns = [
    r'\s*\[Official\s+Video\]',
    r'\s*\[Official\s+Audio\]',
    r'\s*\[Official\s+Music\s+Video\]',
    r'\s*\[Music\s+Video\]',
    r'\s*\(Visualizer\)',
    r'\s*\(Official\s+Music\s+Video\)',
    r'\s*\(Official\s+Video\)',
    r'\s*\(Official\s+Audio\)',
  ];

  for (final pattern in noisePatterns) {
    result = result.replaceAll(RegExp(pattern, caseSensitive: false), '');
  }

  return result.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Parsed `Artist - Track` from a YouTube title.
class ParsedYoutubeTitle {
  const ParsedYoutubeTitle({required this.artists, required this.trackName});

  final List<String> artists;
  final String trackName;
}

/// Returns true for YouTube's auto-generated Topic channel marker segment.
///
/// Topic channels are titled "Artist Name - Topic" and upload art tracks as
/// "Artist - Topic - Track". "Topic" is not part of the artist name on Spotify.
bool isYoutubeTopicSegment(String segment) =>
    segment.trim().toLowerCase() == 'topic';

/// Strips the YouTube Topic channel suffix from uploader/channel names.
String stripYoutubeTopicChannelName(String name) =>
    normalizeYoutubeUploaderName(name);

/// Normalizes YouTube uploader/channel names for Spotify matching.
String normalizeYoutubeUploaderName(String name) {
  var result = name.trim();
  result = result.replaceAll(
    RegExp(r'\s*-\s*Topic\s*$', caseSensitive: false),
    '',
  );
  result = result.replaceAll(
    RegExp(r'\s*\[Official[^\]]*\]\s*', caseSensitive: false),
    ' ',
  );
  result = result.replaceAll(
    RegExp(r'\s*\(Official[^)]*\)\s*', caseSensitive: false),
    ' ',
  );
  return result.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Parses `Artist - Track` (also splits artists on `,`, `&`, `and`).
///
/// Handles Topic art-track titles: `Artist - Topic - Track`.
ParsedYoutubeTitle? parseArtistTrackTitle(String title) {
  final parts = title.split(' - ');
  if (parts.length < 2) return null;

  if (parts.length >= 3 && isYoutubeTopicSegment(parts[1])) {
    final artistPart = parts.first.trim();
    final trackPart = parts.sublist(2).join(' - ').trim();
    if (trackPart.isEmpty) return null;

    final artists = _splitArtistNames(artistPart);
    if (artists.isEmpty) return null;
    return ParsedYoutubeTitle(artists: artists, trackName: trackPart);
  }

  final artistPart = parts.first.trim();
  final trackPart = parts.sublist(1).join(' - ').trim();
  if (trackPart.isEmpty) return null;

  final artists = _splitArtistNames(artistPart);
  if (artists.isEmpty) return null;
  return ParsedYoutubeTitle(artists: artists, trackName: trackPart);
}

/// Parses `Track - Artist` (reversed upload title format).
ParsedYoutubeTitle? parseArtistTrackTitleReversed(String title) {
  final parts = title.split(' - ');
  if (parts.length < 2) return null;

  final trackPart = parts.first.trim();
  final artistPart = parts.sublist(1).join(' - ').trim();
  if (trackPart.isEmpty || artistPart.isEmpty) return null;

  final artists = _splitArtistNames(artistPart);
  if (artists.isEmpty) return null;
  return ParsedYoutubeTitle(artists: artists, trackName: trackPart);
}

List<String> _splitArtistNames(String artistPart) {
  return artistPart
      .split(RegExp(r'\s*,\s*|\s+&\s+|\s+and\s+', caseSensitive: false))
      .map(normalizeYoutubeUploaderName)
      .where((a) => a.isNotEmpty)
      .toList();
}

/// Normalizes text for fuzzy comparison.
String normalizeForFuzzy(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^\w\s]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Normalizes artist tokens (strips punctuation like `S.P.Y` → `spy`).
String normalizeArtistToken(String value) =>
    normalizeForFuzzy(value).replaceAll(RegExp(r'[.\s]'), '');

/// Strips trailing `(feat. …)` / `(ft. …)` segments from track titles.
String stripFeaturingFromTrackName(String trackName) {
  return trackName
      .replaceAll(
        RegExp(r'\s*\((feat\.?|ft\.?|with)[^)]*\)\s*', caseSensitive: false),
        ' ',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Track title normalized for Spotify search (drops feat./version parentheticals).
String normalizeTrackNameForSearch(String trackName) {
  var result = stripFeaturingFromTrackName(trackName);
  result = stripParentheticalTrackName(result);
  return result.trim();
}

/// Parses artist/track from a YouTube title, falling back to uploader + title.
///
/// Mix panels often store only the track name with the artist in the uploader
/// field (e.g. title `Babylon System`, author `Silloh`).
ParsedYoutubeTitle? resolveParsedYoutubeTitle({
  required String author,
  required String cleanedTitle,
}) {
  final fromTitle =
      parseArtistTrackTitle(cleanedTitle) ??
      parseArtistTrackTitleReversed(cleanedTitle);
  if (fromTitle != null) {
    return fromTitle;
  }

  final cleanedAuthor = normalizeYoutubeUploaderName(author);
  if (cleanedAuthor.isEmpty) {
    return null;
  }

  return parseArtistTrackTitle('$cleanedAuthor - $cleanedTitle');
}

/// Human-readable label for logs, with Topic channels normalized away.
String formatYoutubeVideoLabel({
  required String author,
  required String title,
}) {
  final cleanedTitle = cleanYoutubeTitle(title);
  final parsed = resolveParsedYoutubeTitle(
    author: author,
    cleanedTitle: cleanedTitle,
  );
  if (parsed != null) {
    return '${parsed.artists.join(', ')} - ${parsed.trackName}';
  }

  final cleanedAuthor = normalizeYoutubeUploaderName(author);
  if (cleanedAuthor.isEmpty) {
    return cleanedTitle;
  }
  return '$cleanedAuthor - $cleanedTitle';
}

String _escapeSpotifyQuery(String value) => value.replaceAll('"', r'\"');

String _exactSpotifySearchQuery(String artist, String trackName) {
  return 'artist:"${_escapeSpotifyQuery(artist)}" '
      'track:"${_escapeSpotifyQuery(trackName)}"';
}

/// Builds Spotify search queries for a YouTube video, most specific first.
List<String> buildSpotifySearchQueries({
  required String author,
  required String cleanedTitle,
}) {
  final queries = <String>[];
  void add(String query) {
    final trimmed = query.trim();
    if (trimmed.isNotEmpty && !queries.contains(trimmed)) {
      queries.add(trimmed);
    }
  }

  final parsed = resolveParsedYoutubeTitle(
    author: author,
    cleanedTitle: cleanedTitle,
  );
  if (parsed != null) {
    final searchTrackNames = {
      parsed.trackName,
      normalizeTrackNameForSearch(parsed.trackName),
    }..removeWhere((name) => name.isEmpty);

    for (final searchTrackName in searchTrackNames) {
      add(_exactSpotifySearchQuery(parsed.artists.first, searchTrackName));
      add('${parsed.artists.join(' ')} $searchTrackName');
      if (parsed.artists.length > 1) {
        add('${parsed.artists.first} $searchTrackName');
      }
      add(searchTrackName);
    }
  }

  final normalizedAuthor = normalizeYoutubeUploaderName(author);
  add('$normalizedAuthor $cleanedTitle');

  return queries;
}

/// Primary Spotify search query for a YouTube video.
String buildSpotifySearchQuery({
  required String author,
  required String cleanedTitle,
}) {
  return buildSpotifySearchQueries(
    author: author,
    cleanedTitle: cleanedTitle,
  ).first;
}

/// Strips trailing parenthetical segments from a track title.
String stripParentheticalTrackName(String trackName) {
  var result = trackName.trim();
  while (RegExp(r'\s*\([^)]*\)\s*$').hasMatch(result)) {
    result = result.replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '').trim();
  }
  return result;
}

/// Scores how well a YouTube search result matches a text query.
int scoreYoutubeVideoForQuery(String query, String youtubeTitle) {
  final normalizedQuery = normalizeForFuzzy(query);
  final cleaned = cleanYoutubeTitle(youtubeTitle);
  final scores = <int>[
    tokenSortRatio(normalizedQuery, normalizeForFuzzy(youtubeTitle)),
    tokenSortRatio(normalizedQuery, normalizeForFuzzy(cleaned)),
  ];

  for (final parsed in [
    parseArtistTrackTitle(cleaned),
    parseArtistTrackTitleReversed(cleaned),
  ]) {
    if (parsed == null) continue;
    final primaryArtists = parsed.artists.take(2).join(' ');
    for (final trackName in {
      parsed.trackName,
      stripParentheticalTrackName(parsed.trackName),
    }) {
      if (trackName.isEmpty) continue;
      scores.add(
        tokenSortRatio(
          normalizedQuery,
          normalizeForFuzzy('$primaryArtists $trackName'),
        ),
      );
    }
  }

  return scores.reduce((a, b) => a > b ? a : b);
}

int _youtubeSearchTieBreakScore(String title) {
  var score = 0;
  final lower = title.toLowerCase();
  if (lower.contains('official')) score += 10;
  if (RegExp(r'\blyrics\b', caseSensitive: false).hasMatch(lower)) {
    score -= 10;
  }
  return score;
}

/// Picks the best YouTube video for a text query from search results.
YoutubeTextQueryMatch? pickBestYoutubeVideo({
  required String query,
  required List<Video> candidates,
  int threshold = youtubeSpotifyMatchThreshold,
}) {
  if (candidates.isEmpty) return null;

  final scored = <({Video video, int score, String title, int tieBreak})>[];
  for (final video in candidates) {
    scored.add((
      video: video,
      score: scoreYoutubeVideoForQuery(query, video.title),
      title: video.title,
      tieBreak: _youtubeSearchTieBreakScore(video.title),
    ));
  }

  scored.sort((a, b) {
    final scoreCmp = b.score.compareTo(a.score);
    if (scoreCmp != 0) return scoreCmp;
    return b.tieBreak.compareTo(a.tieBreak);
  });

  final best = scored.first;
  if (best.score < threshold) return null;

  final runnerUp = scored.length > 1 ? scored[1] : null;
  final ambiguous =
      runnerUp != null &&
      runnerUp.score == best.score &&
      runnerUp.tieBreak == best.tieBreak;

  if (ambiguous) return null;

  return YoutubeTextQueryMatch(
    video: best.video,
    score: best.score,
    runnerUpTitle: runnerUp?.title,
    runnerUpScore: runnerUp?.score,
  );
}

/// Resolves a text query to one YouTube video via search + fuzzy matching.
Future<YoutubeTextQueryMatch?> resolveYoutubeVideoFromTextQuery({
  required YoutubeExplode yt,
  required String query,
  int searchLimit = 20,
}) async {
  final searchList = await yt.search.search(query);
  final results = searchList.take(searchLimit).toList();
  return pickBestYoutubeVideo(query: query, candidates: results);
}

/// Returns true when any [expected] artist fuzzy-matches a Spotify artist name.
bool spotifyArtistsMatchExpected(
  List<String> expected,
  List<String> spotifyArtists, {
  int threshold = youtubeSpotifyMatchThreshold,
}) {
  if (expected.isEmpty || spotifyArtists.isEmpty) return false;

  for (final expectedArtist in expected) {
    final normalizedExpected = normalizeForFuzzy(expectedArtist);
    final tokenExpected = normalizeArtistToken(expectedArtist);
    for (final spotifyArtist in spotifyArtists) {
      final normalizedSpotify = normalizeForFuzzy(spotifyArtist);
      if (ratio(normalizedExpected, normalizedSpotify) >= threshold) {
        return true;
      }
      if (ratio(tokenExpected, normalizeArtistToken(spotifyArtist)) >=
          threshold) {
        return true;
      }
    }
  }
  return false;
}

/// Scores a Spotify search candidate against a YouTube-derived query.
///
/// When [parsedTitle] is available, also scores track-name similarity when the
/// primary artist matches — so extra featured artists on Spotify do not block
/// a match (e.g. "Silloh - Babylon System" vs "Silloh, Speaker Louis").
int scoreSpotifyTrackCandidate({
  required String query,
  required List<String> spotifyArtists,
  required String spotifyTrackName,
  ParsedYoutubeTitle? parsedTitle,
}) {
  final normalizedQuery = normalizeForFuzzy(query);
  final normalizedTarget = normalizeForFuzzy(
    '${spotifyArtists.join(' ')} $spotifyTrackName',
  );

  final scores = <int>[
    tokenSortRatio(normalizedQuery, normalizedTarget),
  ];

  if (parsedTitle != null &&
      spotifyArtistsMatchExpected(parsedTitle.artists, spotifyArtists)) {
    final expectedTrackNames = {
      parsedTitle.trackName,
      stripFeaturingFromTrackName(parsedTitle.trackName),
      stripParentheticalTrackName(parsedTitle.trackName),
      stripParentheticalTrackName(
        stripFeaturingFromTrackName(parsedTitle.trackName),
      ),
    };
    final spotifyNames = {
      spotifyTrackName,
      stripParentheticalTrackName(spotifyTrackName),
    };

    for (final expectedName in expectedTrackNames) {
      if (expectedName.isEmpty) continue;
      final normalizedExpected = normalizeForFuzzy(expectedName);
      for (final spotifyName in spotifyNames) {
        if (spotifyName.isEmpty) continue;
        final normalizedSpotify = normalizeForFuzzy(spotifyName);
        scores
          ..add(tokenSortRatio(normalizedExpected, normalizedSpotify))
          ..add(partialRatio(normalizedExpected, normalizedSpotify))
          ..add(tokenSetRatio(normalizedExpected, normalizedSpotify));
      }
    }

    final primaryArtist = parsedTitle.artists.first;
    scores.add(
      tokenSortRatio(
        normalizeForFuzzy('$primaryArtist ${parsedTitle.trackName}'),
        normalizeForFuzzy(
          '${spotifyArtists.first} $spotifyTrackName',
        ),
      ),
    );
  }

  return scores.reduce((a, b) => a > b ? a : b);
}

/// A scored Spotify search candidate (for verbose diagnostics).
class ScoredSpotifyCandidate {
  const ScoredSpotifyCandidate({
    required this.track,
    required this.score,
    required this.query,
  });

  final Track track;
  final int score;
  final String query;
}

/// Ranks Spotify [tracks] for a YouTube-derived [query].
List<ScoredSpotifyCandidate> rankSpotifyTrackCandidates({
  required String query,
  required List<Track> tracks,
  ParsedYoutubeTitle? parsedTitle,
}) {
  final ranked = <ScoredSpotifyCandidate>[];
  for (final track in tracks) {
    final artistNames =
        track.artists
            ?.map((a) => a.name ?? '')
            .where((n) => n.isNotEmpty)
            .toList() ??
        <String>[];
    final score = scoreSpotifyTrackCandidate(
      query: query,
      spotifyArtists: artistNames,
      spotifyTrackName: track.name ?? '',
      parsedTitle: parsedTitle,
    );
    ranked.add(
      ScoredSpotifyCandidate(track: track, score: score, query: query),
    );
  }
  ranked.sort((a, b) => b.score.compareTo(a.score));
  return ranked;
}

/// Searches Spotify for the best match to a YouTube video.
Future<SpotifyTrackMatch?> matchSpotifyTrackForYoutubeVideo({
  required SpotifyApi api,
  required YoutubeVideoRef video,
  int threshold = youtubeSpotifyMatchThreshold,
}) async {
  final cleanedTitle = cleanYoutubeTitle(video.title);
  final parsedTitle = resolveParsedYoutubeTitle(
    author: video.author,
    cleanedTitle: cleanedTitle,
  );
  final queries = buildSpotifySearchQueries(
    author: video.author,
    cleanedTitle: cleanedTitle,
  );

  SpotifyTrackMatch? bestMatch;
  final allRanked = <ScoredSpotifyCandidate>[];

  for (final query in queries) {
    final pages = await api.search
        .get(query, types: [SearchType.track])
        .first(5);
    final tracks = pages
        .expand((page) => page.items?.whereType<Track>() ?? <Track>[])
        .toList();
    if (tracks.isEmpty) {
      continue;
    }

    final ranked = rankSpotifyTrackCandidates(
      query: query,
      tracks: tracks,
      parsedTitle: parsedTitle,
    );
    allRanked.addAll(ranked);

    final top = ranked.first;
    if (top.score >= threshold &&
        (bestMatch == null || top.score > bestMatch.score)) {
      bestMatch = SpotifyTrackMatch(
        track: top.track,
        score: top.score,
        query: query,
      );
    }

    if (bestMatch != null && bestMatch.score >= 95) {
      break;
    }
  }

  if (bestMatch == null && log.debugMode && allRanked.isNotEmpty) {
    allRanked.sort((a, b) => b.score.compareTo(a.score));
    log.debug('    Spotify candidates (best first):');
    for (final candidate in allRanked.take(5)) {
      final artists =
          candidate.track.artists?.map((a) => a.name).nonNulls.join(', ') ?? '';
      log.debug(
        '      score ${candidate.score} via "${candidate.query}": '
        '$artists - ${candidate.track.name}',
      );
    }
    if (queries.length > 1) {
      log.debug('    Queries tried: ${queries.join(' | ')}');
    }
  }

  return bestMatch;
}

/// Spotify match attempt for one YouTube video.
class SpotifyTrackMatchJob {
  const SpotifyTrackMatchJob({required this.video, this.match});

  final YoutubeVideoRef video;
  final SpotifyTrackMatch? match;
}

/// Matches [videos] to Spotify tracks concurrently via [requestPool].
Future<List<SpotifyTrackMatchJob>> matchSpotifyTracksForVideos({
  required SpotifyApi api,
  required RequestPool requestPool,
  required List<YoutubeVideoRef> videos,
}) {
  return Future.wait(
    videos.map((video) async {
      final match = await requestPool.request(
        () => matchSpotifyTrackForYoutubeVideo(api: api, video: video),
        identifier: 'convert-spotify-match-${video.id}',
      );
      return SpotifyTrackMatchJob(video: video, match: match);
    }),
  );
}
