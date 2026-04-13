import 'package:args/command_runner.dart';
import 'package:dart_console/dart_console.dart';
import 'package:dcli/dcli.dart';
import 'package:in_phase/src/database/database.exports.dart';
import 'package:in_phase/src/logger/logger.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:in_phase/src/spotify/spotify.dart';
import 'package:io/io.dart';

class BuyCommand extends Command<int> {
  BuyCommand() : _console = Console();

  final Console _console;

  @override
  final String name = 'buy';

  @override
  final String description =
      'Open iTunes links for missing tracks one-by-one to buy quickly.';

  @override
  Future<int> run() async {
    final missingTracks = await db().syncMissingTracksDao
        .getAllMissingTracksNewestFirst();

    if (missingTracks.isEmpty) {
      log.info('No missing tracks found.');
      return ExitCode.success.code;
    }

    log
      ..info('Found ${missingTracks.length} missing track(s).')
      ..info('Controls: [enter]=next, [o]=open again, [s]=skip, [q]=quit');

    for (var index = 0; index < missingTracks.length; index++) {
      final missingTrack = missingTracks[index];
      final trackId = SpotifyTrackId(missingTrack.spotifyTrackId);
      final label = '[${index + 1}/${missingTracks.length}]';
      final trackDisplay = '${missingTrack.artist} - ${missingTrack.title}';

      log.info('\n$label ${cyan(trackDisplay)}');

      final itunesUrl = await _resolveItunesUrl(
        trackId: trackId,
        missingTrack: missingTrack,
      );

      if (itunesUrl == null) {
        log.warning('No iTunes buy link found. Skipping to next track.');
        continue;
      }

      if (!await _openItunesUrl(itunesUrl)) {
        return ExitCode.software.code;
      }

      final action = _readPromptAction();
      if (action == _PromptAction.quit) {
        log.info('Stopped.');
        break;
      }
      if (action == _PromptAction.reopen) {
        if (!await _openItunesUrl(itunesUrl)) {
          return ExitCode.software.code;
        }
        final afterReopenAction = _readPromptAction();
        if (afterReopenAction == _PromptAction.quit) {
          log.info('Stopped.');
          break;
        }
      }
    }

    return ExitCode.success.code;
  }

  Future<String?> _resolveItunesUrl({
    required SpotifyTrackId trackId,
    required SyncMissingTrack missingTrack,
  }) async {
    if (missingTrack.itunesUrl case final existingUrl?
        when existingUrl.trim().isNotEmpty) {
      return ItunesStore.toStoreAppUrl(existingUrl);
    }

    log.info('No stored iTunes link, searching...');
    final discoveredUrl = await ItunesStore.lookupTrackUrl(
      artist: missingTrack.artist,
      title: missingTrack.title,
    );

    if (discoveredUrl != null) {
      await db().syncMissingTracksDao.updateItunesUrl(
        spotifyTrackId: trackId,
        itunesUrl: discoveredUrl,
      );
      log.info('Saved discovered iTunes link.');
    }

    return discoveredUrl;
  }

  Future<bool> _openItunesUrl(String itunesUrl) async {
    try {
      log.info('Opening: $itunesUrl');
      await SystemLauncher.openUrl(itunesUrl);
      return true;
    } catch (e) {
      if (e is UnsupportedError) {
        log.error(e.message);
        return false;
      }
      log.warning('Failed opening store URL, trying web URL fallback...');
      final webFallbackUrl = _toWebFallback(itunesUrl);
      if (webFallbackUrl == null) {
        log.error('Failed to open iTunes URL: $e');
        return false;
      }
      try {
        log.info('Opening fallback: $webFallbackUrl');
        await SystemLauncher.openUrl(webFallbackUrl);
        return true;
      } catch (fallbackError) {
        log.error(
          'Failed to open iTunes URL and fallback URL: $fallbackError',
        );
        return false;
      }
    }
  }

  _PromptAction _readPromptAction() {
    while (true) {
      log.raw(grey('Press [enter]/o/s/q: '));
      final key = _console.readKey();
      if (key.isControl) {
        if (key.controlChar == ControlCharacter.enter) {
          return _PromptAction.next;
        }
        continue;
      }

      final input = key.char.toLowerCase();
      switch (input) {
        case 'o':
          return _PromptAction.reopen;
        case 's':
          return _PromptAction.skip;
        case 'q':
          return _PromptAction.quit;
      }
    }
  }

  String? _toWebFallback(String storeUrl) {
    final parsed = Uri.tryParse(storeUrl);
    if (parsed == null || parsed.scheme != 'itmss') {
      return null;
    }
    final host = parsed.host;
    final trackId = parsed.queryParameters['i'];
    if (host.isEmpty || trackId == null || trackId.isEmpty) {
      return null;
    }
    return Uri(
      scheme: 'https',
      host: host,
      path: parsed.path,
      queryParameters: {'i': trackId},
    ).toString();
  }
}

enum _PromptAction { next, reopen, skip, quit }
