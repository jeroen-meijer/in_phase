import 'package:drift/drift.dart';

/// Cached playlists table.
class CachedPlaylists extends Table {
  /// Spotify playlist ID (primary key).
  TextColumn get id => text()();

  /// Snapshot ID for change detection.
  TextColumn get snapshotId => text()();

  /// Playlist name.
  TextColumn get name => text()();

  /// When this was cached.
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached playlist tracks table.
class CachedPlaylistTracks extends Table {
  /// Spotify track ID.
  TextColumn get trackId => text()();

  /// Playlist ID (foreign key).
  TextColumn get playlistId => text().references(CachedPlaylists, #id)();

  /// Track URI.
  TextColumn get uri => text()();

  /// Track name.
  TextColumn get name => text()();

  /// Artist names (JSON array).
  TextColumn get artistNames => text()();

  /// When track was added to playlist.
  DateTimeColumn get addedAt => dateTime()();

  /// Album ID (optional).
  TextColumn get albumId => text().nullable()();

  @override
  Set<Column> get primaryKey => {trackId, playlistId, addedAt};
}

/// Cached albums table.
class CachedAlbums extends Table {
  /// Spotify album ID (primary key).
  TextColumn get id => text()();

  /// Album name.
  TextColumn get name => text()();

  /// Release date string.
  TextColumn get releaseDate => text().nullable()();

  /// Label name.
  TextColumn get label => text().nullable()();

  /// Artist names (JSON array).
  TextColumn get artistNames => text().nullable()();

  /// When this was cached.
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Mapping of tracks to their albums.
class TrackAlbumMappings extends Table {
  /// Spotify track ID.
  TextColumn get trackId => text()();

  /// Spotify album ID.
  TextColumn get albumId => text().references(CachedAlbums, #id)();

  @override
  Set<Column> get primaryKey => {trackId, albumId};
}

/// Cached artists table.
class CachedArtists extends Table {
  /// Spotify artist ID (primary key).
  TextColumn get id => text()();

  /// Artist name.
  TextColumn get name => text()();

  /// When this was cached.
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached artist album lists table.
class CachedArtistAlbumLists extends Table {
  /// Spotify artist ID (primary key, foreign key).
  TextColumn get artistId => text().references(CachedArtists, #id)();

  /// When this list was cached.
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {artistId};
}

/// Artist-album relationships (many-to-many).
class ArtistAlbumRelationships extends Table {
  /// Spotify artist ID.
  TextColumn get artistId => text().references(CachedArtists, #id)();

  /// Spotify album ID.
  TextColumn get albumId => text().references(CachedAlbums, #id)();

  /// Order in the artist's album list.
  IntColumn get orderIndex => integer()();

  @override
  Set<Column> get primaryKey => {artistId, albumId};
}

/// Cached label searches table.
class CachedLabelSearches extends Table {
  /// Label name (primary key).
  TextColumn get labelName => text()();

  /// When this search was cached.
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {labelName};
}

/// Cached label search track results.
class CachedLabelTracks extends Table {
  /// Spotify track ID.
  TextColumn get trackId => text()();

  /// Label name (foreign key).
  TextColumn get labelName =>
      text().references(CachedLabelSearches, #labelName)();

  /// Track URI.
  TextColumn get uri => text()();

  /// Track name.
  TextColumn get name => text()();

  /// Artist names (JSON array).
  TextColumn get artistNames => text()();

  /// Album ID (optional).
  TextColumn get albumId => text().nullable()();

  /// Album name (optional).
  TextColumn get albumName => text().nullable()();

  /// Release date (optional).
  TextColumn get releaseDate => text().nullable()();

  @override
  Set<Column> get primaryKey => {trackId, labelName};
}

/// Cache metadata table.
class CacheMetadata extends Table {
  /// Single row ID.
  IntColumn get id => integer()();

  /// When cache was created.
  DateTimeColumn get created => dateTime().nullable()();

  /// When cache was last updated.
  DateTimeColumn get lastUpdated => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================================
// SYNC CACHE TABLES
// ============================================================================

/// Sync track mappings (Spotify track ID -> Rekordbox song ID).
class SyncTrackMappings extends Table {
  /// Spotify track ID.
  TextColumn get spotifyTrackId => text()();

  /// Rekordbox song ID.
  TextColumn get rekordboxSongId => text()();

  /// When this mapping was created.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {spotifyTrackId};
}

/// Missing tracks that couldn't be matched in Rekordbox.
class SyncMissingTracks extends Table {
  /// Spotify track ID.
  TextColumn get spotifyTrackId => text()();

  /// Artist names.
  TextColumn get artist => text()();

  /// Track title.
  TextColumn get title => text()();

  /// iTunes URL (nullable).
  TextColumn get itunesUrl => text().nullable()();

  /// When this track was last inserted.
  DateTimeColumn get lastInsertedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {spotifyTrackId};
}

/// Synced playlists metadata.
class SyncPlaylists extends Table {
  /// Playlist ID.
  TextColumn get playlistId => text()();

  /// Snapshot ID.
  TextColumn get snapshotId => text()();

  /// Playlist name.
  TextColumn get name => text()();

  /// When this playlist was cached.
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {playlistId};
}

/// Tracks in synced playlists.
class SyncPlaylistTracks extends Table {
  /// Playlist ID.
  TextColumn get playlistId => text()();

  /// Spotify track ID.
  TextColumn get trackId => text()();

  /// Track name.
  TextColumn get name => text()();

  /// Artist names (JSON array).
  TextColumn get artistNames => text()();

  /// Position in the playlist.
  IntColumn get orderIndex => integer()();

  @override
  Set<Column> get primaryKey => {playlistId, trackId, orderIndex};
}
