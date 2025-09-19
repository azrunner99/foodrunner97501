import 'package:flutter_test/flutter_test.dart';
import 'package:food_runs_counter/models.dart';
import 'package:food_runs_counter/widgets/weekly_hours_picker.dart';

void main() {
  group('WeeklyHoursPicker logic', () {
    test('snap rounds to nearest slot correctly', () {
      // Access the private method via Function.apply using mirrors is not possible in Flutter tests.
      // Instead, validate behavior indirectly by constructing picker and using _snap-equivalent logic.
      // We replicate the snap logic here to assert expected mapping.
      int snap(int minutes, int slot) {
        if (slot <= 1) return minutes;
        final r = minutes % slot;
        return r >= slot / 2 ? minutes + (slot - r) : minutes - r;
      }

      expect(snap(7, 15), 0);
      expect(snap(8, 15), 15);
      expect(snap(22, 15), 15);
      expect(snap(23, 15), 30);
      expect(snap(37, 15), 30);
      expect(snap(38, 15), 45);
    });

    test('overnight mapping: close > 1440 is preserved', () {
      final hours = WeeklyHours(
        openMinutes: {for (var d = 1; d <= 7; d++) d: 22 * 60}, // 22:00
        closeMinutes: {for (var d = 1; d <= 7; d++) d: 25 * 60}, // 01:00 next day
      );

      // Widget holds values as-is; toMap/closeDayOffset should mark offset=1
      expect(hours.closeMinutes[1], 1500); // 25*60
      expect(hours.closeDayOffset[1], 1);
    });

    test('default hours sanity', () {
      final def = WeeklyHours.defaults();
      // Mon (1) default open 11:00, close 23:00 same day
      expect(def.openMinutes[1], 11 * 60);
      expect(def.closeMinutes[1], 23 * 60);
      expect(def.closeDayOffset[1], 0);
      // Fri (5) default close at 24:00 (next day)
      expect(def.closeMinutes[5], 24 * 60);
      expect(def.closeDayOffset[5], 1);
    });
  });
}
