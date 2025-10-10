extension type SpotifyPlaylistId(String value) implements String {
  static final _regex = RegExp(r'^[a-zA-Z0-9]{22}$');

  static SpotifyPlaylistId? tryParse(String value) {
    if (_regex.hasMatch(value)) {
      return SpotifyPlaylistId(value);
    }
    return null;
  }

  String get uri => 'spotify:playlist:$value';
}

extension type const SpotifyArtistId(String value) implements String {
  static final _regex = RegExp(r'^[a-zA-Z0-9]{22}$');

  static SpotifyPlaylistId? tryParse(String value) {
    if (_regex.hasMatch(value)) {
      return SpotifyPlaylistId(value);
    }
    return null;
  }

  String get uri => 'spotify:artist:$value';
}

extension type const SpotifyAlbumId(String value) implements String {
  static final _regex = RegExp(r'^[a-zA-Z0-9]{22}$');

  static SpotifyPlaylistId? tryParse(String value) {
    if (_regex.hasMatch(value)) {
      return SpotifyPlaylistId(value);
    }
    return null;
  }

  String get uri => 'spotify:album:$value';
}

extension type const SpotifyTrackId(String value) implements String {
  static final _regex = RegExp(r'^[a-zA-Z0-9]{22}$');

  static SpotifyPlaylistId? tryParse(String value) {
    if (_regex.hasMatch(value)) {
      return SpotifyPlaylistId(value);
    }
    return null;
  }

  String get uri => 'spotify:track:$value';
}

/// Type-safe cache identifier for Spotify API requests.
extension type const SpotifyCacheIdentifier(String value) implements String {
  const SpotifyCacheIdentifier._(this.value);

  /// Creates a cache identifier for album requests.
  static SpotifyCacheIdentifier album(SpotifyAlbumId albumId) =>
      SpotifyCacheIdentifier._('album:${albumId.value}');

  /// Creates a cache identifier for artist requests.
  static SpotifyCacheIdentifier artist(SpotifyArtistId artistId) =>
      SpotifyCacheIdentifier._('artist:${artistId.value}');

  /// Creates a cache identifier for playlist requests.
  static SpotifyCacheIdentifier playlist(SpotifyPlaylistId playlistId) =>
      SpotifyCacheIdentifier._('playlist:${playlistId.value}');

  /// Creates a cache identifier for playlist track requests.
  static SpotifyCacheIdentifier playlistTracks(SpotifyPlaylistId playlistId) =>
      SpotifyCacheIdentifier._('playlist-tracks:${playlistId.value}');

  /// Creates a cache identifier for artist albums requests.
  static SpotifyCacheIdentifier artistAlbums(SpotifyArtistId artistId) =>
      SpotifyCacheIdentifier._('artist-albums:${artistId.value}');

  /// Creates a cache identifier for label search requests.
  static SpotifyCacheIdentifier labelSearch(String labelName) =>
      SpotifyCacheIdentifier._('label-search:$labelName');
}
