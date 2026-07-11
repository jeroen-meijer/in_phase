import 'package:in_phase/src/cli/commands/curate/curate_types.dart';
import 'package:in_phase/src/entities/entities.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:nocterm/nocterm.dart';
import 'package:spotify/spotify.dart';

/// Plain-text track line (header applies [Colors.cyan] in the session view).
String formatCurateTrackLine({
  required int position,
  required int total,
  required int progressMs,
  required int durationMs,
  required Track track,
}) {
  final progress = formatDurationMs(progressMs.clamp(0, durationMs));
  final duration = formatDurationMs(durationMs);
  final artists = track.artists?.map((a) => a.name).join(', ') ?? '?';
  return '[$position/$total] $progress/$duration  ${track.name} — $artists';
}

/// One cell: ✓ if [isIn] is true, space if false, dim space if unknown.
TextSpan _librarySlot(bool? isIn) {
  if (isIn == true) {
    return const TextSpan(
      text: '✓',
      style: TextStyle(color: Colors.green),
    );
  }
  return const TextSpan(
    text: ' ',
    style: TextStyle(
      color: Colors.grey,
      fontWeight: FontWeight.dim,
    ),
  );
}

/// `null` when [trackId] or [map] is null (still loading or no id).
bool? _trackInPlaylist(
  String? trackId,
  Map<String, Set<String>>? map,
  String playlistId,
) {
  if (trackId == null || map == null) {
    return null;
  }
  return map[playlistId]?.contains(trackId) ?? false;
}

/// Sticky footer row: target playlist keys (styled) + per-target ✓ / space.
RichText curateFooterTargetsRow(
  List<CurateResolvedTarget> targets, {
  String? trackId,
  Map<String, Set<String>>? playlistTrackIds,
}) {
  if (targets.isEmpty) {
    return const RichText(
      text: TextSpan(
        text: 'No target playlists in config — add targets for keys 1–9.',
        style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.dim),
      ),
    );
  }

  final children = <InlineSpan>[
    for (var i = 0; i < targets.length; i++) ...[
      if (i > 0) const TextSpan(text: '  '),
      TextSpan(
        text: '[${i + 1}]',
        style: const TextStyle(color: Colors.green),
      ),
      _librarySlot(
        _trackInPlaylist(
          trackId,
          playlistTrackIds,
          targets[i].playlistId,
        ),
      ),
      TextSpan(text: ' ${targets[i].name}'),
    ],
  ];
  return RichText(
    text: TextSpan(
      children: children,
      style: const TextStyle(fontWeight: FontWeight.dim),
    ),
  );
}

/// Sticky footer row: global shortcuts + ✓ / space for Liked Songs on `[l]`.
RichText curateFooterKeysRow(
  CurateConfig config, {
  String? trackId,
  Set<String>? likedIds,
  bool moveMode = false,
}) {
  final inLikes = trackId == null || likedIds == null
      ? null
      : likedIds.contains(trackId);

  final children = <InlineSpan>[
    const TextSpan(
      text: '[l]',
      style: TextStyle(color: Colors.cyan),
    ),
    _librarySlot(inLikes),
    const TextSpan(
      text: ' like  [n/s] next  ',
      style: TextStyle(color: Colors.cyan),
    ),
    const TextSpan(
      text: '[←/→] seek ±',
      style: TextStyle(color: Colors.cyan),
    ),
    TextSpan(
      text: '${config.seekStep}s  ',
      style: const TextStyle(color: Colors.cyan),
    ),
    const TextSpan(
      text: '[r] restart  ',
      style: TextStyle(color: Colors.cyan),
    ),
    const TextSpan(
      text: '[c] copy URL  ',
      style: TextStyle(color: Colors.cyan),
    ),
    const TextSpan(
      text: '[o] open  ',
      style: TextStyle(color: Colors.cyan),
    ),
    const TextSpan(
      text: '[f] find playlist  ',
      style: TextStyle(color: Colors.cyan),
    ),
    const TextSpan(
      text: '[m] move ',
      style: TextStyle(color: Colors.cyan),
    ),
    TextSpan(
      text: moveMode ? 'ON  ' : 'OFF  ',
      style: TextStyle(
        color: moveMode ? Colors.green : Colors.grey,
        fontWeight: moveMode ? FontWeight.bold : FontWeight.dim,
      ),
    ),
    const TextSpan(
      text: '[q] quit',
      style: TextStyle(color: Colors.cyan),
    ),
  ];

  if (config.autoAddToLikes) {
    children.addAll(const [
      TextSpan(
        text: '  auto-like: ',
        style: TextStyle(
          color: Colors.cyan,
          fontWeight: FontWeight.dim,
        ),
      ),
      TextSpan(
        text: '✓',
        style: TextStyle(color: Colors.green),
      ),
    ]);
  }

  return RichText(
    text: TextSpan(
      children: children,
      style: const TextStyle(fontWeight: FontWeight.dim),
    ),
  );
}
