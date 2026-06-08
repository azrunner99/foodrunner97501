// Characterization test for the lunch->dinner shift transition.
//
// This is the fragile, "do not modify" logic from TRANSITION_PROTECTION.md.
// It is driven by AppState's 30-second periodic ticker comparing the wall
// clock against the day plan's transition window. We pin today's behavior so
// the engine can be redesigned safely in Phase 3.
//
// Technique: AppState reads `clock.now()`, and `package:fake_async` overrides
// that clock — so elapsing fake time both advances the clock AND fires the
// periodic ticker, deterministically reproducing the transition.

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bjs_food_runs/app_state.dart';
import 'package:bjs_food_runs/storage.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test('lunch->dinner transition: lunch-only removed, both reset, '
      'dinner-only preserved', () {
    // Monday 14:00 — open, lunch shift, before the 15:30 dinner switch.
    final start = DateTime(2026, 1, 5, 14, 0);

    FakeAsync(initialTime: start).run((async) {
      // Storage.init() is synchronous in effect (assigns boxes, no awaits).
      Storage.init();

      final app = AppState();
      app.load(); // starts the periodic ticker after its async storage reads
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 1));

      // Roster: lunch [A, B], dinner [B, C].
      //   A = lunch-only  -> removed at dinner
      //   B = both shifts  -> reset to 0 at dinner
      //   C = dinner-only  -> counts preserved through transition
      app.addServer('A');
      app.addServer('B');
      app.addServer('C');
      async.flushMicrotasks();
      final id = {for (final s in app.servers) s.name: s.id};

      app.setTodayPlan([id['A']!, id['B']!], [id['B']!, id['C']!]);
      async.flushMicrotasks();
      expect(app.shiftActive, isTrue, reason: 'lunch shift should auto-start');
      expect(app.shiftType, 'Lunch');

      // Lunch runs for A and B.
      for (var i = 0; i < 5; i++) {
        app.increment(id['A']!);
      }
      for (var i = 0; i < 3; i++) {
        app.increment(id['B']!);
      }
      expect(app.currentCounts[id['A']!], 5);
      expect(app.currentCounts[id['B']!], 3);

      // Move into the transition window (15:45) and bring the dinner-only
      // server C onto the floor, the way a manager toggling to dinner would.
      async.elapse(const Duration(minutes: 105));
      app.updateActiveRoster([id['A']!, id['B']!, id['C']!],
          preserveExistingCounts: true);
      for (var i = 0; i < 4; i++) {
        app.increment(id['C']!);
      }
      expect(app.currentCounts[id['C']!], 4);

      // Cross the transition end (17:00); the ticker finalizes the handoff.
      async.elapse(const Duration(minutes: 80));

      expect(app.shiftType, 'Dinner', reason: 'should have switched to dinner');
      expect(app.currentCounts.containsKey(id['A']!), isFalse,
          reason: 'lunch-only A is removed');
      expect(app.currentCounts[id['B']!], 0,
          reason: 'both-shift B resets to 0');
      expect(app.currentCounts[id['C']!], 4,
          reason: 'dinner-only C keeps its transition counts');
      expect(app.workingServerIds, {id['B']!, id['C']!});

      app.dispose(); // cancel the ticker before leaving fake time
    });
  });

  test('dinner-only servers can log runs during the transition window '
      'without a manual toggle', () {
    final start = DateTime(2026, 1, 5, 14, 0);

    FakeAsync(initialTime: start).run((async) {
      Storage.init();
      final app = AppState();
      app.load();
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 1));

      app.addServer('A'); // lunch-only
      app.addServer('B'); // both shifts
      app.addServer('C'); // dinner-only
      async.flushMicrotasks();
      final id = {for (final s in app.servers) s.name: s.id};

      app.setTodayPlan([id['A']!, id['B']!], [id['B']!, id['C']!]);
      async.flushMicrotasks();
      expect(app.shiftActive, isTrue);

      // Before the transition window the dinner-only server isn't on the floor.
      expect(app.increment(id['C']!), isNull);
      expect(app.currentCounts[id['C']!] ?? 0, 0);

      // Enter the transition window (15:45). The ticker should put the dinner
      // crew on the floor automatically — no toggle required.
      async.elapse(const Duration(minutes: 105));
      expect(app.workingServerIds.contains(id['C']!), isTrue);

      app.increment(id['C']!);
      expect(app.currentCounts[id['C']!], 1);
      // The lunch crew can still log runs during the overlap.
      app.increment(id['A']!);
      expect(app.currentCounts[id['A']!], 1);

      app.dispose();
    });
  });
}
