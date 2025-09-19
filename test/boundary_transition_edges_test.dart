import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_runs_counter/app_state.dart';
import 'package:food_runs_counter/models.dart';
import 'package:food_runs_counter/storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Transition boundary tests', () {
    late AppState app;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await Storage.init();
      app = AppState();

      // Always-open business hours to isolate transition behavior
      final alwaysOpen = WeeklyHours(
        openMinutes: {for (var d = 1; d <= 7; d++) d: 0},
        closeMinutes: {for (var d = 1; d <= 7; d++) d: 24 * 60},
      );
      app.setWeeklyHours(alwaysOpen);

      final s = app.settings..gamificationEnabled = false;
      await app.saveSettings(s);
    });

    Future<void> addRuns(String id, int n) async {
      for (var i = 0; i < n; i++) {
        app.increment(id);
        await Future<void>.delayed(const Duration(milliseconds: 3));
      }
    }

    test('Just before transitionStart allows only lunch roster', () async {
      final lunch = ['A', 'B'];
      final dinner = ['B', 'C'];
      app.setTodayPlan(lunch, dinner);

      // Start Lunch explicitly
      final noon = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 12, 0);
      await app.startNewShift(label: 'Lunch', workingIds: lunch, start: noon);

      // Move transitionStart to now+1, End to now+2 -> "before transition"
      final now = DateTime.now();
      final m = now.hour * 60 + now.minute;
      final newSettings = app.settings
        ..transitionStartMinutes = m + 1
        ..transitionEndMinutes = m + 2;
      await app.saveSettings(newSettings);
      app.setTodayPlan(lunch, dinner);

      // Try to add C (dinner-only) -> should not be in working set before transition
      app.updateActiveRoster([...lunch, 'C'], preserveExistingCounts: true);
      await addRuns('C', 1);

      expect(app.workingServerIds.contains('C'), isFalse,
          reason: 'Dinner-only C must not be active before transitionStart');
    });

    test('At transitionEnd: switch to dinner, reset both-shift, preserve dinner-only', () async {
      final lunch = ['A', 'B'];
      final dinner = ['B', 'C'];
      app.setTodayPlan(lunch, dinner);

      // Start Lunch
      final noon = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 12, 0);
      await app.startNewShift(label: 'Lunch', workingIds: lunch, start: noon);

      // Simulate transition period: include C and give it some counts
      app.updateActiveRoster([...lunch, 'C'], preserveExistingCounts: true);
      await addRuns('A', 2);
      await addRuns('B', 3);
      await addRuns('C', 4);

      // Set transitionEnd to now (and start just before) to force immediate switch
      final now = DateTime.now();
      final m = now.hour * 60 + now.minute;
      final newSettings = app.settings
        ..transitionStartMinutes = m - 1
        ..transitionEndMinutes = m; // boundary
      await app.saveSettings(newSettings);
      app.setTodayPlan(lunch, dinner);
      await Future<void>.delayed(const Duration(milliseconds: 80));

      final working = app.workingServerIds;
      final counts = app.currentCounts;

      expect(working.contains('A'), isFalse, reason: 'Lunch-only A removed at dinner');
      expect(working.contains('B'), isTrue, reason: 'Both-shift B remains but resets');
      expect(working.contains('C'), isTrue, reason: 'Dinner-only C remains');

      expect(counts['B'], 0, reason: 'B resets to 0 at dinner start');
      expect(counts['C'], 4, reason: 'C preserves its transition counts');
    });
  });
}
