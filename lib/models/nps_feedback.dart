/// Data model for NPS feedback entries
///
/// This model represents individual guest feedback responses about server performance.
library;

/// Enumeration for feedback types
enum FeedbackType {
  yes('yes'),
  maybe('maybe'),
  no('no');

  const FeedbackType(this.value);
  final String value;

  /// Create FeedbackType from string value
  static FeedbackType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'yes':
        return FeedbackType.yes;
      case 'maybe':
        return FeedbackType.maybe;
      case 'no':
        return FeedbackType.no;
      default:
        throw ArgumentError('Invalid feedback type: $value');
    }
  }

  /// Get display name for UI
  String get displayName {
    switch (this) {
      case FeedbackType.yes:
        return 'Yes';
      case FeedbackType.maybe:
        return 'Maybe';
      case FeedbackType.no:
        return 'No';
    }
  }

  /// Get NPS impact score
  int get npsImpact {
    switch (this) {
      case FeedbackType.yes:
        return 1; // Positive impact
      case FeedbackType.maybe:
        return 0; // Neutral impact
      case FeedbackType.no:
        return -1; // Negative impact
    }
  }
}

/// Enumeration for shift periods
enum ShiftPeriod {
  breakfast('breakfast'),
  lunch('lunch'),
  dinner('dinner'),
  lateNight('late_night');

  const ShiftPeriod(this.value);
  final String value;

  /// Create ShiftPeriod from string value
  static ShiftPeriod? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'breakfast':
        return ShiftPeriod.breakfast;
      case 'lunch':
        return ShiftPeriod.lunch;
      case 'dinner':
        return ShiftPeriod.dinner;
      case 'late_night':
        return ShiftPeriod.lateNight;
      default:
        return null;
    }
  }

  /// Get display name for UI
  String get displayName {
    switch (this) {
      case ShiftPeriod.breakfast:
        return 'Breakfast';
      case ShiftPeriod.lunch:
        return 'Lunch';
      case ShiftPeriod.dinner:
        return 'Dinner';
      case ShiftPeriod.lateNight:
        return 'Late Night';
    }
  }
}

/// Represents an individual guest feedback entry
class NPSFeedback {
  final int? id;
  final String serverId;
  final FeedbackType feedbackType;
  final DateTime feedbackDate;
  final double? salesAmount;
  final int? tableNumber;
  final ShiftPeriod? shiftPeriod;
  final int? guestCount;
  final String? notes;
  final DateTime? createdAt;

  NPSFeedback({
    this.id,
    required this.serverId,
    required this.feedbackType,
    required this.feedbackDate,
    this.salesAmount,
    this.tableNumber,
    this.shiftPeriod,
    this.guestCount,
    this.notes,
    this.createdAt,
  });

  /// Create NPSFeedback from a database map
  factory NPSFeedback.fromMap(Map<String, dynamic> map) {
    return NPSFeedback(
      id: map['id'] as int?,
      serverId: map['server_id'] as String,
      feedbackType: FeedbackType.fromString(map['feedback_type'] as String),
      feedbackDate: DateTime.parse(map['feedback_date'] as String),
      salesAmount: map['sales_amount'] != null
          ? (map['sales_amount'] as num).toDouble()
          : null,
      tableNumber: map['table_number'] as int?,
      shiftPeriod: ShiftPeriod.fromString(map['shift_period'] as String?),
      guestCount: map['guest_count'] as int?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  /// Convert NPSFeedback to a database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'server_id': serverId,
      'feedback_type': feedbackType.value,
      'feedback_date':
          feedbackDate.toIso8601String().split('T')[0], // Store as YYYY-MM-DD
      'sales_amount': salesAmount,
      'table_number': tableNumber,
      'shift_period': shiftPeriod?.value,
      'guest_count': guestCount,
      'notes': notes?.trim(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Create a copy of this feedback with updated fields
  NPSFeedback copyWith({
    int? id,
    String? serverId,
    FeedbackType? feedbackType,
    DateTime? feedbackDate,
    double? salesAmount,
    int? tableNumber,
    ShiftPeriod? shiftPeriod,
    int? guestCount,
    String? notes,
    DateTime? createdAt,
  }) {
    return NPSFeedback(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      feedbackType: feedbackType ?? this.feedbackType,
      feedbackDate: feedbackDate ?? this.feedbackDate,
      salesAmount: salesAmount ?? this.salesAmount,
      tableNumber: tableNumber ?? this.tableNumber,
      shiftPeriod: shiftPeriod ?? this.shiftPeriod,
      guestCount: guestCount ?? this.guestCount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'NPSFeedback{id: $id, serverId: $serverId, type: ${feedbackType.value}, date: $feedbackDate}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NPSFeedback &&
        other.id == id &&
        other.serverId == serverId &&
        other.feedbackType == feedbackType &&
        other.feedbackDate == feedbackDate;
  }

  @override
  int get hashCode {
    return Object.hash(id, serverId, feedbackType, feedbackDate);
  }

  /// Validation methods

  /// Check if the feedback data is valid
  bool isValid() {
    return serverId.isNotEmpty &&
        feedbackDate.isBefore(DateTime.now().add(const Duration(days: 1))) &&
        (salesAmount == null || salesAmount! >= 0) &&
        (tableNumber == null || tableNumber! > 0) &&
        (guestCount == null || guestCount! > 0);
  }

  /// Get validation errors
  List<String> getValidationErrors() {
    final errors = <String>[];

    if (serverId.isEmpty) {
      errors.add('Server ID must not be empty');
    }

    if (feedbackDate.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      errors.add('Feedback date cannot be in the future');
    }

    if (salesAmount != null && salesAmount! < 0) {
      errors.add('Sales amount cannot be negative');
    }

    if (tableNumber != null && tableNumber! <= 0) {
      errors.add('Table number must be positive');
    }

    if (guestCount != null && guestCount! <= 0) {
      errors.add('Guest count must be positive');
    }

    if (notes != null && notes!.length > 500) {
      errors.add('Notes cannot exceed 500 characters');
    }

    return errors;
  }

  /// Business logic methods

  /// Get NPS impact score for this feedback
  int get npsImpact => feedbackType.npsImpact;

  /// Check if this feedback is positive
  bool get isPositive => feedbackType == FeedbackType.yes;

  /// Check if this feedback is neutral
  bool get isNeutral => feedbackType == FeedbackType.maybe;

  /// Check if this feedback is negative
  bool get isNegative => feedbackType == FeedbackType.no;

  /// Get formatted feedback date
  String get formattedDate {
    return '${feedbackDate.year}-${feedbackDate.month.toString().padLeft(2, '0')}-${feedbackDate.day.toString().padLeft(2, '0')}';
  }

  /// Get formatted sales amount
  String get formattedSalesAmount {
    if (salesAmount == null) return 'N/A';
    return '\$${salesAmount!.toStringAsFixed(2)}';
  }

  /// Check if feedback is from a specific date
  bool isFromDate(DateTime date) {
    return feedbackDate.year == date.year &&
        feedbackDate.month == date.month &&
        feedbackDate.day == date.day;
  }

  /// Check if feedback is within a date range
  bool isWithinDateRange(DateTime startDate, DateTime endDate) {
    return feedbackDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
        feedbackDate.isBefore(endDate.add(const Duration(days: 1)));
  }

  /// Get month key for this feedback (YYYYMM format)
  int get monthKey {
    return feedbackDate.year * 100 + feedbackDate.month;
  }

  /// Get display text for feedback type
  String get feedbackTypeDisplay => feedbackType.displayName;

  /// Get display text for shift period
  String get shiftPeriodDisplay => shiftPeriod?.displayName ?? 'N/A';

  /// Get age of this feedback in days
  int get ageInDays {
    return DateTime.now().difference(feedbackDate).inDays;
  }

  /// Check if this is recent feedback (within last 7 days)
  bool get isRecent => ageInDays <= 7;

  /// Check if this feedback has sales data
  bool get hasSalesData => salesAmount != null && salesAmount! > 0;

  /// Check if this feedback has complete data
  bool get hasCompleteData {
    return salesAmount != null &&
        tableNumber != null &&
        shiftPeriod != null &&
        guestCount != null;
  }

  /// Get feedback quality score (0-100) based on completeness
  int get qualityScore {
    int score = 50; // Base score for having basic feedback

    if (salesAmount != null) score += 15;
    if (tableNumber != null) score += 10;
    if (shiftPeriod != null) score += 10;
    if (guestCount != null) score += 10;
    if (notes != null && notes!.trim().isNotEmpty) score += 5;

    return score.clamp(0, 100);
  }
}
