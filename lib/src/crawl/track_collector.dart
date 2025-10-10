import 'package:equatable/equatable.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:rkdb_dart/src/crawl/date_utils.dart';
import 'package:rkdb_dart/src/entities/entities.dart';
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
  const CollectedTrackSourcePlaylist(this.id);

  /// The ID of the playlist.
  final String id;
}

/// {@template collected_track_source_artist}
/// The source of a collected track from a artist.
/// {@endtemplate}
class CollectedTrackSourceArtist extends CollectedTrackSource {
  /// {@macro collected_track_source_artist}
  const CollectedTrackSourceArtist(this.id);

  /// The ID of the artist.
  final String id;
}

/// {@template collected_track_source_label}
/// The source of a collected track from a label.
/// {@endtemplate}
class CollectedTrackSourceLabel extends CollectedTrackSource {
  /// {@macro collected_track_source_label}
  const CollectedTrackSourceLabel(this.id);

  /// The ID of the label.
  final String id;
}

/// {@template track_collector}
/// Collects tracks from various Spotify sources (playlists, artists, labels).
/// {@endtemplate}
class TrackCollector {
  /// {@macro track_collector}
  TrackCollector({
    required this.api,
    required this.requestPool,
    required this.cache,
  });

  final SpotifyApi api;
  final RequestPool requestPool;
  CrawlCache cache;

  /// Collects tracks from a playlist within the specified date range.
  Future<List<CollectedTrack>> collectFromPlaylist(
    String playlistId,
    DateTime cutoffDate,
    DateTime endDate,
    PlaylistTrackDateMode dateMode,
  ) async {
    log.info('  📜 Collecting from playlist: $playlistId');

    // Fetch playlist info to get snapshot ID
    final playlist = await requestPool.request(
      () => api.playlists.get(playlistId),
      identifier: SpotifyCacheIdentifier.playlist(
        SpotifyPlaylistId(playlistId),
      ),
    );

    final snapshotId = playlist.snapshotId ?? '';
    final playlistName = playlist.name ?? 'Unknown Playlist';

    log.info('    Playlist: $playlistName (snapshot: $snapshotId)');

    // Check if cached and unchanged
    final cachedPlaylist = cache.playlists[SpotifyPlaylistId(playlistId)];
    if (cachedPlaylist != null &&
        !cache.isPlaylistChanged(SpotifyPlaylistId(playlistId), snapshotId)) {
      log.info('    💾 Using cached playlist data');
      return _filterPlaylistTracksByDate(
        cachedPlaylist.tracks,
        cutoffDate,
        endDate,
        playlistId,
        dateMode,
      );
    }

    // Fetch tracks from Spotify
    log.info('    🔄 Fetching tracks from Spotify...');
    final playlistTracks = await requestPool.request(
      () => api.playlists.getTracksByPlaylistId(playlistId).all(50),
      identifier: SpotifyCacheIdentifier.playlistTracks(
        SpotifyPlaylistId(playlistId),
      ),
    );

    // Cache the playlist
    final cachedTracks = playlistTracks.where((pt) => pt.track?.id != null).map(
      (playlistTrack) {
        final track = playlistTrack.track!;
        return CachedPlaylistTrack(
          trackId: SpotifyTrackId(track.id!),
          uri: track.uri!,
          name: track.name!,
          artistNames: track.artists?.map((a) => a.name ?? '').toList() ?? [],
          addedAt: playlistTrack.addedAt!,
          albumId: SpotifyAlbumId(track.album!.id!),
        );
      },
    ).toList();

    cache = cache.withPlaylist(
      SpotifyPlaylistId(playlistId),
      CachedPlaylist(
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
      if (dateMode == PlaylistTrackDateMode.addedDate) {
        trackDate = playlistTrack.addedAt!;
      } else {
        // Use release date - need to get it from the album
        var releaseDate = track.album?.releaseDate;

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

            // Cache the album
            cache = cache.withAlbums({
              SpotifyAlbumId(track.album!.id!): CachedAlbum(
                id: SpotifyAlbumId(track.album!.id!),
                name: album.name ?? '',
                releaseDate: album.releaseDate,
                label: album.label,
                artistNames: album.artists?.map((a) => a.name ?? '').toList(),
                cachedAt: DateTime.now(),
              ),
            });
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

      collectedTracks.add(
        CollectedTrack(
          id: SpotifyTrackId(track.id!),
          uri: track.uri!,
          name: track.name!,
          artistNames: track.artists?.map((a) => a.name ?? '').toList() ?? [],
          addedAt: trackDate,
          source: CollectedTrackSourcePlaylist(playlistId),
          albumId: track.album?.id != null
              ? SpotifyAlbumId(track.album!.id!)
              : null,
        ),
      );
    }

    log.info(
      '    📅 ${collectedTracks.length} tracks in date range '
      '(${formatDate(cutoffDate)} - ${formatDate(endDate)}) '
      '(using ${dateMode == PlaylistTrackDateMode.addedDate ? 'added date' : 'release date'})',
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

    // Fetch artist info
    final artist = await requestPool.request(
      () => api.artists.get(artistId),
      identifier: SpotifyCacheIdentifier.artist(
        SpotifyArtistId(artistId),
      ),
    );

    log.info('    Artist: ${artist.name}');

    // Fetch artist's albums and singles
    final albums = await requestPool.request(
      () => api.artists.albums(artistId).all(),
      identifier: SpotifyCacheIdentifier.artistAlbums(
        SpotifyArtistId(artistId),
      ),
    );

    log.info('    Found ${albums.length} albums/singles');

    // Filter albums by release date
    final recentAlbums = <Album>[];
    for (final album in albums) {
      var releaseDate = album.releaseDate;

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

          // Cache the album
          cache = cache.withAlbums({
            SpotifyAlbumId(album.id!): CachedAlbum(
              id: SpotifyAlbumId(album.id!),
              name: fullAlbum.name ?? '',
              releaseDate: fullAlbum.releaseDate,
              label: fullAlbum.label,
              artistNames: fullAlbum.artists?.map((a) => a.name ?? '').toList(),
              cachedAt: DateTime.now(),
            ),
          });
        } catch (e) {
          log.warning(
            '    ⚠️  Error fetching album ${album.id!}: $e',
          );
        }
      }

      if (releaseDate == null) continue;

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
            allTracks.add(
              CollectedTrack(
                id: SpotifyTrackId(track.id!),
                uri: track.uri!,
                name: track.name!,
                artistNames:
                    track.artists?.map((a) => a.name ?? '').toList() ?? [],
                addedAt: releaseDate,
                source: CollectedTrackSourceArtist(artistId),
                albumId: SpotifyAlbumId(album.id!),
              ),
            );
          }
        }

        // Cache the album
        cache = cache.withAlbums({
          SpotifyAlbumId(album.id!): CachedAlbum(
            id: SpotifyAlbumId(album.id!),
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

    // Search for tracks by label
    final searchQuery = 'label:"$labelName"';
    final searchResults = await requestPool.request(
      () => api.search.get(searchQuery, types: [SearchType.track]).first(50),
      identifier: SpotifyCacheIdentifier.labelSearch(labelName),
    );

    final tracks = searchResults.expand((page) {
      return page.items?.whereType<Track>() ?? <Track>[];
    }).toList();

    log.info('    Found ${tracks.length} tracks from search');

    // Filter tracks by release date and validate label match
    final collectedTracks = <CollectedTrack>[];
    final mismatchedLabels = <String>{};

    for (final track in tracks) {
      var releaseDate = track.album?.releaseDate;

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

          // Cache the album
          cache = cache.withAlbums({
            SpotifyAlbumId(track.album!.id!): CachedAlbum(
              id: SpotifyAlbumId(track.album!.id!),
              name: album.name ?? '',
              releaseDate: album.releaseDate,
              label: album.label,
              artistNames: album.artists?.map((a) => a.name ?? '').toList(),
              cachedAt: DateTime.now(),
            ),
          });
        } catch (e) {
          log.warning(
            '    ⚠️  Error fetching album ${track.album!.id!}: $e',
          );
        }
      }

      if (releaseDate == null) continue;

      try {
        final parsedReleaseDate = parseSpotifyReleaseDate(releaseDate);
        if (!parsedReleaseDate.isInRange(cutoffDate, endDate)) continue;

        final cachedAlbum = cache.albums[track.album!.id!];
        Album? fullAlbum;

        final String trackLabel;
        if (cachedAlbum case CachedAlbum(:final label?)) {
          trackLabel = label;
        } else {
          final album = await requestPool.request(
            () => api.albums.get(track.album!.id!),
            identifier: SpotifyCacheIdentifier.album(
              SpotifyAlbumId(track.album!.id!),
            ),
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
          collectedTracks.add(
            CollectedTrack(
              id: SpotifyTrackId(track.id!),
              uri: track.uri!,
              name: track.name!,
              artistNames:
                  track.artists?.map((a) => a.name ?? '').toList() ?? [],
              addedAt: parsedReleaseDate,
              source: CollectedTrackSourceLabel(labelName),
              albumId: track.album?.id != null
                  ? SpotifyAlbumId(track.album!.id!)
                  : null,
            ),
          );

          // Cache the album if we have a full 'album' or the track has a simple
          // album stored
          if ((fullAlbum != null) ||
              (cachedAlbum == null && track.album != null)) {
            final id = fullAlbum?.id ?? track.album!.id!;

            cache = cache.withAlbums({
              SpotifyAlbumId(id): CachedAlbum(
                id: SpotifyAlbumId(id),
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
    List<CachedPlaylistTrack> cachedTracks,
    DateTime cutoffDate,
    DateTime endDate,
    String playlistId,
    PlaylistTrackDateMode dateMode,
  ) async {
    final filtered = <CollectedTrack>[];

    for (final track in cachedTracks) {
      DateTime trackDate;

      // Determine which date to use based on the mode
      if (dateMode == PlaylistTrackDateMode.addedDate) {
        trackDate = track.addedAt;
      } else {
        // Use release date - need to look it up from cache or fetch from API
        var cachedAlbum = cache.albums[track.albumId];

        if (cachedAlbum == null || cachedAlbum.releaseDate == null) {
          // Fetch album info from API
          try {
            final album = await requestPool.request(
              () => api.albums.get(track.albumId!),
              identifier: SpotifyCacheIdentifier.album(track.albumId!),
            );

            // Cache the album
            cachedAlbum = CachedAlbum(
              id: track.albumId!,
              name: album.name ?? '',
              releaseDate: album.releaseDate,
              label: album.label,
              artistNames: album.artists?.map((a) => a.name ?? '').toList(),
              cachedAt: DateTime.now(),
            );

            cache = cache.withAlbums({track.albumId!: cachedAlbum});
          } catch (e) {
            log.warning(
              '    ⚠️  Error fetching album ${track.albumId!}: $e',
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

      filtered.add(
        CollectedTrack(
          id: track.trackId,
          uri: track.uri,
          name: track.name,
          artistNames: track.artistNames,
          addedAt: trackDate,
          source: CollectedTrackSourcePlaylist(playlistId),
          albumId: track.albumId,
        ),
      );
    }

    log.info(
      '    📅 ${filtered.length} cached tracks in date range '
      '(${formatDate(cutoffDate)} - ${formatDate(endDate)}) '
      '(using ${dateMode == PlaylistTrackDateMode.addedDate ? 'added date' : 'release date'})',
    );

    return filtered;
  }
}
