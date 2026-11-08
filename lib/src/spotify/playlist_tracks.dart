import 'package:in_phase/src/misc/misc.dart';
import 'package:in_phase/src/spotify/types.dart';
import 'package:spotify/spotify.dart';

/// Max items per Spotify playlist write request.
const _maxTracksPerWrite = 100;

extension SpotifyPlaylistTracks on Iterable<PlaylistTrack> {
  /// Entries whose track has a Spotify id. Local files and unavailable items
  /// have none.
  Iterable<PlaylistTrack> get spotifyTracks =>
      where((entry) => entry.track?.id != null);
}

/// Fetches every entry of [playlistId], including local files.
Future<List<PlaylistTrack>> fetchPlaylistTracks({
  required SpotifyApi api,
  required RequestPool requestPool,
  required SpotifyPlaylistId playlistId,
}) {
  return requestPool.fetchAllPages(
    api.playlists.getPlaylistTracks(playlistId),
    pageIdentifier: (offset) =>
        SpotifyCacheIdentifier.playlistTracksPage(playlistId, offset),
  );
}

/// Fetches all playlists in the user's library.
Future<List<PlaylistSimple>> fetchSavedPlaylists({
  required SpotifyApi api,
  required RequestPool requestPool,
}) {
  return requestPool.fetchAllPages(
    api.me.playlists.saved(),
    pageIdentifier: SpotifyCacheIdentifier.savedPlaylistsPage,
  );
}

/// Replaces all items of [playlistId] with [uris].
///
/// The first request swaps the contents in one call, so a failure later on
/// leaves the playlist with at least its first 100 new tracks instead of
/// empty.
Future<void> replacePlaylistTracks({
  required SpotifyApi api,
  required SpotifyPlaylistId playlistId,
  required List<String> uris,
}) async {
  if (uris.isEmpty) {
    await api.playlists.clear(playlistId);
    return;
  }
  await api.playlists.replace(
    playlistId,
    uris.take(_maxTracksPerWrite).toList(),
  );
  await _addTracks(api, playlistId, uris.skip(_maxTracksPerWrite).toList());
}

/// Appends the [uris] that are not in [playlistId] yet, in order.
///
/// Returns the URIs that were added.
Future<List<String>> appendNewPlaylistTracks({
  required SpotifyApi api,
  required RequestPool requestPool,
  required SpotifyPlaylistId playlistId,
  required List<String> uris,
}) async {
  final existing = await fetchPlaylistTracks(
    api: api,
    requestPool: requestPool,
    playlistId: playlistId,
  );
  final existingUris = existing.map((entry) => entry.track?.uri).toSet();
  final newUris = uris.where((uri) => !existingUris.contains(uri)).toList();
  await _addTracks(api, playlistId, newUris);
  return newUris;
}

Future<void> _addTracks(
  SpotifyApi api,
  SpotifyPlaylistId playlistId,
  List<String> uris,
) async {
  for (var i = 0; i < uris.length; i += _maxTracksPerWrite) {
    await api.playlists.addTracks(
      uris.skip(i).take(_maxTracksPerWrite).toList(),
      playlistId,
    );
  }
}
