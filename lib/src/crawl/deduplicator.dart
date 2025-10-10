import 'package:rkdb_dart/src/crawl/track_collector.dart';
import 'package:rkdb_dart/src/entities/entities.dart';

/// Deduplicates a list of tracks based on the specified mode.
List<CollectedTrack> deduplicate(
  List<CollectedTrack> tracks,
  DeduplicateMode? mode,
) {
  if (mode == null) return tracks;

  switch (mode) {
    case DeduplicateMode.onId:
      return _deduplicateById(tracks);
    case DeduplicateMode.onMatch:
      return _deduplicateByMatch(tracks);
  }
}

/// Removes tracks with duplicate IDs, keeping the first occurrence.
List<CollectedTrack> _deduplicateById(List<CollectedTrack> tracks) {
  final seenIds = <String>{};
  final result = <CollectedTrack>[];

  for (final track in tracks) {
    if (seenIds.add(track.id)) {
      result.add(track);
    }
  }

  return result;
}

/// Removes tracks with matching artist names and track titles.
///
/// The matching is done after normalizing the text:
/// - Convert to lowercase
/// - Remove non-alphanumeric characters (except spaces)
/// - Collapse multiple spaces to single space
/// - Trim whitespace
List<CollectedTrack> _deduplicateByMatch(List<CollectedTrack> tracks) {
  final seenMatches = <String>{};
  final result = <CollectedTrack>[];

  for (final track in tracks) {
    final matchKey = _normalizeForMatching(
      '${track.artistNames.join(' ')} ${track.name}',
    );

    if (seenMatches.add(matchKey)) {
      result.add(track);
    }
  }

  return result;
}

/// Normalizes a string for matching purposes.
///
/// Steps:
/// 1. Convert to lowercase
/// 2. Replace all non-word characters (except spaces) with a single space
/// 3. Collapse multiple spaces to single space
/// 4. Trim leading/trailing whitespace
String _normalizeForMatching(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
