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
    List<DateTime>?
        individualTimestamps, // NEW: Optional timestamp data for enhanced analysis
  }) {
    double riskScore = 0.0;
    List<String> riskFactors = [];
    List<Alert> alerts = [];

    // 1. TEMPORAL ANOMALY ANALYSIS (20% weight - reduced to make room for timestamp analysis)
    final temporalScore = _analyzeTemporalPatterns(clickBins, riskFactors);
    riskScore += temporalScore * 0.20;

    // 2. VOLUME ANOMALY ANALYSIS (25% weight)
    final volumeScore = _analyzeVolumeAnomalies(
        clickBins, totalRuns, allServerCounts.values.toList(), riskFactors);
    riskScore += volumeScore * 0.25;

    // 3. PATTERN IRREGULARITY ANALYSIS (20% weight)
    final patternScore = _analyzePatternIrregularities(clickBins, riskFactors);
    riskScore += patternScore * 0.20;

    // 4. PEER COMPARISON ANALYSIS (15% weight)
    final peerScore = _analyzePeerComparison(
        totalRuns, allServerCounts, serverId, riskFactors);
    riskScore += peerScore * 0.15;

    // 5. TIMESTAMP-BASED ANALYSIS (20% weight) - NEW ENHANCED ANALYSIS
    if (individualTimestamps != null && individualTimestamps.isNotEmpty) {
      final timestampScore =
          TimestampIntegrityAnalyzer.calculateTimestampRiskScore(
              individualTimestamps);
      riskScore += timestampScore * 0.20;

      // Add timestamp-based risk factors
      final timestampRiskFactors =
          TimestampIntegrityAnalyzer.generateTimestampRiskFactors(
              individualTimestamps);
      riskFactors.addAll(timestampRiskFactors);
    }

    // Generate alerts based on findings (including timestamp alerts)
    alerts.addAll(_generateAlerts(serverId, serverName, clickBins, totalRuns,
        riskScore, individualTimestamps));

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

  /// Advanced server analysis with enhanced pattern recognition
  static EnhancedIntegrityAssessment analyzeServerAdvanced({
    required String serverId,
    required String serverName,
    required Map<String, int> clickBins,
    required int totalRuns,
    required List<Server> allServers,
    required Map<String, int> allServerCounts,
    required DateTime analysisTime,
  }) {
    // Use existing analysis as base
    final baseAssessment = IntegrityAnalyzer.analyzeServer(
      serverId: serverId,
      serverName: serverName,
      clickBins: clickBins,
      totalRuns: totalRuns,
      allServers: allServers,
      allServerCounts: allServerCounts,
      analysisTime: analysisTime,
    );

    // Add advanced pattern detection
    final clusters = AdvancedIntegrityAnalyzer.detectClickClusters(clickBins);
    final mechanicalScore =
        AdvancedIntegrityAnalyzer.detectMechanicalPatterns(clickBins);
    final sessionScore =
        AdvancedIntegrityAnalyzer.analyzeSessionDuration(clickBins);
    final zScore =
        AdvancedIntegrityAnalyzer.calculateZScore(allServerCounts, serverId);

    // Enhanced risk calculation
    double riskScore = baseAssessment.riskScore;
    List<String> riskFactors = List.from(baseAssessment.riskFactors);

    // Add pattern-based risk adjustments
    if (mechanicalScore > 0.7) {
      riskScore += 15.0;
      riskFactors.add('Mechanical clicking pattern detected');
    }

    if (clusters.length > 2) {
      riskScore += clusters.length * 5.0;
      riskFactors.add('Multiple click clusters detected');
    }

    if (sessionScore > 0.7) {
      riskScore += 10.0;
      riskFactors.add('Extended session duration');
    }

    if (zScore > 3.0) {
      riskScore += 20.0;
      riskFactors.add('Extreme statistical outlier');
    }

    // Generate advanced alerts
    final advancedAlerts = AdvancedIntegrityAnalyzer.generateAdvancedAlerts(
        serverId, clickBins, allServerCounts, riskScore);

    final finalScore = math.min(riskScore, 100.0);

    return EnhancedIntegrityAssessment(
      serverId: serverId,
      serverName: serverName,
      riskScore: finalScore,
      riskLevel: _getRiskLevel(finalScore),
      riskFactors: riskFactors,
      alerts: [...baseAssessment.alerts, ...advancedAlerts],
      clickData: baseAssessment.clickData,
      analysisTime: analysisTime,
      clickClusters: clusters,
      mechanicalScore: mechanicalScore,
      sessionDurationScore: sessionScore,
      zScore: zScore,
    );
  }

  /// Analyze temporal patterns for suspicious activity
  static double _analyzeTemporalPatterns(
      Map<String, int> clickBins, List<String> riskFactors) {
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
  static double _analyzeVolumeAnomalies(Map<String, int> clickBins,
      int totalRuns, List<int> allRunCounts, List<String> riskFactors) {
    double score = 0.0;

    if (allRunCounts.isNotEmpty) {
      // Calculate statistics for peer comparison
      allRunCounts.sort();
      final median = allRunCounts[allRunCounts.length ~/ 2];
      final average =
          allRunCounts.reduce((a, b) => a + b) / allRunCounts.length;
      final top10Percent = allRunCounts[(allRunCounts.length * 0.9).floor()];

      // Check if significantly above average
      if (totalRuns > average * 2.5) {
        score += 35.0;
        riskFactors.add(
            'Runs significantly above average ($totalRuns vs ${average.toStringAsFixed(1)})');
      } else if (totalRuns > average * 1.8) {
        score += 20.0;
        riskFactors.add(
            'Runs well above average ($totalRuns vs ${average.toStringAsFixed(1)})');
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
      Map<String, int> clickBins, List<String> riskFactors) {
    double score = 0.0;

    final totalClickMinutes = (clickBins['1'] ?? 0) +
        (clickBins['2'] ?? 0) +
        (clickBins['3'] ?? 0) +
        (clickBins['4+'] ?? 0);

    if (totalClickMinutes == 0) return 0.0;

    // Check for mechanical patterns
    final rapidClickMinutes =
        (clickBins['2'] ?? 0) + (clickBins['3'] ?? 0) + (clickBins['4+'] ?? 0);

    final rapidClickRatio = rapidClickMinutes / totalClickMinutes;

    if (rapidClickRatio > 0.4) {
      score += 30.0;
      riskFactors.add(
          'High ratio of rapid-click minutes (${(rapidClickRatio * 100).toStringAsFixed(1)}%)');
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
      List<String> riskFactors) {
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
            .reduce((a, b) => a + b) /
        otherCounts.length;
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
      double riskScore,
      List<DateTime>? individualTimestamps) {
    List<Alert> alerts = [];

    // Timestamp-based analysis (when available)
    if (individualTimestamps != null && individualTimestamps.isNotEmpty) {
      // Analyze timing patterns
      final velocityRisk =
          TimestampIntegrityAnalyzer.analyzeClickVelocity(individualTimestamps);
      final microBursts =
          TimestampIntegrityAnalyzer.detectMicroBursts(individualTimestamps);
      final mechanicalSignature =
          TimestampIntegrityAnalyzer.analyzeMechanicalConsistency(
              individualTimestamps);
      final proportionalAnalysis =
          TimestampIntegrityAnalyzer.analyzeClickProportions(
              individualTimestamps);

      // Proportional abuse detection (CRITICAL - catches dishonest multi-clicking)
      if (proportionalAnalysis.suspiciousProportions) {
        if (proportionalAnalysis.riskScore > 75.0) {
          alerts.add(Alert(
            level: AlertLevel.critical,
            title: 'Excessive Multi-Click Abuse',
            message:
                '$serverName shows disproportionate multi-clicking: ${proportionalAnalysis.description} (${proportionalAnalysis.riskAssessment})',
            serverId: serverId,
            timestamp: DateTime.now(),
          ));
        } else if (proportionalAnalysis.riskScore > 50.0) {
          alerts.add(Alert(
            level: AlertLevel.high,
            title: 'Suspicious Multi-Click Frequency',
            message:
                '$serverName has abnormal multi-click patterns: ${proportionalAnalysis.description}',
            serverId: serverId,
            timestamp: DateTime.now(),
          ));
        } else {
          alerts.add(Alert(
            level: AlertLevel.medium,
            title: 'Elevated Multi-Click Activity',
            message:
                '$serverName shows higher than normal multi-click frequency: ${proportionalAnalysis.description}',
            serverId: serverId,
            timestamp: DateTime.now(),
          ));
        }
      }

      // Mechanical pattern alerts
      final mechanicalRisk = mechanicalSignature.isMechanical
          ? 95.0
          : mechanicalSignature.isSuspicious
              ? 70.0
              : 20.0;
      if (mechanicalRisk > 80.0) {
        alerts.add(Alert(
          level: AlertLevel.critical,
          title: 'Mechanical Click Pattern Detected',
          message:
              '$serverName shows highly regular timing (CV: ${(mechanicalSignature.coefficientOfVariation * 100).toStringAsFixed(1)}%)',
          serverId: serverId,
          timestamp: DateTime.now(),
        ));
      }

      // Micro-burst alerts with context awareness
      if (microBursts.isNotEmpty) {
        final extremeBursts = microBursts.where((b) => b.isExtreme).length;
        final impossibleSpeedBursts =
            microBursts.where((b) => b.isImpossibleSpeed).length;
        final suspiciousBursts =
            microBursts.where((b) => b.isSuspicious && !b.isExtreme).length;

        // Critical: Impossible speed or 5+ click bursts
        if (impossibleSpeedBursts > 0 || extremeBursts > 1) {
          // Multiple extreme bursts = clear abuse
          alerts.add(Alert(
            level: AlertLevel.critical,
            title: 'Automation/Script Detection',
            message:
                '$serverName shows patterns impossible for human users ($extremeBursts extreme bursts, $impossibleSpeedBursts impossible speeds)',
            serverId: serverId,
            timestamp: DateTime.now(),
          ));
        }
        // High: Repeated 4-click patterns (suspicious but not impossible)
        else if (suspiciousBursts > 3) {
          // Allow some 4-click incidents
          alerts.add(Alert(
            level: AlertLevel.high,
            title: 'Repeated Rapid Click Patterns',
            message:
                '$serverName has $suspiciousBursts instances of 4+ rapid clicks (beyond normal 2-3 item runs)',
            serverId: serverId,
            timestamp: DateTime.now(),
          ));
        }
      }

      // Velocity alerts - only for significant abuse patterns
      if (velocityRisk > 50.0) {
        // Raised threshold since we're more context-aware
        alerts.add(Alert(
          level: AlertLevel.medium,
          title: 'Sustained Abuse Pattern',
          message:
              '$serverName shows repeated patterns exceeding normal 2-3 item runs (${velocityRisk.toStringAsFixed(1)}% pattern risk)',
          serverId: serverId,
          timestamp: DateTime.now(),
        ));
      }
    }

    // Critical alerts
    if ((clickBins['4+'] ?? 0) > 0) {
      alerts.add(Alert(
        level: AlertLevel.critical,
        title: 'Extreme Click Rate Detected',
        message:
            '$serverName recorded ${clickBins['4+']} minutes with 4+ clicks per minute',
        serverId: serverId,
        timestamp: DateTime.now(),
      ));
    }

    // High alerts
    if ((clickBins['3'] ?? 0) > 3) {
      alerts.add(Alert(
        level: AlertLevel.high,
        title: 'Multiple Triple-Click Events',
        message:
            '$serverName had ${clickBins['3']} minutes with 3 clicks per minute',
        serverId: serverId,
        timestamp: DateTime.now(),
      ));
    }

    // Medium alerts
    if (riskScore > RISK_THRESHOLD_ORANGE) {
      alerts.add(Alert(
        level: AlertLevel.medium,
        title: 'Elevated Risk Score',
        message:
            '$serverName has a risk score of ${riskScore.toStringAsFixed(1)}',
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
    return (doubleClickMinutes + tripleClickMinutes + quadPlusClickMinutes) /
        totalClickMinutes;
  }
}

// ============================================================================
// ADVANCED PATTERN RECOGNITION CLASSES AND METHODS (Phase 2)
// ============================================================================

/// Represents a detected click cluster - burst of activity
class ClickCluster {
  final int startIndex;
  final int endIndex;
  final int totalClicks;
  final int duration; // in seconds
  final double intensity; // clicks per minute

  const ClickCluster({
    required this.startIndex,
    required this.endIndex,
    required this.totalClicks,
    required this.duration,
    required this.intensity,
  });
}

/// Enhanced integrity assessment with advanced analytics
class EnhancedIntegrityAssessment extends IntegrityAssessment {
  final List<ClickCluster> clickClusters;
  final double mechanicalScore;
  final double sessionDurationScore;
  final double zScore;

  const EnhancedIntegrityAssessment({
    required super.serverId,
    required super.serverName,
    required super.riskScore,
    required super.riskLevel,
    required super.riskFactors,
    required super.alerts,
    required super.analysisTime,
    required super.clickData,
    required this.clickClusters,
    required this.mechanicalScore,
    required this.sessionDurationScore,
    required this.zScore,
  });

  /// Convert enhanced assessment back to basic assessment for compatibility
  IntegrityAssessment toBasicAssessment() {
    return IntegrityAssessment(
      serverId: serverId,
      serverName: serverName,
      riskScore: riskScore,
      riskLevel: riskLevel,
      riskFactors: riskFactors,
      alerts: alerts,
      analysisTime: analysisTime,
      clickData: clickData,
    );
  }
}

/// Advanced pattern analysis extensions
extension AdvancedIntegrityAnalyzer on IntegrityAnalyzer {
  /// Detect click clustering - bursts of activity in short time windows
  static List<ClickCluster> detectClickClusters(Map<String, int> clickBins) {
    List<ClickCluster> clusters = [];

    // Convert bins to time-ordered list
    final sortedBins = clickBins.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    int clusterStart = 0;
    int clusterTotalClicks = 0;

    for (int i = 0; i < sortedBins.length; i++) {
      final currentBin = sortedBins[i];
      final clickCount = currentBin.value;

      if (clickCount >= 10) {
        // High activity bin
        if (clusterTotalClicks == 0) {
          clusterStart = i;
        }
        clusterTotalClicks += clickCount;
      } else {
        // End of potential cluster
        if (clusterTotalClicks >= 50) {
          // Significant cluster
          final duration = i - clusterStart;
          clusters.add(ClickCluster(
            startIndex: clusterStart,
            endIndex: i - 1,
            totalClicks: clusterTotalClicks,
            duration:
                duration * 60, // Convert to seconds (assuming 1-minute bins)
            intensity: clusterTotalClicks / duration,
          ));
        }
        clusterTotalClicks = 0;
      }
    }

    return clusters;
  }

  /// Analyze clicking rhythm for mechanical patterns
  static double detectMechanicalPatterns(Map<String, int> clickBins) {
    if (clickBins.length < 5) return 0.0;

    final clickCounts = clickBins.values.toList();

    // Calculate coefficient of variation (lower = more mechanical)
    final mean =
        clickCounts.fold(0, (sum, count) => sum + count) / clickCounts.length;
    final variance =
        clickCounts.fold(0.0, (sum, count) => sum + math.pow(count - mean, 2)) /
            clickCounts.length;
    final stdDev = math.sqrt(variance);
    final coeffOfVariation = mean > 0 ? stdDev / mean : 0.0;

    // Mechanical patterns have low variation (high consistency)
    if (coeffOfVariation < 0.3) {
      return 1.0 - coeffOfVariation; // Score inversely related to variation
    }

    return 0.0;
  }

  /// Detect sessions that are unusually long
  static double analyzeSessionDuration(Map<String, int> clickBins) {
    final activeBins = clickBins.values.where((count) => count > 0).length;
    final sessionMinutes = activeBins; // Assuming 1-minute bins

    if (sessionMinutes > 180) {
      // 3+ hours
      return 1.0;
    } else if (sessionMinutes > 120) {
      // 2+ hours
      return 0.7;
    } else if (sessionMinutes > 90) {
      // 1.5+ hours
      return 0.4;
    }

    return 0.0;
  }

  /// Calculate Z-score compared to peer group
  static double calculateZScore(
      Map<String, int> allServerCounts, String serverId) {
    final serverCount = allServerCounts[serverId] ?? 0;
    final otherCounts =
        allServerCounts.values.where((count) => count != serverCount).toList();

    if (otherCounts.isEmpty) return 0.0;

    final mean =
        otherCounts.fold(0, (sum, count) => sum + count) / otherCounts.length;
    final variance =
        otherCounts.fold(0.0, (sum, count) => sum + math.pow(count - mean, 2)) /
            otherCounts.length;
    final stdDev = math.sqrt(variance);

    return stdDev > 0 ? (serverCount - mean) / stdDev : 0.0;
  }

  /// Detect sudden spikes in activity
  static double detectVolumeSpikes(Map<String, int> clickBins) {
    final counts = clickBins.values.toList();
    if (counts.length < 3) return 0.0;

    double maxSpike = 0.0;

    for (int i = 1; i < counts.length - 1; i++) {
      final prev = counts[i - 1];
      final current = counts[i];
      final next = counts[i + 1];

      final avgAdjacent = (prev + next) / 2;
      if (avgAdjacent > 0 && current > avgAdjacent * 3) {
        final spike = current / avgAdjacent;
        maxSpike = math.max(maxSpike, spike - 3.0); // Normalize so 3x = 0
      }
    }

    return math.min(maxSpike / 5.0, 1.0); // Cap at 1.0
  }

  /// Enhanced alert generation with specific pattern detection
  static List<Alert> generateAdvancedAlerts(
      String serverId,
      Map<String, int> clickBins,
      Map<String, int> allServerCounts,
      double riskScore) {
    List<Alert> alerts = [];
    final now = DateTime.now();

    // Click clustering alerts
    final clusters = detectClickClusters(clickBins);
    for (final cluster in clusters) {
      if (cluster.intensity > 20) {
        alerts.add(Alert(
          level: cluster.intensity > 30 ? AlertLevel.high : AlertLevel.medium,
          title: 'Click Clustering Detected',
          message:
              '${cluster.totalClicks} clicks in ${cluster.duration ~/ 60} minutes (${cluster.intensity.toStringAsFixed(1)} clicks/min)',
          serverId: serverId,
          timestamp: now,
        ));
      }
    }

    // Mechanical pattern alerts
    final mechanicalScore = detectMechanicalPatterns(clickBins);
    if (mechanicalScore > 0.7) {
      alerts.add(Alert(
        level: mechanicalScore > 0.9 ? AlertLevel.high : AlertLevel.medium,
        title: 'Mechanical Clicking Pattern',
        message:
            'Highly consistent clicking pattern detected (${(mechanicalScore * 100).toStringAsFixed(0)}% mechanical)',
        serverId: serverId,
        timestamp: now,
      ));
    }

    // Volume spike alerts
    final spikeScore = detectVolumeSpikes(clickBins);
    if (spikeScore > 0.5) {
      alerts.add(Alert(
        level: spikeScore > 0.8 ? AlertLevel.high : AlertLevel.medium,
        title: 'Activity Spike Detected',
        message: 'Sudden spike in clicking activity detected',
        serverId: serverId,
        timestamp: now,
      ));
    }

    // Z-score outlier alerts
    final zScore = calculateZScore(allServerCounts, serverId);
    if (zScore > 3.0) {
      alerts.add(Alert(
        level: zScore > 4.0 ? AlertLevel.critical : AlertLevel.high,
        title: 'Extreme Statistical Outlier',
        message:
            'Performance ${zScore.toStringAsFixed(1)} standard deviations above team average',
        serverId: serverId,
        timestamp: now,
      ));
    }

    // Session duration alerts
    final sessionScore = analyzeSessionDuration(clickBins);
    if (sessionScore > 0.5) {
      alerts.add(Alert(
        level: sessionScore > 0.8 ? AlertLevel.high : AlertLevel.medium,
        title: 'Extended Session Duration',
        message: 'Unusually long continuous clicking session detected',
        serverId: serverId,
        timestamp: now,
      ));
    }

    return alerts;
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

// Enhanced timestamp-based analysis data structures
class MicroBurst {
  final DateTime startTime;
  final int clickCount;
  final int durationMs;
  final double velocity; // clicks per second

  MicroBurst({
    required this.startTime,
    required this.clickCount,
    required this.durationMs,
  }) : velocity = durationMs > 0 ? (clickCount * 1000.0) / durationMs : 0.0;

  // Context-aware detection based on legitimate vs suspicious patterns
  bool get isLegitimate =>
      clickCount <= 3; // 2-3 clicks is normal multi-item run
  bool get isSuspicious =>
      clickCount >= 4 && clickCount < 5; // 4 clicks starts being suspicious
  bool get isExtreme => clickCount >= 5; // 5+ clicks is highly suspicious
  bool get isImpossibleSpeed => velocity > 20.0; // Beyond human capability
}

class TimingSignature {
  final double meanInterval;
  final double stdDeviation;
  final double coefficientOfVariation;
  final List<int> intervals;

  TimingSignature({
    required this.meanInterval,
    required this.stdDeviation,
    required this.coefficientOfVariation,
    required this.intervals,
  });

  bool get isMechanical =>
      coefficientOfVariation < 0.05; // <5% variation is mechanical
  bool get isSuspicious =>
      coefficientOfVariation < 0.10; // <10% variation is suspicious
  bool get isHuman =>
      coefficientOfVariation > 0.15; // >15% variation is typical human
}

class ClickSession {
  final DateTime startTime;
  final DateTime endTime;
  final int clickCount;
  final Duration duration;

  ClickSession({
    required this.startTime,
    required this.endTime,
    required this.clickCount,
  }) : duration = endTime.difference(startTime);

  double get averageClickRate =>
      duration.inSeconds > 0 ? clickCount / duration.inSeconds : 0.0;
  bool get isSuspiciouslyLong => duration > Duration(hours: 2);
  bool get isSuspiciouslyIntense =>
      averageClickRate > 8.0; // >8 clicks/second sustained
}

class ClickEvent {
  final DateTime startTime;
  final int clickCount;

  ClickEvent({
    required this.startTime,
    required this.clickCount,
  });

  bool get isLegitimate =>
      clickCount <= 3; // 1-3 clicks per event is legitimate
  bool get isSuspicious => clickCount >= 4; // 4+ clicks per event is suspicious
}

class ProportionalAnalysis {
  final int singleClickEvents;
  final int multiClickEvents;
  final int totalEvents;
  final double multiClickRatio;
  final double averageClicksPerEvent;
  final bool suspiciousProportions;
  final double riskScore;

  ProportionalAnalysis({
    required this.singleClickEvents,
    required this.multiClickEvents,
    required this.totalEvents,
    required this.multiClickRatio,
    required this.averageClicksPerEvent,
    required this.suspiciousProportions,
    required this.riskScore,
  });

  String get description {
    return '$multiClickEvents/$totalEvents events are multi-click (${(multiClickRatio * 100).toStringAsFixed(1)}%)';
  }

  String get riskAssessment {
    if (riskScore > 75) return 'Extreme abuse pattern';
    if (riskScore > 50) return 'Highly suspicious proportions';
    if (riskScore > 25) return 'Concerning frequency';
    return 'Normal patterns';
  }
}

/// Enhanced integrity analyzer using individual click timestamps
class TimestampIntegrityAnalyzer {
  // Legitimate multi-item run thresholds (2-3 items is normal)
  static const double LEGITIMATE_MULTI_CLICK_VELOCITY =
      5.0; // 2-3 clicks in ~500ms is normal
  static const double SUSPICIOUS_VELOCITY =
      8.0; // 4+ rapid clicks starts being suspicious
  static const double EXTREME_VELOCITY =
      12.0; // 5+ extremely rapid clicks is a red flag

  // Pattern analysis constants
  static const double HUMAN_MIN_VARIATION =
      0.15; // 15% coefficient of variation
  static const double SUSPICIOUS_VARIATION = 0.08; // 8% (tightened from 10%)
  static const double MECHANICAL_VARIATION = 0.04; // 4% (tightened from 5%)

  // Context thresholds for legitimate behavior
  static const int LEGITIMATE_BURST_SIZE = 3; // 2-3 clicks is normal
  static const int SUSPICIOUS_BURST_SIZE =
      4; // 4+ clicks starts being suspicious
  static const int EXTREME_BURST_SIZE = 5; // 5+ clicks is highly suspicious

  /// Analyze click velocity patterns with context for legitimate multi-item runs
  static double analyzeClickVelocity(List<DateTime> timestamps) {
    if (timestamps.length < 4) return 0.0; // Need 4+ clicks to be suspicious

    double maxVelocity = 0.0;
    int suspiciousBurstCount = 0;
    int extremeBurstCount = 0;
    List<double> allVelocities = [];

    // Analyze intervals between consecutive clicks
    for (int i = 1; i < timestamps.length; i++) {
      final intervalMs =
          timestamps[i].difference(timestamps[i - 1]).inMilliseconds;
      if (intervalMs > 0) {
        final velocity = 1000.0 / intervalMs; // clicks per second
        maxVelocity = math.max(maxVelocity, velocity);
        allVelocities.add(velocity);
      }
    }

    // Analyze patterns in context - look for sustained abuse, not isolated multi-item runs
    for (int i = 0; i < allVelocities.length - 2; i++) {
      // Check for sequences of 3+ rapid clicks
      bool isSustainedRapid = true;
      for (int j = i; j < math.min(i + 3, allVelocities.length); j++) {
        if (allVelocities[j] < SUSPICIOUS_VELOCITY) {
          isSustainedRapid = false;
          break;
        }
      }

      if (isSustainedRapid) {
        // Check if it's extreme (5+ clicks) vs just suspicious (4 clicks)
        bool isExtreme = true;
        for (int j = i; j < math.min(i + 4, allVelocities.length); j++) {
          if (allVelocities[j] < EXTREME_VELOCITY) {
            isExtreme = false;
            break;
          }
        }

        if (isExtreme) {
          extremeBurstCount++;
        } else {
          suspiciousBurstCount++;
        }
      }
    }

    // Risk scoring focuses on patterns, not isolated incidents
    double riskScore = 0.0;

    // Extreme patterns (5+ rapid clicks sustained) = major red flag
    if (extremeBurstCount > 0) {
      riskScore += extremeBurstCount * 40.0; // Heavy penalty for clear abuse
    }

    // Suspicious patterns (4 rapid clicks) = moderate concern
    if (suspiciousBurstCount > 2) {
      // Only flag if it happens repeatedly
      riskScore +=
          (suspiciousBurstCount - 2) * 15.0; // Allow some legitimate incidents
    }

    // Single max velocity check for truly extreme speeds (automation)
    if (maxVelocity > 20.0) {
      // Impossible human speed
      riskScore += 60.0;
    }

    return math.min(100.0, riskScore);
  }

  /// Detect micro-bursts of rapid successive clicks with context awareness
  static List<MicroBurst> detectMicroBursts(List<DateTime> timestamps) {
    if (timestamps.length < SUSPICIOUS_BURST_SIZE)
      return []; // Need 4+ clicks to be suspicious

    List<MicroBurst> bursts = [];

    // Look for clusters of 4+ clicks within 1 second (suspicious)
    // or 5+ clicks within 2 seconds (extreme)
    for (int i = 0; i < timestamps.length - (SUSPICIOUS_BURST_SIZE - 1); i++) {
      int burstCount = 1;
      DateTime burstStart = timestamps[i];
      int lastIndex = i;

      for (int j = i + 1; j < timestamps.length; j++) {
        final duration = timestamps[j].difference(burstStart).inMilliseconds;

        // Different time windows based on burst size
        int maxDuration = burstCount >= EXTREME_BURST_SIZE
            ? 2000
            : 1000; // 2s for 5+, 1s for 4

        if (duration <= maxDuration) {
          burstCount++;
          lastIndex = j;
        } else {
          break;
        }
      }

      // Only flag bursts of 4+ clicks (suspicious) or 5+ clicks (extreme)
      if (burstCount >= SUSPICIOUS_BURST_SIZE) {
        final burstDuration =
            timestamps[lastIndex].difference(burstStart).inMilliseconds;
        bursts.add(MicroBurst(
          startTime: burstStart,
          clickCount: burstCount,
          durationMs: burstDuration,
        ));

        // Skip ahead to avoid overlapping bursts
        i = lastIndex;
      }
    }

    return bursts;
  }

  /// Analyze mechanical consistency in timing patterns
  static TimingSignature analyzeMechanicalConsistency(
      List<DateTime> timestamps) {
    if (timestamps.length < 3) {
      return TimingSignature(
        meanInterval: 0.0,
        stdDeviation: 0.0,
        coefficientOfVariation: 1.0, // High variation = human-like
        intervals: [],
      );
    }

    // Calculate intervals between consecutive clicks
    List<int> intervals = [];
    for (int i = 1; i < timestamps.length; i++) {
      final interval =
          timestamps[i].difference(timestamps[i - 1]).inMilliseconds;
      if (interval > 0 && interval < 10000) {
        // Ignore intervals >10 seconds
        intervals.add(interval);
      }
    }

    if (intervals.isEmpty) {
      return TimingSignature(
        meanInterval: 0.0,
        stdDeviation: 0.0,
        coefficientOfVariation: 1.0,
        intervals: [],
      );
    }

    // Calculate statistical measures
    final mean = intervals.reduce((a, b) => a + b) / intervals.length;
    final variance =
        intervals.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) /
            intervals.length;
    final stdDev = math.sqrt(variance);
    final coeffVar = mean > 0 ? stdDev / mean : 1.0;

    return TimingSignature(
      meanInterval: mean,
      stdDeviation: stdDev,
      coefficientOfVariation: coeffVar,
      intervals: intervals,
    );
  }

  /// Detect click sessions with precise timing boundaries
  static List<ClickSession> detectClickSessions(List<DateTime> timestamps,
      {Duration sessionGap = const Duration(minutes: 5)}) {
    if (timestamps.isEmpty) return [];

    List<ClickSession> sessions = [];
    DateTime sessionStart = timestamps.first;
    DateTime sessionEnd = timestamps.first;
    int clickCount = 1;

    for (int i = 1; i < timestamps.length; i++) {
      final gap = timestamps[i].difference(sessionEnd);

      if (gap <= sessionGap) {
        // Continue current session
        sessionEnd = timestamps[i];
        clickCount++;
      } else {
        // End current session and start new one
        sessions.add(ClickSession(
          startTime: sessionStart,
          endTime: sessionEnd,
          clickCount: clickCount,
        ));

        sessionStart = timestamps[i];
        sessionEnd = timestamps[i];
        clickCount = 1;
      }
    }

    // Add final session
    sessions.add(ClickSession(
      startTime: sessionStart,
      endTime: sessionEnd,
      clickCount: clickCount,
    ));

    return sessions;
  }

  /// Calculate comprehensive timestamp-based risk score
  static double calculateTimestampRiskScore(List<DateTime> timestamps) {
    if (timestamps.length < 2) return 0.0;

    double totalRisk = 0.0;

    // 1. Velocity analysis (30% weight)
    final velocityRisk = analyzeClickVelocity(timestamps);
    totalRisk += velocityRisk * 0.30;

    // 2. Mechanical consistency analysis (25% weight)
    final timingSignature = analyzeMechanicalConsistency(timestamps);
    double mechanicalRisk = 0.0;
    if (timingSignature.isMechanical) {
      mechanicalRisk = 80.0;
    } else if (timingSignature.isSuspicious) {
      mechanicalRisk = 40.0;
    }
    totalRisk += mechanicalRisk * 0.25;

    // 3. Micro-burst analysis (25% weight)
    final microBursts = detectMicroBursts(timestamps);
    double burstRisk = 0.0;
    for (final burst in microBursts) {
      if (burst.isExtreme) {
        burstRisk += 30.0;
      } else if (burst.isSuspicious) {
        burstRisk += 15.0;
      }
    }
    totalRisk += math.min(100.0, burstRisk) * 0.25;

    // 4. Session analysis (15% weight)
    final sessions = detectClickSessions(timestamps);
    double sessionRisk = 0.0;
    for (final session in sessions) {
      if (session.isSuspiciouslyIntense) {
        sessionRisk += 20.0;
      }
      if (session.isSuspiciouslyLong) {
        sessionRisk += 15.0;
      }
    }
    totalRisk += math.min(100.0, sessionRisk) * 0.15;

    // 5. Proportional analysis (20% weight) - CRITICAL for dishonest patterns
    final proportionalAnalysis = analyzeClickProportions(timestamps);
    totalRisk += proportionalAnalysis.riskScore * 0.20;

    return math.min(100.0, totalRisk);
  }

  /// Generate enhanced risk factors based on timestamp analysis
  static List<String> generateTimestampRiskFactors(List<DateTime> timestamps) {
    List<String> riskFactors = [];

    if (timestamps.length < 2) return riskFactors;

    // Velocity analysis
    final velocityRisk = analyzeClickVelocity(timestamps);
    if (velocityRisk > 60) {
      // Calculate max velocity for specific message
      double maxVelocity = 0.0;
      for (int i = 1; i < timestamps.length; i++) {
        final intervalMs =
            timestamps[i].difference(timestamps[i - 1]).inMilliseconds;
        if (intervalMs > 0) {
          final velocity = 1000.0 / intervalMs;
          maxVelocity = math.max(maxVelocity, velocity);
        }
      }
      riskFactors.add(
          "Inhuman click velocity detected: ${maxVelocity.toStringAsFixed(1)} clicks/second");
    }

    // Mechanical consistency analysis
    final timingSignature = analyzeMechanicalConsistency(timestamps);
    if (timingSignature.isMechanical) {
      riskFactors.add(
          "Mechanical timing patterns: ${(timingSignature.coefficientOfVariation * 100).toStringAsFixed(1)}% variation coefficient");
    } else if (timingSignature.isSuspicious) {
      riskFactors.add(
          "Suspiciously consistent timing: ${(timingSignature.coefficientOfVariation * 100).toStringAsFixed(1)}% variation");
    }

    // Micro-burst analysis
    final microBursts = detectMicroBursts(timestamps);
    final suspiciousBursts = microBursts.where((b) => b.isSuspicious).toList();
    if (suspiciousBursts.isNotEmpty) {
      final worstBurst =
          suspiciousBursts.reduce((a, b) => a.velocity > b.velocity ? a : b);
      riskFactors.add(
          "Micro-burst detected: ${worstBurst.clickCount} clicks in ${worstBurst.durationMs}ms (${worstBurst.velocity.toStringAsFixed(1)} clicks/sec)");
    }

    // Session analysis
    final sessions = detectClickSessions(timestamps);
    final intenseSessions =
        sessions.where((s) => s.isSuspiciouslyIntense).toList();
    if (intenseSessions.isNotEmpty) {
      final mostIntense = intenseSessions
          .reduce((a, b) => a.averageClickRate > b.averageClickRate ? a : b);
      riskFactors.add(
          "Sustained high-intensity clicking: ${mostIntense.averageClickRate.toStringAsFixed(1)} clicks/sec for ${mostIntense.duration.inMinutes} minutes");
    }

    // Proportional analysis - KEY for detecting dishonest multi-clicking
    final proportionalAnalysis = analyzeClickProportions(timestamps);
    if (proportionalAnalysis.suspiciousProportions) {
      riskFactors.add(
          "Disproportionate multi-clicking: ${proportionalAnalysis.description} - ${proportionalAnalysis.riskAssessment}");
    }

    return riskFactors;
  }

  /// Analyze proportional patterns to detect disproportionate multi-clicking
  static ProportionalAnalysis analyzeClickProportions(
      List<DateTime> timestamps) {
    if (timestamps.length < 10) {
      return ProportionalAnalysis(
        singleClickEvents: 0,
        multiClickEvents: 0,
        totalEvents: 0,
        multiClickRatio: 0.0,
        averageClicksPerEvent: 0.0,
        suspiciousProportions: false,
        riskScore: 0.0,
      );
    }

    // Group clicks into events (clicks within 2 seconds = same event)
    List<ClickEvent> events = [];
    DateTime? currentEventStart;
    int currentEventClicks = 0;

    for (int i = 0; i < timestamps.length; i++) {
      if (currentEventStart == null) {
        // Start new event
        currentEventStart = timestamps[i];
        currentEventClicks = 1;
      } else {
        final timeSinceEventStart =
            timestamps[i].difference(currentEventStart).inMilliseconds;

        if (timeSinceEventStart <= 2000) {
          // Within 2 seconds = same event
          currentEventClicks++;
        } else {
          // End current event, start new one
          events.add(ClickEvent(
            startTime: currentEventStart,
            clickCount: currentEventClicks,
          ));
          currentEventStart = timestamps[i];
          currentEventClicks = 1;
        }
      }
    }

    // Add final event
    if (currentEventStart != null) {
      events.add(ClickEvent(
        startTime: currentEventStart,
        clickCount: currentEventClicks,
      ));
    }

    // Analyze proportions
    final singleClickEvents = events.where((e) => e.clickCount == 1).length;
    final multiClickEvents = events.where((e) => e.clickCount >= 2).length;
    final totalEvents = events.length;
    final multiClickRatio =
        totalEvents > 0 ? multiClickEvents / totalEvents : 0.0;
    final averageClicksPerEvent =
        totalEvents > 0 ? timestamps.length / totalEvents : 0.0;

    // Determine if proportions are suspicious
    double riskScore = 0.0;
    bool suspiciousProportions = false;

    // Normal expectation: Most events should be single clicks
    // Suspicious thresholds:
    if (multiClickRatio > 0.60) {
      // >60% multi-click events is very suspicious
      riskScore += 80.0;
      suspiciousProportions = true;
    } else if (multiClickRatio > 0.40) {
      // >40% multi-click events is suspicious
      riskScore += 50.0;
      suspiciousProportions = true;
    } else if (multiClickRatio > 0.25) {
      // >25% multi-click events is concerning
      riskScore += 25.0;
    }

    // Check for excessive average clicks per event
    if (averageClicksPerEvent > 2.5) {
      // Average >2.5 clicks per event
      riskScore += 40.0;
      suspiciousProportions = true;
    } else if (averageClicksPerEvent > 2.0) {
      // Average >2.0 clicks per event
      riskScore += 20.0;
    }

    // Additional red flags for abuse patterns
    final veryHighMultiClicks = events.where((e) => e.clickCount >= 4).length;
    if (veryHighMultiClicks > totalEvents * 0.10) {
      // >10% of events are 4+ clicks
      riskScore += 60.0;
      suspiciousProportions = true;
    }

    return ProportionalAnalysis(
      singleClickEvents: singleClickEvents,
      multiClickEvents: multiClickEvents,
      totalEvents: totalEvents,
      multiClickRatio: multiClickRatio,
      averageClicksPerEvent: averageClicksPerEvent,
      suspiciousProportions: suspiciousProportions,
      riskScore: math.min(100.0, riskScore),
    );
  }
}
