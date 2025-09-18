import 'package:flutter_test/flutter_test.dart';
import 'package:food_runs_counter/models.dart';
import 'package:food_runs_counter/business_time.dart';

void main() {
  test('isOpenAt handles overnight close correctly', () {
  // Configure hours so that open is 01:10 and close is 04:00 next day
  final open = <int, int>{for (var d = 1; d <= 7; d++) d: 1 * 60 + 10}; // 1:10 AM
  final close = <int, int>{for (var d = 1; d <= 7; d++) d: 4 * 60}; // 4:00 AM
  final closeDayOffset = {for (var d = 1; d <= 7; d++) d: 1};
  final hours = WeeklyHours(openMinutes: open, closeMinutes: close, closeDayOffset: closeDayOffset);

  // Simulate 1:04 AM (should be closed)
  final t1 = DateTime(2025, 9, 18, 1, 4);
  expect(isOpenAtFor(hours, t1), false);

  // Simulate 1:10 AM (should be open)
  final t2 = DateTime(2025, 9, 18, 1, 10);
  expect(isOpenAtFor(hours, t2), true);

  // Simulate 3:59 AM (should still be open)
  final t3 = DateTime(2025, 9, 18, 3, 59);
  expect(isOpenAtFor(hours, t3), true);

  // Simulate 4:01 AM (should be closed)
  final t4 = DateTime(2025, 9, 18, 4, 1);
  expect(isOpenAtFor(hours, t4), false);
  });
}
