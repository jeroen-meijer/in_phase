import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:rkdb_dart/src/database/daos.dart';
import 'package:rkdb_dart/src/database/tables.dart';

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

  /// Creates a database instance with a directory path.
  /// The database file will be named 'cache.db'.
  factory AppDatabase.fromDirectory(Directory dir) {
    final file = File(p.join(dir.path, 'cache.db'));
    return AppDatabase.fromFile(file);
  }

  @override
  int get schemaVersion => 2;

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
      },
    );
  }
}
