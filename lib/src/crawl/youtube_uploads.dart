import 'package:collection/collection.dart';
import 'package:in_phase/src/crawl/crawl.dart';
import 'package:simple_date/simple_date.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

const _fetchConcurrency = 5;

/// Returns a channel's uploads dated from [rangeStart] through [rangeEnd],
/// newest first.
///
/// [pages] yields the channel's upload ids newest first, one page at a time.
/// [fetchVideo] loads the title and date the upload ids lack. No further
/// page is read once an upload is older than [rangeStart].
Future<List<Video>> uploadsInDateRange({
  required Stream<List<VideoId>> pages,
  required Future<Video> Function(VideoId id) fetchVideo,
  required SimpleDate rangeStart,
  required SimpleDate rangeEnd,
}) async {
  final videosInRange = <Video>[];

  await for (final ids in pages) {
    for (final batch in ids.slices(_fetchConcurrency)) {
      final videos = await Future.wait(batch.map(fetchVideo));
      for (final video in videos) {
        final date = uploadDateOf(video);
        if (date == null) continue;

        final day = simpleDateFromLocalDateTime(date);
        if (day.isBefore(rangeStart)) return videosInRange;
        if (!day.isAfter(rangeEnd)) videosInRange.add(video);
      }
    }
  }

  return videosInRange;
}

/// The date [video] was published, or uploaded when it has no publish date.
DateTime? uploadDateOf(Video video) => video.publishDate ?? video.uploadDate;
