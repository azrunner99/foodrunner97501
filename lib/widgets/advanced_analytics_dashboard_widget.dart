import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../utils/station_analytics_calculator.dart';
import '../models/station_performance_metric.dart';

/// Advanced Analytics Dashboard Widget
/// Comprehensive visualization of station performance metrics
class AdvancedAnalyticsDashboardWidget extends StatefulWidget {
  final List<StationComparisonData> stationData;
  final Map<String, double> stationEfficiencies;
  final List<String> performanceInsights;

  const AdvancedAnalyticsDashboardWidget({
    Key? key,
    required this.stationData,
    required this.stationEfficiencies,
    required this.performanceInsights,
  }) : super(key: key);

  @override
  State<AdvancedAnalyticsDashboardWidget> createState() => _AdvancedAnalyticsDashboardWidgetState();
}

class _AdvancedAnalyticsDashboardWidgetState extends State<AdvancedAnalyticsDashboardWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTimeRange = '30 Days';
  String _selectedMetric = 'Efficiency';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildControlPanel(),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildEfficiencyChart(),
              _buildTrendAnalysis(),
              _buildPerformanceInsights(),
              _buildStationComparison(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedTimeRange,
              decoration: const InputDecoration(
                labelText: 'Time Range',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: ['7 Days', '30 Days', '90 Days', '1 Year'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedTimeRange = newValue!;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedMetric,
              decoration: const InputDecoration(
                labelText: 'Metric',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: ['Efficiency', 'Utilization', 'Quality', 'Consistency'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedMetric = newValue!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Station Efficiency Trends',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('Day ${value.toInt()}');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: _buildEfficiencyLineBars(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<LineChartBarData> _buildEfficiencyLineBars() {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];
    final lineBars = <LineChartBarData>[];

    for (int i = 0; i < widget.stationData.length && i < 4; i++) {
      final station = widget.stationData[i];
      final spots = <FlSpot>[];
      
      // Generate sample data points for demonstration
      for (int j = 0; j < 30; j++) {
        final baseValue = station.currentEfficiency;
        final variation = (j % 7) * 2.0; // Weekly pattern
        spots.add(FlSpot(j.toDouble(), baseValue + variation));
      }

      lineBars.add(LineChartBarData(
        spots: spots,
        isCurved: true,
        color: colors[i % colors.length],
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: colors[i % colors.length].withOpacity(0.1),
        ),
      ));
    }

    return lineBars;
  }

  Widget _buildTrendAnalysis() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Trends',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: widget.stationData.length,
                itemBuilder: (context, index) {
                  final station = widget.stationData[index];
                  return _buildTrendCard(station);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendCard(StationComparisonData station) {
    final trendColor = station.trendPercentage >= 0 ? Colors.green : Colors.red;
    final trendIcon = station.trendPercentage >= 0 ? Icons.trending_up : Icons.trending_down;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: trendColor.withOpacity(0.1),
          child: Icon(trendIcon, color: trendColor),
        ),
        title: Text(station.stationType),
        subtitle: Text('Current: ${station.currentEfficiency.toStringAsFixed(1)}%'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${station.trendPercentage >= 0 ? '+' : ''}${station.trendPercentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: trendColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'vs Previous',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceInsights() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Insights',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: widget.performanceInsights.length,
                itemBuilder: (context, index) {
                  final insight = widget.performanceInsights[index];
                  return _buildInsightCard(insight, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(String insight, int index) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];
    final icons = [Icons.analytics, Icons.trending_up, Icons.warning, Icons.lightbulb];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colors[index % colors.length].withOpacity(0.1),
          child: Icon(icons[index % icons.length], color: colors[index % colors.length]),
        ),
        title: Text(insight),
        subtitle: Text('Generated ${DateFormat('MMM dd, yyyy').format(DateTime.now())}'),
      ),
    );
  }

  Widget _buildStationComparison() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Station Comparison',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < widget.stationData.length) {
                            return Text(
                              widget.stationData[value.toInt()].stationType,
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: _buildBarGroups(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return widget.stationData.asMap().entries.map((entry) {
      final index = entry.key;
      final station = entry.value;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: station.currentEfficiency,
            color: Colors.blue,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();
  }
}

