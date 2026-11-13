import 'package:in_phase/src/spotify/spotify.dart';
import 'package:spotify/spotify.dart';
import 'package:test/test.dart';

void main() {
  test('spotifyTracks skips local files and missing tracks', () {
    final entries = [
      PlaylistTrack()..track = (Track()..id = 'remote'),
      PlaylistTrack()
        ..isLocal = true
        ..track = Track(),
      PlaylistTrack(),
    ];

    expect(entries.spotifyTracks.map((e) => e.track!.id), ['remote']);
  });
}
