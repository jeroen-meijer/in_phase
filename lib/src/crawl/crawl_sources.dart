import 'package:in_phase/src/crawl/crawl.dart';

/// One input of a crawl job, such as a playlist, artist, label or YouTube
/// channel.
///
/// `label` names the source in failure messages.
typedef CrawlSource = ({
  String label,
  Future<List<CollectedTrack>> Function(CrawlProgressReporter? progress)
  collect,
});

/// Tracks from the sources that succeeded, and a `label: error` line for each
/// source that failed.
typedef CrawlSourcesResult = ({
  List<CollectedTrack> tracks,
  List<String> failedSources,
});

/// Collects every source in [sources] concurrently.
///
/// Tracks keep the order of [sources]. A failing source is left out and
/// reported in `failedSources`. Throws when every source fails, since the
/// result would hold no tracks at all.
Future<CrawlSourcesResult> collectFromSources(
  List<CrawlSource> sources, {
  CrawlProgressDisplay? display,
}) async {
  if (sources.isEmpty) {
    return (tracks: <CollectedTrack>[], failedSources: <String>[]);
  }

  final failures = <String>[];
  final results = await Future.wait([
    for (final (index, source) in sources.indexed)
      source
          .collect(display?.reporterFor(index))
          .then((tracks) {
            display?.setDone(index, tracks.length);
            return tracks;
          })
          .catchError((Object e) {
            display?.setError(index);
            failures.add('${source.label}: $e');
            return <CollectedTrack>[];
          }),
  ]);

  if (failures.length == sources.length) {
    throw Exception(
      'All ${failures.length} source(s) failed:\n  ${failures.join('\n  ')}',
    );
  }
  return (
    tracks: results.expand((tracks) => tracks).toList(),
    failedSources: failures,
  );
}
