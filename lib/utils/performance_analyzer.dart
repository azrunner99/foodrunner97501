import 'dart:math' as math;
import '../models.dart';
import '../models/performance_models.dart';

/// Advanced analytics engine for sophisticated performance analysis
class PerformanceAnalyzer {
  // Feature flag for enhanced workload analysis. Default off for safety.
  static const bool kEnableAdvancedWorkloadAnalysis = false;
  /// Calculate peer comparison analysis for a server
  static PeerAnalysis calculatePeerComparison({
    required ServerPerformanceData serverPerformance,
    required List<ServerPerformanceData> allServerPerformances,
    required List<Server> allServers,
  }) {
    // Group servers by tenure brackets for fair comparison
    final tenureBrackets = _groupServersByTenure(allServerPerformances);
    final serverTenureBracket =
        _getTenureBracket(serverPerformance.daysEmployed);
    final peers = tenureBrackets[serverTenureBracket] ?? [];

    // Calculate peer statistics
    final peerScores = peers.map((p) => p.performanceScore).toList();
    final peerRanking =
        _calculatePeerRanking(serverPerformance.performanceScore, peerScores);
    final peerPercentile =
        _calculatePercentile(serverPerformance.performanceScore, peerScores);

    // Calculate comparative metrics
    final comparativeMetrics =
        _calculateComparativeMetrics(serverPerformance, peers);

    // Generate peer insights
    final insights = _generatePeerInsights(
        serverPerformance, peers, peerRanking, peerPercentile);

    return PeerAnalysis(
      serverPerformance: serverPerformance,
      tenureBracket: serverTenureBracket,
      totalPeers: peers.length,
      peerRanking: peerRanking,
      peerPercentile: peerPercentile,
      averageScore: peerScores.isNotEmpty
          ? peerScores.reduce((a, b) => a + b) / peerScores.length
          : 0.0,
      topPerformerScore:
          peerScores.isNotEmpty ? peerScores.reduce(math.max) : 0.0,
      bottomPerformerScore:
          peerScores.isNotEmpty ? peerScores.reduce(math.min) : 0.0,
      comparativeMetrics: comparativeMetrics,
      insights: insights,
    );
  }

  /// Calculate team-wide performance analytics
  static TeamAnalytics calculateTeamAnalytics(
      List<ServerPerformanceData> allPerformances) {
    if (allPerformances.isEmpty) {
      return TeamAnalytics.empty();
    }

    final scores = allPerformances.map((p) => p.performanceScore).toList();
    final meanScore = scores.reduce((a, b) => a + b) / scores.length;
    final variance =
        scores.map((s) => math.pow(s - meanScore, 2)).reduce((a, b) => a + b) /
            scores.length;
    final standardDeviation = math.sqrt(variance);

    // Performance distribution
    final distribution = _calculatePerformanceDistribution(allPerformances);

    // Top and bottom performers
    final sortedByScore = List<ServerPerformanceData>.from(allPerformances)
      ..sort((a, b) => b.performanceScore.compareTo(a.performanceScore));

    final topPerformers = sortedByScore.take(3).toList();
    final bottomPerformers =
        sortedByScore.skip(math.max(0, sortedByScore.length - 3)).toList();

    // Team trends
    final teamTrends = _calculateTeamTrends(allPerformances);

    // Risk assessment
    final riskAssessment = _calculateTeamRiskAssessment(allPerformances);

    return TeamAnalytics(
      totalServers: allPerformances.length,
      averageScore: meanScore,
      standardDeviation: standardDeviation,
      highestScore: scores.reduce(math.max),
      lowestScore: scores.reduce(math.min),
      distribution: distribution,
      topPerformers: topPerformers,
      bottomPerformers: bottomPerformers,
      teamTrends: teamTrends,
      riskAssessment: riskAssessment,
    );
  }

  /// Analyze performance variance and consistency patterns
  static ConsistencyAnalysis analyzeConsistency(
      ServerPerformanceData performance, List<PerformanceTrend> trends) {
    if (trends.length < 2) {
      return ConsistencyAnalysis.insufficient();
    }

    final scores = trends.map((t) => t.score).toList();
    final mean = scores.reduce((a, b) => a + b) / scores.length;
    final variance =
        scores.map((s) => math.pow(s - mean, 2)).reduce((a, b) => a + b) /
            scores.length;
    final standardDeviation = math.sqrt(variance);
    final coefficientOfVariation = mean > 0 ? standardDeviation / mean : 0.0;

    // Trend direction analysis
    final trendDirection = _analyzeTrendDirection(trends);

    // Performance stability rating
    final stabilityRating =
        _calculateStabilityRating(coefficientOfVariation, trendDirection);

    // Consistency insights
    final insights = _generateConsistencyInsights(
        coefficientOfVariation, trendDirection, stabilityRating);

    return ConsistencyAnalysis(
      mean: mean,
      standardDeviation: standardDeviation,
      coefficientOfVariation: coefficientOfVariation,
      trendDirection: trendDirection,
      stabilityRating: stabilityRating,
      insights: insights,
    );
  }

  /// Calculate workload-adjusted performance metrics
  static WorkloadAnalysis calculateWorkloadAnalysis({
    required ServerPerformanceData performance,
    required List<ShiftRecord> allShifts,
    required MonthlyBusinessData? businessData,
  }) {
    // Calculate workload intensity
    final workloadIntensity =
        _calculateWorkloadIntensity(performance, allShifts);

    // Performance under different workload conditions
    final workloadPerformance = _analyzePerformanceByWorkload(
      performance,
      allShifts,
      businessData: businessData,
    );

    // Efficiency relative to workload
    final efficiencyRatio =
        _calculateEfficiencyRatio(performance, workloadIntensity);

    // Workload sustainability assessment
    final sustainability =
        _assessWorkloadSustainability(performance, workloadIntensity);

    return WorkloadAnalysis(
      workloadIntensity: workloadIntensity,
      workloadPerformance: workloadPerformance,
      efficiencyRatio: efficiencyRatio,
      sustainability: sustainability,
    );
  }

  // Private helper methods

  static Map<String, List<ServerPerformanceData>> _groupServersByTenure(
      List<ServerPerformanceData> performances) {
    final Map<String, List<ServerPerformanceData>> groups = {
      'new': [], // 0-30 days
      'junior': [], // 31-90 days
      'regular': [], // 91-180 days
      'senior': [], // 180+ days
    };

    for (final performance in performances) {
      final bracket = _getTenureBracket(performance.daysEmployed);
      groups[bracket]?.add(performance);
    }

    return groups;
  }

  static String _getTenureBracket(int daysEmployed) {
    if (daysEmployed <= 30) return 'new';
    if (daysEmployed <= 90) return 'junior';
    if (daysEmployed <= 180) return 'regular';
    return 'senior';
  }

  static int _calculatePeerRanking(double score, List<double> peerScores) {
    if (peerScores.isEmpty) return 1;
    final betterScores = peerScores.where((s) => s > score).length;
    return betterScores + 1;
  }

  static double _calculatePercentile(double score, List<double> peerScores) {
    if (peerScores.isEmpty) return 100.0;
    final worseScores = peerScores.where((s) => s < score).length;
    return (worseScores / peerScores.length) * 100.0;
  }

  static ComparativeMetrics _calculateComparativeMetrics(
    ServerPerformanceData server,
    List<ServerPerformanceData> peers,
  ) {
    if (peers.isEmpty) {
      return ComparativeMetrics.empty();
    }

    final peerEfficiencies = peers.map((p) => p.metrics.rawEfficiency).toList();
    final peerGuestEfficiencies =
        peers.map((p) => p.metrics.guestEfficiency).toList();
    final peerConsistencies =
        peers.map((p) => p.metrics.consistencyScore).toList();

    final avgEfficiency =
        peerEfficiencies.reduce((a, b) => a + b) / peerEfficiencies.length;
    final avgGuestEfficiency = peerGuestEfficiencies.reduce((a, b) => a + b) /
        peerGuestEfficiencies.length;
    final avgConsistency =
        peerConsistencies.reduce((a, b) => a + b) / peerConsistencies.length;

    return ComparativeMetrics(
      efficiencyVsPeers: server.metrics.rawEfficiency / avgEfficiency,
      guestEfficiencyVsPeers:
          server.metrics.guestEfficiency / avgGuestEfficiency,
      consistencyVsPeers: server.metrics.consistencyScore / avgConsistency,
      averagePeerEfficiency: avgEfficiency,
      averagePeerGuestEfficiency: avgGuestEfficiency,
      averagePeerConsistency: avgConsistency,
    );
  }

  static List<String> _generatePeerInsights(
    ServerPerformanceData server,
    List<ServerPerformanceData> peers,
    int ranking,
    double percentile,
  ) {
    final insights = <String>[];

    if (percentile >= 80) {
      insights.add('Performing in top 20% of peer group');
    } else if (percentile >= 60) {
      insights.add('Above average performance within peer group');
    } else if (percentile >= 40) {
      insights.add('Average performance within peer group');
    } else if (percentile >= 20) {
      insights.add('Below average performance within peer group');
    } else {
      insights.add('Performance needs improvement compared to peers');
    }

    if (ranking == 1) {
      insights.add('Top performer in tenure bracket');
    } else if (ranking <= 3) {
      insights.add('Among top 3 performers in tenure bracket');
    }

    return insights;
  }

  static PerformanceDistribution _calculatePerformanceDistribution(
      List<ServerPerformanceData> performances) {
    int elite = 0, strong = 0, developing = 0, needsAttention = 0, critical = 0;

    for (final performance in performances) {
      switch (performance.rating) {
        case PerformanceRating.elite:
          elite++;
          break;
        case PerformanceRating.strong:
          strong++;
          break;
        case PerformanceRating.developing:
          developing++;
          break;
        case PerformanceRating.needsAttention:
          needsAttention++;
          break;
        case PerformanceRating.critical:
          critical++;
          break;
      }
    }

    return PerformanceDistribution(
      elite: elite,
      strong: strong,
      developing: developing,
      needsAttention: needsAttention,
      critical: critical,
    );
  }

  static TeamTrends _calculateTeamTrends(
      List<ServerPerformanceData> performances) {
    // This would typically compare against historical data
    // For now, we'll provide basic trend indicators
    final improving = performances
        .where((p) => p.flags.contains(PerformanceFlag.highPerformer))
        .length;
    final declining = performances
        .where((p) => p.flags.contains(PerformanceFlag.decliningTrend))
        .length;
    final stable = performances.length - improving - declining;

    return TeamTrends(
      improving: improving,
      stable: stable,
      declining: declining,
    );
  }

  static RiskAssessment _calculateTeamRiskAssessment(
      List<ServerPerformanceData> performances) {
    final highRisk = performances
        .where((p) => p.rating == PerformanceRating.critical)
        .length;
    final mediumRisk = performances
        .where((p) => p.rating == PerformanceRating.needsAttention)
        .length;
    final lowRisk = performances.length - highRisk - mediumRisk;

    final riskLevel = highRisk > 0
        ? 'High'
        : mediumRisk > performances.length * 0.3
            ? 'Medium'
            : 'Low';

    return RiskAssessment(
      overallRiskLevel: riskLevel,
      highRiskServers: highRisk,
      mediumRiskServers: mediumRisk,
      lowRiskServers: lowRisk,
    );
  }

  static TrendDirection _analyzeTrendDirection(List<PerformanceTrend> trends) {
    if (trends.length < 3) return TrendDirection.stable;

    final recentTrends = trends.skip(trends.length - 3).toList();
    final scores = recentTrends.map((t) => t.score).toList();

    final isImproving = scores[2] > scores[1] && scores[1] > scores[0];
    final isDeclining = scores[2] < scores[1] && scores[1] < scores[0];

    if (isImproving) return TrendDirection.improving;
    if (isDeclining) return TrendDirection.declining;
    return TrendDirection.stable;
  }

  static StabilityRating _calculateStabilityRating(
      double coefficientOfVariation, TrendDirection direction) {
    // Low CV = high consistency
    if (coefficientOfVariation < 0.1) {
      return direction == TrendDirection.improving
          ? StabilityRating.excellent
          : StabilityRating.good;
    } else if (coefficientOfVariation < 0.2) {
      return StabilityRating.good;
    } else if (coefficientOfVariation < 0.3) {
      return StabilityRating.fair;
    } else {
      return StabilityRating.poor;
    }
  }

  static List<String> _generateConsistencyInsights(
    double coefficientOfVariation,
    TrendDirection direction,
    StabilityRating rating,
  ) {
    final insights = <String>[];

    switch (rating) {
      case StabilityRating.excellent:
        insights.add('Highly consistent performance with minimal variation');
        break;
      case StabilityRating.good:
        insights.add('Good consistency with acceptable variation');
        break;
      case StabilityRating.fair:
        insights.add('Moderate consistency with some performance swings');
        break;
      case StabilityRating.poor:
        insights.add('High variation in performance, needs attention');
        break;
    }

    switch (direction) {
      case TrendDirection.improving:
        insights.add('Performance trending upward');
        break;
      case TrendDirection.declining:
        insights.add('Performance trending downward');
        break;
      case TrendDirection.stable:
        insights.add('Performance relatively stable');
        break;
    }

    return insights;
  }

  static double _calculateWorkloadIntensity(
      ServerPerformanceData performance, List<ShiftRecord> shifts) {
    // Calculate average workload intensity based on shifts worked and complexity
    final serverShifts = shifts
        .where((s) => s.counts.containsKey(performance.serverId))
        .toList();
    if (serverShifts.isEmpty) return 1.0;

    // Factor in shift frequency and type
    final shiftFrequency =
        serverShifts.length / 30.0; // shifts per day over 30 days
    final avgRunsPerShift = performance.shiftsWorked > 0
        ? performance.totalFoodRuns / performance.shiftsWorked
        : 0.0;

    // Normalize to 0-2 scale where 1.0 is average intensity
    return math.min(2.0, (shiftFrequency * 0.5) + (avgRunsPerShift / 10.0));
  }

  static Map<String, double> _analyzePerformanceByWorkload(
    ServerPerformanceData performance,
    List<ShiftRecord> shifts, {
    MonthlyBusinessData? businessData,
  }) {
    if (!kEnableAdvancedWorkloadAnalysis || shifts.isEmpty) {
      return {
        'lowWorkload': performance.performanceScore * 1.1,
        'mediumWorkload': performance.performanceScore,
        'highWorkload': performance.performanceScore * 0.9,
      };
    }

    // Basic enhanced logic: bucket recent shifts by runs-per-shift relative to
    // period guest volume (if available) to approximate workload pressure.
    final serverId = performance.serverId;
    final serverShifts = shifts
        .where((s) => s.counts.containsKey(serverId))
        .toList(growable: false);
    if (serverShifts.isEmpty) {
      return {
        'lowWorkload': performance.performanceScore,
        'mediumWorkload': performance.performanceScore,
        'highWorkload': performance.performanceScore,
      };
    }

    final totalRuns = serverShifts.fold<int>(
        0, (sum, s) => sum + (s.counts[serverId] ?? 0));
    final runsPerShift = totalRuns / serverShifts.length;

    double guestLoadPerShift;
    if (businessData != null && businessData.totalGuestCount > 0) {
      // Approximate per-shift guest volume for the server using either server-specific
      // mapping when available, otherwise distribute total guests evenly.
      final serverGuests = businessData.serverSpecificGuests[serverId] ??
          (businessData.totalGuestCount /
              math.max(1, serverShifts.length));
      guestLoadPerShift = serverGuests / math.max(1, serverShifts.length);
    } else {
      // Fallback: use runs-per-shift as a proxy for workload
      guestLoadPerShift = runsPerShift * 6; // heuristic proxy
    }

    // Define buckets by guest load per shift
    final lowThreshold = guestLoadPerShift * 0.8;
    final highThreshold = guestLoadPerShift * 1.2;

    // Simulate workload-specific performance adjustments
    // Note: this keeps deltas small to avoid behavior changes
    double low = performance.performanceScore;
    double med = performance.performanceScore;
    double high = performance.performanceScore;

    if (runsPerShift < lowThreshold) {
      low *= 1.05; // slightly better under light load
      high *= 0.95;
    } else if (runsPerShift > highThreshold) {
      high *= 1.05; // slightly better under heavy load if coping well
      low *= 0.95;
    }

    return {
      'lowWorkload': low,
      'mediumWorkload': med,
      'highWorkload': high,
    };
  }

  static double _calculateEfficiencyRatio(
      ServerPerformanceData performance, double workloadIntensity) {
    // Higher efficiency ratio means better performance relative to workload
    return workloadIntensity > 0
        ? performance.performanceScore / (workloadIntensity * 50)
        : performance.performanceScore / 50;
  }

  static WorkloadSustainability _assessWorkloadSustainability(
      ServerPerformanceData performance, double workloadIntensity) {
    final efficiencyRatio =
        _calculateEfficiencyRatio(performance, workloadIntensity);

    if (efficiencyRatio > 1.5) {
      return WorkloadSustainability.excellent;
    } else if (efficiencyRatio > 1.2) {
      return WorkloadSustainability.good;
    } else if (efficiencyRatio > 0.8) {
      return WorkloadSustainability.fair;
    } else {
      return WorkloadSustainability.poor;
    }
  }
}

// Supporting data classes

class PeerAnalysis {
  final ServerPerformanceData serverPerformance;
  final String tenureBracket;
  final int totalPeers;
  final int peerRanking;
  final double peerPercentile;
  final double averageScore;
  final double topPerformerScore;
  final double bottomPerformerScore;
  final ComparativeMetrics comparativeMetrics;
  final List<String> insights;

  PeerAnalysis({
    required this.serverPerformance,
    required this.tenureBracket,
    required this.totalPeers,
    required this.peerRanking,
    required this.peerPercentile,
    required this.averageScore,
    required this.topPerformerScore,
    required this.bottomPerformerScore,
    required this.comparativeMetrics,
    required this.insights,
  });
}

class ComparativeMetrics {
  final double efficiencyVsPeers;
  final double guestEfficiencyVsPeers;
  final double consistencyVsPeers;
  final double averagePeerEfficiency;
  final double averagePeerGuestEfficiency;
  final double averagePeerConsistency;

  ComparativeMetrics({
    required this.efficiencyVsPeers,
    required this.guestEfficiencyVsPeers,
    required this.consistencyVsPeers,
    required this.averagePeerEfficiency,
    required this.averagePeerGuestEfficiency,
    required this.averagePeerConsistency,
  });

  static ComparativeMetrics empty() => ComparativeMetrics(
        efficiencyVsPeers: 1.0,
        guestEfficiencyVsPeers: 1.0,
        consistencyVsPeers: 1.0,
        averagePeerEfficiency: 0.0,
        averagePeerGuestEfficiency: 0.0,
        averagePeerConsistency: 0.0,
      );
}

class TeamAnalytics {
  final int totalServers;
  final double averageScore;
  final double standardDeviation;
  final double highestScore;
  final double lowestScore;
  final PerformanceDistribution distribution;
  final List<ServerPerformanceData> topPerformers;
  final List<ServerPerformanceData> bottomPerformers;
  final TeamTrends teamTrends;
  final RiskAssessment riskAssessment;

  TeamAnalytics({
    required this.totalServers,
    required this.averageScore,
    required this.standardDeviation,
    required this.highestScore,
    required this.lowestScore,
    required this.distribution,
    required this.topPerformers,
    required this.bottomPerformers,
    required this.teamTrends,
    required this.riskAssessment,
  });

  static TeamAnalytics empty() => TeamAnalytics(
        totalServers: 0,
        averageScore: 0.0,
        standardDeviation: 0.0,
        highestScore: 0.0,
        lowestScore: 0.0,
        distribution: PerformanceDistribution(
            elite: 0, strong: 0, developing: 0, needsAttention: 0, critical: 0),
        topPerformers: [],
        bottomPerformers: [],
        teamTrends: TeamTrends(improving: 0, stable: 0, declining: 0),
        riskAssessment: RiskAssessment(
            overallRiskLevel: 'Low',
            highRiskServers: 0,
            mediumRiskServers: 0,
            lowRiskServers: 0),
      );
}

class PerformanceDistribution {
  final int elite;
  final int strong;
  final int developing;
  final int needsAttention;
  final int critical;

  PerformanceDistribution({
    required this.elite,
    required this.strong,
    required this.developing,
    required this.needsAttention,
    required this.critical,
  });
}

class TeamTrends {
  final int improving;
  final int stable;
  final int declining;

  TeamTrends({
    required this.improving,
    required this.stable,
    required this.declining,
  });
}

class RiskAssessment {
  final String overallRiskLevel;
  final int highRiskServers;
  final int mediumRiskServers;
  final int lowRiskServers;

  RiskAssessment({
    required this.overallRiskLevel,
    required this.highRiskServers,
    required this.mediumRiskServers,
    required this.lowRiskServers,
  });
}

class ConsistencyAnalysis {
  final double mean;
  final double standardDeviation;
  final double coefficientOfVariation;
  final TrendDirection trendDirection;
  final StabilityRating stabilityRating;
  final List<String> insights;

  ConsistencyAnalysis({
    required this.mean,
    required this.standardDeviation,
    required this.coefficientOfVariation,
    required this.trendDirection,
    required this.stabilityRating,
    required this.insights,
  });

  static ConsistencyAnalysis insufficient() => ConsistencyAnalysis(
        mean: 0.0,
        standardDeviation: 0.0,
        coefficientOfVariation: 0.0,
        trendDirection: TrendDirection.stable,
        stabilityRating: StabilityRating.fair,
        insights: ['Insufficient data for consistency analysis'],
      );
}

class WorkloadAnalysis {
  final double workloadIntensity;
  final Map<String, double> workloadPerformance;
  final double efficiencyRatio;
  final WorkloadSustainability sustainability;

  WorkloadAnalysis({
    required this.workloadIntensity,
    required this.workloadPerformance,
    required this.efficiencyRatio,
    required this.sustainability,
  });
}

enum TrendDirection { improving, stable, declining }

enum StabilityRating { excellent, good, fair, poor }

enum WorkloadSustainability { excellent, good, fair, poor }
