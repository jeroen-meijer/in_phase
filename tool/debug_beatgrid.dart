import 'dart:io';

import 'package:in_phase/src/library/library.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:path/path.dart' as p;
import 'package:rekorddart/rekorddart.dart';

Future<void> main(List<String> args) async {
  final titles = args.isEmpty
      ? [
          'Get Funky - Final Mix & Master',
          'Bad Boy Horns',
          'Twerp',
          'Hoover Dub',
        ]
      : args;

  final config = getMostRecentRekordboxConfig()!;
  final share = p.join(config.dbDir, 'share');
  final db = await RekordboxDatabase.connect();

  for (final title in titles) {
    final rows = await (db.select(db.djmdContent)
          ..where((c) => c.title.equals(title)))
        .get();
    if (rows.isEmpty) {
      print('NOT FOUND: $title');
      continue;
    }
    final row = rows.first;
    final path = rekordboxAudioPath(row);
    final anlzPath = row.analysisDataPath == null
        ? null
        : p.join(share, row.analysisDataPath!.replaceFirst(RegExp('^/'), ''));
    print('\n=== $title ===');
    print('file: $path');
    print('sampleRate: ${row.sampleRate} length: ${row.length}s');
    if (anlzPath == null) {
      print('no ANLZ path');
      continue;
    }
    final beats = await readAnlzBeatGrid(anlzPath);
    if (beats == null || beats.isEmpty) {
      print('no PQTZ beats');
      continue;
    }
    print('first 8 PQTZ beats:');
    for (var i = 0; i < 8 && i < beats.length; i++) {
      final b = beats[i];
      print(
        '  [$i] inBar=${b.beatNumberInBar} tempo=${b.tempoCentiBpm} '
        'timeMs=${b.timeMs}',
      );
    }
    final firstDown = beats.indexWhere((b) => b.beatNumberInBar == 1);
    print('first downbeat index: $firstDown');
    if (firstDown >= 0) {
      print(
        '  timeMs=${beats[firstDown].timeMs} '
        'samples@44100=${beats[firstDown].timeMs * 44100 / 1000}',
      );
    }
    final sr = (row.sampleRate ?? 44100).toDouble();
    final sampleCount = (row.length ?? 0) * sr.round();
    final markers = mapBeatGridToEngine(
      beats: beats,
      sampleRate: sr,
      sampleCount: sampleCount,
    );
    print('Engine markers (first 3):');
    for (var i = 0; i < 3 && markers != null && i < markers.length; i++) {
      final m = markers[i];
      print(
        '  beatNumber=${m.beatNumber} offset=${m.sampleOffset.toStringAsFixed(1)} '
        'beatsToNext=${m.numberOfBeats}',
      );
    }
    final cues = await (db.select(db.djmdCue)
          ..where((c) => c.contentID.equals(row.id!)))
        .get();
    print('hot cues (first 3):');
    for (final cue in cues.take(3)) {
      print(
        '  kind=${cue.kind} inMsec=${cue.inMsec} inFrame=${cue.inFrame} '
        'inMpegAbs=${cue.inMpegAbs} '
        'samplesFromMsec=${(cue.inMsec ?? 0) * sr / 1000}',
      );
    }
  }

  await db.close();
}
