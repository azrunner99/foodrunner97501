import 'package:flutter/material.dart';

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

  NPSData({
    required this.serverId,
    required this.month,
    required this.monthlyScore,
    required this.threeMonthAverage,
    required this.responseCount,
    required this.categoryBreakdown,
    required this.guestComments,
    required this.lastUpdated,
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
