extension type SpotifyPlaylistId(String _value) implements String {
  static final _regex = RegExp(r'^[a-zA-Z0-9]{22}$');

  static SpotifyPlaylistId? tryParse(String value) {
    if (_regex.hasMatch(value)) {
      return SpotifyPlaylistId(value);
    }
    return null;
  }

  /// Extracts playlist ID from ID, URI (spotify:playlist:xxx), or share URL.
  static SpotifyPlaylistId? tryExtract(String input) {
    final s = input.trim();

    // Check for URI
    if (s.startsWith('spotify:playlist:')) {
      final id = s.split(':').last.split('?').first;
      return tryParse(id);
    }

    // Check for share URL
    if (Uri.tryParse(s) case Uri(
      host: 'open.spotify.com' || 'spotify.com',
      pathSegments: ['playlist', final id, ...],
    )) {
      return tryParse(id);
    }

    // Check for ID
    return tryParse(s);
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

  /// Creates a cache identifier for a page of playlist track requests.
  const SpotifyCacheIdentifier.playlistTracksPage(
    SpotifyPlaylistId playlistId,
    int offset,
  ) : _value = 'playlist-tracks:$playlistId:page:$offset';

  /// Creates a cache identifier for a page of the user's saved playlists.
  const SpotifyCacheIdentifier.savedPlaylistsPage(int offset)
    : _value = 'saved-playlists:page:$offset';

  /// Creates a cache identifier for a page of the user's saved tracks.
  const SpotifyCacheIdentifier.savedTracksPage(int offset)
    : _value = 'saved-tracks:page:$offset';

  /// Creates a cache identifier for artist albums requests.
  const SpotifyCacheIdentifier.artistAlbums(SpotifyArtistId artistId)
    : _value = 'artist-albums:$artistId';

  /// Creates a cache identifier for a specific page of artist albums.
  const SpotifyCacheIdentifier.artistAlbumsPage(
    SpotifyArtistId artistId,
    int offset,
  ) : _value = 'artist-albums:$artistId:page:$offset';

  /// Creates a cache identifier for label search requests.
  const SpotifyCacheIdentifier.labelSearch(String labelName)
    : _value = 'label-search:$labelName';
}
