/// Level-gated cosmetic unlocks (avatars / banners).
///
/// Intentionally simple and tunable, and pure Dart so it is fully testable. A
/// base set is available immediately; one more cosmetic unlocks every
/// [levelsPerUnlock] levels. The UI applies this to the avatar/banner pickers
/// (lock + "next unlock at Lvl X").
const int unlocksAtStart = 6; // available from level 1
const int levelsPerUnlock = 3; // one more unlock every N levels

/// How many cosmetic slots are unlocked at [level], capped at [total].
int unlockedCount(int level, int total) {
  final l = level < 1 ? 1 : level;
  final n = unlocksAtStart + ((l - 1) ~/ levelsPerUnlock);
  return n.clamp(0, total);
}

/// Whether the cosmetic at [index] (0-based, in unlock order) is unlocked at
/// [level].
bool isUnlocked(int index, int level, int total) => index < unlockedCount(level, total);

/// The level at which the cosmetic at [index] (0-based) unlocks.
int unlockLevel(int index) {
  if (index < unlocksAtStart) return 1;
  return 1 + (index - unlocksAtStart + 1) * levelsPerUnlock;
}

/// The next still-locked cosmetic index at [level], or null if all [total] are
/// unlocked. Useful for a "next unlock at Lvl X" hint.
int? nextLockedIndex(int level, int total) {
  final c = unlockedCount(level, total);
  return c < total ? c : null;
}

/// The level needed to unlock the next still-locked cosmetic, or null if all are
/// unlocked.
int? nextUnlockLevel(int level, int total) {
  final next = nextLockedIndex(level, total);
  return next == null ? null : unlockLevel(next);
}
