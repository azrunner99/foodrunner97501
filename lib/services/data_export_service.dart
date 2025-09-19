import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/nps_score_feedback.dart';
import '../models/server.dart';
import 'advanced_analytics_service.dart';

/// Service for exporting NPS data and analytics to various formats
class DataExportService {
  /// Export NPS feedback data to CSV format
  static Future<String> exportFeedbackToCSV(
    List<NPSScoreFeedback> feedback,
    List<NPSServer> servers,
  ) async {
    final List<List<dynamic>> csvData = [];

    // Add header row
    csvData.add([
      'Feedback ID',
      'Server Name',
      'NPS Score',
      'Category',
      'Comment',
      'Submission Date',
      'Created Date',
    ]);

    // Create server lookup map
    final serverMap = <int, NPSServer>{};
    for (final server in servers) {
      if (server.id != null) {
        serverMap[server.id!] = server;
      }
    }

    // Add data rows
    for (final feedbackItem in feedback) {
      final server = serverMap[feedbackItem.serverId];
      csvData.add([
        feedbackItem.id,
        server?.name ?? 'Unknown Server',
        feedbackItem.score,
        _getNPSCategory(feedbackItem.score),
        feedbackItem.comment,
        _formatDate(feedbackItem.submissionDate),
        feedbackItem.createdAt != null
            ? _formatDate(feedbackItem.createdAt!)
            : 'N/A',
      ]);
    }

    return const ListToCsvConverter().convert(csvData);
  }

  /// Export server analytics summary to CSV format
  static Future<String> exportServerAnalyticsToCSV(
    List<NPSServer> servers,
    List<NPSScoreFeedback> feedback,
  ) async {
    final List<List<dynamic>> csvData = [];

    // Add header row
    csvData.add([
      'Server ID',
      'Server Name',
      'Hire Date',
      'Active Status',
      'Total Responses',
      'Promoters',
      'Passives',
      'Detractors',
      'NPS Score',
      'Average Score',
      'Latest Response Date',
    ]);

    // Calculate analytics for each server
    for (final server in servers) {
      final serverFeedback =
          feedback.where((f) => f.serverId == (server.id ?? 0)).toList();
      final analytics = _calculateServerAnalytics(serverFeedback);

      csvData.add([
        server.id ?? 'N/A',
        server.name,
        _formatDate(server.hireDate),
        server.active ? 'Active' : 'Inactive',
        analytics['totalResponses'],
        analytics['promoters'],
        analytics['passives'],
        analytics['detractors'],
        analytics['npsScore'],
        analytics['averageScore'],
        analytics['latestResponseDate'],
      ]);
    }

    return const ListToCsvConverter().convert(csvData);
  }

  /// Export comprehensive analytics report to CSV format
  static Future<String> exportComprehensiveAnalyticsToCSV(
    List<NPSServer> servers,
    List<NPSScoreFeedback> feedback, {
    int daysBack = 30,
  }) async {
    final List<List<dynamic>> csvData = [];
    final insights =
        AdvancedAnalyticsService.generateInsights(servers, feedback);

    // Add metadata section
    csvData.addAll([
      ['Comprehensive NPS Analytics Report'],
      ['Generated on:', DateTime.now().toIso8601String()],
      ['Date Range:', '$daysBack days back'],
      ['Total Servers:', servers.length],
      ['Total Responses:', feedback.length],
      [],
      ['Key Metrics'],
    ]);

    // Add key metrics
    insights.keyMetrics.forEach((key, value) {
      csvData.add([key, value]);
    });

    csvData.addAll([
      [],
      ['Server Performance Summary'],
      ['Server Name', 'NPS Score', 'Total Responses', 'Trend'],
    ]);

    // Add server performance data
    for (final server in servers) {
      final serverFeedback =
          feedback.where((f) => f.serverId == (server.id ?? 0)).toList();
      final analytics = _calculateServerAnalytics(serverFeedback);
      csvData.add([
        server.name,
        analytics['npsScore'],
        analytics['totalResponses'],
        _calculateTrend(serverFeedback, daysBack: 7),
      ]);
    }

    csvData.addAll([
      [],
      ['Insights'],
    ]);

    // Add insights
    for (final insight in insights.insights) {
      csvData.add(['Insight', insight]);
    }

    csvData.addAll([
      [],
      ['Recommendations'],
    ]);

    // Add recommendations
    for (final recommendation in insights.recommendations) {
      csvData.add(['Recommendation', recommendation]);
    }

    return const ListToCsvConverter().convert(csvData);
  }

  /// Export time-series data for trend analysis
  static Future<String> exportTimeSeriesDataToCSV(
    List<NPSScoreFeedback> feedback, {
    int daysBack = 30,
  }) async {
    final List<List<dynamic>> csvData = [];

    // Add header row
    csvData.add([
      'Date',
      'Day of Week',
      'Total Responses',
      'Promoters',
      'Passives',
      'Detractors',
      'NPS Score',
      'Average Score',
    ]);

    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: daysBack));

    // Group feedback by date
    final dailyData = <String, List<NPSScoreFeedback>>{};
    for (final feedbackItem in feedback) {
      if (feedbackItem.submissionDate.isAfter(startDate)) {
        final dateKey = _formatDate(feedbackItem.submissionDate);
        dailyData.putIfAbsent(dateKey, () => []).add(feedbackItem);
      }
    }

    // Generate daily analytics
    for (int i = 0; i < daysBack; i++) {
      final date = endDate.subtract(Duration(days: i));
      final dateKey = _formatDate(date);
      final dayFeedback = dailyData[dateKey] ?? [];
      final analytics = _calculateServerAnalytics(dayFeedback);

      csvData.add([
        dateKey,
        _getDayOfWeek(date),
        analytics['totalResponses'],
        analytics['promoters'],
        analytics['passives'],
        analytics['detractors'],
        analytics['npsScore'],
        analytics['averageScore'],
      ]);
    }

    return const ListToCsvConverter().convert(csvData);
  }

  /// Save CSV data to file and share it
  static Future<void> shareCSVFile(
    String csvContent,
    String fileName,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvContent);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'NPS Analytics Export',
        text: 'NPS analytics data export generated on ${DateTime.now()}',
      );
    } catch (e) {
      throw Exception('Failed to export CSV file: $e');
    }
  }

  /// Export all data types in a single archive
  static Future<void> exportCompleteDataset(
    List<NPSServer> servers,
    List<NPSScoreFeedback> feedback,
  ) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    try {
      // Generate all export files
      final feedbackCSV = await exportFeedbackToCSV(feedback, servers);
      final analyticsCSV = await exportServerAnalyticsToCSV(servers, feedback);
      final comprehensiveCSV =
          await exportComprehensiveAnalyticsToCSV(servers, feedback);
      final timeSeriesCSV = await exportTimeSeriesDataToCSV(feedback);

      // Save all files
      final directory = await getApplicationDocumentsDirectory();

      final files = <XFile>[];

      // Save feedback data
      final feedbackFile =
          File('${directory.path}/nps_feedback_$timestamp.csv');
      await feedbackFile.writeAsString(feedbackCSV);
      files.add(XFile(feedbackFile.path));

      // Save analytics summary
      final analyticsFile =
          File('${directory.path}/nps_analytics_$timestamp.csv');
      await analyticsFile.writeAsString(analyticsCSV);
      files.add(XFile(analyticsFile.path));

      // Save comprehensive report
      final comprehensiveFile =
          File('${directory.path}/nps_comprehensive_report_$timestamp.csv');
      await comprehensiveFile.writeAsString(comprehensiveCSV);
      files.add(XFile(comprehensiveFile.path));

      // Save time series data
      final timeSeriesFile =
          File('${directory.path}/nps_time_series_$timestamp.csv');
      await timeSeriesFile.writeAsString(timeSeriesCSV);
      files.add(XFile(timeSeriesFile.path));

      // Share all files
      await Share.shareXFiles(
        files,
        subject: 'Complete NPS Dataset Export',
        text: 'Complete NPS analytics dataset exported on ${DateTime.now()}',
      );
    } catch (e) {
      throw Exception('Failed to export complete dataset: $e');
    }
  }

  // Helper methods
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String _getDayOfWeek(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  static String _getNPSCategory(int score) {
    if (score >= 9) return 'Promoter';
    if (score >= 7) return 'Passive';
    return 'Detractor';
  }

  static Map<String, dynamic> _calculateServerAnalytics(
      List<NPSScoreFeedback> feedback) {
    if (feedback.isEmpty) {
      return {
        'totalResponses': 0,
        'promoters': 0,
        'passives': 0,
        'detractors': 0,
        'npsScore': 0.0,
        'averageScore': 0.0,
        'latestResponseDate': 'No responses',
      };
    }

    final promoters = feedback.where((f) => f.score >= 9).length;
    final passives = feedback.where((f) => f.score >= 7 && f.score <= 8).length;
    final detractors = feedback.where((f) => f.score <= 6).length;

    final npsScore = ((promoters - detractors) / feedback.length) * 100;
    final averageScore =
        feedback.map((f) => f.score).reduce((a, b) => a + b) / feedback.length;

    feedback.sort((a, b) => b.submissionDate.compareTo(a.submissionDate));
    final latestResponseDate = _formatDate(feedback.first.submissionDate);

    return {
      'totalResponses': feedback.length,
      'promoters': promoters,
      'passives': passives,
      'detractors': detractors,
      'npsScore': npsScore.toStringAsFixed(1),
      'averageScore': averageScore.toStringAsFixed(1),
      'latestResponseDate': latestResponseDate,
    };
  }

  static String _calculateTrend(List<NPSScoreFeedback> feedback,
      {int daysBack = 7}) {
    if (feedback.length < 2) return 'Insufficient data';

    final now = DateTime.now();
    final recentFeedback = feedback
        .where((f) =>
            f.submissionDate.isAfter(now.subtract(Duration(days: daysBack))))
        .toList();

    final olderFeedback = feedback
        .where((f) =>
            f.submissionDate.isBefore(now.subtract(Duration(days: daysBack))) &&
            f.submissionDate
                .isAfter(now.subtract(Duration(days: daysBack * 2))))
        .toList();

    if (recentFeedback.isEmpty || olderFeedback.isEmpty)
      return 'Insufficient data';

    final recentNPS = _calculateServerAnalytics(recentFeedback)['npsScore'];
    final olderNPS = _calculateServerAnalytics(olderFeedback)['npsScore'];

    final recentScore = double.tryParse(recentNPS.toString()) ?? 0;
    final olderScore = double.tryParse(olderNPS.toString()) ?? 0;

    final change = recentScore - olderScore;

    if (change > 5) return 'Improving';
    if (change < -5) return 'Declining';
    return 'Stable';
  }
}
