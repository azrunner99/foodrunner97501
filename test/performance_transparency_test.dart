import 'package:flutter_test/flutter_test.dart';
import 'package:food_runs_counter/utils/performance_calculator.dart';
import 'package:food_runs_counter/models/performance_models.dart';
import 'package:food_runs_counter/models.dart';

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
  required double avgCheck,
  required int checks,
  double nps = 60,
}) => NPSData(
  serverId: serverId,
  month: month,
  monthlyScore: nps,
  threeMonthAverage: nps,
  responseCount: checks,
  categoryBreakdown: {
    'service': nps,
    'overall': nps,
    'sales': avgCheck * checks,
  },
  guestComments: const [],
  lastUpdated: DateTime.now(),
);

void main() {
  group('Performance Transparency Components', () {
    test('Component scores sum (with weights & experience) to final score', () {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 30));
      final server = _server('A');
      final shifts = [
        _shift(serverId: 'A', date: now.subtract(const Duration(days: 5)), runs: 12),
        _shift(serverId: 'A', date: now.subtract(const Duration(days: 10)), runs: 8),
      ];
      final npsHistory = [
        _nps(serverId: 'A', month: DateTime(now.year, now.month, 1), avgCheck: 70, checks: 40, nps: 65),
      ];
      final perf = PerformanceCalculator.calculateServerPerformance(
        serverId: 'A',
        startDate: start,
        endDate: now,
        shifts: shifts,
        businessData: null,
        hireDate: server.hireDate!,
        npsHistory: npsHistory,
      );

      expect(perf.npsComponentScore, isNotNull, reason: 'NPS component should be captured');
      expect(perf.salesAbilityScore, isNotNull, reason: 'Sales ability component should be present');
      expect(perf.foodRunningScore, isNotNull, reason: 'Food running component should be present');
      expect(perf.npsWeight, isNotNull);
      expect(perf.salesWeight, isNotNull);
      expect(perf.foodRunningWeight, isNotNull);

      final reconstructedWeighted = (perf.npsComponentScore! * perf.npsWeight!) +
          (perf.salesAbilityScore! * perf.salesWeight!) +
          (perf.foodRunningScore! * perf.foodRunningWeight!);

      // Experience factor is embedded in final; approximate reverse by dividing
      // (Cannot get experienceFactor directly; we validate proportional closeness)
      final ratio = perf.performanceScore / reconstructedWeighted;

      expect(ratio, inInclusiveRange(0.6, 1.05), reason: 'Experience factor should scale weighted aggregate into final score plausibly');
    });

    test('Weight redistribution with limited NPS months (<3)', () {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 30));
      final server = _server('B');
      final shifts = [
        _shift(serverId: 'B', date: now.subtract(const Duration(days: 3)), runs: 10),
      ];
      // Only 1 month of NPS
      final npsHistory = [
        _nps(serverId: 'B', month: DateTime(now.year, now.month, 1), avgCheck: 65, checks: 25),
      ];
      final perf = PerformanceCalculator.calculateServerPerformance(
        serverId: 'B',
        startDate: start,
        endDate: now,
        shifts: shifts,
        businessData: null,
        hireDate: server.hireDate!,
        npsHistory: npsHistory,
      );
      // With 1 month: npsWeight should be reduced from 0.50 toward >=0.35 and <=0.50
      expect(perf.npsWeight, isNotNull);
      expect(perf.npsWeight! <= 0.50 && perf.npsWeight! >= 0.35, true,
          reason: 'NPS weight should reduce but not below 0.35 for limited months');
    });

    test('No NPS data triggers full weight redistribution', () {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 30));
      final server = _server('C');
      final shifts = [
        _shift(serverId: 'C', date: now.subtract(const Duration(days: 7)), runs: 9),
      ];
      final perf = PerformanceCalculator.calculateServerPerformance(
        serverId: 'C',
        startDate: start,
        endDate: now,
        shifts: shifts,
        businessData: null,
        hireDate: server.hireDate!,
        npsHistory: const [],
      );
      expect(perf.npsWeight, 0.0);
      expect(perf.salesWeight, closeTo(0.60, 0.0001));
      expect(perf.foodRunningWeight, closeTo(0.40, 0.0001));
    });
  });
}
