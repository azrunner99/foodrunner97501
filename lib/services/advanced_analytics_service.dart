import 'package:flutter/material.dart';
import '../models/nps_score_feedback.dart';
import '../models/server.dart';
import 'package:fl_chart/fl_chart.dart';

/// Advanced analytics service for NPS system
/// Provides comprehensive data analysis and chart data preparation
class AdvancedAnalyticsService {
  /// Calculate NPS trend data over time for line charts
  static List<FlSpot> calculateNPSTrend(List<NPSScoreFeedback> feedback,
      {int daysBack = 30}) {
    final now = DateTime.now();
    final cutoffDate = now.subtract(Duration(days: daysBack));

    // Filter feedback within date range
    final recentFeedback =
        feedback.where((f) => f.submissionDate.isAfter(cutoffDate)).toList();

    // Group by day and calculate daily NPS
    final Map<DateTime, List<NPSScoreFeedback>> dailyFeedback = {};

    for (final feedback in recentFeedback) {
      final day = DateTime(
        feedback.submissionDate.year,
        feedback.submissionDate.month,
        feedback.submissionDate.day,
      );

      dailyFeedback.putIfAbsent(day, () => []).add(feedback);
    }

    // Calculate NPS for each day
    final List<FlSpot> spots = [];
    final sortedDays = dailyFeedback.keys.toList()..sort();

    for (int i = 0; i < sortedDays.length; i++) {
      final day = sortedDays[i];
      final dayFeedback = dailyFeedback[day]!;
      final npsScore = _calculateNPSScore(dayFeedback);

      spots.add(FlSpot(i.toDouble(), npsScore));
    }

    return spots;
  }

  /// Calculate score distribution for pie charts
  static List<PieChartSectionData> calculateScoreDistribution(
      List<NPSScoreFeedback> feedback) {
    if (feedback.isEmpty) {
      return [
        PieChartSectionData(
          color: Colors.grey,
          value: 100,
          title: 'No Data',
          radius: 60,
        ),
      ];
    }

    int promoters = 0;
    int passives = 0;
    int detractors = 0;

    for (final f in feedback) {
      if (f.score >= 9) {
        promoters++;
      } else if (f.score >= 7) {
        passives++;
      } else {
        detractors++;
      }
    }

    final total = feedback.length;
    final List<PieChartSectionData> sections = [];

    if (promoters > 0) {
      sections.add(PieChartSectionData(
        color: Colors.green,
        value: (promoters / total) * 100,
        title: 'Promoters\n$promoters',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
    }

    if (passives > 0) {
      sections.add(PieChartSectionData(
        color: Colors.orange,
        value: (passives / total) * 100,
        title: 'Passives\n$passives',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
    }

    if (detractors > 0) {
      sections.add(PieChartSectionData(
        color: Colors.red,
        value: (detractors / total) * 100,
        title: 'Detractors\n$detractors',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
    }

    return sections;
  }

  /// Calculate server comparison data for bar charts
  static List<BarChartGroupData> calculateServerComparison(
    List<NPSServer> servers,
    List<NPSScoreFeedback> feedback,
  ) {
    final List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < servers.length; i++) {
      final server = servers[i];
      final serverFeedback =
          feedback.where((f) => f.serverId == server.id).toList();
      final npsScore = _calculateNPSScore(serverFeedback);

      final color = npsScore >= 50
          ? Colors.green
          : npsScore >= 0
              ? Colors.orange
              : Colors.red;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: npsScore.abs(), // Use absolute value for display
              color: color,
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return barGroups;
  }

  /// Get server performance rankings
  static List<ServerPerformanceData> getServerRankings(
    List<NPSServer> servers,
    List<NPSScoreFeedback> feedback,
  ) {
    final List<ServerPerformanceData> rankings = [];

    for (final server in servers) {
      final serverFeedback =
          feedback.where((f) => f.serverId == server.id).toList();
      final npsScore = _calculateNPSScore(serverFeedback);
      final responseCount = serverFeedback.length;

      rankings.add(ServerPerformanceData(
        server: server,
        npsScore: npsScore,
        responseCount: responseCount,
        averageScore: serverFeedback.isEmpty
            ? 0
            : serverFeedback.map((f) => f.score).reduce((a, b) => a + b) /
                serverFeedback.length,
      ));
    }

    // Sort by NPS score descending
    rankings.sort((a, b) => b.npsScore.compareTo(a.npsScore));

    return rankings;
  }

  /// Calculate monthly performance trends
  static Map<String, double> getMonthlyTrends(List<NPSScoreFeedback> feedback) {
    final Map<String, List<NPSScoreFeedback>> monthlyFeedback = {};

    for (final f in feedback) {
      final monthKey =
          '${f.submissionDate.year}-${f.submissionDate.month.toString().padLeft(2, '0')}';
      monthlyFeedback.putIfAbsent(monthKey, () => []).add(f);
    }

    final Map<String, double> monthlyNPS = {};
    monthlyFeedback.forEach((month, feedback) {
      monthlyNPS[month] = _calculateNPSScore(feedback);
    });

    return monthlyNPS;
  }

  /// Get insights and recommendations
  static AnalyticsInsights generateInsights(
    List<NPSServer> servers,
    List<NPSScoreFeedback> feedback,
  ) {
    final overallNPS = _calculateNPSScore(feedback);
    final rankings = getServerRankings(servers, feedback);
    final trends = getMonthlyTrends(feedback);

    final List<String> insights = [];
    final List<String> recommendations = [];

    // Overall performance insights
    if (overallNPS >= 50) {
      insights.add(
          'Excellent overall NPS score of ${overallNPS.toStringAsFixed(1)}');
    } else if (overallNPS >= 0) {
      insights.add(
          'Room for improvement with NPS score of ${overallNPS.toStringAsFixed(1)}');
      recommendations.add('Focus on converting passives to promoters');
    } else {
      insights.add(
          'Critical: Negative NPS score of ${overallNPS.toStringAsFixed(1)}');
      recommendations
          .add('Immediate action needed to address detractor concerns');
    }

    // Server performance insights
    if (rankings.isNotEmpty) {
      final topServer = rankings.first;
      final bottomServer = rankings.last;

      if (topServer.npsScore - bottomServer.npsScore > 20) {
        insights.add('Significant performance gap between servers');
        recommendations.add(
            'Share best practices from ${topServer.server.name} with other servers');
      }
    }

    // Response volume insights
    final responseCount = feedback.length;
    if (responseCount < 10) {
      insights.add('Low response volume: $responseCount total responses');
      recommendations.add('Increase feedback collection efforts');
    }

    return AnalyticsInsights(
      insights: insights,
      recommendations: recommendations,
      keyMetrics: {
        'Overall NPS': overallNPS,
        'Total Responses': responseCount.toDouble(),
        'Active Servers': servers.length.toDouble(),
      },
    );
  }

  /// Helper method to calculate NPS score from feedback list
  static double _calculateNPSScore(List<NPSScoreFeedback> feedback) {
    if (feedback.isEmpty) return 0.0;

    int promoters = 0;
    int detractors = 0;

    for (final f in feedback) {
      if (f.score >= 9) {
        promoters++;
      } else if (f.score <= 6) {
        detractors++;
      }
    }

    final promoterPercentage = (promoters / feedback.length) * 100;
    final detractorPercentage = (detractors / feedback.length) * 100;

    return promoterPercentage - detractorPercentage;
  }
}

/// Data class for server performance metrics
class ServerPerformanceData {
  final NPSServer server;
  final double npsScore;
  final int responseCount;
  final double averageScore;

  const ServerPerformanceData({
    required this.server,
    required this.npsScore,
    required this.responseCount,
    required this.averageScore,
  });
}

/// Data class for analytics insights
class AnalyticsInsights {
  final List<String> insights;
  final List<String> recommendations;
  final Map<String, double> keyMetrics;

  const AnalyticsInsights({
    required this.insights,
    required this.recommendations,
    required this.keyMetrics,
  });
}
