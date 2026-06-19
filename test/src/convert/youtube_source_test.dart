import 'package:in_phase/src/convert/youtube_source.dart';
import 'package:test/test.dart';

void main() {
  group('classifyYoutubeInput', () {
    test('classifies plain text as query', () {
      final result = classifyYoutubeInput('olivia dean so easy');
      expect(result.kind, YoutubeInputKind.textQuery);
      expect(result.textQuery, 'olivia dean so easy');
    });

    test('classifies video URL', () {
      final result = classifyYoutubeInput(
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      );
      expect(result.kind, YoutubeInputKind.videoUrl);
    });

    test('classifies playlist URL', () {
      final result = classifyYoutubeInput(
        'https://www.youtube.com/playlist?list=PLrAXtmRdnEQy6nuLMH7',
      );
      expect(result.kind, YoutubeInputKind.playlistUrl);
      expect(result.isMixPlaylist, isFalse);
    });

    test('detects mix playlist and seed video', () {
      final result = classifyYoutubeInput(
        'https://www.youtube.com/watch?v=abc123&list=RDmgV4U9qbzp4',
      );
      expect(result.kind, YoutubeInputKind.playlistUrl);
      expect(result.isMixPlaylist, isTrue);
      expect(result.seedVideoId, 'abc123');
      expect(result.hasWatchAndList, isTrue);
    });

    test('parses youtu.be watch URL with list query param', () {
      final result = classifyYoutubeInput(
        'https://youtu.be/mgV4U9qbzp4?list=RDmgV4U9qbzp4',
      );
      expect(result.kind, YoutubeInputKind.playlistUrl);
      expect(result.playlistId, 'RDmgV4U9qbzp4');
      expect(result.seedVideoId, 'mgV4U9qbzp4');
      expect(result.hasWatchAndList, isTrue);
    });

    test('pure playlist URL has no watch-and-list context', () {
      final result = classifyYoutubeInput(
        'https://www.youtube.com/playlist?list=PLrAXtmRdnEQy6nuLMH7',
      );
      expect(result.hasWatchAndList, isFalse);
    });

    test('watch URL with regular PL playlist is not a mix', () {
      final result = classifyYoutubeInput(
        'https://youtu.be/mgV4U9qbzp4?list=PLdhWpY3gLgZE',
      );
      expect(result.kind, YoutubeInputKind.playlistUrl);
      expect(result.playlistId, 'PLdhWpY3gLgZE');
      expect(result.seedVideoId, 'mgV4U9qbzp4');
      expect(result.hasWatchAndList, isTrue);
      expect(result.isMixPlaylist, isFalse);
      expect(isYoutubeMixListId('PLdhWpY3gLgZE'), isFalse);
      expect(isYoutubeMixListId('RDmgV4U9qbzp4'), isTrue);
    });
  });
}
