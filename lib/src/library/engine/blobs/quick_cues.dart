import 'dart:typed_data';

import 'package:in_phase/src/library/engine/blobs/byte_codec.dart';
import 'package:in_phase/src/library/engine/blobs/qcompress.dart';
import 'package:meta/meta.dart';

/// An ARGB pad color as stored in Engine DJ performance-data blobs.
@immutable
class EnginePadColor {
  const EnginePadColor(this.a, this.r, this.g, this.b);

  const EnginePadColor.none() : this(0, 0, 0, 0);

  final int a;
  final int r;
  final int g;
  final int b;

  @override
  bool operator ==(Object other) =>
      other is EnginePadColor &&
      other.a == a &&
      other.r == r &&
      other.g == g &&
      other.b == b;

  @override
  int get hashCode => Object.hash(a, r, g, b);
}

/// A single hot cue slot in the `quickCues` blob.
///
/// An unset slot has an empty label, a sample offset of -1 and a fully zero
/// color, matching libdjinterop's `quick_cue_blob::empty()`.
@immutable
class EngineQuickCue {
  const EngineQuickCue({
    required this.label,
    required this.sampleOffset,
    required this.color,
  });

  const EngineQuickCue.empty()
    : this(label: '', sampleOffset: -1, color: const EnginePadColor.none());

  final String label;
  final double sampleOffset;
  final EnginePadColor color;

  bool get isSet => sampleOffset != -1;

  @override
  bool operator ==(Object other) =>
      other is EngineQuickCue &&
      other.label == label &&
      other.sampleOffset == sampleOffset &&
      other.color == color;

  @override
  int get hashCode => Object.hash(label, sampleOffset, color);
}

/// The `PerformanceData.quickCues` blob: eight hot cue slots plus the main
/// cue position. qCompress-framed; all multi-byte fields are big-endian.
@immutable
class EngineQuickCues {
  EngineQuickCues({
    required this.quickCues,
    required this.adjustedMainCue,
    required this.isMainCueAdjusted,
    required this.defaultMainCue,
  }) {
    if (quickCues.length != slotCount) {
      throw ArgumentError.value(
        quickCues.length,
        'quickCues',
        'Expected exactly $slotCount quick cue slots',
      );
    }
  }

  factory EngineQuickCues.fromBlob(Uint8List blob) {
    final raw = qUncompress(blob);
    if (raw.length < 25) {
      throw const FormatException(
        'Quick cues data has less than the minimum length of 25 bytes',
      );
    }

    final reader = ByteReader(raw);
    final count = reader.i64be();
    final cues = List.generate(count, (_) {
      final label = reader.label();
      final sampleOffset = reader.f64be();
      final a = reader.u8();
      final r = reader.u8();
      final g = reader.u8();
      final b = reader.u8();
      return EngineQuickCue(
        label: label,
        sampleOffset: sampleOffset,
        color: EnginePadColor(a, r, g, b),
      );
    });
    return EngineQuickCues(
      quickCues: cues,
      adjustedMainCue: reader.f64be(),
      isMainCueAdjusted: reader.u8() != 0,
      defaultMainCue: reader.f64be(),
    );
  }

  static const int slotCount = 8;

  final List<EngineQuickCue> quickCues;
  final double adjustedMainCue;
  final bool isMainCueAdjusted;
  final double defaultMainCue;

  Uint8List toBlob() {
    final writer = ByteWriter()..i64be(quickCues.length);
    for (final cue in quickCues) {
      writer
        ..label(cue.label)
        ..f64be(cue.sampleOffset)
        ..u8(cue.color.a)
        ..u8(cue.color.r)
        ..u8(cue.color.g)
        ..u8(cue.color.b);
    }
    writer
      ..f64be(adjustedMainCue)
      ..u8(isMainCueAdjusted ? 1 : 0)
      ..f64be(defaultMainCue);
    return qCompress(writer.takeBytes());
  }
}
