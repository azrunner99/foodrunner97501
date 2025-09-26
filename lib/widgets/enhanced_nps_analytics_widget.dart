import 'package:flutter/material.dart';
import '../utils/log.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/nps_provider.dart';
import '../services/advanced_analytics_service.dart';
import '../services/nps_filter_service.dart';
import '../services/nps_benchmarking_service.dart';
import '../models/nps_score_feedback.dart';
import '../models/monthly_report.dart';
import '../storage/nps_database.dart';
import '../storage/database_factory.dart';
import 'secured_nps_widgets.dart';
import '../screens/nps_benchmarking_screen.dart';
import '../services/historical_nps_aggregation_service.dart';
import '../services/performance_timeline_service.dart';
import '../services/intelligent_performance_classifier.dart';
import '../services/advanced_trend_analysis_service.dart' as trend_analysis;
import '../models/historical_nps_data.dart';
import '../models/performance_models.dart' as performance_models;

/// Enhanced analytics dashboard with charts and visualizations
class EnhancedNPSAnalyticsWidget extends StatefulWidget {
  const EnhancedNPSAnalyticsWidget({super.key});

  @override
  State<EnhancedNPSAnalyticsWidget> createState() =>
      _EnhancedNPSAnalyticsWidgetState();
}

class _EnhancedNPSAnalyticsWidgetState
    extends State<EnhancedNPSAnalyticsWidget> {
  int _selectedTimeRange = 30; // Days
  String _selectedChartType = 'trend';
  
  // Historical analytics state
  List<HistoricalNPSData> _historicalData = [];
  List<PerformanceTimeline> _timelines = [];
  bool _isLoadingHistorical = false;
  String _selectedServerId = '';
  Map<String, performance_models.PerformanceClassification> _serverClassifications = {};
  Map<String, trend_analysis.AdvancedTrendAnalysis> _serverTrendAnalyses = {};

  @override
  void initState() {
    super.initState();
    _loadHistoricalData();
  }

  Future<void> _loadHistoricalData() async {
    setState(() {
      _isLoadingHistorical = true;
    });

    try {
      d('[EnhancedNPSAnalyticsWidget] Loading historical data...');

      // Load historical data for all servers
      final historicalData = await HistoricalNPSAggregationService.instance.getAllHistoricalData();

      // Load performance timelines
      final timelines = await PerformanceTimelineService.instance.getAllTimelines();

      // Load intelligent performance classifications and trend analyses
      final classifications = <String, performance_models.PerformanceClassification>{};
      final trendAnalyses = <String, trend_analysis.AdvancedTrendAnalysis>{};
      
      for (final data in historicalData) {
        // Get monthly reports for this server
        final monthlyReports = await _getMonthlyReportsForServer(data.serverId);
        
        // Classify performance
        final classification = IntelligentPerformanceClassifier().classifyServerPerformance(
          monthlyReports: monthlyReports,
          serverName: data.serverName,
          serverId: int.parse(data.serverId),
        );
        
        // Analyze trends
        final trendAnalysis = trend_analysis.AdvancedTrendAnalysisService().analyzeServerTrends(
          monthlyReports: monthlyReports,
          serverName: data.serverName,
          serverId: int.parse(data.serverId),
        );
        
        classifications[data.serverId] = classification;
        trendAnalyses[data.serverId] = trendAnalysis;
      }

      setState(() {
        _historicalData = historicalData;
        _timelines = timelines;
        _serverClassifications = classifications;
        _serverTrendAnalyses = trendAnalyses;
        _isLoadingHistorical = false;
      });

      d('[EnhancedNPSAnalyticsWidget] Loaded ${historicalData.length} servers with historical data and classifications');
    } catch (e) {
      d('[EnhancedNPSAnalyticsWidget] Error loading historical data: $e');
      setState(() {
        _isLoadingHistorical = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SecuredAnalyticsWidget(
      child: Consumer<NPSProvider>(
        builder: (context, npsProvider, child) {
          if (npsProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading analytics...'),
                ],
              ),
            );
          }

          // Load real monthly reports from database
          return FutureBuilder<List<NPSMonthlyReport>>(
            future: _loadMonthlyReports(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading NPS reports...'),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 48, color: Colors.red),
                      SizedBox(height: 16),
                      Text('Error loading reports: ${snapshot.error}'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final monthlyReports = snapshot.data ?? [];

              if (monthlyReports.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics_outlined,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No NPS Data Available',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Enter monthly NPS data to see analytics',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                );
              }

              return Consumer2<NPSFilterService, NPSBenchmarkingService>(
                builder: (context, filterService, benchmarkService, child) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 20),
                        // Monthly Reports Summary
                        _buildMonthlyReportsSummary(monthlyReports),
                        const SizedBox(height: 20),
                        // Key Metrics from Monthly Reports
                        _buildKeyMetricsFromReports(monthlyReports),
                        const SizedBox(height: 20),
                        // Historical Analytics Section
                        _buildHistoricalAnalyticsSection(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Load all available monthly reports from database
  Future<List<NPSMonthlyReport>> _loadMonthlyReports() async {
    try {
      d('[EnhancedNPSAnalyticsWidget] Starting to load monthly reports...');
      
      // Use the database factory to get the correct database instance
      final db = DatabaseFactory.instance;
      d('[EnhancedNPSAnalyticsWidget] Database factory type: ${DatabaseFactory.implementationType}');
      
      List<Map<String, dynamic>> reportMaps;
      
      // Handle different database schemas
      final dbType = DatabaseFactory.implementationType;
      d('[EnhancedNPSAnalyticsWidget] Detected database type: $dbType');
      
      if (dbType.contains('Sqflite')) {
        // Sqflite uses month_year column (YYYYMM format)
        d('[EnhancedNPSAnalyticsWidget] Using Sqflite schema with month_year column');
        reportMaps = await db.queryTable(
          'nps_monthly_reports',
          orderBy: 'month_year DESC',
        );
      } else {
        // Drift uses separate report_month and report_year columns
        d('[EnhancedNPSAnalyticsWidget] Using Drift schema with report_month and report_year columns');
        reportMaps = await db.queryTable(
        'nps_monthly_reports',
        orderBy: 'report_year DESC, report_month DESC',
      );
      }
      
      d('[EnhancedNPSAnalyticsWidget] Loaded ${reportMaps.length} monthly reports');
      
      if (reportMaps.isNotEmpty) {
        d('[EnhancedNPSAnalyticsWidget] First report: ${reportMaps.first}');
      }
      
      final reports = reportMaps.map((map) => NPSMonthlyReport.fromMap(map)).toList();
      
      // Debug: Log the actual reports to see what we're getting
      d('[EnhancedNPSAnalyticsWidget] Loaded ${reports.length} total reports');
      
      return reports;
    } catch (e) {
  d('[EnhancedNPSAnalyticsWidget] Error loading monthly reports: $e');
      rethrow;
    }
  }

  /// Build summary widget for monthly reports
  Widget _buildMonthlyReportsSummary(List<NPSMonthlyReport> reports) {
    if (reports.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('No monthly reports available'),
        ),
      );
    }

    // Calculate aggregate metrics
    // Group reports by server to get unique servers
    final serverReports = <int, List<NPSMonthlyReport>>{};
    for (final report in reports) {
      serverReports.putIfAbsent(report.serverId, () => []).add(report);
    }
    
    final totalServers = serverReports.length;
    
    // Calculate average all-time NPS per server, then average those
    final serverAverages = <double>[];
    for (final serverReportList in serverReports.values) {
      // Get the most recent report for this server (highest month/year)
      final mostRecentReport = serverReportList.reduce((a, b) {
        if (a.reportYear > b.reportYear) return a;
        if (a.reportYear < b.reportYear) return b;
        return a.reportMonth > b.reportMonth ? a : b;
      });
      
      if (mostRecentReport.allTimeNpsPercentage != null) {
        serverAverages.add(mostRecentReport.allTimeNpsPercentage!);
      }
    }
    
    final avgNPS = serverAverages.isEmpty 
        ? 0.0 
        : serverAverages.reduce((a, b) => a + b) / serverAverages.length;
    // Calculate total sales and checks from most recent report per server
    double totalSales = 0.0;
    int totalChecks = 0;
    for (final serverReportList in serverReports.values) {
      final mostRecentReport = serverReportList.reduce((a, b) {
        if (a.reportYear > b.reportYear) return a;
        if (a.reportYear < b.reportYear) return b;
        return a.reportMonth > b.reportMonth ? a : b;
      });
      totalSales += mostRecentReport.allTimeSales;
      totalChecks += mostRecentReport.allTimeTableCount;
    }

    // Get unique months represented in the data
    final months = reports.map((r) => r.reportMonth % 100).toSet().toList()
      ..sort(); // Extract month from YYYYMM
    final monthNames = months.map((m) => _getMonthName(m)).join(', ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly NPS Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Data from: $monthNames',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryMetric(
                      'Servers Reporting', totalServers.toString()),
                ),
                Expanded(
                  child: _buildSummaryMetric(
                      'Average NPS', '${avgNPS.toStringAsFixed(1)}%'),
                ),
                Expanded(
                  child: _buildSummaryMetric(
                      'Total Sales', '\$${totalSales.toStringAsFixed(0)}'),
                ),
                Expanded(
                  child: _buildSummaryMetric(
                      'Total Checks', totalChecks.toString()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return monthNames[month];
  }

  Widget _buildSummaryMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  /// Count unique months across all reports
  int _getUniqueMonthsCount(List<NPSMonthlyReport> reports) {
    final uniqueMonths = <String>{};
    for (final report in reports) {
      final monthKey = '${report.reportYear}-${report.reportMonth.toString().padLeft(2, '0')}';
      uniqueMonths.add(monthKey);
    }
    return uniqueMonths.length;
  }

  /// Get monthly reports for a specific server
  Future<List<NPSMonthlyReport>> _getMonthlyReportsForServer(String serverId) async {
    try {
      final database = DatabaseFactory.instance;
      final isSqflite = database.runtimeType.toString().contains('Sqflite');
      
      final results = await database.queryTable(
        'nps_monthly_reports',
        where: 'server_id = ?',
        whereArgs: [int.parse(serverId)],
        orderBy: isSqflite ? 'month_year DESC' : 'report_year DESC, report_month DESC',
      );
      
      return results.map((row) => NPSMonthlyReport.fromMap(row)).toList();
    } catch (e) {
      d('[EnhancedNPSAnalyticsWidget] Error loading monthly reports for server $serverId: $e');
      return [];
    }
  }





  /// Build advanced trend analysis section
  Widget _buildAdvancedTrendAnalysis() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.indigo.shade600),
                const SizedBox(width: 8),
                Text(
                  'Advanced Trend Analysis',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade800,
                    fontSize: 24, // Increased font size
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.indigo.shade300),
                  ),
                  child: Text(
                    'Phase 3',
                    style: TextStyle(
                      color: Colors.indigo.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Sophisticated trend analysis with velocity tracking, strength measurement, and predictive insights.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
                fontSize: 16, // Increased font size
              ),
            ),
            const SizedBox(height: 16),
            if (_serverTrendAnalyses.isEmpty)
              _buildNoTrendAnalysisMessage()
            else
              Column(
                children: [
                  _buildTrendAnalysisSummary(),
                  const SizedBox(height: 16),
                  _buildDetailedTrendAnalyses(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Build message when no trend analyses are available
  Widget _buildNoTrendAnalysisMessage() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.trending_up, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Trend Analysis Available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Enter monthly NPS data to enable advanced trend analysis',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build trend analysis summary
  Widget _buildTrendAnalysisSummary() {
    final trendCounts = <trend_analysis.TrendDirection, int>{};
    final momentumCounts = <trend_analysis.MomentumType, int>{};
    
    for (final analysis in _serverTrendAnalyses.values) {
      trendCounts[analysis.trendDirection] = (trendCounts[analysis.trendDirection] ?? 0) + 1;
      momentumCounts[analysis.momentum] = (momentumCounts[analysis.momentum] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trend Distribution',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18, // Increased font size
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTrendSummaryItem(
                  trend_analysis.TrendDirection.stronglyImproving,
                  trendCounts[trend_analysis.TrendDirection.stronglyImproving] ?? 0,
                  _serverTrendAnalyses.length,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTrendSummaryItem(
                  trend_analysis.TrendDirection.improving,
                  trendCounts[trend_analysis.TrendDirection.improving] ?? 0,
                  _serverTrendAnalyses.length,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTrendSummaryItem(
                  trend_analysis.TrendDirection.stable,
                  trendCounts[trend_analysis.TrendDirection.stable] ?? 0,
                  _serverTrendAnalyses.length,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTrendSummaryItem(
                  trend_analysis.TrendDirection.declining,
                  trendCounts[trend_analysis.TrendDirection.declining] ?? 0,
                  _serverTrendAnalyses.length,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTrendSummaryItem(
                  trend_analysis.TrendDirection.stronglyDeclining,
                  trendCounts[trend_analysis.TrendDirection.stronglyDeclining] ?? 0,
                  _serverTrendAnalyses.length,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTrendSummaryItem(
                  trend_analysis.TrendDirection.unknown,
                  trendCounts[trend_analysis.TrendDirection.unknown] ?? 0,
                  _serverTrendAnalyses.length,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build trend summary item
  Widget _buildTrendSummaryItem(trend_analysis.TrendDirection trend, int count, int total) {
    final percentage = total > 0 ? (count / total * 100).round() : 0;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getAdvancedTrendColor(trend).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getAdvancedTrendColor(trend).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                trend.emoji,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 4),
              Text(
                trend.displayName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getAdvancedTrendColor(trend),
                  fontSize: 14, // Increased font size
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$count ($percentage%)',
            style: TextStyle(
              fontSize: 16, // Increased font size
              fontWeight: FontWeight.bold,
              color: _getAdvancedTrendColor(trend),
            ),
          ),
        ],
      ),
    );
  }

  /// Build detailed trend analyses
  Widget _buildDetailedTrendAnalyses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Trend Analysis',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18, // Increased font size
          ),
        ),
        const SizedBox(height: 12),
        ..._serverTrendAnalyses.entries.map((entry) => 
          _buildTrendAnalysisCard(entry.key, entry.value)
        ),
      ],
    );
  }

  /// Build individual trend analysis card
  Widget _buildTrendAnalysisCard(String serverId, trend_analysis.AdvancedTrendAnalysis analysis) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getAdvancedTrendColor(analysis.trendDirection).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getAdvancedTrendColor(analysis.trendDirection).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                analysis.trendDirection.emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  analysis.serverName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18, // Increased font size
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getAdvancedTrendColor(analysis.trendDirection).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  analysis.trendDirection.displayName,
                  style: TextStyle(
                    color: _getAdvancedTrendColor(analysis.trendDirection),
                    fontWeight: FontWeight.bold,
                    fontSize: 14, // Increased font size
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTrendMetric(
                  'Strength',
                  '${analysis.trendStrength.toStringAsFixed(1)}%',
                  _getTrendStrengthColor(analysis.trendStrength),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTrendMetric(
                  'Velocity',
                  '${analysis.trendVelocity.toStringAsFixed(1)}/mo',
                  _getVelocityColor(analysis.trendVelocity),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTrendMetric(
                  'Confidence',
                  '${analysis.trendConfidence.toStringAsFixed(1)}%',
                  _getConfidenceColor(analysis.trendConfidence),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTrendMetric(
                  'Momentum',
                  analysis.momentum.displayName,
                  _getMomentumColor(analysis.momentum),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTrendMetric(
                  'Persistence',
                  '${analysis.trendPersistence}mo',
                  _getPersistenceColor(analysis.trendPersistence),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTrendMetric(
                  'Volatility',
                  '${analysis.volatility.toStringAsFixed(1)}',
                  _getAdvancedVolatilityColor(analysis.volatility),
                ),
              ),
            ],
          ),
          if (analysis.projectedPerformance != null) ...[
            const SizedBox(height: 12),
            _buildProjectedPerformance(analysis.projectedPerformance!),
          ],
          const SizedBox(height: 12),
          Text(
            'Key Insights:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14, // Increased font size
            ),
          ),
          const SizedBox(height: 4),
          ...analysis.trendInsights.take(2).map((insight) => 
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 2),
              child: Text(
                '• $insight',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13, // Increased font size
                ),
              ),
            ),
          ),
          if (analysis.trendRecommendations.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Recommendations:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14, // Increased font size
              ),
            ),
            const SizedBox(height: 4),
            ...analysis.trendRecommendations.take(2).map((rec) => 
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Text(
                  '• $rec',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13, // Increased font size
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build trend metric
  Widget _buildTrendMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16, // Increased font size
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12, // Increased font size
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build projected performance
  Widget _buildProjectedPerformance(trend_analysis.ProjectedPerformance projection) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Projected Performance',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14, // Increased font size
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '3 months: ${projection.projected3Month.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 14), // Increased font size
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  '6 months: ${projection.projected6Month.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 14), // Increased font size
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Confidence: ${projection.confidence.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12, // Increased font size
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// Get advanced trend color
  Color _getAdvancedTrendColor(trend_analysis.TrendDirection trend) {
    switch (trend) {
      case trend_analysis.TrendDirection.stronglyImproving:
        return Colors.green;
      case trend_analysis.TrendDirection.improving:
        return Colors.lightGreen;
      case trend_analysis.TrendDirection.stable:
        return Colors.blue;
      case trend_analysis.TrendDirection.declining:
        return Colors.orange;
      case trend_analysis.TrendDirection.stronglyDeclining:
        return Colors.red;
      case trend_analysis.TrendDirection.unknown:
        return Colors.grey;
    }
  }

  /// Get trend strength color
  Color _getTrendStrengthColor(double strength) {
    if (strength >= 80) return Colors.green;
    if (strength >= 60) return Colors.lightGreen;
    if (strength >= 40) return Colors.orange;
    return Colors.red;
  }

  /// Get velocity color
  Color _getVelocityColor(double velocity) {
    if (velocity > 1.0) return Colors.green;
    if (velocity > 0.1) return Colors.lightGreen;
    if (velocity > -0.1) return Colors.blue;
    if (velocity > -1.0) return Colors.orange;
    return Colors.red;
  }

  /// Get momentum color
  Color _getMomentumColor(trend_analysis.MomentumType momentum) {
    switch (momentum) {
      case trend_analysis.MomentumType.strongPositive:
        return Colors.green;
      case trend_analysis.MomentumType.positive:
        return Colors.lightGreen;
      case trend_analysis.MomentumType.weakPositive:
        return Colors.blue;
      case trend_analysis.MomentumType.neutral:
        return Colors.grey;
      case trend_analysis.MomentumType.weakNegative:
        return Colors.orange;
      case trend_analysis.MomentumType.negative:
        return Colors.deepOrange;
      case trend_analysis.MomentumType.strongNegative:
        return Colors.red;
    }
  }

  /// Get persistence color
  Color _getPersistenceColor(int persistence) {
    if (persistence >= 6) return Colors.green;
    if (persistence >= 3) return Colors.blue;
    return Colors.orange;
  }

  /// Get advanced volatility color
  Color _getAdvancedVolatilityColor(double volatility) {
    if (volatility <= 1.0) return Colors.green;
    if (volatility <= 3.0) return Colors.blue;
    if (volatility <= 5.0) return Colors.orange;
    return Colors.red;
  }

  /// Convert historical TrendDirection to advanced TrendDirection
  trend_analysis.TrendDirection _convertToAdvancedTrendDirection(TrendDirection direction) {
    switch (direction) {
      case TrendDirection.improving:
        return trend_analysis.TrendDirection.improving;
      case TrendDirection.declining:
        return trend_analysis.TrendDirection.declining;
      case TrendDirection.stable:
        return trend_analysis.TrendDirection.stable;
      case TrendDirection.volatile:
        return trend_analysis.TrendDirection.unknown; // Map volatile to unknown
    }
  }

  /// Build key metrics from monthly reports
  Widget _buildKeyMetricsFromReports(List<NPSMonthlyReport> reports) {
    // Debug: Log what we're actually displaying
    d('[EnhancedNPSAnalyticsWidget] Displaying metrics for ${reports.length} total reports, ${_getUniqueMonthsCount(reports)} unique months');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text('Based on ${_getUniqueMonthsCount(reports)} unique months of data'),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.analytics,
          color: Colors.orange.shade600,
          size: 32,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Advanced Analytics',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                'Comprehensive NPS performance insights',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            context.read<NPSProvider>().initialize();
          },
          tooltip: 'Refresh data',
        ),
      ],
    );
  }

  Widget _buildTimeRangeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time Range',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [7, 30, 90, 365].map((days) {
                final isSelected = _selectedTimeRange == days;
                return ChoiceChip(
                  label: Text('${days}d'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedTimeRange = days;
                      });
                    }
                  },
                  selectedColor: Colors.orange.shade100,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.orange.shade800 : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetricsCards(AnalyticsInsights insights) {
    return Row(
      children: insights.keyMetrics.entries.map((entry) {
        return Expanded(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    entry.value.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: entry.key == 'Overall NPS'
                          ? _getNPSColor(entry.value)
                          : Colors.orange.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChartSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chart Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                {'key': 'trend', 'label': 'Trend', 'icon': Icons.trending_up},
                {
                  'key': 'distribution',
                  'label': 'Distribution',
                  'icon': Icons.pie_chart
                },
                {
                  'key': 'comparison',
                  'label': 'Server Comparison',
                  'icon': Icons.bar_chart
                },
              ].map((chart) {
                final isSelected = _selectedChartType == chart['key'];
                return ChoiceChip(
                  avatar: Icon(
                    chart['icon'] as IconData,
                    size: 18,
                    color: isSelected ? Colors.orange.shade800 : null,
                  ),
                  label: Text(chart['label'] as String),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedChartType = chart['key'] as String;
                      });
                    }
                  },
                  selectedColor: Colors.orange.shade100,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.orange.shade800 : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedChart(
      List<NPSScoreFeedback> feedback, List<dynamic> servers) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 300,
          child: _getChartWidget(feedback, servers),
        ),
      ),
    );
  }

  Widget _getChartWidget(
      List<NPSScoreFeedback> feedback, List<dynamic> servers) {
    switch (_selectedChartType) {
      case 'trend':
        return _buildTrendChart(feedback);
      case 'distribution':
        return _buildDistributionChart(feedback);
      case 'comparison':
        return _buildComparisonChart(feedback, servers);
      default:
        return _buildTrendChart(feedback);
    }
  }

  Widget _buildTrendChart(List<NPSScoreFeedback> feedback) {
    final spots = AdvancedAnalyticsService.calculateNPSTrend(feedback,
        daysBack: _selectedTimeRange);

    if (spots.isEmpty) {
      return const Center(
        child: Text(
          'No data available for the selected time range',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 20,
          verticalInterval: 5,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: spots.length > 10 ? spots.length / 5 : 1,
              getTitlesWidget: (value, meta) {
                return Text(
                  'Day ${value.toInt() + 1}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 20,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.orange.shade600,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: Colors.orange.shade100,
            ),
            dotData: const FlDotData(show: true),
          ),
        ],
        minY: -100,
        maxY: 100,
      ),
    );
  }

  Widget _buildDistributionChart(List<NPSScoreFeedback> feedback) {
    final sections =
        AdvancedAnalyticsService.calculateScoreDistribution(feedback);

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 60,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildComparisonChart(
      List<NPSScoreFeedback> feedback, List<dynamic> servers) {
    if (servers.isEmpty) {
      return const Center(
        child: Text(
          'No servers available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Create sample bar data since we need to adapt to the existing server structure
    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < servers.length && i < 5; i++) {
      final sampleNPS = 20 + (i * 15) + (i.isEven ? 10 : -5); // Sample data
      final color = sampleNPS >= 50
          ? Colors.green
          : sampleNPS >= 0
              ? Colors.orange
              : Colors.red;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: sampleNPS.abs().toDouble(),
              color: color,
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < servers.length) {
                  final serverName =
                      servers[index].toString().split('(')[0]; // Extract name
                  return Text(
                    serverName.length > 8
                        ? '${serverName.substring(0, 8)}...'
                        : serverName,
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildInsightsPanel(AnalyticsInsights insights) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Colors.orange.shade600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Insights & Recommendations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (insights.insights.isNotEmpty) ...[
              const Text(
                'Key Insights:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...insights.insights.map((insight) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.analytics,
                          size: 16,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(insight)),
                      ],
                    ),
                  )),
            ],
            if (insights.recommendations.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Recommendations:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...insights.recommendations.map((recommendation) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.orange.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(recommendation)),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }




  /// Calculate a comprehensive performance score for a server
  Map<String, dynamic> _calculateServerPerformanceScore(
      NPSMonthlyReport report) {
    final oneMonth = report.oneMonthNpsPercentage ?? 0.0;
    final threeMonth = report.threeMonthNpsPercentage ?? 0.0;
    final allTime = report.allTimeNpsPercentage ?? 0.0;

    const double performanceBenchmark =
        80.0; // Industry standard for acceptable performance

    // Calculate performance level relative to 80% benchmark
    String performanceLevel;
    Color performanceColor;
    double performanceMultiplier;

    final recentPerformance = oneMonth > 0 ? oneMonth : allTime;

    if (recentPerformance >= 90.0) {
      performanceLevel = 'Exceptional';
      performanceColor = Colors.green.shade700;
      performanceMultiplier = 1.25;
    } else if (recentPerformance >= performanceBenchmark) {
      performanceLevel = 'Above Standard';
      performanceColor = Colors.green;
      performanceMultiplier = 1.1;
    } else if (recentPerformance >= 70.0) {
      performanceLevel = 'Below Standard';
      performanceColor = Colors.orange;
      performanceMultiplier = 0.9;
    } else if (recentPerformance >= 50.0) {
      performanceLevel = 'Needs Improvement';
      performanceColor = Colors.red;
      performanceMultiplier = 0.7;
    } else {
      performanceLevel = 'Critical';
      performanceColor = Colors.red.shade700;
      performanceMultiplier = 0.5;
    }

    // Calculate trend analysis with 80% benchmark in mind
    String trend;
    String trendIcon;
    double trendMultiplier;

    // Determine trend based on progression toward/away from 80% benchmark
    if (oneMonth > 0 && threeMonth > 0) {
      if (oneMonth > threeMonth && oneMonth >= performanceBenchmark) {
        trend = 'Improving & Above Standard';
        trendIcon = '🌟';
        trendMultiplier = 1.2;
      } else if (oneMonth > threeMonth) {
        trend = 'Improving';
        trendIcon = '📈';
        trendMultiplier = 1.15;
      } else if (oneMonth >= performanceBenchmark &&
          threeMonth >= performanceBenchmark) {
        trend = 'Consistently Above Standard';
        trendIcon = '✅';
        trendMultiplier = 1.1;
      } else if (oneMonth < threeMonth && oneMonth < performanceBenchmark) {
        trend = 'Declining Below Standard';
        trendIcon = '⚠️';
        trendMultiplier = 0.8;
      } else if (oneMonth < threeMonth) {
        trend = 'Recent Decline';
        trendIcon = '📉';
        trendMultiplier = 0.9;
      } else {
        trend = 'Stable Performance';
        trendIcon = '➡️';
        trendMultiplier = 1.0;
      }
    } else {
      // Fallback for missing data
      if (allTime >= performanceBenchmark) {
        trend = 'Above Standard';
        trendIcon = '✅';
        trendMultiplier = 1.0;
      } else {
        trend = 'Below Standard';
        trendIcon = '⚠️';
        trendMultiplier = 0.8;
      }
    }

    // Weight recent performance more heavily, but factor in benchmark achievement
    final baseScore = (oneMonth * 0.5) + (threeMonth * 0.3) + (allTime * 0.2);

    // Bonus for meeting/exceeding 80% benchmark
    double benchmarkBonus = 1.0;
    if (recentPerformance >= performanceBenchmark) {
      benchmarkBonus = 1.0 +
          ((recentPerformance - performanceBenchmark) /
              100.0); // Extra credit for exceeding
    } else {
      benchmarkBonus = recentPerformance /
          performanceBenchmark; // Penalty for below standard
    }

    // Apply all multipliers
    final finalScore =
        baseScore * trendMultiplier * performanceMultiplier * benchmarkBonus;

    return {
      'report': report,
      'score': finalScore,
      'trend': trend,
      'trendIcon': trendIcon,
      'performanceLevel': performanceLevel,
      'performanceColor': performanceColor,
      'benchmarkStatus': recentPerformance >= performanceBenchmark
          ? 'Above Standard'
          : 'Below Standard',
      'benchmarkGap': recentPerformance - performanceBenchmark,
    };
  }

  /// Format percentage values for display
  String _formatPercentage(double? percentage) {
    if (percentage == null) return 'N/A';
    return '${percentage.toStringAsFixed(1)}%';
  }

  /// Format benchmark gap for display
  String _formatBenchmarkGap(double gap) {
    if (gap >= 0) {
      return '+${gap.toStringAsFixed(1)}%';
    } else {
      return '${gap.toStringAsFixed(1)}%';
    }
  }

  /// Get color for trend indicators
  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'Strong Upward Trend':
      case 'Recent Improvement':
        return Colors.green;
      case 'Stable Performance':
        return Colors.blue;
      case 'Recent Decline':
        return Colors.orange;
      case 'Downward Trend':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get color based on performance score
  Color _getScoreColor(double score) {
    if (score >= 70) return Colors.green;
    if (score >= 50) return Colors.blue;
    if (score >= 30) return Colors.orange;
    return Colors.red;
  }

  Color _getNPSColor(double nps) {
    if (nps >= 50) return Colors.green;
    if (nps >= 0) return Colors.orange;
    return Colors.red;
  }

  Widget _buildBenchmarkingSummary(BenchmarkAnalysis analysis) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Performance Benchmarking',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NPSBenchmarkingScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('View Details'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPerformanceRating(analysis),
            const SizedBox(height: 16),
            _buildBenchmarkComparison(analysis),
            if (analysis.recommendations.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildTopRecommendations(analysis),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceRating(BenchmarkAnalysis analysis) {
    Color ratingColor;
    IconData ratingIcon;
    String ratingText = analysis.performanceRating;

    // Determine rating color and icon based on performance rating text
    switch (analysis.performanceRating.toLowerCase()) {
      case 'excellent':
        ratingColor = Colors.green;
        ratingIcon = Icons.trending_up;
        break;
      case 'good':
        ratingColor = Colors.blue;
        ratingIcon = Icons.thumb_up;
        break;
      case 'average':
        ratingColor = Colors.orange;
        ratingIcon = Icons.trending_flat;
        break;
      case 'below average':
        ratingColor = Colors.red;
        ratingIcon = Icons.trending_down;
        break;
      case 'poor':
        ratingColor = Colors.red.shade700;
        ratingIcon = Icons.warning;
        break;
      default:
        ratingColor = Colors.grey;
        ratingIcon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ratingColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ratingColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(ratingIcon, color: ratingColor, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overall Performance: $ratingText',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ratingColor,
                    ),
              ),
              Text(
                'Current NPS: ${analysis.currentNPS.toStringAsFixed(1)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarkComparison(BenchmarkAnalysis analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Industry Comparison',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        _buildComparisonRow(
          'Industry Average',
          analysis.industryAverage,
          analysis.currentNPS,
        ),
        if (analysis.competitorComparison.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'vs. Competitors',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          ...analysis.competitorComparison.entries.take(2).map(
                (entry) => _buildComparisonRow(
                    entry.key, entry.value, analysis.currentNPS),
              ),
        ],
      ],
    );
  }

  Widget _buildComparisonRow(
      String label, double benchmarkValue, double currentValue) {
    final difference = currentValue - benchmarkValue;
    final isPositive = difference >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label),
          ),
          Expanded(
            child: Text(
              benchmarkValue.toStringAsFixed(1),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isPositive ? Colors.green : Colors.red,
                  size: 16,
                ),
                Text(
                  '${isPositive ? '+' : ''}${difference.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopRecommendations(BenchmarkAnalysis analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Recommendations',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        ...analysis.recommendations.take(3).map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rec.title,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }


  /// Build the historical analytics section
  Widget _buildHistoricalAnalyticsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                Text(
                  'Historical NPS Analytics',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                    fontSize: 24,
                  ),
                ),
                const Spacer(),
                if (_isLoadingHistorical)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadHistoricalData,
                    tooltip: 'Refresh Historical Data',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoadingHistorical)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading historical analytics...'),
                    ],
                  ),
                ),
              )
            else if (_historicalData.isEmpty)
              _buildNoHistoricalDataMessage()
            else
              Column(
                children: [
                  _buildHistoricalServerSelector(),
                  if (_selectedServerId.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSelectedServerDetails(),
                  ],
                            const SizedBox(height: 16),
                            _buildAllServersOverview(),
                            const SizedBox(height: 16),
                            _buildAdvancedTrendAnalysis(),
                          ],
                        ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoHistoricalDataMessage() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Historical Data Available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Enter monthly NPS data to see historical analytics',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildHistoricalServerSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Server for Detailed Analysis',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedServerId.isEmpty ? null : _selectedServerId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Server',
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: const TextStyle(fontSize: 16),
            items: _historicalData.map((data) {
              return DropdownMenuItem<String>(
                value: data.serverId,
                child: Text(
                  data.serverName,
                  style: const TextStyle(fontSize: 16),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedServerId = value ?? '';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedServerDetails() {
    final historicalData = _historicalData.firstWhere(
      (data) => data.serverId == _selectedServerId,
      orElse: () => _historicalData.first,
    );

    final timeline = _timelines.firstWhere(
      (t) => t.serverId == _selectedServerId,
      orElse: () => _timelines.first,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person,
                color: _getClassificationColor(historicalData.classification),
              ),
              const SizedBox(width: 8),
              Text(
                historicalData.serverName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getClassificationColor(historicalData.classification).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getClassificationColor(historicalData.classification).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '${historicalData.classification.emoji} ${historicalData.classification.displayName}',
                  style: TextStyle(
                    color: _getClassificationColor(historicalData.classification),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Overall Score',
                  '${historicalData.overallPerformanceScore.toStringAsFixed(1)}%',
                  _getHistoricalScoreColor(historicalData.overallPerformanceScore),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricItem(
                  'Trend',
                  _getHistoricalTrendText(_convertToAdvancedTrendDirection(timeline.trend.direction)),
                  _getHistoricalTrendColor(_convertToAdvancedTrendDirection(timeline.trend.direction)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricItem(
                  'Volatility',
                  '${timeline.volatility.toStringAsFixed(1)}',
                  _getVolatilityColor(timeline.volatility),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Monthly Performance History',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ...historicalData.monthlyData.take(3).map((monthly) => _buildMonthlyPerformanceItem(monthly)),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyPerformanceItem(MonthlyPerformance monthly) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${monthly.month.month}/${monthly.month.year}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              '1M: ${monthly.oneMonthNPS.toStringAsFixed(1)}%',
              style: TextStyle(
                color: _getHistoricalScoreColor(monthly.oneMonthNPS),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '3M: ${monthly.threeMonthNPS.toStringAsFixed(1)}%',
              style: TextStyle(
                color: _getHistoricalScoreColor(monthly.threeMonthNPS),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'All: ${monthly.allTimeNPS.toStringAsFixed(1)}%',
              style: TextStyle(
                color: _getHistoricalScoreColor(monthly.allTimeNPS),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllServersOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Servers Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        ..._historicalData.map((data) => _buildServerOverviewItem(data)),
      ],
    );
  }

  Widget _buildServerOverviewItem(HistoricalNPSData data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              data.serverName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              '${data.overallPerformanceScore.toStringAsFixed(1)}%',
              style: TextStyle(
                color: _getHistoricalScoreColor(data.overallPerformanceScore),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              data.classification.displayName,
              style: TextStyle(
                color: _getClassificationColor(data.classification),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${data.totalMonthsReported} months',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for colors and styling
  Color _getClassificationColor(dynamic classification) {
    // Handle both IntelligentPerformanceTier and PerformanceClassification
    if (classification is performance_models.IntelligentPerformanceTier) {
      switch (classification) {
        case performance_models.IntelligentPerformanceTier.elite:
          return Colors.purple;
        case performance_models.IntelligentPerformanceTier.strong:
          return Colors.green;
        case performance_models.IntelligentPerformanceTier.developing:
          return Colors.blue;
        case performance_models.IntelligentPerformanceTier.concerning:
          return Colors.orange;
        case performance_models.IntelligentPerformanceTier.critical:
          return Colors.red;
        case performance_models.IntelligentPerformanceTier.unknown:
          return Colors.grey;
      }
    } else if (classification is PerformanceClassification) {
      // Handle PerformanceClassification from historical_nps_data.dart
      switch (classification) {
        case PerformanceClassification.elite:
          return Colors.purple;
        case PerformanceClassification.strong:
          return Colors.green;
        case PerformanceClassification.developing:
          return Colors.blue;
        case PerformanceClassification.concerning:
          return Colors.orange;
        case PerformanceClassification.critical:
          return Colors.red;
        case PerformanceClassification.unknown:
          return Colors.grey;
      }
    }
    return Colors.grey; // Default fallback
  }

  Color _getHistoricalScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  /// Get confidence color
  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) return Colors.green;
    if (confidence >= 60) return Colors.blue;
    if (confidence >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getHistoricalTrendText(trend_analysis.TrendDirection direction) {
    switch (direction) {
      case trend_analysis.TrendDirection.improving:
        return '↗ Improving';
      case trend_analysis.TrendDirection.declining:
        return '↘ Declining';
      case trend_analysis.TrendDirection.stable:
        return '→ Stable';
      case trend_analysis.TrendDirection.stronglyImproving:
        return '🚀 Strongly Improving';
      case trend_analysis.TrendDirection.stronglyDeclining:
        return '📉 Strongly Declining';
      case trend_analysis.TrendDirection.unknown:
        return '❓ Unknown';
    }
  }

  Color _getHistoricalTrendColor(trend_analysis.TrendDirection direction) {
    switch (direction) {
      case trend_analysis.TrendDirection.improving:
        return Colors.green;
      case trend_analysis.TrendDirection.declining:
        return Colors.red;
      case trend_analysis.TrendDirection.stable:
        return Colors.blue;
      case trend_analysis.TrendDirection.stronglyImproving:
        return Colors.green;
      case trend_analysis.TrendDirection.stronglyDeclining:
        return Colors.red;
      case trend_analysis.TrendDirection.unknown:
        return Colors.grey;
    }
  }

  Color _getVolatilityColor(double volatility) {
    if (volatility < 10) return Colors.green;
    if (volatility < 20) return Colors.orange;
    return Colors.red;
  }



  /// Build individual metric card
  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for trend analysis
  IconData _getClassificationIcon(dynamic tier) {
    if (tier is performance_models.IntelligentPerformanceTier) {
      switch (tier) {
        case performance_models.IntelligentPerformanceTier.elite:
          return Icons.emoji_events;
        case performance_models.IntelligentPerformanceTier.strong:
          return Icons.thumb_up;
        case performance_models.IntelligentPerformanceTier.developing:
          return Icons.trending_up;
        case performance_models.IntelligentPerformanceTier.concerning:
          return Icons.warning;
        case performance_models.IntelligentPerformanceTier.critical:
          return Icons.error;
        case performance_models.IntelligentPerformanceTier.unknown:
          return Icons.help;
      }
    }
    return Icons.help;
  }

  Color _getTrendDirectionColor(trend_analysis.TrendDirection direction) {
    switch (direction) {
      case trend_analysis.TrendDirection.improving:
      case trend_analysis.TrendDirection.stronglyImproving:
        return Colors.green;
      case trend_analysis.TrendDirection.declining:
      case trend_analysis.TrendDirection.stronglyDeclining:
        return Colors.red;
      case trend_analysis.TrendDirection.stable:
        return Colors.blue;
      case trend_analysis.TrendDirection.unknown:
        return Colors.grey;
    }
  }

  String _getTrendDirectionLabel(trend_analysis.TrendDirection direction) {
    switch (direction) {
      case trend_analysis.TrendDirection.improving:
        return 'Improving';
      case trend_analysis.TrendDirection.declining:
        return 'Declining';
      case trend_analysis.TrendDirection.stable:
      return 'Stable';
      case trend_analysis.TrendDirection.stronglyImproving:
        return 'Strongly Improving';
      case trend_analysis.TrendDirection.stronglyDeclining:
        return 'Strongly Declining';
      case trend_analysis.TrendDirection.unknown:
        return 'Unknown';
    }
  }

  String _getMomentumTypeLabel(trend_analysis.MomentumType momentum) {
    switch (momentum) {
      case trend_analysis.MomentumType.strongPositive:
        return 'Strong +';
      case trend_analysis.MomentumType.positive:
        return 'Positive';
      case trend_analysis.MomentumType.weakPositive:
        return 'Weak +';
      case trend_analysis.MomentumType.neutral:
        return 'Neutral';
      case trend_analysis.MomentumType.negative:
        return 'Negative';
      case trend_analysis.MomentumType.weakNegative:
        return 'Weak -';
      case trend_analysis.MomentumType.strongNegative:
        return 'Strong -';
    }
  }
}
