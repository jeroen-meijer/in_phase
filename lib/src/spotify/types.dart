extension type SpotifyPlaylistId._(String value) implements String {
  static final _regex = RegExp(r'^[a-zA-Z0-9]{22}$');

  static SpotifyPlaylistId? tryParse(String value) {
    if (_regex.hasMatch(value)) {
      return SpotifyPlaylistId._(value);
    }
    return null;
  }

  String get uri => 'spotify:playlist:$value';
}
