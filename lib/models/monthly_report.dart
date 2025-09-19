/// Data model for NPS monthly reports
///
/// This model represents pre-calculated monthly NPS reports that aggregate
/// feedback data and provide performance metrics for each server.
library;

/// Represents feedback counts for different time periods
class FeedbackCounts {
  final int yes;
  final int maybe;
  final int no;

  FeedbackCounts({
    this.yes = 0,
    this.maybe = 0,
    this.no = 0,
  });

  /// Total feedback count
  int get total => yes + maybe + no;

  /// Calculate NPS percentage from these counts
  double get npsPercentage {
    if (total == 0) return 0.0;
    return ((yes - no) / total) * 100.0;
  }

  /// Check if there's enough feedback for statistical significance
  bool get hasSignificantSample => total >= 10;

  /// Get positive feedback percentage
  double get positivePercentage {
    if (total == 0) return 0.0;
    return (yes / total) * 100.0;
  }

  /// Get neutral feedback percentage
  double get neutralPercentage {
    if (total == 0) return 0.0;
    return (maybe / total) * 100.0;
  }

  /// Get negative feedback percentage
  double get negativePercentage {
    if (total == 0) return 0.0;
    return (no / total) * 100.0;
  }

  @override
  String toString() {
    return 'FeedbackCounts{yes: $yes, maybe: $maybe, no: $no, total: $total}';
  }
}

/// Represents a complete monthly NPS report for a server
class NPSMonthlyReport {
  final int? id;
  final int serverId;
  final int reportMonth; // YYYYMM format
  final int reportYear;
  final double? allTimeNpsPercentage;
  final double? threeMonthNpsPercentage;
  final double? oneMonthNpsPercentage;
  final double allTimeSales;
  final int allTimeTableCount;
  final FeedbackCounts monthFeedback;
  final FeedbackCounts threeMonthFeedback;
  final FeedbackCounts allTimeFeedback;
  final DateTime? generatedAt;
  final DateTime dataAsOfDate;

  NPSMonthlyReport({
    this.id,
    required this.serverId,
    required this.reportMonth,
    required this.reportYear,
    this.allTimeNpsPercentage,
    this.threeMonthNpsPercentage,
    this.oneMonthNpsPercentage,
    this.allTimeSales = 0.0,
    this.allTimeTableCount = 0,
    required this.monthFeedback,
    required this.threeMonthFeedback,
    required this.allTimeFeedback,
    this.generatedAt,
    required this.dataAsOfDate,
  });

  /// Create NPSMonthlyReport from a database map
  factory NPSMonthlyReport.fromMap(Map<String, dynamic> map) {
    return NPSMonthlyReport(
      id: map['id'] as int?,
      serverId: map['server_id'] as int,
      reportMonth: map['report_month'] as int,
      reportYear: map['report_year'] as int,
      allTimeNpsPercentage: map['all_time_nps_percentage'] != null
          ? (map['all_time_nps_percentage'] as num).toDouble()
          : null,
      threeMonthNpsPercentage: map['three_month_nps_percentage'] != null
          ? (map['three_month_nps_percentage'] as num).toDouble()
          : null,
      oneMonthNpsPercentage: map['one_month_nps_percentage'] != null
          ? (map['one_month_nps_percentage'] as num).toDouble()
          : null,
      allTimeSales: (map['all_time_sales'] as num?)?.toDouble() ?? 0.0,
      allTimeTableCount: map['all_time_table_count'] as int? ?? 0,
      monthFeedback: FeedbackCounts(
        yes: map['month_feedback_yes'] as int? ?? 0,
        maybe: map['month_feedback_maybe'] as int? ?? 0,
        no: map['month_feedback_no'] as int? ?? 0,
      ),
      threeMonthFeedback: FeedbackCounts(
        yes: map['three_month_feedback_yes'] as int? ?? 0,
        maybe: map['three_month_feedback_maybe'] as int? ?? 0,
        no: map['three_month_feedback_no'] as int? ?? 0,
      ),
      allTimeFeedback: FeedbackCounts(
        yes: map['all_time_feedback_yes'] as int? ?? 0,
        maybe: map['all_time_feedback_maybe'] as int? ?? 0,
        no: map['all_time_feedback_no'] as int? ?? 0,
      ),
      generatedAt: map['generated_at'] != null
          ? DateTime.parse(map['generated_at'] as String)
          : null,
      dataAsOfDate: DateTime.parse(map['data_as_of_date'] as String),
    );
  }

  /// Convert NPSMonthlyReport to a database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'server_id': serverId,
      'report_month': reportMonth,
      'report_year': reportYear,
      'all_time_nps_percentage': allTimeNpsPercentage,
      'three_month_nps_percentage': threeMonthNpsPercentage,
      'one_month_nps_percentage': oneMonthNpsPercentage,
      'all_time_sales': allTimeSales,
      'all_time_table_count': allTimeTableCount,
      'month_feedback_yes': monthFeedback.yes,
      'month_feedback_maybe': monthFeedback.maybe,
      'month_feedback_no': monthFeedback.no,
      'three_month_feedback_yes': threeMonthFeedback.yes,
      'three_month_feedback_maybe': threeMonthFeedback.maybe,
      'three_month_feedback_no': threeMonthFeedback.no,
      'all_time_feedback_yes': allTimeFeedback.yes,
      'all_time_feedback_maybe': allTimeFeedback.maybe,
      'all_time_feedback_no': allTimeFeedback.no,
      'generated_at': generatedAt?.toIso8601String(),
      'data_as_of_date': dataAsOfDate.toIso8601String().split('T')[0],
    };
  }

  /// Create a copy of this report with updated fields
  NPSMonthlyReport copyWith({
    int? id,
    int? serverId,
    int? reportMonth,
    int? reportYear,
    double? allTimeNpsPercentage,
    double? threeMonthNpsPercentage,
    double? oneMonthNpsPercentage,
    double? allTimeSales,
    int? allTimeTableCount,
    FeedbackCounts? monthFeedback,
    FeedbackCounts? threeMonthFeedback,
    FeedbackCounts? allTimeFeedback,
    DateTime? generatedAt,
    DateTime? dataAsOfDate,
  }) {
    return NPSMonthlyReport(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      reportMonth: reportMonth ?? this.reportMonth,
      reportYear: reportYear ?? this.reportYear,
      allTimeNpsPercentage: allTimeNpsPercentage ?? this.allTimeNpsPercentage,
      threeMonthNpsPercentage:
          threeMonthNpsPercentage ?? this.threeMonthNpsPercentage,
      oneMonthNpsPercentage:
          oneMonthNpsPercentage ?? this.oneMonthNpsPercentage,
      allTimeSales: allTimeSales ?? this.allTimeSales,
      allTimeTableCount: allTimeTableCount ?? this.allTimeTableCount,
      monthFeedback: monthFeedback ?? this.monthFeedback,
      threeMonthFeedback: threeMonthFeedback ?? this.threeMonthFeedback,
      allTimeFeedback: allTimeFeedback ?? this.allTimeFeedback,
      generatedAt: generatedAt ?? this.generatedAt,
      dataAsOfDate: dataAsOfDate ?? this.dataAsOfDate,
    );
  }

  @override
  String toString() {
    return 'NPSMonthlyReport{serverId: $serverId, month: $reportMonth, allTimeNPS: $allTimeNpsPercentage}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NPSMonthlyReport &&
        other.serverId == serverId &&
        other.reportMonth == reportMonth;
  }

  @override
  int get hashCode {
    return Object.hash(serverId, reportMonth);
  }

  /// Business logic methods

  /// Get the month and year as a formatted string
  String get formattedMonth {
    final month = reportMonth % 100;
    return '$reportYear-${month.toString().padLeft(2, '0')}';
  }

  /// Get the month name
  String get monthName {
    final month = reportMonth % 100;
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
    return monthNames[month];
  }

  /// Get performance trend analysis
  PerformanceTrend get performanceTrend {
    if (oneMonthNpsPercentage == null || threeMonthNpsPercentage == null) {
      return PerformanceTrend.stable;
    }

    final difference = oneMonthNpsPercentage! - threeMonthNpsPercentage!;

    if (difference > 5.0) {
      return PerformanceTrend.improving;
    } else if (difference < -5.0) {
      return PerformanceTrend.declining;
    } else {
      return PerformanceTrend.stable;
    }
  }

  /// Get trend description for UI
  String get trendDescription {
    switch (performanceTrend) {
      case PerformanceTrend.improving:
        return 'Improving ⬆️';
      case PerformanceTrend.declining:
        return 'Declining ⬇️';
      case PerformanceTrend.stable:
        return 'Stable ➡️';
    }
  }

  /// Get NPS rating category for one-month performance
  NPSRating get oneMonthRating => _getRating(oneMonthNpsPercentage);

  /// Get NPS rating category for three-month performance
  NPSRating get threeMonthRating => _getRating(threeMonthNpsPercentage);

  /// Get NPS rating category for all-time performance
  NPSRating get allTimeRating => _getRating(allTimeNpsPercentage);

  NPSRating _getRating(double? nps) {
    if (nps == null) return NPSRating.none;
    if (nps >= 50) return NPSRating.excellent;
    if (nps >= 0) return NPSRating.good;
    if (nps >= -50) return NPSRating.poor;
    return NPSRating.critical;
  }

  /// Check if there's sufficient data for reliable analysis
  bool get hasReliableData {
    return allTimeFeedback.total >= 10 && threeMonthFeedback.total >= 5;
  }

  /// Get data quality score (0-100)
  int get dataQualityScore {
    int score = 0;

    // Base score for having data
    if (allTimeFeedback.total > 0) score += 20;

    // Bonus for sample size
    if (allTimeFeedback.total >= 10) score += 20;
    if (allTimeFeedback.total >= 50) score += 10;
    if (allTimeFeedback.total >= 100) score += 10;

    // Bonus for recent data
    if (monthFeedback.total > 0) score += 15;
    if (threeMonthFeedback.total >= 5) score += 15;

    // Bonus for having sales data
    if (allTimeSales > 0) score += 5;
    if (allTimeTableCount > 0) score += 5;

    return score.clamp(0, 100);
  }

  /// Get primary NPS score (preferring shorter-term data when available)
  double? get primaryNpsScore {
    if (oneMonthNpsPercentage != null && monthFeedback.hasSignificantSample) {
      return oneMonthNpsPercentage;
    }
    if (threeMonthNpsPercentage != null &&
        threeMonthFeedback.hasSignificantSample) {
      return threeMonthNpsPercentage;
    }
    return allTimeNpsPercentage;
  }

  /// Get formatted sales amount
  String get formattedSales {
    return '\$${allTimeSales.toStringAsFixed(2)}';
  }

  /// Get average sales per table
  double get averageSalesPerTable {
    if (allTimeTableCount == 0) return 0.0;
    return allTimeSales / allTimeTableCount;
  }

  /// Get formatted average sales per table
  String get formattedAverageSalesPerTable {
    return '\$${averageSalesPerTable.toStringAsFixed(2)}';
  }

  /// Check if this is a recent report
  bool get isRecent {
    if (generatedAt == null) return false;
    return DateTime.now().difference(generatedAt!).inDays <= 7;
  }

  /// Get age of report in days
  int get ageInDays {
    if (generatedAt == null) return 0;
    return DateTime.now().difference(generatedAt!).inDays;
  }
}

/// Enumeration for performance trend
enum PerformanceTrend {
  improving,
  stable,
  declining,
}

/// Enumeration for NPS rating categories
enum NPSRating {
  excellent, // 50+
  good, // 0 to 49
  poor, // -1 to -49
  critical, // -50 or below
  none, // No data
}

extension NPSRatingExtension on NPSRating {
  String get displayName {
    switch (this) {
      case NPSRating.excellent:
        return 'Excellent';
      case NPSRating.good:
        return 'Good';
      case NPSRating.poor:
        return 'Poor';
      case NPSRating.critical:
        return 'Critical';
      case NPSRating.none:
        return 'No Data';
    }
  }

  String get description {
    switch (this) {
      case NPSRating.excellent:
        return 'Outstanding performance';
      case NPSRating.good:
        return 'Solid performance';
      case NPSRating.poor:
        return 'Needs improvement';
      case NPSRating.critical:
        return 'Requires immediate attention';
      case NPSRating.none:
        return 'Insufficient data';
    }
  }
}
