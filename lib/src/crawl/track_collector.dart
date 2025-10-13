import 'package:equatable/equatable.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:rkdb_dart/src/crawl/date_utils.dart';
import 'package:rkdb_dart/src/database/database.exports.dart';
import 'package:rkdb_dart/src/entities/entities.dart' as entities;
import 'package:rkdb_dart/src/logger/logger.dart';
import 'package:rkdb_dart/src/misc/misc.dart';
import 'package:rkdb_dart/src/spotify/spotify.dart';
import 'package:spotify/spotify.dart';

/// {@template collected_track}
/// Represents a track collected from a source with metadata.
/// {@endtemplate}
class CollectedTrack {
  /// {@macro collected_track}
  const CollectedTrack({
    required this.id,
    required this.uri,
    required this.name,
    required this.artistNames,
    required this.addedAt,
    required this.source,
    this.albumId,
  });

  final SpotifyTrackId id;
  final String uri;
  final String name;
  final List<String> artistNames;
  final DateTime addedAt;
  final CollectedTrackSource source;
  final SpotifyAlbumId? albumId;
}

/// {@template collected_track_source}
/// The source of a collected track.
/// {@endtemplate}
sealed class CollectedTrackSource with EquatableMixin {
  /// {@macro collected_track_source}
  const CollectedTrackSource();

  @override
  List<Object?> get props => [];
}

/// {@template collected_track_source_playlist}
/// The source of a collected track from a playlist.
/// {@endtemplate}
class CollectedTrackSourcePlaylist extends CollectedTrackSource {
  /// {@macro collected_track_source_playlist}
  const CollectedTrackSourcePlaylist({
    required this.id,
    required this.name,
  });

  /// The ID of the playlist.
  final String id;

  /// The name of the playlist.
  final String name;

  @override
  List<Object?> get props => [id, name];
}

/// {@template collected_track_source_artist}
/// The source of a collected track from a artist.
/// {@endtemplate}
class CollectedTrackSourceArtist extends CollectedTrackSource {
  /// {@macro collected_track_source_artist}
  const CollectedTrackSourceArtist({
    required this.id,
    required this.name,
  });

  /// The ID of the artist.
  final String id;

  /// The name of the artist.
  final String name;

  @override
  List<Object?> get props => [id, name];
}

/// {@template collected_track_source_label}
/// The source of a collected track from a label.
/// {@endtemplate}
class CollectedTrackSourceLabel extends CollectedTrackSource {
  /// {@macro collected_track_source_label}
  const CollectedTrackSourceLabel({
    required this.name,
  });

  /// The name of the label.
  final String name;

  @override
  List<Object?> get props => [name];
}

/// {@template track_collector}
/// Collects tracks from various Spotify sources (playlists, artists, labels).
/// {@endtemplate}
class TrackCollector {
  /// {@macro track_collector}
  TrackCollector({
    required this.api,
    required this.requestPool,
    required this.cacheAdapter,
  });

  final SpotifyApi api;
  final RequestPool requestPool;
  final CacheAdapter cacheAdapter;

  /// Collects tracks from a playlist within the specified date range.
  Future<List<CollectedTrack>> collectFromPlaylist(
    String playlistId,
    DateTime cutoffDate,
    DateTime endDate,
    entities.PlaylistTrackDateMode dateMode,
  ) async {
    log.info('  📜 Collecting from playlist: $playlistId');

    final spotifyPlaylistId = SpotifyPlaylistId(playlistId);

    // Fetch playlist info to get snapshot ID
    final playlist = await requestPool.request(
      () => api.playlists.get(playlistId),
      identifier: SpotifyCacheIdentifier.playlist(spotifyPlaylistId),
    );

    final snapshotId = playlist.snapshotId ?? '';
    final playlistName = playlist.name ?? 'Unknown Playlist';

    log.info('    Playlist: $playlistName (snapshot: $snapshotId)');

    // Check if cached and unchanged
    final cachedPlaylist = await cacheAdapter.getPlaylist(spotifyPlaylistId);
    final isChanged = await cacheAdapter.isPlaylistChanged(
      spotifyPlaylistId,
      snapshotId,
    );
    if (cachedPlaylist != null && !isChanged) {
      log.info('    💾 Using cached playlist data');
      return _filterPlaylistTracksByDate(
        cachedPlaylist.tracks,
        cutoffDate,
        endDate,
        playlistId,
        playlistName,
        dateMode,
      );
    }

    // Fetch tracks from Spotify
    log.info('    🔄 Fetching tracks from Spotify...');
    final playlistTracks = await requestPool.request(
      () => api.playlists.getTracksByPlaylistId(playlistId).all(50),
      identifier: SpotifyCacheIdentifier.playlistTracks(spotifyPlaylistId),
    );

    // Cache the playlist
    final cachedTracks = playlistTracks.where((pt) => pt.track?.id != null).map(
      (playlistTrack) {
        final track = playlistTrack.track!;
        return entities.CachedPlaylistTrack(
          trackId: SpotifyTrackId(track.id!),
          uri: track.uri!,
          name: track.name!,
          artistNames: track.artists?.map((a) => a.name ?? '').toList() ?? [],
          addedAt: playlistTrack.addedAt!,
          albumId: SpotifyAlbumId(track.album!.id!),
        );
      },
    ).toList();

    await cacheAdapter.cachePlaylist(
      spotifyPlaylistId,
      entities.CachedPlaylist(
        snapshotId: snapshotId,
        name: playlistName,
        tracks: cachedTracks,
        cachedAt: DateTime.now(),
      ),
    );

    log.info('    ✅ Found ${playlistTracks.length} tracks from playlist');

    // Convert to CollectedTrack with date filtering
    final collectedTracks = <CollectedTrack>[];

    for (final playlistTrack in playlistTracks) {
      if (playlistTrack.track?.id == null) continue;

      final track = playlistTrack.track!;
      DateTime trackDate;

      // Determine which date to use based on the mode
      if (dateMode == entities.PlaylistTrackDateMode.addedDate) {
        trackDate = playlistTrack.addedAt!;
      } else {
        // Use release date - need to get it from the album
        var releaseDate = track.album?.releaseDate;
        var albumToCache = track.album;

        // If release date is missing, try to fetch the full album
        if (releaseDate == null && track.album?.id != null) {
          try {
            final album = await requestPool.request(
              () => api.albums.get(track.album!.id!),
              identifier: SpotifyCacheIdentifier.album(
                SpotifyAlbumId(track.album!.id!),
              ),
            );
            releaseDate = album.releaseDate;
            albumToCache = album;
          } catch (e) {
            log.warning(
              '    ⚠️  Error fetching album ${track.album!.id!}: $e',
            );
          }
        }

        if (releaseDate == null) {
          // Skip tracks without release date
          continue;
        }

        // Cache the album info if we have it and it's not already cached
        if (albumToCache?.id != null) {
          final albumId = SpotifyAlbumId(albumToCache!.id!);
          final hasAlbum = await cacheAdapter.hasAlbum(albumId);
          if (!hasAlbum) {
            await cacheAdapter.cacheAlbums({
              albumId: entities.CachedAlbum(
                id: albumId,
                name: albumToCache.name ?? '',
                releaseDate: releaseDate,
                // AlbumSimple doesn't have label, only full Album does
                label: albumToCache is Album ? albumToCache.label : null,
                artistNames: albumToCache.artists
                    ?.map((a) => a.name ?? '')
                    .toList(),
                cachedAt: DateTime.now(),
              ),
            });
          }
        }

        try {
          trackDate = parseSpotifyReleaseDate(releaseDate);
        } catch (e) {
          log.warning(
            '    ⚠️  Could not parse release date for track ${track.id}: '
            '$releaseDate',
          );
          continue;
        }
      }

      // Filter by date range
      if (!trackDate.isInRange(cutoffDate, endDate)) continue;

      final collectedTrack = CollectedTrack(
        id: SpotifyTrackId(track.id!),
        uri: track.uri!,
        name: track.name!,
        artistNames: track.artists?.map((a) => a.name ?? '').toList() ?? [],
        addedAt: trackDate,
        source: CollectedTrackSourcePlaylist(
          id: playlistId,
          name: playlistName,
        ),
        albumId: track.album?.id != null
            ? SpotifyAlbumId(track.album!.id!)
            : null,
      );

      collectedTracks.add(collectedTrack);

      // Log individual track collection
      final dateModeText = dateMode == entities.PlaylistTrackDateMode.addedDate
          ? 'added to playlist'
          : 'released';
      final artistNames =
          track.artists?.map((a) => a.name ?? '').join(', ') ??
          'Unknown Artist';
      log.debug(
        '    ✓ $artistNames - ${track.name} '
        '(included because $dateModeText on ${formatDate(trackDate)})',
      );
    }

    log.info(
      '    📅 ${collectedTracks.length} tracks in date range '
      '(${formatDate(cutoffDate)} - ${formatDate(endDate)}) '
      // ignore: lines_longer_than_80_chars
      '(using ${dateMode == entities.PlaylistTrackDateMode.addedDate ? 'added date' : 'release date'})',
    );

    return collectedTracks;
  }

  /// Collects tracks from an artist's recent releases within the date range.
  Future<List<CollectedTrack>> collectFromArtist(
    String artistId,
    DateTime cutoffDate,
    DateTime endDate,
  ) async {
    log.info('  🎤 Collecting from artist: $artistId');

    final spotifyArtistId = SpotifyArtistId(artistId);

    // Check if artist metadata is cached and fresh (< 1 month old)
    final cachedArtist = await cacheAdapter.getArtist(spotifyArtistId);
    final String artistName;

    if (cachedArtist != null && !cachedArtist.isStale) {
      log.info('    💾 Using cached artist metadata');
      artistName = cachedArtist.name;
    } else {
      // Fetch artist info
      final artist = await requestPool.request(
        () => api.artists.get(artistId),
        identifier: SpotifyCacheIdentifier.artist(spotifyArtistId),
      );

      artistName = artist.name ?? 'Unknown Artist';

      // Cache artist metadata
      await cacheAdapter.cacheArtist(
        spotifyArtistId,
        entities.CachedArtist(
          id: spotifyArtistId,
          name: artistName,
          cachedAt: DateTime.now(),
        ),
      );
    }

    log.info('    Artist: $artistName');

    // Check if artist albums are cached and fresh (from today)
    final cachedArtistAlbums = await cacheAdapter.getArtistAlbums(
      spotifyArtistId,
    );
    final List<Album> albums;

    if (cachedArtistAlbums != null && cachedArtistAlbums.isFreshToday) {
      log.info('    💾 Using cached artist albums list (fresh today)');
      // Reconstruct album list from cached IDs
      // We still need minimal album info, but we can use our album cache
      albums = [];
      for (final albumId in cachedArtistAlbums.albumIds) {
        final cachedAlbum = await cacheAdapter.getAlbum(albumId);
        if (cachedAlbum != null && cachedAlbum.releaseDate != null) {
          // Create minimal Album object from cache
          albums.add(
            Album()
              ..id = albumId.toString()
              ..name = cachedAlbum.name
              ..releaseDate = cachedAlbum.releaseDate,
          );
        }
      }
      log.info('    Reconstructed ${albums.length} albums from cache');
    } else {
      log.info(
        '    🔄 Fetching artist albums '
        '${cachedArtistAlbums != null ? '(cache stale)' : '(not cached)'}',
      );

      // Fetch albums with early termination (cache-based and date-based)
      // Using getPage() instead of stream() to enable RequestPool deduplication
      final allAlbumIds = <SpotifyAlbumId>[];
      albums = [];

      const limit = 50;
      var offset = 0;
      var pagesFetched = 0;
      var hitCache = false;
      var hitDateCutoff = false;

      while (true) {
        pagesFetched++;
        log.debug(
          '    Fetching page $pagesFetched of artist albums (offset: $offset)',
        );

        // Fetch page with RequestPool for deduplication and retry
        final page = await requestPool.request(
          () => api.artists.albums(artistId).getPage(limit, offset),
          identifier: SpotifyCacheIdentifier.artistAlbumsPage(
            spotifyArtistId,
            offset,
          ),
        );

        for (final album in page.items ?? <Album>[]) {
          if (album.id == null) continue;

          final albumId = SpotifyAlbumId(album.id!);
          allAlbumIds.add(albumId);

          // Check if we hit a cached album - if so, stop fetching
          if (cachedArtistAlbums != null &&
              cachedArtistAlbums.albumIds.contains(albumId)) {
            log.info(
              '    ✓ Found cached album "${album.name}", '
              'stopping fetch and using cache',
            );
            hitCache = true;
            break;
          }

          // Check if this album is too old (beyond our date range)
          // Since albums come newest-first, we can stop here
          if (album.releaseDate != null) {
            try {
              final releaseDate = parseSpotifyReleaseDate(album.releaseDate!);
              if (releaseDate.isBefore(cutoffDate)) {
                log.info(
                  '    ✓ Found album "${album.name}" from '
                  '${formatDate(releaseDate)}, before cutoff '
                  '${formatDate(cutoffDate)}, stopping fetch',
                );
                hitDateCutoff = true;
                break;
              }
            } catch (e) {
              log.warning(
                '    ⚠️  Could not parse release date: ${album.releaseDate}',
              );
            }
          }

          albums.add(album);
        }

        // Stop if we hit cache, date cutoff, or reached the last page
        if (hitCache || hitDateCutoff || page.isLast) break;

        // Move to next page
        offset = page.nextOffset;
      }

      // If we hit cache, append the rest from cached list
      if (hitCache && cachedArtistAlbums != null) {
        var foundOurPosition = false;
        for (final cachedAlbumId in cachedArtistAlbums.albumIds) {
          if (!foundOurPosition) {
            if (allAlbumIds.contains(cachedAlbumId)) {
              foundOurPosition = true;
            }
            continue;
          }

          // Add remaining cached albums
          final cachedAlbum = await cacheAdapter.getAlbum(cachedAlbumId);
          if (cachedAlbum != null && cachedAlbum.releaseDate != null) {
            albums.add(
              Album()
                ..id = cachedAlbumId.toString()
                ..name = cachedAlbum.name
                ..releaseDate = cachedAlbum.releaseDate,
            );
            allAlbumIds.add(cachedAlbumId);
          }
        }
      }

      // Cache the album IDs list
      await cacheAdapter.cacheArtistAlbums(
        spotifyArtistId,
        entities.CachedArtistAlbums(
          artistId: spotifyArtistId,
          albumIds: allAlbumIds,
          cachedAt: DateTime.now(),
        ),
      );

      final terminationReason = hitCache
          ? 'cache hit'
          : hitDateCutoff
          ? 'date cutoff'
          : 'full fetch';
      log.info(
        '    Found ${albums.length} albums/singles '
        '($pagesFetched pages, $terminationReason)',
      );
    }

    // Filter albums by release date
    final recentAlbums = <Album>[];
    for (final album in albums) {
      var releaseDate = album.releaseDate;
      var albumToCache = album;

      // If release date is missing, try to fetch the full album
      if (releaseDate == null && album.id != null) {
        try {
          final fullAlbum = await requestPool.request(
            () => api.albums.get(album.id!),
            identifier: SpotifyCacheIdentifier.album(
              SpotifyAlbumId(album.id!),
            ),
          );
          releaseDate = fullAlbum.releaseDate;
          albumToCache = fullAlbum;
        } catch (e) {
          log.warning(
            '    ⚠️  Error fetching album ${album.id!}: $e',
          );
        }
      }

      if (releaseDate == null) continue;

      // Cache the album info if we have it and it's not already cached
      if (albumToCache.id != null) {
        final albumId = SpotifyAlbumId(albumToCache.id!);
        final hasAlbum = await cacheAdapter.hasAlbum(albumId);
        if (!hasAlbum) {
          await cacheAdapter.cacheAlbums({
            albumId: entities.CachedAlbum(
              id: albumId,
              name: albumToCache.name ?? '',
              releaseDate: releaseDate,
              label: albumToCache.label,
              artistNames: albumToCache.artists
                  ?.map((a) => a.name ?? '')
                  .toList(),
              cachedAt: DateTime.now(),
            ),
          });
        }
      }

      try {
        final parsedReleaseDate = parseSpotifyReleaseDate(releaseDate);
        if (parsedReleaseDate.isInRange(cutoffDate, endDate)) {
          recentAlbums.add(album);
        }
      } catch (e) {
        log.warning(
          '    ⚠️  Could not parse release date: $releaseDate',
        );
      }
    }

    log.info('    ${recentAlbums.length} albums/singles in date range');

    // Fetch tracks from recent albums
    final allTracks = <CollectedTrack>[];
    for (final album in recentAlbums) {
      try {
        final albumFull = await requestPool.request(
          () => api.albums.get(album.id!),
          identifier: SpotifyCacheIdentifier.album(SpotifyAlbumId(album.id!)),
        );

        final releaseDate = parseSpotifyReleaseDate(album.releaseDate!);

        for (final track in albumFull.tracks ?? <TrackSimple>[]) {
          if (track.id != null) {
            final collectedTrack = CollectedTrack(
              id: SpotifyTrackId(track.id!),
              uri: track.uri!,
              name: track.name!,
              artistNames:
                  track.artists?.map((a) => a.name ?? '').toList() ?? [],
              addedAt: releaseDate,
              source: CollectedTrackSourceArtist(
                id: artistId,
                name: artistName,
              ),
              albumId: SpotifyAlbumId(album.id!),
            );

            allTracks.add(collectedTrack);

            // Log individual track collection
            final artistNames =
                track.artists?.map((a) => a.name ?? '').join(', ') ??
                'Unknown Artist';
            log.debug(
              '    ✓ $artistNames - ${track.name} '
              '(included because released on ${formatDate(releaseDate)})',
            );
          }
        }

        // Cache the album
        final albumId = SpotifyAlbumId(album.id!);
        await cacheAdapter.cacheAlbums({
          albumId: entities.CachedAlbum(
            id: albumId,
            name: albumFull.name ?? '',
            releaseDate: album.releaseDate,
            label: albumFull.label,
            artistNames: albumFull.artists?.map((a) => a.name ?? '').toList(),
            cachedAt: DateTime.now(),
          ),
        });
      } catch (e) {
        log.warning('    ⚠️  Error processing album ${album.id}: $e');
      }
    }

    log.info('    ✅ Found ${allTracks.length} tracks from artist');

    return allTracks;
  }

  /// Collects tracks from a label's releases within the date range.
  Future<List<CollectedTrack>> collectFromLabel(
    String labelName,
    DateTime cutoffDate,
    DateTime endDate,
  ) async {
    log.info('  🏷️  Collecting from label: $labelName');

    // Check if label search is cached and fresh (from today)
    final cachedLabelSearch = await cacheAdapter.getLabelSearch(labelName);
    final List<Track> tracks;

    if (cachedLabelSearch != null && cachedLabelSearch.isFreshToday) {
      log
        ..info('    💾 Using cached label search results (fresh today)')
        ..info('    Cached ${cachedLabelSearch.tracks.length} tracks');

      // Reconstruct Track objects from cached data
      tracks = cachedLabelSearch.tracks.map((cachedTrack) {
        final track = Track()
          ..id = cachedTrack.trackId.toString()
          ..uri = cachedTrack.uri
          ..name = cachedTrack.name
          ..artists = cachedTrack.artistNames.map((name) {
            return Artist()..name = name;
          }).toList();

        // Reconstruct album (simplified)
        if (cachedTrack.albumId != null) {
          track.album = AlbumSimple()
            ..id = cachedTrack.albumId.toString()
            ..name = cachedTrack.albumName
            ..releaseDate = cachedTrack.releaseDate;
        }

        return track;
      }).toList();
    } else {
      log.info(
        '    🔄 Searching for label tracks '
        '${cachedLabelSearch != null ? '(cache stale)' : '(not cached)'}',
      );

      // Search for tracks by label
      final searchQuery = 'label:"$labelName"';
      final searchResults = await requestPool.request(
        () => api.search.get(searchQuery, types: [SearchType.track]).first(50),
        identifier: SpotifyCacheIdentifier.labelSearch(labelName),
      );

      tracks = searchResults.expand((page) {
        return page.items?.whereType<Track>() ?? <Track>[];
      }).toList();

      // Cache the search result tracks with full data
      final cachedTracks = tracks
          .where((t) => t.id != null && t.uri != null && t.name != null)
          .map((t) {
            return entities.CachedLabelTrack(
              trackId: SpotifyTrackId(t.id!),
              uri: t.uri!,
              name: t.name!,
              artistNames: t.artists?.map((a) => a.name ?? '').toList() ?? [],
              albumId: t.album?.id != null
                  ? SpotifyAlbumId(t.album!.id!)
                  : null,
              albumName: t.album?.name,
              releaseDate: t.album?.releaseDate,
            );
          })
          .toList();

      await cacheAdapter.cacheLabelSearch(
        labelName,
        entities.CachedLabelSearch(
          labelName: labelName,
          tracks: cachedTracks,
          cachedAt: DateTime.now(),
        ),
      );
    }

    log.info('    Found ${tracks.length} tracks from search');

    // Filter tracks by release date and validate label match
    final collectedTracks = <CollectedTrack>[];
    final mismatchedLabels = <String>{};

    for (final track in tracks) {
      var releaseDate = track.album?.releaseDate;
      var albumToCache = track.album;

      // If release date is missing, try to fetch the full album
      if (releaseDate == null && track.album?.id != null) {
        try {
          final album = await requestPool.request(
            () => api.albums.get(track.album!.id!),
            identifier: SpotifyCacheIdentifier.album(
              SpotifyAlbumId(track.album!.id!),
            ),
          );
          releaseDate = album.releaseDate;
          albumToCache = album;
        } catch (e) {
          log.warning(
            '    ⚠️  Error fetching album ${track.album!.id!}: $e',
          );
        }
      }

      if (releaseDate == null) continue;

      // Cache the album info early if we have it and it's not already cached
      if (albumToCache?.id != null) {
        final albumId = SpotifyAlbumId(albumToCache!.id!);
        final hasAlbum = await cacheAdapter.hasAlbum(albumId);
        if (!hasAlbum) {
          await cacheAdapter.cacheAlbums({
            albumId: entities.CachedAlbum(
              id: albumId,
              name: albumToCache.name ?? '',
              releaseDate: releaseDate,
              // AlbumSimple doesn't have label, only full Album does
              label: albumToCache is Album ? albumToCache.label : null,
              artistNames: albumToCache.artists
                  ?.map((a) => a.name ?? '')
                  .toList(),
              cachedAt: DateTime.now(),
            ),
          });
        }
      }

      try {
        final parsedReleaseDate = parseSpotifyReleaseDate(releaseDate);
        if (!parsedReleaseDate.isInRange(cutoffDate, endDate)) continue;

        final trackAlbumId = SpotifyAlbumId(track.album!.id!);
        final cachedAlbum = await cacheAdapter.getAlbum(trackAlbumId);
        Album? fullAlbum;

        final String trackLabel;
        if (cachedAlbum case entities.CachedAlbum(:final label?)) {
          trackLabel = label;
        } else {
          final album = await requestPool.request(
            () => api.albums.get(track.album!.id!),
            identifier: SpotifyCacheIdentifier.album(trackAlbumId),
          );
          fullAlbum = album;
          trackLabel = fullAlbum.label!;
        }

        // Validate label match using fuzzy matching
        final matchRatio = ratio(
          labelName.toLowerCase(),
          trackLabel.toLowerCase(),
        );

        if (matchRatio >= 90) {
          // High confidence match
          final collectedTrack = CollectedTrack(
            id: SpotifyTrackId(track.id!),
            uri: track.uri!,
            name: track.name!,
            artistNames: track.artists?.map((a) => a.name ?? '').toList() ?? [],
            addedAt: parsedReleaseDate,
            source: CollectedTrackSourceLabel(name: labelName),
            albumId: track.album?.id != null
                ? SpotifyAlbumId(track.album!.id!)
                : null,
          );

          collectedTracks.add(collectedTrack);

          // Log individual track collection
          final artistNames =
              track.artists?.map((a) => a.name ?? '').join(', ') ??
              'Unknown Artist';
          log.debug(
            '    ✓ $artistNames - ${track.name} '
            '(included because released on ${formatDate(parsedReleaseDate)} '
            'from label "$labelName")',
          );

          // Cache the album if we have a full 'album' or the track has a simple
          // album stored
          if ((fullAlbum != null) ||
              (cachedAlbum == null && track.album != null)) {
            final albumIdString = fullAlbum?.id ?? track.album!.id!;
            final albumId = SpotifyAlbumId(albumIdString);

            await cacheAdapter.cacheAlbums({
              albumId: entities.CachedAlbum(
                id: albumId,
                name: fullAlbum?.name ?? track.album!.name!,
                releaseDate: fullAlbum?.releaseDate ?? track.album!.releaseDate,
                label: trackLabel,
                artistNames: (fullAlbum?.artists ?? track.album!.artists)
                    ?.map((a) => a.name ?? '')
                    .toList(),
                cachedAt: DateTime.now(),
              ),
            });
          }
        } else if (trackLabel.isNotEmpty) {
          mismatchedLabels.add(trackLabel);
        }
      } catch (e) {
        log.warning('    ⚠️  Error processing track ${track.id}: $e');
      }
    }

    if (mismatchedLabels.isNotEmpty) {
      log.info(
        '    ⚠️  Skipped tracks from mismatched labels: '
        '${mismatchedLabels.join(', ')}',
      );
    }

    log.info('    ✅ Found ${collectedTracks.length} tracks from label');

    return collectedTracks;
  }

  Future<List<CollectedTrack>> _filterPlaylistTracksByDate(
    List<entities.CachedPlaylistTrack> cachedTracks,
    DateTime cutoffDate,
    DateTime endDate,
    String playlistId,
    String playlistName,
    entities.PlaylistTrackDateMode dateMode,
  ) async {
    final filtered = <CollectedTrack>[];

    for (final track in cachedTracks) {
      DateTime trackDate;

      // Determine which date to use based on the mode
      if (dateMode == entities.PlaylistTrackDateMode.addedDate) {
        trackDate = track.addedAt;
      } else {
        // Use release date - need to look it up from cache or fetch from API
        final albumId = track.albumId;
        if (albumId == null) continue;

        var cachedAlbum = await cacheAdapter.getAlbum(albumId);

        if (cachedAlbum == null || cachedAlbum.releaseDate == null) {
          // Fetch album info from API
          try {
            final album = await requestPool.request(
              () => api.albums.get(albumId.toString()),
              identifier: SpotifyCacheIdentifier.album(albumId),
            );

            // Cache the album
            cachedAlbum = entities.CachedAlbum(
              id: albumId,
              name: album.name ?? '',
              releaseDate: album.releaseDate,
              label: album.label,
              artistNames: album.artists?.map((a) => a.name ?? '').toList(),
              cachedAt: DateTime.now(),
            );

            await cacheAdapter.cacheAlbums({albumId: cachedAlbum});
          } catch (e) {
            log.warning(
              '    ⚠️  Error fetching album $albumId: $e',
            );
            continue;
          }
        }

        final releaseDate = cachedAlbum.releaseDate!;
        try {
          trackDate = parseSpotifyReleaseDate(releaseDate);
        } catch (e) {
          log.warning(
            '    ⚠️  Could not parse release date for '
            'cached track ${track.trackId}: '
            '$releaseDate',
          );
          continue;
        }
      }

      // Filter by date range
      if (!trackDate.isInRange(cutoffDate, endDate)) continue;

      final collectedTrack = CollectedTrack(
        id: SpotifyTrackId(track.trackId.toString()),
        uri: track.uri,
        name: track.name,
        artistNames: track.artistNames,
        addedAt: trackDate,
        source: CollectedTrackSourcePlaylist(
          id: playlistId,
          name: playlistName,
        ),
        albumId: track.albumId != null
            ? SpotifyAlbumId(track.albumId.toString())
            : null,
      );

      filtered.add(collectedTrack);

      // Log individual track collection
      final dateModeText = dateMode == entities.PlaylistTrackDateMode.addedDate
          ? 'added to playlist'
          : 'released';
      log.debug(
        '    ✓ ${track.artistNames.join(', ')} - ${track.name} '
        '(included because $dateModeText on ${formatDate(trackDate)})',
      );
    }

    log.info(
      '    📅 ${filtered.length} cached tracks in date range '
      '(${formatDate(cutoffDate)} - ${formatDate(endDate)}) '
      // ignore: lines_longer_than_80_chars
      '(using ${dateMode == entities.PlaylistTrackDateMode.addedDate ? 'added date' : 'release date'})',
    );

    return filtered;
  }
}
