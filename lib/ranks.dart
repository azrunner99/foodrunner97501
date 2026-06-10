/// Progression rank tiers spanning the 1–150 level XP curve.
///
/// Pure Dart (no Flutter import) so it is fully unit-testable. Colors are stored
/// as ARGB ints; the UI wraps them in `Color(...)`.
class RankTier {
  final String name;
  final int minLevel; // inclusive
  final int maxLevel; // inclusive
  final int color; // ARGB
  const RankTier(this.name, this.minLevel, this.maxLevel, this.color);
}

/// Ordered low → high. Must cover 1..150 with no gaps or overlaps.
const List<RankTier> rankTiers = [
  RankTier('Bronze', 1, 14, 0xFFCD7F32),
  RankTier('Silver', 15, 29, 0xFFB8C4D0),
  RankTier('Gold', 30, 49, 0xFFFFC53D),
  RankTier('Platinum', 50, 74, 0xFF45E0C8),
  RankTier('Diamond', 75, 109, 0xFF2DB7FF),
  RankTier('Master', 110, 149, 0xFF8B5CF6),
  RankTier('Legend', 150, 150, 0xFFFF4D8D),
];

/// The tier containing [level] (clamped to 1..150).
RankTier tierForLevel(int level) {
  final l = level.clamp(1, 150);
  for (final t in rankTiers) {
    if (l >= t.minLevel && l <= t.maxLevel) return t;
  }
  return rankTiers.last;
}

/// 0..1 progress through the current tier by level.
double tierProgress(int level) {
  final t = tierForLevel(level);
  final span = t.maxLevel - t.minLevel;
  if (span <= 0) return 1.0;
  final l = level.clamp(t.minLevel, t.maxLevel);
  return ((l - t.minLevel) / span).clamp(0.0, 1.0);
}

/// The next tier above [level], or null if already in the top tier.
RankTier? nextTier(int level) {
  final t = tierForLevel(level);
  final i = rankTiers.indexOf(t);
  return (i >= 0 && i < rankTiers.length - 1) ? rankTiers[i + 1] : null;
}

/// Levels remaining until the next tier (0 if already in the top tier).
int levelsToNextTier(int level) {
  final next = nextTier(level);
  if (next == null) return 0;
  return (next.minLevel - level.clamp(1, 150)).clamp(0, 150);
}

/// Whether moving from [fromLevel] to [toLevel] crosses into a new tier.
bool isTierUp(int fromLevel, int toLevel) =>
    tierForLevel(toLevel).name != tierForLevel(fromLevel).name && toLevel > fromLevel;
