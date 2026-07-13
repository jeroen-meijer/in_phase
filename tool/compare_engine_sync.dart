import 'dart:io';

import 'package:collection/collection.dart';
import 'package:in_phase/src/library/library.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:path/path.dart' as p;
import 'package:rekorddart/rekorddart.dart';

bool blobsDiffer(EngineTrackRow row, EngineTrackRecord record) {
  final desiredBeat = EngineBeatData.fromBlob(record.beatData);
  final storedBeat = EngineBeatData.fromBlob(row.beatData!);
  if (!const ListEquality<EngineBeatGridMarker>().equals(
    storedBeat.defaultBeatGrid,
    desiredBeat.defaultBeatGrid,
  )) {
    return true;
  }
  final desiredQc = EngineQuickCues.fromBlob(record.quickCues);
  final storedQc = EngineQuickCues.fromBlob(row.quickCues!);
  if (!const ListEquality<EngineQuickCue>().equals(
    storedQc.quickCues,
    desiredQc.quickCues,
  )) {
    return true;
  }
  return false;
}

Future<void> main(List<String> args) async {
  final titles = args.isEmpty
      ? ['Get Funky - Final Mix & Master', 'Bad Boy Horns']
      : args;

  final config = getMostRecentRekordboxConfig()!;
  final share = p.join(config.dbDir, 'share');
  final rbDb = await RekordboxDatabase.connect();
  final rb = await readRekordboxLibrary(rbDb, anlzRootPath: share);
  await rbDb.close();

  final enginePath = p.join(
    Platform.environment['HOME']!,
    'Music',
    'Engine Library',
  );
  final engineDb = EngineDatabase.open(
    engineDatabasePath(enginePath),
    readOnly: true,
  );
  final existing = {
    for (final row in engineDb.readTracks())
      row.columns['title'] as String: row,
  };
  engineDb.close();

  for (final track in rb.tracks) {
    if (!titles.contains(track.title)) continue;

    final row = existing[track.title];
    if (row == null) {
      print('NOT IN ENGINE: ${track.title}');
      continue;
    }

    final record = mapTrackToEngine(
      track,
      engineLibraryPath: enginePath,
      rekordboxShareRoot: share,
    );
    final update = blobsDiffer(row, record);

    print('\n=== ${track.title} ===');
    print('blobsDiffer: $update');

    final stored = EngineBeatData.fromBlob(row.beatData!);
    final desired = EngineBeatData.fromBlob(record.beatData);
    print(
      'stored beat[0]: ${stored.defaultBeatGrid.first.beatNumber} '
      '@ ${stored.defaultBeatGrid.first.sampleOffset}',
    );
    print(
      'desired beat[0]: ${desired.defaultBeatGrid.first.beatNumber} '
      '@ ${desired.defaultBeatGrid.first.sampleOffset}',
    );

    if (row.quickCues != null && record.quickCues.isNotEmpty) {
      final sq = EngineQuickCues.fromBlob(row.quickCues!);
      final dq = EngineQuickCues.fromBlob(record.quickCues);
      print('stored cue A: ${sq.quickCues[0].sampleOffset}');
      print('desired cue A: ${dq.quickCues[0].sampleOffset}');
    }
  }

  final engineDb2 = EngineDatabase.open(
    engineDatabasePath(enginePath),
    readOnly: true,
  );
  final allRows = engineDb2.readTracks();
  engineDb2.close();

  final byKey = {
    for (final row in allRows)
      if (row.pdbImportKey != null) row.pdbImportKey!: row,
  };

  var totalUpdate = 0;
  var totalUnchanged = 0;
  for (final track in rb.tracks) {
    final id = int.tryParse(track.id);
    final row = id != null ? byKey[id] : null;
    if (row == null) continue;
    final record = mapTrackToEngine(
      track,
      engineLibraryPath: enginePath,
      rekordboxShareRoot: share,
    );
    if (blobsDiffer(row, record)) {
      totalUpdate++;
    } else {
      totalUnchanged++;
    }
  }
  print('\nFull library blob diff: $totalUpdate differ, $totalUnchanged same');
}
