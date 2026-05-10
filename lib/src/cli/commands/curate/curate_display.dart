import 'package:dcli/dcli.dart';
import 'package:in_phase/src/entities/entities.dart';
import 'package:in_phase/src/logger/logger.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:spotify/spotify.dart';

/// Prints the keyboard shortcut hints for the curate session.
void printKeyHints(CurateConfig config) {
  final targetHints = config.targets
      .asMap()
      .entries
      .map((e) => '${green("[${e.key + 1}]")} ${e.value.name}')
      .join('  ');
  final autoLike = config.autoAddToLikes ? '  ${cyan("auto-like")}' : '';
  log.raw(
    '$targetHints  ${cyan("[n/s]")} next  '
    '${cyan("[←][→]")} seek ±${config.seekStep}s  '
    '${cyan("[r]")} restart  ${cyan("[l]")} like  ${cyan("[c]")} copy URL  '
    '${cyan("[q]")} quit$autoLike',
  );
}

/// Prints a single track line with position and duration.
void printTrackLine(
  int position,
  int total,
  int progressMs,
  int durationMs,
  Track track,
) {
  final progress = formatDurationMs(progressMs.clamp(0, durationMs));
  final duration = formatDurationMs(durationMs);
  final artists = track.artists?.map((a) => a.name).join(', ') ?? '?';
  log.raw(
    '${cyan('[$position/$total]')} $progress/$duration  ${track.name} - $artists',
  );
}
