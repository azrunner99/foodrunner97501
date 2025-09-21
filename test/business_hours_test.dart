import 'package:flutter_test/flutter_test.dart';
import 'package:food_runs_counter/models.dart';
import 'package:food_runs_counter/app_state.dart';

// Helper function to test business hours logic directly without AppState dependencies
bool isOpenAtTime(int currentMinutes, int openMinutes, int closeMinutes) {
  // Validate business hours data
  assert(openMinutes >= 0 && openMinutes < 1440, 'Open time must be between 0-1439 minutes, got $openMinutes');
  assert(closeMinutes >= 0 && closeMinutes < 1440, 'Close time must be between 0-1439 minutes, got $closeMinutes');
  
  if (closeMinutes > openMinutes) {
    // Normal day operation: open=9:00(540), close=17:00(1020)
    return currentMinutes >= openMinutes && currentMinutes < closeMinutes;
  } else {
    // Overnight operation: open=17:00(1020), close=01:00(60) next day
    // Open if: current >= open OR current < close
    return currentMinutes >= openMinutes || currentMinutes < closeMinutes;
  }
}

void main() {
  group('Business Hours Logic Tests', () {
    test('Normal business hours (9:00 AM - 5:00 PM)', () {
      const openMinutes = 9 * 60; // 9:00 AM = 540 minutes
      const closeMinutes = 17 * 60; // 5:00 PM = 1020 minutes

      // Test cases during normal hours
      final tests = [
        // Before opening
        (8 * 60 + 59, false, '8:59 AM should be closed'),
        // At opening
        (9 * 60, true, '9:00 AM should be open'),
        // During business hours
        (12 * 60 + 30, true, '12:30 PM should be open'),
        // Just before closing
        (16 * 60 + 59, true, '4:59 PM should be open'),
        // At closing time
        (17 * 60, false, '5:00 PM should be closed'),
        // After closing
        (20 * 60, false, '8:00 PM should be closed'),
      ];

      for (final (currentMinutes, expected, description) in tests) {
        expect(isOpenAtTime(currentMinutes, openMinutes, closeMinutes), expected, reason: description);
      }
    });

    test('Overnight business hours (5:00 PM - 1:00 AM)', () {
      const openMinutes = 17 * 60; // 5:00 PM = 1020 minutes
      const closeMinutes = 1 * 60; // 1:00 AM = 60 minutes

      final tests = [
        // Early morning before close
        (0 * 60 + 30, true, '12:30 AM should be open (overnight)'),
        // Just before close
        (0 * 60 + 59, true, '12:59 AM should be open (overnight)'),
        // At close time
        (1 * 60, false, '1:00 AM should be closed'),
        // After close, before open
        (10 * 60, false, '10:00 AM should be closed'),
        // Just before open
        (16 * 60 + 59, false, '4:59 PM should be closed'),
        // At open time
        (17 * 60, true, '5:00 PM should be open'),
        // During evening hours
        (20 * 60, true, '8:00 PM should be open'),
        // Late night
        (23 * 60 + 30, true, '11:30 PM should be open'),
      ];

      for (final (currentMinutes, expected, description) in tests) {
        expect(isOpenAtTime(currentMinutes, openMinutes, closeMinutes), expected, reason: description);
      }
    });

    test('Edge case: Midnight operations (11:00 PM - 2:00 AM)', () {
      const openMinutes = 23 * 60; // 11:00 PM = 1380 minutes
      const closeMinutes = 2 * 60; // 2:00 AM = 120 minutes

      final tests = [
        // Before opening
        (22 * 60 + 59, false, '10:59 PM should be closed'),
        // At opening
        (23 * 60, true, '11:00 PM should be open'),
        // Across midnight
        (0 * 60, true, '12:00 AM should be open'),
        // Early morning before close
        (1 * 60 + 30, true, '1:30 AM should be open'),
        // At close
        (2 * 60, false, '2:00 AM should be closed'),
        // After close
        (10 * 60, false, '10:00 AM should be closed'),
      ];

      for (final (currentMinutes, expected, description) in tests) {
        expect(isOpenAtTime(currentMinutes, openMinutes, closeMinutes), expected, reason: description);
      }
    });

    test('24-hour operation (same open and close times)', () {
      const openMinutes = 0; // 12:00 AM
      const closeMinutes = 0; // 12:00 AM (next day)

      // When open == close, it should be treated as overnight (always open)
      final tests = [
        (0 * 60, true, '12:00 AM should be open (24h)'),
        (6 * 60, true, '6:00 AM should be open (24h)'),
        (12 * 60, true, '12:00 PM should be open (24h)'),
        (18 * 60, true, '6:00 PM should be open (24h)'),
        (23 * 60 + 59, true, '11:59 PM should be open (24h)'),
      ];

      for (final (currentMinutes, expected, description) in tests) {
        expect(isOpenAtTime(currentMinutes, openMinutes, closeMinutes), expected, reason: description);
      }
    });

    test('Data validation assertions', () {
      // Test invalid open time (negative)
      expect(() {
        isOpenAtTime(12 * 60, -1, 17 * 60);
      }, throwsA(isA<AssertionError>()));

      // Test invalid open time (too large)
      expect(() {
        isOpenAtTime(12 * 60, 1440, 17 * 60); // 1440 minutes = 24:00, should be 0-1439
      }, throwsA(isA<AssertionError>()));

      // Test invalid close time (negative)
      expect(() {
        isOpenAtTime(12 * 60, 9 * 60, -1);
      }, throwsA(isA<AssertionError>()));

      // Test invalid close time (too large)
      expect(() {
        isOpenAtTime(12 * 60, 9 * 60, 1440);
      }, throwsA(isA<AssertionError>()));
    });

    test('Real-world examples', () {
      // Restaurant: 5:00 PM - 1:00 AM
      expect(isOpenAtTime(18 * 60, 17 * 60, 1 * 60), true, reason: 'Restaurant at 6:00 PM should be open');
      expect(isOpenAtTime(0 * 60 + 30, 17 * 60, 1 * 60), true, reason: 'Restaurant at 12:30 AM should be open');
      expect(isOpenAtTime(2 * 60, 17 * 60, 1 * 60), false, reason: 'Restaurant at 2:00 AM should be closed');
      
      // Bar: 10:00 PM - 4:00 AM
      expect(isOpenAtTime(22 * 60, 22 * 60, 4 * 60), true, reason: 'Bar at 10:00 PM should be open');
      expect(isOpenAtTime(2 * 60, 22 * 60, 4 * 60), true, reason: 'Bar at 2:00 AM should be open');
      expect(isOpenAtTime(5 * 60, 22 * 60, 4 * 60), false, reason: 'Bar at 5:00 AM should be closed');
      
      // 24/7 Diner: 12:00 AM - 12:00 AM
      expect(isOpenAtTime(3 * 60, 0, 0), true, reason: '24/7 Diner at 3:00 AM should be open');
      expect(isOpenAtTime(15 * 60, 0, 0), true, reason: '24/7 Diner at 3:00 PM should be open');
      expect(isOpenAtTime(21 * 60, 0, 0), true, reason: '24/7 Diner at 9:00 PM should be open');
    });
  });
}