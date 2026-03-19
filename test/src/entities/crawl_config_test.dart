import 'package:in_phase/src/entities/crawl_config.dart';
import 'package:test/test.dart';

void main() {
  group('CrawlOptions', () {
    test('fromJson defaults includeArtistAppearances to true', () {
      final options = CrawlOptions.fromJson(
        const <String, dynamic>{},
      );

      expect(options.includeArtistAppearances, isTrue);
    });

    test('fromJson parses includeArtistAppearances as true', () {
      final options = CrawlOptions.fromJson(
        const <String, dynamic>{
          'include_artist_appearances': true,
        },
      );

      expect(options.includeArtistAppearances, isTrue);
    });

    test('fromJson parses includeArtistAppearances as false', () {
      final options = CrawlOptions.fromJson(
        const <String, dynamic>{
          'include_artist_appearances': false,
        },
      );

      expect(options.includeArtistAppearances, isFalse);
    });

    test('toJson includes includeArtistAppearances', () {
      const options = CrawlOptions(
        includeArtistAppearances: false,
      );

      final json = options.toJson();

      expect(json['include_artist_appearances'], isFalse);
    });

    test('default constructor sets includeArtistAppearances to true', () {
      const options = CrawlOptions();

      expect(options.includeArtistAppearances, isTrue);
    });

    test('round-trips through JSON correctly', () {
      const original = CrawlOptions(
        includeArtistAppearances: false,
      );

      final json = original.toJson();
      final restored = CrawlOptions.fromJson(json);

      expect(
        restored.includeArtistAppearances,
        original.includeArtistAppearances,
      );
    });
  });
}
