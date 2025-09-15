import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/nps_provider.dart';
import '../services/advanced_analytics_service.dart';
import '../services/nps_filter_service.dart';
import '../services/nps_benchmarking_service.dart';
import '../models/nps_score_feedback.dart';
import 'nps_notification_badge.dart';
import 'nps_notification_test_panel.dart';
import 'nps_quick_filters_widget.dart';
import 'nps_filter_summary_widget.dart';
import 'nps_filter_widget.dart';
import 'secured_nps_widgets.dart';
import '../screens/nps_benchmarking_screen.dart';

/// Enhanced analytics dashboard with charts and visualizations
class EnhancedNPSAnalyticsWidget extends StatefulWidget {
  const EnhancedNPSAnalyticsWidget({super.key});

  @override
  State<EnhancedNPSAnalyticsWidget> createState() => _EnhancedNPSAnalyticsWidgetState();
}

class _EnhancedNPSAnalyticsWidgetState extends State<EnhancedNPSAnalyticsWidget> {
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

          // For demo purposes, create sample data
          return Consumer2<NPSFilterService, NPSBenchmarkingService>(
            builder: (context, filterService, benchmarkService, child) {
            // Apply filters to sample data
            final allFeedback = _generateSampleData();
            final filteredFeedback = filterService.filterFeedback(allFeedback);
            
            final insights = AdvancedAnalyticsService.generateInsights(
              npsProvider.servers, 
              filteredFeedback,
            );

            // Generate benchmark analysis
            final benchmarkAnalysis = benchmarkService.analyzePerformance(
              filteredFeedback, 
              npsProvider.servers,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  // Quick Filters
                  NPSQuickFiltersWidget(
                    onFilterChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  // Filter Summary
                  NPSFilterSummaryWidget(
                    onClearFilters: () {
                      filterService.resetFilters();
                      setState(() {});
                    },
                    onEditFilters: () => _showAdvancedFilters(context),
                  ),
                  const SizedBox(height: 20),
                  _buildTimeRangeSelector(),
                  const SizedBox(height: 20),
                  _buildKeyMetricsCards(insights),
                  const SizedBox(height: 20),
                  _buildChartSelector(),
                  const SizedBox(height: 16),
                  _buildSelectedChart(filteredFeedback, npsProvider.servers),
                  const SizedBox(height: 20),
                  _buildInsightsPanel(insights),
                  const SizedBox(height: 20),
                  const NPSNotificationSummary(),
                  const SizedBox(height: 20),
                  _buildServerRankings(filteredFeedback, npsProvider.servers),
                  const SizedBox(height: 20),
                  _buildBenchmarkingSummary(benchmarkAnalysis),
                  const SizedBox(height: 20),
                  const SecuredDataExportWidget(),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notification Testing',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const NPSNotificationTestPanel(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
        },
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
                {'key': 'distribution', 'label': 'Distribution', 'icon': Icons.pie_chart},
                {'key': 'comparison', 'label': 'Server Comparison', 'icon': Icons.bar_chart},
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

  Widget _buildSelectedChart(List<NPSScoreFeedback> feedback, List<dynamic> servers) {
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

  Widget _getChartWidget(List<NPSScoreFeedback> feedback, List<dynamic> servers) {
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
    final spots = AdvancedAnalyticsService.calculateNPSTrend(feedback, daysBack: _selectedTimeRange);
    
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
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
    final sections = AdvancedAnalyticsService.calculateScoreDistribution(feedback);
    
    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 60,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildComparisonChart(List<NPSScoreFeedback> feedback, List<dynamic> servers) {
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
      final color = sampleNPS >= 50 ? Colors.green :
                   sampleNPS >= 0 ? Colors.orange : Colors.red;
      
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
                  final serverName = servers[index].toString().split('(')[0]; // Extract name
                  return Text(
                    serverName.length > 8 ? '${serverName.substring(0, 8)}...' : serverName,
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
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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

  Widget _buildServerRankings(List<NPSScoreFeedback> feedback, List<dynamic> servers) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.leaderboard,
                  color: Colors.orange.shade600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Server Performance Rankings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (servers.isEmpty)
              const Center(
                child: Text(
                  'No servers available',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...servers.take(5).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final server = entry.value;
                final sampleNPS = 60 - (index * 8); // Sample declining performance
                final medal = index == 0 ? '🥇' : index == 1 ? '🥈' : index == 2 ? '🥉' : '${index + 1}';
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          medal,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              server.toString().split('(')[0], // Extract server name
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Sample data: ${index + 1} responses',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getNPSColor(sampleNPS.toDouble()).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getNPSColor(sampleNPS.toDouble()).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          sampleNPS.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _getNPSColor(sampleNPS.toDouble()),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _showAdvancedFilters(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          child: NPSFilterWidget(
            onFiltersChanged: () {
              Navigator.of(context).pop();
              setState(() {});
            },
          ),
        ),
      ),
    );
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
          ...analysis.competitorComparison.entries.take(2).map((entry) =>
            _buildComparisonRow(entry.key, entry.value, analysis.currentNPS),
          ),
        ],
      ],
    );
  }

  Widget _buildComparisonRow(String label, double benchmarkValue, double currentValue) {
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

  // Generate sample data for demonstration
  List<NPSScoreFeedback> _generateSampleData() {
    final List<NPSScoreFeedback> sampleData = [];
    final now = DateTime.now();
    
    // Generate sample feedback for the last 30 days
    for (int i = 0; i < _selectedTimeRange; i++) {
      final date = now.subtract(Duration(days: i));
      final numResponses = (i % 3) + 1; // 1-3 responses per day
      
      for (int j = 0; j < numResponses; j++) {
        sampleData.add(NPSScoreFeedback(
          id: (i * 10) + j,
          serverId: (j % 3) + 1, // Distribute across 3 servers
          score: 5 + (i % 6), // Scores from 5-10
          comment: 'Sample feedback ${i}-${j}',
          submissionDate: date,
          createdAt: date,
        ));
      }
    }
    
    return sampleData;
  }
}