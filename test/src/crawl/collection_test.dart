import 'package:in_phase/src/crawl/crawl.dart';
import 'package:in_phase/src/entities/entities.dart';
import 'package:in_phase/src/reports/reports.dart';
import 'package:in_phase/src/spotify/spotify.dart';
import 'package:simple_date/simple_date.dart';
import 'package:test/test.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() {
  group('collectFromSources', () {
    test('returns the tracks of every source in source order', () async {
      final result = await collectFromSources([
        _source('playlist A', [_track('a1'), _track('a2')]),
        _source('artist B', [_track('b1')]),
      ]);

      expect(result.tracks.map((t) => t.id), ['a1', 'a2', 'b1']);
      expect(result.failedSources, isEmpty);
    });

    test('keeps the tracks of the other sources when one fails', () async {
      final result = await collectFromSources([
        _source('playlist A', [_track('a1')]),
        _failingSource('YouTube channel @x'),
        _source('artist B', [_track('b1')]),
      ]);

      expect(result.tracks.map((t) => t.id), ['a1', 'b1']);
    });

    test('names each failed source with its error', () async {
      final result = await collectFromSources([
        _source('playlist A', [_track('a1')]),
        _failingSource('YouTube channel @x'),
      ]);

      expect(result.failedSources, [
        'YouTube channel @x: Exception: unreachable',
      ]);
    });

    test('throws when every source fails', () async {
      await expectLater(
        collectFromSources([
          _failingSource('playlist A'),
          _failingSource('artist B'),
        ]),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            allOf(contains('playlist A'), contains('artist B')),
          ),
        ),
      );
    });

    test('returns no tracks when the job has no sources', () async {
      final result = await collectFromSources([]);

      expect(result.tracks, isEmpty);
      expect(result.failedSources, isEmpty);
    });
  });

  group('uploadsInDateRange', () {
    final rangeStart = SimpleDate(2026, 11, 7);
    final rangeEnd = SimpleDate(2026, 11, 13);

    Future<List<String>> titlesInRange(_FakeChannel channel) async {
      final videos = await uploadsInDateRange(
        pages: channel.uploadPages(),
        fetchVideo: channel.fetchVideo,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );
      return [for (final video in videos) video.title];
    }

    test('includes uploads from the first and last day of the range', () async {
      final channel = _FakeChannel([
        [
          _video('last day', DateTime(2026, 11, 13, 23, 59)),
          _video('first day', DateTime(2026, 11, 7)),
          _video('day before', DateTime(2026, 11, 6, 23, 59)),
        ],
      ]);

      expect(await titlesInRange(channel), ['last day', 'first day']);
    });

    test('skips uploads dated after the range and keeps reading', () async {
      final channel = _FakeChannel([
        [
          _video('premiere', DateTime(2026, 11, 14)),
          _video('in range', DateTime(2026, 11, 10)),
        ],
      ]);

      expect(await titlesInRange(channel), ['in range']);
    });

    test('reads the next page while uploads are in range', () async {
      final channel = _FakeChannel([
        [
          _video('page 1', DateTime(2026, 11, 12)),
        ],
        [
          _video('page 2', DateTime(2026, 11, 9)),
          _video('older', DateTime(2026, 11, 3)),
        ],
      ]);

      expect(await titlesInRange(channel), ['page 1', 'page 2']);
    });

    test(
      'stops reading pages at the first upload older than the range',
      () async {
        final channel = _FakeChannel([
          [
            _video('in range', DateTime(2026, 11, 12)),
            _video('older', DateTime(2026, 11, 2)),
          ],
          [
            _video('next page', DateTime(2026, 11, 2)),
          ],
        ]);

        await titlesInRange(channel);

        expect(channel.pagesRead, 1);
      },
    );

    test('skips an upload without a date instead of stopping', () async {
      final channel = _FakeChannel([
        [
          _video('no date', null),
          _video('in range', DateTime(2026, 11, 8)),
        ],
      ]);

      expect(await titlesInRange(channel), ['in range']);
    });

    test('returns nothing for a channel without uploads', () async {
      final channel = _FakeChannel([]);

      expect(await titlesInRange(channel), isEmpty);
    });
  });

  group('CrawlReportGenerator', () {
    group('render', () {
      CrawlReport reportWith(List<String> failedSources) => CrawlReport(
        startTime: DateTime(2026, 11, 13, 15),
        endTime: DateTime(2026, 11, 13, 15, 5),
        jobReports: [
          CrawlJobReport(
            jobName: 'underground_weekly',
            startTime: DateTime(2026, 11, 13, 15),
            endTime: DateTime(2026, 11, 13, 15, 5),
            trackEntries: const [],
            failedSources: failedSources,
          ),
        ],
      );

      test('lists each failed source on one line', () {
        final markdown = CrawlReportGenerator.render(
          reportWith([
            'YouTube channel @x: Failed to load,\n try again.',
          ]),
        );

        expect(
          markdown,
          contains(
            '- YouTube channel @x: Failed to load, try again.\n',
          ),
        );
      });

      test('leaves out the failed sources section when none failed', () {
        final markdown = CrawlReportGenerator.render(reportWith([]));

        expect(markdown, isNot(contains('Failed Sources')));
      });
    });
  });
}

CrawlSource _source(String label, List<CollectedTrack> tracks) =>
    (label: label, collect: (_) async => tracks);

CrawlSource _failingSource(String label) =>
    (label: label, collect: (_) async => throw Exception('unreachable'));

CollectedTrack _track(String id) => CollectedTrack(
  id: SpotifyTrackId(id),
  uri: 'spotify:track:$id',
  name: id,
  artistNames: const ['artist'],
  addedAt: DateTime(2026, 11, 10),
  source: const CollectedTrackSourceLabel(name: 'label'),
);

var _videoCount = 0;

Video _video(String title, DateTime? publishDate) {
  final id = 'video${(_videoCount++).toString().padLeft(6, '0')}';
  return Video(
    VideoId(id),
    title,
    'channel',
    ChannelId('UCAAAAAAAAAAAAAAAAAAAAAA'),
    null,
    null,
    publishDate,
    '',
    null,
    ThumbnailSet(id),
    null,
    const Engagement(0, null, null),
    false,
  );
}

/// A YouTube channel whose uploads page lists only ids, newest first.
class _FakeChannel {
  _FakeChannel(this._pages);

  final List<List<Video>> _pages;

  /// How many upload pages were requested.
  int pagesRead = 0;

  Stream<List<VideoId>> uploadPages() async* {
    for (final page in _pages) {
      pagesRead++;
      yield [for (final video in page) video.id];
    }
  }

  Future<Video> fetchVideo(VideoId id) async =>
      _pages.expand((page) => page).firstWhere((video) => video.id == id);
}
