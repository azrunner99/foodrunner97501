import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models.dart';

/// Comprehensive server integrity analysis and risk assessment
class IntegrityAnalyzer {
  static const double RISK_THRESHOLD_YELLOW = 30.0;
  static const double RISK_THRESHOLD_ORANGE = 60.0;
  static const double RISK_THRESHOLD_RED = 80.0;
  
  // Click rate thresholds (clicks per minute)
  static const int SUSPICIOUS_CLICK_RATE = 8;
  static const int EXTREME_CLICK_RATE = 15;
  
  // Session analysis thresholds
  static const Duration SUSPICIOUS_SESSION_LENGTH = Duration(minutes: 45);
  static const Duration EXTREME_SESSION_LENGTH = Duration(hours: 2);

  /// Calculate comprehensive risk score for a server
  static IntegrityAssessment analyzeServer({
    required String serverId,
    required String serverName,
    required Map<String, int> clickBins,
    required int totalRuns,
    required List<Server> allServers,
    required Map<String, int> allServerCounts,
    required DateTime analysisTime,
  }) {
    double riskScore = 0.0;
    List<String> riskFactors = [];
    List<Alert> alerts = [];

    // 1. TEMPORAL ANOMALY ANALYSIS (25% weight)
    final temporalScore = _analyzeTemporalPatterns(clickBins, riskFactors);
    riskScore += temporalScore * 0.25;

    // 2. VOLUME ANOMALY ANALYSIS (30% weight)
    final volumeScore = _analyzeVolumeAnomalies(
      clickBins, totalRuns, allServerCounts.values.toList(), riskFactors
    );
    riskScore += volumeScore * 0.30;

    // 3. PATTERN IRREGULARITY ANALYSIS (25% weight)
    final patternScore = _analyzePatternIrregularities(clickBins, riskFactors);
    riskScore += patternScore * 0.25;

    // 4. PEER COMPARISON ANALYSIS (20% weight)
    final peerScore = _analyzePeerComparison(
      totalRuns, allServerCounts, serverId, riskFactors
    );
    riskScore += peerScore * 0.20;

    // Generate alerts based on findings
    alerts.addAll(_generateAlerts(serverId, serverName, clickBins, totalRuns, riskScore));

    return IntegrityAssessment(
      serverId: serverId,
      serverName: serverName,
      riskScore: riskScore.clamp(0.0, 100.0),
      riskLevel: _getRiskLevel(riskScore),
      riskFactors: riskFactors,
      alerts: alerts,
      analysisTime: analysisTime,
      clickData: ClickAnalysisData.fromBins(clickBins, totalRuns),
    );
  }

  /// Analyze temporal patterns for suspicious activity
  static double _analyzeTemporalPatterns(
    Map<String, int> clickBins, 
    List<String> riskFactors
  ) {
    double score = 0.0;
    
    // Check for excessive rapid clicking
    final doubles = clickBins['2'] ?? 0;
    final triples = clickBins['3'] ?? 0;
    final quads = clickBins['4+'] ?? 0;
    
    if (quads > 0) {
      score += 40.0;
      riskFactors.add('4+ clicks per minute detected ($quads instances)');
    }
    
    if (triples > 2) {
      score += 25.0;
      riskFactors.add('Excessive triple-clicks ($triples instances)');
    }
    
    if (doubles > 10) {
      score += 15.0;
      riskFactors.add('High double-click frequency ($doubles instances)');
    }

    return score.clamp(0.0, 100.0);
  }

  /// Analyze volume anomalies compared to expectations
  static double _analyzeVolumeAnomalies(
    Map<String, int> clickBins,
    int totalRuns,
    List<int> allRunCounts,
    List<String> riskFactors
  ) {
    double score = 0.0;
    
    if (allRunCounts.isNotEmpty) {
      // Calculate statistics for peer comparison
      allRunCounts.sort();
      final median = allRunCounts[allRunCounts.length ~/ 2];
      final average = allRunCounts.reduce((a, b) => a + b) / allRunCounts.length;
      final top10Percent = allRunCounts[(allRunCounts.length * 0.9).floor()];
      
      // Check if significantly above average
      if (totalRuns > average * 2.5) {
        score += 35.0;
        riskFactors.add('Runs significantly above average (${totalRuns} vs ${average.toStringAsFixed(1)})');
      } else if (totalRuns > average * 1.8) {
        score += 20.0;
        riskFactors.add('Runs well above average (${totalRuns} vs ${average.toStringAsFixed(1)})');
      }

      // Check if in extreme top percentile
      if (totalRuns >= top10Percent && totalRuns > median * 2) {
        score += 25.0;
        riskFactors.add('Performance in top 10% with extreme variance');
      }
    }

    return score.clamp(0.0, 100.0);
  }

  /// Analyze pattern irregularities suggesting automation
  static double _analyzePatternIrregularities(
    Map<String, int> clickBins,
    List<String> riskFactors
  ) {
    double score = 0.0;
    
    final totalClickMinutes = (clickBins['1'] ?? 0) + 
                             (clickBins['2'] ?? 0) + 
                             (clickBins['3'] ?? 0) + 
                             (clickBins['4+'] ?? 0);
    
    if (totalClickMinutes == 0) return 0.0;
    
    // Check for mechanical patterns
    final rapidClickMinutes = (clickBins['2'] ?? 0) + 
                             (clickBins['3'] ?? 0) + 
                             (clickBins['4+'] ?? 0);
    
    final rapidClickRatio = rapidClickMinutes / totalClickMinutes;
    
    if (rapidClickRatio > 0.4) {
      score += 30.0;
      riskFactors.add('High ratio of rapid-click minutes (${(rapidClickRatio * 100).toStringAsFixed(1)}%)');
    } else if (rapidClickRatio > 0.2) {
      score += 15.0;
      riskFactors.add('Elevated rapid-click frequency');
    }

    return score.clamp(0.0, 100.0);
  }

  /// Compare performance against peers
  static double _analyzePeerComparison(
    int totalRuns,
    Map<String, int> allServerCounts,
    String serverId,
    List<String> riskFactors
  ) {
    double score = 0.0;
    
    final otherCounts = allServerCounts.entries
        .where((e) => e.key != serverId)
        .map((e) => e.value)
        .toList();
    
    if (otherCounts.isEmpty) return 0.0;
    
    otherCounts.sort();
    final q3 = otherCounts[(otherCounts.length * 0.75).floor()];
    final max = otherCounts.last;
    
    // Standard deviation calculation
    final mean = otherCounts.reduce((a, b) => a + b) / otherCounts.length;
    final variance = otherCounts
        .map((x) => (x - mean) * (x - mean))
        .reduce((a, b) => a + b) / otherCounts.length;
    final stdDev = math.sqrt(variance);
    
    // Check for extreme outliers
    if (totalRuns > mean + (3 * stdDev)) {
      score += 40.0;
      riskFactors.add('Extreme statistical outlier (>3 standard deviations)');
    } else if (totalRuns > mean + (2 * stdDev)) {
      score += 25.0;
      riskFactors.add('Statistical outlier (>2 standard deviations)');
    }
    
    // Check percentile ranking
    if (totalRuns > max * 0.95 && totalRuns > q3 * 1.5) {
      score += 20.0;
      riskFactors.add('Top performer with suspicious margin');
    }

    return score.clamp(0.0, 100.0);
  }

  /// Generate specific alerts based on analysis
  static List<Alert> _generateAlerts(
    String serverId,
    String serverName,
    Map<String, int> clickBins,
    int totalRuns,
    double riskScore
  ) {
    List<Alert> alerts = [];
    
    // Critical alerts
    if ((clickBins['4+'] ?? 0) > 0) {
      alerts.add(Alert(
        level: AlertLevel.critical,
        title: 'Extreme Click Rate Detected',
        message: '$serverName recorded ${clickBins['4+']} minutes with 4+ clicks per minute',
        serverId: serverId,
        timestamp: DateTime.now(),
      ));
    }
    
    // High alerts
    if ((clickBins['3'] ?? 0) > 3) {
      alerts.add(Alert(
        level: AlertLevel.high,
        title: 'Multiple Triple-Click Events',
        message: '$serverName had ${clickBins['3']} minutes with 3 clicks per minute',
        serverId: serverId,
        timestamp: DateTime.now(),
      ));
    }
    
    // Medium alerts
    if (riskScore > RISK_THRESHOLD_ORANGE) {
      alerts.add(Alert(
        level: AlertLevel.medium,
        title: 'Elevated Risk Score',
        message: '$serverName has a risk score of ${riskScore.toStringAsFixed(1)}',
        serverId: serverId,
        timestamp: DateTime.now(),
      ));
    }
    
    return alerts;
  }

  /// Determine risk level from score
  static RiskLevel _getRiskLevel(double score) {
    if (score >= RISK_THRESHOLD_RED) return RiskLevel.red;
    if (score >= RISK_THRESHOLD_ORANGE) return RiskLevel.orange;
    if (score >= RISK_THRESHOLD_YELLOW) return RiskLevel.yellow;
    return RiskLevel.green;
  }
}

/// Risk assessment result for a server
class IntegrityAssessment {
  final String serverId;
  final String serverName;
  final double riskScore;
  final RiskLevel riskLevel;
  final List<String> riskFactors;
  final List<Alert> alerts;
  final DateTime analysisTime;
  final ClickAnalysisData clickData;

  const IntegrityAssessment({
    required this.serverId,
    required this.serverName,
    required this.riskScore,
    required this.riskLevel,
    required this.riskFactors,
    required this.alerts,
    required this.analysisTime,
    required this.clickData,
  });

  Color get riskColor {
    switch (riskLevel) {
      case RiskLevel.green:
        return Colors.green;
      case RiskLevel.yellow:
        return Colors.orange;
      case RiskLevel.orange:
        return Colors.deepOrange;
      case RiskLevel.red:
        return Colors.red;
    }
  }

  String get riskDescription {
    switch (riskLevel) {
      case RiskLevel.green:
        return 'Normal';
      case RiskLevel.yellow:
        return 'Minor Concerns';
      case RiskLevel.orange:
        return 'Significant Issues';
      case RiskLevel.red:
        return 'High Risk';
    }
  }
}

/// Click analysis data
class ClickAnalysisData {
  final int totalClickMinutes;
  final int singleClickMinutes;
  final int doubleClickMinutes;
  final int tripleClickMinutes;
  final int quadPlusClickMinutes;
  final int totalRuns;

  const ClickAnalysisData({
    required this.totalClickMinutes,
    required this.singleClickMinutes,
    required this.doubleClickMinutes,
    required this.tripleClickMinutes,
    required this.quadPlusClickMinutes,
    required this.totalRuns,
  });

  factory ClickAnalysisData.fromBins(Map<String, int> bins, int runs) {
    final singles = bins['1'] ?? 0;
    final doubles = bins['2'] ?? 0;
    final triples = bins['3'] ?? 0;
    final quads = bins['4+'] ?? 0;
    
    return ClickAnalysisData(
      totalClickMinutes: singles + doubles + triples + quads,
      singleClickMinutes: singles,
      doubleClickMinutes: doubles,
      tripleClickMinutes: triples,
      quadPlusClickMinutes: quads,
      totalRuns: runs,
    );
  }

  double get rapidClickRatio {
    if (totalClickMinutes == 0) return 0.0;
    return (doubleClickMinutes + tripleClickMinutes + quadPlusClickMinutes) / totalClickMinutes;
  }
}

/// Alert levels for integrity issues
enum AlertLevel { low, medium, high, critical }

/// Risk levels for servers
enum RiskLevel { green, yellow, orange, red }

/// Individual alert for integrity issues
class Alert {
  final AlertLevel level;
  final String title;
  final String message;
  final String serverId;
  final DateTime timestamp;

  const Alert({
    required this.level,
    required this.title,
    required this.message,
    required this.serverId,
    required this.timestamp,
  });

  Color get color {
    switch (level) {
      case AlertLevel.low:
        return Colors.blue;
      case AlertLevel.medium:
        return Colors.orange;
      case AlertLevel.high:
        return Colors.deepOrange;
      case AlertLevel.critical:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (level) {
      case AlertLevel.low:
        return Icons.info_outline;
      case AlertLevel.medium:
        return Icons.warning_amber_outlined;
      case AlertLevel.high:
        return Icons.error_outline;
      case AlertLevel.critical:
        return Icons.dangerous_outlined;
    }
  }
}
