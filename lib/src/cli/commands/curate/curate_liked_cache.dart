import 'package:in_phase/src/misc/misc.dart';
import 'package:in_phase/src/spotify/spotify.dart';
import 'package:spotify/spotify.dart';

/// Target playlist membership for curate; fills in the background for footer
/// hints and duplicate checks once [loaded] is true.
class CurateTargetPlaylistsCache {
  final Map<String, Set<String>> ids = <String, Set<String>>{};
  bool loaded = false;
  Future<void>? _load;

  Future<void>? get ready => _load;

  void start(Future<Map<String, Set<String>>> fetch) {
    _load ??= fetch.then((map) {
      for (final entry in map.entries) {
        ids[entry.key] = Set<String>.from(entry.value);
      }
      loaded = true;
    });
  }

  bool? contains(String playlistId, String? trackId) {
    if (!loaded || trackId == null) {
      return null;
    }
    return ids[playlistId]?.contains(trackId) ?? false;
  }

  void markAdded(String playlistId, String trackId) {
    ids.putIfAbsent(playlistId, () => {}).add(trackId);
  }

  void markRemoved(String playlistId, String trackId) {
    ids[playlistId]?.remove(trackId);
  }
}

/// Liked Songs lookup for curate: fast per-track checks, optional full preload
/// for footer indicators.
class CurateLikedTracksCache {
  CurateLikedTracksCache(this._api, this._requestPool);

  final SpotifyApi _api;
  final RequestPool _requestPool;
  final Set<String> _ids = {};
  Future<void>? _preload;

  /// Starts paging through all saved tracks (for footer ✓ hints).
  void startPreload() {
    _preload ??= _fetchAllSavedIds();
  }

  Future<void> _fetchAllSavedIds() async {
    const pageSize = 50;
    final saved = await _requestPool.fetchAllPages(
      _api.me.tracks.saved(),
      limit: pageSize,
      pageIdentifier: SpotifyCacheIdentifier.savedTracksPage,
    );
    _ids.addAll(saved.map((ts) => ts.track?.id).nonNulls);
  }

  /// Whether [trackId] is in Liked Songs. Uses the in-memory set when known,
  /// otherwise a single Spotify `contains` call (does not wait for preload).
  Future<bool> isLiked(String trackId) async {
    if (_ids.contains(trackId)) {
      return true;
    }
    final saved = await _api.me.tracks.containsOne(trackId);
    if (saved) {
      _ids.add(trackId);
    }
    return saved;
  }

  void markLiked(String trackId) => _ids.add(trackId);

  /// Snapshot for footer rendering after the first preload pass completes.
  Future<Set<String>> get idsForFooter async {
    startPreload();
    await _preload;
    return Set<String>.unmodifiable(_ids);
  }
}
