extension type SpotifyPlaylistId(String _value) implements String {
  static final _regex = RegExp(r'^[a-zA-Z0-9]{22}$');

  static SpotifyPlaylistId? tryParse(String value) {
    if (_regex.hasMatch(value)) {
      return SpotifyPlaylistId(value);
    }
    return null;
  }

  String get uri => 'spotify:playlist:$_value';
}

extension type const SpotifyArtistId(String _value) implements String {
  static final _regex = RegExp(r'^[a-zA-Z0-9]{22}$');

  static SpotifyPlaylistId? tryParse(String value) {
    if (_regex.hasMatch(value)) {
      return SpotifyPlaylistId(value);
    }
    return null;
  }

  String get uri => 'spotify:artist:$_value';
}

extension type const SpotifyAlbumId(String _value) implements String {
  static final _regex = RegExp(r'^[a-zA-Z0-9]{22}$');

  static SpotifyPlaylistId? tryParse(String value) {
    if (_regex.hasMatch(value)) {
      return SpotifyPlaylistId(value);
    }
    return null;
  }

  String get uri => 'spotify:album:$_value';
}

extension type const SpotifyTrackId(String _value) implements String {
  static final _regex = RegExp(r'^[a-zA-Z0-9]{22}$');

  static SpotifyPlaylistId? tryParse(String value) {
    if (_regex.hasMatch(value)) {
      return SpotifyPlaylistId(value);
    }
    return null;
  }

  String get uri => 'spotify:track:$_value';
}

/// Type-safe cache identifier for Spotify API requests.
extension type const SpotifyCacheIdentifier._(String _value) implements String {
  /// Creates a cache identifier for album requests.
  const SpotifyCacheIdentifier.album(SpotifyAlbumId albumId)
    : _value = 'album:$albumId';

  /// Creates a cache identifier for artist requests.
  const SpotifyCacheIdentifier.artist(SpotifyArtistId artistId)
    : _value = 'artist:$artistId';

  /// Creates a cache identifier for playlist requests.
  const SpotifyCacheIdentifier.playlist(SpotifyPlaylistId playlistId)
    : _value = 'playlist:$playlistId';

  /// Creates a cache identifier for playlist track requests.
  const SpotifyCacheIdentifier.playlistTracks(SpotifyPlaylistId playlistId)
    : _value = 'playlist-tracks:$playlistId';

  /// Creates a cache identifier for artist albums requests.
  const SpotifyCacheIdentifier.artistAlbums(SpotifyArtistId artistId)
    : _value = 'artist-albums:$artistId';

  /// Creates a cache identifier for label search requests.
  const SpotifyCacheIdentifier.labelSearch(String labelName)
    : _value = 'label-search:$labelName';
}
