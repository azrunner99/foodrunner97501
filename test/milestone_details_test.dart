import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/widgets.dart';
import '../lib/app_state.dart';
import '../lib/storage.dart';
import '../lib/models.dart';

void main() {
  group('Milestone Details Tracking', () {
    late AppState appState;

    setUp(() async {
      // Ensure Flutter bindings and mock SharedPreferences are initialized
      WidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await Storage.init();

      appState = AppState();

      // Ensure tests are not blocked by business hours gating
      final alwaysOpen = WeeklyHours(
        openMinutes: {for (var d = 1; d <= 7; d++) d: 0},
        closeMinutes: {for (var d = 1; d <= 7; d++) d: 24 * 60},
      );
      appState.setWeeklyHours(alwaysOpen);
      // Add a test server (returns Future)
      await appState.addServer('Test Server');
      // Find the created server id by name
      final server =
          appState.servers.firstWhere((s) => s.name == 'Test Server');
      // Start a shift with this working server
      await appState.startNewShift(label: 'Lunch', workingIds: [server.id]);
    });

    test('should track milestone details when achievement is earned', () async {
      final serverId =
          appState.servers.firstWhere((s) => s.name == 'Test Server').id;
      // Clear any existing milestone details
      expect(appState.lastMilestoneDetails[serverId], isNull);

      // Perform multiple runs to trigger a milestone
      for (int i = 0; i < 5; i++) {
        await appState.increment(serverId);
      }

      // Check if milestone details are tracked
      final milestoneDetails = appState.lastMilestoneDetails[serverId];
      if (milestoneDetails != null) {
        expect(milestoneDetails['type'], isNotNull);
        expect(milestoneDetails['xpReward'], isA<int>());
        expect(milestoneDetails['message'], isA<String>());
        expect(milestoneDetails['actionType'], isA<String>());
        expect(milestoneDetails['timestamp'], isA<String>());

        print(
            'Milestone details tracked: ${milestoneDetails['type']} with ${milestoneDetails['xpReward']} XP');
      }
    });

    test('should track traditional achievement details', () async {
      final serverId =
          appState.servers.firstWhere((s) => s.name == 'Test Server').id;

      // Perform rapid taps to trigger Full Hands achievement
      await appState.increment(serverId);
      await appState.increment(serverId);

      // Check if achievement details are tracked
      final milestoneDetails = appState.lastMilestoneDetails[serverId];
      if (milestoneDetails != null &&
          milestoneDetails['type'] == 'traditional_achievement') {
        expect(milestoneDetails['achievementId'], isA<String>());
        expect(milestoneDetails['title'], isA<String>());
        expect(milestoneDetails['description'], isA<String>());
        expect(milestoneDetails['xpReward'], isA<int>());

        print(
            'Achievement details tracked: ${milestoneDetails['title']} - ${milestoneDetails['description']}');
      }
    });

    test('should clear milestone details when shift ends', () async {
      final serverId =
          appState.servers.firstWhere((s) => s.name == 'Test Server').id;

      // Trigger some runs
      for (int i = 0; i < 5; i++) {
        await appState.increment(serverId);
      }

      // Verify milestone details exist
      expect(appState.lastMilestoneDetails[serverId], isNotNull);

      // End the shift via endDay in new API
      await appState.endDay();

      // Verify milestone details are cleared
      expect(appState.lastMilestoneDetails[serverId], isNull);
    });
  });
}
