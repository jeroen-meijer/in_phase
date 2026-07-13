import 'dart:typed_data';

import 'package:in_phase/src/library/library.dart';
import 'package:test/test.dart';

void main() {
  group('qCompress', () {
    test('round-trips arbitrary data', () {
      final data = Uint8List.fromList(List.generate(1000, (i) => i % 256));
      expect(qUncompress(qCompress(data)), data);
    });

    test('prefixes the big-endian uncompressed length', () {
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      final blob = qCompress(data);
      expect(blob.sublist(0, 4), [0, 0, 0, 5]);
    });

    test('returns empty for an empty blob', () {
      expect(qUncompress(Uint8List(0)), isEmpty);
    });
  });

  group('EngineBeatData', () {
    test('round-trips through its blob format', () {
      const markers = [
        EngineBeatGridMarker(
          sampleOffset: -3000.5,
          beatNumber: -4,
          numberOfBeats: 132,
        ),
        EngineBeatGridMarker(
          sampleOffset: 2723911.9,
          beatNumber: 128,
          numberOfBeats: 0,
        ),
      ];
      const beatData = EngineBeatData(
        sampleRate: 44100,
        samples: 2822400,
        defaultBeatGrid: markers,
        adjustedBeatGrid: markers,
      );

      final decoded = EngineBeatData.fromBlob(beatData.toBlob());
      expect(decoded.sampleRate, 44100);
      expect(decoded.samples, 2822400);
      expect(decoded.defaultBeatGrid, markers);
      expect(decoded.adjustedBeatGrid, markers);
      expect(decoded.isBeatGridSet, isTrue);
    });

    test('uncompressed layout matches libdjinterop', () {
      // 33-byte header/footer plus 24 bytes per marker.
      const beatData = EngineBeatData(
        sampleRate: 44100,
        samples: 1000,
        defaultBeatGrid: [
          EngineBeatGridMarker(
            sampleOffset: 0,
            beatNumber: -4,
            numberOfBeats: 4,
          ),
        ],
        adjustedBeatGrid: [],
      );
      final raw = qUncompress(beatData.toBlob());
      expect(raw.length, 33 + 24);
    });
  });

  group('EngineQuickCues', () {
    test('round-trips through its blob format', () {
      final slots = [
        const EngineQuickCue(
          label: 'Drop',
          sampleOffset: 88200,
          color: EnginePadColor(0xFF, 0xEA, 0xC5, 0x32),
        ),
        for (var i = 1; i < EngineQuickCues.slotCount; i++)
          const EngineQuickCue.empty(),
      ];
      final quickCues = EngineQuickCues(
        quickCues: slots,
        adjustedMainCue: 44100,
        isMainCueAdjusted: true,
        defaultMainCue: 44100,
      );

      final decoded = EngineQuickCues.fromBlob(quickCues.toBlob());
      expect(decoded.quickCues, slots);
      expect(decoded.adjustedMainCue, 44100);
      expect(decoded.isMainCueAdjusted, isTrue);
      expect(decoded.defaultMainCue, 44100);
    });

    test('requires exactly 8 slots', () {
      expect(
        () => EngineQuickCues(
          quickCues: const [EngineQuickCue.empty()],
          adjustedMainCue: 0,
          isMainCueAdjusted: false,
          defaultMainCue: 0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('EngineLoops', () {
    test('round-trips and is not compressed', () {
      final slots = [
        const EngineLoop(
          label: 'Intro loop',
          startSampleOffset: 44100,
          endSampleOffset: 88200,
          isStartSet: true,
          isEndSet: true,
          color: EnginePadColor(0xFF, 0x00, 0xA8, 0xB1),
        ),
        for (var i = 1; i < EngineLoops.slotCount; i++)
          const EngineLoop.empty(),
      ];
      final loops = EngineLoops(loops: slots);

      final blob = loops.toBlob();
      // 8-byte count + 8 * (23 bytes + label length).
      expect(blob.length, 8 + 8 * 23 + 'Intro loop'.length);
      expect(EngineLoops.fromBlob(blob).loops, slots);
    });
  });

  group('EngineTrackData', () {
    test('round-trips through its blob format', () {
      const trackData = EngineTrackData(
        sampleRate: 44100,
        samples: 2822400,
        key: 17,
      );

      final decoded = EngineTrackData.fromBlob(trackData.toBlob());
      expect(decoded.sampleRate, 44100);
      expect(decoded.samples, 2822400);
      expect(decoded.key, 17);
      expect(decoded.averageLoudnessLow, 0);
    });

    test('uncompressed layout is 44 bytes', () {
      const trackData = EngineTrackData(sampleRate: 44100, samples: 1, key: 0);
      expect(qUncompress(trackData.toBlob()).length, 44);
    });
  });
}
