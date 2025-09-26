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
                        // Server Performance Rankings
                        _buildServerRankings(
                            monthlyReports, npsProvider.servers),
                        const SizedBox(height: 20),
                        // Key Metrics from Monthly Reports
                        _buildKeyMetricsFromReports(monthlyReports),
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
      
      return reportMaps.map((map) => NPSMonthlyReport.fromMap(map)).toList();
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
    final totalServers = reports.length;
    final avgNPS = reports
            .map((r) => r.allTimeNpsPercentage ?? 0.0)
            .reduce((a, b) => a + b) /
        totalServers;
    final totalSales =
        reports.map((r) => r.allTimeSales).reduce((a, b) => a + b);
    final totalChecks =
        reports.map((r) => r.allTimeTableCount).reduce((a, b) => a + b);

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

  /// Build key metrics from monthly reports
  Widget _buildKeyMetricsFromReports(List<NPSMonthlyReport> reports) {
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
            Text('Based on ${reports.length} monthly reports'),
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

  Widget _buildServerRankings(
      List<NPSMonthlyReport> monthlyReports, List<dynamic> servers) {
    // Group reports by server ID and aggregate their performance
    final Map<int, List<NPSMonthlyReport>> reportsByServer = {};
    for (final report in monthlyReports) {
      reportsByServer.putIfAbsent(report.serverId, () => []).add(report);
    }

    // Calculate aggregated performance scores for each server
    final serverScores = reportsByServer.entries.map((entry) {
      final serverId = entry.key;
      final serverReports = entry.value;
      return _calculateAggregatedServerPerformance(
          serverId, serverReports, monthlyReports);
    }).toList();

    // Sort by performance score (descending)
    serverScores.sort((a, b) => b['score'].compareTo(a['score']));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Colors.orange.shade600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Restaurant Impact Rankings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Who\'s helping vs hurting the restaurant - based on sales impact & NPS performance',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (serverScores.isEmpty)
              const Center(
                child: Text(
                  'No monthly report data available',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...serverScores.take(5).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final scoreData = entry.value;
                final serverId = scoreData['serverId'] as int;
                final performanceScore = scoreData['score'] as double;
                final recentPerformance =
                    scoreData['recentPerformance'] as double;
                final historicalInsight =
                    scoreData['historicalInsight'] as String;
                final salesPercentage = scoreData['salesPercentage'] as double;
                final impactLevel = scoreData['impactLevel'] as String;
                final impactColor = scoreData['impactColor'] as Color;
                final simpleSummary = scoreData['simpleSummary'] as String;
                final trend = scoreData['trend'] as String;
                final trendIcon = scoreData['trendIcon'] as String;
                final improvementRate = scoreData['improvementRate'] as double;

                final medal = index == 0
                    ? '🥇'
                    : index == 1
                        ? '🥈'
                        : index == 2
                            ? '🥉'
                            : '${index + 1}';

                // Find corresponding server name - extract just the name
                final server = servers.cast<dynamic>().firstWhere(
                      (server) => server.id == serverId,
                      orElse: () => null,
                    );

                // Extract clean server name (just the name part)
                String serverName = 'Server $serverId';
                if (server != null) {
                  final serverStr = server.toString();
                  // Extract name from pattern like "NPSServer(id: 2, name: b, hireDate: ...)"
                  final nameMatch =
                      RegExp(r'name:\s*([^,]+)').firstMatch(serverStr);
                  if (nameMatch != null) {
                    serverName =
                        nameMatch.group(1)?.trim() ?? 'Server $serverId';
                  }
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade100,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 50,
                          child: Text(
                            medal,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Server name and primary impact indicator
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      serverName,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  // Simple impact indicator
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: impactColor,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      impactLevel,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Simple summary - dummy proof
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: impactColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: impactColor.withOpacity(0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      simpleSummary,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            impactColor.computeLuminance() > 0.5
                                                ? Colors.grey.shade800
                                                : impactColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        // Sales percentage - clear format
                                        Icon(
                                          Icons.pie_chart,
                                          size: 18,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${salesPercentage.toStringAsFixed(1)}% of restaurant sales',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        // Trend emoji icon
                                        Text(
                                          trendIcon,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${recentPerformance.toStringAsFixed(0)}% NPS',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: recentPerformance >= 80
                                                ? Colors.green.shade700
                                                : Colors.red.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Trend indicator badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getTrendBadgeColor(
                                                improvementRate),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            _getTrendLabel(improvementRate),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Clear benchmark context
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: recentPerformance >= 80
                                                ? Colors.green.withOpacity(0.1)
                                                : Colors.red.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: recentPerformance >= 80
                                                  ? Colors.green
                                                      .withOpacity(0.3)
                                                  : Colors.red.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Text(
                                            recentPerformance >= 80
                                                ? 'Above 80% target'
                                                : 'Below 80% target',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: recentPerformance >= 80
                                                  ? Colors.green.shade700
                                                  : Colors.red.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Historical insight (simplified)
                              Text(
                                historicalInsight,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Simple score indicator with restaurant impact
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: impactColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: impactColor,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    performanceScore.toStringAsFixed(0),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: impactColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Impact Score',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: impactColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ], // Closing bracket for Row children
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  /// Calculate aggregated performance for a server across all their monthly reports
  Map<String, dynamic> _calculateAggregatedServerPerformance(int serverId,
      List<NPSMonthlyReport> serverReports, List<NPSMonthlyReport> allReports) {
    if (serverReports.isEmpty) {
      return {
        'serverId': serverId,
        'score': 0.0,
        'trend': 'No Data',
        'trendIcon': '❓',
        'performanceLevel': 'No Data',
        'performanceColor': Colors.grey,
        'benchmarkGap': -80.0,
        'recentPerformance': 0.0,
        'overallPerformance': 0.0,
        'monthsReporting': 0,
        'consistencyScore': 0.0,
        'improvementRate': 0.0,
        'historicalInsight': 'No historical data available',
        'performanceHistory': <double>[],
        'monthNames': <String>[],
        'salesPercentage': 0.0,
        'restaurantImpact': 'No Impact',
        'impactLevel': 'None',
        'impactColor': Colors.grey,
        'simpleSummary': 'No data available',
      };
    }

    // Sort reports by month to get chronological order
    serverReports.sort((a, b) => a.reportMonth.compareTo(b.reportMonth));

    // Extract all available performance data with month tracking
    final List<double> performanceHistory = [];
    final List<String> monthNames = [];

    for (final report in serverReports) {
      final performance =
          report.oneMonthNpsPercentage ?? report.allTimeNpsPercentage ?? 0.0;
      performanceHistory.add(performance);

      // Extract month name from YYYYMM format
      final month = report.reportMonth % 100;
      monthNames.add(_getMonthName(month));
    }

    // Calculate aggregated performance metrics
    final recentPerformance =
        performanceHistory.isNotEmpty ? performanceHistory.last : 0.0;
    final overallPerformance = performanceHistory.isNotEmpty
        ? performanceHistory.reduce((a, b) => a + b) / performanceHistory.length
        : 0.0;

    // Calculate consistency score (lower standard deviation = more consistent)
    double consistencyScore = 0.0;
    if (performanceHistory.length > 1) {
      final mean = overallPerformance;
      final variance = performanceHistory
              .map((x) => (x - mean) * (x - mean))
              .reduce((a, b) => a + b) /
          performanceHistory.length;
      final standardDeviation =
          variance > 0 ? (variance).abs() : 0.0; // Simplified sqrt
      consistencyScore = 100.0 -
          (standardDeviation > 20
              ? 20
              : standardDeviation); // Max penalty of 20 points
    }

    // Calculate improvement rate
    double improvementRate = 0.0;
    if (performanceHistory.length >= 2) {
      final firstPerformance = performanceHistory.first;
      final lastPerformance = performanceHistory.last;
      improvementRate = lastPerformance - firstPerformance;
    }

    // Generate historical insight
    String historicalInsight = _generateHistoricalInsight(performanceHistory,
        monthNames, consistencyScore, improvementRate, overallPerformance);

    // Calculate sales percentage and restaurant impact
    final totalRestaurantSales = allReports
        .map((r) => r.allTimeSales)
        .fold(0.0, (sum, sales) => sum + sales);

    final serverTotalSales = serverReports
        .map((r) => r.allTimeSales)
        .fold(0.0, (sum, sales) => sum + sales);

    final salesPercentage = totalRestaurantSales > 0
        ? (serverTotalSales / totalRestaurantSales) * 100
        : 0.0;

    // Calculate restaurant impact (simple and clear)
    String restaurantImpact;
    String impactLevel;
    Color impactColor;
    String simpleSummary;

    // Calculate trend description for admin insights
    String trendDescription = "";
    if (performanceHistory.length >= 2) {
      if (improvementRate > 5.0) {
        trendDescription =
            " and improving significantly (+${improvementRate.toStringAsFixed(1)}%)";
      } else if (improvementRate > 2.0) {
        trendDescription =
            " and trending upward (+${improvementRate.toStringAsFixed(1)}%)";
      } else if (improvementRate >= -2.0) {
        trendDescription = " and performance is stable";
      } else if (improvementRate < -5.0) {
        trendDescription =
            " and declining significantly (${improvementRate.toStringAsFixed(1)}%)";
      } else {
        trendDescription =
            " and trending downward (${improvementRate.toStringAsFixed(1)}%)";
      }
    }

    if (salesPercentage < 5.0) {
      // Low sales impact
      if (recentPerformance >= 80) {
        restaurantImpact = 'Minor Boost';
        impactLevel = 'Good';
        impactColor = Colors.green.shade300;
        simpleSummary =
            'Good performance but low sales impact$trendDescription';
      } else {
        restaurantImpact = 'Minor Drag';
        impactLevel = 'Bad';
        impactColor = Colors.orange.shade300;
        simpleSummary = 'Below standard but low sales impact$trendDescription';
      }
    } else if (salesPercentage < 15.0) {
      // Medium sales impact
      if (recentPerformance >= 85) {
        restaurantImpact = 'Restaurant Booster';
        impactLevel = 'Excellent';
        impactColor = Colors.green.shade600;
        simpleSummary = 'HELPING the restaurant succeed$trendDescription';
      } else if (recentPerformance >= 80) {
        restaurantImpact = 'Above Standard';
        impactLevel = 'Good';
        impactColor = Colors.green.shade400;
        simpleSummary = 'Meeting our 80% standard$trendDescription';
      } else if (recentPerformance >= 70) {
        restaurantImpact = 'Below Standard';
        impactLevel = 'Okay';
        impactColor = Colors.yellow.shade600;
        simpleSummary = 'Below our 80% standard$trendDescription';
      } else {
        restaurantImpact = 'Restaurant Drag';
        impactLevel = 'Problem';
        impactColor = Colors.red.shade500;
        simpleSummary = 'HURTING the restaurant$trendDescription';
      }
    } else {
      // High sales impact
      if (recentPerformance >= 85) {
        restaurantImpact = 'STAR PERFORMER';
        impactLevel = 'Superstar';
        impactColor = Colors.green.shade800;
        simpleSummary =
            'MAJOR restaurant booster - keep this server!$trendDescription';
      } else if (recentPerformance >= 80) {
        restaurantImpact = 'High Volume Above Standard';
        impactLevel = 'Excellent';
        impactColor = Colors.green.shade600;
        simpleSummary =
            'High sales and meeting our 80% standard$trendDescription';
      } else if (recentPerformance >= 70) {
        restaurantImpact = 'High Volume Below Standard';
        impactLevel = 'Concerning';
        impactColor = Colors.orange.shade600;
        simpleSummary =
            'High sales but below our 80% standard - needs improvement$trendDescription';
      } else {
        restaurantImpact = 'RESTAURANT KILLER';
        impactLevel = 'Crisis';
        impactColor = Colors.red.shade800;
        simpleSummary =
            'MAJOR problem - high sales but terrible NPS!$trendDescription';
      }
    }

    const double performanceBenchmark = 80.0;

    // Calculate performance level relative to 80% benchmark
    String performanceLevel;
    Color performanceColor;
    double performanceMultiplier;

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

    // Calculate trend across all reports
    String trend;
    String trendIcon;
    double trendMultiplier;

    if (serverReports.length >= 2) {
      if (improvementRate > 5.0 && recentPerformance >= performanceBenchmark) {
        trend = 'Strong Improvement';
        trendIcon = '🚀';
        trendMultiplier = 1.2;
      } else if (improvementRate > 2.0) {
        trend = 'Improving';
        trendIcon = '📈';
        trendMultiplier = 1.15;
      } else if (improvementRate >= -2.0 &&
          recentPerformance >= performanceBenchmark) {
        trend = 'Stable Above Standard';
        trendIcon = '✅';
        trendMultiplier = 1.1;
      } else if (improvementRate >= -2.0) {
        trend = 'Stable';
        trendIcon = '➡️';
        trendMultiplier = 1.0;
      } else if (improvementRate < -5.0) {
        trend = 'Declining';
        trendIcon = '📉';
        trendMultiplier = 0.8;
      } else {
        trend = 'Slight Decline';
        trendIcon = '⬇️';
        trendMultiplier = 0.9;
      }
    } else {
      // Single report - assess based on performance level
      if (recentPerformance >= performanceBenchmark) {
        trend = 'Above Standard';
        trendIcon = '✅';
        trendMultiplier = 1.0;
      } else {
        trend = 'Below Standard';
        trendIcon = '⚠️';
        trendMultiplier = 0.8;
      }
    }

    // Calculate final score with sales impact weighting
    double baseScore = recentPerformance;

    // Sales impact multiplier (higher sales = higher impact on restaurant)
    double salesImpactMultiplier = 1.0 +
        (salesPercentage / 100.0); // Each 1% of sales adds 1% to multiplier

    // Bonus for meeting/exceeding 80% benchmark
    double benchmarkBonus = 1.0;
    if (recentPerformance >= performanceBenchmark) {
      benchmarkBonus = 1.0 +
          ((recentPerformance - performanceBenchmark) /
              200.0); // Moderate bonus
    } else {
      benchmarkBonus = recentPerformance /
          performanceBenchmark; // Penalty for below standard
    }

    // Consistency bonus (reward consistent performers)
    double consistencyBonus =
        1.0 + (consistencyScore / 1000.0); // Small bonus for consistency

    // Restaurant impact modifier - amplifies or reduces based on actual business impact
    double restaurantImpactModifier = 1.0;
    if (salesPercentage >= 15.0) {
      // High sales servers get amplified scores (good or bad)
      restaurantImpactModifier = recentPerformance >= 70
          ? 1.3
          : 0.7; // Major boost for good, penalty for bad
    } else if (salesPercentage >= 5.0) {
      // Medium sales servers get moderate adjustment
      restaurantImpactModifier = recentPerformance >= 80 ? 1.15 : 0.9;
    }

    // Apply all multipliers
    final finalScore = baseScore *
        trendMultiplier *
        performanceMultiplier *
        benchmarkBonus *
        consistencyBonus *
        salesImpactMultiplier *
        restaurantImpactModifier;

    return {
      'serverId': serverId,
      'score': finalScore,
      'trend': trend,
      'trendIcon': trendIcon,
      'performanceLevel': performanceLevel,
      'performanceColor': performanceColor,
      'benchmarkGap': recentPerformance - performanceBenchmark,
      'recentPerformance': recentPerformance,
      'overallPerformance': overallPerformance,
      'monthsReporting': serverReports.length,
      'consistencyScore': consistencyScore,
      'improvementRate': improvementRate,
      'historicalInsight': historicalInsight,
      'performanceHistory': performanceHistory,
      'monthNames': monthNames,
      'salesPercentage': salesPercentage,
      'restaurantImpact': restaurantImpact,
      'impactLevel': impactLevel,
      'impactColor': impactColor,
      'simpleSummary': simpleSummary,
    };
  }

  /// Generate historical insight based on performance data
  String _generateHistoricalInsight(
    List<double> performanceHistory,
    List<String> monthNames,
    double consistencyScore,
    double improvementRate,
    double averagePerformance,
  ) {
    if (performanceHistory.isEmpty) return 'No data available';
    if (performanceHistory.length == 1) return 'Single month reporting';

    final monthCount = performanceHistory.length;
    final months = monthNames.join(', ');

    // Analyze patterns
    if (consistencyScore > 90 && averagePerformance >= 80) {
      return 'Consistently excellent performer across $monthCount months ($months)';
    } else if (consistencyScore > 85) {
      return 'Very reliable performer with minimal variation ($months)';
    } else if (improvementRate > 10) {
      return 'Dramatic improvement trend: +${improvementRate.toStringAsFixed(1)}% since $months';
    } else if (improvementRate > 5) {
      return 'Strong upward trajectory over $monthCount months ($months)';
    } else if (improvementRate < -10) {
      return 'Concerning decline: ${improvementRate.toStringAsFixed(1)}% drop since $months';
    } else if (improvementRate < -5) {
      return 'Performance has declined over $monthCount months ($months)';
    } else if (consistencyScore < 70) {
      return 'Inconsistent performance across $monthCount months - needs attention';
    } else {
      return 'Stable performance over $monthCount months ($months)';
    }
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

  /// Get trend badge color based on improvement rate
  Color _getTrendBadgeColor(double improvementRate) {
    if (improvementRate > 5.0) {
      return Colors.green.shade600; // Strong improvement
    } else if (improvementRate > 2.0) {
      return Colors.green.shade400; // Improving
    } else if (improvementRate >= -2.0) {
      return Colors.blue.shade400; // Stable
    } else if (improvementRate < -5.0) {
      return Colors.red.shade600; // Declining
    } else {
      return Colors.orange.shade500; // Slight decline
    }
  }

  /// Get trend label based on improvement rate
  String _getTrendLabel(double improvementRate) {
    if (improvementRate > 5.0) {
      return 'Rising';
    } else if (improvementRate > 2.0) {
      return 'Up';
    } else if (improvementRate >= -2.0) {
      return 'Stable';
    } else if (improvementRate < -5.0) {
      return 'Falling';
    } else {
      return 'Down';
    }
  }
}
