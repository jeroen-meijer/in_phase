import 'dart:typed_data';

import 'package:in_phase/src/library/library.dart';
import 'package:test/test.dart';

/// Builds a minimal ANLZ .DAT file containing the given PQTZ beats.
Uint8List buildAnlzFile(List<AnlzBeat> beats, {bool includeGrid = true}) {
  const fileHeaderLength = 28;
  final builder = BytesBuilder();

  Uint8List u32(int v) => Uint8List(4)..buffer.asByteData().setUint32(0, v);
  Uint8List u16(int v) => Uint8List(2)..buffer.asByteData().setUint16(0, v);

  // An unrelated section before the beat grid, to exercise section walking.
  final pathSection = BytesBuilder()
    ..add('PPTH'.codeUnits)
    ..add(u32(16))
    ..add(u32(20))
    ..add(u32(0))
    ..add(u32(0));

  final gridSection = BytesBuilder();
  if (includeGrid) {
    gridSection
      ..add('PQTZ'.codeUnits)
      ..add(u32(24))
      ..add(u32(24 + beats.length * 8))
      ..add(u32(0x01000002))
      ..add(u32(0x00800000))
      ..add(u32(beats.length));
    for (final beat in beats) {
      gridSection
        ..add(u16(beat.beatNumberInBar))
        ..add(u16(beat.tempoCentiBpm))
        ..add(u32(beat.timeMs));
    }
  }

  final fileLength = fileHeaderLength + pathSection.length + gridSection.length;
  builder
    ..add('PMAI'.codeUnits)
    ..add(u32(fileHeaderLength))
    ..add(u32(fileLength))
    ..add(Uint8List(fileHeaderLength - 12))
    ..add(pathSection.takeBytes())
    ..add(gridSection.takeBytes());
  return builder.takeBytes();
}

void main() {
  group('parseAnlzBeatGrid', () {
    test('parses beats from a PQTZ section', () {
      const beats = [
        AnlzBeat(beatNumberInBar: 1, tempoCentiBpm: 12800, timeMs: 100),
        AnlzBeat(beatNumberInBar: 2, tempoCentiBpm: 12800, timeMs: 568),
        AnlzBeat(beatNumberInBar: 3, tempoCentiBpm: 12800, timeMs: 1037),
      ];

      expect(parseAnlzBeatGrid(buildAnlzFile(beats)), beats);
    });

    test('returns null when there is no PQTZ section', () {
      expect(
        parseAnlzBeatGrid(buildAnlzFile(const [], includeGrid: false)),
        isNull,
      );
    });

    test('returns null for a non-ANLZ file', () {
      expect(parseAnlzBeatGrid(Uint8List.fromList([1, 2, 3, 4])), isNull);
    });
  });
}
