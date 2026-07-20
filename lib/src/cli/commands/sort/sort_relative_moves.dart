/// Positions in the sorted playlist that keep relative original order.
///
/// Given original indices in sorted-output order (e.g. `[3, 0, 1, 2]` for
/// `#4,#1,#2,#3`), returns which new positions belong to one longest
/// increasing subsequence. Those tracks only shifted as a block; everything
/// else is a relative move.
Set<int> relativeStablePositions(List<int> originalIndicesInSortedOrder) {
  final n = originalIndicesInSortedOrder.length;
  if (n == 0) return {};

  // lengths[i] = LIS length ending at i; prev[i] = previous index in that LIS
  final lengths = List<int>.filled(n, 1);
  final prev = List<int>.filled(n, -1);

  var bestEnd = 0;
  var bestLen = 1;

  for (var i = 0; i < n; i++) {
    for (var j = 0; j < i; j++) {
      if (originalIndicesInSortedOrder[j] < originalIndicesInSortedOrder[i] &&
          lengths[j] + 1 > lengths[i]) {
        lengths[i] = lengths[j] + 1;
        prev[i] = j;
      }
    }
    if (lengths[i] > bestLen) {
      bestLen = lengths[i];
      bestEnd = i;
    }
  }

  final stable = <int>{};
  for (var i = bestEnd; i != -1; i = prev[i]) {
    stable.add(i);
  }
  return stable;
}
