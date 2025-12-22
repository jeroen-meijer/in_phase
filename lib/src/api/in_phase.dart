import 'dart:async';

import 'package:in_phase/src/api/progress/crawl_progress.dart';
import 'package:in_phase/src/api/progress/sync_progress.dart';
import 'package:in_phase/src/api/search_result.dart';
import 'package:in_phase/src/database/database.dart';
import 'package:in_phase/src/entities/crawl_config.dart';
import 'package:in_phase/src/entities/sync_config.dart';
import 'package:in_phase/src/logger/logger.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:in_phase/src/spotify/api.dart';
import 'package:rekorddart/rekorddart.dart';
import 'package:spotify/spotify.dart';

/// Main API class for InPhase functionality
class InPhase {
  InPhase._({
    required AppDatabase syncDb,
    required RequestPool requestPool,
    SpotifyApi? spotifyApi,
    RekordboxDatabase? rbDb,
  }) : _spotifyApi = spotifyApi,
       _rbDb = rbDb,
       _syncDb = syncDb,
       _requestPool = requestPool;
  SpotifyApi? _spotifyApi;
  final RekordboxDatabase? _rbDb;
  final AppDatabase _syncDb;
  final RequestPool _requestPool;
  bool _disposed = false;

  /// Creates an InPhase instance WITHOUT requiring authentication
  ///
  /// [rekordboxDbPath] - Deprecated: This parameter is ignored. Rekordbox database is always auto-detected.
  /// [allowConnectionWhenRunning] - If true, allows connection to Rekordbox
  /// database even when Rekordbox is running. Useful for sandboxed environments
  /// (e.g., Flutter apps) that cannot check if Rekordbox is running.
  /// Authentication can be added later via [authenticate()] method.
  static Future<InPhase> create({
    String?
    rekordboxDbPath, // Deprecated: ignored, kept for backward compatibility
    bool allowConnectionWhenRunning = false,
  }) async {
    // Initialize sync database
    final syncDb = AppDatabase.fromCacheDbFile();

    // Initialize request pool
    final requestPool = Zonable.fromZone<RequestPool>();

    // Always try to connect to Rekordbox database (auto-detects)
    // If Rekordbox is not installed or database not found, rbDb will be null
    RekordboxDatabase? rbDb;
    try {
      rbDb = await RekordboxDatabase.connect(
        allowConnectionWhenRunning: allowConnectionWhenRunning,
      );
    } catch (e, stackTrace) {
      // Rekordbox not found or not accessible - continue without it
      // Features that require Rekordbox will throw appropriate errors
      // Log the error for debugging
      log.warning(
        'Failed to connect to Rekordbox database (auto-detection failed): $e\n'
        'Stack trace: $stackTrace',
      );
      rbDb = null;
    }

    return InPhase._(
      rbDb: rbDb,
      syncDb: syncDb,
      requestPool: requestPool,
    );
  }

  /// Authenticates the InPhase instance with a Spotify API
  ///
  /// [spotifyApi] - Authenticated Spotify API instance (use [spotifyLogin] to get this)
  /// Throws [StateError] if instance is already authenticated
  Future<void> authenticate(SpotifyApi spotifyApi) async {
    _checkDisposed();
    if (_spotifyApi != null) {
      throw StateError('InPhase instance is already authenticated');
    }
    _spotifyApi = spotifyApi;
  }

  /// Logs out and clears authentication
  ///
  /// Does not dispose of the instance, just clears authentication.
  /// Config operations can still be performed after logout.
  Future<void> logout() async {
    _checkDisposed();
    _spotifyApi = null;
  }

  /// Checks if user is authenticated with Spotify
  bool get isAuthenticated {
    _checkDisposed();
    return _spotifyApi != null;
  }

  /// Gets the current Spotify user info
  ///
  /// Throws [StateError] if not authenticated
  Future<User> getCurrentUser() async {
    _checkDisposed();
    _checkAuthenticated();
    return _spotifyApi!.me.get();
  }

  /// Gets all Spotify playlists for the authenticated user
  ///
  /// Throws [StateError] if not authenticated
  Future<List<PlaylistSimple>> getPlaylists() async {
    _checkDisposed();
    _checkAuthenticated();
    return _spotifyApi!.playlists.me.all(50).then((value) => value.toList());
  }

  /// Syncs playlists from Spotify to Rekordbox
  ///
  /// Throws [StateError] if not authenticated
  /// Emits progress events via the returned stream.
  Stream<SyncProgress> syncPlaylists({
    List<String>? playlistIds,
  }) async* {
    _checkDisposed();
    _checkAuthenticated();
    _checkRekordboxAvailable();

    // TODO: Implement full sync logic with progress events
    // This is a placeholder that needs to be implemented by refactoring
    // the sync command logic to emit progress events
    throw UnimplementedError('syncPlaylists not yet implemented');
  }

  /// Crawls Spotify for new tracks and creates playlists
  ///
  /// Throws [StateError] if not authenticated
  Stream<CrawlProgress> crawl({
    List<String>? jobNames,
    DateTime? startDate,
    DateTime? endDate,
    bool dryRun = false,
  }) async* {
    _checkDisposed();
    _checkAuthenticated();

    // TODO: Implement full crawl logic with progress events
    // This is a placeholder that needs to be implemented by refactoring
    // the crawl command logic to emit progress events
    throw UnimplementedError('crawl not yet implemented');
  }

  /// Searches Rekordbox library for tracks
  ///
  /// Throws [StateError] if not authenticated
  Future<List<SearchResult>> search(String query, {int limit = 20}) async {
    _checkDisposed();
    _checkAuthenticated();
    _checkRekordboxAvailable();

    // Load all tracks
    final allTracks = await _rbDb!
        .select(_rbDb.djmdContent)
        .join([
          leftOuterJoin(
            _rbDb.djmdArtist,
            _rbDb.djmdContent.artistID.equalsExp(_rbDb.djmdArtist.id),
          ),
        ])
        .map(
          (e) => (
            artist: e.readTableOrNull(_rbDb.djmdArtist),
            song: e.readTable(_rbDb.djmdContent),
          ),
        )
        .get();

    if (allTracks.isEmpty) {
      return [];
    }

    // Check if query is numeric (Rekordbox ID)
    if (RegExp(r'^\d+$').hasMatch(query)) {
      final track = await _rbDb.getSongById(query);
      if (track == null) {
        return [];
      }
      // Convert to SearchResult
      final artist = track.artistID != null
          ? await (_rbDb.select(
              _rbDb.djmdArtist,
            )..where((a) => a.id.equals(track.artistID!))).getSingleOrNull()
          : null;

      final cues = await (_rbDb.select(
        _rbDb.djmdCue,
      )..where((c) => c.contentID.equals(track.id!))).get();

      final hotCueCount = cues.where((c) {
        final kind = CueKind.fromKind(c.kind);
        return kind?.isHotCue ?? false;
      }).length;

      final memoryCueCount = cues.where((c) => c.kind == 0).length;

      return [
        SearchResult(
          trackId: track.id!,
          title: track.title ?? 'Unknown Title',
          artist: artist?.name ?? 'Unknown Artist',
          bpm: track.bpm != null ? (track.bpm! / 100).round() : null,
          lengthSeconds: track.length,
          hotCueCount: hotCueCount,
          memoryCueCount: memoryCueCount,
        ),
      ];
    }

    // Fuzzy search
    final matches = await findFuzzyTrackMatches(
      query: query,
      tracks: allTracks,
      maxResults: limit,
    );

    // Convert to SearchResult
    final results = <SearchResult>[];
    for (final match in matches) {
      final track = match.value.song;
      final artist = match.value.artist;

      final cues = await (_rbDb.select(
        _rbDb.djmdCue,
      )..where((c) => c.contentID.equals(track.id!))).get();

      final hotCueCount = cues.where((c) {
        final kind = CueKind.fromKind(c.kind);
        return kind?.isHotCue ?? false;
      }).length;

      final memoryCueCount = cues.where((c) => c.kind == 0).length;

      results.add(
        SearchResult(
          trackId: track.id!,
          title: track.title ?? 'Unknown Title',
          artist: artist?.name ?? 'Unknown Artist',
          bpm: track.bpm != null ? (track.bpm! / 100).round() : null,
          lengthSeconds: track.length,
          hotCueCount: hotCueCount,
          memoryCueCount: memoryCueCount,
        ),
      );
    }

    return results;
  }

  // Config operations do NOT require authentication
  Future<SyncConfig> getSyncConfig() async {
    _checkDisposed();
    return SyncConfig.fromFile(Constants.syncConfigFile);
  }

  Future<void> saveSyncConfig(SyncConfig config) async {
    _checkDisposed();
    await config.write(Constants.syncConfigFile);
  }

  Future<CrawlConfig> getCrawlConfig() async {
    _checkDisposed();
    return CrawlConfig.fromFile(Constants.crawlConfigFile);
  }

  Future<void> saveCrawlConfig(CrawlConfig config) async {
    _checkDisposed();
    await config.write(Constants.crawlConfigFile);
  }

  /// Disposes of the InPhase instance and cleans up resources
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    await _syncDb.close();
    await _rbDb?.close();
    _requestPool.clear();
  }

  void _checkAuthenticated() {
    if (_spotifyApi == null) {
      throw StateError(
        'InPhase instance is not authenticated. '
        'Call authenticate() before performing this operation.',
      );
    }
  }

  void _checkDisposed() {
    if (_disposed) {
      throw StateError('InPhase instance has been disposed');
    }
  }

  void _checkRekordboxAvailable() {
    if (_rbDb == null) {
      throw StateError(
        'Rekordbox database not available. '
        'Please ensure Rekordbox is installed and the database is accessible. '
        'The app attempted to auto-detect the Rekordbox database '
        'but could not find it.',
      );
    }
  }
}
