import 'package:in_phase/src/library/rekordbox/anlz_parser.dart';
import 'package:in_phase/src/library/rekordbox/rekordbox_artwork.dart';
import 'package:in_phase/src/library/rekordbox/rekordbox_models.dart';
import 'package:in_phase/src/logger/logger.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:path/path.dart' as p;
import 'package:rekorddart/rekorddart.dart';

/// Everything read from Rekordbox that is needed for an Engine DJ sync.
class RekordboxLibrary {
  const RekordboxLibrary({required this.tracks, required this.playlistTree});

  final List<RekordboxTrack> tracks;

  /// Root playlist nodes in `Seq` order.
  final List<RekordboxPlaylistNode> playlistTree;
}

/// Reads tracks (with cues and ANLZ beat grids) and the playlist tree from
/// the Rekordbox database.
///
/// [anlzRootPath] is the Rekordbox share directory containing `PIONEER/`
/// analysis files, typically `~/Library/Pioneer/rekordbox/share`.
Future<RekordboxLibrary> readRekordboxLibrary(
  RekordboxDatabase db, {
  required String anlzRootPath,
}) async {
  final artistNames = await _nameMap(
    db,
    await db.select(db.djmdArtist).get(),
    (r) => (r.id, r.name),
  );
  final albumNames = await _nameMap(
    db,
    await db.select(db.djmdAlbum).get(),
    (r) => (r.id, r.name),
  );
  final genreNames = await _nameMap(
    db,
    await db.select(db.djmdGenre).get(),
    (r) => (r.id, r.name),
  );
  final albumImagePaths = {
    for (final album in await db.select(db.djmdAlbum).get())
      if (album.id != null &&
          album.imagePath != null &&
          album.imagePath!.isNotEmpty)
        album.id!: album.imagePath!,
  };
  final labelNames = await _nameMap(
    db,
    await db.select(db.djmdLabel).get(),
    (r) => (r.id, r.name),
  );
  final keyNames = await _nameMap(
    db,
    await db.select(db.djmdKey).get(),
    (r) => (r.id, r.scaleName),
  );

  final contents = await (db.select(
    db.djmdContent,
  )..where((c) => c.rbLocalDeleted.equals(0))).get();

  final allCues = await (db.select(
    db.djmdCue,
  )..where((c) => c.rbLocalDeleted.equals(0))).get();
  final cuesByContent = <String, List<RekordboxCue>>{};
  for (final cue in allCues) {
    final contentId = cue.contentID;
    final kind = CueKind.fromKind(cue.kind);
    final inMsec = cue.inMsec;
    if (contentId == null || kind == null || inMsec == null || inMsec < 0) {
      continue;
    }
    cuesByContent
        .putIfAbsent(contentId, () => [])
        .add(
          RekordboxCue(
            kind: kind,
            inMsec: inMsec,
            inFrame: cue.inFrame,
            outMsec: cue.outMsec != null && cue.outMsec! > inMsec
                ? cue.outMsec
                : null,
            comment: cue.comment,
          ),
        );
  }

  final tracks = <RekordboxTrack>[];
  var missingGrids = 0;
  for (final content in contents) {
    final id = content.id;
    if (id == null) continue;

    final audioPath = rekordboxAudioPath(content);
    if (audioPath == null || !p.isAbsolute(audioPath)) {
      log.debug('Skipping track without local audio file: ${content.title}');
      continue;
    }

    List<AnlzBeat>? beatGrid;
    final analysisDataPath = content.analysisDataPath;
    if (analysisDataPath != null && analysisDataPath.isNotEmpty) {
      beatGrid = await readAnlzBeatGrid(
        p.join(anlzRootPath, _stripLeadingSlash(analysisDataPath)),
      );
    }
    if (beatGrid == null) missingGrids++;

    tracks.add(
      RekordboxTrack(
        id: id,
        audioFilePath: audioPath,
        title: content.title,
        artist: artistNames[content.artistID],
        album: albumNames[content.albumID],
        genre: genreNames[content.genreID],
        label: labelNames[content.labelID],
        composer: artistNames[content.composerID],
        remixer: artistNames[content.remixerID],
        comment: content.commnt,
        keyName: keyNames[content.keyID],
        bpmCenti: content.bpm,
        lengthSeconds: content.length,
        rating: content.rating,
        releaseYear: content.releaseYear,
        bitRate: content.bitRate,
        fileSizeBytes: content.fileSize,
        sampleRate: content.sampleRate,
        dateAdded: _parseRekordboxDate(content.stockDate ?? content.createdAt),
        artworkRelativePath: normalizeRekordboxSharePath(
          content.imagePath ?? albumImagePaths[content.albumID],
        ),
        cues: cuesByContent[id] ?? const [],
        beatGrid: beatGrid,
      ),
    );
  }

  if (missingGrids > 0) {
    log.debug(
      '$missingGrids track(s) have no ANLZ beat grid; Engine will analyze '
      'those itself.',
    );
  }

  return RekordboxLibrary(
    tracks: tracks,
    playlistTree: await _readPlaylistTree(db),
  );
}

Future<Map<String, String>> _nameMap<T>(
  RekordboxDatabase db,
  List<T> rows,
  (String?, String?) Function(T) selector,
) async {
  final map = <String, String>{};
  for (final row in rows) {
    final (id, name) = selector(row);
    if (id != null && name != null && name.isNotEmpty) {
      map[id] = name;
    }
  }
  return map;
}

Future<List<RekordboxPlaylistNode>> _readPlaylistTree(
  RekordboxDatabase db,
) async {
  final playlists = await (db.select(
    db.djmdPlaylist,
  )..where((s) => s.rbLocalDeleted.equals(0))).get();

  final songs = await (db.select(
    db.djmdSongPlaylist,
  )..where((s) => s.rbLocalDeleted.equals(0))).get();
  final trackIdsByPlaylist = <String, List<(int, String)>>{};
  for (final song in songs) {
    final playlistId = song.playlistID;
    final contentId = song.contentID;
    if (playlistId == null || contentId == null) continue;
    trackIdsByPlaylist.putIfAbsent(playlistId, () => []).add((
      song.trackNo ?? 0,
      contentId,
    ));
  }

  final byParent = <String, List<DjmdPlaylistData>>{};
  for (final playlist in playlists) {
    // Attribute 0 = playlist, 1 = folder, 4 = smart playlist. Smart
    // playlists cannot be represented in Engine, so they are skipped.
    if (playlist.smartList != null || playlist.attribute == 4) continue;
    byParent.putIfAbsent(playlist.parentID ?? 'root', () => []).add(playlist);
  }

  List<RekordboxPlaylistNode> buildChildren(String parentId) {
    final children = byParent[parentId] ?? const [];
    final sorted = children.toList()
      ..sort((a, b) => (a.seq ?? 0).compareTo(b.seq ?? 0));
    return [
      for (final playlist in sorted)
        if (playlist.id != null && (playlist.name ?? '').isNotEmpty)
          RekordboxPlaylistNode(
            id: playlist.id!,
            name: playlist.name!,
            isFolder: playlist.attribute == 1,
            children: playlist.attribute == 1
                ? buildChildren(playlist.id!)
                : const [],
            trackIds: playlist.attribute == 1
                ? const []
                : _sortedTrackIds(trackIdsByPlaylist[playlist.id!]),
          ),
    ];
  }

  return buildChildren('root');
}

List<String> _sortedTrackIds(List<(int, String)>? entries) {
  if (entries == null) return const [];
  final sorted = entries.toList()..sort((a, b) => a.$1.compareTo(b.$1));
  return [for (final (_, contentId) in sorted) contentId];
}

String _stripLeadingSlash(String path) =>
    path.startsWith('/') ? path.substring(1) : path;

DateTime? _parseRekordboxDate(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value.trim());
}
