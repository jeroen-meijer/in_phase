// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daos.dart';

// ignore_for_file: type=lint
mixin _$PlaylistsDaoMixin on DatabaseAccessor<AppDatabase> {
  $CachedPlaylistsTable get cachedPlaylists => attachedDatabase.cachedPlaylists;
  $CachedPlaylistTracksTable get cachedPlaylistTracks =>
      attachedDatabase.cachedPlaylistTracks;
}
mixin _$AlbumsDaoMixin on DatabaseAccessor<AppDatabase> {
  $CachedAlbumsTable get cachedAlbums => attachedDatabase.cachedAlbums;
}
mixin _$TrackAlbumMappingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $CachedAlbumsTable get cachedAlbums => attachedDatabase.cachedAlbums;
  $TrackAlbumMappingsTable get trackAlbumMappings =>
      attachedDatabase.trackAlbumMappings;
}
mixin _$ArtistsDaoMixin on DatabaseAccessor<AppDatabase> {
  $CachedArtistsTable get cachedArtists => attachedDatabase.cachedArtists;
}
mixin _$ArtistAlbumsDaoMixin on DatabaseAccessor<AppDatabase> {
  $CachedArtistsTable get cachedArtists => attachedDatabase.cachedArtists;
  $CachedArtistAlbumListsTable get cachedArtistAlbumLists =>
      attachedDatabase.cachedArtistAlbumLists;
  $CachedAlbumsTable get cachedAlbums => attachedDatabase.cachedAlbums;
  $ArtistAlbumRelationshipsTable get artistAlbumRelationships =>
      attachedDatabase.artistAlbumRelationships;
}
mixin _$LabelSearchesDaoMixin on DatabaseAccessor<AppDatabase> {
  $CachedLabelSearchesTable get cachedLabelSearches =>
      attachedDatabase.cachedLabelSearches;
  $CachedLabelTracksTable get cachedLabelTracks =>
      attachedDatabase.cachedLabelTracks;
}
mixin _$MetadataDaoMixin on DatabaseAccessor<AppDatabase> {
  $CacheMetadataTable get cacheMetadata => attachedDatabase.cacheMetadata;
}
mixin _$SyncMappingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SyncTrackMappingsTable get syncTrackMappings =>
      attachedDatabase.syncTrackMappings;
}
mixin _$SyncMissingTracksDaoMixin on DatabaseAccessor<AppDatabase> {
  $SyncMissingTracksTable get syncMissingTracks =>
      attachedDatabase.syncMissingTracks;
}
mixin _$SyncPlaylistsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SyncPlaylistsTable get syncPlaylists => attachedDatabase.syncPlaylists;
  $SyncPlaylistTracksTable get syncPlaylistTracks =>
      attachedDatabase.syncPlaylistTracks;
}
