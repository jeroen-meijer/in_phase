import 'package:in_phase/src/misc/misc.dart';
import 'package:in_phase/src/spotify/spotify.dart';
import 'package:spotify/spotify.dart';

/// User-owned and collaborative playlists for the add-to-playlist picker.
///
/// Prefetched at curate session start so pressing `f` does not wait on Spotify.
class CurateUserPlaylistsCache {
  final List<PlaylistSimple> playlists = [];

  /// All playlists in the user's library (for ID/name resolution).
  final List<PlaylistSimple> savedPlaylists = [];
  bool loaded = false;
  Future<void>? _load;

  /// Track ids added this session via the picker (or any add path).
  final Map<String, Set<String>> _sessionTrackIds = <String, Set<String>>{};

  Future<void>? get ready => _load;

  /// Starts loading editable playlists in the background.
  void start(SpotifyApi api, RequestPool requestPool) {
    _load ??= _fetch(api, requestPool);
  }

  Future<void> _fetch(SpotifyApi api, RequestPool requestPool) async {
    try {
      final user = await api.me.get();
      final userId = user.id;
      if (userId == null || userId.isEmpty) {
        return;
      }

      final saved = await requestPool.fetchAllPages(
        api.me.playlists.saved(),
        limit: 50,
        pageIdentifier: SpotifyCacheIdentifier.savedPlaylistsPage,
      );

      final editable = saved
          .where((p) => _canEdit(p, userId))
          .where((p) => p.id != null && p.id!.isNotEmpty)
          .toList();

      // Spotify returns `/me/playlists` in recency order (most recently edited
      // first). Preserve that order instead of re-sorting alphabetically.
      savedPlaylists
        ..clear()
        ..addAll(
          saved.where((p) => p.id != null && p.id!.isNotEmpty),
        );
      playlists
        ..clear()
        ..addAll(editable);
    } finally {
      loaded = true;
    }
  }

  bool _canEdit(PlaylistSimple playlist, String userId) {
    if (playlist.collaborative == true) {
      return true;
    }
    return playlist.owner?.id == userId;
  }

  /// Playlists whose name contains [query] (case-insensitive). Empty query
  /// returns all cached playlists.
  List<PlaylistSimple> filter(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return List<PlaylistSimple>.from(playlists);
    }
    return playlists
        .where((p) => (p.name ?? '').toLowerCase().contains(needle))
        .toList();
  }

  /// Whether [trackId] was added to [playlistId] this session.
  bool sessionContains(String playlistId, String trackId) {
    return _sessionTrackIds[playlistId]?.contains(trackId) ?? false;
  }

  void markAdded(String playlistId, String trackId) {
    _sessionTrackIds.putIfAbsent(playlistId, () => {}).add(trackId);
    final index = playlists.indexWhere((p) => p.id == playlistId);
    if (index > 0) {
      final playlist = playlists.removeAt(index);
      playlists.insert(0, playlist);
    }
  }

  void markRemoved(String playlistId, String trackId) {
    _sessionTrackIds[playlistId]?.remove(trackId);
  }
}
