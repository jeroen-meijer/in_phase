// ignore_for_file: lines_longer_than_80_chars

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
    TrackAlbumMappings,
    CachedArtists,
    CachedArtistAlbumLists,
    ArtistAlbumRelationships,
    CachedLabelSearches,
    CachedLabelTracks,
    CacheMetadata,
    SyncTrackMappings,
    SyncMissingTracks,
    SyncPlaylists,
    SyncPlaylistTracks,
  ],
  daos: [
    PlaylistsDao,
    AlbumsDao,
    TrackAlbumMappingsDao,
    ArtistsDao,
    ArtistAlbumsDao,
    LabelSearchesDao,
    MetadataDao,
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
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from == 1 && to == 2) {
          // Add sync tables in version 2
          await m.createTable(syncTrackMappings);
          await m.createTable(syncMissingTracks);
          await m.createTable(syncPlaylists);
          await m.createTable(syncPlaylistTracks);
        }
        if (from <= 2 && to == 3) {
          // Add order_index column to artist_album_relationships table
          // Check if the column already exists
          final result = await m.database
              .customSelect(
                'PRAGMA table_info(artist_album_relationships)',
              )
              .get();

          final hasOrderIndex = result.any(
            (row) => row.data['name'] == 'order_index',
          );

          // Clean up any existing temporary table
          try {
            await m.database.customStatement(
              'DROP TABLE IF EXISTS artist_album_relationships_new',
            );
          } catch (e) {
            // Ignore errors if table doesn't exist
          }

          if (!hasOrderIndex) {
            // First add the column as nullable
            await m.database.customStatement(
              'ALTER TABLE artist_album_relationships ADD COLUMN order_index INTEGER',
            );

            // Update existing rows to have order_index = 0
            await m.database.customStatement(
              'UPDATE artist_album_relationships SET order_index = 0 WHERE order_index IS NULL',
            );
          }

          // Make the column NOT NULL by recreating the table
          await m.database.customStatement(
            'CREATE TABLE artist_album_relationships_new (artist_id TEXT NOT NULL, album_id TEXT NOT NULL, order_index INTEGER NOT NULL, PRIMARY KEY (artist_id, album_id), FOREIGN KEY (artist_id) REFERENCES cached_artists (id), FOREIGN KEY (album_id) REFERENCES cached_albums (id))',
          );

          // Copy data to new table
          await m.database.customStatement(
            'INSERT INTO artist_album_relationships_new SELECT artist_id, album_id, COALESCE(order_index, 0) FROM artist_album_relationships',
          );

          // Drop old table and rename new one
          await m.database.customStatement(
            'DROP TABLE artist_album_relationships',
          );
          await m.database.customStatement(
            'ALTER TABLE artist_album_relationships_new RENAME TO artist_album_relationships',
          );
        }
      },
    );
  }
}
