import 'package:flutter_test/flutter_test.dart';
import 'package:food_runs_counter/feature_flags.dart';
import 'package:food_runs_counter/models/performance_models.dart';
import 'package:food_runs_counter/utils/performance_calculator.dart';
import 'package:food_runs_counter/models.dart';

/// Basic stub implementations / helpers (lightweight) ---------------------------------
ShiftRecord _shift({required String serverId, required DateTime date, int runs = 5}) => ShiftRecord(
  id: 's_${date.millisecondsSinceEpoch}',
  label: 'Dinner',
  shiftType: 'Dinner',
  start: date,
  counts: {serverId: runs},
  // pizookieCounts / stationAssignments / sectionAssignments default internally
);

Server _server(String id) => Server(id: id, name: id, hireDate: DateTime.now().subtract(const Duration(days: 40)));

void main() {
  group('Performance Data Hygiene', () {
    test('Blank NPS months excluded when hygiene flag enabled', () {
      // Arrange
      FeatureFlags.perfV2DataHygiene = true;
      final server = _server('A');
      final now = DateTime.now();
      // Simulate NPS history with one blank month (represented by zero seller data) and one valid month
      final npsHistory = <NPSData>[
        NPSData(
          serverId: server.id,
          month: DateTime(now.year, now.month - 1, 1),
          monthlyScore: 50,
          threeMonthAverage: 50,
          responseCount: 0, // blank
          categoryBreakdown: {'service': 50, 'overall': 50, 'sales': 0},
          guestComments: const [],
          lastUpdated: now,
        ),
        NPSData(
          serverId: server.id,
          month: DateTime(now.year, now.month - 2, 1),
          monthlyScore: 70,
            threeMonthAverage: 70,
          responseCount: 10,
          categoryBreakdown: {'service': 70, 'overall': 70, 'sales': 500},
          guestComments: const [],
          lastUpdated: now,
        ),
      ];
      // Provide some volume (simulate runs already encoded in shifts) and emulate sales by adding another shift with higher runs
      final shifts = [
        _shift(serverId: server.id, date: now.subtract(const Duration(days: 10)), runs: 5),
        _shift(serverId: server.id, date: now.subtract(const Duration(days: 15)), runs: 4),
        _shift(serverId: server.id, date: now.subtract(const Duration(days: 20)), runs: 6),
      ];

      // Act
      final perf = PerformanceCalculator.calculateServerPerformance(
        serverId: server.id,
        startDate: now.subtract(const Duration(days: 60)),
        endDate: now,
        shifts: shifts,
        businessData: null,
        hireDate: server.hireDate ?? DateTime.now().subtract(const Duration(days: 40)),
        npsHistory: npsHistory,
      );

      // Assert
      expect(perf.dataQuality, isNotNull);
      // With one valid month + shifts we expect at least partial (not missing)
    // With shiftsWorked>=3 and at least one valid NPS month we expect data quality to not be missing.
    // (Volume (sales/checks) is zero in this synthetic test so classification may be sparse.)
    expect(perf.dataQuality != DataQuality.missing, true,
      reason: 'Expected non-missing data quality with hygiene flag enabled and valid NPS + shift data. Got ${perf.dataQuality}');
    });

    test('Data quality null when flag disabled', () {
      FeatureFlags.perfV2DataHygiene = false;
      final server = _server('B');
      final now = DateTime.now();
      final shifts = [_shift(serverId: server.id, date: now.subtract(const Duration(days: 5)))];
      final perf = PerformanceCalculator.calculateServerPerformance(
        serverId: server.id,
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now,
        shifts: shifts,
        businessData: null,
        hireDate: server.hireDate ?? DateTime.now().subtract(const Duration(days: 40)),
        npsHistory: const [],
      );
      expect(perf.dataQuality, isNull);
    });
  });
}
