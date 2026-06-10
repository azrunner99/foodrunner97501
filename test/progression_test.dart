import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bjs_food_runs/app_state.dart';
import 'package:bjs_food_runs/leaderboard.dart';
import 'package:bjs_food_runs/ranks.dart';
import 'package:bjs_food_runs/storage.dart';
import 'package:bjs_food_runs/unlocks.dart';

// A weekday lunch time outside any peak/closer window, so scoring is just the
// base +10 per run (deterministic). 2026-01-05 is a Monday.
final _lunchTime = DateTime(2026, 1, 5, 13, 45);

void main() {
  group('Rank tiers', () {
    test('tiers cover 1..150 with no gaps or overlaps', () {
      for (var level = 1; level <= 150; level++) {
        final matches = rankTiers.where((t) => level >= t.minLevel && level <= t.maxLevel);
        expect(matches.length, 1, reason: 'level $level should map to exactly one tier');
      }
    });

    test('tierForLevel boundaries and clamping', () {
      expect(tierForLevel(1).name, 'Bronze');
      expect(tierForLevel(14).name, 'Bronze');
      expect(tierForLevel(15).name, 'Silver');
      expect(tierForLevel(150).name, 'Legend');
      expect(tierForLevel(0).name, 'Bronze'); // clamped up
      expect(tierForLevel(999).name, 'Legend'); // clamped down
    });

    test('tierProgress is 0 at the start and 1 at the end of a tier', () {
      expect(tierProgress(15), 0.0); // start of Silver
      expect(tierProgress(29), closeTo(1.0, 1e-9)); // end of Silver
      expect(tierProgress(150), 1.0); // single-level top tier
    });

    test('nextTier / levelsToNextTier / isTierUp', () {
      expect(nextTier(1)!.name, 'Silver');
      expect(nextTier(149)!.name, 'Legend');
      expect(nextTier(150), isNull);
      expect(levelsToNextTier(1), 14); // Bronze->Silver at 15
      expect(levelsToNextTier(150), 0);
      expect(isTierUp(14, 15), isTrue);
      expect(isTierUp(15, 16), isFalse);
      expect(isTierUp(16, 15), isFalse); // not an increase
    });
  });

  group('Leaderboard ranking', () {
    test('ranks descending with competition ties (1,2,2,4)', () {
      final r = rankBy({'a': 10, 'b': 5, 'c': 5, 'd': 1});
      expect(r.map((e) => e.serverId).toList(), ['a', 'b', 'c', 'd']);
      expect(r.map((e) => e.rank).toList(), [1, 2, 2, 4]);
    });

    test('include adds missing ids as 0 and restricts the set', () {
      final r = rankBy({'a': 3}, include: ['a', 'b', 'c']);
      expect(r.firstWhere((e) => e.serverId == 'a').rank, 1);
      expect(r.where((e) => e.value == 0).length, 2);
      expect(r.length, 3);
    });

    test('rankOf honors ties and returns null when absent', () {
      final v = {'a': 10, 'b': 5, 'c': 5};
      expect(rankOf('a', v), 1);
      expect(rankOf('c', v), 2);
      expect(rankOf('z', v), isNull);
    });
  });

  group('Unlocks', () {
    test('base set is available immediately, more unlock with level', () {
      expect(unlockedCount(1, 100), unlocksAtStart);
      expect(unlockedCount(4, 100), unlocksAtStart + 1);
      expect(isUnlocked(0, 1, 100), isTrue);
      expect(isUnlocked(unlocksAtStart, 1, 100), isFalse);
      expect(isUnlocked(unlocksAtStart, 4, 100), isTrue);
    });

    test('unlockedCount is capped at total', () {
      expect(unlockedCount(999, 8), 8);
    });

    test('unlockLevel and nextUnlockLevel', () {
      expect(unlockLevel(0), 1);
      expect(unlockLevel(unlocksAtStart), 4); // first level-gated slot
      expect(nextUnlockLevel(1, 100), 4);
      expect(nextUnlockLevel(999, 8), isNull); // everything unlocked
    });
  });

  group('AppState progression events', () {
    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      await Storage.init();
    });

    test('a run that crosses a level boundary records a level-up', () async {
      await withClock(Clock.fixed(_lunchTime), () async {
        final app = AppState();
        app.settings.gamificationEnabled = false; // base +10 only, no badge XP
        await app.addServer('A');
        final aId = app.servers.single.id;
        app.setTodayPlan([aId], [aId]);
        app.forceStartCurrentShift();

        // Level 2 is 1000 XP = 100 runs at +10 each.
        for (var i = 0; i < 100; i++) {
          app.increment(aId);
        }
        expect(app.recentLevelUp, isNotNull);
        expect(app.recentLevelUp!.serverId, aId);
        expect(app.recentLevelUp!.newLevel, 2);

        app.clearRecentLevelUp();
        expect(app.recentLevelUp, isNull);
      });
    });

    test('overtaking a coworker records a pass event', () async {
      await withClock(Clock.fixed(_lunchTime), () async {
        final app = AppState();
        await app.addServer('A');
        await app.addServer('B');
        final ids = {for (final s in app.servers) s.name: s.id};
        app.setTodayPlan([ids['A']!, ids['B']!], [ids['A']!, ids['B']!]);
        app.forceStartCurrentShift();

        for (var i = 0; i < 3; i++) {
          app.increment(ids['B']!); // B = 3
        }
        app.increment(ids['A']!);
        app.increment(ids['A']!); // A = 2
        app.clearRecentPass();

        app.increment(ids['A']!); // A = 3, ties B — not a pass
        expect(app.recentPass, isNull);

        app.increment(ids['A']!); // A = 4, overtakes B
        expect(app.recentPass, isNotNull);
        expect(app.recentPass!.runnerId, ids['A']);
        expect(app.recentPass!.passedName, 'B');
      });
    });

    test('the team total crossing a milestone is recorded', () async {
      await withClock(Clock.fixed(_lunchTime), () async {
        final app = AppState();
        await app.addServer('A');
        final aId = app.servers.single.id;
        app.setTodayPlan([aId], [aId]);
        app.forceStartCurrentShift();

        for (var i = 0; i < 25; i++) {
          app.increment(aId);
        }
        expect(app.recentTeamMilestone, 25);
      });
    });

    test('the live leaderboard ranks working servers by current runs', () async {
      await withClock(Clock.fixed(_lunchTime), () async {
        final app = AppState();
        await app.addServer('A');
        await app.addServer('B');
        final ids = {for (final s in app.servers) s.name: s.id};
        app.setTodayPlan([ids['A']!, ids['B']!], [ids['A']!, ids['B']!]);
        app.forceStartCurrentShift();
        app.increment(ids['B']!);
        app.increment(ids['B']!);
        app.increment(ids['A']!);

        final board = app.currentShiftLeaderboard();
        expect(board.first.serverId, ids['B']); // B leads
        expect(board.firstWhere((e) => e.serverId == ids['B']).rank, 1);
        expect(board.firstWhere((e) => e.serverId == ids['A']).rank, 2);
      });
    });
  });
}
