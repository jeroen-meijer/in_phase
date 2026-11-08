import 'package:in_phase/src/misc/misc.dart';
import 'package:rekorddart/rekorddart.dart' hide isNull;
import 'package:test/test.dart';

const _timestamp = '2026-01-01 00:00:00';

RbArtistAndSong _song(String id, String artist, String? title) => (
  artist: DjmdArtistData(
    name: artist,
    createdAt: _timestamp,
    updatedAt: _timestamp,
  ),
  song: DjmdContentData(
    id: id,
    title: title,
    createdAt: _timestamp,
    updatedAt: _timestamp,
  ),
);

void main() {
  test('normalizeForMatch ignores case, punctuation and spacing', () {
    expect(
      normalizeForMatch('  S.P.Y -  Rock Da House! '),
      's p y rock da house',
    );
  });

  group('RekordboxMatchIndex', () {
    test('finds the closest song across worker chunks', () async {
      final index = RekordboxMatchIndex([
        _song('1', 'Gydra', 'Wipe'),
        _song('2', 'Noisia', 'Tentacles'),
        _song('3', 'S.P.Y', 'Rock Da House'),
        _song('4', 'Unknown', null),
        _song('5', 'Phace', 'Psylocybin'),
      ]);

      final match = await index.bestMatch(['S.P.Y'], 'Rock Da House');

      expect(match!.value.song.id, '3');
      expect(match.score, 100);
    });

    test('returns null for an empty library', () async {
      expect(await RekordboxMatchIndex(const []).bestMatch(['a'], 'b'), isNull);
    });
  });
}
