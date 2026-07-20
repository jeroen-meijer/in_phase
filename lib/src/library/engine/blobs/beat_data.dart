import 'dart:typed_data';

import 'package:in_phase/src/library/engine/blobs/byte_codec.dart';
import 'package:in_phase/src/library/engine/blobs/qcompress.dart';
import 'package:meta/meta.dart';

/// A single marker in an Engine DJ beat grid.
///
/// Layout per marker (little-endian, 24 bytes): sample offset (f64), beat
/// number (i64), number of beats until the next marker (i32), and an unknown
/// value (i32, always zero).
@immutable
class EngineBeatGridMarker {
  const EngineBeatGridMarker({
    required this.sampleOffset,
    required this.beatNumber,
    required this.numberOfBeats,
  });

  final double sampleOffset;
  final int beatNumber;
  final int numberOfBeats;

  @override
  bool operator ==(Object other) =>
      other is EngineBeatGridMarker &&
      other.sampleOffset == sampleOffset &&
      other.beatNumber == beatNumber &&
      other.numberOfBeats == numberOfBeats;

  @override
  int get hashCode => Object.hash(sampleOffset, beatNumber, numberOfBeats);

  @override
  String toString() =>
      'EngineBeatGridMarker(offset: $sampleOffset, beat: $beatNumber, '
      'beats: $numberOfBeats)';
}

/// The `PerformanceData.beatData` blob: sample rate, track length in samples,
/// and default/adjusted beat grids.
///
/// The blob is qCompress-framed. The header (sample rate, samples, is-set
/// flag, grid marker counts) is big-endian, while individual markers are
/// little-endian, per libdjinterop's `beat_data_blob.cpp`.
@immutable
class EngineBeatData {
  const EngineBeatData({
    required this.sampleRate,
    required this.samples,
    required this.defaultBeatGrid,
    required this.adjustedBeatGrid,
  });

  factory EngineBeatData.fromBlob(Uint8List blob) {
    final raw = qUncompress(blob);
    if (raw.length < 33) {
      throw const FormatException(
        'Beat data has less than the minimum length of 33 bytes',
      );
    }

    final reader = ByteReader(raw);
    final sampleRate = reader.f64be();
    final samples = reader.f64be();
    reader.u8(); // is_beatgrid_set, implied by grid contents.
    return EngineBeatData(
      sampleRate: sampleRate,
      samples: samples,
      defaultBeatGrid: _readGrid(reader),
      adjustedBeatGrid: _readGrid(reader),
    );
  }

  final double sampleRate;
  final double samples;
  final List<EngineBeatGridMarker> defaultBeatGrid;
  final List<EngineBeatGridMarker> adjustedBeatGrid;

  bool get isBeatGridSet =>
      defaultBeatGrid.isNotEmpty && adjustedBeatGrid.isNotEmpty;

  Uint8List toBlob() {
    final writer = ByteWriter()
      ..f64be(sampleRate)
      ..f64be(samples)
      ..u8(isBeatGridSet ? 1 : 0);
    _writeGrid(writer, defaultBeatGrid);
    _writeGrid(writer, adjustedBeatGrid);
    return qCompress(writer.takeBytes());
  }

  static void _writeGrid(ByteWriter writer, List<EngineBeatGridMarker> grid) {
    writer.i64be(grid.length);
    for (final marker in grid) {
      writer
        ..f64le(marker.sampleOffset)
        ..i64le(marker.beatNumber)
        ..i32le(marker.numberOfBeats)
        ..i32le(0);
    }
  }

  static List<EngineBeatGridMarker> _readGrid(ByteReader reader) {
    final count = reader.i64be();
    return List.generate(count, (_) {
      final sampleOffset = reader.f64le();
      final beatNumber = reader.i64le();
      final numberOfBeats = reader.i32le();
      reader.i32le(); // Unknown value, always zero.
      return EngineBeatGridMarker(
        sampleOffset: sampleOffset,
        beatNumber: beatNumber,
        numberOfBeats: numberOfBeats,
      );
    });
  }
}
