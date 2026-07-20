import 'dart:typed_data';

import 'package:in_phase/src/library/engine/blobs/byte_codec.dart';
import 'package:in_phase/src/library/engine/blobs/qcompress.dart';
import 'package:meta/meta.dart';

/// The `PerformanceData.trackData` blob: sample rate, track length in
/// samples, musical key, and per-band average loudness.
///
/// qCompress-framed; all fields are big-endian. Loudness values are left at
/// zero since Engine DJ recomputes them during its own analysis.
@immutable
class EngineTrackData {
  const EngineTrackData({
    required this.sampleRate,
    required this.samples,
    required this.key,
    this.averageLoudnessLow = 0,
    this.averageLoudnessMid = 0,
    this.averageLoudnessHigh = 0,
  });

  factory EngineTrackData.fromBlob(Uint8List blob) {
    final raw = qUncompress(blob);
    if (raw.length < 44) {
      throw const FormatException(
        'Track data blob does not have the expected length of 44 bytes',
      );
    }

    final reader = ByteReader(raw);
    return EngineTrackData(
      sampleRate: reader.f64be(),
      samples: reader.i64be(),
      key: reader.i32be(),
      averageLoudnessLow: reader.f64be(),
      averageLoudnessMid: reader.f64be(),
      averageLoudnessHigh: reader.f64be(),
    );
  }

  final double sampleRate;
  final int samples;

  /// Engine key integer 0-23, see `EngineKey`.
  final int key;

  final double averageLoudnessLow;
  final double averageLoudnessMid;
  final double averageLoudnessHigh;

  Uint8List toBlob() {
    final writer = ByteWriter()
      ..f64be(sampleRate)
      ..i64be(samples)
      ..i32be(key)
      ..f64be(averageLoudnessLow)
      ..f64be(averageLoudnessMid)
      ..f64be(averageLoudnessHigh);
    return qCompress(writer.takeBytes());
  }
}
