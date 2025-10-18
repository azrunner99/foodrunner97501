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
  /// NOTE: Returns null because individual feedback tracking is not used
  Future<double?> calculateAllTimeNPS(String serverId) async {
    // Individual feedback table is empty - admin enters NPS percentages directly
    return null;
  }

  /// Calculate three-month NPS for a specific server
  /// NOTE: Returns null because individual feedback tracking is not used
  Future<double?> calculateThreeMonthNPS(String serverId,
      [DateTime? endDate]) async {
    // Individual feedback table is empty - admin enters NPS percentages directly
    return null;
  }

  /// Calculate one-month NPS for a specific server
  /// NOTE: Returns null because individual feedback tracking is not used
  Future<double?> calculateOneMonthNPS(String serverId, int monthKey) async {
    // Individual feedback table is empty - admin enters NPS percentages directly
    return null;
  }

  /// Generate trend analysis for a server
  /// NOTE: Returns empty analysis because individual feedback tracking is not used
  Future<NPSTrendAnalysis> generateTrendAnalysis(String serverId) async {
    // Returns empty since we don't calculate from feedback
    return NPSTrendAnalysis(
      serverId: serverId,
      oneMonthNPS: null,
      threeMonthNPS: null,
      allTimeNPS: null,
      calculatedAt: DateTime.now(),
    );
  }

  /// Generate complete monthly report for a server
  /// NOTE: Returns empty report because individual feedback tracking is not used
  /// Use saveMonthlyReport() to save manually-entered data instead
  Future<NPSMonthlyReport> generateMonthlyReport(
      String serverId, int reportMonth) async {
    d('[NPSCalculator] WARNING: generateMonthlyReport called but returns empty (no feedback data)');
    d('[NPSCalculator] Admin should use monthly data entry widget to input reports manually');
    
    final year = reportMonth ~/ 100;
    final month = reportMonth % 100;

    // Return empty report since feedback table is empty
    return NPSMonthlyReport(
      serverId: serverId,
      reportMonth: reportMonth,
      reportYear: year,
      allTimeNpsPercentage: null,
      threeMonthNpsPercentage: null,
      oneMonthNpsPercentage: null,
      allTimeSales: 0.0,
      allTimeTableCount: 0,
      monthFeedback: FeedbackCounts(),
      threeMonthFeedback: FeedbackCounts(),
      allTimeFeedback: FeedbackCounts(),
      generatedAt: DateTime.now(),
      dataAsOfDate: DateTime(year, month + 1, 0),
    );
  }

  /// Generate monthly reports for all active servers
  /// NOTE: Returns empty reports because individual feedback tracking is not used
  /// Admin should use monthly data entry widget instead
  Future<List<NPSMonthlyReport>> generateMonthlyReportsForAllServers(
      int reportMonth) async {
    d('[NPSCalculator] WARNING: Auto-generation returns empty reports (no feedback data)');
    d('[NPSCalculator] Use monthly data entry widget to input reports manually');
    
    // Return empty list since we don't auto-calculate
    return [];
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
  /// NOTE: Does nothing because individual feedback tracking is not used
  /// Admin enters reports manually via the monthly data entry widget
  Future<List<NPSMonthlyReport>> processMonthlyReports(int reportMonth) async {
    d('[NPSCalculator] WARNING: processMonthlyReports does nothing (no feedback data)');
    d('[NPSCalculator] Admin should use monthly data entry widget');
    return [];
  }

  // REMOVED: Private helper methods that calculated from empty feedback table
  // - _calculateNPSFromFeedback()
  // - _getFeedbackCounts()
  // - _getCumulativeMetrics()
  // These are not needed since admin manually enters all NPS data

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
  final String serverId;
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
