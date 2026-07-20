import 'package:in_phase/src/library/rekordbox/anlz_parser.dart';
import 'package:in_phase/src/misc/misc.dart';
import 'package:meta/meta.dart';

/// A cue point read from Rekordbox's `djmdCue` table.
///
/// Cues with a non-null [outMsec] are loops; [kind] distinguishes memory
/// cues from hot cue slots A-H.
@immutable
class RekordboxCue {
  const RekordboxCue({
    required this.kind,
    required this.inMsec,
    this.inFrame,
    this.outMsec,
    this.comment,
  });

  final CueKind kind;
  final int inMsec;

  /// Rekordbox `InFrame` (1/150 s units), when set.
  final int? inFrame;
  final int? outMsec;
  final String? comment;

  bool get isLoop => outMsec != null;
}

/// A track read from Rekordbox, with joined names, cues, and beat grid,
/// ready for conversion to Engine DJ.
@immutable
class RekordboxTrack {
  const RekordboxTrack({
    required this.id,
    required this.audioFilePath,
    this.title,
    this.artist,
    this.album,
    this.genre,
    this.label,
    this.composer,
    this.remixer,
    this.comment,
    this.keyName,
    this.bpmCenti,
    this.lengthSeconds,
    this.rating,
    this.releaseYear,
    this.bitRate,
    this.fileSizeBytes,
    this.sampleRate,
    this.dateAdded,
    this.artworkRelativePath,
    this.cues = const [],
    this.beatGrid,
  });

  /// Rekordbox `djmdContent.ID` (numeric string).
  final String id;

  /// Absolute path to the audio file on disk.
  final String audioFilePath;

  final String? title;
  final String? artist;
  final String? album;
  final String? genre;
  final String? label;
  final String? composer;
  final String? remixer;
  final String? comment;

  /// Key name from `djmdKey.ScaleName` (natural or Camelot notation).
  final String? keyName;

  /// BPM * 100 as stored by Rekordbox.
  final int? bpmCenti;

  final int? lengthSeconds;

  /// Rekordbox rating 0-5 stars.
  final int? rating;

  final int? releaseYear;
  final int? bitRate;
  final int? fileSizeBytes;
  final int? sampleRate;
  final DateTime? dateAdded;

  /// Rekordbox `ImagePath` (track or album), relative to the share directory.
  final String? artworkRelativePath;

  final List<RekordboxCue> cues;

  /// Beat grid from the track's ANLZ `.DAT` file, if available.
  final List<AnlzBeat>? beatGrid;
}

/// A node in the Rekordbox playlist tree: either a folder or a playlist.
@immutable
class RekordboxPlaylistNode {
  const RekordboxPlaylistNode({
    required this.id,
    required this.name,
    required this.isFolder,
    this.children = const [],
    this.trackIds = const [],
  });

  final String id;
  final String name;
  final bool isFolder;

  /// Child nodes in `Seq` order (folders only).
  final List<RekordboxPlaylistNode> children;

  /// Track content IDs in `TrackNo` order (playlists only).
  final List<String> trackIds;
}
