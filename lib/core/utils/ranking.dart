/// Produces dense ranks for scores already sorted from highest to lowest.
/// Example: [10, 10, 10, 8, 8, 3] becomes [1, 1, 1, 2, 2, 3].
List<int> denseRanks(Iterable<int> sortedScores) {
  final ranks = <int>[];
  int? previous;
  var rank = 0;
  for (final score in sortedScores) {
    if (previous == null || score != previous) {
      rank++;
      previous = score;
    }
    ranks.add(rank);
  }
  return List<int>.unmodifiable(ranks);
}
