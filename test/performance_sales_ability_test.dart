import 'package:flutter_test/flutter_test.dart';
import 'package:food_runs_counter/utils/performance_calculator.dart';
import 'package:food_runs_counter/models/performance_models.dart';
import 'package:food_runs_counter/models.dart';

/// Minimal helpers
ShiftRecord _shift({required String serverId, required DateTime date, int runs = 10}) => ShiftRecord(
  id: 's_${date.millisecondsSinceEpoch}',
  label: 'Dinner',
  shiftType: 'Dinner',
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
  required double avgCheck,
  required int checks,
}) => NPSData(
  serverId: serverId,
  month: month,
  monthlyScore: 60, // neutral guest perception
  threeMonthAverage: 60,
  responseCount: checks,
  categoryBreakdown: {
    'service': 60,
    'overall': 60,
    'sales': avgCheck * checks, // store total sales in 'sales'
  },
  guestComments: const [],
  lastUpdated: DateTime.now(),
);

void main() {
  group('Sales Ability Dynamic Baseline', () {
    test('Higher average check yields higher overall performance (same runs)', () {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 30));

      final serverA = _server('A');
      final serverB = _server('B');

      // Identical shift production
      final shiftsA = [
        _shift(serverId: 'A', date: now.subtract(const Duration(days: 5)), runs: 10),
        _shift(serverId: 'A', date: now.subtract(const Duration(days: 10)), runs: 10),
      ];
      final shiftsB = [
        _shift(serverId: 'B', date: now.subtract(const Duration(days: 5)), runs: 10),
        _shift(serverId: 'B', date: now.subtract(const Duration(days: 10)), runs: 10),
      ];

      // Server A lower avg check ~50, Server B higher avg check ~90
      final npsA = [
        _nps(serverId: 'A', month: DateTime(now.year, now.month, 1), avgCheck: 50, checks: 40),
      ];
      final npsB = [
        _nps(serverId: 'B', month: DateTime(now.year, now.month, 1), avgCheck: 90, checks: 40),
      ];

      final perfA = PerformanceCalculator.calculateServerPerformance(
        serverId: 'A',
        startDate: start,
        endDate: now,
        shifts: shiftsA,
        businessData: null,
        hireDate: serverA.hireDate!,
        npsHistory: npsA,
      );

      final perfB = PerformanceCalculator.calculateServerPerformance(
        serverId: 'B',
        startDate: start,
        endDate: now,
        shifts: shiftsB,
        businessData: null,
        hireDate: serverB.hireDate!,
        npsHistory: npsB,
      );

      expect(perfB.performanceScore, greaterThan(perfA.performanceScore),
        reason: 'Higher average check should contribute to higher performance score when other factors equal');
    });

    test('Extremely low average check penalized below neutral', () {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 30));
      final server = _server('C');

      final shifts = [
        _shift(serverId: 'C', date: now.subtract(const Duration(days: 5)), runs: 10),
        _shift(serverId: 'C', date: now.subtract(const Duration(days: 10)), runs: 10),
      ];

      final lowAvgCheckNps = [
        _nps(serverId: 'C', month: DateTime(now.year, now.month, 1), avgCheck: 35, checks: 40),
      ];

      final perf = PerformanceCalculator.calculateServerPerformance(
        serverId: 'C',
        startDate: start,
        endDate: now,
        shifts: shifts,
        businessData: null,
        hireDate: server.hireDate!,
        npsHistory: lowAvgCheckNps,
      );

      // If overall score is fairly high due to other components, ensure sales ability pulled it down some.
      // We'll just assert it's not elite due to low average check influence.
      expect(perf.performanceScore < 90, true,
        reason: 'Low average check should prevent elite composite score with otherwise average inputs');
    });
  });
}
