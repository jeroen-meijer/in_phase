import 'package:in_phase/src/misc/misc.dart';
import 'package:test/test.dart';

void main() {
  group('mapKeyToCamelotPlaylistOrder', () {
    test('orders keys as 1A, 1B, 2A, 2B, ...', () {
      expect(mapKeyToCamelotPlaylistOrder('1A'), 0);
      expect(mapKeyToCamelotPlaylistOrder('1B'), 1);
      expect(mapKeyToCamelotPlaylistOrder('2A'), 2);
      expect(mapKeyToCamelotPlaylistOrder('2B'), 3);
      expect(mapKeyToCamelotPlaylistOrder('12A'), 22);
      expect(mapKeyToCamelotPlaylistOrder('12B'), 23);
    });

    test('accepts natural key names', () {
      expect(
        mapKeyToCamelotPlaylistOrder('Am'),
        mapKeyToCamelotPlaylistOrder('8A'),
      );
      expect(
        mapKeyToCamelotPlaylistOrder('C'),
        mapKeyToCamelotPlaylistOrder('8B'),
      );
    });

    test('returns null for unknown keys', () {
      expect(mapKeyToCamelotPlaylistOrder(null), isNull);
      expect(mapKeyToCamelotPlaylistOrder('not a key'), isNull);
    });
  });
}
