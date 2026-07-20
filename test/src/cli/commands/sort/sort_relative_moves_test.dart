import 'package:in_phase/src/cli/commands/sort/sort_relative_moves.dart';
import 'package:test/test.dart';

void main() {
  group('relativeStablePositions', () {
    test('rotation #4,#1,#2,#3 greys only the trailing block', () {
      // Original 0,1,2,3 → sorted as 3,0,1,2
      final stable = relativeStablePositions([3, 0, 1, 2]);
      expect(stable, {1, 2, 3});
    });

    test('already sorted: all stable', () {
      expect(relativeStablePositions([0, 1, 2, 3]), {0, 1, 2, 3});
    });

    test('single swap highlights one side of the LIS', () {
      // 0,2,1,3 → LIS is 0,2,3 or 0,1,3
      final stable = relativeStablePositions([0, 2, 1, 3]);
      expect(stable.length, 3);
      expect(stable.contains(0), isTrue);
      expect(stable.contains(3), isTrue);
    });

    test('empty', () {
      expect(relativeStablePositions([]), isEmpty);
    });
  });
}
