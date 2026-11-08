import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:in_phase/src/database/daos.dart';
import 'package:in_phase/src/database/tables.dart';
import 'package:in_phase/src/misc/misc.dart';

part 'database.g.dart';

/// The Drift database for caching crawl and sync data.
@DriftDatabase(
  tables: [
    CachedPlaylists,
    CachedPlaylistTracks,
    CachedAlbums,
    CachedArtists,
    CachedArtistAlbumLists,
    ArtistAlbumRelationships,
    CachedLabelSearches,
    CachedLabelTracks,
    SyncTrackMappings,
    SyncMissingTracks,
    SyncPlaylists,
    SyncPlaylistTracks,
  ],
  daos: [
    PlaylistsDao,
    AlbumsDao,
    ArtistsDao,
    ArtistAlbumsDao,
    LabelSearchesDao,
    SyncMappingsDao,
    SyncMissingTracksDao,
    SyncPlaylistsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Creates a database instance with a file path.
  factory AppDatabase.fromFile(File file) {
    return AppDatabase(
      NativeDatabase.createInBackground(file),
    );
  }

  /// Creates a database instance from the cache database file.
  factory AppDatabase.fromCacheDbFile() {
    return AppDatabase.fromFile(Constants.cacheDbFile);
  }

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) => m.createAll(),
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.createTable(syncTrackMappings);
          await m.createTable(syncMissingTracks);
          await m.createTable(syncPlaylists);
          await m.createTable(syncPlaylistTracks);
        }
        if (from < 3) {
          final orderIndex =
              await _hasColumn('artist_album_relationships', 'order_index')
              ? 'COALESCE(order_index, 0)'
              : '0';
          await _rebuildTable(
            m,
            artistAlbumRelationships,
            selectColumns: 'artist_id, album_id, $orderIndex',
          );
        }
        if (from < 4) {
          // 1.5.1 stored `last_inserted_at` (NOT NULL); some caches were
          // already patched by hand to `source_added_at`.
          if (await _hasColumn('sync_missing_tracks', 'last_inserted_at')) {
            await _rebuildTable(
              m,
              syncMissingTracks,
              selectColumns:
                  'spotify_track_id, artist, title, itunes_url, '
                  'last_inserted_at',
            );
          } else if (!await _hasColumn(
            'sync_missing_tracks',
            'source_added_at',
          )) {
            await m.addColumn(
              syncMissingTracks,
              syncMissingTracks.sourceAddedAt,
            );
          }
          if (!await _hasColumn('sync_playlist_tracks', 'added_at')) {
            await m.addColumn(syncPlaylistTracks, syncPlaylistTracks.addedAt);
          }
          await m.deleteTable('track_album_mappings');
          await m.deleteTable('cache_metadata');
        }
      },
    );
  }

  /// Recreates [table] from its current definition, copying rows from the
  /// old table with [selectColumns] (in the order of the table's columns).
  Future<void> _rebuildTable(
    Migrator m,
    TableInfo<Table, dynamic> table, {
    required String selectColumns,
  }) async {
    final name = table.actualTableName;
    final oldName = '${name}_old';
    await customStatement('DROP TABLE IF EXISTS $oldName');
    await customStatement('ALTER TABLE $name RENAME TO $oldName');
    await m.createTable(table);
    final columns = table.$columns.map((c) => c.name).join(', ');
    await customStatement(
      'INSERT INTO $name ($columns) SELECT $selectColumns FROM $oldName',
    );
    await m.deleteTable(oldName);
  }

  Future<bool> _hasColumn(String table, String column) async {
    final rows = await customSelect('PRAGMA table_info($table)').get();
    return rows.any((row) => row.data['name'] == column);
  }
}
