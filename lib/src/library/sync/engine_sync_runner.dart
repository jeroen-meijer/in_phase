import 'package:collection/collection.dart';
import 'package:in_phase/src/library/convert/track_mapper.dart';
import 'package:in_phase/src/library/engine/blobs/beat_data.dart';
import 'package:in_phase/src/library/engine/blobs/loops.dart';
import 'package:in_phase/src/library/engine/blobs/quick_cues.dart';
import 'package:in_phase/src/library/engine/blobs/track_data.dart';
import 'package:in_phase/src/library/engine/engine_album_art.dart';
import 'package:in_phase/src/library/engine/engine_database.dart';
import 'package:in_phase/src/library/rekordbox/rekordbox_artwork.dart';
import 'package:in_phase/src/library/rekordbox/rekordbox_models.dart';
import 'package:in_phase/src/library/rekordbox/rekordbox_reader.dart';
import 'package:in_phase/src/logger/logger.dart';
import 'package:in_phase/src/misc/misc.dart';

/// Outcome counts of an Engine sync (or dry run).
class EngineSyncResult {
  int tracksAdded = 0;
  int tracksUpdated = 0;
  int tracksUnchanged = 0;
  int tracksPruned = 0;
  int tracksSkipped = 0;

  /// Rekordbox tracks that have an ANLZ beat grid (source count, not writes).
  int tracksWithBeatGrid = 0;

  /// Beat grids written this run (new or rewritten tracks only).
  int beatGridsWritten = 0;

  /// Source tracks with a resolvable Rekordbox artwork file.
  int tracksWithArtwork = 0;

  /// Artwork rows/files written this run.
  int artworkWritten = 0;

  int playlistsSynced = 0;
  int foldersSynced = 0;
  int playlistEntries = 0;
  bool playlistsPruned = false;
}

/// Performs (or simulates, when [dryRun] is set) a one-way sync of
/// [library] into the Engine database [engineDb].
///
/// Tracks are matched by `pdbImportKey` (the Rekordbox content ID), falling
/// back to the audio file path. When [prune] is set, Engine tracks whose
/// Rekordbox source disappeared are deleted and the playlist tree is rebuilt
/// as an exact mirror; otherwise unknown Engine tracks/playlists are left
/// untouched.
Future<EngineSyncResult> runEngineSync({
  required RekordboxLibrary library,
  required EngineDatabase engineDb,
  required String engineLibraryPath,
  required String rekordboxShareRoot,
  required bool dryRun,
  required bool prune,
  required bool memoryCuesToHotCues,
  required bool syncArt,
}) async {
  final result = EngineSyncResult();
  final artworkHashByPath = <String, String?>{};

  String? artworkHashFor(RekordboxTrack track) {
    final path = track.artworkRelativePath;
    if (path == null) return null;
    return artworkHashByPath.putIfAbsent(
      path,
      () => rekordboxArtworkSourceHash(rekordboxShareRoot, path),
    );
  }

  // Convert all Rekordbox tracks, de-duplicating on target path (Engine has
  // a UNIQUE constraint on Track.path).
  final records = <EngineTrackRecord>[];
  final tracksByRekordboxId = <int, RekordboxTrack>{};
  final seenPaths = <String>{};
  for (final track in library.tracks) {
    final artHash = syncArt ? artworkHashFor(track) : null;
    if (artHash != null) result.tracksWithArtwork++;

    final record = mapTrackToEngine(
      track,
      engineLibraryPath: engineLibraryPath,
      rekordboxShareRoot: rekordboxShareRoot,
      memoryCuesToHotCues: memoryCuesToHotCues,
      syncArt: syncArt,
      artworkSourceHash: artHash,
    );
    tracksByRekordboxId[record.rekordboxId] = track;
    if (!seenPaths.add(record.path)) {
      log.warning(
        'Skipping duplicate audio file path: ${track.audioFilePath} '
        '(track "${track.title}")',
      );
      result.tracksSkipped++;
      continue;
    }
    if (record.hasBeatGrid) result.tracksWithBeatGrid++;
    records.add(record);
  }

  final existing = engineDb.readTracks();
  final byImportKey = <int, EngineTrackRow>{
    for (final row in existing)
      if (row.pdbImportKey != null) row.pdbImportKey!: row,
  };
  final byPath = <String, EngineTrackRow>{
    for (final row in existing)
      if (row.path != null) row.path!: row,
  };

  final engineIdByRekordboxId = <int, int>{};
  final toInsert = <EngineTrackRecord>[];
  final toUpdate = <(int, EngineTrackRecord)>[];
  final matchedEngineIds = <int>{};

  for (final record in records) {
    final match = byImportKey[record.rekordboxId] ?? byPath[record.path];
    if (match == null) {
      toInsert.add(record);
      continue;
    }
    matchedEngineIds.add(match.id);
    engineIdByRekordboxId[record.rekordboxId] = match.id;
    if (_trackNeedsUpdate(
      match,
      record,
      engineDb,
      syncArt: syncArt,
    )) {
      toUpdate.add((match.id, record));
      result.tracksUpdated++;
    } else {
      result.tracksUnchanged++;
    }
  }
  result
    ..tracksAdded = toInsert.length
    ..beatGridsWritten =
        toInsert.where((r) => r.hasBeatGrid).length +
        toUpdate.where((e) => e.$2.hasBeatGrid).length;

  final toPrune = prune
      ? existing.where((row) => !matchedEngineIds.contains(row.id)).toList()
      : const <EngineTrackRow>[];
  result
    ..tracksPruned = toPrune.length
    ..playlistsPruned = prune;

  void countPlaylists(List<RekordboxPlaylistNode> nodes) {
    for (final node in nodes) {
      if (node.isFolder) {
        result.foldersSynced++;
        countPlaylists(node.children);
      } else {
        result.playlistsSynced++;
        result.playlistEntries += node.trackIds.length;
      }
    }
  }

  countPlaylists(library.playlistTree);

  if (dryRun) {
    if (syncArt) {
      final registry = EngineAlbumArtRegistry(
        db: engineDb,
        engineLibraryPath: engineLibraryPath,
        writeExternalArtwork: engineDb.supportsExternalAlbumArt,
      );
      result.artworkWritten = _artworkToImport(
        toInsert: toInsert,
        toUpdate: toUpdate,
        tracksByRekordboxId: tracksByRekordboxId,
        registry: registry,
      ).length;
    }
    return result;
  }

  final artRegistry = syncArt
      ? EngineAlbumArtRegistry(
          db: engineDb,
          engineLibraryPath: engineLibraryPath,
          writeExternalArtwork: engineDb.supportsExternalAlbumArt,
        )
      : null;

  if (syncArt) {
    artRegistry!.ensurePlaceholder();
    final toImport = _artworkToImport(
      toInsert: toInsert,
      toUpdate: toUpdate,
      tracksByRekordboxId: tracksByRekordboxId,
      registry: artRegistry,
    );

    if (toImport.isNotEmpty) {
      await withSpinner('Importing artwork...', (session) async {
        var done = 0;
        final total = toImport.length;
        for (final entry in toImport.entries) {
          artRegistry.importArtwork(
            shareRoot: rekordboxShareRoot,
            artworkRelativePath: entry.value,
            hash: entry.key,
          );
          done++;
          session.updateMessage('[$done/$total] Importing artwork...');
        }
      });
    }
    result.artworkWritten = artRegistry.rowsInserted;
  }

  engineDb.runInTransaction(() {
    EngineTrackRecord prepare(EngineTrackRecord record) {
      if (!syncArt) return record;
      final artId = artRegistry!.albumArtIdForHash(record.artworkSourceHash);
      return record.withAlbumArtId(artId);
    }

    for (final record in toInsert) {
      final trackId = engineDb.insertTrack(
        prepare(record),
        syncArt: syncArt,
      );
      engineIdByRekordboxId[record.rekordboxId] = trackId;
    }
    for (final (trackId, record) in toUpdate) {
      engineDb.updateTrack(
        trackId,
        prepare(record),
        syncArt: syncArt,
      );
    }
    for (final row in toPrune) {
      engineDb.deleteTrack(row.id);
    }

    _syncPlaylists(
      engineDb: engineDb,
      tree: library.playlistTree,
      engineIdByRekordboxId: engineIdByRekordboxId,
      prune: prune,
    );
  });

  return result;
}

/// Unique Rekordbox artwork hashes that still need importing into Engine.
Map<String, String> _artworkToImport({
  required List<EngineTrackRecord> toInsert,
  required List<(int, EngineTrackRecord)> toUpdate,
  required Map<int, RekordboxTrack> tracksByRekordboxId,
  required EngineAlbumArtRegistry registry,
}) {
  final unique = <String, String>{};

  void consider(EngineTrackRecord record) {
    final hash = record.artworkSourceHash;
    if (hash == null || hash.isEmpty || registry.containsHash(hash)) {
      return;
    }
    final path = tracksByRekordboxId[record.rekordboxId]?.artworkRelativePath;
    if (path == null) return;
    unique.putIfAbsent(hash, () => path);
  }

  toInsert.forEach(consider);
  toUpdate.map((e) => e.$2).forEach(consider);

  return unique;
}

/// Whether the Engine row differs from the desired [record], comparing
/// metadata columns and decoded performance-data blobs.
///
/// Blobs are compared semantically rather than byte-wise so that data Engine
/// adds during its own analysis (e.g. loudness in `trackData`) does not
/// cause endless rewrites.
bool _trackNeedsUpdate(
  EngineTrackRow row,
  EngineTrackRecord record,
  EngineDatabase engineDb, {
  required bool syncArt,
}) {
  final desired = EngineDatabase.trackColumnValues(
    record,
    supportsExternalAlbumArt: engineDb.supportsExternalAlbumArt,
    syncArt: syncArt,
  );
  for (final entry in desired.entries) {
    final current = row.columns[entry.key];
    final target = entry.value;
    // SQLite may return ints for REAL columns and vice versa.
    if (current is num && target is num) {
      if (current.toDouble() != target.toDouble()) return true;
    } else if (current != target) {
      return true;
    }
  }

  try {
    final currentBeatData = row.beatData != null
        ? EngineBeatData.fromBlob(row.beatData!)
        : null;
    final desiredBeatData = EngineBeatData.fromBlob(record.beatData);
    if (currentBeatData == null ||
        currentBeatData.sampleRate != desiredBeatData.sampleRate ||
        currentBeatData.samples != desiredBeatData.samples ||
        !const ListEquality<EngineBeatGridMarker>().equals(
          currentBeatData.defaultBeatGrid,
          desiredBeatData.defaultBeatGrid,
        )) {
      return true;
    }

    final currentQuickCues = row.quickCues != null
        ? EngineQuickCues.fromBlob(row.quickCues!)
        : null;
    final desiredQuickCues = EngineQuickCues.fromBlob(record.quickCues);
    if (currentQuickCues == null ||
        currentQuickCues.adjustedMainCue != desiredQuickCues.adjustedMainCue ||
        !const ListEquality<EngineQuickCue>().equals(
          currentQuickCues.quickCues,
          desiredQuickCues.quickCues,
        )) {
      return true;
    }

    final currentLoops = row.loops != null
        ? EngineLoops.fromBlob(row.loops!)
        : null;
    final desiredLoops = EngineLoops.fromBlob(record.loops);
    if (currentLoops == null ||
        !const ListEquality<EngineLoop>().equals(
          currentLoops.loops,
          desiredLoops.loops,
        )) {
      return true;
    }

    // trackData: only sample rate, samples, and key are synced; loudness is
    // Engine's own analysis output and intentionally ignored.
    final currentTrackData = row.trackData != null
        ? EngineTrackData.fromBlob(row.trackData!)
        : null;
    final desiredTrackData = EngineTrackData.fromBlob(record.trackData);
    if (currentTrackData == null ||
        currentTrackData.sampleRate != desiredTrackData.sampleRate ||
        currentTrackData.samples != desiredTrackData.samples ||
        currentTrackData.key != desiredTrackData.key) {
      return true;
    }
  } on Exception {
    // Unparseable existing blobs: rewrite them.
    return true;
  }

  return false;
}

void _syncPlaylists({
  required EngineDatabase engineDb,
  required List<RekordboxPlaylistNode> tree,
  required Map<int, int> engineIdByRekordboxId,
  required bool prune,
}) {
  if (prune) {
    // Mirror semantics: rebuild the entire tree so ordering and structure
    // match Rekordbox exactly.
    engineDb.deleteAllPlaylists();
  }

  void syncNodes(List<RekordboxPlaylistNode> nodes, int parentListId) {
    for (final node in nodes) {
      // After a prune the tree is empty, so lookups only matter when
      // pruning is disabled and existing playlists must be reused.
      final listId =
          engineDb.findPlaylist(
            title: node.name,
            parentListId: parentListId,
          ) ??
          engineDb.insertPlaylist(
            title: node.name,
            parentListId: parentListId,
          );
      if (node.isFolder) {
        syncNodes(node.children, listId);
      } else {
        // Engine forbids duplicate tracks within a playlist (unlike
        // Rekordbox), so only the first occurrence is kept.
        final trackIds = <int>{
          for (final rekordboxId in node.trackIds)
            ?engineIdByRekordboxId[int.parse(rekordboxId)],
        };
        engineDb.replacePlaylistEntities(listId, trackIds.toList());
      }
    }
  }

  syncNodes(tree, 0);
}
