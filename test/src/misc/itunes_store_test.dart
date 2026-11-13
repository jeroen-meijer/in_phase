import 'package:in_phase/src/misc/misc.dart';
import 'package:test/test.dart';

Map<String, dynamic> _result(String artist, String title, String url) => {
  'artistName': artist,
  'trackName': title,
  'trackViewUrl': url,
};

void main() {
  group('ItunesStore.bestTrackWebUrl', () {
    test('rejects results that match only the artist or only the title', () {
      expect(
        ItunesStore.bestTrackWebUrl(
          artist: 'Gydra',
          title: 'Wipe',
          rawResults: [
            _result('Gydra', 'Other Song', 'https://a'),
            _result('Someone Else', 'Wipe', 'https://b'),
          ],
        ),
        isNull,
      );
    });

    test('prefers an exact match over a partial one', () {
      expect(
        ItunesStore.bestTrackWebUrl(
          artist: 'S.P.Y',
          title: 'Rock Da House',
          rawResults: [
            _result('S.P.Y & Friend', 'Rock Da House', 'https://partial'),
            _result('S.P.Y', 'Rock Da House', 'https://exact'),
          ],
        ),
        'https://exact',
      );
    });
  });
}
