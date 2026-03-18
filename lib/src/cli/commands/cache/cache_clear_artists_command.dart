import 'package:args/command_runner.dart';
import 'package:in_phase/src/database/cache_adapter.dart';
import 'package:in_phase/src/database/database.exports.dart';
import 'package:in_phase/src/logger/logger.dart';
import 'package:in_phase/src/spotify/spotify.dart';
import 'package:io/io.dart';

/// Clears crawl cache for specific artists so the next crawl fetches fresh data.
///
/// Use when artists have new releases that aren't showing up, often because
/// the cache was populated before the release and marked "fresh today".
class CacheClearArtistsCommand extends Command<int> {
  CacheClearArtistsCommand() {
    argParser.addMultiOption(
      'artist',
      abbr: 'a',
      help: 'Spotify artist ID(s) to clear cache for.',
      valueHelp: 'id',
    );
  }

  @override
  final String name = 'clear-artists';

  @override
  final String description =
      'Clears crawl cache for specific artists. '
      'Next crawl will re-fetch albums from Spotify.';

  @override
  Future<int> run() async {
    final artistIds = argResults!['artist'] as List<String>;
    if (artistIds.isEmpty) {
      log.error('Specify at least one artist with --artist <id>');
      log.info('Example: in_phase cache clear-artists -a 4UJP03mzC9b90Qq1TqavvN');
      return ExitCode.usage.code;
    }

    final database = db();
    final adapter = CacheAdapter(database);

    for (final id in artistIds) {
      try {
        await adapter.deleteArtistCache(SpotifyArtistId(id));
        log.info('Cleared cache for artist: $id');
      } catch (e) {
        log.error('Failed to clear cache for $id: $e');
        return ExitCode.software.code;
      }
    }

    log.info('Done. Run crawl with --verbose to see what is found.');
    return ExitCode.success.code;
  }
}
