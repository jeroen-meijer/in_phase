import 'package:in_phase/src/crawl/crawl.dart';
import 'package:in_phase/src/entities/entities.dart';
import 'package:in_phase/src/spotify/spotify.dart';
import 'package:test/test.dart';

CollectedTrack _track(String id, String artist, String name, int day) =>
    CollectedTrack(
      id: SpotifyTrackId(id),
      uri: 'spotify:track:$id',
      name: name,
      artistNames: [artist],
      addedAt: DateTime.utc(2026, 1, day),
      source: const CollectedTrackSourceLabel(name: 'label'),
    );

void main() {
  final tracks = [
    _track('a', 'Gydra', 'Wipe', 1),
    _track('b', 'Noisia', 'Tentacles', 2),
    _track('a', 'Gydra', 'Wipe', 3),
    _track('c', 'GYDRA', 'Wipe!', 4),
  ];

  test('null mode keeps every track', () {
    expect(deduplicate(tracks, null), same(tracks));
  });

  test('on_id keeps the latest copy at the first position', () {
    final result = deduplicate(tracks, DeduplicateMode.onId);
    expect(result.map((t) => '${t.id}@${t.addedAt.day}'), [
      'a@3',
      'b@2',
      'c@4',
    ]);
  });

  test('on_match compares normalized artist and title', () {
    final result = deduplicate(tracks, DeduplicateMode.onMatch);
    expect(result.map((t) => '${t.id}@${t.addedAt.day}'), ['c@4', 'b@2']);
  });
}
