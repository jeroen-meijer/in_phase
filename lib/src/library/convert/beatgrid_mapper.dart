import 'package:in_phase/src/library/convert/audio_timing.dart';
import 'package:in_phase/src/library/engine/blobs/beat_data.dart';
import 'package:in_phase/src/library/rekordbox/anlz_parser.dart';

/// Converts a Rekordbox ANLZ beat grid (one entry per beat) into Engine DJ
/// beat grid markers (one entry per tempo change).
///
/// Beat phase is aligned so downbeats (`beatNumberInBar == 1`) fall on Engine
/// beat indices 0, 4, 8, … — PQTZ often starts with beat 4 of the previous
/// bar at ~0 ms, which would otherwise display as Engine beat "1" one beat
/// too early.
///
/// For lossy files, [encoderDelaySamples] subtracts AAC/MP3 priming so markers
/// match Engine's waveform timeline.
List<EngineBeatGridMarker>? mapBeatGridToEngine({
  required List<AnlzBeat> beats,
  required double sampleRate,
  required int sampleCount,
  double encoderDelaySamples = 0,
}) {
  if (beats.length < 2 || sampleRate <= 0 || sampleCount <= 0) return null;

  final firstDownbeatIndex = beats.indexWhere((b) => b.beatNumberInBar == 1);
  if (firstDownbeatIndex < 0) return null;

  int engineBeatIndex(int pqtIndex) => pqtIndex - firstDownbeatIndex;

  double sampleOffset(int pqtIndex) => rekordboxMsToSamples(
    beats[pqtIndex].timeMs,
    sampleRate,
    encoderDelaySamples: encoderDelaySamples,
  );

  // Collect anchors at tempo changes using phase-aligned beat indices.
  final anchorIndices = <int>[0];
  for (var i = 1; i < beats.length; i++) {
    if (beats[i].tempoCentiBpm != beats[i - 1].tempoCentiBpm) {
      anchorIndices.add(i);
    }
  }
  if (anchorIndices.last != beats.length - 1) {
    anchorIndices.add(beats.length - 1);
  }
  if (anchorIndices.length < 2) return null;

  var markers = [
    for (final pqtIndex in anchorIndices)
      (
        index: engineBeatIndex(pqtIndex),
        sampleOffset: sampleOffset(pqtIndex),
      ),
  ];

  // Normalization, ported from libdjinterop's `normalize_beatgrid`.

  final beyondEnd = markers.indexWhere((m) => m.sampleOffset > sampleCount);
  if (beyondEnd != -1) {
    markers = markers.sublist(0, beyondEnd + 1);
  }

  final afterStart = markers.indexWhere((m) => m.sampleOffset > 0);
  if (afterStart > 0) {
    markers = markers.sublist(afterStart - 1);
  }

  if (markers.length < 2) return null;

  final firstSamplesPerBeat =
      (markers[1].sampleOffset - markers[0].sampleOffset) /
      (markers[1].index - markers[0].index);
  markers[0] = (
    index: -4,
    sampleOffset:
        markers[0].sampleOffset - (4 + markers[0].index) * firstSamplesPerBeat,
  );

  final last = markers.length - 1;
  final lastSamplesPerBeat =
      (markers[last].sampleOffset - markers[last - 1].sampleOffset) /
      (markers[last].index - markers[last - 1].index);
  final indexAdjustment =
      ((sampleCount - markers[last].sampleOffset) / lastSamplesPerBeat).ceil();
  markers[last] = (
    index: markers[last].index + indexAdjustment,
    sampleOffset:
        markers[last].sampleOffset + indexAdjustment * lastSamplesPerBeat,
  );

  return [
    for (var i = 0; i < markers.length; i++)
      EngineBeatGridMarker(
        sampleOffset: markers[i].sampleOffset,
        beatNumber: markers[i].index,
        numberOfBeats: i < markers.length - 1
            ? markers[i + 1].index - markers[i].index
            : 0,
      ),
  ];
}

/// Returns the phase-aligned sample offset of the first downbeat, if present.
double? firstDownbeatSampleOffset({
  required List<AnlzBeat> beats,
  required double sampleRate,
  double encoderDelaySamples = 0,
}) {
  final index = beats.indexWhere((b) => b.beatNumberInBar == 1);
  if (index < 0) return null;
  return rekordboxMsToSamples(
    beats[index].timeMs,
    sampleRate,
    encoderDelaySamples: encoderDelaySamples,
  );
}
