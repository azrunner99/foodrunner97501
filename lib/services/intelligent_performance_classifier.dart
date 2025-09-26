import '../models/monthly_report.dart';
import '../models/historical_nps_data.dart' hide PerformanceClassification;
import '../models/performance_models.dart';
import '../utils/log.dart';
import 'dart:math' as math;

/// Intelligent Performance Classification Service
/// Phase 2: Smart performance tiers and multi-dimensional scoring
class IntelligentPerformanceClassifier {
  static final IntelligentPerformanceClassifier _instance = IntelligentPerformanceClassifier._internal();
  factory IntelligentPerformanceClassifier() => _instance;
  IntelligentPerformanceClassifier._internal();

  /// Performance tier thresholds
  static const Map<IntelligentPerformanceTier, double> _tierThresholds = {
    IntelligentPerformanceTier.elite: 90.0,
    IntelligentPerformanceTier.strong: 80.0,
    IntelligentPerformanceTier.developing: 60.0,
    IntelligentPerformanceTier.concerning: 40.0,
    IntelligentPerformanceTier.critical: 0.0,
  };

  /// Weighting configuration for multi-dimensional scoring
  static const Map<String, double> _scoringWeights = {
    'recent_performance': 0.30,    // 30% - Most recent performance
    'historical_consistency': 0.25, // 25% - How consistent over time
    'improvement_trend': 0.20,     // 20% - Rate of improvement/decline
    'data_quality': 0.15,          // 15% - Reliability of data
    'tenure_consideration': 0.10,  // 10% - Experience level factor
  };

  /// Classify server performance based on comprehensive analysis
  PerformanceClassification classifyServerPerformance({
    required List<NPSMonthlyReport> monthlyReports,
    required String serverName,
    required int serverId,
    int? tenureMonths,
  }) {
    try {
      d('[IntelligentPerformanceClassifier] Classifying performance for server: $serverName');

      if (monthlyReports.isEmpty) {
        return PerformanceClassification(
          tier: IntelligentPerformanceTier.unknown,
          score: 0.0,
          confidence: 0.0,
          reasoning: 'No data available for classification',
          recommendations: ['Enter monthly NPS data to enable performance classification'],
        );
      }

      // Get the most recent report for all-time performance
      final mostRecentReport = _getMostRecentReport(monthlyReports);
      final allTimeNPS = mostRecentReport.allTimeNpsPercentage ?? 0.0;

      // Calculate multi-dimensional score
      final multiDimensionalScore = _calculateMultiDimensionalScore(
        monthlyReports: monthlyReports,
        serverName: serverName,
        tenureMonths: tenureMonths,
      );

      // Determine performance tier
      final tier = _determinePerformanceTier(multiDimensionalScore, allTimeNPS);

      // Calculate confidence level
      final confidence = _calculateConfidenceLevel(monthlyReports, multiDimensionalScore);

      // Generate reasoning and recommendations
      final reasoning = _generateReasoning(
        tier: tier,
        allTimeNPS: allTimeNPS,
        multiDimensionalScore: multiDimensionalScore,
        reports: monthlyReports,
      );

      final recommendations = _generateRecommendations(
        tier: tier,
        allTimeNPS: allTimeNPS,
        multiDimensionalScore: multiDimensionalScore,
        reports: monthlyReports,
      );

      d('[IntelligentPerformanceClassifier] Classification result: $tier (${multiDimensionalScore.toStringAsFixed(1)}%)');

      return PerformanceClassification(
        tier: tier,
        score: multiDimensionalScore,
        confidence: confidence,
        reasoning: reasoning,
        recommendations: recommendations,
      );
    } catch (e) {
      d('[IntelligentPerformanceClassifier] Error classifying performance: $e');
      return PerformanceClassification(
        tier: IntelligentPerformanceTier.unknown,
        score: 0.0,
        confidence: 0.0,
        reasoning: 'Error occurred during classification',
        recommendations: ['Contact support if this issue persists'],
      );
    }
  }

  /// Calculate multi-dimensional performance score
  double _calculateMultiDimensionalScore({
    required List<NPSMonthlyReport> monthlyReports,
    required String serverName,
    int? tenureMonths,
  }) {
    // 1. Recent Performance (30%)
    final recentPerformance = _calculateRecentPerformance(monthlyReports);
    
    // 2. Historical Consistency (25%)
    final historicalConsistency = _calculateHistoricalConsistency(monthlyReports);
    
    // 3. Improvement Trend (20%)
    final improvementTrend = _calculateImprovementTrend(monthlyReports);
    
    // 4. Data Quality (15%)
    final dataQuality = _calculateDataQuality(monthlyReports);
    
    // 5. Tenure Consideration (10%)
    final tenureConsideration = _calculateTenureConsideration(tenureMonths, monthlyReports);

    // Calculate weighted score
    final weightedScore = 
        (recentPerformance * _scoringWeights['recent_performance']!) +
        (historicalConsistency * _scoringWeights['historical_consistency']!) +
        (improvementTrend * _scoringWeights['improvement_trend']!) +
        (dataQuality * _scoringWeights['data_quality']!) +
        (tenureConsideration * _scoringWeights['tenure_consideration']!);

    d('[IntelligentPerformanceClassifier] Score breakdown for $serverName:');
    d('  Recent Performance: ${recentPerformance.toStringAsFixed(1)}% (${(_scoringWeights['recent_performance']! * 100).toInt()}%)');
    d('  Historical Consistency: ${historicalConsistency.toStringAsFixed(1)}% (${(_scoringWeights['historical_consistency']! * 100).toInt()}%)');
    d('  Improvement Trend: ${improvementTrend.toStringAsFixed(1)}% (${(_scoringWeights['improvement_trend']! * 100).toInt()}%)');
    d('  Data Quality: ${dataQuality.toStringAsFixed(1)}% (${(_scoringWeights['data_quality']! * 100).toInt()}%)');
    d('  Tenure Consideration: ${tenureConsideration.toStringAsFixed(1)}% (${(_scoringWeights['tenure_consideration']! * 100).toInt()}%)');
    d('  Final Weighted Score: ${weightedScore.toStringAsFixed(1)}%');

    return weightedScore.clamp(0.0, 100.0);
  }

  /// Calculate recent performance score (last 3 months)
  double _calculateRecentPerformance(List<NPSMonthlyReport> reports) {
    if (reports.isEmpty) return 0.0;

    // Sort by date (most recent first)
    final sortedReports = List<NPSMonthlyReport>.from(reports)
      ..sort((a, b) {
        if (a.reportYear != b.reportYear) return b.reportYear.compareTo(a.reportYear);
        return b.reportMonth.compareTo(a.reportMonth);
      });

    // Take last 3 months or all available
    final recentReports = sortedReports.take(3).toList();
    
    // Calculate weighted average (more recent = higher weight)
    double weightedSum = 0.0;
    double totalWeight = 0.0;
    
    for (int i = 0; i < recentReports.length; i++) {
      final weight = recentReports.length - i; // Most recent gets highest weight
      final nps = recentReports[i].oneMonthNpsPercentage ?? 0.0;
      weightedSum += nps * weight;
      totalWeight += weight;
    }

    return totalWeight > 0 ? weightedSum / totalWeight : 0.0;
  }

  /// Calculate historical consistency (how stable performance is over time)
  double _calculateHistoricalConsistency(List<NPSMonthlyReport> reports) {
    if (reports.length < 2) return 50.0; // Neutral score for insufficient data

    final npsScores = reports
        .map((r) => r.allTimeNpsPercentage ?? 0.0)
        .where((score) => score > 0)
        .toList();

    if (npsScores.length < 2) return 50.0;

    // Calculate coefficient of variation (lower = more consistent)
    final mean = npsScores.reduce((a, b) => a + b) / npsScores.length;
    final variance = npsScores.map((score) => (score - mean) * (score - mean)).reduce((a, b) => a + b) / npsScores.length;
    final standardDeviation = math.sqrt(variance);
    final coefficientOfVariation = mean > 0 ? standardDeviation / mean : 1.0;

    // Convert to 0-100 scale (lower variation = higher consistency score)
    final consistencyScore = (1.0 - coefficientOfVariation.clamp(0.0, 1.0)) * 100.0;
    return consistencyScore.clamp(0.0, 100.0);
  }

  /// Calculate improvement trend (rate of change over time)
  double _calculateImprovementTrend(List<NPSMonthlyReport> reports) {
    if (reports.length < 2) return 50.0; // Neutral score for insufficient data

    // Sort by date
    final sortedReports = List<NPSMonthlyReport>.from(reports)
      ..sort((a, b) {
        if (a.reportYear != b.reportYear) return a.reportYear.compareTo(b.reportYear);
        return a.reportMonth.compareTo(b.reportMonth);
      });

    // Calculate trend using linear regression
    final npsScores = sortedReports
        .map((r) => r.allTimeNpsPercentage ?? 0.0)
        .where((score) => score > 0)
        .toList();

    if (npsScores.length < 2) return 50.0;

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
    
    // Convert slope to 0-100 scale
    // Positive slope = improvement, negative slope = decline
    final trendScore = 50.0 + (slope * 2.0); // Scale factor of 2
    return trendScore.clamp(0.0, 100.0);
  }

  /// Calculate data quality score
  double _calculateDataQuality(List<NPSMonthlyReport> reports) {
    if (reports.isEmpty) return 0.0;

    double qualityScore = 0.0;
    int factors = 0;

    // Factor 1: Data completeness
    final completeReports = reports.where((r) => 
      r.allTimeNpsPercentage != null && 
      r.allTimeNpsPercentage! > 0
    ).length;
    final completenessScore = (completeReports / reports.length) * 100.0;
    qualityScore += completenessScore;
    factors++;

    // Factor 2: Data recency (more recent data = higher quality)
    final mostRecent = _getMostRecentReport(reports);
    final daysSinceLastReport = DateTime.now().difference(mostRecent.dataAsOfDate).inDays;
    final recencyScore = (30 - daysSinceLastReport).clamp(0, 30) * (100.0 / 30.0);
    qualityScore += recencyScore;
    factors++;

    // Factor 3: Data consistency (no extreme outliers)
    final npsScores = reports
        .map((r) => r.allTimeNpsPercentage ?? 0.0)
        .where((score) => score > 0)
        .toList();
    
    if (npsScores.isNotEmpty) {
      final mean = npsScores.reduce((a, b) => a + b) / npsScores.length;
      final outliers = npsScores.where((score) => (score - mean).abs() > mean * 0.5).length;
      final consistencyScore = ((npsScores.length - outliers) / npsScores.length) * 100.0;
      qualityScore += consistencyScore;
      factors++;
    }

    return factors > 0 ? qualityScore / factors : 0.0;
  }

  /// Calculate tenure consideration score
  double _calculateTenureConsideration(int? tenureMonths, List<NPSMonthlyReport> reports) {
    if (tenureMonths == null) {
      // Estimate tenure from data
      if (reports.isEmpty) return 50.0;
      
      final oldestReport = reports.reduce((a, b) {
        if (a.reportYear != b.reportYear) return a.reportYear < b.reportYear ? a : b;
        return a.reportMonth < b.reportMonth ? a : b;
      });
      
      final monthsSinceFirst = (DateTime.now().year - oldestReport.reportYear) * 12 + 
                              (DateTime.now().month - oldestReport.reportMonth);
      tenureMonths = monthsSinceFirst.clamp(1, 120); // Cap at 10 years
    }

    // Score based on tenure (newer employees get benefit of doubt)
    if (tenureMonths < 3) return 60.0; // New employee - neutral to positive
    if (tenureMonths < 6) return 70.0; // Learning period - slightly positive
    if (tenureMonths < 12) return 80.0; // Established - good
    if (tenureMonths < 24) return 90.0; // Experienced - very good
    return 100.0; // Veteran - excellent
  }

  /// Determine performance tier based on score and all-time NPS
  IntelligentPerformanceTier _determinePerformanceTier(double multiDimensionalScore, double allTimeNPS) {
    // Use the higher of multi-dimensional score or all-time NPS for tier determination
    final effectiveScore = [multiDimensionalScore, allTimeNPS].reduce((a, b) => a > b ? a : b);

    if (effectiveScore >= _tierThresholds[IntelligentPerformanceTier.elite]!) {
      return IntelligentPerformanceTier.elite;
    } else if (effectiveScore >= _tierThresholds[IntelligentPerformanceTier.strong]!) {
      return IntelligentPerformanceTier.strong;
    } else if (effectiveScore >= _tierThresholds[IntelligentPerformanceTier.developing]!) {
      return IntelligentPerformanceTier.developing;
    } else if (effectiveScore >= _tierThresholds[IntelligentPerformanceTier.concerning]!) {
      return IntelligentPerformanceTier.concerning;
    } else {
      return IntelligentPerformanceTier.critical;
    }
  }

  /// Calculate confidence level in the classification
  double _calculateConfidenceLevel(List<NPSMonthlyReport> reports, double score) {
    double confidence = 0.0;
    int factors = 0;

    // Factor 1: Amount of data
    final dataAmountScore = (reports.length * 20.0).clamp(0.0, 100.0);
    confidence += dataAmountScore;
    factors++;

    // Factor 2: Data quality
    final qualityScore = _calculateDataQuality(reports);
    confidence += qualityScore;
    factors++;

    // Factor 3: Score clarity (distance from tier boundaries)
    final tierBoundaries = [90.0, 80.0, 60.0, 40.0, 0.0];
    double minDistance = 100.0;
    for (final boundary in tierBoundaries) {
      final distance = (score - boundary).abs();
      if (distance < minDistance) minDistance = distance;
    }
    final clarityScore = (minDistance * 2.0).clamp(0.0, 100.0);
    confidence += clarityScore;
    factors++;

    return factors > 0 ? confidence / factors : 0.0;
  }

  /// Generate reasoning for the classification
  String _generateReasoning({
    required IntelligentPerformanceTier tier,
    required double allTimeNPS,
    required double multiDimensionalScore,
    required List<NPSMonthlyReport> reports,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('Performance Classification: ${tier.displayName}');
    buffer.writeln('');
    buffer.writeln('All-time NPS: ${allTimeNPS.toStringAsFixed(1)}%');
    buffer.writeln('Multi-dimensional Score: ${multiDimensionalScore.toStringAsFixed(1)}%');
    buffer.writeln('Data Points: ${reports.length} monthly reports');
    buffer.writeln('');
    
    // Add specific reasoning based on tier
    switch (tier) {
      case IntelligentPerformanceTier.elite:
        buffer.writeln('This server demonstrates exceptional performance with consistently high NPS scores and strong historical data.');
        break;
      case IntelligentPerformanceTier.strong:
        buffer.writeln('This server shows reliable performance with good NPS scores and consistent historical data.');
        break;
      case IntelligentPerformanceTier.developing:
        buffer.writeln('This server shows potential with moderate performance. Focus on improvement areas for growth.');
        break;
      case IntelligentPerformanceTier.concerning:
        buffer.writeln('This server shows performance issues that need attention. Consider additional training or support.');
        break;
      case IntelligentPerformanceTier.critical:
        buffer.writeln('This server requires immediate attention due to consistently low performance scores.');
        break;
      case IntelligentPerformanceTier.unknown:
        buffer.writeln('Insufficient data available for accurate performance classification.');
        break;
    }

    return buffer.toString();
  }

  /// Generate recommendations based on classification
  List<String> _generateRecommendations({
    required IntelligentPerformanceTier tier,
    required double allTimeNPS,
    required double multiDimensionalScore,
    required List<NPSMonthlyReport> reports,
  }) {
    final recommendations = <String>[];

    switch (tier) {
      case IntelligentPerformanceTier.elite:
        recommendations.addAll([
          'Continue current practices - this server is performing excellently',
          'Consider this server as a mentor for other team members',
          'Recognize and reward this outstanding performance',
        ]);
        break;
      case IntelligentPerformanceTier.strong:
        recommendations.addAll([
          'Maintain current performance level',
          'Identify specific strengths to leverage',
          'Look for opportunities to reach elite level',
        ]);
        break;
      case IntelligentPerformanceTier.developing:
        recommendations.addAll([
          'Provide targeted training in identified weak areas',
          'Set specific performance goals and track progress',
          'Consider pairing with a strong performer for mentoring',
        ]);
        break;
      case IntelligentPerformanceTier.concerning:
        recommendations.addAll([
          'Schedule one-on-one meeting to discuss performance',
          'Develop improvement plan with specific milestones',
          'Provide additional support and resources',
          'Monitor progress closely over next 30 days',
        ]);
        break;
      case IntelligentPerformanceTier.critical:
        recommendations.addAll([
          'Immediate intervention required',
          'Develop comprehensive improvement plan',
          'Consider additional training or role adjustment',
          'Set up regular check-ins and progress reviews',
        ]);
        break;
      case IntelligentPerformanceTier.unknown:
        recommendations.addAll([
          'Enter more monthly NPS data for accurate assessment',
          'Ensure data quality and completeness',
          'Contact support if data issues persist',
        ]);
        break;
    }

    return recommendations;
  }

  /// Get the most recent report from a list
  NPSMonthlyReport _getMostRecentReport(List<NPSMonthlyReport> reports) {
    return reports.reduce((a, b) {
      if (a.reportYear != b.reportYear) return a.reportYear > b.reportYear ? a : b;
      return a.reportMonth > b.reportMonth ? a : b;
    });
  }
}
