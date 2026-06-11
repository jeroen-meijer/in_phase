import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:in_phase/src/logger/logger.dart';

/// Whether convert resolves a single video or a full playlist/mix.
enum YoutubeResolveScope { singleVideo, playlist }

/// Prompts on stdin for video-only vs full list when both are present.
///
/// [isMix] is true for `list=RD…` auto-mixes; false for `list=PL…` playlists.
YoutubeResolveScope promptYoutubeResolveScope({required bool isMix}) {
  final listDescription = isMix
      ? 'YouTube mix (auto-generated, ~25 tracks, best-effort snapshot)'
      : 'playlist (all tracks in the list)';
  log
    ..info('This URL is a watch page with a video and an associated list.')
    ..info('  List type: $listDescription');

  while (true) {
    final answer = ask('[v]ideo only or [p]laylist?').trim().toLowerCase();
    switch (answer) {
      case 'v':
      case 'video':
        return YoutubeResolveScope.singleVideo;
      case 'p':
      case 'playlist':
        return YoutubeResolveScope.playlist;
      default:
        log.info(
          'Please enter "v" for the current video only or "p" for the '
          'full list.',
        );
    }
  }
}

/// Resolves scope for watch URLs that include both `v=` and `list=`.
YoutubeResolveScope resolveWatchAndListScope({
  required bool isMix,
  String? scopeFlag,
}) {
  if (scopeFlag != null) {
    return scopeFlag == 'playlist'
        ? YoutubeResolveScope.playlist
        : YoutubeResolveScope.singleVideo;
  }

  if (stdin.hasTerminal) {
    return promptYoutubeResolveScope(isMix: isMix);
  }

  return YoutubeResolveScope.singleVideo;
}
