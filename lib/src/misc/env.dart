import 'dart:io';

class Env {
  Env({
    required this.spotifyClientId,
    required this.spotifyClientSecret,
    required this.spotifyRedirectUri,
  });

  factory Env.fromHostEnvironment() {
    final [
      spotifyClientId,
      spotifyClientSecret,
      spotifyRedirectUri,
    ] = _requireEnvMany([
      'SPOTIFY_CLIENT_ID',
      'SPOTIFY_CLIENT_SECRET',
      'SPOTIFY_REDIRECT_URI',
    ]);

    return Env(
      spotifyClientId: spotifyClientId,
      spotifyClientSecret: spotifyClientSecret,
      spotifyRedirectUri: spotifyRedirectUri,
    );
  }

  final String spotifyClientId;
  final String spotifyClientSecret;
  final String spotifyRedirectUri;

  static List<String> _requireEnvMany(List<String> names) {
    final foundValues = {
      for (final name in names) name: Platform.environment[name],
    };

    if (foundValues.entries.where((e) => e.value == null)
        case final missingEnvVars when missingEnvVars.isNotEmpty) {
      throw Exception(
        'Environment variables not found: '
        '${missingEnvVars.map((e) => e.key).join(', ')}',
      );
    }

    return foundValues.values.map((e) => e!).toList();
  }
}
