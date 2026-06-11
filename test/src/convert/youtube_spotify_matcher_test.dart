import 'package:in_phase/src/convert/youtube_spotify_matcher.dart';
import 'package:test/test.dart';

void main() {
  group('scoreYoutubeVideoForQuery', () {
    test('forward Artist - Track title', () {
      final score = scoreYoutubeVideoForQuery(
        'pola bryson phoneline',
        'Pola & Bryson - Phoneline (Official Video)',
      );
      expect(score, greaterThanOrEqualTo(youtubeSpotifyMatchThreshold));
    });

    test('reversed Track - Artist title (Billboard #9 regression)', () {
      final score = scoreYoutubeVideoForQuery(
        'olivia dean so easy',
        'So Easy (To Fall In Love) (Audio) - Olivia Dean',
      );
      expect(score, greaterThanOrEqualTo(youtubeSpotifyMatchThreshold));
    });
  });

  group('buildSpotifySearchQueries', () {
    test('includes exact and fuzzy queries when title parses', () {
      final queries = buildSpotifySearchQueries(
        author: 'Shogun Audio',
        cleanedTitle: 'Pola & Bryson - Phoneline',
      );
      expect(queries.any((q) => q.startsWith('artist:"')), isTrue);
      expect(queries, contains('Pola Bryson Phoneline'));
      expect(queries, contains('Phoneline'));
    });

    test('uses artist from reversed Track - Artist title', () {
      final queries = buildSpotifySearchQueries(
        author: 'Olivia Dean',
        cleanedTitle: 'So Easy (To Fall In Love) - Olivia Dean',
      );
      expect(
        queries.any((q) => q.toLowerCase().contains('olivia dean')),
        isTrue,
      );
      expect(
        queries.any((q) => q.toLowerCase().contains('so easy')),
        isTrue,
      );
    });
  });

  group('resolveParsedYoutubeTitle', () {
    test('combines uploader and track-only mix panel titles', () {
      final parsed = resolveParsedYoutubeTitle(
        author: 'Silloh - Topic',
        cleanedTitle: 'Babylon System',
      );
      expect(parsed, isNotNull);
      expect(parsed!.artists, ['Silloh']);
      expect(parsed.trackName, 'Babylon System');
    });

    test('combines uploader for Gui Badboy-style entries', () {
      final parsed = resolveParsedYoutubeTitle(
        author: 'Gui - Topic',
        cleanedTitle: 'Badboy',
      );
      expect(parsed?.artists, ['Gui']);
      expect(parsed?.trackName, 'Badboy');
    });

    test('strips feat. segments for search', () {
      expect(
        stripFeaturingFromTrackName('Destiny (feat. Jozzy)'),
        'Destiny',
      );
    });

    test('strips [Official] from uploader names', () {
      expect(
        normalizeYoutubeUploaderName('Higgo [Official]'),
        'Higgo',
      );
      final parsed = resolveParsedYoutubeTitle(
        author: 'Higgo [Official]',
        cleanedTitle: 'Sunrise',
      );
      expect(parsed?.artists, ['Higgo']);
      expect(
        buildSpotifySearchQueries(
          author: 'Higgo [Official]',
          cleanedTitle: 'Sunrise',
        ),
        contains('artist:"Higgo" track:"Sunrise"'),
      );
    });

    test('strips version parentheticals for search', () {
      expect(
        normalizeTrackNameForSearch("'95 (Original Mix)"),
        "'95",
      );
      expect(
        buildSpotifySearchQueries(
          author: 'Higgo [Official]',
          cleanedTitle: "'95 (Original Mix)",
        ),
        contains('artist:"Higgo" track:"\'95"'),
      );
    });
  });

  group('formatYoutubeVideoLabel', () {
    test('strips Topic from art-track titles', () {
      expect(
        formatYoutubeVideoLabel(
          author: 'Silloh - Topic',
          title: 'Silloh - Topic - Babylon System',
        ),
        'Silloh - Babylon System',
      );
      expect(
        formatYoutubeVideoLabel(
          author: 'Gui - Topic',
          title: 'Gui - Topic - Badboy',
        ),
        'Gui - Badboy',
      );
    });

    test('uses parsed artist-track when channel name differs', () {
      expect(
        formatYoutubeVideoLabel(
          author: 'Drum&BassArena',
          title: 'Silloh - Into the Void',
        ),
        'Silloh - Into the Void',
      );
    });
  });

  group('scoreSpotifyTrackCandidate', () {
    test('matches when Spotify lists extra featured artists', () {
      final parsed = resolveParsedYoutubeTitle(
        author: 'Silloh - Topic',
        cleanedTitle: 'Babylon System',
      );
      final score = scoreSpotifyTrackCandidate(
        query: 'Silloh Babylon System',
        spotifyArtists: ['Silloh', 'Speaker Louis'],
        spotifyTrackName: 'Babylon System',
        parsedTitle: parsed,
      );
      expect(score, greaterThanOrEqualTo(youtubeSpotifyMatchThreshold));
    });

    test('matches collab tracks when YouTube lists one artist', () {
      final parsed = resolveParsedYoutubeTitle(
        author: 'Gui - Topic',
        cleanedTitle: 'Badboy',
      );
      final score = scoreSpotifyTrackCandidate(
        query: 'Gui Badboy',
        spotifyArtists: ['Gui', 'Leks', 'Silloh'],
        spotifyTrackName: 'Badboy',
        parsedTitle: parsed,
      );
      expect(score, greaterThanOrEqualTo(youtubeSpotifyMatchThreshold));
    });

    test('matches dotted artist names like S.P.Y', () {
      final parsed = parseArtistTrackTitle('S.P.Y - Closer');
      expect(
        spotifyArtistsMatchExpected(parsed!.artists, ['S.P.Y']),
        isTrue,
      );
      final score = scoreSpotifyTrackCandidate(
        query: 'S.P.Y Closer',
        spotifyArtists: ['S.P.Y'],
        spotifyTrackName: 'Closer',
        parsedTitle: parsed,
      );
      expect(score, greaterThanOrEqualTo(youtubeSpotifyMatchThreshold));
    });

    test('matches track titles with spacing differences', () {
      final parsed = parseArtistTrackTitle('Gui - Badboy');
      final score = scoreSpotifyTrackCandidate(
        query: 'Gui Badboy',
        spotifyArtists: ['Gui'],
        spotifyTrackName: 'Bad Boy',
        parsedTitle: parsed,
      );
      expect(score, greaterThanOrEqualTo(youtubeSpotifyMatchThreshold));
    });
  });

  group('YouTube Topic channels', () {
    test('parseArtistTrackTitle handles Artist - Topic - Track', () {
      final parsed = parseArtistTrackTitle('Leks - Topic - OMG');
      expect(parsed, isNotNull);
      expect(parsed!.artists, ['Leks']);
      expect(parsed.trackName, 'OMG');
    });

    test('buildSpotifySearchQueries strip Topic from queries', () {
      expect(
        buildSpotifySearchQueries(
          author: 'Leks - Topic',
          cleanedTitle: 'Leks - Topic - OMG',
        ),
        contains('Leks OMG'),
      );
      expect(
        buildSpotifySearchQueries(
          author: 'Alibi - Topic',
          cleanedTitle: 'Alibi - Topic - Middlemen',
        ),
        contains('Alibi Middlemen'),
      );
      expect(
        buildSpotifySearchQueries(
          author: 'Gui - Topic',
          cleanedTitle: 'Gui - Topic - Badboy',
        ),
        contains('Gui Badboy'),
      );
    });

    test('stripYoutubeTopicChannelName leaves normal channels unchanged', () {
      expect(
        stripYoutubeTopicChannelName('Forbidden Frequencies'),
        'Forbidden Frequencies',
      );
      expect(stripYoutubeTopicChannelName('Drake - Topic'), 'Drake');
    });
  });

  group('parseArtistTrackTitleReversed', () {
    test('parses Track - Artist format', () {
      final parsed = parseArtistTrackTitleReversed(
        'So Easy (To Fall In Love) - Olivia Dean',
      );
      expect(parsed, isNotNull);
      expect(parsed!.trackName, contains('So Easy'));
      expect(parsed.artists, contains('Olivia Dean'));
    });
  });
}
