import 'package:in_phase/src/entities/entities.dart';
import 'package:in_phase/src/spotify/spotify.dart';
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

  group('SyncConfig', () {
    group('fromYamlString', () {
      SyncConfig parse(String customTracks) => SyncConfig.fromYamlString('''
playlists: []
folders: {}
overwrite_song_keys: false
$customTracks
''');

      test('groups custom tracks by playlist id', () {
        final config = parse('''
custom_tracks:
  4rnleEAOdmFAbRcNCgZMpY:
    - rekordbox_id: '101'
    - rekordbox_id: '102'
''');

        expect(
          config.customTracks[SpotifyPlaylistId('4rnleEAOdmFAbRcNCgZMpY')]?.map(
            (t) => t.rekordboxId,
          ),
          ['101', '102'],
        );
      });

      test('reads a Rekordbox id written as a number', () {
        final config = parse('''
custom_tracks:
  4rnleEAOdmFAbRcNCgZMpY:
    - rekordbox_id: 101
      target: 102
''');

        final track = config.customTracks.values.single.single;
        expect(track.rekordboxId, '101');
        expect(track.target, '102');
      });

      test('leaves target empty when it is not set', () {
        final config = parse('''
custom_tracks:
  4rnleEAOdmFAbRcNCgZMpY:
    - rekordbox_id: 101
''');

        expect(config.customTracks.values.single.single.target, isNull);
      });

      test('returns no custom tracks when custom_tracks is missing', () {
        expect(parse('').customTracks, isEmpty);
      });

      test('rejects a Rekordbox id that is not a number or a string', () {
        expect(
          () => parse('''
custom_tracks:
  4rnleEAOdmFAbRcNCgZMpY:
    - rekordbox_id: [101]
'''),
          throwsArgumentError,
        );
      });
    });
  });
}
