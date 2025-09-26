import 'package:flutter_test/flutter_test.dart';
import 'package:food_runs_counter/utils/performance_calculator.dart';
import 'package:food_runs_counter/models/performance_models.dart';
import 'package:food_runs_counter/models.dart';

// Helpers
ShiftRecord _shift({required String serverId, required DateTime date, int runs = 10, String type = 'Dinner'}) => ShiftRecord(
  id: 's_${date.millisecondsSinceEpoch}',
  label: type,
  shiftType: type,
  start: date,
  counts: {serverId: runs},
);

Server _server(String id, {int daysEmployed = 120}) => Server(
  id: id,
  name: id,
  hireDate: DateTime.now().subtract(Duration(days: daysEmployed)),
);

NPSData _nps({
  required String serverId,
  required DateTime month,
  required double monthly,
  required double threeMonth,
  required int responses,
  double sales = 0,
}) => NPSData(
  serverId: serverId,
  month: month,
  monthlyScore: monthly,
  threeMonthAverage: threeMonth,
  responseCount: responses,
  categoryBreakdown: {
    'service': monthly,
    'overall': monthly,
    'sales': sales,
  },
  guestComments: const [],
  lastUpdated: DateTime.now(),
);

void main() {
  group('Smoothing Logic', () {
    test('NPS smoothing shrinks extreme score with low volume', () {
      final now = DateTime.now();
      final server = _server('S');
      final shifts = [
        _shift(serverId: 'S', date: now.subtract(const Duration(days: 2))),
      ];
      // Single month with very high raw score but low inferred new responses
      final npsHistory = [
        _nps(serverId: 'S', month: DateTime(now.year, now.month, 1), monthly: 95, threeMonth: 95, responses: 40, sales: 2000),
        // Older baseline (lower cumulative) -> create low delta
        _nps(serverId: 'S', month: DateTime(now.year, now.month - 1, 1), monthly: 80, threeMonth: 80, responses: 38, sales: 1800),
      ];

      final perf = PerformanceCalculator.calculateServerPerformance(
        serverId: 'S',
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now,
        shifts: shifts,
        businessData: null,
        hireDate: server.hireDate!,
        npsHistory: npsHistory,
      );

      // Raw would be near 95, smoothing should pull it downward toward neutral.
      expect(perf.npsComponentScore, isNotNull);
      expect(perf.npsComponentScore! < 95, true);
    });

    test('Sales ability extreme shrinks when very low checks', () {
      final now = DateTime.now();
      final server = _server('SA');
      final shifts = [
        _shift(serverId: 'SA', date: now.subtract(const Duration(days: 1))),
      ];
      // Very high average check scenario but with tiny volume (10 checks)
      final npsHistory = [
        _nps(serverId: 'SA', month: DateTime(now.year, now.month, 1), monthly: 60, threeMonth: 60, responses: 10, sales: 1500), // avg check 150
      ];

      final perf = PerformanceCalculator.calculateServerPerformance(
        serverId: 'SA',
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now,
        shifts: shifts,
        businessData: null,
        hireDate: server.hireDate!,
        npsHistory: npsHistory,
      );

      // Sales ability score should not be pegged at 100 after smoothing (should be reduced)
      expect(perf.salesAbilityScore, isNotNull);
      expect(perf.salesAbilityScore! < 100, true);
    });

    test('Experience factor exposed for reconstruction', () {
      final now = DateTime.now();
      final server = _server('EXP');
      final shifts = [
        _shift(serverId: 'EXP', date: now.subtract(const Duration(days: 3))),
        _shift(serverId: 'EXP', date: now.subtract(const Duration(days: 8))),
      ];
      final npsHistory = [
        _nps(serverId: 'EXP', month: DateTime(now.year, now.month, 1), monthly: 70, threeMonth: 70, responses: 60, sales: 3000),
      ];

      final perf = PerformanceCalculator.calculateServerPerformance(
        serverId: 'EXP',
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now,
        shifts: shifts,
        businessData: null,
        hireDate: server.hireDate!,
        npsHistory: npsHistory,
      );

      expect(perf.experienceFactor, isNotNull);
      final reconstructed = ((perf.npsComponentScore! * perf.npsWeight!) +
              (perf.salesAbilityScore! * perf.salesWeight!) +
              (perf.foodRunningScore! * perf.foodRunningWeight!)) *
          perf.experienceFactor!;
      // Allow tight tolerance
      expect((perf.performanceScore - reconstructed).abs() < 0.001, true);
    });
  });
}
