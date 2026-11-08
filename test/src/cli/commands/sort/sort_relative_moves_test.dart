import 'dart:math';

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

  group('sortReorderMoves', () {
    /// Applies [moves] the way Spotify's reorder endpoint does.
    List<int> apply(
      int length,
      List<({int rangeStart, int insertBefore})> moves,
    ) {
      final playlist = List.generate(length, (i) => i);
      for (final move in moves) {
        final track = playlist.removeAt(move.rangeStart);
        playlist.insert(
          move.rangeStart < move.insertBefore
              ? move.insertBefore - 1
              : move.insertBefore,
          track,
        );
      }
      return playlist;
    }

    test('already sorted needs no moves', () {
      expect(sortReorderMoves([0, 1, 2, 3]), isEmpty);
    });

    test('rotation moves only the last track to the front', () {
      expect(sortReorderMoves([3, 0, 1, 2]), [
        (rangeStart: 3, insertBefore: 0),
      ]);
    });

    test('random orders end up sorted with one move per relative move', () {
      final random = Random(42);
      for (var run = 0; run < 200; run++) {
        final sorted = List.generate(random.nextInt(40), (i) => i)
          ..shuffle(random);
        final moves = sortReorderMoves(sorted);

        expect(apply(sorted.length, moves), sorted);
        expect(
          moves.length,
          sorted.length - relativeStablePositions(sorted).length,
        );
      }
    });
  });
}
