// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daos.dart';

// ignore_for_file: type=lint
mixin _$PlaylistsDaoMixin on DatabaseAccessor<AppDatabase> {
  $CachedPlaylistsTable get cachedPlaylists => attachedDatabase.cachedPlaylists;
  $CachedPlaylistTracksTable get cachedPlaylistTracks =>
      attachedDatabase.cachedPlaylistTracks;
  PlaylistsDaoManager get managers => PlaylistsDaoManager(this);
}

class PlaylistsDaoManager {
  final _$PlaylistsDaoMixin _db;
  PlaylistsDaoManager(this._db);
  $$CachedPlaylistsTableTableManager get cachedPlaylists =>
      $$CachedPlaylistsTableTableManager(
        _db.attachedDatabase,
        _db.cachedPlaylists,
      );
  $$CachedPlaylistTracksTableTableManager get cachedPlaylistTracks =>
      $$CachedPlaylistTracksTableTableManager(
        _db.attachedDatabase,
        _db.cachedPlaylistTracks,
      );
}

mixin _$AlbumsDaoMixin on DatabaseAccessor<AppDatabase> {
  $CachedAlbumsTable get cachedAlbums => attachedDatabase.cachedAlbums;
  AlbumsDaoManager get managers => AlbumsDaoManager(this);
}

class AlbumsDaoManager {
  final _$AlbumsDaoMixin _db;
  AlbumsDaoManager(this._db);
  $$CachedAlbumsTableTableManager get cachedAlbums =>
      $$CachedAlbumsTableTableManager(_db.attachedDatabase, _db.cachedAlbums);
}

mixin _$TrackAlbumMappingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $TrackAlbumMappingsTable get trackAlbumMappings =>
      attachedDatabase.trackAlbumMappings;
  TrackAlbumMappingsDaoManager get managers =>
      TrackAlbumMappingsDaoManager(this);
}

class TrackAlbumMappingsDaoManager {
  final _$TrackAlbumMappingsDaoMixin _db;
  TrackAlbumMappingsDaoManager(this._db);
  $$TrackAlbumMappingsTableTableManager get trackAlbumMappings =>
      $$TrackAlbumMappingsTableTableManager(
        _db.attachedDatabase,
        _db.trackAlbumMappings,
      );
}

mixin _$ArtistsDaoMixin on DatabaseAccessor<AppDatabase> {
  $CachedArtistsTable get cachedArtists => attachedDatabase.cachedArtists;
  ArtistsDaoManager get managers => ArtistsDaoManager(this);
}

class ArtistsDaoManager {
  final _$ArtistsDaoMixin _db;
  ArtistsDaoManager(this._db);
  $$CachedArtistsTableTableManager get cachedArtists =>
      $$CachedArtistsTableTableManager(_db.attachedDatabase, _db.cachedArtists);
}

mixin _$ArtistAlbumsDaoMixin on DatabaseAccessor<AppDatabase> {
  $CachedArtistAlbumListsTable get cachedArtistAlbumLists =>
      attachedDatabase.cachedArtistAlbumLists;
  $ArtistAlbumRelationshipsTable get artistAlbumRelationships =>
      attachedDatabase.artistAlbumRelationships;
  ArtistAlbumsDaoManager get managers => ArtistAlbumsDaoManager(this);
}

class ArtistAlbumsDaoManager {
  final _$ArtistAlbumsDaoMixin _db;
  ArtistAlbumsDaoManager(this._db);
  $$CachedArtistAlbumListsTableTableManager get cachedArtistAlbumLists =>
      $$CachedArtistAlbumListsTableTableManager(
        _db.attachedDatabase,
        _db.cachedArtistAlbumLists,
      );
  $$ArtistAlbumRelationshipsTableTableManager get artistAlbumRelationships =>
      $$ArtistAlbumRelationshipsTableTableManager(
        _db.attachedDatabase,
        _db.artistAlbumRelationships,
      );
}

mixin _$LabelSearchesDaoMixin on DatabaseAccessor<AppDatabase> {
  $CachedLabelSearchesTable get cachedLabelSearches =>
      attachedDatabase.cachedLabelSearches;
  $CachedLabelTracksTable get cachedLabelTracks =>
      attachedDatabase.cachedLabelTracks;
  LabelSearchesDaoManager get managers => LabelSearchesDaoManager(this);
}

class LabelSearchesDaoManager {
  final _$LabelSearchesDaoMixin _db;
  LabelSearchesDaoManager(this._db);
  $$CachedLabelSearchesTableTableManager get cachedLabelSearches =>
      $$CachedLabelSearchesTableTableManager(
        _db.attachedDatabase,
        _db.cachedLabelSearches,
      );
  $$CachedLabelTracksTableTableManager get cachedLabelTracks =>
      $$CachedLabelTracksTableTableManager(
        _db.attachedDatabase,
        _db.cachedLabelTracks,
      );
}

mixin _$MetadataDaoMixin on DatabaseAccessor<AppDatabase> {
  $CacheMetadataTable get cacheMetadata => attachedDatabase.cacheMetadata;
  MetadataDaoManager get managers => MetadataDaoManager(this);
}

class MetadataDaoManager {
  final _$MetadataDaoMixin _db;
  MetadataDaoManager(this._db);
  $$CacheMetadataTableTableManager get cacheMetadata =>
      $$CacheMetadataTableTableManager(_db.attachedDatabase, _db.cacheMetadata);
}

mixin _$SyncMappingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SyncTrackMappingsTable get syncTrackMappings =>
      attachedDatabase.syncTrackMappings;
  SyncMappingsDaoManager get managers => SyncMappingsDaoManager(this);
}

class SyncMappingsDaoManager {
  final _$SyncMappingsDaoMixin _db;
  SyncMappingsDaoManager(this._db);
  $$SyncTrackMappingsTableTableManager get syncTrackMappings =>
      $$SyncTrackMappingsTableTableManager(
        _db.attachedDatabase,
        _db.syncTrackMappings,
      );
}

mixin _$SyncMissingTracksDaoMixin on DatabaseAccessor<AppDatabase> {
  $SyncMissingTracksTable get syncMissingTracks =>
      attachedDatabase.syncMissingTracks;
  SyncMissingTracksDaoManager get managers => SyncMissingTracksDaoManager(this);
}

class SyncMissingTracksDaoManager {
  final _$SyncMissingTracksDaoMixin _db;
  SyncMissingTracksDaoManager(this._db);
  $$SyncMissingTracksTableTableManager get syncMissingTracks =>
      $$SyncMissingTracksTableTableManager(
        _db.attachedDatabase,
        _db.syncMissingTracks,
      );
}

mixin _$SyncPlaylistsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SyncPlaylistsTable get syncPlaylists => attachedDatabase.syncPlaylists;
  $SyncPlaylistTracksTable get syncPlaylistTracks =>
      attachedDatabase.syncPlaylistTracks;
  SyncPlaylistsDaoManager get managers => SyncPlaylistsDaoManager(this);
}

class SyncPlaylistsDaoManager {
  final _$SyncPlaylistsDaoMixin _db;
  SyncPlaylistsDaoManager(this._db);
  $$SyncPlaylistsTableTableManager get syncPlaylists =>
      $$SyncPlaylistsTableTableManager(_db.attachedDatabase, _db.syncPlaylists);
  $$SyncPlaylistTracksTableTableManager get syncPlaylistTracks =>
      $$SyncPlaylistTracksTableTableManager(
        _db.attachedDatabase,
        _db.syncPlaylistTracks,
      );
}
