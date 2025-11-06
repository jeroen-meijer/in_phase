import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:in_phase/src/database/database.dart';
import 'package:in_phase/src/database/tables.dart';
import 'package:in_phase/src/spotify/spotify.dart';

part 'daos.g.dart';

/// A synced track with minimal metadata (used by sync command).
typedef SyncedTrack = ({
  SpotifyTrackId id,
  String name,
  List<String> artistNames,
});

/// DAO for cached playlists operations.
@DriftAccessor(tables: [CachedPlaylists, CachedPlaylistTracks])
class PlaylistsDao extends DatabaseAccessor<AppDatabase>
    with _$PlaylistsDaoMixin {
  PlaylistsDao(super.db);

  /// Gets a cached playlist by ID.
  Future<CachedPlaylist?> getPlaylist(String playlistId) {
    return (select(
      cachedPlaylists,
    )..where((p) => p.id.equals(playlistId))).getSingleOrNull();
  }

  /// Gets all tracks for a playlist.
  Future<List<CachedPlaylistTrack>> getPlaylistTracks(String playlistId) {
    return (select(
      cachedPlaylistTracks,
    )..where((t) => t.playlistId.equals(playlistId))).get();
  }

  /// Inserts or updates a playlist with its tracks.
  Future<void> upsertPlaylist({
    required String playlistId,
    required String snapshotId,
    required String name,
    required List<CachedPlaylistTracksCompanion> tracks,
  }) async {
    await transaction(() async {
      // Upsert playlist
      await into(cachedPlaylists).insertOnConflictUpdate(
        CachedPlaylistsCompanion.insert(
          id: playlistId,
          snapshotId: snapshotId,
          name: name,
          cachedAt: DateTime.now(),
        ),
      );

      // Delete old tracks
      await (delete(
        cachedPlaylistTracks,
      )..where((t) => t.playlistId.equals(playlistId))).go();

      // Insert new tracks
      await batch((batch) {
        batch.insertAll(cachedPlaylistTracks, tracks);
      });
    });
  }
}

/// DAO for cached albums operations.
@DriftAccessor(tables: [CachedAlbums])
class AlbumsDao extends DatabaseAccessor<AppDatabase> with _$AlbumsDaoMixin {
  AlbumsDao(super.db);

  /// Gets a cached album by ID.
  Future<CachedAlbum?> getAlbum(String albumId) {
    return (select(
      cachedAlbums,
    )..where((a) => a.id.equals(albumId))).getSingleOrNull();
  }

  /// Checks if an album exists.
  Future<bool> albumExists(String albumId) async {
    final album = await getAlbum(albumId);
    return album != null;
  }

  /// Inserts or updates an album.
  Future<void> upsertAlbum(CachedAlbumsCompanion album) {
    return into(cachedAlbums).insertOnConflictUpdate(album);
  }

  /// Inserts or updates multiple albums.
  Future<void> upsertAlbums(List<CachedAlbumsCompanion> albums) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(cachedAlbums, albums);
    });
  }

  /// Gets albums by release date range.
  Future<List<CachedAlbum>> getAlbumsByReleaseDate({
    String? fromDate,
    String? toDate,
  }) {
    final query = select(cachedAlbums);

    if (fromDate != null) {
      query.where((a) => a.releaseDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      query.where((a) => a.releaseDate.isSmallerOrEqualValue(toDate));
    }

    return query.get();
  }
}

/// DAO for track-album mappings operations.
@DriftAccessor(tables: [TrackAlbumMappings])
class TrackAlbumMappingsDao extends DatabaseAccessor<AppDatabase>
    with _$TrackAlbumMappingsDaoMixin {
  TrackAlbumMappingsDao(super.db);

  /// Gets the album ID for a track.
  Future<String?> getAlbumIdForTrack(String trackId) async {
    final mapping = await (select(
      trackAlbumMappings,
    )..where((m) => m.trackId.equals(trackId))).getSingleOrNull();
    return mapping?.albumId;
  }

  /// Inserts or updates a track-album mapping.
  Future<void> upsertMapping(String trackId, String albumId) {
    return into(trackAlbumMappings).insertOnConflictUpdate(
      TrackAlbumMappingsCompanion.insert(
        trackId: trackId,
        albumId: albumId,
      ),
    );
  }
}

/// DAO for cached artists operations.
@DriftAccessor(tables: [CachedArtists])
class ArtistsDao extends DatabaseAccessor<AppDatabase> with _$ArtistsDaoMixin {
  ArtistsDao(super.db);

  /// Gets a cached artist by ID.
  Future<CachedArtist?> getArtist(String artistId) {
    return (select(
      cachedArtists,
    )..where((a) => a.id.equals(artistId))).getSingleOrNull();
  }

  /// Checks if an artist is stale (older than 1 month).
  Future<bool> isArtistStale(String artistId) async {
    final artist = await getArtist(artistId);
    if (artist == null) return true;

    final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
    return artist.cachedAt.isBefore(oneMonthAgo);
  }

  /// Inserts or updates an artist.
  Future<void> upsertArtist(CachedArtistsCompanion artist) {
    return into(cachedArtists).insertOnConflictUpdate(artist);
  }
}

/// DAO for cached artist albums operations.
@DriftAccessor(tables: [CachedArtistAlbumLists, ArtistAlbumRelationships])
class ArtistAlbumsDao extends DatabaseAccessor<AppDatabase>
    with _$ArtistAlbumsDaoMixin {
  ArtistAlbumsDao(super.db);

  /// Gets the album list for an artist.
  Future<List<String>> getArtistAlbums(String artistId) async {
    final results =
        await (select(artistAlbumRelationships)
              ..where((r) => r.artistId.equals(artistId))
              ..orderBy([(r) => OrderingTerm.asc(r.orderIndex)]))
            .get();

    return results.map((r) => r.albumId).toList();
  }

  /// Checks if artist albums list is fresh (from today).
  Future<bool> isArtistAlbumsFresh(String artistId) async {
    final list = await (select(
      cachedArtistAlbumLists,
    )..where((l) => l.artistId.equals(artistId))).getSingleOrNull();

    if (list == null) return false;

    final now = DateTime.now();
    final cacheDate = DateTime(
      list.cachedAt.year,
      list.cachedAt.month,
      list.cachedAt.day,
    );
    final today = DateTime(now.year, now.month, now.day);

    return cacheDate.isAtSameMomentAs(today) ||
        cacheDate.isAfter(today.subtract(const Duration(days: 1)));
  }

  /// Inserts or updates an artist's album list.
  Future<void> upsertArtistAlbums({
    required String artistId,
    required List<String> albumIds,
  }) async {
    await transaction(() async {
      // Upsert the list entry
      await into(cachedArtistAlbumLists).insertOnConflictUpdate(
        CachedArtistAlbumListsCompanion.insert(
          artistId: artistId,
          cachedAt: DateTime.now(),
        ),
      );

      // Delete old relationships
      await (delete(
        artistAlbumRelationships,
      )..where((r) => r.artistId.equals(artistId))).go();

      // Insert new relationships
      final relationships = albumIds
          .asMap()
          .entries
          .map(
            (entry) => ArtistAlbumRelationshipsCompanion.insert(
              artistId: artistId,
              albumId: entry.value,
              orderIndex: entry.key,
            ),
          )
          .toList();

      await batch((batch) {
        batch.insertAll(artistAlbumRelationships, relationships);
      });
    });
  }
}

/// DAO for cached label searches operations.
@DriftAccessor(tables: [CachedLabelSearches, CachedLabelTracks])
class LabelSearchesDao extends DatabaseAccessor<AppDatabase>
    with _$LabelSearchesDaoMixin {
  LabelSearchesDao(super.db);

  /// Gets tracks for a label search.
  Future<List<CachedLabelTrack>> getLabelTracks(String labelName) {
    return (select(
      cachedLabelTracks,
    )..where((t) => t.labelName.equals(labelName))).get();
  }

  /// Checks if label search is fresh (from today).
  Future<bool> isLabelSearchFresh(String labelName) async {
    final search = await (select(
      cachedLabelSearches,
    )..where((s) => s.labelName.equals(labelName))).getSingleOrNull();

    if (search == null) return false;

    final now = DateTime.now();
    final cacheDate = DateTime(
      search.cachedAt.year,
      search.cachedAt.month,
      search.cachedAt.day,
    );
    final today = DateTime(now.year, now.month, now.day);

    return cacheDate.isAtSameMomentAs(today) ||
        cacheDate.isAfter(today.subtract(const Duration(days: 1)));
  }

  /// Inserts or updates a label search with its tracks.
  Future<void> upsertLabelSearch({
    required String labelName,
    required List<CachedLabelTracksCompanion> tracks,
  }) async {
    await transaction(() async {
      // Upsert the search entry
      await into(cachedLabelSearches).insertOnConflictUpdate(
        CachedLabelSearchesCompanion.insert(
          labelName: labelName,
          cachedAt: DateTime.now(),
        ),
      );

      // Delete old tracks
      await (delete(
        cachedLabelTracks,
      )..where((t) => t.labelName.equals(labelName))).go();

      // Insert new tracks
      await batch((batch) {
        batch.insertAll(cachedLabelTracks, tracks);
      });
    });
  }
}

/// DAO for cache metadata operations.
@DriftAccessor(tables: [CacheMetadata])
class MetadataDao extends DatabaseAccessor<AppDatabase>
    with _$MetadataDaoMixin {
  MetadataDao(super.db);

  /// Gets the cache metadata.
  Future<CacheMetadataData?> getMetadata() {
    return (select(
      cacheMetadata,
    )..where((m) => m.id.equals(1))).getSingleOrNull();
  }

  /// Updates the last updated timestamp.
  Future<void> updateLastUpdated() {
    return (update(cacheMetadata)..where((m) => m.id.equals(1))).write(
      CacheMetadataCompanion(
        lastUpdated: Value(DateTime.now()),
      ),
    );
  }

  /// Initializes metadata if it doesn't exist.
  Future<void> initializeMetadata() async {
    final existing = await getMetadata();
    if (existing == null) {
      await into(cacheMetadata).insert(
        CacheMetadataCompanion.insert(
          id: const Value(1),
          created: Value(DateTime.now()),
          lastUpdated: Value(DateTime.now()),
        ),
      );
    }
  }
}

/// Helper extension to convert JSON array strings.
extension StringListConverter on String {
  List<String> toStringList() {
    try {
      final decoded = json.decode(this);
      if (decoded is List) {
        return decoded.cast<String>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

/// Helper extension to convert string list to JSON.
extension StringListToJson on List<String> {
  String toJson() => json.encode(this);
}

// ============================================================================
// SYNC CACHE DAOS
// ============================================================================

/// Data access object for sync track mappings.
@DriftAccessor(tables: [SyncTrackMappings])
class SyncMappingsDao extends DatabaseAccessor<AppDatabase>
    with _$SyncMappingsDaoMixin {
  SyncMappingsDao(super.db);

  /// Gets a Rekordbox song ID for a Spotify track ID.
  Future<String?> getMapping(SpotifyTrackId spotifyTrackId) async {
    final result =
        await (select(
              syncTrackMappings,
            )..where((t) => t.spotifyTrackId.equals(spotifyTrackId.toString())))
            .getSingleOrNull();
    return result?.rekordboxSongId;
  }

  /// Gets all mappings as a map of SpotifyTrackId -> RekordboxSongId.
  Future<Map<SpotifyTrackId, String>> getAllMappings() async {
    final results = await select(syncTrackMappings).get();
    return {
      for (final result in results)
        SpotifyTrackId(result.spotifyTrackId): result.rekordboxSongId,
    };
  }

  /// Sets a mapping.
  Future<void> setMapping(
    SpotifyTrackId spotifyTrackId,
    String rekordboxSongId,
  ) async {
    await into(syncTrackMappings).insertOnConflictUpdate(
      SyncTrackMappingsCompanion.insert(
        spotifyTrackId: spotifyTrackId.toString(),
        rekordboxSongId: rekordboxSongId,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Batch sets multiple mappings from Spotify track IDs to Rekordbox song IDs.
  Future<void> setMappingsBatch(Map<SpotifyTrackId, String> mappings) async {
    if (mappings.isEmpty) return;

    final now = DateTime.now();
    await batch((batch) {
      batch.insertAllOnConflictUpdate(
        syncTrackMappings,
        [
          for (final entry in mappings.entries)
            SyncTrackMappingsCompanion.insert(
              spotifyTrackId: entry.key.toString(),
              rekordboxSongId: entry.value,
              createdAt: now,
            ),
        ],
      );
    });
  }
}

/// Data access object for sync missing tracks.
@DriftAccessor(tables: [SyncMissingTracks])
class SyncMissingTracksDao extends DatabaseAccessor<AppDatabase>
    with _$SyncMissingTracksDaoMixin {
  SyncMissingTracksDao(super.db);

  /// Adds or updates a missing track.
  Future<void> insertMissingTrack({
    required SpotifyTrackId spotifyTrackId,
    required String artist,
    required String title,
    String? itunesUrl,
  }) async {
    await into(syncMissingTracks).insertOnConflictUpdate(
      SyncMissingTracksCompanion.insert(
        spotifyTrackId: spotifyTrackId.toString(),
        artist: artist,
        title: title,
        itunesUrl: Value(itunesUrl),
        lastInsertedAt: DateTime.now(),
      ),
    );
  }

  /// Gets all missing tracks.
  Future<List<SyncMissingTrack>> getAllMissingTracks() async {
    return select(syncMissingTracks).get();
  }

  /// Batch inserts multiple missing tracks.
  Future<void> insertMissingTracksBatch(
    List<({SpotifyTrackId id, String artist, String title})> tracks,
  ) async {
    if (tracks.isEmpty) return;

    final now = DateTime.now();
    await batch((batch) {
      batch.insertAllOnConflictUpdate(
        syncMissingTracks,
        [
          for (final track in tracks)
            SyncMissingTracksCompanion.insert(
              spotifyTrackId: track.id.toString(),
              artist: track.artist,
              title: track.title,
              itunesUrl: const Value(null),
              lastInsertedAt: now,
            ),
        ],
      );
    });
  }
}

/// Data access object for sync playlists.
@DriftAccessor(tables: [SyncPlaylists, SyncPlaylistTracks])
class SyncPlaylistsDao extends DatabaseAccessor<AppDatabase>
    with _$SyncPlaylistsDaoMixin {
  SyncPlaylistsDao(super.db);

  /// Gets a synced playlist by ID.
  Future<SyncPlaylist?> getPlaylist(SpotifyPlaylistId playlistId) async {
    return (select(
          syncPlaylists,
        )..where((p) => p.playlistId.equals(playlistId.toString())))
        .getSingleOrNull();
  }

  /// Gets tracks for a synced playlist.
  Future<List<SyncPlaylistTrack>> getPlaylistTracks(
    SpotifyPlaylistId playlistId,
  ) async {
    return (select(syncPlaylistTracks)
          ..where((t) => t.playlistId.equals(playlistId.toString()))
          ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
        .get();
  }

  /// Checks if a playlist has changed by comparing snapshot IDs.
  Future<bool> isPlaylistChanged(
    SpotifyPlaylistId playlistId,
    String snapshotId,
  ) async {
    final cached = await getPlaylist(playlistId);
    if (cached == null) return true;
    return cached.snapshotId != snapshotId;
  }

  /// Caches a playlist with its tracks.
  Future<void> cachePlaylist({
    required SpotifyPlaylistId playlistId,
    required String snapshotId,
    required List<SyncedTrack> tracks,
    required String name,
  }) async {
    await transaction(() async {
      // Insert or update playlist metadata
      await into(syncPlaylists).insertOnConflictUpdate(
        SyncPlaylistsCompanion.insert(
          playlistId: playlistId.toString(),
          snapshotId: snapshotId,
          name: name,
          cachedAt: DateTime.now(),
        ),
      );

      // Delete old tracks
      await (delete(
        syncPlaylistTracks,
      )..where((t) => t.playlistId.equals(playlistId.toString()))).go();

      // Insert new tracks
      for (var i = 0; i < tracks.length; i++) {
        final track = tracks[i];
        await into(syncPlaylistTracks).insert(
          SyncPlaylistTracksCompanion.insert(
            playlistId: playlistId.toString(),
            trackId: track.id.toString(),
            name: track.name,
            artistNames: jsonEncode(track.artistNames),
            orderIndex: i,
          ),
        );
      }
    });
  }
}
