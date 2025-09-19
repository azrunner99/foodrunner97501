import 'package:flutter_test/flutter_test.dart';
import 'package:food_runs_counter/models.dart';
import 'package:food_runs_counter/business_time.dart';

void main() {
  group('Business hours boundary tests - open/close', () {
    test('Same-day close: just before, at, after open/close', () {
      // Open 10:00, Close 22:00 for all days
      final hours = WeeklyHours(
        openMinutes: {for (var d = 1; d <= 7; d++) d: 10 * 60},
        closeMinutes: {for (var d = 1; d <= 7; d++) d: 22 * 60},
      );

      final base = DateTime(2025, 9, 17, 0, 0); // Wednesday
      // Choose Wednesday for stability
      final wed = base.add(const Duration(days: 2));

      // Open boundary
      final tOpenMinus1 = DateTime(wed.year, wed.month, wed.day, 9, 59);
      final tOpen = DateTime(wed.year, wed.month, wed.day, 10, 0);
      final tOpenPlus1 = DateTime(wed.year, wed.month, wed.day, 10, 1);

      expect(isOpenAtFor(hours, tOpenMinus1), isFalse,
          reason: 'Closed just before open');
      expect(isOpenAtFor(hours, tOpen), isTrue,
          reason: 'Open at exact open minute');
      expect(isOpenAtFor(hours, tOpenPlus1), isTrue,
          reason: 'Open after open minute');

      // Close boundary
      final tCloseMinus1 = DateTime(wed.year, wed.month, wed.day, 21, 59);
      final tClose = DateTime(wed.year, wed.month, wed.day, 22, 0);
      final tClosePlus1 = DateTime(wed.year, wed.month, wed.day, 22, 1);

      expect(isOpenAtFor(hours, tCloseMinus1), isTrue,
          reason: 'Still open just before close');
      expect(isOpenAtFor(hours, tClose), isFalse,
          reason: 'Closed at the exact close minute');
      expect(isOpenAtFor(hours, tClosePlus1), isFalse,
          reason: 'Closed after close minute');
    });

        test('Overnight close: attribution across midnight and boundaries', () {
            // Open 18:00, Close 02:00 next day
            // Important: Provide closeDayOffset=1 so the end is on the next calendar day
            final hours = WeeklyHours(
                openMinutes: {for (var d = 1; d <= 7; d++) d: 18 * 60},
                closeMinutes: {for (var d = 1; d <= 7; d++) d: 2 * 60},
                closeDayOffset: {for (var d = 1; d <= 7; d++) d: 1},
            );

      final base = DateTime(2025, 9, 18, 0, 0); // Thursday
      final thu = base; // use Thursday
      final fri = thu.add(const Duration(days: 1));

      // Open boundary on Thu
      final tOpenMinus1 = DateTime(thu.year, thu.month, thu.day, 17, 59);
      final tOpen = DateTime(thu.year, thu.month, thu.day, 18, 0);
      final tOpenPlus1 = DateTime(thu.year, thu.month, thu.day, 18, 1);
      expect(isOpenAtFor(hours, tOpenMinus1), isFalse,
          reason: 'Closed just before open (overnight schedule)');
      expect(isOpenAtFor(hours, tOpen), isTrue,
          reason: 'Open at exact open minute');
      expect(isOpenAtFor(hours, tOpenPlus1), isTrue,
          reason: 'Open after open minute');

      // Overnight close boundary occurs on Fri at 02:00 for Thu business day
      final tCloseMinus1 = DateTime(fri.year, fri.month, fri.day, 1, 59);
      final tClose = DateTime(fri.year, fri.month, fri.day, 2, 0);
      final tClosePlus1 = DateTime(fri.year, fri.month, fri.day, 2, 1);

      expect(isOpenAtFor(hours, tCloseMinus1), isTrue,
          reason: 'Still open before overnight close');
      expect(isOpenAtFor(hours, tClose), isFalse,
          reason: 'Closed at the exact overnight close minute');
      expect(isOpenAtFor(hours, tClosePlus1), isFalse,
          reason: 'Closed after overnight close');

      // Attribution: 01:00 on Fri should belong to Thu business day and be open
      final tEarlyFri = DateTime(fri.year, fri.month, fri.day, 1, 0);
      expect(isOpenAtFor(hours, tEarlyFri), isTrue,
          reason: 'Early Friday hour belongs to Thursday business day');
    });
  });
}
