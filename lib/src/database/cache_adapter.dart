import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:rkdb_dart/src/database/daos.dart';
import 'package:rkdb_dart/src/database/database.dart';
import 'package:rkdb_dart/src/database/database_provider.dart';
import 'package:rkdb_dart/src/entities/entities.dart' as entities;
import 'package:rkdb_dart/src/spotify/spotify.dart';

/// Adapter that provides CrawlCache-like interface backed by Drift database.
///
/// This allows TrackCollector to work with the database without major
/// refactoring.
class CacheAdapter {
  CacheAdapter(this._db);

  final AppDatabase _db;

  // DAO getters - access from database instance
  PlaylistsDao get playlistsDao => _db.playlistsDao;
  AlbumsDao get albumsDao => _db.albumsDao;
  TrackAlbumMappingsDao get trackAlbumMappingsDao => _db.trackAlbumMappingsDao;
  ArtistsDao get artistsDao => _db.artistsDao;
  ArtistAlbumsDao get artistAlbumsDao => _db.artistAlbumsDao;
  LabelSearchesDao get labelSearchesDao => _db.labelSearchesDao;
  MetadataDao get metadataDao => _db.metadataDao;

  /// Checks if a playlist has changed by comparing snapshot IDs.
  Future<bool> isPlaylistChanged(
    SpotifyPlaylistId playlistId,
    String snapshotId,
  ) async {
    final cached = await playlistsDao.getPlaylist(playlistId.toString());
    if (cached == null) return true;
    return cached.snapshotId != snapshotId;
  }

  /// Gets a cached playlist with its tracks.
  Future<entities.CachedPlaylist?> getPlaylist(
    SpotifyPlaylistId playlistId,
  ) async {
    final playlist = await playlistsDao.getPlaylist(playlistId.toString());
    if (playlist == null) return null;

    final tracks = await playlistsDao.getPlaylistTracks(playlistId.toString());

    return entities.CachedPlaylist(
      snapshotId: playlist.snapshotId,
      name: playlist.name,
      tracks: tracks
          .map(
            (t) => entities.CachedPlaylistTrack(
              trackId: SpotifyTrackId(t.trackId),
              uri: t.uri,
              name: t.name,
              artistNames: t.artistNames.toStringList(),
              addedAt: t.addedAt,
              albumId: t.albumId != null ? SpotifyAlbumId(t.albumId!) : null,
            ),
          )
          .toList(),
      cachedAt: playlist.cachedAt,
    );
  }

  /// Caches a playlist with its tracks.
  Future<void> cachePlaylist(
    SpotifyPlaylistId playlistId,
    entities.CachedPlaylist playlist,
  ) async {
    final tracks = playlist.tracks
        .map(
          (t) => CachedPlaylistTracksCompanion.insert(
            trackId: t.trackId.toString(),
            playlistId: playlistId.toString(),
            uri: t.uri,
            name: t.name,
            artistNames: jsonEncode(t.artistNames),
            addedAt: t.addedAt,
            albumId: Value(t.albumId?.toString()),
          ),
        )
        .toList();

    await playlistsDao.upsertPlaylist(
      playlistId: playlistId.toString(),
      snapshotId: playlist.snapshotId,
      name: playlist.name,
      tracks: tracks,
    );
  }

  /// Gets a cached album.
  Future<entities.CachedAlbum?> getAlbum(SpotifyAlbumId albumId) async {
    final album = await albumsDao.getAlbum(albumId.toString());
    if (album == null) return null;

    return entities.CachedAlbum(
      id: SpotifyAlbumId(album.id),
      name: album.name,
      releaseDate: album.releaseDate,
      label: album.label,
      artistNames: album.artistNames?.toStringList(),
      cachedAt: album.cachedAt,
    );
  }

  /// Checks if an album is in the cache.
  Future<bool> hasAlbum(SpotifyAlbumId albumId) =>
      albumsDao.albumExists(albumId.toString());

  /// Caches one or more albums.
  Future<void> cacheAlbums(
    Map<SpotifyAlbumId, entities.CachedAlbum> albums,
  ) async {
    final companions = albums.entries
        .map(
          (e) => CachedAlbumsCompanion.insert(
            id: e.key.toString(),
            name: e.value.name,
            releaseDate: Value(e.value.releaseDate),
            label: Value(e.value.label),
            artistNames: Value(
              e.value.artistNames != null
                  ? jsonEncode(e.value.artistNames)
                  : null,
            ),
            cachedAt: e.value.cachedAt,
          ),
        )
        .toList();

    await albumsDao.upsertAlbums(companions);
  }

  /// Gets a cached artist.
  Future<entities.CachedArtist?> getArtist(SpotifyArtistId artistId) async {
    final artist = await artistsDao.getArtist(artistId.toString());
    if (artist == null) return null;

    return entities.CachedArtist(
      id: SpotifyArtistId(artist.id),
      name: artist.name,
      cachedAt: artist.cachedAt,
    );
  }

  /// Caches an artist.
  Future<void> cacheArtist(
    SpotifyArtistId artistId,
    entities.CachedArtist artist,
  ) async {
    await artistsDao.upsertArtist(
      CachedArtistsCompanion.insert(
        id: artistId.toString(),
        name: artist.name,
        cachedAt: artist.cachedAt,
      ),
    );
  }

  /// Gets cached artist albums list.
  Future<entities.CachedArtistAlbums?> getArtistAlbums(
    SpotifyArtistId artistId,
  ) async {
    final isFresh = await artistAlbumsDao.isArtistAlbumsFresh(
      artistId.toString(),
    );

    if (!isFresh) return null;

    final albumIds = await artistAlbumsDao.getArtistAlbums(
      artistId.toString(),
    );

    final list = await (_db.select(
      _db.cachedArtistAlbumLists,
    )..where((l) => l.artistId.equals(artistId.toString()))).getSingleOrNull();
    if (list == null) return null;

    return entities.CachedArtistAlbums(
      artistId: artistId,
      albumIds: albumIds.map(SpotifyAlbumId.new).toList(),
      cachedAt: list.cachedAt,
    );
  }

  /// Caches artist albums list.
  Future<void> cacheArtistAlbums(
    SpotifyArtistId artistId,
    entities.CachedArtistAlbums albums,
  ) async {
    await artistAlbumsDao.upsertArtistAlbums(
      artistId: artistId.toString(),
      albumIds: albums.albumIds.map((id) => id.toString()).toList(),
    );
  }

  /// Gets cached label search.
  Future<entities.CachedLabelSearch?> getLabelSearch(String labelName) async {
    final isFresh = await labelSearchesDao.isLabelSearchFresh(labelName);
    if (!isFresh) return null;

    final tracks = await labelSearchesDao.getLabelTracks(labelName);
    final search = await (_db.select(
      _db.cachedLabelSearches,
    )..where((s) => s.labelName.equals(labelName))).getSingleOrNull();

    if (search == null) return null;

    return entities.CachedLabelSearch(
      labelName: labelName,
      tracks: tracks
          .map(
            (t) => entities.CachedLabelTrack(
              trackId: SpotifyTrackId(t.trackId),
              uri: t.uri,
              name: t.name,
              artistNames: t.artistNames.toStringList(),
              albumId: t.albumId != null ? SpotifyAlbumId(t.albumId!) : null,
              albumName: t.albumName,
              releaseDate: t.releaseDate,
            ),
          )
          .toList(),
      cachedAt: search.cachedAt,
    );
  }

  /// Caches label search results.
  Future<void> cacheLabelSearch(
    String labelName,
    entities.CachedLabelSearch search,
  ) async {
    final tracks = search.tracks
        .map(
          (t) => CachedLabelTracksCompanion.insert(
            trackId: t.trackId.toString(),
            labelName: labelName,
            uri: t.uri,
            name: t.name,
            artistNames: jsonEncode(t.artistNames),
            albumId: Value(t.albumId?.toString()),
            albumName: Value(t.albumName),
            releaseDate: Value(t.releaseDate),
          ),
        )
        .toList();

    await labelSearchesDao.upsertLabelSearch(
      labelName: labelName,
      tracks: tracks,
    );
  }

  /// Updates the last updated timestamp.
  Future<void> updateMetadata() async {
    await metadataDao.updateLastUpdated();
  }
}

/// Gets a cache adapter for the database from the current zone.
CacheAdapter getCacheAdapter() => CacheAdapter(db());
