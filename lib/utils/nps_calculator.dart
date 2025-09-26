/// NPS Calculator Engine
///
/// This class provides all the calculation logic for the Server NPS system,
/// including NPS score calculations, trend analysis, and report generation.
library;
import 'log.dart';

import '../storage/nps_database_adapter.dart';
import '../models/monthly_report.dart';

/// Core calculation engine for NPS metrics
class NPSCalculator {
  final NPSDatabaseAdapter _database;

  NPSCalculator(this._database);

  /// Calculate all-time NPS for a specific server
  Future<double?> calculateAllTimeNPS(int serverId) async {
    try {
      final feedback = await _database.getFeedbackForServer(serverId);
      return _calculateNPSFromFeedback(feedback);
    } catch (e) {
      d('[NPSCalculator] Error calculating all-time NPS: $e');
      return null;
    }
  }

  /// Calculate three-month NPS for a specific server
  Future<double?> calculateThreeMonthNPS(int serverId,
      [DateTime? endDate]) async {
    try {
      final end = endDate ?? DateTime.now();
      final start = DateTime(end.year, end.month - 3, end.day);

      final feedback = await _database.getFeedbackForServerInRange(
        serverId,
        startDate: start,
        endDate: end,
      );

      return _calculateNPSFromFeedback(feedback);
    } catch (e) {
      d('[NPSCalculator] Error calculating three-month NPS: $e');
      return null;
    }
  }

  /// Calculate one-month NPS for a specific server
  Future<double?> calculateOneMonthNPS(int serverId, int monthKey) async {
    try {
      final year = monthKey ~/ 100;
      final month = monthKey % 100;

      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0); // Last day of month

      final feedback = await _database.getFeedbackForServerInRange(
        serverId,
        startDate: startDate,
        endDate: endDate,
      );

      return _calculateNPSFromFeedback(feedback);
    } catch (e) {
      d('[NPSCalculator] Error calculating one-month NPS: $e');
      return null;
    }
  }

  /// Generate trend analysis for a server
  Future<NPSTrendAnalysis> generateTrendAnalysis(int serverId) async {
    try {
      final now = DateTime.now();
      final currentMonth = now.year * 100 + now.month;

      final oneMonthNPS = await calculateOneMonthNPS(serverId, currentMonth);
      final threeMonthNPS = await calculateThreeMonthNPS(serverId);
      final allTimeNPS = await calculateAllTimeNPS(serverId);

      return NPSTrendAnalysis(
        serverId: serverId,
        oneMonthNPS: oneMonthNPS,
        threeMonthNPS: threeMonthNPS,
        allTimeNPS: allTimeNPS,
        calculatedAt: now,
      );
    } catch (e) {
      d('[NPSCalculator] Error generating trend analysis: $e');
      return NPSTrendAnalysis(
        serverId: serverId,
        oneMonthNPS: null,
        threeMonthNPS: null,
        allTimeNPS: null,
        calculatedAt: DateTime.now(),
      );
    }
  }

  /// Generate complete monthly report for a server
  Future<NPSMonthlyReport> generateMonthlyReport(
      int serverId, int reportMonth) async {
    try {
      d('[NPSCalculator] Generating monthly report for server $serverId, month $reportMonth');

      final year = reportMonth ~/ 100;
      final month = reportMonth % 100;

      // Calculate NPS scores
      final allTimeNPS = await calculateAllTimeNPS(serverId);
      final threeMonthNPS =
          await calculateThreeMonthNPS(serverId, DateTime(year, month + 1, 0));
      final oneMonthNPS = await calculateOneMonthNPS(serverId, reportMonth);

      // Get feedback counts
      final allTimeFeedback = await _getFeedbackCounts(serverId);
      final threeMonthFeedback = await _getFeedbackCounts(
        serverId,
        DateTime(year, month - 2, 1),
        DateTime(year, month + 1, 0),
      );
      final monthFeedback = await _getFeedbackCounts(
        serverId,
        DateTime(year, month, 1),
        DateTime(year, month + 1, 0),
      );

      // Get cumulative metrics
      final allTimeMetrics = await _getCumulativeMetrics(serverId);

      return NPSMonthlyReport(
        serverId: serverId,
        reportMonth: reportMonth,
        reportYear: year,
        allTimeNpsPercentage: allTimeNPS,
        threeMonthNpsPercentage: threeMonthNPS,
        oneMonthNpsPercentage: oneMonthNPS,
        allTimeSales: allTimeMetrics['sales'] ?? 0.0,
        allTimeTableCount: allTimeMetrics['tableCount'] ?? 0,
        monthFeedback: monthFeedback,
        threeMonthFeedback: threeMonthFeedback,
        allTimeFeedback: allTimeFeedback,
        generatedAt: DateTime.now(),
        dataAsOfDate: DateTime(year, month + 1, 0),
      );
    } catch (e) {
      d('[NPSCalculator] Error generating monthly report: $e');
      rethrow;
    }
  }

  /// Generate monthly reports for all active servers
  Future<List<NPSMonthlyReport>> generateMonthlyReportsForAllServers(
      int reportMonth) async {
    try {
      final servers = await _database.getAllServers(activeOnly: true);
      final reports = <NPSMonthlyReport>[];

      for (final serverMap in servers) {
        final serverId = serverMap['id'] as int;
        try {
          final report = await generateMonthlyReport(serverId, reportMonth);
          reports.add(report);
        } catch (e) {
          d('[NPSCalculator] Error generating report for server $serverId: $e');
          // Continue with other servers
        }
      }

      d('[NPSCalculator] Generated ${reports.length} monthly reports');
      return reports;
    } catch (e) {
      d('[NPSCalculator] Error generating monthly reports for all servers: $e');
      rethrow;
    }
  }

  /// Save monthly report to database
  Future<void> saveMonthlyReport(NPSMonthlyReport report) async {
    try {
      // Use Android Sqflite format for all database operations
      final reportMap = report.toMap();
      d('[NPSCalculator] Using Android Sqflite format for saving report');
      
      await _database.insertOrUpdateMonthlyReport(reportMap);
      d('[NPSCalculator] Saved monthly report for server ${report.serverId}');
    } catch (e) {
      d('[NPSCalculator] Error saving monthly report: $e');
      rethrow;
    }
  }

  /// Process monthly report generation for a specific month
  Future<List<NPSMonthlyReport>> processMonthlyReports(int reportMonth) async {
    try {
      d('[NPSCalculator] Processing monthly reports for month $reportMonth');

      final reports = await generateMonthlyReportsForAllServers(reportMonth);

      // Save all reports to database
      for (final report in reports) {
        await saveMonthlyReport(report);
      }

      d('[NPSCalculator] Processed and saved ${reports.length} monthly reports');
      return reports;
    } catch (e) {
      d('[NPSCalculator] Error processing monthly reports: $e');
      rethrow;
    }
  }

  /// Private helper methods

  /// Calculate NPS from a list of feedback records
  double? _calculateNPSFromFeedback(
      List<Map<String, dynamic>> feedbackRecords) {
    if (feedbackRecords.isEmpty) return null;

    int yes = 0;
    int maybe = 0;
    int no = 0;

    for (final record in feedbackRecords) {
      final type = record['feedback_type'] as String;
      switch (type) {
        case 'yes':
          yes++;
          break;
        case 'maybe':
          maybe++;
          break;
        case 'no':
          no++;
          break;
      }
    }

    final total = yes + maybe + no;
    if (total == 0) return null;

    return ((yes - no) / total) * 100.0;
  }

  /// Get feedback counts for a server within a date range
  Future<FeedbackCounts> _getFeedbackCounts(
    int serverId, [
    DateTime? startDate,
    DateTime? endDate,
  ]) async {
    try {
      final feedback = await _database.getFeedbackForServerInRange(
        serverId,
        startDate: startDate,
        endDate: endDate,
      );

      int yes = 0;
      int maybe = 0;
      int no = 0;

      for (final record in feedback) {
        final type = record['feedback_type'] as String;
        switch (type) {
          case 'yes':
            yes++;
            break;
          case 'maybe':
            maybe++;
            break;
          case 'no':
            no++;
            break;
        }
      }

      return FeedbackCounts(yes: yes, maybe: maybe, no: no);
    } catch (e) {
      d('[NPSCalculator] Error getting feedback counts: $e');
      return FeedbackCounts();
    }
  }

  /// Get cumulative metrics (sales and table count) for a server
  Future<Map<String, dynamic>> _getCumulativeMetrics(int serverId) async {
    try {
      final feedback = await _database.getFeedbackForServer(serverId);

      double totalSales = 0.0;
      int tableCount = 0;
      final uniqueTables = <String>{};

      for (final record in feedback) {
        // Add sales if available
        final salesAmount = record['sales_amount'] as double?;
        if (salesAmount != null) {
          totalSales += salesAmount;
        }

        // Count unique tables
        final tableNumber = record['table_number'] as int?;
        final feedbackDate = record['feedback_date'] as String;
        if (tableNumber != null) {
          uniqueTables.add('${feedbackDate}_$tableNumber');
        }
      }

      tableCount = uniqueTables.length;

      return {
        'sales': totalSales,
        'tableCount': tableCount,
      };
    } catch (e) {
      d('[NPSCalculator] Error getting cumulative metrics: $e');
      return {'sales': 0.0, 'tableCount': 0};
    }
  }

  /// Utility methods

  /// Generate month key from date
  static int generateMonthKey(DateTime date) {
    return date.year * 100 + date.month;
  }

  /// Get current month key
  static int get currentMonthKey {
    final now = DateTime.now();
    return generateMonthKey(now);
  }

  /// Get previous month key
  static int get previousMonthKey {
    final now = DateTime.now();
    final previous = DateTime(now.year, now.month - 1, 1);
    return generateMonthKey(previous);
  }

  /// Parse month key to DateTime
  static DateTime monthKeyToDateTime(int monthKey) {
    final year = monthKey ~/ 100;
    final month = monthKey % 100;
    return DateTime(year, month, 1);
  }

  /// Get month name from month key
  static String monthKeyToName(int monthKey) {
    final date = monthKeyToDateTime(monthKey);
    const monthNames = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${monthNames[date.month]} ${date.year}';
  }

  /// Validate NPS score
  static bool isValidNPSScore(double? score) {
    if (score == null) return true; // null is valid (no data)
    return score >= -100.0 && score <= 100.0;
  }

  /// Format NPS score for display
  static String formatNPSScore(double? score, {bool includeSign = true}) {
    if (score == null) return 'N/A';

    final formatted = score.toStringAsFixed(1);
    if (includeSign && score > 0) {
      return '+$formatted';
    }
    return formatted;
  }

  /// Get NPS category from score
  static NPSRating getNPSRating(double? score) {
    if (score == null) return NPSRating.none;
    if (score >= 50) return NPSRating.excellent;
    if (score >= 0) return NPSRating.good;
    if (score >= -50) return NPSRating.poor;
    return NPSRating.critical;
  }
}

/// Trend analysis result for a server
class NPSTrendAnalysis {
  final int serverId;
  final double? oneMonthNPS;
  final double? threeMonthNPS;
  final double? allTimeNPS;
  final DateTime calculatedAt;

  NPSTrendAnalysis({
    required this.serverId,
    this.oneMonthNPS,
    this.threeMonthNPS,
    this.allTimeNPS,
    required this.calculatedAt,
  });

  /// Get performance trend
  PerformanceTrend get trend {
    if (oneMonthNPS == null || threeMonthNPS == null) {
      return PerformanceTrend.stable;
    }

    final difference = oneMonthNPS! - threeMonthNPS!;

    if (difference > 5.0) {
      return PerformanceTrend.improving;
    } else if (difference < -5.0) {
      return PerformanceTrend.declining;
    } else {
      return PerformanceTrend.stable;
    }
  }

  /// Get trend description
  String get trendDescription {
    switch (trend) {
      case PerformanceTrend.improving:
        return 'Improving ⬆️';
      case PerformanceTrend.declining:
        return 'Declining ⬇️';
      case PerformanceTrend.stable:
        return 'Stable ➡️';
    }
  }

  /// Get trend change amount
  double? get trendChange {
    if (oneMonthNPS == null || threeMonthNPS == null) return null;
    return oneMonthNPS! - threeMonthNPS!;
  }

  /// Get formatted trend change
  String get formattedTrendChange {
    final change = trendChange;
    if (change == null) return 'N/A';

    final formatted = change.abs().toStringAsFixed(1);
    if (change > 0) {
      return '+$formatted';
    } else if (change < 0) {
      return '-$formatted';
    } else {
      return '0.0';
    }
  }

  /// Check if trend is significant (change > 5 points)
  bool get isSignificantTrend {
    final change = trendChange;
    if (change == null) return false;
    return change.abs() > 5.0;
  }

  @override
  String toString() {
    return 'NPSTrendAnalysis{serverId: $serverId, trend: $trend, change: $trendChange}';
  }
}
