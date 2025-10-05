/// Advanced Station Analytics Service
/// Phase 3: Advanced analytics with trend analysis, efficiency scoring, and performance comparisons

import '../models.dart';
import '../utils/log.dart';
import 'dart:math' as math;

/// Advanced analytics data for station/section performance
class AdvancedStationAnalytics {
  final String sectionName;
  final String stationType;
  final List<PerformanceTrend> trends;
  final EfficiencyScore efficiencyScore;
  final PerformanceComparison comparison;
  final List<PerformanceInsight> insights;
  final DateTime analysisDate;

  AdvancedStationAnalytics({
    required this.sectionName,
    required this.stationType,
    required this.trends,
    required this.efficiencyScore,
    required this.comparison,
    required this.insights,
    required this.analysisDate,
  });
}

/// Performance trend data over time
class PerformanceTrend {
  final String metricName;
  final List<TrendDataPoint> dataPoints;
  final TrendDirection direction;
  final double trendStrength; // R-squared value
  final double velocity; // Rate of change
  final String description;

  PerformanceTrend({
    required this.metricName,
    required this.dataPoints,
    required this.direction,
    required this.trendStrength,
    required this.velocity,
    required this.description,
  });
}

/// Individual data point in a trend
class TrendDataPoint {
  final DateTime date;
  final double value;
  final String period; // "week", "month", etc.

  TrendDataPoint({
    required this.date,
    required this.value,
    required this.period,
  });
}

/// Trend direction enum
enum TrendDirection {
  improving,
  declining,
  stable,
  volatile,
  unknown
}

/// Advanced efficiency scoring
class EfficiencyScore {
  final double overallScore; // 0-100
  final double runsEfficiency; // Based on runs per shift
  final double salesEfficiency; // Based on sales per run
  final double timeEfficiency; // Based on shift duration
  final double consistencyScore; // Based on variance
  final EfficiencyGrade grade;
  final List<String> improvementAreas;

  EfficiencyScore({
    required this.overallScore,
    required this.runsEfficiency,
    required this.salesEfficiency,
    required this.timeEfficiency,
    required this.consistencyScore,
    required this.grade,
    required this.improvementAreas,
  });
}

/// Efficiency grade levels
enum EfficiencyGrade {
  excellent, // 90-100
  good, // 80-89
  average, // 70-79
  belowAverage, // 60-69
  poor // 0-59
}

/// Performance comparison data
class PerformanceComparison {
  final double rank; // 1-10, where 1 is best
  final double percentile; // 0-100
  final List<ComparisonMetric> metrics;
  final String comparisonSummary;

  PerformanceComparison({
    required this.rank,
    required this.percentile,
    required this.metrics,
    required this.comparisonSummary,
  });
}

/// Individual comparison metric
class ComparisonMetric {
  final String name;
  final double value;
  final double average;
  final double difference; // value - average
  final double percentageDifference; // (difference / average) * 100
  final ComparisonStatus status;

  ComparisonMetric({
    required this.name,
    required this.value,
    required this.average,
    required this.difference,
    required this.percentageDifference,
    required this.status,
  });
}

/// Comparison status
enum ComparisonStatus {
  aboveAverage,
  atAverage,
  belowAverage
}

/// Performance insight
class PerformanceInsight {
  final String title;
  final String description;
  final InsightType type;
  final InsightPriority priority;
  final List<String> recommendations;

  PerformanceInsight({
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.recommendations,
  });
}

/// Insight types
enum InsightType {
  trend,
  efficiency,
  comparison,
  recommendation,
  warning
}

/// Insight priority levels
enum InsightPriority {
  high,
  medium,
  low
}

class AdvancedStationAnalyticsService {
  static final AdvancedStationAnalyticsService _instance = AdvancedStationAnalyticsService._internal();
  factory AdvancedStationAnalyticsService() => _instance;
  AdvancedStationAnalyticsService._internal();

  /// Generate advanced analytics for a section
  Future<AdvancedStationAnalytics> generateAdvancedAnalytics({
    required String sectionName,
    required String stationType,
    required List<ShiftRecord> shiftRecords,
    required List<dynamic> allSectionData, // All sections for comparison
  }) async {
    try {
      d('[AdvancedStationAnalytics] Generating advanced analytics for $sectionName');
      
      // Filter shift records for this section
      final sectionShifts = _filterShiftsForSection(shiftRecords, sectionName);
      
      // Generate trends
      final trends = await _generateTrends(sectionShifts);
      
      // Calculate efficiency score
      final efficiencyScore = _calculateEfficiencyScore(sectionShifts);
      
      // Generate performance comparison
      final comparison = _generatePerformanceComparison(sectionName, allSectionData);
      
      // Generate insights
      final insights = _generateInsights(trends, efficiencyScore, comparison);
      
      return AdvancedStationAnalytics(
        sectionName: sectionName,
        stationType: stationType,
        trends: trends,
        efficiencyScore: efficiencyScore,
        comparison: comparison,
        insights: insights,
        analysisDate: DateTime.now(),
      );
    } catch (e) {
      d('[AdvancedStationAnalytics] Error generating analytics: $e');
      rethrow;
    }
  }

  /// Filter shift records for a specific section
  List<ShiftRecord> _filterShiftsForSection(List<ShiftRecord> shiftRecords, String sectionName) {
    // This would need to be implemented based on how section assignments are stored
    // For now, return all shifts as a placeholder
    return shiftRecords;
  }

  /// Generate performance trends
  Future<List<PerformanceTrend>> _generateTrends(List<ShiftRecord> shifts) async {
    final trends = <PerformanceTrend>[];
    
    // Generate runs trend
    final runsTrend = _generateRunsTrend(shifts);
    if (runsTrend != null) trends.add(runsTrend);
    
    // Generate efficiency trend
    final efficiencyTrend = _generateEfficiencyTrend(shifts);
    if (efficiencyTrend != null) trends.add(efficiencyTrend);
    
    return trends;
  }

  /// Generate runs trend
  PerformanceTrend? _generateRunsTrend(List<ShiftRecord> shifts) {
    if (shifts.length < 3) return null; // Need at least 3 data points
    
    final dataPoints = <TrendDataPoint>[];
    for (int i = 0; i < shifts.length; i++) {
      final shift = shifts[i];
      final totalRuns = shift.counts.values.fold(0, (sum, runs) => sum + runs);
      dataPoints.add(TrendDataPoint(
        date: shift.start,
        value: totalRuns.toDouble(),
        period: 'shift',
      ));
    }
    
    final trendAnalysis = _analyzeTrend(dataPoints);
    
    return PerformanceTrend(
      metricName: 'Total Runs',
      dataPoints: dataPoints,
      direction: trendAnalysis.direction,
      trendStrength: trendAnalysis.strength,
      velocity: trendAnalysis.velocity,
      description: _generateTrendDescription('runs', trendAnalysis),
    );
  }

  /// Generate efficiency trend
  PerformanceTrend? _generateEfficiencyTrend(List<ShiftRecord> shifts) {
    if (shifts.length < 3) return null;
    
    final dataPoints = <TrendDataPoint>[];
    for (int i = 0; i < shifts.length; i++) {
      final shift = shifts[i];
      final totalRuns = shift.counts.values.fold(0, (sum, runs) => sum + runs);
      final efficiency = totalRuns / 20.0; // Target: 20 runs per shift
      dataPoints.add(TrendDataPoint(
        date: shift.start,
        value: efficiency * 100, // Convert to percentage
        period: 'shift',
      ));
    }
    
    final trendAnalysis = _analyzeTrend(dataPoints);
    
    return PerformanceTrend(
      metricName: 'Efficiency',
      dataPoints: dataPoints,
      direction: trendAnalysis.direction,
      trendStrength: trendAnalysis.strength,
      velocity: trendAnalysis.velocity,
      description: _generateTrendDescription('efficiency', trendAnalysis),
    );
  }

  /// Analyze trend data
  TrendAnalysis _analyzeTrend(List<TrendDataPoint> dataPoints) {
    if (dataPoints.length < 2) {
      return TrendAnalysis(
        direction: TrendDirection.unknown,
        strength: 0.0,
        velocity: 0.0,
      );
    }
    
    // Calculate linear regression
    final n = dataPoints.length;
    final xValues = List.generate(n, (i) => i.toDouble());
    final yValues = dataPoints.map((p) => p.value).toList();
    
    final sumX = xValues.reduce((a, b) => a + b);
    final sumY = yValues.reduce((a, b) => a + b);
    final sumXY = xValues.asMap().entries.fold(0.0, (sum, entry) => 
        sum + (entry.value * yValues[entry.key]));
    final sumXX = xValues.fold(0.0, (sum, x) => sum + (x * x));
    final sumYY = yValues.fold(0.0, (sum, y) => sum + (y * y));
    
    final slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;
    
    // Calculate R-squared
    final yMean = sumY / n;
    final ssRes = xValues.asMap().entries.fold(0.0, (sum, entry) {
      final predicted = slope * entry.value + intercept;
      final actual = yValues[entry.key];
      return sum + math.pow(actual - predicted, 2);
    });
    final ssTot = yValues.fold(0.0, (sum, y) => sum + math.pow(y - yMean, 2));
    final rSquared = 1 - (ssRes / ssTot);
    
    // Determine direction
    TrendDirection direction;
    if (slope > 0.1) {
      direction = TrendDirection.improving;
    } else if (slope < -0.1) {
      direction = TrendDirection.declining;
    } else {
      direction = TrendDirection.stable;
    }
    
    return TrendAnalysis(
      direction: direction,
      strength: rSquared.clamp(0.0, 1.0),
      velocity: slope,
    );
  }

  /// Calculate efficiency score
  EfficiencyScore _calculateEfficiencyScore(List<ShiftRecord> shifts) {
    if (shifts.isEmpty) {
      return EfficiencyScore(
        overallScore: 0.0,
        runsEfficiency: 0.0,
        salesEfficiency: 0.0,
        timeEfficiency: 0.0,
        consistencyScore: 0.0,
        grade: EfficiencyGrade.poor,
        improvementAreas: ['No data available'],
      );
    }
    
    // Calculate runs efficiency
    final totalRuns = shifts.fold(0, (sum, shift) => 
        sum + shift.counts.values.fold(0, (s, runs) => s + runs));
    final avgRunsPerShift = totalRuns / shifts.length;
    final runsEfficiency = (avgRunsPerShift / 20.0 * 100).clamp(0.0, 100.0);
    
    // Calculate sales efficiency (placeholder)
    final salesEfficiency = 75.0; // Would be calculated from actual sales data
    
    // Calculate time efficiency (placeholder)
    final timeEfficiency = 80.0; // Would be calculated from shift duration data
    
    // Calculate consistency score
    final runsValues = shifts.map((shift) => 
        shift.counts.values.fold(0, (sum, runs) => sum + runs).toDouble()).toList();
    final consistencyScore = _calculateConsistency(runsValues);
    
    // Calculate overall score
    final overallScore = (runsEfficiency * 0.4 + salesEfficiency * 0.3 + 
                         timeEfficiency * 0.2 + consistencyScore * 0.1);
    
    // Determine grade
    EfficiencyGrade grade;
    if (overallScore >= 90) {
      grade = EfficiencyGrade.excellent;
    } else if (overallScore >= 80) {
      grade = EfficiencyGrade.good;
    } else if (overallScore >= 70) {
      grade = EfficiencyGrade.average;
    } else if (overallScore >= 60) {
      grade = EfficiencyGrade.belowAverage;
    } else {
      grade = EfficiencyGrade.poor;
    }
    
    // Generate improvement areas
    final improvementAreas = <String>[];
    if (runsEfficiency < 80) improvementAreas.add('Increase runs per shift');
    if (salesEfficiency < 80) improvementAreas.add('Improve sales performance');
    if (timeEfficiency < 80) improvementAreas.add('Optimize time management');
    if (consistencyScore < 70) improvementAreas.add('Improve consistency');
    
    return EfficiencyScore(
      overallScore: overallScore,
      runsEfficiency: runsEfficiency,
      salesEfficiency: salesEfficiency,
      timeEfficiency: timeEfficiency,
      consistencyScore: consistencyScore,
      grade: grade,
      improvementAreas: improvementAreas,
    );
  }

  /// Calculate consistency score based on variance
  double _calculateConsistency(List<double> values) {
    if (values.length < 2) return 100.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.fold(0.0, (sum, value) => 
        sum + math.pow(value - mean, 2)) / values.length;
    final standardDeviation = math.sqrt(variance);
    final coefficientOfVariation = standardDeviation / mean;
    
    // Convert to 0-100 scale (lower CV = higher consistency)
    return (100 - (coefficientOfVariation * 100)).clamp(0.0, 100.0);
  }

  /// Generate performance comparison
  PerformanceComparison _generatePerformanceComparison(String sectionName, List<dynamic> allSectionData) {
    // This would compare the section against all other sections
    // For now, return placeholder data
    return PerformanceComparison(
      rank: 3.0,
      percentile: 75.0,
      metrics: [
        ComparisonMetric(
          name: 'Runs per Shift',
          value: 18.5,
          average: 16.2,
          difference: 2.3,
          percentageDifference: 14.2,
          status: ComparisonStatus.aboveAverage,
        ),
        ComparisonMetric(
          name: 'Efficiency Score',
          value: 85.0,
          average: 78.0,
          difference: 7.0,
          percentageDifference: 9.0,
          status: ComparisonStatus.aboveAverage,
        ),
      ],
      comparisonSummary: 'This section performs above average in most metrics',
    );
  }

  /// Generate insights
  List<PerformanceInsight> _generateInsights(
    List<PerformanceTrend> trends,
    EfficiencyScore efficiencyScore,
    PerformanceComparison comparison,
  ) {
    final insights = <PerformanceInsight>[];
    
    // Trend insights
    for (final trend in trends) {
      if (trend.direction == TrendDirection.improving && trend.trendStrength > 0.7) {
        insights.add(PerformanceInsight(
          title: 'Strong ${trend.metricName} Improvement',
          description: trend.description,
          type: InsightType.trend,
          priority: InsightPriority.high,
          recommendations: ['Continue current practices', 'Share strategies with other sections'],
        ));
      } else if (trend.direction == TrendDirection.declining && trend.trendStrength > 0.5) {
        insights.add(PerformanceInsight(
          title: '${trend.metricName} Declining',
          description: trend.description,
          type: InsightType.warning,
          priority: InsightPriority.high,
          recommendations: ['Investigate root causes', 'Implement improvement plan'],
        ));
      }
    }
    
    // Efficiency insights
    if (efficiencyScore.grade == EfficiencyGrade.excellent) {
      insights.add(PerformanceInsight(
        title: 'Excellent Efficiency Performance',
        description: 'This section demonstrates outstanding efficiency across all metrics',
        type: InsightType.efficiency,
        priority: InsightPriority.medium,
        recommendations: ['Use as training example', 'Document best practices'],
      ));
    } else if (efficiencyScore.grade == EfficiencyGrade.poor) {
      insights.add(PerformanceInsight(
        title: 'Efficiency Needs Improvement',
        description: 'This section requires immediate attention to improve performance',
        type: InsightType.warning,
        priority: InsightPriority.high,
        recommendations: efficiencyScore.improvementAreas,
      ));
    }
    
    // Comparison insights
    if (comparison.percentile >= 90) {
      insights.add(PerformanceInsight(
        title: 'Top Performer',
        description: 'This section ranks in the top 10% of all sections',
        type: InsightType.comparison,
        priority: InsightPriority.medium,
        recommendations: ['Maintain current performance', 'Mentor other sections'],
      ));
    }
    
    return insights;
  }

  /// Generate trend description
  String _generateTrendDescription(String metric, TrendAnalysis analysis) {
    final direction = analysis.direction;
    final strength = analysis.strength;
    final velocity = analysis.velocity;
    
    String directionText;
    switch (direction) {
      case TrendDirection.improving:
        directionText = 'improving';
        break;
      case TrendDirection.declining:
        directionText = 'declining';
        break;
      case TrendDirection.stable:
        directionText = 'stable';
        break;
      case TrendDirection.volatile:
        directionText = 'volatile';
        break;
      case TrendDirection.unknown:
        directionText = 'unclear';
        break;
    }
    
    String strengthText;
    if (strength > 0.8) {
      strengthText = 'strong';
    } else if (strength > 0.5) {
      strengthText = 'moderate';
    } else {
      strengthText = 'weak';
    }
    
    return '$metric shows a $strengthText $directionText trend (${(velocity * 100).toStringAsFixed(1)}% change per period)';
  }
}

/// Trend analysis result
class TrendAnalysis {
  final TrendDirection direction;
  final double strength; // R-squared
  final double velocity; // Rate of change

  TrendAnalysis({
    required this.direction,
    required this.strength,
    required this.velocity,
  });
}



