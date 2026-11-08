import 'dart:io';

import 'package:in_phase/src/database/database.dart';
import 'package:in_phase/src/spotify/spotify.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

/// Creates a cache database file with the schema shipped in 1.5.1 (v3).
///
/// When [handPatched] is true, the sync tables already have the v4 date
/// columns, matching caches that were fixed manually before v4 existed.
Future<File> _createV3Database({required bool handPatched}) async {
  final dir = await Directory.systemTemp.createTemp('in_phase_migration');
  addTearDown(() => dir.delete(recursive: true));
  final file = File(path.join(dir.path, 'cache.db'));

  final fresh = AppDatabase.fromFile(file);
  await fresh.customSelect('SELECT 1').get();
  await fresh.close();

  sqlite3.open(file.path)
    ..execute('DROP TABLE sync_missing_tracks')
    ..execute('DROP TABLE sync_playlist_tracks')
    ..execute(
      handPatched
          ? 'CREATE TABLE sync_missing_tracks (spotify_track_id TEXT NOT NULL '
                'PRIMARY KEY, artist TEXT NOT NULL, title TEXT NOT NULL, '
                'itunes_url TEXT, source_added_at TEXT)'
          : 'CREATE TABLE sync_missing_tracks (spotify_track_id TEXT NOT NULL, '
                'artist TEXT NOT NULL, title TEXT NOT NULL, itunes_url TEXT, '
                'last_inserted_at TEXT NOT NULL, '
                'PRIMARY KEY (spotify_track_id))',
    )
    ..execute(
      'CREATE TABLE sync_playlist_tracks (playlist_id TEXT NOT NULL, '
      'track_id TEXT NOT NULL, name TEXT NOT NULL, artist_names TEXT NOT NULL, '
      'order_index INTEGER NOT NULL, '
      '${handPatched ? 'added_at TEXT, ' : ''}'
      'PRIMARY KEY (playlist_id, track_id, order_index))',
    )
    ..execute(
      'CREATE TABLE track_album_mappings (track_id TEXT NOT NULL, '
      'album_id TEXT NOT NULL, PRIMARY KEY (track_id, album_id))',
    )
    ..execute(
      'CREATE TABLE cache_metadata (id INTEGER NOT NULL PRIMARY KEY, '
      'created TEXT, last_updated TEXT)',
    )
    ..execute(
      "INSERT INTO sync_missing_tracks VALUES ('wipe', 'Gydra', 'Wipe', "
      "'itmss://example.test/wipe', '2025-08-23T14:12:27.000Z')",
    )
    ..execute('PRAGMA user_version = 3')
    ..dispose();
  return file;
}

void main() {
  for (final handPatched in [false, true]) {
    test('upgrades a v3 cache (hand patched: $handPatched) to v4', () async {
      final file = await _createV3Database(handPatched: handPatched);
      final db = AppDatabase.fromFile(file);
      addTearDown(db.close);

      final kept = await db.syncMissingTracksDao.getMissingTracksBySourceDate();
      expect(kept, hasLength(1));
      expect(kept.single.itunesUrl, 'itmss://example.test/wipe');
      expect(kept.single.sourceAddedAt, DateTime.utc(2025, 8, 23, 14, 12, 27));

      // Collection targets store tracks without a source date.
      await db.syncMissingTracksDao.insertMissingTracksBatch([
        (
          id: const SpotifyTrackId('rock'),
          artist: 'S.P.Y',
          title: 'Rock Da House',
          sourceAddedAt: null,
        ),
      ]);
      await db.syncPlaylistsDao.cachePlaylist(
        playlistId: SpotifyPlaylistId('playlist'),
        snapshotId: 'snapshot',
        name: 'Playlist',
        tracks: [
          (
            id: const SpotifyTrackId('wipe'),
            name: 'Wipe',
            artistNames: ['Gydra'],
            addedAt: DateTime.utc(2026),
          ),
        ],
      );
      final cached = await db.syncPlaylistsDao.getPlaylistTracks(
        SpotifyPlaylistId('playlist'),
      );
      expect(cached.single.addedAt, DateTime.utc(2026));

      final tables = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
          .map((row) => row.read<String>('name'))
          .get();
      expect(tables, isNot(contains('track_album_mappings')));
      expect(tables, isNot(contains('cache_metadata')));
      expect(tables, isNot(contains('sync_missing_tracks_old')));
    });
  }
}
