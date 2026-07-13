import 'dart:io';
import 'dart:typed_data';

import 'package:meta/meta.dart';

/// A single beat from a Rekordbox ANLZ `PQTZ` beat grid tag.
@immutable
class AnlzBeat {
  const AnlzBeat({
    required this.beatNumberInBar,
    required this.tempoCentiBpm,
    required this.timeMs,
  });

  /// Position within the bar, 1-4.
  final int beatNumberInBar;

  /// Tempo at this beat as BPM * 100.
  final int tempoCentiBpm;

  /// Time of this beat in milliseconds from the start of the track.
  final int timeMs;

  @override
  bool operator ==(Object other) =>
      other is AnlzBeat &&
      other.beatNumberInBar == beatNumberInBar &&
      other.tempoCentiBpm == tempoCentiBpm &&
      other.timeMs == timeMs;

  @override
  int get hashCode => Object.hash(beatNumberInBar, tempoCentiBpm, timeMs);
}

/// Parses the `PQTZ` beat grid from a Rekordbox ANLZ `.DAT` file.
///
/// ANLZ files start with a `PMAI` header followed by tagged sections. All
/// values are big-endian. The `PQTZ` section contains one 8-byte entry per
/// beat: beat number within the bar (u16), tempo as BPM * 100 (u16), and time
/// in ms (u32). See the Deep Symmetry rekordbox analysis file documentation.
///
/// Returns null if the file has no `PQTZ` section or contains no beats.
List<AnlzBeat>? parseAnlzBeatGrid(Uint8List bytes) {
  if (bytes.length < 12) return null;

  final data = ByteData.sublistView(bytes);
  if (_fourcc(data, 0) != 'PMAI') return null;

  final headerLength = data.getUint32(4);
  final fileLength = data.getUint32(8);
  final end = fileLength <= bytes.length ? fileLength : bytes.length;

  var offset = headerLength;
  while (offset + 12 <= end) {
    final tag = _fourcc(data, offset);
    final tagHeaderLength = data.getUint32(offset + 4);
    final tagLength = data.getUint32(offset + 8);
    if (tagLength < 12 || offset + tagLength > end) break;

    if (tag == 'PQTZ') {
      final beatCount = data.getUint32(offset + 20);
      final beatsStart = offset + tagHeaderLength;
      if (beatsStart + beatCount * 8 > offset + tagLength) return null;

      final beats = List.generate(beatCount, (i) {
        final beatOffset = beatsStart + i * 8;
        return AnlzBeat(
          beatNumberInBar: data.getUint16(beatOffset),
          tempoCentiBpm: data.getUint16(beatOffset + 2),
          timeMs: data.getUint32(beatOffset + 4),
        );
      });
      return beats.isEmpty ? null : beats;
    }

    offset += tagLength;
  }

  return null;
}

/// Reads and parses the beat grid from an ANLZ file at [path].
///
/// Returns null if the file does not exist or contains no beat grid.
Future<List<AnlzBeat>?> readAnlzBeatGrid(String path) async {
  final file = File(path);
  // ignore: avoid_slow_async_io
  if (!await file.exists()) return null;
  return parseAnlzBeatGrid(await file.readAsBytes());
}

String _fourcc(ByteData data, int offset) => String.fromCharCodes([
  data.getUint8(offset),
  data.getUint8(offset + 1),
  data.getUint8(offset + 2),
  data.getUint8(offset + 3),
]);
