import 'dart:async';

import 'package:dcli/dcli.dart' hide Env;
import 'package:doos/doos.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:rkdb_dart/src/logger/logger.dart';
import 'package:rkdb_dart/src/misc/misc.dart';
import 'package:spotify/spotify.dart';

part 'api.g.dart';

const _credentialsKey = 'spotify_credentials';
const _scopes = [
  'ugc-image-upload',
  'user-read-playback-state',
  'user-modify-playback-state',
  'user-read-currently-playing',
  'app-remote-control',
  'streaming',
  'playlist-read-private',
  'playlist-read-collaborative',
  'playlist-modify-private',
  'playlist-modify-public',
  'user-follow-modify',
  'user-follow-read',
  'user-read-playback-position',
  'user-top-read',
  'user-read-recently-played',
  'user-library-modify',
  'user-library-read',
  'user-read-email',
  'user-read-private',
];

final DoosStorageEntry<_SavedClientCredentials> _credentialsEntry =
    Zonable.fromZone<Doos>().getEntry<_SavedClientCredentials>(
      _credentialsKey,
      deserializer: (value) =>
          _SavedClientCredentials.fromJson(value as Map<String, dynamic>),
    );

Future<void> _writeCredentials(SpotifyApiCredentials credentials) async {
  log.debug('Writing credentials to cache');
  await _credentialsEntry.write(
    _SavedClientCredentials.fromSpotifyApiCredentials(credentials),
  );
}

Future<SpotifyApi> spotifyLogin({
  FutureOr<String> Function(Uri) redirectAndGetResponseUri =
      spotifyOpenBrowserAndAskForPasteUrl,
  bool useCache = true,
}) async {
  final env = Zonable.fromZone<Env>();

  try {
    if (await _attemptCachedCredentialsLogin() case final api? when useCache) {
      return api;
    }
  } on AuthorizationException {
    log.debug(
      'Stored access and refresh tokens have expired -- '
      'logging in instead',
    );
    await spotifyLogout();
  }

  final credentials = SpotifyApiCredentials(
    env.spotifyClientId,
    env.spotifyClientSecret,
    scopes: _scopes,
  );
  final grant = SpotifyApi.authorizationCodeGrant(
    credentials,
    onCredentialsRefreshed: _writeCredentials,
  );
  final redirectUri = Uri.parse(env.spotifyRedirectUri);
  final authUri = grant.getAuthorizationUrl(
    redirectUri,
    scopes: _scopes,
  );

  log.debug('Getting authorization URL: $authUri');
  final responseUri = await redirectAndGetResponseUri(authUri);
  log.debug('Redirecting to URL: $redirectUri');

  final api = SpotifyApi.fromAuthCodeGrant(grant, responseUri);
  await _writeCredentials(await api.getCredentials());

  return api;
}

Future<SpotifyApi?> _attemptCachedCredentialsLogin() async {
  final env = Zonable.fromZone<Env>();
  final credentialsDataResult = await _credentialsEntry.readOrNull();

  final _SavedClientCredentials credentialsData;

  switch (credentialsDataResult) {
    case DoosErr(:final error):
      throw Exception('Failed to read credentials: $error');
    case DoosOk(value: null):
      return null;
    case DoosOk(value: final credentialsData_?):
      credentialsData = credentialsData_;
  }

  final credentials = credentialsData.toSpotifyApiCredentials(
    clientId: env.spotifyClientId,
    clientSecret: env.spotifyClientSecret,
  );
  final api = SpotifyApi(
    credentials,
    onCredentialsRefreshed: _writeCredentials,
  );
  await _writeCredentials(await api.getCredentials());

  return api;
}

Future<String> spotifyOpenBrowserAndAskForPasteUrl(Uri uri) async {
  log.info('Please open a browser to this URL:\n\n  $uri\n');

  final response = ask(
    'Please paste the URL from the browser after you have logged in:',
  );
  return response.trim();
}

Future<void> spotifyLogout() async {
  log.debug('Removing credentials from cache');
  await _credentialsEntry.remove();
}

@JsonSerializable()
class _SavedClientCredentials {
  _SavedClientCredentials({
    required this.accessToken,
    required this.refreshToken,
    required this.scopes,
    required this.expiration,
  });

  factory _SavedClientCredentials.fromSpotifyApiCredentials(
    SpotifyApiCredentials credentials,
  ) => _SavedClientCredentials(
    accessToken: credentials.accessToken!,
    refreshToken: credentials.refreshToken!,
    scopes: credentials.scopes!,
    expiration: credentials.expiration!,
  );

  factory _SavedClientCredentials.fromJson(Map<String, dynamic> json) =>
      _$SavedClientCredentialsFromJson(json);
  Map<String, dynamic> toJson() => _$SavedClientCredentialsToJson(this);

  SpotifyApiCredentials toSpotifyApiCredentials({
    required String clientId,
    required String clientSecret,
  }) => SpotifyApiCredentials(
    clientId,
    clientSecret,
    accessToken: accessToken,
    refreshToken: refreshToken,
    scopes: scopes,
    expiration: expiration,
  );

  final String accessToken;
  final String refreshToken;
  final List<String> scopes;
  final DateTime expiration;
}
