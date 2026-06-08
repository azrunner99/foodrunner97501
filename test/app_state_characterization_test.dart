// Characterization tests for AppState.
//
// These pin the *current* behavior of the scoring engine, shift lifecycle, and
// time-window helpers so the fragile logic can be refactored safely later
// (Phase 3). They favor robust structural/relative assertions over brittle
// exact-XP arithmetic where the exact numbers aren't the point.
//
// Time is controlled via `package:clock` (AppState reads `clock.now()`), so
// these tests are deterministic regardless of when CI runs.

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bjs_food_runs/app_state.dart';
import 'package:bjs_food_runs/storage.dart';

/// A weekday, mid-lunch but outside any peak/closer window (13:45), so basic
/// scoring isn't entangled with bonus windows. 2026-01-05 is a Monday.
final _lunchTime = DateTime(2026, 1, 5, 13, 45);

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  group('Time-window helpers', () {
    final app = AppState();

    test('lunch peak window is [11:30, 13:30)', () {
      expect(app.isLunchPeak(DateTime(2026, 1, 5, 12, 0)), isTrue);
      expect(app.isLunchPeak(DateTime(2026, 1, 5, 11, 29)), isFalse);
      expect(app.isLunchPeak(DateTime(2026, 1, 5, 13, 30)), isFalse);
    });

    test('dinner peak window is [17:30, 19:30)', () {
      expect(app.isDinnerPeak(DateTime(2026, 1, 5, 18, 0)), isTrue);
      expect(app.isDinnerPeak(DateTime(2026, 1, 5, 17, 29)), isFalse);
      expect(app.isDinnerPeak(DateTime(2026, 1, 5, 19, 30)), isFalse);
    });

    test('lunch/dinner closer windows', () {
      expect(app.isLunchCloser(DateTime(2026, 1, 5, 14, 30)), isTrue);
      expect(app.isLunchCloser(DateTime(2026, 1, 5, 15, 30)), isFalse);
      expect(app.isDinnerCloser(DateTime(2026, 1, 5, 22, 0)), isTrue);
      expect(app.isDinnerCloser(DateTime(2026, 1, 5, 23, 0)), isFalse);
    });

    test('intended shift flips to Dinner at 15:30', () {
      expect(app.currentIntendedShiftType(DateTime(2026, 1, 5, 12, 0)), 'Lunch');
      expect(app.currentIntendedShiftType(DateTime(2026, 1, 5, 15, 29)), 'Lunch');
      expect(app.currentIntendedShiftType(DateTime(2026, 1, 5, 16, 0)), 'Dinner');
    });

    test('isOpenNow respects default weekday hours', () async {
      await withClock(Clock.fixed(DateTime(2026, 1, 5, 12, 0)), () async {
        expect(AppState().isOpenNow, isTrue);
      });
      await withClock(Clock.fixed(DateTime(2026, 1, 5, 2, 0)), () async {
        expect(AppState().isOpenNow, isFalse);
      });
    });
  });

  group('Shift lifecycle & scoring', () {
    test('a run is blocked when no shift is active', () async {
      final app = AppState();
      await app.addServer('A');
      final aId = app.servers.single.id;

      expect(app.increment(aId), isNull);
      expect(app.currentCounts[aId] ?? 0, 0);
    });

    test('a run is blocked for a server not on the active roster', () async {
      await withClock(Clock.fixed(_lunchTime), () async {
        final app = AppState();
        await app.addServer('A');
        await app.addServer('B');
        final ids = {for (final s in app.servers) s.name: s.id};
        // Only A is rostered.
        app.setTodayPlan([ids['A']!], [ids['A']!]);
        app.forceStartCurrentShift();

        expect(app.increment(ids['B']!), isNull);
        expect(app.currentCounts[ids['B']!] ?? 0, 0);
      });
    });

    test('a run increments count, all-time runs, and points', () async {
      await withClock(Clock.fixed(_lunchTime), () async {
        final app = AppState();
        await app.addServer('A');
        final aId = app.servers.single.id;
        app.setTodayPlan([aId], [aId]);
        app.forceStartCurrentShift();

        expect(app.shiftActive, isTrue);
        final pointsBefore = app.profiles[aId]!.points;

        app.increment(aId);

        expect(app.currentCounts[aId], 1);
        expect(app.profiles[aId]!.allTimeRuns, 1);
        expect(app.profiles[aId]!.points, greaterThan(pointsBefore));
        expect(app.lastRunServerId, aId);
      });
    });

    test('two rapid runs earn the Full Hands bonus (more than two singles)',
        () async {
      await withClock(Clock.fixed(_lunchTime), () async {
        // Two taps at the same instant => within the 3s Full Hands window.
        final fast = AppState();
        await fast.addServer('A');
        final fastId = fast.servers.single.id;
        fast.setTodayPlan([fastId], [fastId]);
        fast.forceStartCurrentShift();
        fast.increment(fastId);
        fast.increment(fastId);

        expect(fast.currentCounts[fastId], 2);
        // Full Hands is a repeatable badge, recorded per-day in
        // repeatEarnedDates (keyed 'full_hands_<ymd>'), not in achievements.
        expect(
          fast.profiles[fastId]!.repeatEarnedDates
              .any((k) => k.startsWith('full_hands')),
          isTrue,
        );
      });
    });

    test('decrement lowers the count and resets the streak', () async {
      await withClock(Clock.fixed(_lunchTime), () async {
        final app = AppState();
        await app.addServer('A');
        final aId = app.servers.single.id;
        app.setTodayPlan([aId], [aId]);
        app.forceStartCurrentShift();

        app.increment(aId);
        app.increment(aId);
        expect(app.currentCounts[aId], 2);

        app.decrement(aId);
        expect(app.currentCounts[aId], 1);
      });
    });

    test('ending a shift requires the admin PIN and finalizes to history',
        () async {
      await withClock(Clock.fixed(_lunchTime), () async {
        final app = AppState();
        await app.addServer('A');
        final aId = app.servers.single.id;
        app.setTodayPlan([aId], [aId]);
        app.forceStartCurrentShift();
        app.increment(aId);

        expect(await app.endCurrentShiftWithPin('0000'), isFalse);
        expect(app.shiftActive, isTrue);

        expect(await app.endCurrentShiftWithPin('5520'), isTrue);
        expect(app.shiftActive, isFalse);
        expect(app.history, isNotEmpty);
        expect(app.totals[aId], greaterThan(0));
      });
    });

    test('a pizookie run counts as a run and adds pizookie stats + points',
        () async {
      await withClock(Clock.fixed(_lunchTime), () async {
        final app = AppState();
        await app.addServer('A');
        final aId = app.servers.single.id;
        app.setTodayPlan([aId], [aId]);
        app.forceStartCurrentShift();

        final pointsBefore = app.profiles[aId]!.points;
        app.incrementPizookie(aId);

        expect(app.currentCounts[aId], 1);
        expect(app.currentPizookieCounts[aId], 1);
        expect(app.profiles[aId]!.pizookieRuns, 1);
        expect(app.profiles[aId]!.allTimeRuns, 1);
        // A pizookie is worth 25 (plus any same-tick daily badges).
        expect(app.profiles[aId]!.points, greaterThanOrEqualTo(pointsBefore + 25));
      });
    });

    test('a pizookie run is blocked when no shift is active', () async {
      final app = AppState();
      await app.addServer('A');
      final aId = app.servers.single.id;

      expect(app.incrementPizookie(aId), isNull);
      expect(app.currentCounts[aId] ?? 0, 0);
    });
  });
}
