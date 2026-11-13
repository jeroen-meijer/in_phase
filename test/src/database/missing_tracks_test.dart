import 'package:drift/native.dart';
import 'package:in_phase/src/database/database.dart';
import 'package:in_phase/src/spotify/spotify.dart';
import 'package:test/test.dart';

void main() {
  test('missing tracks follow source dates and retain buy links', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final dao = db.syncMissingTracksDao;
    final old = DateTime.utc(2026);
    final recent = DateTime.utc(2026, 10);

    await dao.insertMissingTracksBatch([
      (
        id: const SpotifyTrackId('wipe'),
        artist: 'Gydra',
        title: 'Wipe',
        sourceAddedAt: old,
      ),
      (
        id: const SpotifyTrackId('rock'),
        artist: 'S.P.Y',
        title: 'Rock Da House',
        sourceAddedAt: recent,
      ),
    ]);
    await dao.updateItunesUrl(
      spotifyTrackId: const SpotifyTrackId('wipe'),
      itunesUrl: 'itmss://example.test/wipe',
    );
    await dao.insertMissingTracksBatch([
      (
        id: const SpotifyTrackId('wipe'),
        artist: 'Gydra',
        title: 'Wipe',
        sourceAddedAt: null,
      ),
    ]);

    final tracks = await dao.getMissingTracksBySourceDate();
    expect(tracks.map((track) => track.spotifyTrackId), ['rock', 'wipe']);
    expect(tracks.last.sourceAddedAt, old);
    expect(tracks.last.itunesUrl, 'itmss://example.test/wipe');
  });
}
