import 'package:flutter/material.dart';
import '../utils/log.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/nps_provider.dart';
import '../app_state.dart';
import '../services/advanced_analytics_service.dart';
import '../services/nps_filter_service.dart';
import '../services/nps_benchmarking_service.dart';
import '../models/nps_score_feedback.dart';
import '../models/monthly_report.dart';
import '../storage/nps_database.dart';
import '../storage/database_factory.dart';
import '../storage/nps_database_adapter.dart';
import 'secured_nps_widgets.dart';
import '../screens/nps_benchmarking_screen.dart';
import '../services/historical_nps_aggregation_service.dart';
import '../services/performance_timeline_service.dart';
// import '../services/intelligent_performance_classifier.dart';
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

  @override
  void initState() {
    super.initState();
    _loadHistoricalData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Force reload historical data whenever the widget becomes visible
    // This ensures we always have fresh data when navigating to Analytics tab
    print('🔄 [EnhancedNPSAnalyticsWidget] didChangeDependencies() - forcing historical data reload');
    _loadHistoricalData();
  }

  Future<void> _loadHistoricalData() async {
    setState(() {
      _isLoadingHistorical = true;
    });

    try {
      d('[EnhancedNPSAnalyticsWidget] Loading historical data...');
      print('🚨🚨🚨 [EnhancedNPSAnalyticsWidget] _loadHistoricalData() CALLED! 🚨🚨🚨');

      // First, verify the service is initialized
      await HistoricalNPSAggregationService.instance.initialize();
      print('🔍 [EnhancedNPSAnalyticsWidget] Service initialized, calling getAllHistoricalData()');

      // Get AppState servers for name mapping
      final appState = Provider.of<AppState>(context, listen: false);
      final appStateServers = appState.servers;
      print('🔍 [EnhancedNPSAnalyticsWidget] Found ${appStateServers.length} servers in AppState for name mapping');
      for (int i = 0; i < appStateServers.length && i < 5; i++) {
        final server = appStateServers[i];
        print('🔍 [EnhancedNPSAnalyticsWidget] AppState server ${i + 1}: id=${server.id}, name=${server.name}');
      }

      // Load historical data for all servers with AppState server mapping
      final historicalData = await HistoricalNPSAggregationService.instance.getAllHistoricalDataWithAppState(appStateServers);

      // Load performance timelines
      final timelines = await PerformanceTimelineService.instance.getAllTimelines();

      // Load intelligent performance classifications
      final classifications = <String, performance_models.PerformanceClassification>{};
      
      for (final data in historicalData) {
        // Get monthly reports for this server
        final monthlyReports = await _getMonthlyReportsForServer(data.serverId);
        
        // Classify performance - temporarily disabled
        // final classification = IntelligentPerformanceClassifier.classifyPerformance(
        //   npsScore: data.overallPerformanceScore,
        //   monthlyReports: monthlyReports,
        // );
        
        // classifications[data.serverId] = classification;
      }

      setState(() {
        _historicalData = historicalData;
        _timelines = timelines;
        _serverClassifications = classifications;
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
                        _buildHistoricalAnalyticsSection(monthlyReports),
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
      
      // Use the same data source as the working Server NPS Scorecard
      final db = DatabaseFactory.instance;
      
      // Get ALL available months with data (like the scorecard does)
      final availableMonths = await _getAvailableMonthsWithData(db);
      
      if (availableMonths.isEmpty) {
        d('[EnhancedNPSAnalyticsWidget] No months with data found');
        return [];
      }
      
      d('[EnhancedNPSAnalyticsWidget] Found ${availableMonths.length} months with data');
      
      // Load data from ALL available months (not just current month)
      final allReports = <NPSMonthlyReport>[];
      
      for (final monthData in availableMonths) {
        final year = monthData['year'] as int;
        final month = monthData['month'] as int;
        
        d('[EnhancedNPSAnalyticsWidget] Loading data for month: $month/$year');
        
        // Use the same method as the scorecard
        final serverData = await _getServerNPSDataForMonth(db, month, year);
        
        d('[EnhancedNPSAnalyticsWidget] Retrieved ${serverData.length} server records for $month/$year');
        
        // Convert server data to NPSMonthlyReport format for compatibility
        for (final data in serverData) {
          try {
            final report = NPSMonthlyReport(
              serverId: data['server_id']?.toString() ?? '',
              reportMonth: month,
              reportYear: year,
              allTimeNpsPercentage: (data['all_time_nps_percentage'] as num?)?.toDouble(),
              threeMonthNpsPercentage: (data['three_month_nps_percentage'] as num?)?.toDouble(),
              oneMonthNpsPercentage: (data['one_month_nps_percentage'] as num?)?.toDouble(),
              allTimeSales: (data['all_time_sales'] as num?)?.toDouble() ?? 0.0,
              allTimeTableCount: (data['all_time_table_count'] as num?)?.toInt() ?? 0,
              monthFeedback: FeedbackCounts(
                yes: (data['month_feedback_yes'] as num?)?.toInt() ?? 0,
                maybe: (data['month_feedback_maybe'] as num?)?.toInt() ?? 0,
                no: (data['month_feedback_no'] as num?)?.toInt() ?? 0,
              ),
              threeMonthFeedback: FeedbackCounts(
                yes: (data['three_month_feedback_yes'] as num?)?.toInt() ?? 0,
                maybe: (data['three_month_feedback_maybe'] as num?)?.toInt() ?? 0,
                no: (data['three_month_feedback_no'] as num?)?.toInt() ?? 0,
              ),
              allTimeFeedback: FeedbackCounts(
                yes: (data['all_time_feedback_yes'] as num?)?.toInt() ?? 0,
                maybe: (data['all_time_feedback_maybe'] as num?)?.toInt() ?? 0,
                no: (data['all_time_feedback_no'] as num?)?.toInt() ?? 0,
              ),
              generatedAt: DateTime.now(),
              dataAsOfDate: DateTime.now(),
            );
            allReports.add(report);
            d('[EnhancedNPSAnalyticsWidget] Added report for server: ${data['server_name']} (ID: ${data['server_id']}) for $month/$year');
          } catch (e) {
            d('[EnhancedNPSAnalyticsWidget] Error converting server data to report format: $e');
          }
        }
      }
      
      d('[EnhancedNPSAnalyticsWidget] Converted ${allReports.length} total server records to NPSMonthlyReport format across ${availableMonths.length} months');
      
      // Debug: Log the actual reports to see what we're getting
      d('[EnhancedNPSAnalyticsWidget] Loaded ${allReports.length} total reports from all available months');
      
      if (allReports.isNotEmpty) {
        d('[EnhancedNPSAnalyticsWidget] First report: Server ${allReports.first.serverId}, NPS: ${allReports.first.allTimeNpsPercentage}% for ${allReports.first.reportMonth}/${allReports.first.reportYear}');
      }
      
      return allReports;
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
    final serverReports = <String, List<NPSMonthlyReport>>{};
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
        whereArgs: [serverId],
        orderBy: 'report_year DESC, report_month DESC',
      );
      
      return results.map((row) => NPSMonthlyReport.fromMap(row)).toList();
    } catch (e) {
      d('[EnhancedNPSAnalyticsWidget] Error loading monthly reports for server $serverId: $e');
      return [];
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
  Widget _buildHistoricalAnalyticsSection(List<NPSMonthlyReport> monthlyReports) {
    // If we have monthly reports but no historical data, try to load it
    if (monthlyReports.isNotEmpty && _historicalData.isEmpty && !_isLoadingHistorical) {
      // Trigger historical data loading on next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadHistoricalData();
      });
    }
    
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
              _buildNoHistoricalDataMessage(monthlyReports)
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
                          ],
                        ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoHistoricalDataMessage(List<NPSMonthlyReport> monthlyReports) {
    // Provide more specific messaging based on available data
    String message;
    String subMessage;
    
    if (monthlyReports.isEmpty) {
      message = 'No Historical Data Available';
      subMessage = 'Enter monthly NPS data to see historical analytics';
    } else {
      message = 'Processing Historical Data...';
      subMessage = 'Found ${monthlyReports.length} monthly reports from ${monthlyReports.map((r) => r.serverId).toSet().length} servers. Loading analytics...';
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subMessage,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (monthlyReports.isNotEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadHistoricalData,
                child: const Text('Retry Loading'),
              ),
            ],
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
                  timeline.trend.direction.name,
                  Colors.blue,
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

  /// Get available months that have NPS report data (copied from Server NPS Scorecard)
  Future<List<Map<String, dynamic>>> _getAvailableMonthsWithData(dynamic database) async {
    try {
      d('[EnhancedNPSAnalyticsWidget] Getting available months using HistoricalNPSAggregationService approach...');
      
      // Use the EXACT same approach as the working HistoricalNPSAggregationService
      final allReports = await database.queryTable('nps_monthly_reports');
      d('[EnhancedNPSAnalyticsWidget] Found ${allReports.length} total monthly reports');
      
      if (allReports.isEmpty) {
        d('[EnhancedNPSAnalyticsWidget] No monthly reports found - returning empty list');
        return [];
      }
      
      // Filter out integer server IDs (EXACT same logic as HistoricalNPSAggregationService)
      final filteredReports = allReports.where((report) {
        final serverId = report['server_id'].toString();
        // Filter out ALL numeric IDs (both single and multi-digit)
        final isNumericId = RegExp(r'^\d+$').hasMatch(serverId);
        if (isNumericId) {
          d('[EnhancedNPSAnalyticsWidget] Filtering out numeric server_id: $serverId');
        }
        return !isNumericId; // Keep only string IDs with proper name mappings
      }).toList();
      
      d('[EnhancedNPSAnalyticsWidget] After filtering: ${filteredReports.length} reports (removed ${allReports.length - filteredReports.length} old format reports)');
      
      // Group reports by month and year
      final Map<String, List<Map<String, dynamic>>> monthToReports = {};
      
      for (final report in filteredReports) {
        final reportMonthFromDb = report['report_month'] as int?;
        final reportYearFromDb = report['report_year'] as int?;
        
        int year;
        int month;
        
        // Handle YYYYMM format in report_month column (legacy format)
        if (reportMonthFromDb != null && reportMonthFromDb > 10000) {
          // This is YYYYMM format (e.g., 202509)
          year = reportMonthFromDb ~/ 100;
          month = reportMonthFromDb % 100;
          d('[EnhancedNPSAnalyticsWidget] Found YYYYMM format: $reportMonthFromDb -> year=$year, month=$month');
        }
        // Handle separate report_month and report_year columns (new format)
        else if (reportMonthFromDb != null && reportYearFromDb != null) {
          year = reportYearFromDb;
          month = reportMonthFromDb;
        }
        else {
          d('[EnhancedNPSAnalyticsWidget] Skipping report with null month/year: $report');
          continue;
        }
        
        // Validate month is in valid range (1-12)
        if (month < 1 || month > 12) {
          d('[EnhancedNPSAnalyticsWidget] ⚠️ Invalid month number: $month, skipping this report');
          continue;
        }
        
        final monthKey = '${year}_$month';
        monthToReports.putIfAbsent(monthKey, () => []).add(report);
      }
      
      d('[EnhancedNPSAnalyticsWidget] Found data for ${monthToReports.length} unique months');
      
      // Convert to the expected format
      final monthsWithData = <Map<String, dynamic>>[];
      final monthNames = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      
      for (final entry in monthToReports.entries) {
        final monthKey = entry.key;
        final reports = entry.value;
        final parts = monthKey.split('_');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        
        // Count unique servers for this month
        final uniqueServers = reports.map((r) => r['server_id'].toString()).toSet();
        
        monthsWithData.add({
          'month_key': monthKey,
          'display_name': '${monthNames[month - 1]} $year',
          'server_count': uniqueServers.length,
          'year': year,
          'month': month,
        });
      }
      
      // Sort by year and month (most recent first)
      monthsWithData.sort((a, b) {
        final aYear = a['year'] as int;
        final aMonth = a['month'] as int;
        final bYear = b['year'] as int;
        final bMonth = b['month'] as int;
        
        if (aYear != bYear) {
          return bYear.compareTo(aYear); // Most recent year first
        }
        return bMonth.compareTo(aMonth); // Most recent month first
      });
      
      d('[EnhancedNPSAnalyticsWidget] Returning ${monthsWithData.length} months with data');
      return monthsWithData;
    } catch (e) {
      d('[EnhancedNPSAnalyticsWidget] Error getting available months: $e');
      return [];
    }
  }

  /// Get server NPS data for a specific month (copied from Server NPS Scorecard)
  Future<List<Map<String, dynamic>>> _getServerNPSDataForMonth(
      dynamic database, int reportMonth, int reportYear) async {
    try {
      d('[EnhancedNPSAnalyticsWidget] Querying for month=$reportMonth, year=$reportYear using HistoricalNPSAggregationService approach...');
      
      // Use the EXACT same approach as the working HistoricalNPSAggregationService
      final allReports = await database.queryTable('nps_monthly_reports');
      d('[EnhancedNPSAnalyticsWidget] Found ${allReports.length} total monthly reports');
      
      if (allReports.isEmpty) {
        d('[EnhancedNPSAnalyticsWidget] No monthly reports found');
        return [];
      }
      
      // Filter out integer server IDs (EXACT same logic as HistoricalNPSAggregationService)
      final filteredReports = allReports.where((report) {
        final serverId = report['server_id'].toString();
        // Filter out ALL numeric IDs (both single and multi-digit)
        final isNumericId = RegExp(r'^\d+$').hasMatch(serverId);
        if (isNumericId) {
          d('[EnhancedNPSAnalyticsWidget] Filtering out numeric server_id: $serverId');
        }
        return !isNumericId; // Keep only string IDs with proper name mappings
      }).toList();
      
      d('[EnhancedNPSAnalyticsWidget] After filtering: ${filteredReports.length} reports');
      
      // Filter for the specific month and year
      final monthReports = filteredReports.where((report) {
        final reportMonthFromDb = report['report_month'] as int?;
        final reportYearFromDb = report['report_year'] as int?;
        
        // Handle YYYYMM format in report_month column (legacy format)
        if (reportMonthFromDb != null && reportMonthFromDb > 10000) {
          // This is YYYYMM format (e.g., 202509)
          final year = reportMonthFromDb ~/ 100;
          final month = reportMonthFromDb % 100;
          d('[EnhancedNPSAnalyticsWidget] Found YYYYMM format: $reportMonthFromDb -> year=$year, month=$month');
          
          // Validate month is in valid range (1-12)
          if (month < 1 || month > 12) {
            d('[EnhancedNPSAnalyticsWidget] ⚠️ Invalid month number from YYYYMM: $month, skipping this report');
            return false;
          }
          
          return month == reportMonth && year == reportYear;
        }
        
        // Handle separate report_month and report_year columns (new format)
        if (reportMonthFromDb != null && reportYearFromDb != null) {
          // Validate month is in valid range (1-12)
          if (reportMonthFromDb < 1 || reportMonthFromDb > 12) {
            d('[EnhancedNPSAnalyticsWidget] ⚠️ Invalid month number: $reportMonthFromDb, skipping this report');
            return false;
          }
          
          return reportMonthFromDb == reportMonth && reportYearFromDb == reportYear;
        }
        
        return false;
      }).toList();
      
      d('[EnhancedNPSAnalyticsWidget] Found ${monthReports.length} reports for $reportMonth/$reportYear');
      
      // Convert to the expected format with server names
      final serverData = <Map<String, dynamic>>[];
      
      for (final report in monthReports) {
        final serverId = report['server_id'].toString();
        
        // Get server name from the database
        try {
          final servers = await database.queryTable('servers', where: 'id = ?', whereArgs: [serverId]);
          String serverName = 'Unknown Server';
          
          if (servers.isNotEmpty) {
            serverName = servers.first['name'] as String? ?? 'Unknown Server';
          }
          
          serverData.add({
            'server_id': serverId,
            'server_name': serverName,
            'all_time_nps_percentage': report['all_time_nps_percentage'] as double? ?? 0.0,
            'three_month_nps_percentage': report['three_month_nps_percentage'] as double? ?? 0.0,
            'one_month_nps_percentage': report['one_month_nps_percentage'] as double? ?? 0.0,
            'all_time_sales': report['all_time_sales'] as double? ?? 0.0,
            'all_time_table_count': report['all_time_table_count'] as int? ?? 0,
            'report_month': reportMonth,
            'report_year': reportYear,
          });
        } catch (e) {
          d('[EnhancedNPSAnalyticsWidget] Error getting server name for $serverId: $e');
          // Add with unknown name if we can't get the server name
          serverData.add({
            'server_id': serverId,
            'server_name': 'Unknown Server',
            'all_time_nps_percentage': report['all_time_nps_percentage'] as double? ?? 0.0,
            'three_month_nps_percentage': report['three_month_nps_percentage'] as double? ?? 0.0,
            'one_month_nps_percentage': report['one_month_nps_percentage'] as double? ?? 0.0,
            'all_time_sales': report['all_time_sales'] as double? ?? 0.0,
            'all_time_table_count': report['all_time_table_count'] as int? ?? 0,
            'report_month': reportMonth,
            'report_year': reportYear,
          });
        }
      }
      
      d('[EnhancedNPSAnalyticsWidget] Returning ${serverData.length} server records for $reportMonth/$reportYear');
      return serverData;
    } catch (e) {
      d('[EnhancedNPSAnalyticsWidget] Error getting server data: $e');
      return [];
    }
  }

}
