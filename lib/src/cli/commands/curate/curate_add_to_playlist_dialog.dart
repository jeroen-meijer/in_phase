import 'dart:async';

import 'package:in_phase/src/cli/commands/curate/curate_playlist_add.dart';
import 'package:in_phase/src/cli/commands/curate/curate_types.dart';
import 'package:in_phase/src/cli/commands/curate/curate_user_playlists_cache.dart';
import 'package:nocterm/nocterm.dart';
import 'package:spotify/spotify.dart';

/// Modal picker: search user playlists and add or move the current track on
/// Enter.
final class CurateAddToPlaylistDialog extends StatefulComponent {
  const CurateAddToPlaylistDialog({
    required this.context,
    required this.runtime,
    required this.currentTrack,
    super.key,
  });

  final CurateContext context;
  final CurateRuntimeState runtime;
  final CurrentTrackInfo currentTrack;

  @override
  State<CurateAddToPlaylistDialog> createState() =>
      _CurateAddToPlaylistDialogState();
}

final class _CurateAddToPlaylistDialogState
    extends State<CurateAddToPlaylistDialog> {
  final _searchController = TextEditingController();
  var _query = '';
  var _selectedIndex = 0;
  var _adding = false;

  CurateUserPlaylistsCache get _playlists => component.context.userPlaylists;

  bool get _moveMode => component.runtime.moveMode;

  List<PlaylistSimple> get _filtered => _playlists.filter(_query);

  @override
  void initState() {
    super.initState();
    if (!_playlists.loaded) {
      unawaited(_waitForPlaylists());
    }
    _searchController.addListener(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _query = _searchController.text;
        _selectedIndex = 0;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _waitForPlaylists() async {
    await _playlists.ready;
    if (mounted) {
      setState(() {});
    }
  }

  void _moveSelection(int delta) {
    final items = _filtered;
    if (items.isEmpty) {
      return;
    }
    setState(() {
      _selectedIndex = (_selectedIndex + delta).clamp(0, items.length - 1);
    });
  }

  Future<void> _confirmSelection() async {
    if (_adding) {
      return;
    }
    final items = _filtered;
    if (items.isEmpty) {
      return;
    }
    final playlist = items[_selectedIndex.clamp(0, items.length - 1)];
    final playlistId = playlist.id;
    final playlistName = playlist.name ?? playlistId ?? 'playlist';
    if (playlistId == null || playlistId.isEmpty) {
      return;
    }

    setState(() => _adding = true);
    try {
      final result = _moveMode
          ? await curateMoveTrackToPlaylist(
              context: component.context,
              runtime: component.runtime,
              currentTrack: component.currentTrack,
              playlistId: playlistId,
              playlistName: playlistName,
            )
          : await curateAddTrackToPlaylist(
              context: component.context,
              currentTrack: component.currentTrack,
              playlistId: playlistId,
              playlistName: playlistName,
            );
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } finally {
      if (mounted) {
        setState(() => _adding = false);
      }
    }
  }

  bool _onSearchKey(KeyboardEvent event) {
    if (event.logicalKey == LogicalKey.arrowDown) {
      _moveSelection(1);
      return true;
    }
    if (event.logicalKey == LogicalKey.arrowUp) {
      _moveSelection(-1);
      return true;
    }
    if (event.logicalKey == LogicalKey.enter) {
      unawaited(_confirmSelection());
      return true;
    }
    return false;
  }

  @override
  Component build(BuildContext context) {
    final title = _moveMode ? 'Move to playlist' : 'Add to playlist';
    final actionHint = _moveMode ? 'move' : 'add';

    if (!_playlists.loaded) {
      return Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: Colors.black,
          border: BoxBorder.all(color: Colors.grey),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 1),
            const Text(
              'Loading your playlists…',
              style: TextStyle(fontWeight: FontWeight.dim),
            ),
          ],
        ),
      );
    }

    final items = _filtered;

    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: Colors.black,
        border: BoxBorder.all(color: Colors.grey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 1),
          TextField(
            controller: _searchController,
            focused: true,
            placeholder: 'Search playlists',
            placeholderStyle: const TextStyle(fontWeight: FontWeight.dim),
            onKeyEvent: _onSearchKey,
            onSubmitted: (_) => unawaited(_confirmSelection()),
          ),
          const SizedBox(height: 1),
          if (_adding)
            Text(
              _moveMode ? 'Moving…' : 'Adding…',
              style: const TextStyle(fontWeight: FontWeight.dim),
            )
          else if (items.isEmpty)
            Text(
              _query.isEmpty
                  ? 'No editable playlists found'
                  : 'No playlists match "$_query"',
              style: const TextStyle(fontWeight: FontWeight.dim),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final playlist = items[index];
                  final selected = index == _selectedIndex;
                  final name = playlist.name ?? '?';
                  final count = _formatTrackCount(playlist.tracksLink?.total);
                  return RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${selected ? '●' : '○'} $name  ',
                          style: TextStyle(
                            color: selected ? Colors.cyan : null,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        TextSpan(
                          text: count,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.dim,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 1),
          Text(
            '↑/↓ select · Enter $actionHint · Esc cancel',
            style: const TextStyle(fontWeight: FontWeight.dim),
          ),
        ],
      ),
    );
  }
}

String _formatTrackCount(int? total) {
  if (total == null) {
    return '? tracks';
  }
  if (total == 1) {
    return '1 track';
  }
  return '$total tracks';
}
