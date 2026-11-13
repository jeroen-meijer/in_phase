import 'package:in_phase/src/crawl/crawl.dart';
import 'package:in_phase/src/entities/entities.dart';
import 'package:in_phase/src/misc/misc.dart';

/// Removes duplicate tracks according to [mode]; returns [tracks] unchanged
/// when [mode] is null.
///
/// Of each group of duplicates, the copy with the latest `addedAt` is kept,
/// at the position of the first copy.
List<CollectedTrack> deduplicate(
  List<CollectedTrack> tracks,
  DeduplicateMode? mode,
) {
  if (mode == null) return tracks;

  final latestByKey = <String, CollectedTrack>{};
  for (final track in tracks) {
    final key = switch (mode) {
      DeduplicateMode.onId => track.id.toString(),
      DeduplicateMode.onMatch => normalizeQuery(track.artistNames, track.name),
    };
    final existing = latestByKey[key];
    if (existing == null || track.addedAt.isAfter(existing.addedAt)) {
      latestByKey[key] = track;
    }
  }
  return latestByKey.values.toList();
}
