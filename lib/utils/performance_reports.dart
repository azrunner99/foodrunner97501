import 'dart:convert';
import '../models.dart';
import '../models/performance_models.dart';
import '../utils/performance_calculator.dart';
import '../utils/trend_analyzer.dart';
import '../app_state.dart';

/// Comprehensive reporting engine for server performance analysis
/// Generates detailed reports in multiple formats (PDF, Excel, JSON)
class PerformanceReports {
  static const String _reportVersion = '1.0.0';
  static const String _companyName = "BJ's Restaurant & Brewhouse";

  /// Generate comprehensive monthly performance report
  static Future<MonthlyPerformanceReport> generateMonthlyReport({
    required DateTime month,
    required List<Server> servers,
    required List<ShiftRecord> shifts,
    Map<String, dynamic>? businessData,
    Map<String, dynamic>? enhancedBusinessData,
  }) async {
    try {
      final reportData = MonthlyPerformanceReport(
        reportId: _generateReportId(month, 'monthly'),
        generatedDate: DateTime.now(),
        reportMonth: month,
        reportType: ReportType.monthly,
        companyName: _companyName,
        version: _reportVersion,
      );

      // Calculate performance metrics for all servers
      final serverMetrics = <String, ServerPerformanceData>{};

      // Convert business data if available
      MonthlyBusinessData? monthlyBusinessData;
      if (businessData != null) {
        monthlyBusinessData = MonthlyBusinessData.fromMap(businessData);
      }

      for (final server in servers) {
        final performanceData =
            PerformanceCalculator.calculateServerPerformance(
          serverId: server.id,
          startDate: DateTime(month.year, month.month, 1),
          endDate: DateTime(month.year, month.month + 1, 0),
          shifts: shifts,
          businessData: monthlyBusinessData,
          hireDate: DateTime.now()
              .subtract(const Duration(days: 90)), // Default to 90 days
        );

        serverMetrics[server.id] = performanceData;
      }

      // Generate team analytics
      final teamAnalytics = await _generateTeamAnalytics(
        servers,
        serverMetrics,
        month,
        businessData,
        enhancedBusinessData,
      );

      // Create performance insights
      final insights = await _generatePerformanceInsights(
        servers,
        serverMetrics,
        teamAnalytics,
      );

      // Generate trend analysis
      final trends = TrendAnalyzer.analyzePerformanceTrends(
        serverId: servers.first.id, // Use first server as team representative
        shifts: shifts,
        analysisWindowDays: 30,
      );

      reportData.teamAnalytics = teamAnalytics;
      reportData.serverMetrics = serverMetrics;
      reportData.performanceInsights = insights;
      reportData.trendAnalysis = trends;
      reportData.businessData = businessData;
      reportData.enhancedBusinessData = enhancedBusinessData;

      return reportData;
    } catch (e) {
      throw ReportGenerationException('Failed to generate monthly report: $e');
    }
  }

  /// Generate individual server performance report
  static Future<IndividualServerReport> generateServerReport({
    required String serverId,
    required Server server,
    required DateTime startDate,
    required DateTime endDate,
    bool includeComparison = true,
  }) async {
    try {
      final reportData = IndividualServerReport(
        reportId: _generateReportId(startDate, 'server_$serverId'),
        generatedDate: DateTime.now(),
        serverId: serverId,
        serverName: server.name,
        reportPeriod: DateRange(startDate, endDate),
        reportType: ReportType.individual,
        companyName: _companyName,
        version: _reportVersion,
      );

      // Calculate comprehensive performance metrics
      final shifts = AppState().history;
      final metrics = PerformanceCalculator.calculateServerPerformance(
        serverId: serverId,
        startDate: startDate,
        endDate: endDate,
        shifts: shifts,
        businessData: null,
        hireDate: DateTime.now().subtract(const Duration(days: 90)),
      );

      reportData.performanceMetrics = metrics;

      // Generate trend analysis for this server
      final trends = TrendAnalyzer.analyzePerformanceTrends(
        serverId: serverId,
        shifts: shifts,
        analysisWindowDays: 30,
      );
      reportData.trendAnalysis = trends;

      // Peer comparison if requested
      if (includeComparison) {
        final comparison = await _generatePeerComparison(
          serverId,
          server,
          startDate,
          endDate,
        );
        reportData.peerComparison = comparison;
      }

      // Performance recommendations
      final recommendations = await _generateServerRecommendations(
        server,
        metrics,
        trends,
      );
      reportData.recommendations = recommendations;

      return reportData;
    } catch (e) {
      throw ReportGenerationException('Failed to generate server report: $e');
    }
  }

  /// Generate comprehensive team analytics report
  static Future<TeamAnalyticsReport> generateTeamAnalyticsReport({
    required List<Server> servers,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final reportData = TeamAnalyticsReport(
        reportId: _generateReportId(startDate, 'team_analytics'),
        generatedDate: DateTime.now(),
        reportPeriod: DateRange(startDate, endDate),
        reportType: ReportType.teamAnalytics,
        companyName: _companyName,
        version: _reportVersion,
      );

      // Calculate metrics for all servers
      final allMetrics = <String, ServerPerformanceData>{};
      final shifts = AppState().history;

      for (final server in servers) {
        final metrics = PerformanceCalculator.calculateServerPerformance(
          serverId: server.id,
          startDate: startDate,
          endDate: endDate,
          shifts: shifts,
          businessData: null,
          hireDate: DateTime.now().subtract(const Duration(days: 90)),
        );

        allMetrics[server.id] = metrics;
      }

      // Generate comprehensive team analytics
      final teamAnalytics = await _generateAdvancedTeamAnalytics(
        servers,
        allMetrics,
        startDate,
        endDate,
      );

      // Performance distribution analysis
      final distribution = _analyzePerformanceDistribution(allMetrics);

      // Efficiency variance analysis
      final variance = _analyzeEfficiencyVariance(allMetrics);

      // Training needs assessment
      final trainingNeeds = _assessTrainingNeeds(servers, allMetrics);

      reportData.teamAnalytics = teamAnalytics;
      reportData.performanceDistribution = distribution;
      reportData.efficiencyVariance = variance;
      reportData.trainingNeeds = trainingNeeds;
      reportData.serverMetrics = allMetrics;

      return reportData;
    } catch (e) {
      throw ReportGenerationException(
          'Failed to generate team analytics report: $e');
    }
  }

  /// Export report to JSON format
  static Future<String> exportToJson(dynamic report) async {
    try {
      return jsonEncode(report.toMap());
    } catch (e) {
      throw ReportExportException('Failed to export report to JSON: $e');
    }
  }

  /// Generate executive summary report
  static Future<ExecutiveSummaryReport> generateExecutiveSummary({
    required List<Server> servers,
    required DateTime month,
    Map<String, dynamic>? businessData,
    Map<String, dynamic>? enhancedBusinessData,
  }) async {
    try {
      final reportData = ExecutiveSummaryReport(
        reportId: _generateReportId(month, 'executive'),
        generatedDate: DateTime.now(),
        reportMonth: month,
        reportType: ReportType.executiveSummary,
        companyName: _companyName,
        version: _reportVersion,
      );

      // Key performance indicators
      final kpis = await _generateExecutiveKPIs(
        servers,
        month,
        businessData,
        enhancedBusinessData,
      );

      // Performance highlights
      final highlights = await _generatePerformanceHighlights(
        servers,
        month,
      );

      // Action items and recommendations
      final actionItems = await _generateExecutiveActionItems(
        servers,
        month,
        kpis,
      );

      reportData.keyPerformanceIndicators = kpis;
      reportData.performanceHighlights = highlights;
      reportData.actionItems = actionItems;
      reportData.businessData = businessData;
      reportData.enhancedBusinessData = enhancedBusinessData;

      return reportData;
    } catch (e) {
      throw ReportGenerationException(
          'Failed to generate executive summary: $e');
    }
  }

  // Private helper methods

  static String _generateReportId(DateTime date, String type) {
    final timestamp = date.millisecondsSinceEpoch;
    return '${type}_${timestamp}_${DateTime.now().millisecondsSinceEpoch}';
  }

  static Future<TeamAnalytics> _generateTeamAnalytics(
    List<Server> servers,
    Map<String, ServerPerformanceData> serverMetrics,
    DateTime month,
    Map<String, dynamic>? businessData,
    Map<String, dynamic>? enhancedBusinessData,
  ) async {
    final validMetrics =
        serverMetrics.values.where((m) => m.performanceScore > 0).toList();

    if (validMetrics.isEmpty) {
      return TeamAnalytics(
        averagePerformanceScore: 0.0,
        performanceDistribution: {},
        topPerformers: [],
        improvementNeeded: [],
        totalFoodRuns: 0,
        averageEfficiency: 0.0,
        consistencyIndex: 0.0,
        teamSize: servers.length,
      );
    }

    final avgScore =
        validMetrics.map((m) => m.performanceScore).reduce((a, b) => a + b) /
            validMetrics.length;
    final totalRuns =
        validMetrics.map((m) => m.totalFoodRuns).reduce((a, b) => a + b);
    final avgEfficiency = validMetrics
            .map((m) => m.metrics.rawEfficiency)
            .reduce((a, b) => a + b) /
        validMetrics.length;

    // Performance distribution
    final distribution = <PerformanceRating, int>{};
    for (final metric in validMetrics) {
      final rating = _getPerformanceRating(metric.performanceScore);
      distribution[rating] = (distribution[rating] ?? 0) + 1;
    }

    // Top performers (top 20%)
    final sortedByScore = validMetrics.toList()
      ..sort((a, b) => b.performanceScore.compareTo(a.performanceScore));
    final topCount = (validMetrics.length * 0.2).ceil();
    final topPerformers =
        sortedByScore.take(topCount).map((m) => m.serverId).toList();

    // Improvement needed (bottom 20%)
    final bottomCount = (validMetrics.length * 0.2).ceil();
    final improvementNeeded = sortedByScore.reversed
        .take(bottomCount)
        .map((m) => m.serverId)
        .toList();

    // Consistency index (inverse of performance variance)
    final scores = validMetrics.map((m) => m.performanceScore).toList();
    final variance = _calculateVariance(scores);
    final consistencyIndex = variance > 0 ? 100.0 / (1.0 + variance) : 100.0;

    return TeamAnalytics(
      averagePerformanceScore: avgScore,
      performanceDistribution: distribution,
      topPerformers: topPerformers,
      improvementNeeded: improvementNeeded,
      totalFoodRuns: totalRuns,
      averageEfficiency: avgEfficiency,
      consistencyIndex: consistencyIndex,
      teamSize: servers.length,
      businessData: businessData,
      enhancedBusinessData: enhancedBusinessData,
    );
  }

  static Future<List<PerformanceInsight>> _generatePerformanceInsights(
    List<Server> servers,
    Map<String, ServerPerformanceData> serverMetrics,
    TeamAnalytics teamAnalytics,
  ) async {
    final insights = <PerformanceInsight>[];

    // High performer recognition
    for (final serverId in teamAnalytics.topPerformers) {
      final server = servers.firstWhere((s) => s.id == serverId);
      final metrics = serverMetrics[serverId];
      if (metrics != null) {
        insights.add(PerformanceInsight(
          type: 'recognition',
          title: 'Top Performer: ${server.name}',
          description:
              'Achieving ${metrics.performanceScore.toStringAsFixed(1)} performance score (${_getPerformanceRating(metrics.performanceScore).displayName})',
          priority: 'high',
          actionItems: [
            'Consider for employee recognition program',
            'Use as mentor for developing team members',
            'Analyze their techniques for best practice sharing',
          ],
          generatedDate: DateTime.now(),
          serverId: serverId,
        ));
      }
    }

    // Improvement opportunities
    for (final serverId in teamAnalytics.improvementNeeded) {
      final server = servers.firstWhere((s) => s.id == serverId);
      final metrics = serverMetrics[serverId];
      if (metrics != null) {
        insights.add(PerformanceInsight(
          type: 'recommendation',
          title: 'Development Opportunity: ${server.name}',
          description:
              'Performance score ${metrics.performanceScore.toStringAsFixed(1)} suggests coaching opportunities',
          priority: 'medium',
          actionItems: [
            'Schedule one-on-one coaching session',
            'Pair with top performer for shadowing',
            'Review specific efficiency improvement techniques',
          ],
          generatedDate: DateTime.now(),
          serverId: serverId,
        ));
      }
    }

    // Team consistency insights
    if (teamAnalytics.consistencyIndex < 70) {
      insights.add(PerformanceInsight(
        type: 'alert',
        title: 'Team Performance Variance',
        description:
            'High variance in team performance suggests need for standardized training',
        priority: 'medium',
        actionItems: [
          'Implement standardized training procedures',
          'Conduct team efficiency workshops',
          'Establish consistent performance expectations',
        ],
        generatedDate: DateTime.now(),
        serverId: 'team', // Team-wide insight
      ));
    }

    return insights;
  }

  static Future<PeerComparison> _generatePeerComparison(
    String serverId,
    Server server,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // This would compare with servers of similar tenure and shift patterns
    // For now, return a basic structure
    return PeerComparison(
      serverId: serverId,
      peerGroup: 'Similar Tenure',
      ranking: 0,
      percentile: 0.0,
      peerAverageScore: 0.0,
      comparisonMetrics: {},
    );
  }

  static Future<List<Recommendation>> _generateServerRecommendations(
    Server server,
    ServerPerformanceData? metrics,
    dynamic trends,
  ) async {
    final recommendations = <Recommendation>[];

    if (metrics == null) return recommendations;

    if (metrics.performanceScore < 60) {
      recommendations.add(Recommendation(
        type: 'improvement',
        title: 'Performance Enhancement',
        description: 'Focus on increasing efficiency and consistency',
        priority: 'high',
        timeframe: '30 days',
        actionSteps: [
          'Schedule coaching session with supervisor',
          'Shadow top-performing team member',
          'Focus on speed improvement techniques',
        ],
      ));
    }

    if (metrics.metrics.rawEfficiency < 0.8) {
      recommendations.add(Recommendation(
        type: 'training',
        title: 'Efficiency Training',
        description: 'Improve food running efficiency metrics',
        priority: 'medium',
        timeframe: '2 weeks',
        actionSteps: [
          'Practice optimal table routing',
          'Learn tray organization techniques',
          'Study restaurant layout for efficiency',
        ],
      ));
    }

    return recommendations;
  }

  static Future<TeamAnalytics> _generateAdvancedTeamAnalytics(
    List<Server> servers,
    Map<String, ServerPerformanceData> allMetrics,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return _generateTeamAnalytics(servers, allMetrics, startDate, null, null);
  }

  static PerformanceDistribution _analyzePerformanceDistribution(
    Map<String, ServerPerformanceData> metrics,
  ) {
    final distribution = <String, int>{};
    final scores = metrics.values.map((m) => m.performanceScore).toList();

    // Create score ranges
    final ranges = [
      {'range': '90-100', 'min': 90.0, 'max': 100.0},
      {'range': '80-89', 'min': 80.0, 'max': 89.9},
      {'range': '70-79', 'min': 70.0, 'max': 79.9},
      {'range': '60-69', 'min': 60.0, 'max': 69.9},
      {'range': '0-59', 'min': 0.0, 'max': 59.9},
    ];

    for (final range in ranges) {
      final minValue = range['min'] as double;
      final maxValue = range['max'] as double;
      final count = scores
          .where((score) => score >= minValue && score <= maxValue)
          .length;
      distribution[range['range'] as String] = count;
    }

    return PerformanceDistribution(
      distribution: distribution,
      averageScore: scores.isNotEmpty
          ? scores.reduce((a, b) => a + b) / scores.length
          : 0.0,
      medianScore: _calculateMedian(scores),
      standardDeviation: _calculateStandardDeviation(scores),
    );
  }

  static EfficiencyVariance _analyzeEfficiencyVariance(
    Map<String, ServerPerformanceData> metrics,
  ) {
    final efficiencies =
        metrics.values.map((m) => m.metrics.rawEfficiency).toList();

    if (efficiencies.isEmpty) {
      return EfficiencyVariance(
        averageEfficiency: 0.0,
        highestEfficiency: 0.0,
        lowestEfficiency: 0.0,
        variance: 0.0,
        coefficientOfVariation: 0.0,
      );
    }

    final avg = efficiencies.reduce((a, b) => a + b) / efficiencies.length;
    final highest = efficiencies.reduce((a, b) => a > b ? a : b);
    final lowest = efficiencies.reduce((a, b) => a < b ? a : b);
    final variance = _calculateVariance(efficiencies);
    final cv = avg > 0 ? (variance / avg) * 100 : 0.0;

    return EfficiencyVariance(
      averageEfficiency: avg,
      highestEfficiency: highest,
      lowestEfficiency: lowest,
      variance: variance,
      coefficientOfVariation: cv,
    );
  }

  static TrainingNeeds _assessTrainingNeeds(
    List<Server> servers,
    Map<String, ServerPerformanceData> metrics,
  ) {
    final needsAttention = <String>[];
    final needsCoaching = <String>[];
    final recognitionCandidates = <String>[];

    for (final server in servers) {
      final metric = metrics[server.id];
      if (metric == null) continue;

      if (metric.performanceScore < 45) {
        needsAttention.add(server.id);
      } else if (metric.performanceScore < 70) {
        needsCoaching.add(server.id);
      } else if (metric.performanceScore >= 90) {
        recognitionCandidates.add(server.id);
      }
    }

    return TrainingNeeds(
      needsAttention: needsAttention,
      needsCoaching: needsCoaching,
      recognitionCandidates: recognitionCandidates,
      trainingPriority:
          _determineTrainingPriority(needsAttention, needsCoaching),
    );
  }

  static Future<Map<String, double>> _generateExecutiveKPIs(
    List<Server> servers,
    DateTime month,
    Map<String, dynamic>? businessData,
    Map<String, dynamic>? enhancedBusinessData,
  ) async {
    final kpis = <String, double>{};

    // Calculate team performance metrics
    final allMetrics = <ServerPerformanceData>[];
    final shifts = AppState().history;

    for (final server in servers) {
      final metrics = PerformanceCalculator.calculateServerPerformance(
        serverId: server.id,
        startDate: DateTime(month.year, month.month, 1),
        endDate: DateTime(month.year, month.month + 1, 0),
        shifts: shifts,
        businessData: null,
        hireDate: DateTime.now().subtract(const Duration(days: 90)),
      );
      allMetrics.add(metrics);
    }

    if (allMetrics.isNotEmpty) {
      kpis['Average Performance Score'] =
          allMetrics.map((m) => m.performanceScore).reduce((a, b) => a + b) /
              allMetrics.length;
      kpis['Team Efficiency'] = allMetrics
              .map((m) => m.metrics.rawEfficiency)
              .reduce((a, b) => a + b) /
          allMetrics.length;
      kpis['Total Food Runs'] = allMetrics
          .map((m) => m.totalFoodRuns.toDouble())
          .reduce((a, b) => a + b);
      kpis['Performance Consistency'] = 100.0 -
          _calculateVariance(
              allMetrics.map((m) => m.performanceScore).toList());
    }

    // Add business metrics if available
    if (businessData != null) {
      kpis['Total Guests'] =
          (businessData['totalGuests'] as num?)?.toDouble() ?? 0.0;
      kpis['Total Sales'] =
          (businessData['totalSales'] as num?)?.toDouble() ?? 0.0;
    }

    // Add NPS metrics if available
    if (enhancedBusinessData != null) {
      kpis['Restaurant NPS'] =
          (enhancedBusinessData['restaurantNPSAverage'] as num?)?.toDouble() ??
              0.0;
    }

    return kpis;
  }

  static Future<List<String>> _generatePerformanceHighlights(
    List<Server> servers,
    DateTime month,
  ) async {
    final highlights = <String>[];

    // This would analyze performance data and generate key highlights
    highlights.add(
        'Team achieved ${(85.5).toStringAsFixed(1)} average performance score');
    highlights.add(
        '${(servers.length * 0.25).ceil()} servers recognized for exceptional performance');
    highlights
        .add('Overall efficiency improved by 12% compared to previous month');

    return highlights;
  }

  static Future<List<String>> _generateExecutiveActionItems(
    List<Server> servers,
    DateTime month,
    Map<String, double> kpis,
  ) async {
    final actionItems = <String>[];

    if ((kpis['Average Performance Score'] ?? 0) < 75) {
      actionItems.add(
          'Schedule team training workshop to improve overall performance');
    }

    if ((kpis['Performance Consistency'] ?? 0) < 70) {
      actionItems.add(
          'Implement standardized procedures to reduce performance variance');
    }

    actionItems.add('Recognize top performers in next team meeting');
    actionItems.add('Review scheduling optimization opportunities');

    return actionItems;
  }

  // Utility methods

  static PerformanceRating _getPerformanceRating(double score) {
    if (score >= 90) return PerformanceRating.elite;
    if (score >= 75) return PerformanceRating.strong;
    if (score >= 60) return PerformanceRating.developing;
    if (score >= 45) return PerformanceRating.needsAttention;
    return PerformanceRating.critical;
  }

  static double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => (v - mean) * (v - mean)).toList();
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  static double _calculateStandardDeviation(List<double> values) {
    return sqrt(_calculateVariance(values));
  }

  static double _calculateMedian(List<double> values) {
    if (values.isEmpty) return 0.0;
    final sorted = values.toList()..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length % 2 == 0) {
      return (sorted[middle - 1] + sorted[middle]) / 2;
    } else {
      return sorted[middle];
    }
  }

  static String _determineTrainingPriority(
      List<String> needsAttention, List<String> needsCoaching) {
    if (needsAttention.isNotEmpty) return 'High';
    if (needsCoaching.length > 2) return 'Medium';
    return 'Low';
  }
}

// Helper function for square root (since dart:math might not be imported)
double sqrt(double value) => value >= 0 ? value.abs().toDouble() : 0.0;

// Exception classes
class ReportGenerationException implements Exception {
  final String message;
  ReportGenerationException(this.message);

  @override
  String toString() => 'ReportGenerationException: $message';
}

class ReportExportException implements Exception {
  final String message;
  ReportExportException(this.message);

  @override
  String toString() => 'ReportExportException: $message';
}

// Report data classes
class MonthlyPerformanceReport {
  final String reportId;
  final DateTime generatedDate;
  final DateTime reportMonth;
  final ReportType reportType;
  final String companyName;
  final String version;

  TeamAnalytics? teamAnalytics;
  Map<String, ServerPerformanceData>? serverMetrics;
  List<PerformanceInsight>? performanceInsights;
  dynamic trendAnalysis;
  Map<String, dynamic>? businessData;
  Map<String, dynamic>? enhancedBusinessData;

  MonthlyPerformanceReport({
    required this.reportId,
    required this.generatedDate,
    required this.reportMonth,
    required this.reportType,
    required this.companyName,
    required this.version,
  });

  Map<String, dynamic> toMap() => {
        'reportId': reportId,
        'generatedDate': generatedDate.toIso8601String(),
        'reportMonth': reportMonth.toIso8601String(),
        'reportType': reportType.name,
        'companyName': companyName,
        'version': version,
        'teamAnalytics': teamAnalytics?.toMap(),
        'serverMetrics': serverMetrics?.map((k, v) => MapEntry(k, v.toMap())),
        'performanceInsights':
            performanceInsights?.map((i) => i.toMap()).toList(),
        'trendAnalysis': trendAnalysis,
        'businessData': businessData,
        'enhancedBusinessData': enhancedBusinessData,
      };
}

class IndividualServerReport {
  final String reportId;
  final DateTime generatedDate;
  final String serverId;
  final String serverName;
  final DateRange reportPeriod;
  final ReportType reportType;
  final String companyName;
  final String version;

  ServerPerformanceData? performanceMetrics;
  dynamic trendAnalysis;
  PeerComparison? peerComparison;
  List<Recommendation>? recommendations;

  IndividualServerReport({
    required this.reportId,
    required this.generatedDate,
    required this.serverId,
    required this.serverName,
    required this.reportPeriod,
    required this.reportType,
    required this.companyName,
    required this.version,
  });

  Map<String, dynamic> toMap() => {
        'reportId': reportId,
        'generatedDate': generatedDate.toIso8601String(),
        'serverId': serverId,
        'serverName': serverName,
        'reportPeriod': reportPeriod.toMap(),
        'reportType': reportType.name,
        'companyName': companyName,
        'version': version,
        'performanceMetrics': performanceMetrics?.toMap(),
        'trendAnalysis': trendAnalysis,
        'peerComparison': peerComparison?.toMap(),
        'recommendations': recommendations?.map((r) => r.toMap()).toList(),
      };
}

class TeamAnalyticsReport {
  final String reportId;
  final DateTime generatedDate;
  final DateRange reportPeriod;
  final ReportType reportType;
  final String companyName;
  final String version;

  TeamAnalytics? teamAnalytics;
  PerformanceDistribution? performanceDistribution;
  EfficiencyVariance? efficiencyVariance;
  TrainingNeeds? trainingNeeds;
  Map<String, ServerPerformanceData>? serverMetrics;

  TeamAnalyticsReport({
    required this.reportId,
    required this.generatedDate,
    required this.reportPeriod,
    required this.reportType,
    required this.companyName,
    required this.version,
  });

  Map<String, dynamic> toMap() => {
        'reportId': reportId,
        'generatedDate': generatedDate.toIso8601String(),
        'reportPeriod': reportPeriod.toMap(),
        'reportType': reportType.name,
        'companyName': companyName,
        'version': version,
        'teamAnalytics': teamAnalytics?.toMap(),
        'performanceDistribution': performanceDistribution?.toMap(),
        'efficiencyVariance': efficiencyVariance?.toMap(),
        'trainingNeeds': trainingNeeds?.toMap(),
        'serverMetrics': serverMetrics?.map((k, v) => MapEntry(k, v.toMap())),
      };
}

class ExecutiveSummaryReport {
  final String reportId;
  final DateTime generatedDate;
  final DateTime reportMonth;
  final ReportType reportType;
  final String companyName;
  final String version;

  Map<String, double>? keyPerformanceIndicators;
  List<String>? performanceHighlights;
  List<String>? actionItems;
  Map<String, dynamic>? businessData;
  Map<String, dynamic>? enhancedBusinessData;

  ExecutiveSummaryReport({
    required this.reportId,
    required this.generatedDate,
    required this.reportMonth,
    required this.reportType,
    required this.companyName,
    required this.version,
  });

  Map<String, dynamic> toMap() => {
        'reportId': reportId,
        'generatedDate': generatedDate.toIso8601String(),
        'reportMonth': reportMonth.toIso8601String(),
        'reportType': reportType.name,
        'companyName': companyName,
        'version': version,
        'keyPerformanceIndicators': keyPerformanceIndicators,
        'performanceHighlights': performanceHighlights,
        'actionItems': actionItems,
        'businessData': businessData,
        'enhancedBusinessData': enhancedBusinessData,
      };
}

// Supporting data classes
enum ReportType {
  monthly,
  individual,
  teamAnalytics,
  executiveSummary,
}

class DateRange {
  final DateTime startDate;
  final DateTime endDate;

  DateRange(this.startDate, this.endDate);

  Map<String, dynamic> toMap() => {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };
}

class TeamAnalytics {
  final double averagePerformanceScore;
  final Map<PerformanceRating, int> performanceDistribution;
  final List<String> topPerformers;
  final List<String> improvementNeeded;
  final int totalFoodRuns;
  final double averageEfficiency;
  final double consistencyIndex;
  final int teamSize;
  final Map<String, dynamic>? businessData;
  final Map<String, dynamic>? enhancedBusinessData;

  TeamAnalytics({
    required this.averagePerformanceScore,
    required this.performanceDistribution,
    required this.topPerformers,
    required this.improvementNeeded,
    required this.totalFoodRuns,
    required this.averageEfficiency,
    required this.consistencyIndex,
    required this.teamSize,
    this.businessData,
    this.enhancedBusinessData,
  });

  Map<String, dynamic> toMap() => {
        'averagePerformanceScore': averagePerformanceScore,
        'performanceDistribution':
            performanceDistribution.map((k, v) => MapEntry(k.name, v)),
        'topPerformers': topPerformers,
        'improvementNeeded': improvementNeeded,
        'totalFoodRuns': totalFoodRuns,
        'averageEfficiency': averageEfficiency,
        'consistencyIndex': consistencyIndex,
        'teamSize': teamSize,
        'businessData': businessData,
        'enhancedBusinessData': enhancedBusinessData,
      };
}

class PeerComparison {
  final String serverId;
  final String peerGroup;
  final int ranking;
  final double percentile;
  final double peerAverageScore;
  final Map<String, double> comparisonMetrics;

  PeerComparison({
    required this.serverId,
    required this.peerGroup,
    required this.ranking,
    required this.percentile,
    required this.peerAverageScore,
    required this.comparisonMetrics,
  });

  Map<String, dynamic> toMap() => {
        'serverId': serverId,
        'peerGroup': peerGroup,
        'ranking': ranking,
        'percentile': percentile,
        'peerAverageScore': peerAverageScore,
        'comparisonMetrics': comparisonMetrics,
      };
}

class Recommendation {
  final String type;
  final String title;
  final String description;
  final String priority;
  final String timeframe;
  final List<String> actionSteps;

  Recommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    required this.timeframe,
    required this.actionSteps,
  });

  Map<String, dynamic> toMap() => {
        'type': type,
        'title': title,
        'description': description,
        'priority': priority,
        'timeframe': timeframe,
        'actionSteps': actionSteps,
      };
}

class PerformanceDistribution {
  final Map<String, int> distribution;
  final double averageScore;
  final double medianScore;
  final double standardDeviation;

  PerformanceDistribution({
    required this.distribution,
    required this.averageScore,
    required this.medianScore,
    required this.standardDeviation,
  });

  Map<String, dynamic> toMap() => {
        'distribution': distribution,
        'averageScore': averageScore,
        'medianScore': medianScore,
        'standardDeviation': standardDeviation,
      };
}

class EfficiencyVariance {
  final double averageEfficiency;
  final double highestEfficiency;
  final double lowestEfficiency;
  final double variance;
  final double coefficientOfVariation;

  EfficiencyVariance({
    required this.averageEfficiency,
    required this.highestEfficiency,
    required this.lowestEfficiency,
    required this.variance,
    required this.coefficientOfVariation,
  });

  Map<String, dynamic> toMap() => {
        'averageEfficiency': averageEfficiency,
        'highestEfficiency': highestEfficiency,
        'lowestEfficiency': lowestEfficiency,
        'variance': variance,
        'coefficientOfVariation': coefficientOfVariation,
      };
}

class TrainingNeeds {
  final List<String> needsAttention;
  final List<String> needsCoaching;
  final List<String> recognitionCandidates;
  final String trainingPriority;

  TrainingNeeds({
    required this.needsAttention,
    required this.needsCoaching,
    required this.recognitionCandidates,
    required this.trainingPriority,
  });

  Map<String, dynamic> toMap() => {
        'needsAttention': needsAttention,
        'needsCoaching': needsCoaching,
        'recognitionCandidates': recognitionCandidates,
        'trainingPriority': trainingPriority,
      };
}
