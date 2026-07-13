import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:in_phase/src/library/engine/engine_database.dart';
import 'package:in_phase/src/library/rekordbox/rekordbox_artwork.dart';
import 'package:path/path.dart' as p;

/// Engine's sentinel `AlbumArt.id` for tracks without artwork.
const engineNoAlbumArtId = 1;

/// Subdirectory under the Engine Library for external artwork (Engine 4.5+).
const engineArtworkDirectoryName = 'Artwork';

/// Encodes Rekordbox JPEG/PNG artwork as a 256×256 PNG for `AlbumArt.albumArt`.
///
/// Matches the approach used by community Engine importers (resize + PNG blob,
/// SHA-1 of the original file bytes for deduplication).
Uint8List encodeEngineAlbumArtBlob(Uint8List sourceBytes) {
  final decoded = img.decodeImage(sourceBytes);
  if (decoded == null) return sourceBytes;

  final resized = img.copyResize(
    decoded,
    width: 256,
    height: 256,
    interpolation: img.Interpolation.average,
  );
  return Uint8List.fromList(img.encodePng(resized));
}

/// JPEG bytes for the external `Engine Library/Artwork/` store (Engine 4.5+).
Uint8List encodeEngineAlbumArtJpeg(Uint8List sourceBytes) {
  final decoded = img.decodeImage(sourceBytes);
  if (decoded == null) return sourceBytes;

  final resized = img.copyResize(
    decoded,
    width: 256,
    height: 256,
    interpolation: img.Interpolation.average,
  );
  return Uint8List.fromList(img.encodeJpg(resized, quality: 90));
}

/// Deduplicated Rekordbox artwork → Engine `AlbumArt` rows (and optional
/// external files).
class EngineAlbumArtRegistry {
  EngineAlbumArtRegistry({
    required EngineDatabase db,
    required String engineLibraryPath,
    required bool writeExternalArtwork,
  }) : _db = db,
       _engineLibraryPath = engineLibraryPath,
       _writeExternalArtwork = writeExternalArtwork {
    for (final row in _db.readAlbumArtRows()) {
      final hash = row.hash;
      if (hash != null && hash.isNotEmpty) {
        _idByHash[hash] = row.id;
      }
    }
  }

  final EngineDatabase _db;
  final String _engineLibraryPath;
  final bool _writeExternalArtwork;
  final _idByHash = <String, int>{};
  int rowsInserted = 0;

  /// Ensures the placeholder row for tracks without artwork exists.
  void ensurePlaceholder() => _db.ensureNoAlbumArtPlaceholder();

  /// Whether [hash] is already registered in Engine.
  bool containsHash(String hash) => _idByHash.containsKey(hash);

  /// Returns the Engine `AlbumArt.id` for [hash], if known.
  int? lookupId(String? hash) {
    if (hash == null || hash.isEmpty) return null;
    return _idByHash[hash];
  }

  /// Reads, encodes, and inserts artwork for [hash] when not already present.
  void importArtwork({
    required String shareRoot,
    required String artworkRelativePath,
    required String hash,
  }) {
    if (containsHash(hash)) return;

    final file = resolveRekordboxArtworkFile(shareRoot, artworkRelativePath);
    if (file == null) return;

    final sourceBytes = file.readAsBytesSync();
    final blob = encodeEngineAlbumArtBlob(sourceBytes);
    final id = _db.insertAlbumArt(hash: hash, imageData: blob);
    _idByHash[hash] = id;
    rowsInserted++;

    if (_writeExternalArtwork) {
      _writeExternalFile(hash, encodeEngineAlbumArtJpeg(sourceBytes));
    }
  }

  /// Returns [engineNoAlbumArtId] when artwork is missing; otherwise a shared
  /// `AlbumArt.id` for [hash] (must already be imported).
  int albumArtIdForHash(String? hash) => lookupId(hash) ?? engineNoAlbumArtId;

  void _writeExternalFile(String hash, Uint8List jpegBytes) {
    final dir = Directory(
      p.join(_engineLibraryPath, engineArtworkDirectoryName),
    );
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    File(p.join(dir.path, '$hash.jpg')).writeAsBytesSync(jpegBytes);
  }
}
