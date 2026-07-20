import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:in_phase/src/library/library.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeRekordboxSharePath', () {
    test('strips a leading slash', () {
      expect(
        normalizeRekordboxSharePath('/PIONEER/Artwork/foo/artwork.jpg'),
        'PIONEER/Artwork/foo/artwork.jpg',
      );
    });

    test('returns null for empty values', () {
      expect(normalizeRekordboxSharePath(null), isNull);
      expect(normalizeRekordboxSharePath(''), isNull);
    });
  });

  group('encodeEngineAlbumArtBlob', () {
    test('resizes to 256x256 PNG', () {
      final source = Uint8List.fromList(
        img.encodeJpg(img.Image(width: 600, height: 400)),
      );
      final blob = encodeEngineAlbumArtBlob(source);
      final decoded = img.decodeImage(blob);

      expect(decoded, isNotNull);
      expect(decoded!.width, 256);
      expect(decoded.height, 256);
    });
  });

  group('sha1Hex', () {
    test('is stable for identical bytes', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      expect(sha1Hex(bytes), sha1Hex(bytes));
    });
  });

  group('resolveRekordboxArtworkFile', () {
    test('returns null when the file is missing', () {
      final dir = Directory.systemTemp.createTempSync('in_phase_art_test');
      addTearDown(() => dir.deleteSync(recursive: true));

      expect(
        resolveRekordboxArtworkFile(
          dir.path,
          'PIONEER/Artwork/missing/artwork.jpg',
        ),
        isNull,
      );
    });

    test('finds an existing file under share root', () {
      final dir = Directory.systemTemp.createTempSync('in_phase_art_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final artFile = File('${dir.path}/PIONEER/Artwork/x/artwork.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(
          Uint8List.fromList(img.encodeJpg(img.Image(width: 8, height: 8))),
        );

      final resolved = resolveRekordboxArtworkFile(
        dir.path,
        '/PIONEER/Artwork/x/artwork.jpg',
      );

      expect(resolved?.path, artFile.path);
      expect(
        rekordboxArtworkSourceHash(
          dir.path,
          '/PIONEER/Artwork/x/artwork.jpg',
        ),
        isNotNull,
      );
    });
  });
}
