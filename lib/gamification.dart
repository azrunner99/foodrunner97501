import 'dart:math';
import 'messages.dart';

class GamificationSettings {
  bool enableGamification;
  bool showTeamTotals;
  bool showGoalProgress;
  bool showMvpConfetti;
  bool showEncouragement;

  GamificationSettings({
    this.enableGamification = true,
    this.showTeamTotals = true,
    this.showGoalProgress = true,
    this.showMvpConfetti = true,
    this.showEncouragement = true,
  });

  Map<String, dynamic> toMap() => {
        'enableGamification': enableGamification,
        'showTeamTotals': showTeamTotals,
        'showGoalProgress': showGoalProgress,
        'showMvpConfetti': showMvpConfetti,
        'showEncouragement': showEncouragement,
      };

  static GamificationSettings fromMap(Map m) => GamificationSettings(
        enableGamification: (m['enableGamification'] ?? true) as bool,
        showTeamTotals: (m['showTeamTotals'] ?? true) as bool,
        showGoalProgress: (m['showGoalProgress'] ?? true) as bool,
        showMvpConfetti: (m['showMvpConfetti'] ?? true) as bool,
        showEncouragement: (m['showEncouragement'] ?? true) as bool,
      );
}

enum PowerUp { doublePoint, bonusFive, nothing }

PowerUp rollPowerUp(Random r) {
  final p = r.nextDouble();
  if (p < 0.05) return PowerUp.doublePoint; // 5%
  if (p < 0.08) return PowerUp.bonusFive;   // +5 about 3%
  return PowerUp.nothing;                    // 92%
}

class AchievementDef {
  final String id;
  final String title;
  final String description;
  final int points; // points awarded once when earned
  final bool repeatable; // true for “I ran food today!” etc.

  const AchievementDef(this.id, this.title, this.description, this.points, {this.repeatable = false});
}

// Level thresholds: deliberately slow progression
const levelThresholds = <int>[
  0,    // Level 1
  120,  // 2
  300,  // 3
  600,  // 4
  1000, // 5
  1500, // 6
  2100, // 7
  2800, // 8
  3600, // 9
  4500, // 10
];

int levelForPoints(int pts) {
  int lvl = 1;
  for (int i = 1; i < levelThresholds.length; i++) {
    if (pts >= levelThresholds[i]) lvl = i + 1;
  }
  return lvl.clamp(1, 10);
}

int nextLevelTarget(int pts) {
  for (final t in levelThresholds) {
    if (pts < t) return t;
  }
  return levelThresholds.last;
}

// Time windows for lunch/dinner peaks and tails (minutes since midnight)
bool _inWindow(DateTime t, int startMin, int endMin) {
  final m = t.hour * 60 + t.minute;
  return m >= startMin && m <= endMin;
}
bool isLunchPeak(DateTime t) => _inWindow(t, 750, 840);   // 12:30–14:00
bool isDinnerPeak(DateTime t) => _inWindow(t, 1110, 1200); // 18:30–20:00
bool isLunchCloser(DateTime t) => _inWindow(t, 840, 930);  // 14:00–15:30
bool isDinnerCloser(DateTime t) => _inWindow(t, 1200, 1440); // after 20:00

// Badges: includes repeatable daily “first run” badge
const achievementsCatalog = <AchievementDef>[
  AchievementDef('first_run_today', 'I ran food today!', 'Awarded on your first run of the day.', 10, repeatable: true),
  AchievementDef('first_run', 'First Run', 'Logged your very first run.', 20),
  AchievementDef('ten_in_shift', 'Double Digits', '10 runs in a single shift.', 25),
  AchievementDef('twenty_in_shift', 'Hustler', '20 runs in a single shift.', 40),
  AchievementDef('fifty_all_time', 'Workhorse', '50 runs all time.', 40),
  AchievementDef('hundred_all_time', 'Centurion', '100 runs all time.', 80),
  AchievementDef('lunch_peak_10', 'Lunch Rush 10', '10 runs during lunch peak (12:30–2:00) in one shift.', 50),
  AchievementDef('dinner_peak_10', 'Dinner Rush 10', '10 runs during dinner peak (6:30–8:00) in one shift.', 50),
  AchievementDef('lunch_closer_8', 'Lunch Closer', '8 runs during lunch tail (2:00–3:30) in one shift.', 35),
  AchievementDef('dinner_closer_8', 'Dinner Closer', '8 runs during dinner tail (after 8:00) in one shift.', 35),
  AchievementDef('three_streak', 'On a Roll', '3 runs in a row without a break.', 15),
  AchievementDef('five_streak', 'Steam Engine', '5 runs in a row without a break.', 25),
  AchievementDef('mvp', 'MVP', 'Top runner for a shift.', 30),
  AchievementDef('team_goal', 'Closer', 'Team hit the shift goal.', 20),
  AchievementDef('night_owl', 'Night Owl', 'Logging runs after 11 PM.', 15),
];
