/// Pure ranking helpers for leaderboards (current shift or all-time).
///
/// No Flutter / AppState coupling, so it is fully unit-testable. The animated
/// leaderboard UI is built on top of this.

class LeaderboardEntry {
  final String serverId;
  final int value;
  final int rank; // 1-based; ties share a rank (standard competition ranking)
  const LeaderboardEntry({required this.serverId, required this.value, required this.rank});
}

/// Ranks [values] (id → score) descending.
///
/// - Ties share a rank and the next rank skips (1, 2, 2, 4).
/// - Ties are ordered by id so output is stable.
/// - [include] optionally restricts/extends the set; ids missing from [values]
///   count as 0 (useful to rank an entire working roster).
List<LeaderboardEntry> rankBy(Map<String, int> values, {Iterable<String>? include}) {
  final ids = (include ?? values.keys).toSet().toList()
    ..sort((a, b) {
      final va = values[a] ?? 0;
      final vb = values[b] ?? 0;
      if (vb != va) return vb.compareTo(va);
      return a.compareTo(b);
    });

  final out = <LeaderboardEntry>[];
  var rank = 0;
  var seen = 0;
  int? lastVal;
  for (final id in ids) {
    final v = values[id] ?? 0;
    seen++;
    if (lastVal == null || v != lastVal) {
      rank = seen;
      lastVal = v;
    }
    out.add(LeaderboardEntry(serverId: id, value: v, rank: rank));
  }
  return out;
}

/// The 1-based rank of [id] within [values], or null if not present. Honors the
/// same tie rules as [rankBy].
int? rankOf(String id, Map<String, int> values, {Iterable<String>? include}) {
  final set = (include ?? values.keys).toSet();
  if (!set.contains(id)) return null;
  for (final e in rankBy(values, include: set)) {
    if (e.serverId == id) return e.rank;
  }
  return null;
}
