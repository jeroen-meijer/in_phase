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

  group('coerceEngineAlbumArtHash', () {
    test('passes through hex TEXT', () {
      expect(
        coerceEngineAlbumArtHash('094bfbee1855a36201150b96b1a79df65a767d28'),
        '094bfbee1855a36201150b96b1a79df65a767d28',
      );
    });

    test('hex-encodes a raw 20-byte SHA-1 BLOB', () {
      final digest = Uint8List.fromList([
        0x09,
        0x4b,
        0xfb,
        0xee,
        0x18,
        0x55,
        0xa3,
        0x62,
        0x01,
        0x15,
        0x0b,
        0x96,
        0xb1,
        0xa7,
        0x9d,
        0xf6,
        0x5a,
        0x76,
        0x7d,
        0x28,
      ]);
      expect(
        coerceEngineAlbumArtHash(digest),
        '094bfbee1855a36201150b96b1a79df65a767d28',
      );
    });

    test('decodes a UTF-8 hex string stored as BLOB', () {
      expect(
        coerceEngineAlbumArtHash(
          Uint8List.fromList('abc123'.codeUnits),
        ),
        'abc123',
      );
    });

    test('returns null for null and empty', () {
      expect(coerceEngineAlbumArtHash(null), isNull);
      expect(coerceEngineAlbumArtHash(''), isNull);
      expect(coerceEngineAlbumArtHash(Uint8List(0)), isNull);
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
