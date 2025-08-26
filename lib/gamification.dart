
enum PowerUp { none, doublePoint, bonusFive }

class AchievementDef {
  final String id;
  final String title;
  final String description;
  final int points;
  final bool repeatable;

  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    this.repeatable = false,
  });
}

const achievementsCatalog = <AchievementDef>[
  AchievementDef(
    id: 'full_hands',
    title: 'Full Hands!',
    description: 'Tap the button 2 times in quick succession (3 seconds).',
    points: 4,
    repeatable: true,
  ),
  AchievementDef(
    id: 'first_run',
    title: 'First Run!',
    description: 'Completed your first food run.',
    points: 10,
  ),
  AchievementDef(
    id: 'first_run_today',
    title: 'First Run Today',
    description: 'First run of the day.',
    points: 5,
    repeatable: true,
  ),
  AchievementDef(
    id: 'three_streak',
    title: '3 Streak',
    description: '3 runs in a row without missing.',
    points: 10,
  ),
  AchievementDef(
    id: 'five_streak',
    title: '5 Streak',
    description: '5 runs in a row without missing.',
    points: 20,
  ),
  AchievementDef(
    id: 'ten_in_shift',
    title: '10 in a Shift',
    description: '10 runs in a single shift.',
    points: 15,
  ),
  AchievementDef(
    id: 'twenty_in_shift',
    title: '20 in a Shift',
    description: '20 runs in a single shift.',
    points: 30,
  ),
  AchievementDef(
    id: 'night_owl',
    title: 'Night Owl',
    description: 'Run food after 11 PM.',
    points: 10,
    repeatable: true,
  ),
  AchievementDef(
    id: 'lunch_peak_10',
    title: 'Lunch Peak 10',
    description: '10 runs during lunch peak.',
    points: 10,
    repeatable: true,
  ),
  AchievementDef(
    id: 'dinner_peak_10',
    title: 'Dinner Peak 10',
    description: '10 runs during dinner peak.',
    points: 10,
    repeatable: true,
  ),
  AchievementDef(
    id: 'lunch_closer_8',
    title: 'Lunch Closer 8',
    description: '8 runs during lunch closing.',
    points: 10,
    repeatable: true,
  ),
  AchievementDef(
    id: 'dinner_closer_8',
    title: 'Dinner Closer 8',
    description: '8 runs during dinner closing.',
    points: 10,
    repeatable: true,
  ),
  AchievementDef(
    id: 'fifty_all_time',
    title: '50 All Time',
    description: '50 runs all time.',
    points: 25,
  ),
  AchievementDef(
    id: 'hundred_all_time',
    title: '100 All Time',
    description: '100 runs all time.',
    points: 50,
  ),
  AchievementDef(
    id: 'mvp',
    title: 'MVP',
    description: 'Most runs in a shift.',
    points: 20,
    repeatable: true,
  ),
  AchievementDef(
    id: 'team_goal',
    title: 'Team Goal',
    description: 'Team met the shift goal.',
    points: 10,
    repeatable: true,
  ),
];

// Progressive XP curve for levels 1-150, designed for years of play
// Early levels are quick, but high levels require much more XP
const int maxLevel = 150;
final List<int> xpTable = List.generate(maxLevel + 2, (level) {
  if (level <= 1) return 0;
  if (level == 2) return 30; // Level 2: 30 runs
  if (level == 3) return 80; // Level 3: 80 runs
  if (level == 4) return 200; // Level 4: 200 runs
  if (level == 5) return 350; // Level 5: 350 runs
  if (level <= 10) {
    // Levels 6-10: curve up
    return (350 + 100 * (level - 5) + (level * level * 2)).toInt();
  } else if (level <= 30) {
    // Levels 11-30: moderate
    return (1000 + 150 * (level - 10) + (level * level * 4)).toInt();
  } else if (level <= 60) {
    // Levels 31-60: hard
    return (6000 + 400 * (level - 30) + (level * level * 8)).toInt();
  } else {
    // Levels 61-150: very steep, for years of play
    return (25000 + 1000 * (level - 60) + (level * level * 20)).toInt();
  }
});

int levelForPoints(int points) {
  for (int lvl = 1; lvl <= maxLevel; lvl++) {
    if (points < xpTable[lvl]) return lvl;
  }
  return maxLevel;
}

int nextLevelTarget(int points) {
  int lvl = levelForPoints(points);
  if (lvl > maxLevel) return xpTable[maxLevel];
  return xpTable[lvl];
}

class GamificationSettings {
  int transitionStartMinutes;
  int transitionEndMinutes;

  GamificationSettings({
    this.transitionStartMinutes = 15 * 60 + 30, // Default 3:30 PM
    this.transitionEndMinutes = 17 * 60,        // Default 5:00 PM
  });

  Map<String, dynamic> toMap() => {
    'transitionStartMinutes': transitionStartMinutes,
    'transitionEndMinutes': transitionEndMinutes,
  };

  static GamificationSettings fromMap(Map<String, dynamic> m) => GamificationSettings(
    transitionStartMinutes: m['transitionStartMinutes'] ?? 15 * 60 + 30,
    transitionEndMinutes: m['transitionEndMinutes'] ?? 17 * 60,
  );
}