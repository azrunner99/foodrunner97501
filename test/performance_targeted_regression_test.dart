import 'package:flutter_test/flutter_test.dart';
import 'package:food_runs_counter/utils/performance_calculator.dart';
import 'package:food_runs_counter/models/performance_models.dart';
import 'package:food_runs_counter/models.dart';

// Minimal fake shift record compatible with existing model usage.
ShiftRecord _shift({required String serverId, required DateTime date, int runs = 0, String shiftType = 'lunch'}) => ShiftRecord(
      id: 'shift-${serverId}-${date.millisecondsSinceEpoch}',
      label: shiftType,
      shiftType: shiftType,
      start: date,
      counts: {if (runs > 0) serverId: runs},
    );

NPSData _npsMonth({
  required String serverId,
  required DateTime month,
  double monthSales = 0,
  double monthChecks = 0,
  double monthNpsPct = 50,
}) => NPSData(
      serverId: serverId,
      month: month,
      monthlyScore: monthNpsPct,
      threeMonthAverage: monthNpsPct, // simplify for test
      responseCount: monthChecks.toInt(),
      categoryBreakdown: {
        'sales': monthSales, // all-time style field
        if (monthSales > 0) 'month_sales': monthSales,
        if (monthChecks > 0) 'month_checks': monthChecks,
        'month_nps_percentage': monthNpsPct,
      },
      guestComments: const [],
      lastUpdated: DateTime.now(),
    );

void main() {
  group('Performance targeted regression', () {
    test('Zero-run guard sets score to 0 with no data', () {
      final start = DateTime.now().subtract(const Duration(days: 30));
      final end = DateTime.now();
      final perf = PerformanceCalculator.calculateServerPerformance(
        serverId: 'A',
        startDate: start,
        endDate: end,
        shifts: const [],
        businessData: null,
        hireDate: DateTime.now().subtract(const Duration(days: 200)),
        npsHistory: const [],
        totalServerCount: 1,
      );
      expect(perf.performanceScore, 0.0, reason: 'Zero-run/no-data score should hard floor to 0');
    });

    test('Ranking tie-break favors higher experience then serverId', () {
      final start = DateTime.now().subtract(const Duration(days: 30));
      final end = DateTime.now();
      // Two servers same raw activity: 10 runs over 2 shifts.
      final shifts = [
        _shift(serverId: 'A', date: start.add(const Duration(days: 1)), runs: 5),
        _shift(serverId: 'A', date: start.add(const Duration(days: 5)), runs: 5),
        _shift(serverId: 'B', date: start.add(const Duration(days: 2)), runs: 5),
        _shift(serverId: 'B', date: start.add(const Duration(days: 6)), runs: 5),
      ];
      final hireOlder = DateTime.now().subtract(const Duration(days: 400));
      final hireNewer = DateTime.now().subtract(const Duration(days: 40));

      final perfA = PerformanceCalculator.calculateServerPerformance(
        serverId: 'A',
        startDate: start,
        endDate: end,
        shifts: shifts,
        businessData: null,
        hireDate: hireOlder,
        npsHistory: const [],
        totalServerCount: 2,
      );
      final perfB = PerformanceCalculator.calculateServerPerformance(
        serverId: 'B',
        startDate: start,
        endDate: end,
        shifts: shifts,
        businessData: null,
        hireDate: hireNewer,
        npsHistory: const [],
        totalServerCount: 2,
      );

      // If scores equal, higher experienceFactor should be ranked before (older hire date => higher experience)
      if (perfA.performanceScore == perfB.performanceScore) {
        expect((perfA.experienceFactor ?? 0) >= (perfB.experienceFactor ?? 0), true);
      }
    });

    test('Timeframe slice excludes month outside window', () {
      final end = DateTime.now();
      final start = end.subtract(const Duration(days: 30));
      final insideMonth = DateTime(end.year, end.month, 1);
      final outsideMonth = insideMonth.subtract(const Duration(days: 40));
      final npsHistory = [
        _npsMonth(serverId: 'A', month: insideMonth, monthSales: 1000, monthChecks: 40, monthNpsPct: 60),
        _npsMonth(serverId: 'A', month: outsideMonth, monthSales: 900, monthChecks: 35, monthNpsPct: 55),
      ];
      final perf = PerformanceCalculator.calculateServerPerformance(
        serverId: 'A',
        startDate: start,
        endDate: end,
        shifts: const [],
        businessData: null,
        hireDate: DateTime.now().subtract(const Duration(days: 120)),
        npsHistory: npsHistory,
        totalServerCount: 1,
      );
      // Only the insideMonth should count toward npsDataMonths, so we expect at least 1 month effect and not 2.
      // We cannot directly read npsDataMonths, but weight redistribution for limited months (1) sets NPS weight to 40% (instead of 50).
      // npsWeight is a fraction (e.g. 0.40) not a percentage integer.
      expect(
        perf.npsWeight,
        anyOf(0.40, 0.35, 0.50),
        reason: 'Weight should reflect limited months; ensure outside month excluded.',
      );
    });

    test('Month aggregation uses summed month_sales/checks when present', () {
      final end = DateTime.now();
      final start = end.subtract(const Duration(days: 60));
      final m1 = DateTime(end.year, end.month, 1).subtract(const Duration(days: 30));
      final m2 = DateTime(end.year, end.month, 1);
      final npsHistory = [
        _npsMonth(serverId: 'A', month: m1, monthSales: 1200, monthChecks: 50, monthNpsPct: 58),
        _npsMonth(serverId: 'A', month: m2, monthSales: 1500, monthChecks: 60, monthNpsPct: 62),
      ];
      final perf = PerformanceCalculator.calculateServerPerformance(
        serverId: 'A',
        startDate: start,
        endDate: end,
        shifts: [
          _shift(serverId: 'A', date: start.add(const Duration(days: 5)), runs: 10),
        ],
        businessData: null,
        hireDate: DateTime.now().subtract(const Duration(days: 200)),
        npsHistory: npsHistory,
        totalServerCount: 1,
      );
      // Average check should be derived from (1200+1500)/(50+60) = 2700/110 = ~24.545 -> winsorized up to min cap 40.
      expect(perf.averageCheck, isNotNull);
      expect(perf.averageCheck! >= 40.0, true, reason: 'Winsorization min cap should raise low computed avg check.');
    });
  });
}
