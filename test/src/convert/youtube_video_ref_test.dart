import 'package:in_phase/src/convert/youtube_video_ref.dart';
import 'package:test/test.dart';

void main() {
  group('youtubeVideoRefFromMetadata', () {
    test('prefers music artist over Topic release channel', () {
      final ref = youtubeVideoRefFromMetadata(
        id: 'Ium6DqVkcvg',
        title: 'Energy',
        author: 'Release - Topic',
        musicArtist: 'Higgo',
        musicSong: 'Energy',
      );
      expect(ref.author, 'Higgo');
      expect(ref.title, 'Energy');
    });

    test('falls back to uploader when music metadata is absent', () {
      final ref = youtubeVideoRefFromMetadata(
        id: 'abc',
        title: 'Sunrise',
        author: 'Higgo [Official]',
      );
      expect(ref.author, 'Higgo [Official]');
      expect(ref.title, 'Sunrise');
    });
  });
}
