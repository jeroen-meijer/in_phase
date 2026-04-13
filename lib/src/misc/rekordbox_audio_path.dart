import 'package:path/path.dart' as path;
import 'package:rekorddart/rekorddart.dart';

/// Returns a path to the main audio file for [song], or null if Rekordbox has
/// no usable [DjmdContentData.folderPath] and file name columns.
///
/// Rekordbox sometimes stores [DjmdContentData.folderPath] so that its last
/// path segment is already the file name (e.g. `.../Album/track.wav`). In that
/// case [DjmdContentData.fileNameL] repeats that segment; joining both would
/// produce `.../track.wav/track.wav`. When the basename of the folder path
/// equals the file name, the folder path is treated as the full file path.
String? rekordboxAudioPath(DjmdContentData song) {
  final rawFolder = song.folderPath?.trim();
  final name = (song.fileNameL ?? song.fileNameS)?.trim();
  if (rawFolder == null || rawFolder.isEmpty || name == null || name.isEmpty) {
    return null;
  }

  final folderNorm = path.normalize(rawFolder);
  if (path.basename(folderNorm) == name) {
    return folderNorm;
  }
  return path.normalize(path.join(folderNorm, name));
}
