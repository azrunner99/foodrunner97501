import 'dart:math';
import 'package:flutter/foundation.dart';

enum PowerUp { none, doublePoint, bonusFive }

PowerUp rollPowerUp(Random r) {
  final n = r.nextInt(100);
  if (n < 5) return PowerUp.bonusFive;
  if (n < 20) return PowerUp.doublePoint;
  return PowerUp.none;
}

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

int levelForPoints(int points) {
  if (points < 100) return 1;
  if (points < 250) return 2;
  if (points < 500) return 3;
  if (points < 1000) return 4;
  if (points < 2000) return 5;
  return 6;
}

int nextLevelTarget(int points) {
  if (points < 100) return 100;
  if (points < 250) return 250;
  if (points < 500) return 500;
  if (points < 1000) return 1000;
  if (points < 2000) return 2000;
  return 999999;
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