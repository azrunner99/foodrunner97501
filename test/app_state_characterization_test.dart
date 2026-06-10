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

  group('Restart persistence', () {
    test('an in-progress shift is restored after an app restart', () async {
      await withClock(Clock.fixed(_lunchTime), () async {
        // First session: start a lunch shift and record some runs.
        final app1 = AppState();
        await app1.addServer('A');
        await app1.addServer('B');
        final ids = {for (final s in app1.servers) s.name: s.id};
        app1.setTodayPlan([ids['A']!, ids['B']!], [ids['A']!, ids['B']!]);
        app1.forceStartCurrentShift();
        app1.increment(ids['A']!);
        app1.increment(ids['A']!);
        app1.increment(ids['B']!);
        // Let fire-and-forget persistence flush to the (mock) store.
        await Future<void>.delayed(const Duration(milliseconds: 10));
        app1.dispose();

        // Second session (simulated restart): a fresh AppState over the same
        // storage should restore the live counts rather than zeroing them.
        final app2 = AppState();
        await app2.load();

        expect(app2.shiftActive, isTrue);
        expect(app2.shiftType, 'Lunch');
        expect(app2.currentCounts[ids['A']!], 2);
        expect(app2.currentCounts[ids['B']!], 1);
        expect(app2.workingServerIds, {ids['A']!, ids['B']!});
        app2.dispose();
      });
    });

    test('a finalized shift leaves nothing to restore', () async {
      // After closing time, so the clock won't auto-start a new shift on reload
      // (that would be correct behavior, but it would obscure what we're testing
      // here: that finalizing clears the persisted snapshot).
      final afterClose = DateTime(2026, 1, 5, 23, 30);
      await withClock(Clock.fixed(afterClose), () async {
        final app1 = AppState();
        await app1.addServer('A');
        final aId = app1.servers.single.id;
        app1.setTodayPlan([aId], [aId]);
        app1.forceStartCurrentShift();
        app1.increment(aId);
        await app1.endCurrentShiftWithPin('5520'); // finalizes + clears snapshot
        await Future<void>.delayed(const Duration(milliseconds: 10));
        app1.dispose();

        final app2 = AppState();
        await app2.load();
        expect(app2.shiftActive, isFalse);
        expect(app2.currentCounts[aId] ?? 0, 0);
        app2.dispose();
      });
    });
  });

  group('Roster edits during a shift', () {
    test('re-saving the roster during the transition does not reset counts',
        () async {
      // 16:00 is inside the default 15:30-17:00 transition window.
      await withClock(Clock.fixed(DateTime(2026, 1, 5, 16, 0)), () async {
        final app = AppState();
        await app.addServer('A'); // lunch-only
        await app.addServer('B'); // both shifts
        await app.addServer('C'); // dinner-only
        final ids = {for (final s in app.servers) s.name: s.id};
        app.setTodayPlan([ids['A']!, ids['B']!], [ids['B']!, ids['C']!]);

        expect(app.shiftActive, isTrue);
        // All three are on the floor during the transition window.
        app.increment(ids['A']!);
        app.increment(ids['A']!);
        app.increment(ids['B']!);
        app.increment(ids['C']!);
        expect(app.currentCounts[ids['A']!], 2);

        // Manager re-saves the SAME roster mid-transition. Nothing resets.
        app.setTodayPlan([ids['A']!, ids['B']!], [ids['B']!, ids['C']!]);
        expect(app.currentCounts[ids['A']!], 2);
        expect(app.currentCounts[ids['B']!], 1);
        expect(app.currentCounts[ids['C']!], 1);
      });
    });

    test('removing a server mid-lunch keeps their runs in the record',
        () async {
      await withClock(Clock.fixed(_lunchTime), () async {
        final app = AppState();
        await app.addServer('A');
        await app.addServer('B');
        final ids = {for (final s in app.servers) s.name: s.id};
        app.setTodayPlan([ids['A']!, ids['B']!], [ids['A']!, ids['B']!]);
        app.forceStartCurrentShift();
        app.increment(ids['A']!);
        app.increment(ids['B']!);
        app.increment(ids['B']!); // B has 2
        expect(app.currentCounts[ids['B']!], 2);

        // B clocks out: manager removes them from the roster.
        app.setTodayPlan([ids['A']!], [ids['A']!]);
        expect(app.workingServerIds.contains(ids['B']!), isFalse,
            reason: 'B is off the floor');
        expect(app.increment(ids['B']!), isNull, reason: 'B can no longer tap');
        expect(app.currentCounts[ids['B']!], 2,
            reason: 'B\'s runs are not erased');

        // Ending the shift records B's runs; totals and profile stay in sync.
        await app.endCurrentShiftWithPin('5520');
        expect(app.totals[ids['B']!], 2);
        expect(app.profiles[ids['B']!]!.allTimeRuns, 2);
      });
    });
  });

  group('Archiving and deleting servers', () {
    test('archiving hides a server from the active list but keeps it restorable',
        () async {
      await withClock(Clock.fixed(_lunchTime), () async {
        final app = AppState();
        await app.addServer('A');
        await app.addServer('B');
        final ids = {for (final s in app.allServers) s.name: s.id};

        expect(await app.archiveServer(ids['B']!, pin: '0000'), isFalse);
        expect(await app.archiveServer(ids['B']!, pin: '5520'), isTrue);

        expect(app.servers.map((s) => s.name).toList(), ['A']);
        expect(app.allServers.length, 2);
        expect(app.isActiveServer(ids['B']!), isFalse);

        expect(await app.restoreServer(ids['B']!, pin: '5520'), isTrue);
        expect(app.servers.map((s) => s.name).toList()..sort(), ['A', 'B']);
        expect(app.isActiveServer(ids['B']!), isTrue);
      });
    });

    test('archiving removes the server from the active shift and roster',
        () async {
      await withClock(Clock.fixed(_lunchTime), () async {
        final app = AppState();
        await app.addServer('A');
        await app.addServer('B');
        final ids = {for (final s in app.allServers) s.name: s.id};
        app.setTodayPlan([ids['A']!, ids['B']!], [ids['A']!, ids['B']!]);
        app.forceStartCurrentShift();
        app.increment(ids['B']!);
        expect(app.workingServerIds.contains(ids['B']!), isTrue);

        await app.archiveServer(ids['B']!, pin: '5520');
        expect(app.workingServerIds.contains(ids['B']!), isFalse);
        expect(app.increment(ids['B']!), isNull);
        expect(app.todayPlan!.lunchRoster.contains(ids['B']!), isFalse);
      });
    });

    test('deleting a server purges them and clears their history entries',
        () async {
      await withClock(Clock.fixed(_lunchTime), () async {
        final app = AppState();
        await app.addServer('A');
        final aId = app.servers.single.id;
        app.setTodayPlan([aId], [aId]);
        app.forceStartCurrentShift();
        app.increment(aId);
        await app.endCurrentShiftWithPin('5520');
        expect(app.history, isNotEmpty);

        expect(await app.removeServer(aId, pin: '5520'), isTrue);
        expect(app.allServers, isEmpty);
        expect(app.totals[aId] ?? 0, 0);
        expect(app.history.every((r) => !r.counts.containsKey(aId)), isTrue);
      });
    });
  });
}
