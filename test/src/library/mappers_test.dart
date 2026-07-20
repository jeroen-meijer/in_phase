import 'package:in_phase/src/library/library.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:test/test.dart';

void main() {
  group('mapKeyToEngine', () {
    test('maps natural key names', () {
      expect(mapKeyToEngine('C'), 0); // 8B
      expect(mapKeyToEngine('Am'), 1); // 8A
      expect(mapKeyToEngine('Fm'), 17); // 4A
      expect(mapKeyToEngine('Dm'), 23); // 7A
    });

    test('maps Camelot key names', () {
      expect(mapKeyToEngine('8B'), 0);
      expect(mapKeyToEngine('4A'), 17);
      expect(mapKeyToEngine('12B'), 8);
    });

    test('returns null for unknown keys', () {
      expect(mapKeyToEngine(null), isNull);
      expect(mapKeyToEngine('not a key'), isNull);
    });
  });

  group('mapBeatGridToEngine', () {
    // 128 BPM at 44100 Hz: 468.75 ms per beat.
    List<AnlzBeat> constantGrid(int count) => [
      for (var i = 0; i < count; i++)
        AnlzBeat(
          beatNumberInBar: i % 4 + 1,
          tempoCentiBpm: 12800,
          timeMs: 500 + (i * 468.75).round(),
        ),
    ];

    test('compresses a constant-tempo grid to two markers', () {
      final markers = mapBeatGridToEngine(
        beats: constantGrid(64),
        sampleRate: 44100,
        sampleCount: 44100 * 60,
      );

      expect(markers, isNotNull);
      expect(markers, hasLength(2));

      // First marker is extended back to beat -4.
      expect(markers![0].beatNumber, -4);
      const samplesPerBeat = 468.75 / 1000 * 44100;
      expect(
        markers[0].sampleOffset,
        closeTo(0.5 * 44100 - 4 * samplesPerBeat, 1),
      );

      // Last marker is extended past the end of the track.
      expect(
        markers[1].sampleOffset,
        greaterThanOrEqualTo(44100 * 60),
      );
      expect(
        markers[0].numberOfBeats,
        markers[1].beatNumber - markers[0].beatNumber,
      );
      expect(markers[1].numberOfBeats, 0);
    });

    test('emits a marker at each tempo change', () {
      // 32 beats at 128 BPM, then 32 beats at 140 BPM (428.57 ms per beat).
      final beats = [
        ...constantGrid(32),
        for (var i = 0; i < 32; i++)
          AnlzBeat(
            beatNumberInBar: i % 4 + 1,
            tempoCentiBpm: 14000,
            timeMs: 500 + (31 * 468.75).round() + ((i + 1) * 428.57).round(),
          ),
      ];

      final markers = mapBeatGridToEngine(
        beats: beats,
        sampleRate: 44100,
        sampleCount: 44100 * 60,
      );

      expect(markers, isNotNull);
      expect(markers, hasLength(3));
      expect(markers![1].beatNumber, 32);
    });

    test('returns null for degenerate grids', () {
      expect(
        mapBeatGridToEngine(
          beats: constantGrid(1),
          sampleRate: 44100,
          sampleCount: 44100,
        ),
        isNull,
      );
    });

    test('aligns phase when PQTZ starts on beat 4 before the downbeat', () {
      // Mirrors Get Funky: beat 4 at 1 ms, first downbeat at 346 ms @ 174 BPM.
      const msPerBeat = 345.0; // 174 BPM
      final beats = [
        const AnlzBeat(beatNumberInBar: 4, tempoCentiBpm: 17400, timeMs: 1),
        for (var i = 0; i < 63; i++)
          AnlzBeat(
            beatNumberInBar: i % 4 + 1,
            tempoCentiBpm: 17400,
            timeMs: 346 + (i * msPerBeat).round(),
          ),
      ];

      final markers = mapBeatGridToEngine(
        beats: beats,
        sampleRate: 48000,
        sampleCount: 48000 * 203,
      );

      expect(markers, isNotNull);
      final downbeatOffset = firstDownbeatSampleOffset(
        beats: beats,
        sampleRate: 48000,
      );
      expect(downbeatOffset, closeTo(346 * 48, 1));

      // Interpolate beat index at the true downbeat; beat 0 mod 4.
      final spb =
          (markers![1].sampleOffset - markers[0].sampleOffset) /
          (markers[1].beatNumber - markers[0].beatNumber);
      final beatAtDownbeat =
          markers[0].beatNumber +
          (downbeatOffset! - markers[0].sampleOffset) / spb;
      expect(beatAtDownbeat.round() % 4, 0);
    });

    test('subtracts encoder delay for lossy formats', () {
      final beats = [
        const AnlzBeat(beatNumberInBar: 1, tempoCentiBpm: 17500, timeMs: 49),
        const AnlzBeat(beatNumberInBar: 2, tempoCentiBpm: 17500, timeMs: 391),
        const AnlzBeat(beatNumberInBar: 3, tempoCentiBpm: 17500, timeMs: 734),
        const AnlzBeat(beatNumberInBar: 4, tempoCentiBpm: 17500, timeMs: 1077),
        for (var i = 4; i < 64; i++)
          AnlzBeat(
            beatNumberInBar: i % 4 + 1,
            tempoCentiBpm: 17500,
            timeMs: 1077 + (i - 3) * 343,
          ),
      ];
      const delay = 2112.0; // AAC priming at 44.1 kHz

      final withoutDelay = firstDownbeatSampleOffset(
        beats: beats,
        sampleRate: 44100,
      );
      final withDelay = firstDownbeatSampleOffset(
        beats: beats,
        sampleRate: 44100,
        encoderDelaySamples: delay,
      );

      expect(withoutDelay, isNotNull);
      expect(withoutDelay, closeTo(49 * 44.1, 1));
      expect(withDelay, closeTo(withoutDelay! - delay, 1));
    });
  });

  group('mapCuesToEngine', () {
    test('places hot cues into their slots', () {
      final mapped = mapCuesToEngine(
        cues: const [
          RekordboxCue(kind: CueKind.hotCueA, inMsec: 1000, comment: 'Drop'),
          RekordboxCue(kind: CueKind.hotCueC, inMsec: 2000),
        ],
        sampleRate: 44100,
      );

      final slots = mapped.quickCues.quickCues;
      expect(slots[0].isSet, isTrue);
      expect(slots[0].label, 'Drop');
      expect(slots[0].sampleOffset, 44100);
      expect(slots[1].isSet, isFalse);
      expect(slots[2].isSet, isTrue);
      expect(slots[2].sampleOffset, 88200);
    });

    test('uses the first memory cue as the main cue', () {
      final mapped = mapCuesToEngine(
        cues: const [
          RekordboxCue(kind: CueKind.memory, inMsec: 3000),
          RekordboxCue(kind: CueKind.memory, inMsec: 1000),
        ],
        sampleRate: 44100,
      );

      expect(mapped.quickCues.adjustedMainCue, 44100);
      expect(mapped.quickCues.isMainCueAdjusted, isTrue);
    });

    test('spills memory cues into empty hot cue slots when enabled', () {
      final mapped = mapCuesToEngine(
        cues: const [
          RekordboxCue(kind: CueKind.hotCueA, inMsec: 1000),
          RekordboxCue(kind: CueKind.memory, inMsec: 2000),
          RekordboxCue(kind: CueKind.memory, inMsec: 3000, outMsec: 4000),
        ],
        sampleRate: 44100,
        memoryCuesToHotCues: true,
      );

      final slots = mapped.quickCues.quickCues;
      // Non-loop memory cue fills the first empty slot (B); the memory loop
      // is not spilled.
      expect(slots[1].isSet, isTrue);
      expect(slots[1].sampleOffset, 88200);
      expect(slots[2].isSet, isFalse);
    });

    test('maps loops from memory and hot cues with out-points', () {
      final mapped = mapCuesToEngine(
        cues: const [
          RekordboxCue(
            kind: CueKind.memory,
            inMsec: 1000,
            outMsec: 2000,
            comment: 'Loop 1',
          ),
          RekordboxCue(kind: CueKind.hotCueB, inMsec: 500, outMsec: 750),
        ],
        sampleRate: 44100,
      );

      final loops = mapped.loops.loops;
      expect(loops[0].isSet, isTrue);
      expect(loops[0].startSampleOffset, 22050);
      expect(loops[0].endSampleOffset, 33075);
      expect(loops[1].isSet, isTrue);
      expect(loops[1].label, 'Loop 1');
      expect(loops[2].isSet, isFalse);
    });

    test('prefers inFrame over inMsec for cue positions', () {
      final mapped = mapCuesToEngine(
        cues: const [
          RekordboxCue(
            kind: CueKind.hotCueA,
            inMsec: 43934,
            inFrame: 6590,
          ),
        ],
        sampleRate: 44100,
      );

      expect(
        mapped.quickCues.quickCues[0].sampleOffset,
        closeTo(6590 * 44100 / 150, 1),
      );
    });
  });

  group('mapTrackToEngine', () {
    test('maps metadata and computes a relative path', () {
      const track = RekordboxTrack(
        id: '42',
        audioFilePath: '/Users/dj/Music/track.mp3',
        title: 'Test Track',
        artist: 'Test Artist',
        keyName: '4A',
        bpmCenti: 12850,
        lengthSeconds: 300,
        rating: 4,
        sampleRate: 44100,
      );

      final record = mapTrackToEngine(
        track,
        engineLibraryPath: '/Users/dj/Music/Engine Library',
        rekordboxShareRoot: '/tmp/share',
      );

      expect(record.rekordboxId, 42);
      expect(record.path, '../track.mp3');
      expect(record.filename, 'track.mp3');
      expect(record.fileType, 'mp3');
      expect(record.bpm, 129);
      expect(record.bpmAnalyzed, 128.5);
      expect(record.key, 17);
      expect(record.rating, 80);
      expect(record.hasBeatGrid, isFalse);

      final trackData = EngineTrackData.fromBlob(record.trackData);
      expect(trackData.sampleRate, 44100);
      expect(trackData.samples, 300 * 44100);
      expect(trackData.key, 17);
    });
  });
}
