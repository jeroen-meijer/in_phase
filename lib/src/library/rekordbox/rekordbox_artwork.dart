import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Rekordbox `ImagePath` value relative to the share directory (e.g.
/// `PIONEER/Artwork/.../artwork.jpg`).
String? normalizeRekordboxSharePath(String? imagePath) {
  if (imagePath == null || imagePath.isEmpty) return null;
  return imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
}

/// Resolves a Rekordbox [relativePath] under [shareRoot] to an on-disk file.
///
/// Returns null when the path is missing or the file does not exist.
File? resolveRekordboxArtworkFile(String shareRoot, String? relativePath) {
  final normalized = normalizeRekordboxSharePath(relativePath);
  if (normalized == null) return null;
  final file = File(p.join(shareRoot, normalized));
  return file.existsSync() ? file : null;
}

/// SHA-1 hex digest of [bytes], matching third-party Engine importers.
String sha1Hex(Uint8List bytes) => sha1.convert(bytes).toString();

/// Reads artwork at [relativePath] under [shareRoot] and returns its SHA-1 hex.
String? rekordboxArtworkSourceHash(String shareRoot, String? relativePath) {
  final file = resolveRekordboxArtworkFile(shareRoot, relativePath);
  if (file == null) return null;
  return sha1Hex(file.readAsBytesSync());
}
