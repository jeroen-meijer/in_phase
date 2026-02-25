import 'dart:math';

import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';
import 'package:in_phase/src/logger/logger.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:io/io.dart';
import 'package:rekorddart/rekorddart.dart';
import 'package:uuid/uuid.dart';

class CuesSyncCommand extends Command<int> {
  CuesSyncCommand() {
    argParser
      ..addFlag(
        'from-memory',
        help:
            'Sync memory cues to hot cues. Existing hot cues are removed '
            'except those at the same time as memory cues.',
        negatable: false,
      )
      ..addFlag(
        'from-hot',
        help:
            'Sync hot cues to memory cues. All existing memory cues are '
            'removed.',
        negatable: false,
      );
  }

  @override
  final String name = 'sync';

  @override
  final String description =
      'Syncs memory cues and hot cues between each other.';

  @override
  Future<int> run() async {
    final fromMemory = argResults!['from-memory'] == true;
    final fromHot = argResults!['from-hot'] == true;

    // Validate that exactly one flag is provided
    if (fromMemory == fromHot) {
      usageException(
        'Exactly one of --from-memory or --from-hot must be specified.',
      );
    }

    final syncDirection = fromMemory
        ? _SyncDirection.memoryToHot
        : _SyncDirection.hotToMemory;

    return withTeardown((addTeardown) async {
      final db = await RekordboxDatabase.connect();
      addTeardown(db.close);

      // Get tracks to process
      log.info('Processing all tracks in database...');
      final tracks = await db.select(db.djmdContent).get();

      log.info('${tracks.length} track(s) found\n');

      var totalSynced = 0;

      for (final track in tracks) {
        totalSynced += switch (syncDirection) {
          _SyncDirection.memoryToHot => await _syncMemoryToHot(db, track),
          _SyncDirection.hotToMemory => await _syncHotToMemory(db, track),
        };
      }

      log.info('\n✅ Successfully synced cues for $totalSynced track(s).');

      return ExitCode.success.code;
    });
  }

  /// Creates a logging function for a specific track.
  void Function(String) _createTrackLogger(DjmdContentData track) {
    final trackTitle = track.title ?? 'Unknown';
    return (String message) {
      log.info('[${green(trackTitle)}] $message');
    };
  }

  /// Syncs memory cues to hot cues.
  ///
  /// - Removes hot cues EXCEPT those at the same time as memory cues
  /// - Creates new hot cues from memory cues (assigning sequential slot
  ///   numbers)
  Future<int> _syncMemoryToHot(
    RekordboxDatabase db,
    DjmdContentData track,
  ) async {
    final logTrack = _createTrackLogger(track);

    final trackId = track.id!;
    final contentUUID = track.uuid;

    // Get all memory cues (Kind = 0)
    final memoryCues =
        await (db.select(db.djmdCue)
              ..where((c) => c.contentID.equals(trackId) & c.kind.equals(0))
              ..orderBy([(c) => OrderingTerm.asc(c.inMsec)]))
            .get();

    if (memoryCues.isEmpty) {
      logTrack('No memory cues found, skipping.');
      return 0;
    }

    // Get all hot cues (Kind 1-3 for A-C, Kind 5-9 for D-H)
    final hotCueKinds = CueKind.hotCues.map((c) => c.kind).toList();
    final hotCues =
        await (db.select(db.djmdCue)
              ..where(
                (c) => c.contentID.equals(trackId) & c.kind.isIn(hotCueKinds),
              )
              ..orderBy([(c) => OrderingTerm.asc(c.inMsec)]))
            .get();

    // Get memory cue time positions
    final memoryCueTimes = memoryCues
        .where((c) => c.inMsec != null)
        .map((c) => c.inMsec!)
        .toSet();

    // Delete hot cues that are NOT at the same time as memory cues
    final hotCuesToDelete = hotCues
        .where((c) => c.inMsec == null || !memoryCueTimes.contains(c.inMsec))
        .toList();

    if (hotCuesToDelete.isNotEmpty) {
      logTrack(
        'Removing ${hotCuesToDelete.length} hot cue(s) '
        'not matching memory cues...',
      );
      for (final cue in hotCuesToDelete) {
        await (db.delete(db.djmdCue)..where((c) => c.id.equals(cue.id!))).go();
      }
    }

    // Find which hot cue slots are already used at memory cue times
    final existingHotCuesByTime = <int, List<DjmdCueData>>{};
    for (final hotCue in hotCues) {
      if (hotCue.inMsec != null && memoryCueTimes.contains(hotCue.inMsec)) {
        existingHotCuesByTime.putIfAbsent(hotCue.inMsec!, () => []).add(hotCue);
      }
    }

    // Create hot cues from memory cues
    CueKind? nextHotCue = CueKind.hotCues.first;
    var createdCount = 0;

    for (final memoryCue in memoryCues) {
      final inMsec = memoryCue.inMsec;

      // Skip if no time position
      if (inMsec == null) {
        continue;
      }

      // Check if hot cue already exists at this time
      final existingAtTime = existingHotCuesByTime[inMsec] ?? [];
      if (existingAtTime.isNotEmpty) {
        logTrack(
          'Hot cue already exists at ${inMsec}ms '
          '(number ${existingAtTime.first.kind}), skipping.',
        );
        continue;
      }

      // Find next available slot (1-8)
      while (nextHotCue != null) {
        final slotInUse = hotCues.any((c) => c.kind == nextHotCue!.kind);
        if (!slotInUse) {
          break;
        }
        nextHotCue = nextHotCue.next;
      }

      if (nextHotCue == null) {
        logTrack(
          'No available hot cue slots (A-H), skipping remaining memory cues.',
        );
        break;
      }

      // Create new hot cue
      final cueId = await _generateUnusedCueId(db);
      final nowIso = DateTime.now().toIso8601String();

      await db
          .into(db.djmdCue)
          .insert(
            DjmdCueCompanion.insert(
              id: Value(cueId),
              contentID: Value(trackId),
              kind: Value(nextHotCue.kind),
              inMsec: Value(inMsec),
              outMsec: Value(memoryCue.outMsec ?? -1),
              contentUUID: contentUUID.toValue(),
              uuid: Value(const Uuid().v4()),
              color: memoryCue.color.toValue(),
              colorTableIndex: memoryCue.colorTableIndex.toValue(),
              activeLoop: memoryCue.activeLoop.toValue(),
              comment: memoryCue.comment.toValue(),
              beatLoopSize: memoryCue.beatLoopSize.toValue(),
              cueMicrosec: memoryCue.cueMicrosec.toValue(),
              inPointSeekInfo: memoryCue.inPointSeekInfo.toValue(),
              outPointSeekInfo: memoryCue.outPointSeekInfo.toValue(),
              rbDataStatus: const Value(0),
              rbLocalDataStatus: const Value(0),
              rbLocalDeleted: const Value(0),
              rbLocalSynced: const Value(0),
              createdAt: nowIso,
              updatedAt: nowIso,
            ),
          );

      logTrack(
        'Created hot cue ${nextHotCue.letter} at ${inMsec}ms',
      );
      createdCount++;
      nextHotCue = nextHotCue.next;
    }

    if (createdCount > 0 || hotCuesToDelete.isNotEmpty) {
      logTrack('Synced $createdCount memory cue(s) to hot cues.');
      return 1;
    }

    return 0;
  }

  /// Syncs hot cues to memory cues.
  ///
  /// - Removes all existing memory cues
  /// - Creates new memory cues from hot cues
  Future<int> _syncHotToMemory(
    RekordboxDatabase db,
    DjmdContentData track,
  ) async {
    final logTrack = _createTrackLogger(track);

    final trackId = track.id!;
    final contentUUID = track.uuid;

    // Get all hot cues (Kind 1-3 for A-C, Kind 5-9 for D-H)
    final hotCueKinds = CueKind.hotCues.map((c) => c.kind).toList();
    final hotCues =
        await (db.select(db.djmdCue)
              ..where(
                (c) => c.contentID.equals(trackId) & c.kind.isIn(hotCueKinds),
              )
              ..orderBy([(c) => OrderingTerm.asc(c.inMsec)]))
            .get();

    if (hotCues.isEmpty) {
      logTrack('No hot cues found, skipping.');
      return 0;
    }

    // Get all existing memory cues
    final memoryCues = await (db.select(
      db.djmdCue,
    )..where((c) => c.contentID.equals(trackId) & c.kind.equals(0))).get();

    // Delete all existing memory cues
    if (memoryCues.isNotEmpty) {
      logTrack('Removing ${memoryCues.length} existing memory cue(s)...');
      for (final cue in memoryCues) {
        await (db.delete(db.djmdCue)..where((c) => c.id.equals(cue.id!))).go();
      }
    }

    // Create memory cues from hot cues
    var createdCount = 0;
    final nowIso = DateTime.now().toIso8601String();

    for (final hotCue in hotCues) {
      final cueId = await _generateUnusedCueId(db);

      await db
          .into(db.djmdCue)
          .insert(
            DjmdCueCompanion.insert(
              id: Value(cueId),
              contentID: Value(trackId),
              kind: const Value(0), // Memory cue
              inMsec: hotCue.inMsec.toValue(),
              outMsec: Value(hotCue.outMsec ?? -1),
              contentUUID: contentUUID.toValue(),
              uuid: Value(const Uuid().v4()),
              color: hotCue.color.toValue(),
              colorTableIndex: hotCue.colorTableIndex.toValue(),
              activeLoop: hotCue.activeLoop.toValue(),
              comment: hotCue.comment.toValue(),
              beatLoopSize: hotCue.beatLoopSize.toValue(),
              cueMicrosec: hotCue.cueMicrosec.toValue(),
              inPointSeekInfo: hotCue.inPointSeekInfo.toValue(),
              outPointSeekInfo: hotCue.outPointSeekInfo.toValue(),
              rbDataStatus: const Value(0),
              rbLocalDataStatus: const Value(0),
              rbLocalDeleted: const Value(0),
              rbLocalSynced: const Value(0),
              createdAt: nowIso,
              updatedAt: nowIso,
            ),
          );

      createdCount++;
    }

    logTrack('Synced $createdCount hot cue(s) to memory cues.');
    return 1;
  }

  /// Generates an unused cue ID.
  Future<String> _generateUnusedCueId(RekordboxDatabase db) async {
    const maxTries = 1000000;
    final random = Random.secure();
    for (var i = 0; i < maxTries; i++) {
      final value = random.nextInt(1 << 28);
      if (value < 100) continue;
      final candidate = value.toString();
      final existing = await (db.select(
        db.djmdCue,
      )..where((c) => c.id.equals(candidate))).getSingleOrNull();
      if (existing == null) return candidate;
    }
    throw StateError(
      'Unable to generate an unused cue ID after $maxTries attempts',
    );
  }
}

enum _SyncDirection {
  memoryToHot,
  hotToMemory,
}
