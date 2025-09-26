import 'package:flutter/material.dart';

/// Data quality classification for performance scoring
/// Phase 1: Data Hygiene & Safeguards
enum DataQuality {
  complete,    // NPS + sales + shifts ≥ threshold
  partial,     // Some components missing
  sparse,      // Below shift or feedback threshold
  missing      // Insufficient data for scoring
}

/// Confidence level for performance calculations
/// Phase 2: Baseline & Fallback Reform
enum ConfidenceLevel {
  high,        // 90-100% confidence - all data present
  medium,      // 70-89% confidence - most data present
  low,         // 50-69% confidence - limited data
  veryLow      // <50% confidence - minimal data
}

/// Performance tier classification for differentiation
/// Phase 3: Differentiation Mechanics
enum PerformanceTier {
  topPerformer,    // Top 20% - exceptional performance
  good,            // 20-60% - above average performance
  average,         // 60-80% - average performance
  needsImprovement // Bottom 20% - below average performance
}

/// Performance trend direction for temporal analysis
/// Phase 4: Temporal Derivation Layer
enum PerformanceTrendDirection {
  improving,       // Performance is getting better over time
  stable,          // Performance is consistent
  declining,       // Performance is getting worse over time
  volatile         // Performance is inconsistent/erratic
}

/// Seasonal pattern classification
/// Phase 4: Temporal Derivation Layer
enum SeasonalPattern {
  none,            // No clear seasonal pattern
  monthly,         // Monthly patterns (e.g., end-of-month busy)
  weekly,          // Weekly patterns (e.g., weekend busy)
  daily,           // Daily patterns (e.g., lunch vs dinner)
  holiday,         // Holiday-related patterns
  mixed            // Multiple seasonal patterns
}

/// Time weighting strategy for performance calculations
/// Phase 4: Temporal Derivation Layer
enum TimeWeightingStrategy {
  linear,          // Linear decay over time
  exponential,     // Exponential decay (recent data weighted more)
  seasonal,        // Seasonal-aware weighting
  adaptive         // Adaptive based on data patterns
}

/// Adaptive weighting strategy for performance calculations
/// Phase 5: Adaptive Weighting & Confidence
enum AdaptiveWeightingStrategy {
  static,          // Fixed weights based on data quality
  dynamic,         // Weights adjust based on data patterns
  learning,        // Machine learning-based weight optimization
  hybrid           // Combination of static and dynamic approaches
}

/// Confidence interval type for uncertainty quantification
/// Phase 5: Adaptive Weighting & Confidence
enum ConfidenceIntervalType {
  standard,        // Standard statistical confidence interval
  bootstrap,       // Bootstrap-based confidence interval
  bayesian,        // Bayesian credible interval
  empirical        // Empirical distribution-based interval
}

/// Uncertainty level for performance scores
/// Phase 5: Adaptive Weighting & Confidence
enum UncertaintyLevel {
  veryLow,         // <5% uncertainty - highly reliable
  low,             // 5-15% uncertainty - reliable
  medium,          // 15-30% uncertainty - moderate reliability
  high,            // 30-50% uncertainty - low reliability
  veryHigh         // >50% uncertainty - very low reliability
}

/// Performance monitoring event types
/// Phase 6: Monitoring & Telemetry
enum PerformanceEventType {
  scoreCalculation,    // Performance score calculated
  dataQualityChange,   // Data quality assessment changed
  confidenceUpdate,    // Confidence level updated
  trendDetection,      // Performance trend detected
  anomalyDetected,     // Performance anomaly detected
  alertTriggered,      // Performance alert triggered
  systemHealth,        // System health check
  userInteraction      // User interaction with performance data
}

/// Alert severity levels for performance monitoring
/// Phase 6: Monitoring & Telemetry
enum AlertSeverity {
  info,            // Informational alert
  warning,         // Warning level alert
  critical,        // Critical performance issue
  emergency        // Emergency performance failure
}

/// Performance monitoring status
/// Phase 6: Monitoring & Telemetry
enum MonitoringStatus {
  active,          // Monitoring is active
  paused,          // Monitoring is paused
  maintenance,     // System in maintenance mode
  error            // Monitoring system error
}

/// Rollout deployment status
/// Phase 7: Rollout & Reconciliation
enum RolloutStatus {
  pending,         // Rollout is pending
  inProgress,      // Rollout is currently in progress
  completed,       // Rollout completed successfully
  failed,          // Rollout failed
  rolledBack,      // Rollout was rolled back
  paused           // Rollout is paused
}

/// Validation result status
/// Phase 7: Rollout & Reconciliation
enum ValidationStatus {
  passed,          // Validation passed
  failed,          // Validation failed
  warning,         // Validation passed with warnings
  skipped          // Validation was skipped
}

/// Reconciliation operation type
/// Phase 7: Rollout & Reconciliation
enum ReconciliationType {
  dataMigration,   // Data migration between systems
  scoreRecalculation, // Recalculation of performance scores
  validationCheck, // Validation of data integrity
  rollback,        // Rollback operation
  cleanup          // Cleanup operation
}

/// Represents shift complexity factors for performance calculation
class ShiftComplexity {
  final String shiftType; // "lunch", "dinner", "double"
  final double difficultyMultiplier; // 1.0 = baseline, 1.5 = busy dinner
  final int guestCount;
  final double sales;
  final DateTime date;

  ShiftComplexity({
    required this.shiftType,
    required this.difficultyMultiplier,
    required this.guestCount,
    required this.sales,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'shiftType': shiftType,
        'difficultyMultiplier': difficultyMultiplier,
        'guestCount': guestCount,
        'sales': sales,
        'date': date.toIso8601String(),
      };

  static ShiftComplexity fromMap(Map<String, dynamic> map) => ShiftComplexity(
        shiftType: map['shiftType'] as String,
        difficultyMultiplier: (map['difficultyMultiplier'] as num).toDouble(),
        guestCount: map['guestCount'] as int,
        sales: (map['sales'] as num).toDouble(),
        date: DateTime.parse(map['date'] as String),
      );
}

/// Net Promoter Score data for server guest satisfaction tracking
class NPSData {
  final String serverId;
  final DateTime month;
  final double monthlyScore; // 0-100%
  final double threeMonthAverage; // Most important metric
  final int responseCount;
  final Map<String, double>
      categoryBreakdown; // service, food, atmosphere, etc.
  final List<String> guestComments;
  final DateTime lastUpdated;
  final bool hasActualNpsData; // Phase 2: Distinguish between no data vs 0% data

  NPSData({
    required this.serverId,
    required this.month,
    required this.monthlyScore,
    required this.threeMonthAverage,
    required this.responseCount,
    required this.categoryBreakdown,
    required this.guestComments,
    required this.lastUpdated,
    this.hasActualNpsData = true, // Default to true for backward compatibility
  });

  Map<String, dynamic> toMap() => {
        'serverId': serverId,
        'month': month.toIso8601String(),
        'monthlyScore': monthlyScore,
        'threeMonthAverage': threeMonthAverage,
        'responseCount': responseCount,
        'categoryBreakdown': categoryBreakdown,
        'guestComments': guestComments,
        'lastUpdated': lastUpdated.toIso8601String(),
        'hasActualNpsData': hasActualNpsData,
      };

  static NPSData fromMap(Map<String, dynamic> map) => NPSData(
        serverId: map['serverId'] as String,
        month: DateTime.parse(map['month'] as String),
        monthlyScore: (map['monthlyScore'] as num).toDouble(),
        threeMonthAverage: (map['threeMonthAverage'] as num).toDouble(),
        responseCount: map['responseCount'] as int,
        categoryBreakdown: Map<String, double>.from(
            (map['categoryBreakdown'] as Map)
                .map((k, v) => MapEntry(k.toString(), (v as num).toDouble()))),
        guestComments: List<String>.from(map['guestComments'] as List),
        lastUpdated: DateTime.parse(map['lastUpdated'] as String),
        hasActualNpsData: map['hasActualNpsData'] as bool? ?? true, // Default to true for backward compatibility
      );

  /// Get NPS category based on score
  NPSCategory get category {
    if (threeMonthAverage >= 80) return NPSCategory.exceptional;
    if (threeMonthAverage >= 70) return NPSCategory.excellent;
    if (threeMonthAverage >= 60) return NPSCategory.good;
    if (threeMonthAverage >= 50) return NPSCategory.fair;
    return NPSCategory.needsImprovement;
  }
}

/// NPS performance categories
enum NPSCategory {
  exceptional, // 80-100: World-class guest service
  excellent, // 70-79: Outstanding guest satisfaction
  good, // 60-69: Above average service
  fair, // 50-59: Meets expectations
  needsImprovement, // 0-49: Below expectations, requires coaching
}

extension NPSCategoryExtension on NPSCategory {
  String get displayName {
    switch (this) {
      case NPSCategory.exceptional:
        return 'Exceptional';
      case NPSCategory.excellent:
        return 'Excellent';
      case NPSCategory.good:
        return 'Good';
      case NPSCategory.fair:
        return 'Fair';
      case NPSCategory.needsImprovement:
        return 'Needs Improvement';
    }
  }

  String get emoji {
    switch (this) {
      case NPSCategory.exceptional:
        return '🌟';
      case NPSCategory.excellent:
        return '⭐';
      case NPSCategory.good:
        return '👍';
      case NPSCategory.fair:
        return '👌';
      case NPSCategory.needsImprovement:
        return '📈';
    }
  }

  Color get color {
    switch (this) {
      case NPSCategory.exceptional:
        return const Color(0xFF4CAF50);
      case NPSCategory.excellent:
        return const Color(0xFF8BC34A);
      case NPSCategory.good:
        return const Color(0xFF2196F3);
      case NPSCategory.fair:
        return const Color(0xFFFF9800);
      case NPSCategory.needsImprovement:
        return const Color(0xFFF44336);
    }
  }
}

/// Enhanced monthly business data with NPS integration
class EnhancedMonthlyBusinessData {
  final DateTime month;
  final int totalGuests;
  final double totalSales;
  final Map<String, NPSData> serverNPSData;
  final double restaurantNPSAverage;
  final Map<String, int> serverShiftCounts;
  final Map<String, double> serverSalesShare;
  final DateTime lastUpdated;

  EnhancedMonthlyBusinessData({
    required this.month,
    required this.totalGuests,
    required this.totalSales,
    required this.serverNPSData,
    required this.restaurantNPSAverage,
    required this.serverShiftCounts,
    required this.serverSalesShare,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() => {
        'month': month.toIso8601String(),
        'totalGuests': totalGuests,
        'totalSales': totalSales,
        'serverNPSData': serverNPSData.map((k, v) => MapEntry(k, v.toMap())),
        'restaurantNPSAverage': restaurantNPSAverage,
        'serverShiftCounts': serverShiftCounts,
        'serverSalesShare': serverSalesShare,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  static EnhancedMonthlyBusinessData fromMap(Map<String, dynamic> map) =>
      EnhancedMonthlyBusinessData(
        month: DateTime.parse(map['month'] as String),
        totalGuests: map['totalGuests'] as int,
        totalSales: (map['totalSales'] as num).toDouble(),
        serverNPSData: (map['serverNPSData'] as Map).map((k, v) =>
            MapEntry(k.toString(), NPSData.fromMap(v as Map<String, dynamic>))),
        restaurantNPSAverage: (map['restaurantNPSAverage'] as num).toDouble(),
        serverShiftCounts:
            Map<String, int>.from(map['serverShiftCounts'] as Map),
        serverSalesShare: Map<String, double>.from(
            (map['serverSalesShare'] as Map)
                .map((k, v) => MapEntry(k.toString(), (v as num).toDouble()))),
        lastUpdated: DateTime.parse(map['lastUpdated'] as String),
      );
}

/// Performance rating categories
enum PerformanceRating {
  elite, // 90-100: Exceptional performers, natural leaders
  strong, // 75-89: Solid performers, reliable team members
  developing, // 60-74: Improving performers, coaching opportunities
  needsAttention, // 45-59: Underperforming, requires intervention
  critical, // 0-44: Serious performance issues, action required
}

extension PerformanceRatingExtension on PerformanceRating {
  String get displayName {
    switch (this) {
      case PerformanceRating.elite:
        return 'Elite';
      case PerformanceRating.strong:
        return 'Strong';
      case PerformanceRating.developing:
        return 'Developing';
      case PerformanceRating.needsAttention:
        return 'Needs Attention';
      case PerformanceRating.critical:
        return 'Critical';
    }
  }

  String get emoji {
    switch (this) {
      case PerformanceRating.elite:
        return '🌟';
      case PerformanceRating.strong:
        return '✅';
      case PerformanceRating.developing:
        return '📈';
      case PerformanceRating.needsAttention:
        return '⚠️';
      case PerformanceRating.critical:
        return '🚨';
    }
  }

  double get minScore {
    switch (this) {
      case PerformanceRating.elite:
        return 90.0;
      case PerformanceRating.strong:
        return 75.0;
      case PerformanceRating.developing:
        return 60.0;
      case PerformanceRating.needsAttention:
        return 45.0;
      case PerformanceRating.critical:
        return 0.0;
    }
  }

  static PerformanceRating fromScore(double score) {
    if (score >= 90.0) return PerformanceRating.elite;
    if (score >= 75.0) return PerformanceRating.strong;
    if (score >= 60.0) return PerformanceRating.developing;
    if (score >= 45.0) return PerformanceRating.needsAttention;
    return PerformanceRating.critical;
  }
}

/// Performance flag types for alerts and insights
enum PerformanceFlag {
  highPerformer, // 🔥 Consistently exceeds expectations
  decliningTrend, // 📉 Performance dropping over time
  inconsistent, // 🎯 High variance in performance
  lowEfficiency, // 🐌 Below minimum thresholds
  newHire, // 👶 In training/adjustment period
  teamLeader, // 🏆 Top performer in peer group
  recognitionDue, // 🎖️ Eligible for recognition
  coachingNeeded, // 📚 Would benefit from training
}

extension PerformanceFlagExtension on PerformanceFlag {
  String get displayName {
    switch (this) {
      case PerformanceFlag.highPerformer:
        return 'High Performer';
      case PerformanceFlag.decliningTrend:
        return 'Declining Trend';
      case PerformanceFlag.inconsistent:
        return 'Inconsistent';
      case PerformanceFlag.lowEfficiency:
        return 'Low Efficiency';
      case PerformanceFlag.newHire:
        return 'New Hire';
      case PerformanceFlag.teamLeader:
        return 'Team Leader';
      case PerformanceFlag.recognitionDue:
        return 'Recognition Due';
      case PerformanceFlag.coachingNeeded:
        return 'Coaching Needed';
    }
  }

  String get emoji {
    switch (this) {
      case PerformanceFlag.highPerformer:
        return '🔥';
      case PerformanceFlag.decliningTrend:
        return '📉';
      case PerformanceFlag.inconsistent:
        return '🎯';
      case PerformanceFlag.lowEfficiency:
        return '🐌';
      case PerformanceFlag.newHire:
        return '👶';
      case PerformanceFlag.teamLeader:
        return '🏆';
      case PerformanceFlag.recognitionDue:
        return '🎖️';
      case PerformanceFlag.coachingNeeded:
        return '📚';
    }
  }
}

/// Core performance metrics for a server
class PerformanceMetrics {
  final double rawEfficiency; // Total food runs ÷ shifts worked
  final double guestEfficiency; // Total food runs ÷ total guests served
  final double salesEfficiency; // Total food runs ÷ total sales ($1000s)
  final double consistencyScore; // 0-100, based on performance variance
  final double experienceFactor; // 0-1, tenure adjustment
  final double adjustedPerformance; // Complexity-adjusted performance
  final double npsScore; // Weighted NPS score including trend analysis
  final double npsThreeMonth; // 3-month NPS average (primary metric)
  final double npsOneMonth; // 1-month NPS average (trend indicator)

  PerformanceMetrics({
    required this.rawEfficiency,
    required this.guestEfficiency,
    required this.salesEfficiency,
    required this.consistencyScore,
    required this.experienceFactor,
    required this.adjustedPerformance,
    required this.npsScore,
    required this.npsThreeMonth,
    required this.npsOneMonth,
  });

  Map<String, dynamic> toMap() => {
        'rawEfficiency': rawEfficiency,
        'guestEfficiency': guestEfficiency,
        'salesEfficiency': salesEfficiency,
        'consistencyScore': consistencyScore,
        'experienceFactor': experienceFactor,
        'adjustedPerformance': adjustedPerformance,
        'npsScore': npsScore,
        'npsThreeMonth': npsThreeMonth,
        'npsOneMonth': npsOneMonth,
      };

  static PerformanceMetrics fromMap(Map<String, dynamic> map) =>
      PerformanceMetrics(
        rawEfficiency: (map['rawEfficiency'] as num).toDouble(),
        guestEfficiency: (map['guestEfficiency'] as num).toDouble(),
        salesEfficiency: (map['salesEfficiency'] as num).toDouble(),
        consistencyScore: (map['consistencyScore'] as num).toDouble(),
        experienceFactor: (map['experienceFactor'] as num).toDouble(),
        adjustedPerformance: (map['adjustedPerformance'] as num).toDouble(),
        npsScore: (map['npsScore'] as num?)?.toDouble() ?? 50.0,
        npsThreeMonth: (map['npsThreeMonth'] as num?)?.toDouble() ?? 50.0,
        npsOneMonth: (map['npsOneMonth'] as num?)?.toDouble() ?? 50.0,
      );
}


extension DataQualityExtension on DataQuality {
  String get label {
    switch (this) {
      case DataQuality.complete:
        return 'Complete';
      case DataQuality.partial:
        return 'Partial';
      case DataQuality.sparse:
        return 'Sparse';
      case DataQuality.missing:
        return 'Missing';
    }
  }

  String get emoji {
    switch (this) {
      case DataQuality.complete:
        return '✅';
      case DataQuality.partial:
        return '🟡';
      case DataQuality.sparse:
        return '⚠️';
      case DataQuality.missing:
        return '❌';
    }
  }
}

/// Monthly business data for the entire restaurant
class MonthlyBusinessData {
  final DateTime month;
  final double totalGuestCount;
  final double totalSales;
  final Map<String, double> serverSpecificGuests;
  final Map<String, double> serverSpecificSales;
  final bool validated;
  final DateTime entryDate;

  MonthlyBusinessData({
    required this.month,
    required this.totalGuestCount,
    required this.totalSales,
    required this.serverSpecificGuests,
    required this.serverSpecificSales,
    required this.validated,
    required this.entryDate,
  });

  Map<String, dynamic> toMap() => {
        'month': month.toIso8601String(),
        'totalGuestCount': totalGuestCount,
        'totalSales': totalSales,
        'serverSpecificGuests': serverSpecificGuests,
        'serverSpecificSales': serverSpecificSales,
        'validated': validated,
        'entryDate': entryDate.toIso8601String(),
      };

  static MonthlyBusinessData fromMap(Map<String, dynamic> map) =>
      MonthlyBusinessData(
        month: DateTime.parse(map['month'] as String),
        totalGuestCount: (map['totalGuestCount'] as num).toDouble(),
        totalSales: (map['totalSales'] as num).toDouble(),
        serverSpecificGuests:
            Map<String, double>.from(map['serverSpecificGuests'] ?? {}),
        serverSpecificSales:
            Map<String, double>.from(map['serverSpecificSales'] ?? {}),
        validated: map['validated'] as bool,
        entryDate: DateTime.parse(map['entryDate'] as String),
      );
}

/// Performance insight/recommendation for management
class PerformanceInsight {
  final String type; // "recommendation", "alert", "recognition"
  final String title;
  final String description;
  final String priority; // "high", "medium", "low"
  final List<String> actionItems;
  final DateTime generatedDate;
  final String serverId;

  PerformanceInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    required this.actionItems,
    required this.generatedDate,
    required this.serverId,
  });

  Map<String, dynamic> toMap() => {
        'type': type,
        'title': title,
        'description': description,
        'priority': priority,
        'actionItems': actionItems,
        'generatedDate': generatedDate.toIso8601String(),
        'serverId': serverId,
      };

  static PerformanceInsight fromMap(Map<String, dynamic> map) =>
      PerformanceInsight(
        type: map['type'] as String,
        title: map['title'] as String,
        description: map['description'] as String,
        priority: map['priority'] as String,
        actionItems: List<String>.from(map['actionItems']),
        generatedDate: DateTime.parse(map['generatedDate'] as String),
        serverId: map['serverId'] as String,
      );
}

/// Comprehensive performance data for a server over a specific period
class ServerPerformanceData {
  final String serverId;
  final DateTime startDate;
  final DateTime endDate;
  final int totalFoodRuns;
  final int shiftsWorked;
  final int daysEmployed;
  final double totalGuestCount;
  final double totalSales;
  final List<ShiftComplexity> shiftTypes;
  final PerformanceMetrics metrics;
  final double performanceScore; // 0-100 overall score
  final PerformanceRating rating;
  final List<PerformanceFlag> flags;
  final List<PerformanceInsight> insights;
  final DateTime calculatedDate;
  final DataQuality? dataQuality; // Nullable until Phase 1 flag enabled
  final double? dataConfidence; // 0-1 scale (future phases)
  // Phase 2 transparency fields (all nullable for backward compatibility)
  final double? npsComponentScore; // Post-weight raw NPS component before experience factor
  final double? salesAbilityScore; // Raw 0-100 sales ability score
  final double? foodRunningScore; // Composite food running sub-score
  final double? averageCheck; // Derived or estimated average check used
  final double? npsWeight; // Applied weights after adjustments
  final double? salesWeight;
  final double? foodRunningWeight;
  // Newly exposed for Phase 2 transparency reconstruction: experience factor applied to weighted score
  final double? experienceFactor;

  ServerPerformanceData({
    required this.serverId,
    required this.startDate,
    required this.endDate,
    required this.totalFoodRuns,
    required this.shiftsWorked,
    required this.daysEmployed,
    required this.totalGuestCount,
    required this.totalSales,
    required this.shiftTypes,
    required this.metrics,
    required this.performanceScore,
    required this.rating,
    required this.flags,
    required this.insights,
    required this.calculatedDate,
    this.dataQuality,
    this.dataConfidence,
    this.npsComponentScore,
    this.salesAbilityScore,
    this.foodRunningScore,
    this.averageCheck,
    this.npsWeight,
    this.salesWeight,
    this.foodRunningWeight,
    this.experienceFactor,
  });

  Map<String, dynamic> toMap() => {
        'serverId': serverId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'totalFoodRuns': totalFoodRuns,
        'shiftsWorked': shiftsWorked,
        'daysEmployed': daysEmployed,
        'totalGuestCount': totalGuestCount,
        'totalSales': totalSales,
        'shiftTypes': shiftTypes.map((s) => s.toMap()).toList(),
        'metrics': metrics.toMap(),
        'performanceScore': performanceScore,
        'rating': rating.index,
        'flags': flags.map((f) => f.index).toList(),
        'insights': insights.map((i) => i.toMap()).toList(),
        'calculatedDate': calculatedDate.toIso8601String(),
    if (dataQuality != null) 'dataQuality': dataQuality!.index,
    if (dataConfidence != null) 'dataConfidence': dataConfidence,
  if (npsComponentScore != null) 'npsComponentScore': npsComponentScore,
  if (salesAbilityScore != null) 'salesAbilityScore': salesAbilityScore,
  if (foodRunningScore != null) 'foodRunningScore': foodRunningScore,
  if (averageCheck != null) 'averageCheck': averageCheck,
  if (npsWeight != null) 'npsWeight': npsWeight,
  if (salesWeight != null) 'salesWeight': salesWeight,
  if (foodRunningWeight != null) 'foodRunningWeight': foodRunningWeight,
  if (experienceFactor != null) 'experienceFactor': experienceFactor,
      };

  static ServerPerformanceData fromMap(Map<String, dynamic> map) =>
      ServerPerformanceData(
        serverId: map['serverId'] as String,
        startDate: DateTime.parse(map['startDate'] as String),
        endDate: DateTime.parse(map['endDate'] as String),
        totalFoodRuns: map['totalFoodRuns'] as int,
        shiftsWorked: map['shiftsWorked'] as int,
        daysEmployed: map['daysEmployed'] as int,
        totalGuestCount: (map['totalGuestCount'] as num).toDouble(),
        totalSales: (map['totalSales'] as num).toDouble(),
        shiftTypes: (map['shiftTypes'] as List)
            .map((s) => ShiftComplexity.fromMap(s))
            .toList(),
        metrics: PerformanceMetrics.fromMap(map['metrics']),
        performanceScore: (map['performanceScore'] as num).toDouble(),
        rating: PerformanceRating.values[map['rating'] as int],
        flags: (map['flags'] as List)
            .map((f) => PerformanceFlag.values[f as int])
            .toList(),
        insights: (map['insights'] as List)
            .map((i) => PerformanceInsight.fromMap(i))
            .toList(),
        calculatedDate: DateTime.parse(map['calculatedDate'] as String),
    dataQuality: map['dataQuality'] != null
      ? DataQuality.values[map['dataQuality'] as int]
      : null,
    dataConfidence: (map['dataConfidence'] as num?)?.toDouble(),
    npsComponentScore: (map['npsComponentScore'] as num?)?.toDouble(),
    salesAbilityScore: (map['salesAbilityScore'] as num?)?.toDouble(),
    foodRunningScore: (map['foodRunningScore'] as num?)?.toDouble(),
    averageCheck: (map['averageCheck'] as num?)?.toDouble(),
    npsWeight: (map['npsWeight'] as num?)?.toDouble(),
    salesWeight: (map['salesWeight'] as num?)?.toDouble(),
    foodRunningWeight: (map['foodRunningWeight'] as num?)?.toDouble(),
    experienceFactor: (map['experienceFactor'] as num?)?.toDouble(),
      );

  /// Get the primary performance insight for display
  PerformanceInsight? get primaryInsight {
    if (insights.isEmpty) return null;

    // Prioritize by type and priority
    final sorted = List<PerformanceInsight>.from(insights);
    sorted.sort((a, b) {
      // First sort by type priority (alert > recommendation > recognition)
      final typeOrder = {'alert': 0, 'recommendation': 1, 'recognition': 2};
      final aTypeOrder = typeOrder[a.type] ?? 3;
      final bTypeOrder = typeOrder[b.type] ?? 3;

      if (aTypeOrder != bTypeOrder) return aTypeOrder.compareTo(bTypeOrder);

      // Then by priority (high > medium > low)
      final priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
      final aPriorityOrder = priorityOrder[a.priority] ?? 3;
      final bPriorityOrder = priorityOrder[b.priority] ?? 3;

      return aPriorityOrder.compareTo(bPriorityOrder);
    });

    return sorted.first;
  }

  /// Check if this server is a high performer
  bool get isHighPerformer => flags.contains(PerformanceFlag.highPerformer);

  /// Check if this server needs attention
  bool get needsAttention =>
      rating == PerformanceRating.needsAttention ||
      rating == PerformanceRating.critical;

  /// Get formatted performance score as percentage
  String get formattedScore => '${performanceScore.toStringAsFixed(1)}%';

  /// Convenience badge string combining emoji + label when available.
  String? get dataQualityBadge => dataQuality != null
      ? '${dataQuality!.emoji} ${dataQuality!.label}'
      : null;
}

/// Performance trend data for visualization
class PerformanceTrend {
  final DateTime date;
  final double score;
  final int foodRuns;
  final int shifts;

  PerformanceTrend({
    required this.date,
    required this.score,
    required this.foodRuns,
    required this.shifts,
  });

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'score': score,
        'foodRuns': foodRuns,
        'shifts': shifts,
      };

  static PerformanceTrend fromMap(Map<String, dynamic> map) => PerformanceTrend(
        date: DateTime.parse(map['date'] as String),
        score: (map['score'] as num).toDouble(),
        foodRuns: map['foodRuns'] as int,
        shifts: map['shifts'] as int,
      );
}

/// Temporal analysis data for performance calculations
/// Phase 4: Temporal Derivation Layer
class TemporalAnalysis {
  final PerformanceTrendDirection trend;
  final double trendStrength; // 0-1, how strong the trend is
  final double performanceVelocity; // Rate of change over time
  final SeasonalPattern seasonalPattern;
  final double seasonalStrength; // 0-1, how strong seasonal patterns are
  final Map<String, double> seasonalFactors; // Month/day factors
  final double timeWeightedScore; // Score adjusted for recency
  final DateTime analysisDate;
  final int dataPointsAnalyzed;

  TemporalAnalysis({
    required this.trend,
    required this.trendStrength,
    required this.performanceVelocity,
    required this.seasonalPattern,
    required this.seasonalStrength,
    required this.seasonalFactors,
    required this.timeWeightedScore,
    required this.analysisDate,
    required this.dataPointsAnalyzed,
  });

  Map<String, dynamic> toMap() => {
    'trend': trend.index,
    'trendStrength': trendStrength,
    'performanceVelocity': performanceVelocity,
    'seasonalPattern': seasonalPattern.index,
    'seasonalStrength': seasonalStrength,
    'seasonalFactors': seasonalFactors,
    'timeWeightedScore': timeWeightedScore,
    'analysisDate': analysisDate.toIso8601String(),
    'dataPointsAnalyzed': dataPointsAnalyzed,
  };

  factory TemporalAnalysis.fromMap(Map<String, dynamic> map) => TemporalAnalysis(
    trend: PerformanceTrendDirection.values[map['trend']],
    trendStrength: map['trendStrength'].toDouble(),
    performanceVelocity: map['performanceVelocity'].toDouble(),
    seasonalPattern: SeasonalPattern.values[map['seasonalPattern']],
    seasonalStrength: map['seasonalStrength'].toDouble(),
    seasonalFactors: Map<String, double>.from(map['seasonalFactors']),
    timeWeightedScore: map['timeWeightedScore'].toDouble(),
    analysisDate: DateTime.parse(map['analysisDate']),
    dataPointsAnalyzed: map['dataPointsAnalyzed'],
  );
}

/// Time-weighted performance data point
/// Phase 4: Temporal Derivation Layer
class TemporalDataPoint {
  final DateTime date;
  final double performanceScore;
  final double weight; // Time-based weight (0-1)
  final Map<String, double> contextFactors; // Business context factors

  TemporalDataPoint({
    required this.date,
    required this.performanceScore,
    required this.weight,
    required this.contextFactors,
  });

  Map<String, dynamic> toMap() => {
    'date': date.toIso8601String(),
    'performanceScore': performanceScore,
    'weight': weight,
    'contextFactors': contextFactors,
  };

  factory TemporalDataPoint.fromMap(Map<String, dynamic> map) => TemporalDataPoint(
    date: DateTime.parse(map['date']),
    performanceScore: map['performanceScore'].toDouble(),
    weight: map['weight'].toDouble(),
    contextFactors: Map<String, double>.from(map['contextFactors']),
  );
}

/// Adaptive weighting configuration for performance calculations
/// Phase 5: Adaptive Weighting & Confidence
class AdaptiveWeightingConfig {
  final AdaptiveWeightingStrategy strategy;
  final Map<String, double> baseWeights; // Component weights (NPS, sales, runs, etc.)
  final Map<String, double> qualityMultipliers; // Quality-based weight adjustments
  final Map<String, double> recencyMultipliers; // Time-based weight adjustments
  final double learningRate; // Rate of weight adaptation
  final int minDataPoints; // Minimum data points for reliable weighting
  final DateTime lastUpdated;

  AdaptiveWeightingConfig({
    required this.strategy,
    required this.baseWeights,
    required this.qualityMultipliers,
    required this.recencyMultipliers,
    required this.learningRate,
    required this.minDataPoints,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() => {
    'strategy': strategy.index,
    'baseWeights': baseWeights,
    'qualityMultipliers': qualityMultipliers,
    'recencyMultipliers': recencyMultipliers,
    'learningRate': learningRate,
    'minDataPoints': minDataPoints,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory AdaptiveWeightingConfig.fromMap(Map<String, dynamic> map) => AdaptiveWeightingConfig(
    strategy: AdaptiveWeightingStrategy.values[map['strategy']],
    baseWeights: Map<String, double>.from(map['baseWeights']),
    qualityMultipliers: Map<String, double>.from(map['qualityMultipliers']),
    recencyMultipliers: Map<String, double>.from(map['recencyMultipliers']),
    learningRate: map['learningRate'].toDouble(),
    minDataPoints: map['minDataPoints'],
    lastUpdated: DateTime.parse(map['lastUpdated']),
  );
}

/// Confidence interval for performance scores
/// Phase 5: Adaptive Weighting & Confidence
class ConfidenceInterval {
  final double lowerBound;
  final double upperBound;
  final double confidenceLevel; // 0.95 for 95% confidence
  final ConfidenceIntervalType type;
  final UncertaintyLevel uncertaintyLevel;
  final double marginOfError;

  ConfidenceInterval({
    required this.lowerBound,
    required this.upperBound,
    required this.confidenceLevel,
    required this.type,
    required this.uncertaintyLevel,
    required this.marginOfError,
  });

  /// Check if a score falls within this confidence interval
  bool contains(double score) => score >= lowerBound && score <= upperBound;

  /// Get the width of the confidence interval
  double get width => upperBound - lowerBound;

  /// Get the relative uncertainty as a percentage
  double get relativeUncertainty => (width / ((lowerBound + upperBound) / 2)) * 100;

  Map<String, dynamic> toMap() => {
    'lowerBound': lowerBound,
    'upperBound': upperBound,
    'confidenceLevel': confidenceLevel,
    'type': type.index,
    'uncertaintyLevel': uncertaintyLevel.index,
    'marginOfError': marginOfError,
  };

  factory ConfidenceInterval.fromMap(Map<String, dynamic> map) => ConfidenceInterval(
    lowerBound: map['lowerBound'].toDouble(),
    upperBound: map['upperBound'].toDouble(),
    confidenceLevel: map['confidenceLevel'].toDouble(),
    type: ConfidenceIntervalType.values[map['type']],
    uncertaintyLevel: UncertaintyLevel.values[map['uncertaintyLevel']],
    marginOfError: map['marginOfError'].toDouble(),
  );
}

/// Adaptive performance score with confidence information
/// Phase 5: Adaptive Weighting & Confidence
class AdaptivePerformanceScore {
  final double score;
  final ConfidenceInterval confidenceInterval;
  final Map<String, double> componentScores; // Individual component scores
  final Map<String, double> componentWeights; // Weights used for each component
  final AdaptiveWeightingConfig weightingConfig;
  final DataQuality dataQuality;
  final ConfidenceLevel confidenceLevel;
  final DateTime calculatedAt;

  AdaptivePerformanceScore({
    required this.score,
    required this.confidenceInterval,
    required this.componentScores,
    required this.componentWeights,
    required this.weightingConfig,
    required this.dataQuality,
    required this.confidenceLevel,
    required this.calculatedAt,
  });

  /// Get formatted score with uncertainty range
  String get formattedScoreWithUncertainty {
    final uncertainty = confidenceInterval.relativeUncertainty;
    return '${score.toStringAsFixed(1)}% ±${uncertainty.toStringAsFixed(1)}%';
  }

  /// Check if this score is significantly different from another score
  bool isSignificantlyDifferent(AdaptivePerformanceScore other, {double significanceLevel = 0.05}) {
    // Check if confidence intervals overlap
    return !(confidenceInterval.contains(other.score) || other.confidenceInterval.contains(score));
  }

  Map<String, dynamic> toMap() => {
    'score': score,
    'confidenceInterval': confidenceInterval.toMap(),
    'componentScores': componentScores,
    'componentWeights': componentWeights,
    'weightingConfig': weightingConfig.toMap(),
    'dataQuality': dataQuality.index,
    'confidenceLevel': confidenceLevel.index,
    'calculatedAt': calculatedAt.toIso8601String(),
  };

  factory AdaptivePerformanceScore.fromMap(Map<String, dynamic> map) => AdaptivePerformanceScore(
    score: map['score'].toDouble(),
    confidenceInterval: ConfidenceInterval.fromMap(map['confidenceInterval']),
    componentScores: Map<String, double>.from(map['componentScores']),
    componentWeights: Map<String, double>.from(map['componentWeights']),
    weightingConfig: AdaptiveWeightingConfig.fromMap(map['weightingConfig']),
    dataQuality: DataQuality.values[map['dataQuality']],
    confidenceLevel: ConfidenceLevel.values[map['confidenceLevel']],
    calculatedAt: DateTime.parse(map['calculatedAt']),
  );
}

/// Performance telemetry event for monitoring and analytics
/// Phase 6: Monitoring & Telemetry
class PerformanceTelemetryEvent {
  final String id;
  final PerformanceEventType eventType;
  final String serverId;
  final Map<String, dynamic> eventData;
  final Map<String, dynamic> contextData;
  final DateTime timestamp;
  final String sessionId;
  final String userId;

  PerformanceTelemetryEvent({
    required this.id,
    required this.eventType,
    required this.serverId,
    required this.eventData,
    required this.contextData,
    required this.timestamp,
    required this.sessionId,
    required this.userId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'eventType': eventType.index,
    'serverId': serverId,
    'eventData': eventData,
    'contextData': contextData,
    'timestamp': timestamp.toIso8601String(),
    'sessionId': sessionId,
    'userId': userId,
  };

  factory PerformanceTelemetryEvent.fromMap(Map<String, dynamic> map) => PerformanceTelemetryEvent(
    id: map['id'],
    eventType: PerformanceEventType.values[map['eventType']],
    serverId: map['serverId'],
    eventData: Map<String, dynamic>.from(map['eventData']),
    contextData: Map<String, dynamic>.from(map['contextData']),
    timestamp: DateTime.parse(map['timestamp']),
    sessionId: map['sessionId'],
    userId: map['userId'],
  );
}

/// Performance alert for monitoring system
/// Phase 6: Monitoring & Telemetry
class PerformanceAlert {
  final String id;
  final String serverId;
  final AlertSeverity severity;
  final String title;
  final String description;
  final Map<String, dynamic> alertData;
  final DateTime triggeredAt;
  final DateTime? acknowledgedAt;
  final String? acknowledgedBy;
  final bool isResolved;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  PerformanceAlert({
    required this.id,
    required this.serverId,
    required this.severity,
    required this.title,
    required this.description,
    required this.alertData,
    required this.triggeredAt,
    this.acknowledgedAt,
    this.acknowledgedBy,
    this.isResolved = false,
    this.resolvedAt,
    this.resolvedBy,
  });

  /// Get alert age in minutes
  int get ageInMinutes => DateTime.now().difference(triggeredAt).inMinutes;

  /// Check if alert is stale (older than 24 hours)
  bool get isStale => ageInMinutes > 1440;

  /// Get alert status
  String get status {
    if (isResolved) return 'Resolved';
    if (acknowledgedAt != null) return 'Acknowledged';
    return 'Active';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'serverId': serverId,
    'severity': severity.index,
    'title': title,
    'description': description,
    'alertData': alertData,
    'triggeredAt': triggeredAt.toIso8601String(),
    'acknowledgedAt': acknowledgedAt?.toIso8601String(),
    'acknowledgedBy': acknowledgedBy,
    'isResolved': isResolved,
    'resolvedAt': resolvedAt?.toIso8601String(),
    'resolvedBy': resolvedBy,
  };

  factory PerformanceAlert.fromMap(Map<String, dynamic> map) => PerformanceAlert(
    id: map['id'],
    serverId: map['serverId'],
    severity: AlertSeverity.values[map['severity']],
    title: map['title'],
    description: map['description'],
    alertData: Map<String, dynamic>.from(map['alertData']),
    triggeredAt: DateTime.parse(map['triggeredAt']),
    acknowledgedAt: map['acknowledgedAt'] != null ? DateTime.parse(map['acknowledgedAt']) : null,
    acknowledgedBy: map['acknowledgedBy'],
    isResolved: map['isResolved'] ?? false,
    resolvedAt: map['resolvedAt'] != null ? DateTime.parse(map['resolvedAt']) : null,
    resolvedBy: map['resolvedBy'],
  );
}

/// Performance monitoring configuration
/// Phase 6: Monitoring & Telemetry
class PerformanceMonitoringConfig {
  final bool isEnabled;
  final MonitoringStatus status;
  final Map<String, double> alertThresholds;
  final Map<String, int> monitoringIntervals;
  final List<String> enabledMetrics;
  final Map<String, dynamic> customSettings;
  final DateTime lastUpdated;

  PerformanceMonitoringConfig({
    required this.isEnabled,
    required this.status,
    required this.alertThresholds,
    required this.monitoringIntervals,
    required this.enabledMetrics,
    required this.customSettings,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() => {
    'isEnabled': isEnabled,
    'status': status.index,
    'alertThresholds': alertThresholds,
    'monitoringIntervals': monitoringIntervals,
    'enabledMetrics': enabledMetrics,
    'customSettings': customSettings,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory PerformanceMonitoringConfig.fromMap(Map<String, dynamic> map) => PerformanceMonitoringConfig(
    isEnabled: map['isEnabled'],
    status: MonitoringStatus.values[map['status']],
    alertThresholds: Map<String, double>.from(map['alertThresholds']),
    monitoringIntervals: Map<String, int>.from(map['monitoringIntervals']),
    enabledMetrics: List<String>.from(map['enabledMetrics']),
    customSettings: Map<String, dynamic>.from(map['customSettings']),
    lastUpdated: DateTime.parse(map['lastUpdated']),
  );
}

/// Performance analytics summary for monitoring dashboard
/// Phase 6: Monitoring & Telemetry
class PerformanceAnalyticsSummary {
  final DateTime generatedAt;
  final Map<String, double> averageScores;
  final Map<String, int> scoreDistribution;
  final List<String> topPerformers;
  final List<String> bottomPerformers;
  final Map<String, int> alertCounts;
  final Map<String, double> trendMetrics;
  final Map<String, dynamic> systemHealth;

  PerformanceAnalyticsSummary({
    required this.generatedAt,
    required this.averageScores,
    required this.scoreDistribution,
    required this.topPerformers,
    required this.bottomPerformers,
    required this.alertCounts,
    required this.trendMetrics,
    required this.systemHealth,
  });

  Map<String, dynamic> toMap() => {
    'generatedAt': generatedAt.toIso8601String(),
    'averageScores': averageScores,
    'scoreDistribution': scoreDistribution,
    'topPerformers': topPerformers,
    'bottomPerformers': bottomPerformers,
    'alertCounts': alertCounts,
    'trendMetrics': trendMetrics,
    'systemHealth': systemHealth,
  };

  factory PerformanceAnalyticsSummary.fromMap(Map<String, dynamic> map) => PerformanceAnalyticsSummary(
    generatedAt: DateTime.parse(map['generatedAt']),
    averageScores: Map<String, double>.from(map['averageScores']),
    scoreDistribution: Map<String, int>.from(map['scoreDistribution']),
    topPerformers: List<String>.from(map['topPerformers']),
    bottomPerformers: List<String>.from(map['bottomPerformers']),
    alertCounts: Map<String, int>.from(map['alertCounts']),
    trendMetrics: Map<String, double>.from(map['trendMetrics']),
    systemHealth: Map<String, dynamic>.from(map['systemHealth']),
  );
}

/// Performance rollout deployment record
/// Phase 7: Rollout & Reconciliation
class PerformanceRollout {
  final String id;
  final String version;
  final List<int> phases;
  final RolloutStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? initiatedBy;
  final Map<String, dynamic> configuration;
  final List<String> affectedServers;
  final Map<String, dynamic> metrics;
  final String? errorMessage;
  final Map<String, dynamic> rollbackData;

  PerformanceRollout({
    required this.id,
    required this.version,
    required this.phases,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.initiatedBy,
    required this.configuration,
    required this.affectedServers,
    required this.metrics,
    this.errorMessage,
    required this.rollbackData,
  });

  /// Get rollout duration
  Duration? get duration {
    if (completedAt != null) {
      return completedAt!.difference(startedAt);
    }
    return null;
  }

  /// Check if rollout is active
  bool get isActive => status == RolloutStatus.inProgress || status == RolloutStatus.pending;

  /// Check if rollout was successful
  bool get isSuccessful => status == RolloutStatus.completed;

  Map<String, dynamic> toMap() => {
    'id': id,
    'version': version,
    'phases': phases,
    'status': status.index,
    'startedAt': startedAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'initiatedBy': initiatedBy,
    'configuration': configuration,
    'affectedServers': affectedServers,
    'metrics': metrics,
    'errorMessage': errorMessage,
    'rollbackData': rollbackData,
  };

  factory PerformanceRollout.fromMap(Map<String, dynamic> map) => PerformanceRollout(
    id: map['id'],
    version: map['version'],
    phases: List<int>.from(map['phases']),
    status: RolloutStatus.values[map['status']],
    startedAt: DateTime.parse(map['startedAt']),
    completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
    initiatedBy: map['initiatedBy'],
    configuration: Map<String, dynamic>.from(map['configuration']),
    affectedServers: List<String>.from(map['affectedServers']),
    metrics: Map<String, dynamic>.from(map['metrics']),
    errorMessage: map['errorMessage'],
    rollbackData: Map<String, dynamic>.from(map['rollbackData']),
  );
}

/// Performance validation result
/// Phase 7: Rollout & Reconciliation
class PerformanceValidation {
  final String id;
  final String rolloutId;
  final ValidationStatus status;
  final String validationType;
  final Map<String, dynamic> criteria;
  final Map<String, dynamic> results;
  final List<String> warnings;
  final List<String> errors;
  final DateTime validatedAt;
  final String? validatedBy;
  final Map<String, dynamic> metadata;

  PerformanceValidation({
    required this.id,
    required this.rolloutId,
    required this.status,
    required this.validationType,
    required this.criteria,
    required this.results,
    required this.warnings,
    required this.errors,
    required this.validatedAt,
    this.validatedBy,
    required this.metadata,
  });

  /// Check if validation passed
  bool get passed => status == ValidationStatus.passed;

  /// Check if validation has warnings
  bool get hasWarnings => warnings.isNotEmpty;

  /// Check if validation has errors
  bool get hasErrors => errors.isNotEmpty;

  Map<String, dynamic> toMap() => {
    'id': id,
    'rolloutId': rolloutId,
    'status': status.index,
    'validationType': validationType,
    'criteria': criteria,
    'results': results,
    'warnings': warnings,
    'errors': errors,
    'validatedAt': validatedAt.toIso8601String(),
    'validatedBy': validatedBy,
    'metadata': metadata,
  };

  factory PerformanceValidation.fromMap(Map<String, dynamic> map) => PerformanceValidation(
    id: map['id'],
    rolloutId: map['rolloutId'],
    status: ValidationStatus.values[map['status']],
    validationType: map['validationType'],
    criteria: Map<String, dynamic>.from(map['criteria']),
    results: Map<String, dynamic>.from(map['results']),
    warnings: List<String>.from(map['warnings']),
    errors: List<String>.from(map['errors']),
    validatedAt: DateTime.parse(map['validatedAt']),
    validatedBy: map['validatedBy'],
    metadata: Map<String, dynamic>.from(map['metadata']),
  );
}

/// Performance reconciliation operation
/// Phase 7: Rollout & Reconciliation
class PerformanceReconciliation {
  final String id;
  final String rolloutId;
  final ReconciliationType type;
  final String description;
  final Map<String, dynamic> parameters;
  final Map<String, dynamic> beforeState;
  final Map<String, dynamic> afterState;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? initiatedBy;
  final bool isSuccessful;
  final String? errorMessage;
  final Map<String, dynamic> metrics;

  PerformanceReconciliation({
    required this.id,
    required this.rolloutId,
    required this.type,
    required this.description,
    required this.parameters,
    required this.beforeState,
    required this.afterState,
    required this.startedAt,
    this.completedAt,
    this.initiatedBy,
    required this.isSuccessful,
    this.errorMessage,
    required this.metrics,
  });

  /// Get operation duration
  Duration? get duration {
    if (completedAt != null) {
      return completedAt!.difference(startedAt);
    }
    return null;
  }

  /// Check if operation is complete
  bool get isComplete => completedAt != null;

  Map<String, dynamic> toMap() => {
    'id': id,
    'rolloutId': rolloutId,
    'type': type.index,
    'description': description,
    'parameters': parameters,
    'beforeState': beforeState,
    'afterState': afterState,
    'startedAt': startedAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'initiatedBy': initiatedBy,
    'isSuccessful': isSuccessful,
    'errorMessage': errorMessage,
    'metrics': metrics,
  };

  factory PerformanceReconciliation.fromMap(Map<String, dynamic> map) => PerformanceReconciliation(
    id: map['id'],
    rolloutId: map['rolloutId'],
    type: ReconciliationType.values[map['type']],
    description: map['description'],
    parameters: Map<String, dynamic>.from(map['parameters']),
    beforeState: Map<String, dynamic>.from(map['beforeState']),
    afterState: Map<String, dynamic>.from(map['afterState']),
    startedAt: DateTime.parse(map['startedAt']),
    completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
    initiatedBy: map['initiatedBy'],
    isSuccessful: map['isSuccessful'],
    errorMessage: map['errorMessage'],
    metrics: Map<String, dynamic>.from(map['metrics']),
  );
}

/// Performance rollout configuration
/// Phase 7: Rollout & Reconciliation
class PerformanceRolloutConfig {
  final String version;
  final List<int> enabledPhases;
  final Map<String, bool> featureFlags;
  final Map<String, dynamic> rolloutSettings;
  final Map<String, dynamic> validationCriteria;
  final Map<String, dynamic> rollbackSettings;
  final DateTime createdAt;
  final String createdBy;
  final bool isActive;

  PerformanceRolloutConfig({
    required this.version,
    required this.enabledPhases,
    required this.featureFlags,
    required this.rolloutSettings,
    required this.validationCriteria,
    required this.rollbackSettings,
    required this.createdAt,
    required this.createdBy,
    required this.isActive,
  });

  Map<String, dynamic> toMap() => {
    'version': version,
    'enabledPhases': enabledPhases,
    'featureFlags': featureFlags,
    'rolloutSettings': rolloutSettings,
    'validationCriteria': validationCriteria,
    'rollbackSettings': rollbackSettings,
    'createdAt': createdAt.toIso8601String(),
    'createdBy': createdBy,
    'isActive': isActive,
  };

  factory PerformanceRolloutConfig.fromMap(Map<String, dynamic> map) => PerformanceRolloutConfig(
    version: map['version'],
    enabledPhases: List<int>.from(map['enabledPhases']),
    featureFlags: Map<String, bool>.from(map['featureFlags']),
    rolloutSettings: Map<String, dynamic>.from(map['rolloutSettings']),
    validationCriteria: Map<String, dynamic>.from(map['validationCriteria']),
    rollbackSettings: Map<String, dynamic>.from(map['rollbackSettings']),
    createdAt: DateTime.parse(map['createdAt']),
    createdBy: map['createdBy'],
    isActive: map['isActive'],
  );
}
