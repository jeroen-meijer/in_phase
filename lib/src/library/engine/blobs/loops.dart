import 'dart:typed_data';

import 'package:in_phase/src/library/engine/blobs/byte_codec.dart';
import 'package:in_phase/src/library/engine/blobs/quick_cues.dart';
import 'package:meta/meta.dart';

/// A single loop slot in the `loops` blob.
///
/// An unset slot has an empty label, offsets of -1, cleared start/end flags,
/// and a fully zero color, matching libdjinterop's `loop_blob::empty()`.
@immutable
class EngineLoop {
  const EngineLoop({
    required this.label,
    required this.startSampleOffset,
    required this.endSampleOffset,
    required this.isStartSet,
    required this.isEndSet,
    required this.color,
  });

  const EngineLoop.empty()
    : this(
        label: '',
        startSampleOffset: -1,
        endSampleOffset: -1,
        isStartSet: false,
        isEndSet: false,
        color: const EnginePadColor.none(),
      );

  final String label;
  final double startSampleOffset;
  final double endSampleOffset;
  final bool isStartSet;
  final bool isEndSet;
  final EnginePadColor color;

  bool get isSet => isStartSet || isEndSet;

  @override
  bool operator ==(Object other) =>
      other is EngineLoop &&
      other.label == label &&
      other.startSampleOffset == startSampleOffset &&
      other.endSampleOffset == endSampleOffset &&
      other.isStartSet == isStartSet &&
      other.isEndSet == isEndSet &&
      other.color == color;

  @override
  int get hashCode => Object.hash(
    label,
    startSampleOffset,
    endSampleOffset,
    isStartSet,
    isEndSet,
    color,
  );
}

/// The `PerformanceData.loops` blob: eight loop slots.
///
/// Unlike the other performance-data blobs, this one is NOT compressed, and
/// its multi-byte fields are little-endian.
@immutable
class EngineLoops {
  EngineLoops({required this.loops}) {
    if (loops.length != slotCount) {
      throw ArgumentError.value(
        loops.length,
        'loops',
        'Expected exactly $slotCount loop slots',
      );
    }
  }

  factory EngineLoops.fromBlob(Uint8List blob) {
    if (blob.length < 8) {
      throw const FormatException(
        'Loops data has less than the minimum length of 8 bytes',
      );
    }

    final reader = ByteReader(blob);
    final count = reader.i64le();
    final loops = List.generate(count, (_) {
      final label = reader.label();
      final start = reader.f64le();
      final end = reader.f64le();
      final isStartSet = reader.u8() != 0;
      final isEndSet = reader.u8() != 0;
      final a = reader.u8();
      final r = reader.u8();
      final g = reader.u8();
      final b = reader.u8();
      return EngineLoop(
        label: label,
        startSampleOffset: start,
        endSampleOffset: end,
        isStartSet: isStartSet,
        isEndSet: isEndSet,
        color: EnginePadColor(a, r, g, b),
      );
    });
    return EngineLoops(loops: loops);
  }

  static const int slotCount = 8;

  final List<EngineLoop> loops;

  Uint8List toBlob() {
    final writer = ByteWriter()..i64le(loops.length);
    for (final loop in loops) {
      writer
        ..label(loop.label)
        ..f64le(loop.startSampleOffset)
        ..f64le(loop.endSampleOffset)
        ..u8(loop.isStartSet ? 1 : 0)
        ..u8(loop.isEndSet ? 1 : 0)
        ..u8(loop.color.a)
        ..u8(loop.color.r)
        ..u8(loop.color.g)
        ..u8(loop.color.b);
    }
    return writer.takeBytes();
  }
}
