import 'package:flutter/foundation.dart';

/// Represents historical NPS performance data for a server across multiple months
class HistoricalNPSData {
  final String serverId;
  final String serverName;
  final List<MonthlyPerformance> monthlyData;
  final PerformanceTrend trend;
  final double volatility;
  final SeasonalPattern? seasonalPattern;
  final PerformanceClassification classification;
  final DateTime lastUpdated;
  final int totalMonthsReported;

  HistoricalNPSData({
    required this.serverId,
    required this.serverName,
    required this.monthlyData,
    required this.trend,
    required this.volatility,
    this.seasonalPattern,
    required this.classification,
    required this.lastUpdated,
    required this.totalMonthsReported,
  });

  /// Calculate overall performance score considering all timeframes
  double get overallPerformanceScore {
    if (monthlyData.isEmpty) return 0.0;
    
    // Weight different timeframes appropriately
    final recentWeight = 0.4;    // Last 3 months
    final mediumWeight = 0.3;    // 3-6 months ago
    final historicalWeight = 0.3; // 6+ months ago
    
    final recentMonths = monthlyData.take(3).toList();
    final mediumMonths = monthlyData.skip(3).take(3).toList();
    final historicalMonths = monthlyData.skip(6).toList();
    
    double recentAvg = recentMonths.isNotEmpty 
        ? recentMonths.map((m) => m.oneMonthNPS).reduce((a, b) => a + b) / recentMonths.length
        : 0.0;
    
    double mediumAvg = mediumMonths.isNotEmpty
        ? mediumMonths.map((m) => m.oneMonthNPS).reduce((a, b) => a + b) / mediumMonths.length
        : recentAvg; // Fallback to recent if no medium data
    
    double historicalAvg = historicalMonths.isNotEmpty
        ? historicalMonths.map((m) => m.oneMonthNPS).reduce((a, b) => a + b) / historicalMonths.length
        : mediumAvg; // Fallback to medium if no historical data
    
    return (recentAvg * recentWeight) + 
           (mediumAvg * mediumWeight) + 
           (historicalAvg * historicalWeight);
  }

  /// Get the most recent performance data
  MonthlyPerformance? get mostRecentPerformance {
    return monthlyData.isNotEmpty ? monthlyData.first : null;
  }

  /// Get performance data for a specific month
  MonthlyPerformance? getPerformanceForMonth(DateTime month) {
    final targetMonth = DateTime(month.year, month.month);
    try {
      return monthlyData.firstWhere(
        (data) => data.month.year == targetMonth.year && data.month.month == targetMonth.month,
      );
    } catch (e) {
      return null;
    }
  }

  /// Calculate trend direction over the last N months
  TrendDirection getTrendDirection({int months = 3}) {
    if (monthlyData.length < 2) return TrendDirection.stable;
    
    final recentData = monthlyData.take(months).toList();
    if (recentData.length < 2) return TrendDirection.stable;
    
    final first = recentData.last.oneMonthNPS;
    final last = recentData.first.oneMonthNPS;
    final difference = last - first;
    
    if (difference > 5.0) return TrendDirection.improving;
    if (difference < -5.0) return TrendDirection.declining;
    return TrendDirection.stable;
  }

  /// Calculate performance volatility (standard deviation)
  double calculateVolatility() {
    if (monthlyData.length < 2) return 0.0;
    
    final scores = monthlyData.map((m) => m.oneMonthNPS).toList();
    final mean = scores.reduce((a, b) => a + b) / scores.length;
    final variance = scores.map((score) => (score - mean) * (score - mean)).reduce((a, b) => a + b) / scores.length;
    return variance > 0 ? variance : 0.0;
  }

  Map<String, dynamic> toMap() {
    return {
      'serverId': serverId,
      'serverName': serverName,
      'monthlyData': monthlyData.map((m) => m.toMap()).toList(),
      'trend': trend.toMap(),
      'volatility': volatility,
      'seasonalPattern': seasonalPattern?.toMap(),
      'classification': classification.toString(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'totalMonthsReported': totalMonthsReported,
    };
  }

  factory HistoricalNPSData.fromMap(Map<String, dynamic> map) {
    return HistoricalNPSData(
      serverId: map['serverId'] as String,
      serverName: map['serverName'] as String,
      monthlyData: (map['monthlyData'] as List)
          .map((m) => MonthlyPerformance.fromMap(m as Map<String, dynamic>))
          .toList(),
      trend: PerformanceTrend.fromMap(map['trend'] as Map<String, dynamic>),
      volatility: map['volatility'] as double,
      seasonalPattern: map['seasonalPattern'] != null 
          ? SeasonalPattern.fromMap(map['seasonalPattern'] as Map<String, dynamic>)
          : null,
      classification: PerformanceClassification.values.firstWhere(
        (e) => e.toString() == map['classification'],
        orElse: () => PerformanceClassification.unknown,
      ),
      lastUpdated: DateTime.parse(map['lastUpdated'] as String),
      totalMonthsReported: map['totalMonthsReported'] as int,
    );
  }
}

/// Represents performance data for a single month
class MonthlyPerformance {
  final DateTime month;
  final double oneMonthNPS;
  final double threeMonthNPS;
  final double allTimeNPS;
  final int responseCount;
  final PerformanceContext context;
  final double sales;
  final int tableCount;

  MonthlyPerformance({
    required this.month,
    required this.oneMonthNPS,
    required this.threeMonthNPS,
    required this.allTimeNPS,
    required this.responseCount,
    required this.context,
    required this.sales,
    required this.tableCount,
  });

  /// Calculate check average for this month
  double get checkAverage => tableCount > 0 ? sales / tableCount : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'month': month.toIso8601String(),
      'oneMonthNPS': oneMonthNPS,
      'threeMonthNPS': threeMonthNPS,
      'allTimeNPS': allTimeNPS,
      'responseCount': responseCount,
      'context': context.toMap(),
      'sales': sales,
      'tableCount': tableCount,
    };
  }

  factory MonthlyPerformance.fromMap(Map<String, dynamic> map) {
    return MonthlyPerformance(
      month: DateTime.parse(map['month'] as String),
      oneMonthNPS: map['oneMonthNPS'] as double,
      threeMonthNPS: map['threeMonthNPS'] as double,
      allTimeNPS: map['allTimeNPS'] as double,
      responseCount: map['responseCount'] as int,
      context: PerformanceContext.fromMap(map['context'] as Map<String, dynamic>),
      sales: map['sales'] as double,
      tableCount: map['tableCount'] as int,
    );
  }
}

/// Represents the trend analysis for a server's performance
class PerformanceTrend {
  final TrendDirection direction;
  final double slope;
  final double strength;
  final double volatility;
  final List<double> movingAverages;
  final String description;

  PerformanceTrend({
    required this.direction,
    required this.slope,
    required this.strength,
    required this.volatility,
    required this.movingAverages,
    required this.description,
  });

  /// Calculate trend strength (0.0 to 1.0)
  double calculateStrength(List<double> scores) {
    if (scores.length < 2) return 0.0;
    
    // Simple linear regression to calculate R-squared
    final n = scores.length;
    final xValues = List.generate(n, (i) => i.toDouble());
    final yValues = scores;
    
    final xMean = xValues.reduce((a, b) => a + b) / n;
    final yMean = yValues.reduce((a, b) => a + b) / n;
    
    double numerator = 0.0;
    double xDenominator = 0.0;
    double yDenominator = 0.0;
    
    for (int i = 0; i < n; i++) {
      final xDiff = xValues[i] - xMean;
      final yDiff = yValues[i] - yMean;
      numerator += xDiff * yDiff;
      xDenominator += xDiff * xDiff;
      yDenominator += yDiff * yDiff;
    }
    
    if (xDenominator == 0 || yDenominator == 0) return 0.0;
    
    final correlation = numerator / (xDenominator * yDenominator);
    return correlation.abs();
  }

  Map<String, dynamic> toMap() {
    return {
      'direction': direction.toString(),
      'slope': slope,
      'strength': strength,
      'volatility': volatility,
      'movingAverages': movingAverages,
      'description': description,
    };
  }

  factory PerformanceTrend.fromMap(Map<String, dynamic> map) {
    return PerformanceTrend(
      direction: TrendDirection.values.firstWhere(
        (e) => e.toString() == map['direction'],
        orElse: () => TrendDirection.stable,
      ),
      slope: map['slope'] as double,
      strength: map['strength'] as double,
      volatility: map['volatility'] as double,
      movingAverages: List<double>.from(map['movingAverages'] as List),
      description: map['description'] as String,
    );
  }
}

/// Represents seasonal patterns in performance
class SeasonalPattern {
  final Map<int, double> monthlyAverages; // Month (1-12) -> Average NPS
  final double seasonalityStrength;
  final List<int> peakMonths;
  final List<int> lowMonths;

  SeasonalPattern({
    required this.monthlyAverages,
    required this.seasonalityStrength,
    required this.peakMonths,
    required this.lowMonths,
  });

  /// Get expected performance for a given month
  double getExpectedPerformance(int month) {
    return monthlyAverages[month] ?? 0.0;
  }

  /// Check if current performance is above/below seasonal expectation
  bool isAboveSeasonalExpectation(double currentNPS, int month) {
    final expected = getExpectedPerformance(month);
    return currentNPS > expected;
  }

  Map<String, dynamic> toMap() {
    return {
      'monthlyAverages': monthlyAverages,
      'seasonalityStrength': seasonalityStrength,
      'peakMonths': peakMonths,
      'lowMonths': lowMonths,
    };
  }

  factory SeasonalPattern.fromMap(Map<String, dynamic> map) {
    return SeasonalPattern(
      monthlyAverages: Map<int, double>.from(map['monthlyAverages'] as Map),
      seasonalityStrength: map['seasonalityStrength'] as double,
      peakMonths: List<int>.from(map['peakMonths'] as List),
      lowMonths: List<int>.from(map['lowMonths'] as List),
    );
  }
}

/// Performance context for a specific month
class PerformanceContext {
  final bool isNewHire;
  final bool isTrainingPeriod;
  final bool isSeasonalPeak;
  final bool isSeasonalLow;
  final String notes;

  PerformanceContext({
    required this.isNewHire,
    required this.isTrainingPeriod,
    required this.isSeasonalPeak,
    required this.isSeasonalLow,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'isNewHire': isNewHire,
      'isTrainingPeriod': isTrainingPeriod,
      'isSeasonalPeak': isSeasonalPeak,
      'isSeasonalLow': isSeasonalLow,
      'notes': notes,
    };
  }

  factory PerformanceContext.fromMap(Map<String, dynamic> map) {
    return PerformanceContext(
      isNewHire: map['isNewHire'] as bool,
      isTrainingPeriod: map['isTrainingPeriod'] as bool,
      isSeasonalPeak: map['isSeasonalPeak'] as bool,
      isSeasonalLow: map['isSeasonalLow'] as bool,
      notes: map['notes'] as String,
    );
  }
}

/// Trend direction enumeration
enum TrendDirection {
  improving,
  stable,
  declining,
  volatile,
}

/// Performance classification based on historical analysis
enum PerformanceClassification {
  elite,        // Consistently high performance across all timeframes
  strong,       // Good overall performance with minor variations
  developing,   // Improving trend or new to role
  concerning,   // Declining trend or inconsistent performance
  critical,     // Consistently poor performance across timeframes
  unknown,      // Insufficient data for classification
}

extension PerformanceClassificationExtension on PerformanceClassification {
  String get displayName {
    switch (this) {
      case PerformanceClassification.elite:
        return 'Elite Performer';
      case PerformanceClassification.strong:
        return 'Strong Performer';
      case PerformanceClassification.developing:
        return 'Developing';
      case PerformanceClassification.concerning:
        return 'Concerning';
      case PerformanceClassification.critical:
        return 'Critical';
      case PerformanceClassification.unknown:
        return 'Unknown';
    }
  }

  String get emoji {
    switch (this) {
      case PerformanceClassification.elite:
        return '🌟';
      case PerformanceClassification.strong:
        return '💪';
      case PerformanceClassification.developing:
        return '📈';
      case PerformanceClassification.concerning:
        return '⚠️';
      case PerformanceClassification.critical:
        return '🚨';
      case PerformanceClassification.unknown:
        return '❓';
    }
  }
}
