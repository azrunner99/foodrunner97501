import 'dart:math' as math;
import '../models.dart';
import '../models/performance_models.dart';

/// Advanced trend analysis and predictive performance modeling
class TrendAnalyzer {

  /// Calculate performance trends with predictive modeling
  static PerformanceTrendAnalysis analyzePerformanceTrends({
    required String serverId,
    required List<ShiftRecord> shifts,
    required int analysisWindowDays,
  }) {
    // Calculate daily performance trends
    final dailyTrends = _calculateDailyTrends(serverId, shifts, analysisWindowDays);
    
    // Calculate rolling averages (7-day, 14-day, 30-day)
    final rollingAverages = _calculateRollingAverages(dailyTrends);
    
    // Analyze trend direction and momentum
    final trendDirection = _analyzeTrendDirection(dailyTrends);
    final momentum = _calculateTrendMomentum(dailyTrends);
    
    // Predict future performance
    final predictions = _predictFuturePerformance(dailyTrends);
    
    // Identify trend patterns and seasonality
    final patterns = _identifyTrendPatterns(dailyTrends);
    
    // Calculate trend confidence
    final confidence = _calculateTrendConfidence(dailyTrends, trendDirection);
    
    return PerformanceTrendAnalysis(
      serverId: serverId,
      analysisWindowDays: analysisWindowDays,
      dailyTrends: dailyTrends,
      rollingAverages: rollingAverages,
      trendDirection: trendDirection,
      momentum: momentum,
      predictions: predictions,
      patterns: patterns,
      confidence: confidence,
      calculatedDate: DateTime.now(),
    );
  }

  /// Calculate seasonal performance patterns
  static SeasonalAnalysis analyzeSeasonalPatterns({
    required String serverId,
    required List<ShiftRecord> shifts,
    required int monthsToAnalyze,
  }) {
    final monthlyData = _groupShiftsByMonth(serverId, shifts, monthsToAnalyze);
    
    // Analyze day-of-week patterns
    final dayOfWeekPatterns = _analyzeDayOfWeekPatterns(serverId, shifts);
    
    // Analyze monthly variations
    final monthlyPatterns = _analyzeMonthlyPatterns(monthlyData);
    
    // Identify peak and low performance periods
    final performancePeaks = _identifyPerformancePeaks(monthlyData);
    
    // Calculate seasonal adjustments
    final seasonalAdjustments = _calculateSeasonalAdjustments(monthlyData);
    
    return SeasonalAnalysis(
      serverId: serverId,
      monthsAnalyzed: monthsToAnalyze,
      dayOfWeekPatterns: dayOfWeekPatterns,
      monthlyPatterns: monthlyPatterns,
      performancePeaks: performancePeaks,
      seasonalAdjustments: seasonalAdjustments,
    );
  }

  /// Compare performance across different time periods
  static PeriodComparison comparePerformancePeriods({
    required String serverId,
    required List<ShiftRecord> shifts,
    required DateTime period1Start,
    required DateTime period1End,
    required DateTime period2Start,
    required DateTime period2End,
  }) {
    final period1Data = _extractPeriodData(serverId, shifts, period1Start, period1End);
    final period2Data = _extractPeriodData(serverId, shifts, period2Start, period2End);
    
    final comparison = _comparePeriods(period1Data.data, period2Data.data);
    final significanceTest = _testStatisticalSignificance(period1Data.data, period2Data.data);
    
    return PeriodComparison(
      serverId: serverId,
      period1: period1Data,
      period2: period2Data,
      comparison: comparison,
      statisticalSignificance: significanceTest,
    );
  }

  /// Predict optimal performance scheduling
  static SchedulingOptimization optimizeScheduling({
    required String serverId,
    required List<ShiftRecord> historicalShifts,
    required SeasonalAnalysis seasonalAnalysis,
  }) {
    // Analyze performance by shift type and timing
    final shiftPerformance = _analyzeShiftTypePerformance(serverId, historicalShifts);
    
    // Identify optimal shift patterns
    final optimalPatterns = _identifyOptimalShiftPatterns(shiftPerformance, seasonalAnalysis);
    
    // Generate scheduling recommendations
    final recommendations = _generateSchedulingRecommendations(optimalPatterns, seasonalAnalysis);
    
    return SchedulingOptimization(
      serverId: serverId,
      shiftPerformance: shiftPerformance,
      optimalPatterns: optimalPatterns,
      recommendations: recommendations,
    );
  }

  /// Calculate performance velocity (rate of improvement/decline)
  static PerformanceVelocity calculatePerformanceVelocity(List<PerformanceTrend> trends) {
    if (trends.length < 2) {
      return PerformanceVelocity.zero();
    }

    // Sort trends by date
    final sortedTrends = List<PerformanceTrend>.from(trends)..sort((a, b) => a.date.compareTo(b.date));
    
    // Calculate velocity metrics
    final shortTermVelocity = _calculateShortTermVelocity(sortedTrends);
    final longTermVelocity = _calculateLongTermVelocity(sortedTrends);
    final acceleration = _calculateAcceleration(sortedTrends);
    
    // Determine velocity category
    final category = _categorizeVelocity(shortTermVelocity, longTermVelocity);
    
    return PerformanceVelocity(
      shortTermVelocity: shortTermVelocity,
      longTermVelocity: longTermVelocity,
      acceleration: acceleration,
      category: category,
    );
  }

  // Private helper methods

  static List<DailyTrend> _calculateDailyTrends(String serverId, List<ShiftRecord> shifts, int windowDays) {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: windowDays));
    
    final dailyTrends = <DailyTrend>[];
    
    for (int i = 0; i < windowDays; i++) {
      final date = startDate.add(Duration(days: i));
      final dayShifts = shifts.where((shift) => 
        shift.start.year == date.year &&
        shift.start.month == date.month &&
        shift.start.day == date.day &&
        shift.counts.containsKey(serverId)
      ).toList();
      
      final totalRuns = dayShifts.fold<int>(0, (sum, shift) => sum + (shift.counts[serverId] ?? 0));
      final shiftsWorked = dayShifts.length;
      final efficiency = shiftsWorked > 0 ? totalRuns / shiftsWorked : 0.0;
      
      dailyTrends.add(DailyTrend(
        date: date,
        totalRuns: totalRuns,
        shiftsWorked: shiftsWorked,
        efficiency: efficiency,
        score: efficiency * 10, // Simple scoring
      ));
    }
    
    return dailyTrends;
  }

  static RollingAverages _calculateRollingAverages(List<DailyTrend> dailyTrends) {
    final scores = dailyTrends.map((t) => t.score).toList();
    
    return RollingAverages(
      sevenDay: _calculateRollingAverage(scores, 7),
      fourteenDay: _calculateRollingAverage(scores, 14),
      thirtyDay: _calculateRollingAverage(scores, 30),
    );
  }

  static List<double> _calculateRollingAverage(List<double> values, int windowSize) {
    final result = <double>[];
    
    for (int i = 0; i < values.length; i++) {
      final startIndex = math.max(0, i - windowSize + 1);
      final windowValues = values.sublist(startIndex, i + 1);
      final average = windowValues.reduce((a, b) => a + b) / windowValues.length;
      result.add(average);
    }
    
    return result;
  }

  static TrendDirection _analyzeTrendDirection(List<DailyTrend> trends) {
    if (trends.length < 3) return TrendDirection.stable;
    
    final recentScores = trends.skip(trends.length - 5).map((t) => t.score).toList();
    
    // Linear regression to determine trend
    final xValues = List.generate(recentScores.length, (i) => i.toDouble());
    final slope = _calculateLinearRegressionSlope(xValues, recentScores);
    
    if (slope > 0.5) return TrendDirection.improving;
    if (slope < -0.5) return TrendDirection.declining;
    return TrendDirection.stable;
  }

  static double _calculateLinearRegressionSlope(List<double> x, List<double> y) {
    if (x.length != y.length || x.isEmpty) return 0.0;
    
    final n = x.length;
    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final sumXY = List.generate(n, (i) => x[i] * y[i]).reduce((a, b) => a + b);
    final sumXX = x.map((xi) => xi * xi).reduce((a, b) => a + b);
    
    final denominator = n * sumXX - sumX * sumX;
    if (denominator == 0) return 0.0;
    
    return (n * sumXY - sumX * sumY) / denominator;
  }

  static TrendMomentum _calculateTrendMomentum(List<DailyTrend> trends) {
    if (trends.length < 5) return TrendMomentum.neutral;
    
    final recentTrends = trends.skip(trends.length - 5).toList();
    final scores = recentTrends.map((t) => t.score).toList();
    
    // Calculate rate of change
    final rateOfChange = (scores.last - scores.first) / scores.length;
    
    if (rateOfChange > 2.0) return TrendMomentum.strong;
    if (rateOfChange > 0.5) return TrendMomentum.moderate;
    if (rateOfChange < -2.0) return TrendMomentum.strongNegative;
    if (rateOfChange < -0.5) return TrendMomentum.moderateNegative;
    return TrendMomentum.neutral;
  }

  static PerformancePredictions _predictFuturePerformance(List<DailyTrend> trends) {
    if (trends.length < 7) {
      return PerformancePredictions.insufficient();
    }
    
    final scores = trends.map((t) => t.score).toList();
    final xValues = List.generate(scores.length, (i) => i.toDouble());
    
    // Simple linear extrapolation
    final slope = _calculateLinearRegressionSlope(xValues, scores);
    final intercept = _calculateLinearRegressionIntercept(xValues, scores);
    
    final nextWeek = intercept + slope * (scores.length + 7);
    final nextMonth = intercept + slope * (scores.length + 30);
    
    return PerformancePredictions(
      nextWeek: math.max(0, nextWeek),
      nextMonth: math.max(0, nextMonth),
      confidence: _calculatePredictionConfidence(trends),
    );
  }

  static double _calculateLinearRegressionIntercept(List<double> x, List<double> y) {
    if (x.length != y.length || x.isEmpty) return 0.0;
    
    final n = x.length;
    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final slope = _calculateLinearRegressionSlope(x, y);
    
    return (sumY - slope * sumX) / n;
  }

  static double _calculatePredictionConfidence(List<DailyTrend> trends) {
    final scores = trends.map((t) => t.score).toList();
    final mean = scores.reduce((a, b) => a + b) / scores.length;
    final variance = scores.map((s) => math.pow(s - mean, 2)).reduce((a, b) => a + b) / scores.length;
    final standardDeviation = math.sqrt(variance);
    
    // Lower standard deviation = higher confidence
    final coefficientOfVariation = mean > 0 ? standardDeviation / mean : 1.0;
    return math.max(0.0, math.min(1.0, 1.0 - coefficientOfVariation));
  }

  static TrendPatterns _identifyTrendPatterns(List<DailyTrend> trends) {
    // Identify cyclical patterns, anomalies, and consistency
    final hasWeeklyPattern = _detectWeeklyPattern(trends);
    final anomalies = _detectAnomalies(trends);
    final consistencyLevel = _calculateConsistencyLevel(trends);
    
    return TrendPatterns(
      hasWeeklyCycle: hasWeeklyPattern,
      anomalies: anomalies,
      consistencyLevel: consistencyLevel,
    );
  }

  static bool _detectWeeklyPattern(List<DailyTrend> trends) {
    // Simple weekly pattern detection
    if (trends.length < 14) return false;
    
    final weekdayScores = <int, List<double>>{};
    
    for (final trend in trends) {
      final weekday = trend.date.weekday;
      weekdayScores.putIfAbsent(weekday, () => []).add(trend.score);
    }
    
    // Check if there's significant variation between weekdays
    final avgScoresByWeekday = weekdayScores.map((day, scores) => 
      MapEntry(day, scores.reduce((a, b) => a + b) / scores.length));
    
    final allAvgs = avgScoresByWeekday.values.toList();
    if (allAvgs.isEmpty) return false;
    
    final maxAvg = allAvgs.reduce(math.max);
    final minAvg = allAvgs.reduce(math.min);
    
    // If there's more than 20% difference, consider it a weekly pattern
    return (maxAvg - minAvg) / maxAvg > 0.2;
  }

  static List<AnomalyPoint> _detectAnomalies(List<DailyTrend> trends) {
    if (trends.length < 7) return [];
    
    final scores = trends.map((t) => t.score).toList();
    final mean = scores.reduce((a, b) => a + b) / scores.length;
    final standardDeviation = math.sqrt(
      scores.map((s) => math.pow(s - mean, 2)).reduce((a, b) => a + b) / scores.length
    );
    
    final anomalies = <AnomalyPoint>[];
    
    for (int i = 0; i < trends.length; i++) {
      final zScore = standardDeviation > 0 ? (trends[i].score - mean) / standardDeviation : 0.0;
      
      if (zScore.abs() > 2.0) { // More than 2 standard deviations
        anomalies.add(AnomalyPoint(
          date: trends[i].date,
          score: trends[i].score,
          zScore: zScore,
          type: zScore > 0 ? AnomalyType.unusuallyHigh : AnomalyType.unusuallyLow,
        ));
      }
    }
    
    return anomalies;
  }

  static ConsistencyLevel _calculateConsistencyLevel(List<DailyTrend> trends) {
    if (trends.isEmpty) return ConsistencyLevel.unknown;
    
    final scores = trends.map((t) => t.score).toList();
    final mean = scores.reduce((a, b) => a + b) / scores.length;
    final standardDeviation = math.sqrt(
      scores.map((s) => math.pow(s - mean, 2)).reduce((a, b) => a + b) / scores.length
    );
    
    final coefficientOfVariation = mean > 0 ? standardDeviation / mean : 1.0;
    
    if (coefficientOfVariation < 0.1) return ConsistencyLevel.veryHigh;
    if (coefficientOfVariation < 0.2) return ConsistencyLevel.high;
    if (coefficientOfVariation < 0.3) return ConsistencyLevel.moderate;
    if (coefficientOfVariation < 0.5) return ConsistencyLevel.low;
    return ConsistencyLevel.veryLow;
  }

  static double _calculateTrendConfidence(List<DailyTrend> trends, TrendDirection direction) {
    if (trends.length < 3) return 0.5;
    
    final consistency = _calculateConsistencyLevel(trends);
    final dataPoints = trends.length;
    
    // Base confidence on data points and consistency
    double confidence = math.min(1.0, dataPoints / 30.0); // More data = higher confidence
    
    // Adjust for consistency
    switch (consistency) {
      case ConsistencyLevel.veryHigh:
        confidence *= 1.2;
        break;
      case ConsistencyLevel.high:
        confidence *= 1.1;
        break;
      case ConsistencyLevel.moderate:
        confidence *= 1.0;
        break;
      case ConsistencyLevel.low:
        confidence *= 0.8;
        break;
      case ConsistencyLevel.veryLow:
        confidence *= 0.6;
        break;
      case ConsistencyLevel.unknown:
        confidence *= 0.5;
        break;
    }
    
    return math.max(0.0, math.min(1.0, confidence));
  }

  // Additional helper methods for other functions...
  
  static Map<String, List<ShiftRecord>> _groupShiftsByMonth(String serverId, List<ShiftRecord> shifts, int monthsToAnalyze) {
    // Group shifts by month for seasonal analysis
    final monthlyData = <String, List<ShiftRecord>>{};
    final endDate = DateTime.now();
    
    for (int i = 0; i < monthsToAnalyze; i++) {
      final monthStart = DateTime(endDate.year, endDate.month - i, 1);
      final monthKey = '${monthStart.year}-${monthStart.month.toString().padLeft(2, '0')}';
      
      final monthShifts = shifts.where((shift) =>
        shift.start.year == monthStart.year &&
        shift.start.month == monthStart.month &&
        shift.counts.containsKey(serverId)
      ).toList();
      
      monthlyData[monthKey] = monthShifts;
    }
    
    return monthlyData;
  }

  static Map<int, double> _analyzeDayOfWeekPatterns(String serverId, List<ShiftRecord> shifts) {
    final patterns = <int, List<double>>{};
    
    for (final shift in shifts) {
      if (!shift.counts.containsKey(serverId)) continue;
      
      final weekday = shift.start.weekday;
      final runs = shift.counts[serverId]!.toDouble();
      patterns.putIfAbsent(weekday, () => []).add(runs);
    }
    
    return patterns.map((day, runsList) => 
      MapEntry(day, runsList.reduce((a, b) => a + b) / runsList.length));
  }

  static Map<String, double> _analyzeMonthlyPatterns(Map<String, List<ShiftRecord>> monthlyData) {
    // Analyze monthly performance patterns
    return monthlyData.map((month, shifts) {
      final totalRuns = shifts.fold<int>(0, (sum, shift) => 
        sum + shift.counts.values.fold<int>(0, (s, count) => s + count));
      return MapEntry(month, totalRuns.toDouble());
    });
  }

  static PerformancePeaks _identifyPerformancePeaks(Map<String, List<ShiftRecord>> monthlyData) {
    final monthlyTotals = _analyzeMonthlyPatterns(monthlyData);
    
    if (monthlyTotals.isEmpty) {
      return PerformancePeaks(bestMonth: '', worstMonth: '', peakScore: 0.0, lowScore: 0.0);
    }
    
    final sortedMonths = monthlyTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return PerformancePeaks(
      bestMonth: sortedMonths.first.key,
      worstMonth: sortedMonths.last.key,
      peakScore: sortedMonths.first.value,
      lowScore: sortedMonths.last.value,
    );
  }

  static Map<String, double> _calculateSeasonalAdjustments(Map<String, List<ShiftRecord>> monthlyData) {
    final monthlyTotals = _analyzeMonthlyPatterns(monthlyData);
    
    if (monthlyTotals.isEmpty) return {};
    
    final average = monthlyTotals.values.reduce((a, b) => a + b) / monthlyTotals.length;
    
    return monthlyTotals.map((month, total) => 
      MapEntry(month, total / average)); // Adjustment factor
  }

  static PeriodData _extractPeriodData(String serverId, List<ShiftRecord> shifts, DateTime start, DateTime end) {
    final periodShifts = shifts.where((shift) =>
      shift.start.isAfter(start.subtract(const Duration(days: 1))) &&
      shift.start.isBefore(end.add(const Duration(days: 1))) &&
      shift.counts.containsKey(serverId)
    ).toList();
    
    final totalRuns = periodShifts.fold<int>(0, (sum, shift) => sum + (shift.counts[serverId] ?? 0));
    final avgRunsPerShift = periodShifts.isNotEmpty ? totalRuns / periodShifts.length : 0.0;
    
    return PeriodData(
      start: start,
      end: end,
      data: {
        'totalRuns': totalRuns.toDouble(),
        'shiftsWorked': periodShifts.length.toDouble(),
        'averageRunsPerShift': avgRunsPerShift,
      },
    );
  }

  static Map<String, double> _comparePeriods(Map<String, double> period1, Map<String, double> period2) {
    final comparison = <String, double>{};
    
    for (final key in period1.keys) {
      if (period2.containsKey(key)) {
        final change = period2[key]! - period1[key]!;
        final percentChange = period1[key]! > 0 ? (change / period1[key]!) * 100 : 0.0;
        comparison['${key}_change'] = change;
        comparison['${key}_percent_change'] = percentChange;
      }
    }
    
    return comparison;
  }

  static StatisticalSignificance _testStatisticalSignificance(Map<String, double> period1, Map<String, double> period2) {
    // Simplified significance test
    final totalRuns1 = period1['totalRuns'] ?? 0.0;
    final totalRuns2 = period2['totalRuns'] ?? 0.0;
    
    final changePercent = totalRuns1 > 0 ? ((totalRuns2 - totalRuns1) / totalRuns1).abs() * 100 : 0.0;
    
    if (changePercent > 20) return StatisticalSignificance.significant;
    if (changePercent > 10) return StatisticalSignificance.moderate;
    return StatisticalSignificance.notSignificant;
  }

  // Additional helper methods for remaining functions...
  
  static Map<String, double> _analyzeShiftTypePerformance(String serverId, List<ShiftRecord> shifts) {
    final shiftTypePerformance = <String, List<double>>{};
    
    for (final shift in shifts) {
      if (!shift.counts.containsKey(serverId)) continue;
      
      final runs = shift.counts[serverId]!.toDouble();
      shiftTypePerformance.putIfAbsent(shift.shiftType, () => []).add(runs);
    }
    
    return shiftTypePerformance.map((type, runsList) =>
      MapEntry(type, runsList.reduce((a, b) => a + b) / runsList.length));
  }

  static List<String> _identifyOptimalShiftPatterns(Map<String, double> shiftPerformance, SeasonalAnalysis seasonalAnalysis) {
    final sortedPerformance = shiftPerformance.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedPerformance.take(2).map((entry) => entry.key).toList();
  }

  static List<String> _generateSchedulingRecommendations(List<String> optimalPatterns, SeasonalAnalysis seasonalAnalysis) {
    final recommendations = <String>[];
    
    if (optimalPatterns.isNotEmpty) {
      recommendations.add('Schedule more ${optimalPatterns.first} shifts for optimal performance');
    }
    
    // Add day-of-week recommendations
    final bestDay = seasonalAnalysis.dayOfWeekPatterns.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    final dayNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    recommendations.add('${dayNames[bestDay.key]} shows highest performance');
    
    return recommendations;
  }

  static double _calculateShortTermVelocity(List<PerformanceTrend> trends) {
    if (trends.length < 7) return 0.0;
    
    final recentTrends = trends.skip(trends.length - 7).toList();
    final firstScore = recentTrends.first.score;
    final lastScore = recentTrends.last.score;
    
    return (lastScore - firstScore) / 7; // Points per day
  }

  static double _calculateLongTermVelocity(List<PerformanceTrend> trends) {
    if (trends.length < 30) return 0.0;
    
    final firstScore = trends.first.score;
    final lastScore = trends.last.score;
    
    return (lastScore - firstScore) / trends.length; // Points per day over entire period
  }

  static double _calculateAcceleration(List<PerformanceTrend> trends) {
    if (trends.length < 14) return 0.0;
    
    final firstHalf = trends.take(trends.length ~/ 2).toList();
    final secondHalf = trends.skip(trends.length ~/ 2).toList();
    
    final firstVelocity = _calculateShortTermVelocity(firstHalf);
    final secondVelocity = _calculateShortTermVelocity(secondHalf);
    
    return secondVelocity - firstVelocity;
  }

  static VelocityCategory _categorizeVelocity(double shortTerm, double longTerm) {
    if (shortTerm > 1.0 && longTerm > 0.5) return VelocityCategory.rapidImprovement;
    if (shortTerm > 0.5 && longTerm > 0.2) return VelocityCategory.steadyImprovement;
    if (shortTerm.abs() < 0.2 && longTerm.abs() < 0.1) return VelocityCategory.stable;
    if (shortTerm < -0.5 && longTerm < -0.2) return VelocityCategory.steadyDecline;
    if (shortTerm < -1.0 && longTerm < -0.5) return VelocityCategory.rapidDecline;
    return VelocityCategory.variable;
  }
}

// Supporting data classes

class PerformanceTrendAnalysis {
  final String serverId;
  final int analysisWindowDays;
  final List<DailyTrend> dailyTrends;
  final RollingAverages rollingAverages;
  final TrendDirection trendDirection;
  final TrendMomentum momentum;
  final PerformancePredictions predictions;
  final TrendPatterns patterns;
  final double confidence;
  final DateTime calculatedDate;

  PerformanceTrendAnalysis({
    required this.serverId,
    required this.analysisWindowDays,
    required this.dailyTrends,
    required this.rollingAverages,
    required this.trendDirection,
    required this.momentum,
    required this.predictions,
    required this.patterns,
    required this.confidence,
    required this.calculatedDate,
  });
}

class DailyTrend {
  final DateTime date;
  final int totalRuns;
  final int shiftsWorked;
  final double efficiency;
  final double score;

  DailyTrend({
    required this.date,
    required this.totalRuns,
    required this.shiftsWorked,
    required this.efficiency,
    required this.score,
  });
}

class RollingAverages {
  final List<double> sevenDay;
  final List<double> fourteenDay;
  final List<double> thirtyDay;

  RollingAverages({
    required this.sevenDay,
    required this.fourteenDay,
    required this.thirtyDay,
  });
}

class PerformancePredictions {
  final double nextWeek;
  final double nextMonth;
  final double confidence;

  PerformancePredictions({
    required this.nextWeek,
    required this.nextMonth,
    required this.confidence,
  });

  static PerformancePredictions insufficient() => PerformancePredictions(
    nextWeek: 0.0,
    nextMonth: 0.0,
    confidence: 0.0,
  );
}

class TrendPatterns {
  final bool hasWeeklyCycle;
  final List<AnomalyPoint> anomalies;
  final ConsistencyLevel consistencyLevel;

  TrendPatterns({
    required this.hasWeeklyCycle,
    required this.anomalies,
    required this.consistencyLevel,
  });
}

class AnomalyPoint {
  final DateTime date;
  final double score;
  final double zScore;
  final AnomalyType type;

  AnomalyPoint({
    required this.date,
    required this.score,
    required this.zScore,
    required this.type,
  });
}

class SeasonalAnalysis {
  final String serverId;
  final int monthsAnalyzed;
  final Map<int, double> dayOfWeekPatterns;
  final Map<String, double> monthlyPatterns;
  final PerformancePeaks performancePeaks;
  final Map<String, double> seasonalAdjustments;

  SeasonalAnalysis({
    required this.serverId,
    required this.monthsAnalyzed,
    required this.dayOfWeekPatterns,
    required this.monthlyPatterns,
    required this.performancePeaks,
    required this.seasonalAdjustments,
  });
}

class PerformancePeaks {
  final String bestMonth;
  final String worstMonth;
  final double peakScore;
  final double lowScore;

  PerformancePeaks({
    required this.bestMonth,
    required this.worstMonth,
    required this.peakScore,
    required this.lowScore,
  });
}

class PeriodComparison {
  final String serverId;
  final PeriodData period1;
  final PeriodData period2;
  final Map<String, double> comparison;
  final StatisticalSignificance statisticalSignificance;

  PeriodComparison({
    required this.serverId,
    required this.period1,
    required this.period2,
    required this.comparison,
    required this.statisticalSignificance,
  });
}

class PeriodData {
  final DateTime start;
  final DateTime end;
  final Map<String, double> data;

  PeriodData({
    required this.start,
    required this.end,
    required this.data,
  });
}

class SchedulingOptimization {
  final String serverId;
  final Map<String, double> shiftPerformance;
  final List<String> optimalPatterns;
  final List<String> recommendations;

  SchedulingOptimization({
    required this.serverId,
    required this.shiftPerformance,
    required this.optimalPatterns,
    required this.recommendations,
  });
}

class PerformanceVelocity {
  final double shortTermVelocity;
  final double longTermVelocity;
  final double acceleration;
  final VelocityCategory category;

  PerformanceVelocity({
    required this.shortTermVelocity,
    required this.longTermVelocity,
    required this.acceleration,
    required this.category,
  });

  static PerformanceVelocity zero() => PerformanceVelocity(
    shortTermVelocity: 0.0,
    longTermVelocity: 0.0,
    acceleration: 0.0,
    category: VelocityCategory.stable,
  );
}

enum TrendDirection { improving, declining, stable }
enum TrendMomentum { strong, moderate, neutral, moderateNegative, strongNegative }
enum AnomalyType { unusuallyHigh, unusuallyLow }
enum ConsistencyLevel { veryHigh, high, moderate, low, veryLow, unknown }
enum StatisticalSignificance { significant, moderate, notSignificant }
enum VelocityCategory { rapidImprovement, steadyImprovement, stable, variable, steadyDecline, rapidDecline }