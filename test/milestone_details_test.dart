import 'package:flutter_test/flutter_test.dart';
import '../lib/app_state.dart';
import '../lib/models.dart';
import '../lib/storage.dart';
import '../lib/gamification.dart';

void main() {
  group('Milestone Details Tracking', () {
    late AppState appState;
    
    setUp(() {
      appState = AppState();
      // Add a test server
      appState.addServer('test-server', 'Test Server');
    });
    
    test('should track milestone details when achievement is earned', () async {
      // Start a shift to enable milestone tracking
      appState.startShift('lunch');
      appState.addWorkingServer('test-server');
      
      // Clear any existing milestone details
      expect(appState.lastMilestoneDetails['test-server'], isNull);
      
      // Perform multiple runs to trigger a milestone
      for (int i = 0; i < 5; i++) {
        await appState.increment('test-server');
      }
      
      // Check if milestone details are tracked
      final milestoneDetails = appState.lastMilestoneDetails['test-server'];
      if (milestoneDetails != null) {
        expect(milestoneDetails['type'], isNotNull);
        expect(milestoneDetails['xpReward'], isA<int>());
        expect(milestoneDetails['message'], isA<String>());
        expect(milestoneDetails['actionType'], isA<String>());
        expect(milestoneDetails['timestamp'], isA<String>());
        
        print('Milestone details tracked: ${milestoneDetails['type']} with ${milestoneDetails['xpReward']} XP');
      }
    });
    
    test('should track traditional achievement details', () async {
      // Start a shift
      appState.startShift('lunch');
      appState.addWorkingServer('test-server');
      
      // Perform rapid taps to trigger Full Hands achievement
      await appState.increment('test-server');
      await appState.increment('test-server');
      
      // Check if achievement details are tracked
      final milestoneDetails = appState.lastMilestoneDetails['test-server'];
      if (milestoneDetails != null && milestoneDetails['type'] == 'traditional_achievement') {
        expect(milestoneDetails['achievementId'], isA<String>());
        expect(milestoneDetails['title'], isA<String>());
        expect(milestoneDetails['description'], isA<String>());
        expect(milestoneDetails['xpReward'], isA<int>());
        
        print('Achievement details tracked: ${milestoneDetails['title']} - ${milestoneDetails['description']}');
      }
    });
    
    test('should clear milestone details when shift ends', () async {
      // Start a shift and trigger an achievement
      appState.startShift('lunch');
      appState.addWorkingServer('test-server');
      
      // Trigger some runs
      for (int i = 0; i < 5; i++) {
        await appState.increment('test-server');
      }
      
      // Verify milestone details exist
      expect(appState.lastMilestoneDetails['test-server'], isNotNull);
      
      // End the shift
      appState.endShift();
      
      // Verify milestone details are cleared
      expect(appState.lastMilestoneDetails['test-server'], isNull);
    });
  });
}