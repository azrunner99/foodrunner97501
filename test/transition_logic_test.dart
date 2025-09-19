import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_runs_counter/app_state.dart';
import 'package:food_runs_counter/models.dart';
import 'package:food_runs_counter/storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Transition Logic Tests', () {
    late AppState app;

    setUp(() async {
      // Use in-memory SharedPreferences and init Storage used by AppState
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await Storage.init();
      app = AppState();

      // Keep tests independent of current time by making business hours always-open.
      final alwaysOpen = WeeklyHours(
        openMinutes: {for (var d = 1; d <= 7; d++) d: 0},
        closeMinutes: {for (var d = 1; d <= 7; d++) d: 24 * 60},
      );
      app.setWeeklyHours(alwaysOpen);

      // Disable gamification to avoid award-side effects in isolated tests
      final s = app.settings..gamificationEnabled = false;
      await app.saveSettings(s);
    });

    Future<void> addRuns(String id, int n) async {
      for (var i = 0; i < n; i++) {
        app.increment(id);
        // Let async persistence complete to avoid concurrent modification
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    }

    test('Lunch [A,B] -> Dinner [B,C]: A removed, B reset, C preserved', () async {
      // Rosters
      final lunch = ['server_a', 'server_b'];
      final dinner = ['server_b', 'server_c'];

      // Set today plan (also primes transition minutes from settings)
      app.setTodayPlan(lunch, dinner);

      // Start a Lunch shift explicitly using a past midday start time to ensure Lunch
      final midday = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 12, 0);
      await app.startNewShift(label: 'Lunch', workingIds: lunch, start: midday);

      // Simulate lunch clicks
      await addRuns('server_a', 5);
      await addRuns('server_b', 8);

      // Simulate transition period by adding dinner-only C to working set, preserving counts
      app.updateActiveRoster([...lunch, 'server_c'], preserveExistingCounts: true);
      await addRuns('server_c', 3);

      // Force transition end relative to current clock by updating settings to past transitionEnd
      final now = DateTime.now();
      final m = now.hour * 60 + now.minute;
      final newSettings = app.settings
        ..transitionStartMinutes = m - 2
        ..transitionEndMinutes = m - 1;

  await app.saveSettings(newSettings);
  // Explicitly trigger transition logic based on updated plan timings
  app.setTodayPlan(lunch, dinner);
  await Future<void>.delayed(const Duration(milliseconds: 150)); // allow state settle

      // Expectations after transition:
      // - server_a: removed (lunch-only)
      // - server_b: reset to 0 (both-shift)
      // - server_c: preserves transition counts (3)

      final counts = app.currentCounts;
      final working = app.workingServerIds;

      expect(working.contains('server_a'), isFalse, reason: 'Lunch-only A should be removed at dinner');
      expect(working.contains('server_b'), isTrue, reason: 'Both-shift B should be active at dinner');
      expect(working.contains('server_c'), isTrue, reason: 'Dinner-only C should be active at dinner');

      expect(counts['server_b'] ?? -1, 0, reason: 'Both-shift B must reset to 0 at dinner start');
      expect(counts['server_c'] ?? -1, 3, reason: 'Dinner-only C must preserve transition counts');
    });
  });
}
