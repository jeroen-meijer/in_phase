import 'package:in_phase/src/library/convert/audio_timing.dart';
import 'package:in_phase/src/library/engine/blobs/loops.dart';
import 'package:in_phase/src/library/engine/blobs/quick_cues.dart';
import 'package:in_phase/src/library/rekordbox/rekordbox_models.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:meta/meta.dart';

/// Engine DJ's standard pad colors for hot cue slots 1-8.
const List<EnginePadColor> engineHotCueSlotColors = [
  EnginePadColor(0xFF, 0xEA, 0xC5, 0x32),
  EnginePadColor(0xFF, 0xEA, 0x8F, 0x32),
  EnginePadColor(0xFF, 0xB8, 0x55, 0xBF),
  EnginePadColor(0xFF, 0xBA, 0x2A, 0x41),
  EnginePadColor(0xFF, 0x86, 0xC6, 0x4B),
  EnginePadColor(0xFF, 0x20, 0xC6, 0x7C),
  EnginePadColor(0xFF, 0x00, 0xA8, 0xB1),
  EnginePadColor(0xFF, 0x15, 0x8E, 0xE2),
];

/// Engine DJ's default loop color.
const EnginePadColor engineLoopColor = EnginePadColor(0xFF, 0x00, 0xA8, 0xB1);

/// Result of converting a track's Rekordbox cues to Engine DJ blobs.
@immutable
class MappedCues {
  const MappedCues({required this.quickCues, required this.loops});

  final EngineQuickCues quickCues;
  final EngineLoops loops;
}

/// Converts Rekordbox cues to Engine hot cue and loop slots.
///
/// - Hot cues A-H map to quick cue slots 1-8 at their original positions.
/// - The first memory cue (by position) becomes Engine's main cue.
/// - When [memoryCuesToHotCues] is set, remaining memory cues fill empty
///   hot cue slots in position order.
/// - All cues with an out-point (memory loops and hot cue loops) fill
///   Engine's 8 loop slots in position order.
///
/// Millisecond positions convert to samples via [sampleRate].
MappedCues mapCuesToEngine({
  required List<RekordboxCue> cues,
  required double sampleRate,
  bool memoryCuesToHotCues = false,
  double encoderDelaySamples = 0,
}) {
  double toSamples(RekordboxCue cue) => rekordboxCueToSamples(
    inMsec: cue.inMsec,
    inFrame: cue.inFrame,
    sampleRate: sampleRate,
    encoderDelaySamples: encoderDelaySamples,
  );

  // Hot cues into their designated slots.
  final slots = List<EngineQuickCue>.filled(
    EngineQuickCues.slotCount,
    const EngineQuickCue.empty(),
  );
  for (final cue in cues) {
    final slot = CueKind.hotCues.indexOf(cue.kind);
    if (slot == -1) continue;
    slots[slot] = EngineQuickCue(
      label: cue.comment ?? '',
      sampleOffset: toSamples(cue),
      color: engineHotCueSlotColors[slot],
    );
  }

  final memoryCues = cues.where((c) => c.kind.isMemoryCue).toList()
    ..sort((a, b) => a.inMsec.compareTo(b.inMsec));

  if (memoryCuesToHotCues) {
    final spillCues = memoryCues.where((c) => !c.isLoop).iterator;
    for (var slot = 0; slot < slots.length; slot++) {
      if (slots[slot].isSet) continue;
      if (!spillCues.moveNext()) break;
      slots[slot] = EngineQuickCue(
        label: spillCues.current.comment ?? '',
        sampleOffset: toSamples(spillCues.current),
        color: engineHotCueSlotColors[slot],
      );
    }
  }

  // First memory cue becomes the main cue position.
  final mainCue = memoryCues.isNotEmpty ? toSamples(memoryCues.first) : 0.0;

  // Loops (memory or hot cues with an out-point) fill the 8 loop slots.
  final loopCues = cues.where((c) => c.isLoop).toList()
    ..sort((a, b) => a.inMsec.compareTo(b.inMsec));
  final loopSlots = List<EngineLoop>.filled(
    EngineLoops.slotCount,
    const EngineLoop.empty(),
  );
  for (var i = 0; i < loopCues.length && i < loopSlots.length; i++) {
    final cue = loopCues[i];
    loopSlots[i] = EngineLoop(
      label: cue.comment ?? '',
      startSampleOffset: toSamples(cue),
      endSampleOffset: rekordboxCueToSamples(
        inMsec: cue.outMsec!,
        sampleRate: sampleRate,
        encoderDelaySamples: encoderDelaySamples,
      ),
      isStartSet: true,
      isEndSet: true,
      color: engineLoopColor,
    );
  }

  return MappedCues(
    quickCues: EngineQuickCues(
      quickCues: slots,
      adjustedMainCue: mainCue,
      isMainCueAdjusted: memoryCues.isNotEmpty,
      defaultMainCue: mainCue,
    ),
    loops: EngineLoops(loops: loopSlots),
  );
}
