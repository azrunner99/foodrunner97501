/// Unit tests for the NPS system models and database operations
///
/// These tests verify the functionality of the Server NPS system components.

import 'package:flutter_test/flutter_test.dart';
import 'package:food_runs_counter/models/server.dart';
import 'package:food_runs_counter/models/nps_feedback.dart';
import 'package:food_runs_counter/models/monthly_report.dart';
import 'package:food_runs_counter/utils/nps_calculator.dart';

void main() {
  group('NPSServer Model Tests', () {
    test('should create NPSServer with valid data', () {
      final server = NPSServer(
        id: '1',
        name: 'John Doe',
        hireDate: DateTime(2024, 1, 15),
        active: true,
      );

      expect(server.id, equals('1'));
      expect(server.name, equals('John Doe'));
      expect(server.hireDate, equals(DateTime(2024, 1, 15)));
      expect(server.active, isTrue);
      expect(server.isValid(), isTrue);
    });

    test('should validate server data correctly', () {
      // Valid server
      final validServer = NPSServer(
        id: 'valid1',
        name: 'Jane Smith',
        hireDate: DateTime(2024, 1, 1),
      );
      expect(validServer.isValid(), isTrue);
      expect(validServer.getValidationErrors(), isEmpty);

      // Invalid server - empty name
      final invalidServer1 = NPSServer(
        id: 'invalid1',
        name: '',
        hireDate: DateTime(2024, 1, 1),
      );
      expect(invalidServer1.isValid(), isFalse);
      expect(invalidServer1.getValidationErrors(),
          contains('Server name cannot be empty'));

      // Invalid server - future hire date
      final invalidServer2 = NPSServer(
        id: 'invalid2',
        name: 'Future Employee',
        hireDate: DateTime.now().add(const Duration(days: 30)),
      );
      expect(invalidServer2.isValid(), isFalse);
      expect(invalidServer2.getValidationErrors(),
          contains('Hire date cannot be in the future'));
    });

    test('should calculate tenure correctly', () {
      final server = NPSServer(
        id: 'tenure1',
        name: 'Test Server',
        hireDate: DateTime(2024, 1, 1),
      );

      final referenceDate = DateTime(2024, 6, 1);
      final tenureInDays = server.getTenureInDays(referenceDate);
      final tenureInMonths = server.getTenureInMonths(referenceDate);

      expect(tenureInDays, greaterThan(120)); // About 5 months
      expect(tenureInMonths, equals(5));
    });

    test('should convert to/from map correctly', () {
      final originalServer = NPSServer(
        id: '1',
        name: 'Test Server',
        hireDate: DateTime(2024, 1, 15),
        active: true,
        createdAt: DateTime(2024, 1, 15, 10, 0, 0),
      );

      final map = originalServer.toMap();
      final reconstructedServer = NPSServer.fromMap(map);

      expect(reconstructedServer.id, equals(originalServer.id));
      expect(reconstructedServer.name, equals(originalServer.name));
      expect(reconstructedServer.hireDate, equals(originalServer.hireDate));
      expect(reconstructedServer.active, equals(originalServer.active));
    });
  });

  group('NPSFeedback Model Tests', () {
    test('should create NPSFeedback with valid data', () {
      final feedback = NPSFeedback(
        id: 1,
        serverId: '1',
        feedbackType: FeedbackType.yes,
        feedbackDate: DateTime(2024, 6, 1),
        salesAmount: 25.50,
        tableNumber: 5,
        shiftPeriod: ShiftPeriod.lunch,
        guestCount: 2,
        notes: 'Great service!',
      );

    expect(feedback.id, equals(1));
    expect(feedback.serverId, equals('1'));
      expect(feedback.feedbackType, equals(FeedbackType.yes));
      expect(feedback.salesAmount, equals(25.50));
      expect(feedback.isValid(), isTrue);
    });

    test('should validate feedback data correctly', () {
      // Valid feedback
      final validFeedback = NPSFeedback(
        serverId: '1',
        feedbackType: FeedbackType.yes,
        feedbackDate: DateTime.now().subtract(const Duration(days: 1)),
        salesAmount: 25.00,
        tableNumber: 5,
        guestCount: 2,
      );
      expect(validFeedback.isValid(), isTrue);
      expect(validFeedback.getValidationErrors(), isEmpty);

      // Invalid feedback - negative sales
      final invalidFeedback1 = NPSFeedback(
        serverId: '1',
        feedbackType: FeedbackType.yes,
        feedbackDate: DateTime.now(),
        salesAmount: -10.00,
      );
      expect(invalidFeedback1.isValid(), isFalse);
      expect(invalidFeedback1.getValidationErrors(),
          contains('Sales amount cannot be negative'));

      // Invalid feedback - future date
      final invalidFeedback2 = NPSFeedback(
        serverId: '1',
        feedbackType: FeedbackType.yes,
        feedbackDate: DateTime.now().add(const Duration(days: 2)),
      );
      expect(invalidFeedback2.isValid(), isFalse);
      expect(invalidFeedback2.getValidationErrors(),
          contains('Feedback date cannot be in the future'));
    });

    test('should calculate NPS impact correctly', () {
      expect(FeedbackType.yes.npsImpact, equals(1));
      expect(FeedbackType.maybe.npsImpact, equals(0));
      expect(FeedbackType.no.npsImpact, equals(-1));
    });

    test('should convert to/from map correctly', () {
      final originalFeedback = NPSFeedback(
        id: 1,
        serverId: '1',
        feedbackType: FeedbackType.yes,
        feedbackDate: DateTime(2024, 6, 1),
        salesAmount: 25.50,
        tableNumber: 5,
        shiftPeriod: ShiftPeriod.lunch,
        guestCount: 2,
        notes: 'Excellent service',
      );

      final map = originalFeedback.toMap();
      final reconstructedFeedback = NPSFeedback.fromMap(map);

      expect(reconstructedFeedback.id, equals(originalFeedback.id));
      expect(reconstructedFeedback.serverId, equals(originalFeedback.serverId));
      expect(reconstructedFeedback.feedbackType,
          equals(originalFeedback.feedbackType));
      expect(reconstructedFeedback.salesAmount,
          equals(originalFeedback.salesAmount));
      expect(reconstructedFeedback.shiftPeriod,
          equals(originalFeedback.shiftPeriod));
    });
  });

  group('FeedbackCounts Tests', () {
    test('should calculate NPS percentage correctly', () {
      // 100% positive (5 yes, 0 no)
      final counts1 = FeedbackCounts(yes: 5, maybe: 0, no: 0);
      expect(counts1.npsPercentage, equals(100.0));

      // 0% neutral (0 yes, 5 maybe, 0 no)
      final counts2 = FeedbackCounts(yes: 0, maybe: 5, no: 0);
      expect(counts2.npsPercentage, equals(0.0));

      // -100% negative (0 yes, 0 maybe, 5 no)
      final counts3 = FeedbackCounts(yes: 0, maybe: 0, no: 5);
      expect(counts3.npsPercentage, equals(-100.0));

      // Mixed feedback (3 yes, 2 maybe, 1 no) = (3-1)/6 * 100 = 33.33%
      final counts4 = FeedbackCounts(yes: 3, maybe: 2, no: 1);
      expect(counts4.npsPercentage, closeTo(33.33, 0.01));

      // No feedback
      final counts5 = FeedbackCounts(yes: 0, maybe: 0, no: 0);
      expect(counts5.npsPercentage, equals(0.0));
    });

    test('should calculate total correctly', () {
      final counts = FeedbackCounts(yes: 3, maybe: 2, no: 1);
      expect(counts.total, equals(6));
    });

    test('should determine statistical significance', () {
      final insignificantCounts = FeedbackCounts(yes: 2, maybe: 1, no: 1);
      expect(insignificantCounts.hasSignificantSample, isFalse);

      final significantCounts = FeedbackCounts(yes: 5, maybe: 3, no: 2);
      expect(significantCounts.hasSignificantSample, isTrue);
    });
  });

  group('NPSMonthlyReport Tests', () {
    test('should create monthly report with valid data', () {
      final report = NPSMonthlyReport(
        serverId: '1',
        reportMonth: 202406,
        reportYear: 2024,
        allTimeNpsPercentage: 45.5,
        threeMonthNpsPercentage: 50.0,
        oneMonthNpsPercentage: 55.0,
        allTimeSales: 1000.00,
        allTimeTableCount: 50,
        monthFeedback: FeedbackCounts(yes: 8, maybe: 2, no: 1),
        threeMonthFeedback: FeedbackCounts(yes: 20, maybe: 5, no: 3),
        allTimeFeedback: FeedbackCounts(yes: 45, maybe: 10, no: 5),
        dataAsOfDate: DateTime(2024, 6, 30),
      );

  expect(report.serverId, equals('1'));
      expect(report.reportMonth, equals(202406));
      expect(report.monthName, equals('June'));
      expect(report.formattedMonth, equals('2024-06'));
    });

    test('should determine performance trend correctly', () {
      // Improving trend (1-month > 3-month)
      final improvingReport = NPSMonthlyReport(
        serverId: '1',
        reportMonth: 202406,
        reportYear: 2024,
        threeMonthNpsPercentage: 40.0,
        oneMonthNpsPercentage: 50.0,
        monthFeedback: FeedbackCounts(),
        threeMonthFeedback: FeedbackCounts(),
        allTimeFeedback: FeedbackCounts(),
        dataAsOfDate: DateTime(2024, 6, 30),
      );
      expect(
          improvingReport.performanceTrend, equals(PerformanceTrend.improving));

      // Declining trend (1-month < 3-month)
      final decliningReport = NPSMonthlyReport(
        serverId: '1',
        reportMonth: 202406,
        reportYear: 2024,
        threeMonthNpsPercentage: 50.0,
        oneMonthNpsPercentage: 40.0,
        monthFeedback: FeedbackCounts(),
        threeMonthFeedback: FeedbackCounts(),
        allTimeFeedback: FeedbackCounts(),
        dataAsOfDate: DateTime(2024, 6, 30),
      );
      expect(
          decliningReport.performanceTrend, equals(PerformanceTrend.declining));

      // Stable trend (small difference)
      final stableReport = NPSMonthlyReport(
        serverId: '1',
        reportMonth: 202406,
        reportYear: 2024,
        threeMonthNpsPercentage: 50.0,
        oneMonthNpsPercentage: 52.0,
        monthFeedback: FeedbackCounts(),
        threeMonthFeedback: FeedbackCounts(),
        allTimeFeedback: FeedbackCounts(),
        dataAsOfDate: DateTime(2024, 6, 30),
      );
      expect(stableReport.performanceTrend, equals(PerformanceTrend.stable));
    });

    test('should calculate average sales per table', () {
      final report = NPSMonthlyReport(
        serverId: '1',
        reportMonth: 202406,
        reportYear: 2024,
        allTimeSales: 1000.00,
        allTimeTableCount: 50,
        monthFeedback: FeedbackCounts(),
        threeMonthFeedback: FeedbackCounts(),
        allTimeFeedback: FeedbackCounts(),
        dataAsOfDate: DateTime(2024, 6, 30),
      );

      expect(report.averageSalesPerTable, equals(20.0));
      expect(report.formattedAverageSalesPerTable, equals('\$20.00'));
    });
  });

  group('NPSCalculator Utility Tests', () {
    test('should generate month keys correctly', () {
      final date = DateTime(2024, 6, 15);
      final monthKey = NPSCalculator.generateMonthKey(date);
      expect(monthKey, equals(202406));
    });

    test('should parse month keys correctly', () {
      final monthKey = 202406;
      final date = NPSCalculator.monthKeyToDateTime(monthKey);
      expect(date.year, equals(2024));
      expect(date.month, equals(6));
      expect(date.day, equals(1));
    });

    test('should format NPS scores correctly', () {
      expect(NPSCalculator.formatNPSScore(null), equals('N/A'));
      expect(NPSCalculator.formatNPSScore(50.0), equals('+50.0'));
      expect(NPSCalculator.formatNPSScore(-25.5), equals('-25.5'));
      expect(NPSCalculator.formatNPSScore(0.0), equals('0.0'));
      expect(NPSCalculator.formatNPSScore(50.0, includeSign: false),
          equals('50.0'));
    });

    test('should validate NPS scores correctly', () {
      expect(NPSCalculator.isValidNPSScore(null), isTrue);
      expect(NPSCalculator.isValidNPSScore(50.0), isTrue);
      expect(NPSCalculator.isValidNPSScore(-50.0), isTrue);
      expect(NPSCalculator.isValidNPSScore(100.0), isTrue);
      expect(NPSCalculator.isValidNPSScore(-100.0), isTrue);
      expect(NPSCalculator.isValidNPSScore(150.0), isFalse);
      expect(NPSCalculator.isValidNPSScore(-150.0), isFalse);
    });

    test('should categorize NPS ratings correctly', () {
      expect(NPSCalculator.getNPSRating(null), equals(NPSRating.none));
      expect(NPSCalculator.getNPSRating(75.0), equals(NPSRating.excellent));
      expect(NPSCalculator.getNPSRating(25.0), equals(NPSRating.good));
      expect(NPSCalculator.getNPSRating(-25.0), equals(NPSRating.poor));
      expect(NPSCalculator.getNPSRating(-75.0), equals(NPSRating.critical));
    });
  });

  group('NPSTrendAnalysis Tests', () {
    test('should analyze trends correctly', () {
      // Improving trend
      final improvingAnalysis = NPSTrendAnalysis(
        serverId: '1',
        oneMonthNPS: 60.0,
        threeMonthNPS: 50.0,
        allTimeNPS: 45.0,
        calculatedAt: DateTime.now(),
      );
      expect(improvingAnalysis.trend, equals(PerformanceTrend.improving));
      expect(improvingAnalysis.trendChange, equals(10.0));
      expect(improvingAnalysis.isSignificantTrend, isTrue);

      // Declining trend
      final decliningAnalysis = NPSTrendAnalysis(
        serverId: '1',
        oneMonthNPS: 40.0,
        threeMonthNPS: 55.0,
        allTimeNPS: 50.0,
        calculatedAt: DateTime.now(),
      );
      expect(decliningAnalysis.trend, equals(PerformanceTrend.declining));
      expect(decliningAnalysis.trendChange, equals(-15.0));
      expect(decliningAnalysis.isSignificantTrend, isTrue);

      // Stable trend
      final stableAnalysis = NPSTrendAnalysis(
        serverId: '1',
        oneMonthNPS: 52.0,
        threeMonthNPS: 50.0,
        allTimeNPS: 48.0,
        calculatedAt: DateTime.now(),
      );
      expect(stableAnalysis.trend, equals(PerformanceTrend.stable));
      expect(stableAnalysis.trendChange, equals(2.0));
      expect(stableAnalysis.isSignificantTrend, isFalse);
    });
  });
}
