import 'dart:typed_data';

import 'package:in_phase/src/library/convert/audio_timing.dart';
import 'package:in_phase/src/library/convert/beatgrid_mapper.dart';
import 'package:in_phase/src/library/convert/cue_mapper.dart';
import 'package:in_phase/src/library/convert/key_mapper.dart';
import 'package:in_phase/src/library/engine/blobs/beat_data.dart';
import 'package:in_phase/src/library/engine/blobs/track_data.dart';
import 'package:in_phase/src/library/engine/engine_album_art.dart';
import 'package:in_phase/src/library/rekordbox/rekordbox_artwork.dart';
import 'package:in_phase/src/library/rekordbox/rekordbox_models.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// A Rekordbox track converted to Engine DJ `Track` column values and
/// `PerformanceData` blobs, ready to be written to `m.db`.
@immutable
class EngineTrackRecord {
  const EngineTrackRecord({
    required this.rekordboxId,
    required this.path,
    required this.filename,
    required this.fileType,
    required this.hasBeatGrid,
    required this.rating,
    required this.trackData,
    required this.beatData,
    required this.quickCues,
    required this.loops,
    this.lengthSeconds,
    this.bpm,
    this.bpmAnalyzed,
    this.year,
    this.bitrate,
    this.fileBytes,
    this.title,
    this.artist,
    this.album,
    this.genre,
    this.comment,
    this.label,
    this.composer,
    this.remixer,
    this.key,
    this.dateAddedUnix,
    this.artworkSourceHash,
    this.albumArtId = engineNoAlbumArtId,
  });

  /// Rekordbox content ID, written to `Track.pdbImportKey` and used as the
  /// stable match key across sync runs.
  final int rekordboxId;

  /// Audio file path relative to the Engine Library directory.
  final String path;

  final String filename;
  final String fileType;

  /// Whether an imported beat grid is present; drives `isBeatGridLocked`.
  final bool hasBeatGrid;

  /// Engine rating 0-100 (Rekordbox stars * 20).
  final int rating;

  final int? lengthSeconds;
  final int? bpm;
  final double? bpmAnalyzed;
  final int? year;
  final int? bitrate;
  final int? fileBytes;
  final String? title;
  final String? artist;
  final String? album;
  final String? genre;
  final String? comment;
  final String? label;
  final String? composer;
  final String? remixer;

  /// Engine key integer 0-23.
  final int? key;

  final int? dateAddedUnix;

  /// SHA-1 hex of the Rekordbox artwork file, when present.
  final String? artworkSourceHash;

  /// Assigned during sync; defaults to [engineNoAlbumArtId].
  final int albumArtId;

  final Uint8List trackData;
  final Uint8List beatData;
  final Uint8List quickCues;
  final Uint8List loops;

  EngineTrackRecord withAlbumArtId(int id) => EngineTrackRecord(
    rekordboxId: rekordboxId,
    path: path,
    filename: filename,
    fileType: fileType,
    hasBeatGrid: hasBeatGrid,
    rating: rating,
    lengthSeconds: lengthSeconds,
    bpm: bpm,
    bpmAnalyzed: bpmAnalyzed,
    year: year,
    bitrate: bitrate,
    fileBytes: fileBytes,
    title: title,
    artist: artist,
    album: album,
    genre: genre,
    comment: comment,
    label: label,
    composer: composer,
    remixer: remixer,
    key: key,
    dateAddedUnix: dateAddedUnix,
    artworkSourceHash: artworkSourceHash,
    albumArtId: id,
    trackData: trackData,
    beatData: beatData,
    quickCues: quickCues,
    loops: loops,
  );
}

/// Converts a [RekordboxTrack] into an [EngineTrackRecord].
///
/// [engineLibraryPath] is the Engine Library directory; track paths in
/// `m.db` are stored relative to it.
EngineTrackRecord mapTrackToEngine(
  RekordboxTrack track, {
  required String engineLibraryPath,
  required String rekordboxShareRoot,
  bool memoryCuesToHotCues = false,
  bool syncArt = true,
  String? artworkSourceHash,
}) {
  final sampleRate = (track.sampleRate ?? 44100).toDouble();
  final sampleCount = (track.lengthSeconds ?? 0) * sampleRate.round();
  final fileType = p
      .extension(track.audioFilePath)
      .replaceFirst('.', '')
      .toLowerCase();
  final encoderDelay = estimatedEncoderDelaySamples(fileType, sampleRate);

  final markers = track.beatGrid != null
      ? mapBeatGridToEngine(
          beats: track.beatGrid!,
          sampleRate: sampleRate,
          sampleCount: sampleCount,
          encoderDelaySamples: encoderDelay,
        )
      : null;

  final beatData = EngineBeatData(
    sampleRate: sampleRate,
    samples: sampleCount.toDouble(),
    defaultBeatGrid: markers ?? const [],
    adjustedBeatGrid: markers ?? const [],
  );

  final cues = mapCuesToEngine(
    cues: track.cues,
    sampleRate: sampleRate,
    memoryCuesToHotCues: memoryCuesToHotCues,
    encoderDelaySamples: encoderDelay,
  );

  final key = mapKeyToEngine(track.keyName);

  final trackData = EngineTrackData(
    sampleRate: sampleRate,
    samples: sampleCount,
    key: key ?? 0,
  );

  final rekordboxRating = track.rating ?? 0;

  return EngineTrackRecord(
    rekordboxId: int.parse(track.id),
    path: p.relative(track.audioFilePath, from: engineLibraryPath),
    filename: p.basename(track.audioFilePath),
    fileType: fileType,
    hasBeatGrid: markers != null,
    rating: rekordboxRating <= 5 ? rekordboxRating * 20 : rekordboxRating,
    lengthSeconds: track.lengthSeconds,
    bpm: track.bpmCenti != null ? (track.bpmCenti! / 100).round() : null,
    bpmAnalyzed: track.bpmCenti != null ? track.bpmCenti! / 100 : null,
    year: track.releaseYear == 0 ? null : track.releaseYear,
    bitrate: track.bitRate,
    fileBytes: track.fileSizeBytes,
    title: track.title,
    artist: track.artist,
    album: track.album,
    genre: track.genre,
    comment: track.comment,
    label: track.label,
    composer: track.composer,
    remixer: track.remixer,
    key: key,
    dateAddedUnix: track.dateAdded != null
        ? track.dateAdded!.millisecondsSinceEpoch ~/ 1000
        : null,
    artworkSourceHash: syncArt
        ? (artworkSourceHash ??
              rekordboxArtworkSourceHash(
                rekordboxShareRoot,
                track.artworkRelativePath,
              ))
        : null,
    trackData: trackData.toBlob(),
    beatData: beatData.toBlob(),
    quickCues: cues.quickCues.toBlob(),
    loops: cues.loops.toBlob(),
  );
}
