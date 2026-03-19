import 'package:equatable/equatable.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:in_phase/src/crawl/crawl.dart';
import 'package:in_phase/src/database/database.exports.dart';
import 'package:in_phase/src/entities/entities.dart' as entities;
import 'package:in_phase/src/logger/logger.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:in_phase/src/spotify/spotify.dart';
import 'package:spotify/spotify.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

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

/// {@template collected_track_source_youtube_channel}
/// The source of a collected track from a YouTube channel.
/// {@endtemplate}
class CollectedTrackSourceYoutubeChannel extends CollectedTrackSource {
  /// {@macro collected_track_source_youtube_channel}
  const CollectedTrackSourceYoutubeChannel({
    required this.id,
    required this.name,
    required this.videoTitle,
    required this.videoId,
  });

  /// The ID or handle of the YouTube channel.
  final String id;

  /// The name of the YouTube channel.
  final String name;

  /// The title of the original YouTube video.
  final String videoTitle;

  /// The ID of the YouTube video.
  final String videoId;

  @override
  List<Object?> get props => [id, name, videoTitle, videoId];
}

/// Parsed YouTube video title containing artists and track name.
class _ParsedTitle {
  const _ParsedTitle({
    required this.artists,
    required this.trackName,
  });

  final List<String> artists;
  final String trackName;
}

/// {@template track_collector}
/// Collects tracks from various Spotify sources (playlists, artists, labels,
/// YouTube channels).
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

  static String _shortId(String id, {int maxLen = 12}) =>
      id.length > maxLen ? id.substring(0, maxLen) : id;

  /// Collects tracks from a playlist within the specified date range.
  Future<List<CollectedTrack>> collectFromPlaylist(
    String playlistId,
    DateTime cutoffDate,
    DateTime endDate,
    entities.PlaylistTrackDateMode dateMode, {
    CrawlProgressReporter? progress,
  }) async {
    var tag = _shortId(playlistId);
    if (progress == null) {
      log.info(tag: tag, '  📜 Collecting from playlist: $playlistId');
    }

    final spotifyPlaylistId = SpotifyPlaylistId(playlistId);

    // Fetch playlist info to get snapshot ID
    final playlist = await requestPool.request(
      () => api.playlists.get(playlistId),
      identifier: SpotifyCacheIdentifier.playlist(spotifyPlaylistId),
    );

    final snapshotId = playlist.snapshotId ?? '';
    final playlistName = playlist.name ?? 'Unknown Playlist';
    tag = playlistName;
    progress?.call(playlistName);

    if (progress == null) {
      log.info(tag: tag, '    Playlist: $playlistName (snapshot: $snapshotId)');
    }

    // Check if cached and unchanged
    final cachedPlaylist = await cacheAdapter.getPlaylist(spotifyPlaylistId);
    final isChanged = await cacheAdapter.isPlaylistChanged(
      spotifyPlaylistId,
      snapshotId,
    );
    if (cachedPlaylist != null && !isChanged) {
      if (progress == null) {
        log.info(tag: tag, '    💾 Using cached playlist data');
      }
      return _filterPlaylistTracksByDate(
        cachedPlaylist.tracks,
        cutoffDate,
        endDate,
        playlistId,
        playlistName,
        dateMode,
        suppressStatusLogs: progress != null,
      );
    }

    // Fetch tracks from Spotify
    if (progress == null) {
      log.info(tag: tag, '    🔄 Fetching tracks from Spotify...');
    }
    final playlistTracks = await requestPool.request(
      () => api.playlists.getPlaylistTracks(playlistId).all(50),
      identifier: SpotifyCacheIdentifier.playlistTracks(spotifyPlaylistId),
    );

    // Cache the playlist
    final cachedTracks = playlistTracks
        .where((pt) => pt.track?.id != null && pt.addedAt != null)
        .map((playlistTrack) {
          final track = playlistTrack.track!;
          return entities.CachedPlaylistTrack(
            trackId: SpotifyTrackId(track.id!),
            uri: track.uri!,
            name: track.name!,
            artistNames: track.artists?.map((a) => a.name ?? '').toList() ?? [],
            addedAt: playlistTrack.addedAt!,
            albumId: track.album?.id != null
                ? SpotifyAlbumId(track.album!.id!)
                : null,
          );
        })
        .toList();

    await cacheAdapter.cachePlaylist(
      spotifyPlaylistId,
      entities.CachedPlaylist(
        snapshotId: snapshotId,
        name: playlistName,
        tracks: cachedTracks,
        cachedAt: DateTime.now(),
      ),
    );

    if (progress == null) {
      log.info(
        tag: tag,
        '    ✅ Found ${playlistTracks.length} tracks from playlist',
      );
    }

    // Pre-fetch albums needing release date (batch for request pool)
    final albumIdsToFetch = <SpotifyAlbumId>[];
    if (dateMode == entities.PlaylistTrackDateMode.releaseDate) {
      final seen = <SpotifyAlbumId>{};
      for (final playlistTrack in playlistTracks) {
        final track = playlistTrack.track;
        if (track?.album?.id == null || track?.album?.releaseDate != null) {
          continue;
        }
        final albumId = SpotifyAlbumId(track!.album!.id!);
        if (seen.add(albumId)) albumIdsToFetch.add(albumId);
      }
    }
    final albumFutures = albumIdsToFetch.map(
      (albumId) async {
        try {
          return await requestPool.request(
            () => api.albums.get(albumId.toString()),
            identifier: SpotifyCacheIdentifier.album(albumId),
          );
        } catch (e) {
          log.warning(tag: tag, '    ⚠️  Error fetching album $albumId: $e');
          return null;
        }
      },
    );
    final fetchedAlbums = <SpotifyAlbumId, Album>{};
    final albumResults = await Future.wait(albumFutures);
    for (var i = 0; i < albumIdsToFetch.length; i++) {
      final album = albumResults[i];
      if (album != null) fetchedAlbums[albumIdsToFetch[i]] = album;
    }

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
        // Use release date - from album or pre-fetched map
        var releaseDate = track.album?.releaseDate;
        var albumToCache = track.album;

        if (releaseDate == null && track.album?.id != null) {
          final albumId = SpotifyAlbumId(track.album!.id!);
          final fetched = fetchedAlbums[albumId];
          if (fetched != null) {
            releaseDate = fetched.releaseDate;
            albumToCache = fetched;
          } else {
            log.warning(
              tag: tag,
              '    ⚠️  Could not get album ${track.album!.id!} '
              'for release date',
            );
          }
        }

        if (releaseDate == null) {
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
            tag: tag,
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
        tag: tag,
        '    ✓ $artistNames - ${track.name} '
        '(included because $dateModeText on ${formatDate(trackDate)})',
      );
    }

    log.info(
      tag: tag,
      '    📅 ${collectedTracks.length} tracks in date range '
      '(${formatDate(cutoffDate)} - ${formatDate(endDate)}) '
      // ignore: lines_longer_than_80_chars
      '(using ${dateMode == entities.PlaylistTrackDateMode.addedDate ? 'added date' : 'release date'})',
    );

    return collectedTracks;
  }

  /// Collects tracks from an artist's recent releases within the date range.
  ///
  /// When [includeAppearances] is `true` (default), also fetches albums where
  /// the artist appears as a featured artist (e.g., remixes, features,
  /// collaborations). For these albums, only tracks where the artist is
  /// credited are included.
  Future<List<CollectedTrack>> collectFromArtist(
    String artistId,
    DateTime cutoffDate,
    DateTime endDate, {
    bool includeAppearances = true,
    CrawlProgressReporter? progress,
  }) async {
    var tag = _shortId(artistId);
    if (progress == null) {
      log.info(tag: tag, '  🎤 Collecting from artist: $artistId');
    }

    final spotifyArtistId = SpotifyArtistId(artistId);

    // Check if artist metadata is cached and fresh (< 1 month old)
    final cachedArtist = await cacheAdapter.getArtist(spotifyArtistId);
    final String artistName;

    if (cachedArtist != null && !cachedArtist.isStale) {
      tag = cachedArtist.name;
      artistName = cachedArtist.name;
      progress?.call(artistName);
      if (progress == null) {
        log.info(tag: tag, '    💾 Using cached artist metadata');
      }
    } else {
      // Fetch artist info
      final artist = await requestPool.request(
        () => api.artists.get(artistId),
        identifier: SpotifyCacheIdentifier.artist(spotifyArtistId),
      );

      artistName = artist.name ?? 'Unknown Artist';
      tag = artistName;
      progress?.call(artistName);

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

    if (progress == null) {
      log.info(tag: tag, '    Artist: $artistName');
    }

    // Check if artist albums are cached and fresh (from today)
    final cachedArtistAlbums = await cacheAdapter.getArtistAlbums(
      spotifyArtistId,
    );
    final List<Album> albums;

    if (cachedArtistAlbums != null && cachedArtistAlbums.isFreshToday) {
      if (progress == null) {
        log.info(
          tag: tag,
          '    💾 Using cached artist albums list (fresh today)',
        );
      }
      // Reconstruct album list from cached IDs
      // We still need minimal album info, but we can use our album cache
      albums = [];
      for (final albumId in cachedArtistAlbums.albumIds) {
        final cachedAlbum = await cacheAdapter.getAlbum(albumId);
        if (cachedAlbum != null && cachedAlbum.releaseDate != null) {
          log.debug(
            tag: tag,
            '    From cache: "${cachedAlbum.name}" (${cachedAlbum.releaseDate})',
          );
          // Create minimal Album object from cache
          albums.add(
            Album()
              ..id = albumId.toString()
              ..name = cachedAlbum.name
              ..releaseDate = cachedAlbum.releaseDate,
          );
        } else {
          log.debug(
            tag: tag,
            '    ⊘ Cache miss for album $albumId (not in cache or no release date)',
          );
        }
      }
      if (progress == null) {
        log.info(
          tag: tag,
          '    Reconstructed ${albums.length} albums from cache',
        );
      }
    } else {
      if (progress == null) {
        log.info(
          tag: tag,
          '    🔄 Fetching artist albums '
          '${cachedArtistAlbums != null ? '(cache stale)' : '(not cached)'}',
        );
      }

      // Fetch albums with early termination (cache-based and date-based)
      // Using getPage() instead of stream() to enable RequestPool deduplication
      final allAlbumIds = <SpotifyAlbumId>[];
      albums = [];

      const limit = 10;
      var offset = 0;
      var pagesFetched = 0;
      var hitCache = false;
      var hitDateCutoff = false;

      while (true) {
        pagesFetched++;
        log.debug(
          tag: tag,
          '    Fetching page $pagesFetched of artist albums '
          '(limit: $limit, offset: $offset)',
        );

        // Fetch page with RequestPool for deduplication and retry
        final includeGroups = [
          'album',
          'single',
          if (includeAppearances) 'appears_on',
        ];
        final page = await requestPool.request(
          () => api.artists
              .albums(artistId, includeGroups: includeGroups)
              .getPage(limit, offset),
          identifier: SpotifyCacheIdentifier.artistAlbumsPage(
            spotifyArtistId,
            offset,
          ),
        );

        // Throw out albums without release date, parse once,
        // sort by date (newest first)
        final rawItems = page.items ?? <Album>[];
        final dated = <({DateTime releaseDate, Album album})>[];
        for (final a in rawItems) {
          if (a.id == null || a.releaseDate == null) continue;
          try {
            dated.add((
              releaseDate: parseSpotifyReleaseDate(a.releaseDate!),
              album: a,
            ));
          } catch (e) {
            log.warning(
              tag: tag,
              '    ⚠️  Could not parse release date: ${a.releaseDate}',
            );
          }
        }
        dated.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));

        for (final entry in dated) {
          final album = entry.album;
          final releaseDate = entry.releaseDate;
          final albumId = SpotifyAlbumId(album.id!);
          allAlbumIds.add(albumId);

          // Check if we hit a cached album - if so, stop fetching
          if (cachedArtistAlbums != null &&
              cachedArtistAlbums.albumIds.contains(albumId)) {
            if (progress == null) {
              log.info(
                tag: tag,
                '    ✓ Found cached album "${album.name}", '
                'stopping fetch and using cache',
              );
            }
            hitCache = true;
            break;
          }

          // Check if this album is too old (beyond our date range)
          // Since we sorted newest-first, we can stop here
          if (releaseDate.isBefore(cutoffDate)) {
            if (progress == null) {
              log.info(
                tag: tag,
                '    ✓ Found album "${album.name}" from '
                '${formatDate(releaseDate)}, before cutoff '
                '${formatDate(cutoffDate)}, stopping fetch',
              );
            }
            hitDateCutoff = true;
            break;
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
      if (progress == null) {
        log.info(
          tag: tag,
          '    Found ${albums.length} albums/singles '
          '($pagesFetched pages, $terminationReason)',
        );
      }
    }

    // Filter albums by release date (batch fetch for request pool)
    final albumIdsNeedingFetch = <SpotifyAlbumId>[];
    final seen = <SpotifyAlbumId>{};
    for (final album in albums) {
      if (album.releaseDate == null && album.id != null) {
        final albumId = SpotifyAlbumId(album.id!);
        if (seen.add(albumId)) albumIdsNeedingFetch.add(albumId);
      }
    }
    final filterAlbumFutures = albumIdsNeedingFetch.map(
      (albumId) async {
        try {
          return await requestPool.request(
            () => api.albums.get(albumId.toString()),
            identifier: SpotifyCacheIdentifier.album(albumId),
          );
        } catch (e) {
          log.warning(tag: tag, '    ⚠️  Error fetching album $albumId: $e');
          return null;
        }
      },
    );
    final filterAlbumResults = await Future.wait(filterAlbumFutures);
    final filterFetchedAlbums = <SpotifyAlbumId, Album>{};
    for (var i = 0; i < albumIdsNeedingFetch.length; i++) {
      final a = filterAlbumResults[i];
      if (a != null) filterFetchedAlbums[albumIdsNeedingFetch[i]] = a;
    }

    final recentAlbums = <Album>[];
    for (final album in albums) {
      var releaseDate = album.releaseDate;
      var albumToCache = album;

      if (releaseDate == null && album.id != null) {
        final fullAlbum = filterFetchedAlbums[SpotifyAlbumId(album.id!)];
        if (fullAlbum != null) {
          releaseDate = fullAlbum.releaseDate;
          albumToCache = fullAlbum;
        }
      }

      if (releaseDate == null) {
        log.debug(
          tag: tag,
          '    ⊘ Skipping "${album.name}" (no release date)',
        );
        continue;
      }

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
          log.debug(
            tag: tag,
            '    ✓ Including "${album.name}" (released ${formatDate(parsedReleaseDate)})',
          );
        } else {
          final reason = parsedReleaseDate.isBefore(cutoffDate)
              ? 'before cutoff ${formatDate(cutoffDate)}'
              : 'after end date ${formatDate(endDate)}';
          log.debug(
            tag: tag,
            '    ⊘ Skipping "${album.name}" (released ${formatDate(parsedReleaseDate)}, $reason)',
          );
        }
      } catch (e) {
        log.warning(
          tag: tag,
          '    ⚠️  Could not parse release date: $releaseDate',
        );
      }
    }

    if (progress == null) {
      log.info(
        tag: tag,
        '    ${recentAlbums.length} albums/singles in date range',
      );
    }

    // Fetch tracks from recent albums (batch requests for request pool)
    final allTracks = <CollectedTrack>[];
    final albumFutures = recentAlbums.map(
      (album) async {
        try {
          return await requestPool.request(
            () => api.albums.get(album.id!),
            identifier: SpotifyCacheIdentifier.album(
              SpotifyAlbumId(album.id!),
            ),
          );
        } catch (e) {
          log.warning(tag: tag, '    ⚠️  Error fetching album ${album.id}: $e');
          return null;
        }
      },
    );
    final albumFulls = await Future.wait(albumFutures);

    for (var i = 0; i < recentAlbums.length; i++) {
      final album = recentAlbums[i];
      final albumFull = albumFulls[i];
      if (albumFull == null) continue;
      try {
        final releaseDate = parseSpotifyReleaseDate(album.releaseDate!);

        // Check if this is an "appears on" album (artist is not in the
        // album's main artists). For these albums, we only include tracks
        // where the target artist is credited.
        // When album.artists is null (unusual), assume the artist owns
        // the album to safely include all tracks rather than risk
        // dropping relevant ones.
        final isAppearsOnAlbum = !(album.artists?.any(
              (a) => a.id == artistId,
            ) ??
            true);

        for (final track in albumFull.tracks ?? <TrackSimple>[]) {
          if (track.id != null) {
            // For appears_on albums, only include tracks where the artist
            // is credited as a track artist.
            if (isAppearsOnAlbum) {
              final artistOnTrack =
                  track.artists?.any((a) => a.id == artistId) ?? false;
              if (!artistOnTrack) {
                log.debug(
                  tag: tag,
                  '    ⊘ Skipping "${track.name}" from "${album.name}" '
                  '(appears_on album, artist not credited on track)',
                );
                continue;
              }
            }

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
            final releasedOn =
                'released on ${formatDate(releaseDate)}';
            final reason = isAppearsOnAlbum
                ? 'appears on "${album.name}", $releasedOn'
                : releasedOn;
            log.debug(
              tag: tag,
              '    ✓ $artistNames - ${track.name} '
              '(included because $reason)',
            );
          }
        }

        // Cache the album
        final albumId = SpotifyAlbumId(album.id!);
        await cacheAdapter.cacheAlbums({
          albumId: entities.CachedAlbum(
            id: albumId,
            name: albumFull.name ?? '',
            releaseDate: albumFull.releaseDate,
            label: albumFull.label,
            artistNames: albumFull.artists?.map((a) => a.name ?? '').toList(),
            cachedAt: DateTime.now(),
          ),
        });
      } catch (e) {
        log.warning(tag: tag, '    ⚠️  Error processing album ${album.id}: $e');
      }
    }

    if (progress == null) {
      log.info(tag: tag, '    ✅ Found ${allTracks.length} tracks from artist');
    }

    return allTracks;
  }

  /// Collects tracks from a label's releases within the date range.
  Future<List<CollectedTrack>> collectFromLabel(
    String labelName,
    DateTime cutoffDate,
    DateTime endDate, {
    CrawlProgressReporter? progress,
  }) async {
    final tag = labelName;
    progress?.call(labelName);
    if (progress == null) {
      log.info(tag: tag, '  🏷️  Collecting from label: $labelName');
    }

    // Check if label search is cached and fresh (from today)
    final cachedLabelSearch = await cacheAdapter.getLabelSearch(labelName);
    final List<Track> tracks;

    if (cachedLabelSearch != null && cachedLabelSearch.isFreshToday) {
      if (progress == null) {
        log
          ..info(
            tag: tag,
            '    💾 Using cached label search results (fresh today)',
          )
          ..info(
            tag: tag,
            '    Cached ${cachedLabelSearch.tracks.length} tracks',
          );
      }

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
      if (progress == null) {
        log.info(
          tag: tag,
          '    🔄 Searching for label tracks '
          '${cachedLabelSearch != null ? '(cache stale)' : '(not cached)'}',
        );
      }

      // Search for tracks by label
      final searchQuery = 'label:"$labelName"';
      final searchResults = await requestPool.request(
        () => api.search.get(searchQuery, types: [SearchType.track]).first(10),
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

    if (progress == null) {
      log.info(tag: tag, '    Found ${tracks.length} tracks from search');
    }

    // Pre-fetch albums needing full data (batch for request pool)
    final albumIdsToFetch = <SpotifyAlbumId>[];
    final seenAlbums = <SpotifyAlbumId>{};
    for (final track in tracks) {
      if (track.album?.id == null) continue;
      final albumId = SpotifyAlbumId(track.album!.id!);
      if (track.album?.releaseDate == null && seenAlbums.add(albumId)) {
        albumIdsToFetch.add(albumId);
      }
    }
    final albumFutures = albumIdsToFetch.map(
      (albumId) async {
        try {
          return await requestPool.request(
            () => api.albums.get(albumId.toString()),
            identifier: SpotifyCacheIdentifier.album(albumId),
          );
        } catch (e) {
          log.warning(tag: tag, '    ⚠️  Error fetching album $albumId: $e');
          return null;
        }
      },
    );
    final fetchedAlbums = <SpotifyAlbumId, Album>{};
    final albumResults = await Future.wait(albumFutures);
    for (var i = 0; i < albumIdsToFetch.length; i++) {
      final album = albumResults[i];
      if (album != null) fetchedAlbums[albumIdsToFetch[i]] = album;
    }

    // Filter tracks by release date and validate label match
    final collectedTracks = <CollectedTrack>[];
    final mismatchedLabels = <String>{};

    for (final track in tracks) {
      var releaseDate = track.album?.releaseDate;
      var albumToCache = track.album;

      if (releaseDate == null && track.album?.id != null) {
        final albumId = SpotifyAlbumId(track.album!.id!);
        final fetched = fetchedAlbums[albumId];
        if (fetched != null) {
          releaseDate = fetched.releaseDate;
          albumToCache = fetched;
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
        } else if (fetchedAlbums.containsKey(trackAlbumId)) {
          fullAlbum = fetchedAlbums[trackAlbumId];
          trackLabel = fullAlbum?.label ?? '';
        } else {
          final album = await requestPool.request(
            () => api.albums.get(track.album!.id!),
            identifier: SpotifyCacheIdentifier.album(trackAlbumId),
          );
          fullAlbum = album;
          trackLabel = album.label ?? '';
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
            tag: tag,
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
        log.warning(tag: tag, '    ⚠️  Error processing track ${track.id}: $e');
      }
    }

    if (mismatchedLabels.isNotEmpty) {
      log.info(
        tag: tag,
        '    ⚠️  Skipped tracks from mismatched labels: '
        '${mismatchedLabels.join(', ')}',
      );
    }

    if (progress == null) {
      log.info(
        tag: tag,
        '    ✅ Found ${collectedTracks.length} tracks from label',
      );
    }

    return collectedTracks;
  }

  /// Collects tracks from a YouTube channel by searching Spotify for matching
  /// tracks.
  Future<List<CollectedTrack>> collectFromYoutubeChannel(
    String channelIdentifier,
    DateTime cutoffDate,
    DateTime endDate, {
    CrawlProgressReporter? progress,
  }) async {
    var tag = _shortId(channelIdentifier);
    if (progress == null) {
      log.info(
        tag: tag,
        '  📺 Collecting from YouTube channel: $channelIdentifier',
      );
    }

    final yt = YoutubeExplode();

    try {
      final channel = await _getYoutubeChannel(yt, channelIdentifier);
      final channelName = channel.title;
      final channelId = channel.id.toString();
      tag = channelName;
      progress?.call(channelName);

      if (progress == null) {
        log.info(tag: tag, '    Channel: $channelName');
      }

      final videosInRange = await _getVideosInDateRange(
        yt.channels.getUploads(channel.id),
        cutoffDate,
        endDate,
      );

      if (progress == null) {
        log.info(
          tag: tag,
          '    Found ${videosInRange.length} videos in date range',
        );
      }

      // Batch Spotify searches for request pool utilization
      final searchFutures = videosInRange.map(
        (video) => _searchSpotifyForVideo(video, tag: tag),
      );
      final spotifyTracks = await Future.wait(searchFutures);

      final collectedTracks = <CollectedTrack>[];
      for (var i = 0; i < videosInRange.length; i++) {
        try {
          final video = videosInRange[i];
          final spotifyTrack = spotifyTracks[i];
          final videoDate = _getVideoDate(video);
          if (spotifyTrack != null && videoDate != null) {
            collectedTracks.add(
              _createCollectedTrackFromSpotify(
                spotifyTrack,
                videoDate,
                channelId,
                channelName,
                video.title,
                video.id.toString(),
              ),
            );

            final artistNames = _formatArtistNames(spotifyTrack.artists);
            log.debug(
              tag: tag,
              '    ✓ $artistNames - ${spotifyTrack.name} '
              '(from YouTube: ${video.title})',
            );
          } else {
            log.debug(
              tag: tag,
              '    ⚠️  No Spotify match found for: ${video.title}',
            );
          }
        } catch (e) {
          log.warning(
            tag: tag,
            '    ⚠️  Error processing video ${videosInRange[i].id}: $e',
          );
        }
      }

      if (progress == null) {
        log.info(
          tag: tag,
          '    ✅ Found ${collectedTracks.length} tracks from YouTube channel',
        );
      }

      return collectedTracks;
    } finally {
      yt.close();
    }
  }

  /// Gets a YouTube channel by handle or ID.
  Future<Channel> _getYoutubeChannel(
    YoutubeExplode yt,
    String identifier,
  ) async {
    return identifier.startsWith('@')
        ? await yt.channels.getByHandle(identifier)
        : await yt.channels.get(identifier);
  }

  /// Filters YouTube videos to those within the date range.
  Future<List<Video>> _getVideosInDateRange(
    Stream<Video> uploads,
    DateTime cutoffDate,
    DateTime endDate,
  ) async {
    final videosInRange = <Video>[];

    await for (final video in uploads) {
      final videoDate = _getVideoDate(video);
      if (videoDate == null) continue;

      // Stop if we've gone past the cutoff date (videos are in reverse
      // chronological order)
      if (videoDate.isBefore(cutoffDate)) break;

      // Include videos within the date range
      if (videoDate.isInRange(cutoffDate, endDate)) {
        videosInRange.add(video);
      }
    }

    return videosInRange;
  }

  /// Gets the publish or upload date from a YouTube video.
  DateTime? _getVideoDate(Video video) {
    return video.publishDate ?? video.uploadDate;
  }

  /// Creates a CollectedTrack from a Spotify track and YouTube video metadata.
  CollectedTrack _createCollectedTrackFromSpotify(
    Track spotifyTrack,
    DateTime? addedAt,
    String channelId,
    String channelName,
    String videoTitle,
    String videoId,
  ) {
    if (addedAt == null) {
      throw ArgumentError('Video date cannot be null');
    }
    return CollectedTrack(
      id: SpotifyTrackId(spotifyTrack.id!),
      uri: spotifyTrack.uri!,
      name: spotifyTrack.name!,
      artistNames: _extractArtistNames(spotifyTrack.artists),
      addedAt: addedAt,
      source: CollectedTrackSourceYoutubeChannel(
        id: channelId,
        name: channelName,
        videoTitle: videoTitle,
        videoId: videoId,
      ),
      albumId: spotifyTrack.album?.id != null
          ? SpotifyAlbumId(spotifyTrack.album!.id!)
          : null,
    );
  }

  /// Extracts artist names from Spotify track artists.
  List<String> _extractArtistNames(List<dynamic>? artists) {
    return artists
            ?.map((a) => (a as dynamic).name as String? ?? '')
            .where((n) => n.isNotEmpty)
            .toList() ??
        [];
  }

  /// Formats artist names for display.
  String _formatArtistNames(List<dynamic>? artists) {
    final names = _extractArtistNames(artists);
    return names.isEmpty ? 'Unknown Artist' : names.join(', ');
  }

  /// Searches Spotify for a track matching the YouTube video.
  Future<Track?> _searchSpotifyForVideo(Video video, {String tag = ''}) async {
    final title = video.title;
    final parsed = _parseVideoTitle(title);

    if (parsed == null) {
      return _searchSpotifyQuery(title, tag: tag);
    }

    // Try multiple search strategies in order of preference
    final searchStrategies = <String Function()>[
      // Strategy 1: Exact match with first artist
      () => _buildExactQuery([parsed.artists.first], parsed.trackName),
      // Strategy 2: Exact match with all artists (if multiple)
      if (parsed.artists.length > 1)
        () => _buildExactQuery(parsed.artists, parsed.trackName),
      // Strategy 3: Fuzzy search with all artists
      () => '${parsed.artists.join(' ')} ${parsed.trackName}',
      // Strategy 4: Fallback to full title
      () => title,
    ];

    for (final strategy in searchStrategies) {
      final query = strategy();
      final track = await _searchSpotifyQuery(query, tag: tag);
      if (track != null && _validateArtistMatch(track, parsed.artists)) {
        return track;
      }
    }

    return null;
  }

  /// Parses a YouTube video title into artists and track name.
  /// Returns null if the title doesn't match the expected format.
  _ParsedTitle? _parseVideoTitle(String title) {
    final parts = title.split(' - ');
    if (parts.length < 2) return null;

    final artistPart = parts[0].trim();
    final trackPart = parts.sublist(1).join(' - ').trim();

    if (trackPart.isEmpty) return null;

    final artists = _parseArtists(artistPart);
    if (artists.isEmpty) return null;

    return _ParsedTitle(artists: artists, trackName: trackPart);
  }

  /// Parses artist names from a string, handling "&" and "and" separators.
  List<String> _parseArtists(String artistPart) {
    return artistPart
        .split(RegExp(r'\s+&\s+|\s+and\s+', caseSensitive: false))
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList();
  }

  /// Builds an exact Spotify search query with artist and track filters.
  String _buildExactQuery(List<String> artists, String trackName) {
    final artistFilters = artists
        .map((a) => 'artist:"${_escapeSpotifyQuery(a)}"')
        .join(' ');
    return '$artistFilters track:"${_escapeSpotifyQuery(trackName)}"';
  }

  /// Performs a Spotify search with the given query string.
  Future<Track?> _searchSpotifyQuery(String query, {String tag = ''}) async {
    try {
      final searchResults = await requestPool.request(
        () => api.search.get(query, types: [SearchType.track]).first(5),
        identifier: 'youtube-search:$query',
      );

      final tracks = searchResults
          .expand((page) => page.items?.whereType<Track>() ?? <Track>[])
          .toList();

      return tracks.isNotEmpty ? tracks.first : null;
    } catch (e) {
      log.debug(tag: tag, '    Search query failed: $query ($e)');
      return null;
    }
  }

  /// Validates that the Spotify track's artists match the expected artists.
  /// Uses fuzzy matching with an 80% similarity threshold.
  bool _validateArtistMatch(Track track, List<String> expectedArtists) {
    final trackArtists =
        track.artists
            ?.map((a) => (a.name ?? '').toLowerCase())
            .where((n) => n.isNotEmpty)
            .toList() ??
        [];

    if (trackArtists.isEmpty) return false;

    const similarityThreshold = 80;

    for (final expectedArtist in expectedArtists) {
      final expectedLower = expectedArtist.toLowerCase();
      for (final trackArtist in trackArtists) {
        if (ratio(expectedLower, trackArtist) >= similarityThreshold) {
          return true;
        }
      }
    }

    return false;
  }

  /// Escapes special characters in Spotify search queries.
  String _escapeSpotifyQuery(String query) {
    return query.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
  }

  Future<List<CollectedTrack>> _filterPlaylistTracksByDate(
    List<entities.CachedPlaylistTrack> cachedTracks,
    DateTime cutoffDate,
    DateTime endDate,
    String playlistId,
    String playlistName,
    entities.PlaylistTrackDateMode dateMode, {
    bool suppressStatusLogs = false,
  }) async {
    final tag = playlistName;
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
              artistNames: album.artists
                  ?.map((a) => a.name ?? '')
                  .where((n) => n.isNotEmpty)
                  .toList(),
              cachedAt: DateTime.now(),
            );

            await cacheAdapter.cacheAlbums({albumId: cachedAlbum});
          } catch (e) {
            log.warning(
              tag: tag,
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
            tag: tag,
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
        tag: tag,
        '    ✓ ${track.artistNames.join(', ')} - ${track.name} '
        '(included because $dateModeText on ${formatDate(trackDate)})',
      );
    }

    if (!suppressStatusLogs) {
      log.info(
        tag: tag,
        '    📅 ${filtered.length} cached tracks in date range '
        '(${formatDate(cutoffDate)} - ${formatDate(endDate)}) '
        // ignore: lines_longer_than_80_chars
        '(using ${dateMode == entities.PlaylistTrackDateMode.addedDate ? 'added date' : 'release date'})',
      );
    }

    return filtered;
  }
}
