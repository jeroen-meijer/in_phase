import 'package:in_phase/src/convert/youtube_mix_source.dart';
import 'package:test/test.dart';

void main() {
  group('parseMixPanelVideos', () {
    final sampleData = {
      'contents': {
        'twoColumnWatchNextResults': {
          'playlist': {
            'playlist': {
              'title': 'Mix - Artist - Track',
              'contents': [
                {
                  'playlistPanelVideoRenderer': {
                    'videoId': 'abc123',
                    'title': {'simpleText': 'Artist - Track'},
                    'longBylineText': {
                      'runs': [
                        {'text': 'Channel Name'},
                      ],
                    },
                  },
                },
                {
                  'playlistPanelVideoRenderer': {
                    'videoId': 'def456',
                    'title': {
                      'runs': [
                        {'text': 'Other Artist - Other Track'},
                      ],
                    },
                    'longBylineText': {
                      'runs': [
                        {'text': 'Other Channel'},
                      ],
                    },
                  },
                },
              ],
            },
          },
        },
      },
    };

    test('parses mix playlist title', () {
      expect(parseMixPlaylistTitle(sampleData), 'Mix - Artist - Track');
    });

    test('parses playlistPanelVideoRenderer entries', () {
      final videos = parseMixPanelVideos(sampleData);

      expect(videos, hasLength(2));
      expect(videos.first.videoId, 'abc123');
      expect(videos.first.title, 'Artist - Track');
      expect(videos.first.author, 'Channel Name');
      expect(videos.last.videoId, 'def456');
    });

    test('returns empty list when mix panel is missing', () {
      expect(parseMixPanelVideos({}), isEmpty);
    });
  });
}
