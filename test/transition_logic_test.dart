import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clock/clock.dart';
import 'package:food_runs_counter/app_state.dart';
import 'package:food_runs_counter/models.dart';
import 'package:food_runs_counter/storage.dart';

/// A fake clock implementation for deterministic testing
class FakeClock extends Clock {
  DateTime _currentTime;
  
  FakeClock(this._currentTime);
  
  @override
  DateTime now() => _currentTime;
  
  void advance(Duration duration) {
    _currentTime = _currentTime.add(duration);
  }
  
  void setTime(DateTime time) {
    _currentTime = time;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Transition Logic Tests', () {
    late AppState app;
    late FakeClock fakeClock;

    setUp(() async {
      // Set up fake clock to start at a specific test time (2025-09-21 11:00 AM)
      fakeClock = FakeClock(DateTime(2025, 9, 21, 11, 0));
      
      // Use in-memory SharedPreferences and init Storage used by AppState
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await Storage.init();
      
      // Create AppState with fake clock
      app = AppState(clock: fakeClock);

      // Set up always-open business hours to avoid timing complications
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
      // Test rosters
      final lunch = ['server_a', 'server_b'];
      final dinner = ['server_b', 'server_c'];

      // Set transition times: 15:30-16:00 (3:30-4:00 PM)
      final testSettings = app.settings
        ..transitionStartMinutes = 15 * 60 + 30  // 15:30
        ..transitionEndMinutes = 16 * 60;        // 16:00
      await app.saveSettings(testSettings);

      // Set today plan
      app.setTodayPlan(lunch, dinner);

      // Start lunch shift at 11:00 AM
      fakeClock.setTime(DateTime(2025, 9, 21, 11, 0));
      await app.startNewShift(label: 'Lunch', workingIds: lunch, start: fakeClock.now());

      // Simulate lunch activity
      await addRuns('server_a', 5);  // lunch-only server
      await addRuns('server_b', 8);  // both-shift server

      // Move to transition period (15:45 PM)
      fakeClock.setTime(DateTime(2025, 9, 21, 15, 45));
      
      // During transition, add dinner-only server with activity
      app.updateActiveRoster([...lunch, 'server_c'], preserveExistingCounts: true);
      await addRuns('server_c', 3);  // dinner-only server

      // Verify state during transition
      expect(app.workingServerIds.contains('server_a'), isTrue, reason: 'A should be active during transition');
      expect(app.workingServerIds.contains('server_b'), isTrue, reason: 'B should be active during transition');
      expect(app.workingServerIds.contains('server_c'), isTrue, reason: 'C should be active during transition');
      expect(app.currentCounts['server_a'], 5, reason: 'A should have lunch counts during transition');
      expect(app.currentCounts['server_b'], 8, reason: 'B should have lunch counts during transition');
      expect(app.currentCounts['server_c'], 3, reason: 'C should have transition counts');

      // Move past transition end (16:01 PM) to trigger dinner shift
      fakeClock.setTime(DateTime(2025, 9, 21, 16, 1));
      
      // Trigger transition logic manually (simulating timer tick)
      app.setTodayPlan(lunch, dinner); // Re-apply plan to trigger transition logic
      await Future<void>.delayed(const Duration(milliseconds: 100)); // Allow state to settle

      // Verify post-transition state
      final counts = app.currentCounts;
      final working = app.workingServerIds;

      expect(working.contains('server_a'), isFalse, reason: 'Lunch-only A should be removed at dinner');
      expect(working.contains('server_b'), isTrue, reason: 'Both-shift B should be active at dinner');
      expect(working.contains('server_c'), isTrue, reason: 'Dinner-only C should be active at dinner');

      expect(counts['server_b'] ?? -1, 0, reason: 'Both-shift B must reset to 0 at dinner start');
      expect(counts['server_c'] ?? -1, 3, reason: 'Dinner-only C must preserve transition counts');
    });

    test('No double-finalization: calling _maybeActivateShiftByClock twice should be safe', () async {
      final lunch = ['server_a'];
      final dinner = ['server_b'];

      // Set transition times
      final testSettings = app.settings
        ..transitionStartMinutes = 15 * 60 + 30  // 15:30
        ..transitionEndMinutes = 16 * 60;        // 16:00
      await app.saveSettings(testSettings);

      app.setTodayPlan(lunch, dinner);

      // Start lunch shift
      fakeClock.setTime(DateTime(2025, 9, 21, 11, 0));
      await app.startNewShift(label: 'Lunch', workingIds: lunch, start: fakeClock.now());
      await addRuns('server_a', 10);

      // Move past transition to dinner
      fakeClock.setTime(DateTime(2025, 9, 21, 16, 1));
      
      // First transition call
      app.setTodayPlan(lunch, dinner);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      
      final firstCounts = Map<String, int>.from(app.currentCounts);
      final firstWorking = Set<String>.from(app.workingServerIds);
      
      // Second transition call (should not change anything)
      app.setTodayPlan(lunch, dinner);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      
      final secondCounts = Map<String, int>.from(app.currentCounts);
      final secondWorking = Set<String>.from(app.workingServerIds);

      expect(firstCounts, equals(secondCounts), reason: 'Counts should not change on second call');
      expect(firstWorking, equals(secondWorking), reason: 'Working set should not change on second call');
      expect(app.workingServerIds.contains('server_a'), isFalse, reason: 'A should remain removed');
      expect(app.workingServerIds.contains('server_b'), isTrue, reason: 'B should remain active');
    });

    test('Complex transition: [A,B,C] -> [B,C,D] preserves counts correctly', () async {
      final lunch = ['server_a', 'server_b', 'server_c'];  // A=lunch-only, B=both, C=both
      final dinner = ['server_b', 'server_c', 'server_d']; // B=both, C=both, D=dinner-only

      // Set transition times
      final testSettings = app.settings
        ..transitionStartMinutes = 15 * 60 + 30
        ..transitionEndMinutes = 16 * 60;
      await app.saveSettings(testSettings);

      app.setTodayPlan(lunch, dinner);

      // Start lunch shift
      fakeClock.setTime(DateTime(2025, 9, 21, 11, 0));
      await app.startNewShift(label: 'Lunch', workingIds: lunch, start: fakeClock.now());

      // Lunch activity
      await addRuns('server_a', 7);  // lunch-only (should be removed)
      await addRuns('server_b', 12); // both-shift (should reset)
      await addRuns('server_c', 9);  // both-shift (should reset)

      // Transition period - add dinner-only server
      fakeClock.setTime(DateTime(2025, 9, 21, 15, 45));
      app.updateActiveRoster([...lunch, 'server_d'], preserveExistingCounts: true);
      await addRuns('server_d', 4);  // dinner-only (should preserve)

      // Move to dinner
      fakeClock.setTime(DateTime(2025, 9, 21, 16, 1));
      app.setTodayPlan(lunch, dinner);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final counts = app.currentCounts;
      final working = app.workingServerIds;

      // Verify removals and preservations
      expect(working.contains('server_a'), isFalse, reason: 'Lunch-only A should be removed');
      expect(working.contains('server_b'), isTrue, reason: 'Both-shift B should be active');
      expect(working.contains('server_c'), isTrue, reason: 'Both-shift C should be active');
      expect(working.contains('server_d'), isTrue, reason: 'Dinner-only D should be active');

      // Verify count behavior
      expect(counts['server_a'], isNull, reason: 'Removed server A should have no counts');
      expect(counts['server_b'], 0, reason: 'Both-shift B should reset to 0');
      expect(counts['server_c'], 0, reason: 'Both-shift C should reset to 0');
      expect(counts['server_d'], 4, reason: 'Dinner-only D should preserve transition counts');
    });

    test('Transition preserves dinner-only servers added mid-transition', () async {
      final lunch = ['server_a'];
      final dinner = ['server_a', 'server_b'];

      // Set transition times
      final testSettings = app.settings
        ..transitionStartMinutes = 15 * 60 + 30
        ..transitionEndMinutes = 16 * 60;
      await app.saveSettings(testSettings);

      app.setTodayPlan(lunch, dinner);

      // Start lunch
      fakeClock.setTime(DateTime(2025, 9, 21, 11, 0));
      await app.startNewShift(label: 'Lunch', workingIds: lunch, start: fakeClock.now());
      await addRuns('server_a', 15);

      // Mid-transition: add dinner-only server with preserveExistingCounts
      fakeClock.setTime(DateTime(2025, 9, 21, 15, 50));
      app.updateActiveRoster(['server_a', 'server_b'], preserveExistingCounts: true);
      
      // Give dinner-only server some activity during transition
      await addRuns('server_b', 6);

      // Complete transition
      fakeClock.setTime(DateTime(2025, 9, 21, 16, 1));
      app.setTodayPlan(lunch, dinner);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final counts = app.currentCounts;

      expect(counts['server_a'], 0, reason: 'Both-shift A should reset to 0');
      expect(counts['server_b'], 6, reason: 'Dinner-only B should preserve transition activity');
    });

    test('Edge case: Empty lunch roster -> dinner with servers', () async {
      final lunch = <String>[];  // No lunch servers
      final dinner = ['server_a', 'server_b'];

      final testSettings = app.settings
        ..transitionStartMinutes = 15 * 60 + 30
        ..transitionEndMinutes = 16 * 60;
      await app.saveSettings(testSettings);

      app.setTodayPlan(lunch, dinner);

      // Start with empty lunch shift
      fakeClock.setTime(DateTime(2025, 9, 21, 11, 0));
      await app.startNewShift(label: 'Lunch', workingIds: lunch, start: fakeClock.now());

      // Add dinner servers during transition
      fakeClock.setTime(DateTime(2025, 9, 21, 15, 45));
      app.updateActiveRoster(dinner, preserveExistingCounts: true);
      await addRuns('server_a', 3);
      await addRuns('server_b', 5);

      // Complete transition
      fakeClock.setTime(DateTime(2025, 9, 21, 16, 1));
      app.setTodayPlan(lunch, dinner);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final counts = app.currentCounts;
      final working = app.workingServerIds;

      expect(working.length, 2, reason: 'Should have both dinner servers');
      expect(counts['server_a'], 3, reason: 'Dinner-only A should preserve counts');
      expect(counts['server_b'], 5, reason: 'Dinner-only B should preserve counts');
    });
  });
}
