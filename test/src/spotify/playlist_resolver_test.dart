import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:in_phase/src/spotify/playlist_resolver.dart';
import 'package:spotify/spotify.dart';
import 'package:test/test.dart';

void main() {
  group('isLikedSongsTarget', () {
    test('matches case-insensitively', () {
      expect(isLikedSongsTarget(likedSongsPlaylistTarget), isTrue);
      expect(isLikedSongsTarget('LIKES'), isTrue);
      expect(isLikedSongsTarget('  likes  '), isTrue);
      expect(isLikedSongsTarget('my likes'), isFalse);
    });
  });

  group('isPlaylistGlobPattern', () {
    test('detects glob characters', () {
      expect(isPlaylistGlobPattern('DnB*'), isTrue);
      expect(isPlaylistGlobPattern('Exact Name'), isFalse);
    });
  });

  group('playlist fuzzy name resolution', () {
    PlaylistSimple playlist(String name) => PlaylistSimple()
      ..name = name
      ..id = 'id-$name';

    int nameScore(String input, String playlistName) => tokenSortRatio(
      input.toLowerCase().trim(),
      playlistName.toLowerCase().trim(),
    );

    test('finds unique fuzzy winner among playlists', () {
      final playlists = [
        playlist('Drum and Bass Weekly'),
        playlist('House Mix'),
      ];

      final scores = playlists
          .map(
            (p) => (
              playlist: p,
              score: nameScore('drum bass weekly', p.name!),
            ),
          )
          .where((e) => e.score >= playlistFuzzyMatchThreshold)
          .toList();

      expect(scores, hasLength(1));
      expect(scores.first.playlist.name, 'Drum and Bass Weekly');
    });

    test('detects ambiguous fuzzy ties at same score', () {
      const input = 'my playlist';
      final scoreA = nameScore(input, 'My Playlist');
      final scoreB = nameScore(input, 'My  Playlist');

      expect(scoreA, greaterThanOrEqualTo(playlistFuzzyMatchThreshold));
      expect(scoreA, equals(scoreB));
    });
  });
}
