import '../models/monthly_report.dart';
import '../utils/log.dart';
import 'dart:math' as math;

/// Advanced Trend Analysis Service
/// Phase 3: Sophisticated trend analysis with velocity, strength, and reliability
class AdvancedTrendAnalysisService {
  static final AdvancedTrendAnalysisService _instance = AdvancedTrendAnalysisService._internal();
  factory AdvancedTrendAnalysisService() => _instance;
  AdvancedTrendAnalysisService._internal();

  /// Analyze advanced trends for a server
  AdvancedTrendAnalysis analyzeServerTrends({
    required List<NPSMonthlyReport> monthlyReports,
    required String serverName,
    required String serverId,
  }) {
    try {
      d('[AdvancedTrendAnalysisService] Analyzing trends for server: $serverName');

      if (monthlyReports.length < 2) {
        return AdvancedTrendAnalysis(
          serverId: serverId,
          serverName: serverName,
          trendDirection: TrendDirection.unknown,
          trendStrength: 0.0,
          trendVelocity: 0.0,
          trendAcceleration: 0.0,
          trendReliability: 0.0,
          trendPersistence: 0,
          volatility: 0.0,
          momentum: MomentumType.neutral,
          peerRanking: 0,
          benchmarkComparison: BenchmarkComparison.unknown,
          trendConfidence: 0.0,
          trendInsights: ['Insufficient data for trend analysis'],
          trendRecommendations: ['Enter more monthly NPS data to enable trend analysis'],
          projectedPerformance: null,
          trendSustainability: 0.0,
        );
      }

      // Sort reports by date (oldest first)
      final sortedReports = _sortReportsByDate(monthlyReports);
      
      // Calculate trend metrics
      final trendDirection = _calculateTrendDirection(sortedReports);
      final trendStrength = _calculateTrendStrength(sortedReports);
      final trendVelocity = _calculateTrendVelocity(sortedReports);
      final trendAcceleration = _calculateTrendAcceleration(sortedReports);
      final trendReliability = _calculateTrendReliability(sortedReports);
      final trendPersistence = _calculateTrendPersistence(sortedReports);
      final volatility = _calculateVolatility(sortedReports);
      final momentum = _determineMomentum(trendVelocity, trendAcceleration);
      
      // Calculate comparative metrics (will be updated when we have peer data)
      final peerRanking = 0; // Placeholder - will be calculated with peer data
      final benchmarkComparison = _calculateBenchmarkComparison(sortedReports);
      
      // Calculate trend confidence
      final trendConfidence = _calculateTrendConfidence(
        trendStrength, 
        trendReliability, 
        trendPersistence, 
        volatility
      );
      
      // Generate insights and recommendations
      final trendInsights = _generateTrendInsights(
        trendDirection,
        trendStrength,
        trendVelocity,
        trendAcceleration,
        trendPersistence,
        volatility,
        momentum,
      );
      
      final trendRecommendations = _generateTrendRecommendations(
        trendDirection,
        trendStrength,
        trendVelocity,
        trendAcceleration,
        momentum,
        trendConfidence,
      );
      
      // Calculate projected performance
      final projectedPerformance = _calculateProjectedPerformance(
        sortedReports,
        trendVelocity,
        trendAcceleration,
      );
      
      // Calculate trend sustainability
      final trendSustainability = _calculateTrendSustainability(
        trendStrength,
        trendReliability,
        volatility,
        trendPersistence,
      );

      d('[AdvancedTrendAnalysisService] Trend analysis complete for $serverName: $trendDirection (${trendStrength.toStringAsFixed(1)}% strength)');

      return AdvancedTrendAnalysis(
        serverId: serverId,
        serverName: serverName,
        trendDirection: trendDirection,
        trendStrength: trendStrength,
        trendVelocity: trendVelocity,
        trendAcceleration: trendAcceleration,
        trendReliability: trendReliability,
        trendPersistence: trendPersistence,
        volatility: volatility,
        momentum: momentum,
        peerRanking: peerRanking,
        benchmarkComparison: benchmarkComparison,
        trendConfidence: trendConfidence,
        trendInsights: trendInsights,
        trendRecommendations: trendRecommendations,
        projectedPerformance: projectedPerformance,
        trendSustainability: trendSustainability,
      );
    } catch (e) {
      d('[AdvancedTrendAnalysisService] Error analyzing trends: $e');
      return AdvancedTrendAnalysis(
        serverId: serverId,
        serverName: serverName,
        trendDirection: TrendDirection.unknown,
        trendStrength: 0.0,
        trendVelocity: 0.0,
        trendAcceleration: 0.0,
        trendReliability: 0.0,
        trendPersistence: 0,
        volatility: 0.0,
        momentum: MomentumType.neutral,
        peerRanking: 0,
        benchmarkComparison: BenchmarkComparison.unknown,
        trendConfidence: 0.0,
        trendInsights: ['Error occurred during trend analysis'],
        trendRecommendations: ['Contact support if this issue persists'],
        projectedPerformance: null,
        trendSustainability: 0.0,
      );
    }
  }

  /// Sort reports by date (oldest first)
  List<NPSMonthlyReport> _sortReportsByDate(List<NPSMonthlyReport> reports) {
    final sorted = List<NPSMonthlyReport>.from(reports);
    sorted.sort((a, b) {
      if (a.reportYear != b.reportYear) return a.reportYear.compareTo(b.reportYear);
      return a.reportMonth.compareTo(b.reportMonth);
    });
    return sorted;
  }

  /// Calculate trend direction using linear regression
  TrendDirection _calculateTrendDirection(List<NPSMonthlyReport> reports) {
    final npsScores = reports
        .map((r) => r.allTimeNpsPercentage ?? 0.0)
        .where((score) => score > 0)
        .toList();

    if (npsScores.length < 2) return TrendDirection.unknown;

    // Simple linear regression
    final n = npsScores.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;
    
    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += npsScores[i];
      sumXY += i * npsScores[i];
      sumXX += i * i;
    }

    final slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    
    if (slope > 0.5) return TrendDirection.stronglyImproving;
    if (slope > 0.1) return TrendDirection.improving;
    if (slope > -0.1) return TrendDirection.stable;
    if (slope > -0.5) return TrendDirection.declining;
    return TrendDirection.stronglyDeclining;
  }

  /// Calculate trend strength (R-squared value)
  double _calculateTrendStrength(List<NPSMonthlyReport> reports) {
    d('[AdvancedTrendAnalysisService] Calculating trend strength for ${reports.length} reports');
    
    final npsScores = reports
        .map((r) => r.allTimeNpsPercentage ?? 0.0)
        .where((score) => score > 0)
        .toList();

    d('[AdvancedTrendAnalysisService] NPS scores after filtering: $npsScores');
    d('[AdvancedTrendAnalysisService] Raw allTimeNpsPercentage values: ${reports.map((r) => r.allTimeNpsPercentage).toList()}');

    if (npsScores.length < 3) {
      d('[AdvancedTrendAnalysisService] Insufficient data for strength calculation: ${npsScores.length} < 3');
      return -1.0; // Special value to indicate insufficient data
    }

    // Calculate R-squared
    final n = npsScores.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0, sumYY = 0;
    
    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += npsScores[i];
      sumXY += i * npsScores[i];
      sumXX += i * i;
      sumYY += npsScores[i] * npsScores[i];
    }

    final meanX = sumX / n;
    final meanY = sumY / n;
    
    double ssXY = 0, ssXX = 0, ssYY = 0;
    for (int i = 0; i < n; i++) {
      final xDiff = i - meanX;
      final yDiff = npsScores[i] - meanY;
      ssXY += xDiff * yDiff;
      ssXX += xDiff * xDiff;
      ssYY += yDiff * yDiff;
    }

    final rSquared = ssXY * ssXY / (ssXX * ssYY);
    return (rSquared * 100).clamp(0.0, 100.0);
  }

  /// Calculate trend velocity (rate of change per month)
  double _calculateTrendVelocity(List<NPSMonthlyReport> reports) {
    final npsScores = reports
        .map((r) => r.allTimeNpsPercentage ?? 0.0)
        .where((score) => score > 0)
        .toList();

    if (npsScores.length < 2) return 0.0;

    // Calculate average monthly change
    double totalChange = 0.0;
    for (int i = 1; i < npsScores.length; i++) {
      totalChange += npsScores[i] - npsScores[i - 1];
    }
    
    return totalChange / (npsScores.length - 1);
  }

  /// Calculate trend acceleration (change in velocity)
  double _calculateTrendAcceleration(List<NPSMonthlyReport> reports) {
    final npsScores = reports
        .map((r) => r.allTimeNpsPercentage ?? 0.0)
        .where((score) => score > 0)
        .toList();

    if (npsScores.length < 3) return 0.0;

    // Calculate velocity for first half and second half
    final midPoint = npsScores.length ~/ 2;
    
    double firstHalfVelocity = 0.0;
    for (int i = 1; i < midPoint; i++) {
      firstHalfVelocity += npsScores[i] - npsScores[i - 1];
    }
    firstHalfVelocity /= (midPoint - 1);
    
    double secondHalfVelocity = 0.0;
    for (int i = midPoint + 1; i < npsScores.length; i++) {
      secondHalfVelocity += npsScores[i] - npsScores[i - 1];
    }
    secondHalfVelocity /= (npsScores.length - midPoint - 1);
    
    return secondHalfVelocity - firstHalfVelocity;
  }

  /// Calculate trend reliability (consistency of trend)
  double _calculateTrendReliability(List<NPSMonthlyReport> reports) {
    final npsScores = reports
        .map((r) => r.allTimeNpsPercentage ?? 0.0)
        .where((score) => score > 0)
        .toList();

    if (npsScores.length < 3) return 0.0;

    // Calculate how consistent the trend direction is
    int consistentDirection = 0;
    int totalComparisons = 0;
    
    for (int i = 2; i < npsScores.length; i++) {
      final recentChange = npsScores[i] - npsScores[i - 1];
      final previousChange = npsScores[i - 1] - npsScores[i - 2];
      
      if ((recentChange > 0 && previousChange > 0) || 
          (recentChange < 0 && previousChange < 0) ||
          (recentChange.abs() < 0.1 && previousChange.abs() < 0.1)) {
        consistentDirection++;
      }
      totalComparisons++;
    }
    
    return totalComparisons > 0 ? (consistentDirection / totalComparisons * 100) : 0.0;
  }

  /// Calculate trend persistence (how long trend has been consistent)
  int _calculateTrendPersistence(List<NPSMonthlyReport> reports) {
    final npsScores = reports
        .map((r) => r.allTimeNpsPercentage ?? 0.0)
        .where((score) => score > 0)
        .toList();

    if (npsScores.length < 2) return 0;

    // Count consecutive months with same direction
    int persistence = 1;
    final firstChange = npsScores[1] - npsScores[0];
    final isPositive = firstChange > 0.1;
    final isNegative = firstChange < -0.1;
    
    for (int i = 2; i < npsScores.length; i++) {
      final change = npsScores[i] - npsScores[i - 1];
      final currentIsPositive = change > 0.1;
      final currentIsNegative = change < -0.1;
      
      if ((isPositive && currentIsPositive) || 
          (isNegative && currentIsNegative) ||
          (firstChange.abs() < 0.1 && change.abs() < 0.1)) {
        persistence++;
      } else {
        break;
      }
    }
    
    return persistence;
  }

  /// Calculate volatility (standard deviation of changes)
  double _calculateVolatility(List<NPSMonthlyReport> reports) {
    d('[AdvancedTrendAnalysisService] Calculating volatility for ${reports.length} reports');
    
    final npsScores = reports
        .map((r) => r.allTimeNpsPercentage ?? 0.0)
        .where((score) => score > 0)
        .toList();

    d('[AdvancedTrendAnalysisService] NPS scores for volatility: $npsScores');
    d('[AdvancedTrendAnalysisService] Raw allTimeNpsPercentage values: ${reports.map((r) => r.allTimeNpsPercentage).toList()}');

    if (npsScores.length < 2) {
      d('[AdvancedTrendAnalysisService] Insufficient data for volatility calculation: ${npsScores.length} < 2');
      return -1.0; // Special value to indicate insufficient data
    }

    // Calculate changes
    final changes = <double>[];
    for (int i = 1; i < npsScores.length; i++) {
      changes.add(npsScores[i] - npsScores[i - 1]);
    }
    
    d('[AdvancedTrendAnalysisService] Month-to-month changes: $changes');
    
    // Calculate standard deviation
    final mean = changes.reduce((a, b) => a + b) / changes.length;
    final variance = changes.map((change) => (change - mean) * (change - mean)).reduce((a, b) => a + b) / changes.length;
    final volatility = math.sqrt(variance);
    
    d('[AdvancedTrendAnalysisService] Mean change: $mean, Variance: $variance, Volatility: $volatility');
    
    return volatility;
  }

  /// Determine momentum type
  MomentumType _determineMomentum(double velocity, double acceleration) {
    if (velocity > 1.0 && acceleration > 0.5) return MomentumType.strongPositive;
    if (velocity > 0.5 && acceleration > 0) return MomentumType.positive;
    if (velocity > 0.1) return MomentumType.weakPositive;
    if (velocity < -1.0 && acceleration < -0.5) return MomentumType.strongNegative;
    if (velocity < -0.5 && acceleration < 0) return MomentumType.negative;
    if (velocity < -0.1) return MomentumType.weakNegative;
    return MomentumType.neutral;
  }

  /// Calculate benchmark comparison
  BenchmarkComparison _calculateBenchmarkComparison(List<NPSMonthlyReport> reports) {
    if (reports.isEmpty) return BenchmarkComparison.unknown;
    
    final latestScore = reports.last.allTimeNpsPercentage ?? 0.0;
    
    if (latestScore >= 90) return BenchmarkComparison.exceedsBenchmark;
    if (latestScore >= 80) return BenchmarkComparison.meetsBenchmark;
    if (latestScore >= 60) return BenchmarkComparison.approachingBenchmark;
    if (latestScore >= 40) return BenchmarkComparison.belowBenchmark;
    return BenchmarkComparison.wellBelowBenchmark;
  }

  /// Calculate trend confidence
  double _calculateTrendConfidence(double strength, double reliability, int persistence, double volatility) {
    // Weight factors
    final strengthWeight = 0.3;
    final reliabilityWeight = 0.3;
    final persistenceWeight = 0.2;
    final volatilityWeight = 0.2;
    
    // Normalize persistence (max 12 months)
    final normalizedPersistence = (persistence / 12.0 * 100).clamp(0.0, 100.0);
    
    // Invert volatility (lower volatility = higher confidence)
    final volatilityScore = (100 - (volatility * 10)).clamp(0.0, 100.0);
    
    final confidence = (strength * strengthWeight) +
                     (reliability * reliabilityWeight) +
                     (normalizedPersistence * persistenceWeight) +
                     (volatilityScore * volatilityWeight);
    
    return confidence.clamp(0.0, 100.0);
  }

  /// Generate trend insights
  List<String> _generateTrendInsights(
    TrendDirection direction,
    double strength,
    double velocity,
    double acceleration,
    int persistence,
    double volatility,
    MomentumType momentum,
  ) {
    final insights = <String>[];
    
    // Direction insights
    switch (direction) {
      case TrendDirection.stronglyImproving:
        insights.add('Performance is improving rapidly with strong positive momentum');
        break;
      case TrendDirection.improving:
        insights.add('Performance shows consistent improvement over time');
        break;
      case TrendDirection.stable:
        insights.add('Performance remains stable with minimal variation');
        break;
      case TrendDirection.declining:
        insights.add('Performance shows concerning decline trend');
        break;
      case TrendDirection.stronglyDeclining:
        insights.add('Performance is declining rapidly and requires immediate attention');
        break;
      case TrendDirection.unknown:
        insights.add('Insufficient data to determine trend direction');
        break;
    }
    
    // Strength insights
    if (strength >= 80) {
      insights.add('Trend is very strong and highly reliable (${strength.toStringAsFixed(1)}% strength)');
    } else if (strength >= 60) {
      insights.add('Trend is moderately strong (${strength.toStringAsFixed(1)}% strength)');
    } else if (strength >= 40) {
      insights.add('Trend is weak and may not be reliable (${strength.toStringAsFixed(1)}% strength)');
    } else {
      insights.add('Trend is very weak and unreliable (${strength.toStringAsFixed(1)}% strength)');
    }
    
    // Velocity insights
    if (velocity.abs() > 2.0) {
      insights.add('Performance is changing rapidly (${velocity.toStringAsFixed(1)} points per month)');
    } else if (velocity.abs() > 1.0) {
      insights.add('Performance is changing moderately (${velocity.toStringAsFixed(1)} points per month)');
    } else {
      insights.add('Performance is changing slowly (${velocity.toStringAsFixed(1)} points per month)');
    }
    
    // Persistence insights
    if (persistence >= 6) {
      insights.add('Trend has been consistent for $persistence months');
    } else if (persistence >= 3) {
      insights.add('Trend has been developing for $persistence months');
    } else {
      insights.add('Trend is relatively new ($persistence months)');
    }
    
    // Volatility insights
    if (volatility > 5.0) {
      insights.add('Performance is highly volatile and unpredictable');
    } else if (volatility > 2.0) {
      insights.add('Performance shows moderate volatility');
    } else {
      insights.add('Performance is stable with low volatility');
    }
    
    return insights;
  }

  /// Generate trend recommendations
  List<String> _generateTrendRecommendations(
    TrendDirection direction,
    double strength,
    double velocity,
    double acceleration,
    MomentumType momentum,
    double confidence,
  ) {
    final recommendations = <String>[];
    
    // Direction-based recommendations
    switch (direction) {
      case TrendDirection.stronglyImproving:
        recommendations.addAll([
          'Continue current practices - strong improvement trend',
          'Consider this server as a mentor for others',
          'Document successful strategies for replication',
        ]);
        break;
      case TrendDirection.improving:
        recommendations.addAll([
          'Maintain current improvement strategies',
          'Identify specific factors driving improvement',
          'Set goals to accelerate improvement rate',
        ]);
        break;
      case TrendDirection.stable:
        recommendations.addAll([
          'Maintain current performance level',
          'Look for opportunities to break through plateau',
          'Consider new challenges or responsibilities',
        ]);
        break;
      case TrendDirection.declining:
        recommendations.addAll([
          'Investigate causes of performance decline',
          'Provide additional support and training',
          'Set up regular check-ins to monitor progress',
        ]);
        break;
      case TrendDirection.stronglyDeclining:
        recommendations.addAll([
          'Immediate intervention required',
          'Develop comprehensive improvement plan',
          'Consider additional training or role adjustment',
          'Monitor progress closely with daily check-ins',
        ]);
        break;
      case TrendDirection.unknown:
        recommendations.addAll([
          'Collect more data to enable trend analysis',
          'Ensure consistent data quality',
          'Contact support if data issues persist',
        ]);
        break;
    }
    
    // Confidence-based recommendations
    if (confidence < 50) {
      recommendations.add('Gather more data to improve trend reliability');
    }
    
    // Momentum-based recommendations
    switch (momentum) {
      case MomentumType.strongPositive:
        recommendations.add('Leverage positive momentum for additional growth');
        break;
      case MomentumType.positive:
        recommendations.add('Maintain positive momentum and build on success');
        break;
      case MomentumType.strongNegative:
        recommendations.add('Urgent action needed to reverse negative momentum');
        break;
      case MomentumType.negative:
        recommendations.add('Take immediate action to reverse negative momentum');
        break;
      case MomentumType.weakPositive:
        recommendations.add('Focus on accelerating positive momentum');
        break;
      case MomentumType.weakNegative:
        recommendations.add('Address declining momentum before it accelerates');
        break;
      case MomentumType.neutral:
        recommendations.add('Focus on creating positive momentum');
        break;
    }
    
    return recommendations;
  }

  /// Calculate projected performance
  ProjectedPerformance? _calculateProjectedPerformance(
    List<NPSMonthlyReport> reports,
    double velocity,
    double acceleration,
  ) {
    if (reports.isEmpty) return null;
    
    final latestScore = reports.last.allTimeNpsPercentage ?? 0.0;
    final currentMonth = reports.last.reportMonth;
    final currentYear = reports.last.reportYear;
    
    // Project 3 months ahead
    final projected3Month = latestScore + (velocity * 3) + (acceleration * 4.5);
    
    // Project 6 months ahead
    final projected6Month = latestScore + (velocity * 6) + (acceleration * 18);
    
    // Calculate next month date
    int nextMonth = currentMonth + 1;
    int nextYear = currentYear;
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear++;
    }
    
    return ProjectedPerformance(
      nextMonth: nextMonth,
      nextYear: nextYear,
      projected3Month: projected3Month.clamp(0.0, 100.0),
      projected6Month: projected6Month.clamp(0.0, 100.0),
      confidence: _calculateProjectionConfidence(velocity, acceleration),
    );
  }

  /// Calculate projection confidence
  double _calculateProjectionConfidence(double velocity, double acceleration) {
    // Higher confidence for stable trends, lower for volatile ones
    final velocityStability = (1.0 - (velocity.abs() / 10.0)).clamp(0.0, 1.0);
    final accelerationStability = (1.0 - (acceleration.abs() / 5.0)).clamp(0.0, 1.0);
    
    return ((velocityStability + accelerationStability) / 2.0 * 100).clamp(0.0, 100.0);
  }

  /// Calculate trend sustainability
  double _calculateTrendSustainability(
    double strength,
    double reliability,
    double volatility,
    int persistence,
  ) {
    // Factors that indicate sustainability
    final strengthFactor = strength / 100.0;
    final reliabilityFactor = reliability / 100.0;
    final volatilityFactor = (1.0 - (volatility / 10.0)).clamp(0.0, 1.0);
    final persistenceFactor = (persistence / 12.0).clamp(0.0, 1.0);
    
    final sustainability = (strengthFactor * 0.3) +
                         (reliabilityFactor * 0.3) +
                         (volatilityFactor * 0.2) +
                         (persistenceFactor * 0.2);
    
    return (sustainability * 100).clamp(0.0, 100.0);
  }
}

/// Advanced trend analysis result
class AdvancedTrendAnalysis {
  final String serverId;
  final String serverName;
  final TrendDirection trendDirection;
  final double trendStrength;
  final double trendVelocity;
  final double trendAcceleration;
  final double trendReliability;
  final int trendPersistence;
  final double volatility;
  final MomentumType momentum;
  final int peerRanking;
  final BenchmarkComparison benchmarkComparison;
  final double trendConfidence;
  final List<String> trendInsights;
  final List<String> trendRecommendations;
  final ProjectedPerformance? projectedPerformance;
  final double trendSustainability;

  AdvancedTrendAnalysis({
    required this.serverId,
    required this.serverName,
    required this.trendDirection,
    required this.trendStrength,
    required this.trendVelocity,
    required this.trendAcceleration,
    required this.trendReliability,
    required this.trendPersistence,
    required this.volatility,
    required this.momentum,
    required this.peerRanking,
    required this.benchmarkComparison,
    required this.trendConfidence,
    required this.trendInsights,
    required this.trendRecommendations,
    required this.projectedPerformance,
    required this.trendSustainability,
  });
}

/// Trend direction enumeration
enum TrendDirection {
  stronglyImproving,
  improving,
  stable,
  declining,
  stronglyDeclining,
  unknown;

  String get displayName {
    switch (this) {
      case TrendDirection.stronglyImproving:
        return 'Strongly Improving';
      case TrendDirection.improving:
        return 'Improving';
      case TrendDirection.stable:
        return 'Stable';
      case TrendDirection.declining:
        return 'Declining';
      case TrendDirection.stronglyDeclining:
        return 'Strongly Declining';
      case TrendDirection.unknown:
        return 'Unknown';
    }
  }

  String get emoji {
    switch (this) {
      case TrendDirection.stronglyImproving:
        return '🚀';
      case TrendDirection.improving:
        return '📈';
      case TrendDirection.stable:
        return '➡️';
      case TrendDirection.declining:
        return '📉';
      case TrendDirection.stronglyDeclining:
        return '📉';
      case TrendDirection.unknown:
        return '❓';
    }
  }
}

/// Momentum type enumeration
enum MomentumType {
  strongPositive,
  positive,
  weakPositive,
  neutral,
  weakNegative,
  negative,
  strongNegative;

  String get displayName {
    switch (this) {
      case MomentumType.strongPositive:
        return 'Strong Positive';
      case MomentumType.positive:
        return 'Positive';
      case MomentumType.weakPositive:
        return 'Weak Positive';
      case MomentumType.neutral:
        return 'Neutral';
      case MomentumType.weakNegative:
        return 'Weak Negative';
      case MomentumType.negative:
        return 'Negative';
      case MomentumType.strongNegative:
        return 'Strong Negative';
    }
  }

  String get emoji {
    switch (this) {
      case MomentumType.strongPositive:
        return '🚀';
      case MomentumType.positive:
        return '📈';
      case MomentumType.weakPositive:
        return '↗️';
      case MomentumType.neutral:
        return '➡️';
      case MomentumType.weakNegative:
        return '↘️';
      case MomentumType.negative:
        return '📉';
      case MomentumType.strongNegative:
        return '📉';
    }
  }
}

/// Benchmark comparison enumeration
enum BenchmarkComparison {
  exceedsBenchmark,
  meetsBenchmark,
  approachingBenchmark,
  belowBenchmark,
  wellBelowBenchmark,
  unknown;

  String get displayName {
    switch (this) {
      case BenchmarkComparison.exceedsBenchmark:
        return 'Exceeds Benchmark';
      case BenchmarkComparison.meetsBenchmark:
        return 'Meets Benchmark';
      case BenchmarkComparison.approachingBenchmark:
        return 'Approaching Benchmark';
      case BenchmarkComparison.belowBenchmark:
        return 'Below Benchmark';
      case BenchmarkComparison.wellBelowBenchmark:
        return 'Well Below Benchmark';
      case BenchmarkComparison.unknown:
        return 'Unknown';
    }
  }
}

/// Projected performance data
class ProjectedPerformance {
  final int nextMonth;
  final int nextYear;
  final double projected3Month;
  final double projected6Month;
  final double confidence;

  ProjectedPerformance({
    required this.nextMonth,
    required this.nextYear,
    required this.projected3Month,
    required this.projected6Month,
    required this.confidence,
  });
}
