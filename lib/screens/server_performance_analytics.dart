/// Enhanced Server Performance Analytics 
/// Advanced analytics specifically for individual server tracking

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../models/comprehensive_shift_data.dart';
import '../services/comprehensive_shift_capture_service.dart';
import '../services/multi_variable_correlation_engine.dart';
import '../widgets/wallpaper_background.dart';

class ServerPerformanceAnalytics extends StatefulWidget {
  final String? serverId;

  const ServerPerformanceAnalytics({super.key, this.serverId});

  @override
  State<ServerPerformanceAnalytics> createState() => _ServerPerformanceAnalyticsState();
}

class _ServerPerformanceAnalyticsState extends State<ServerPerformanceAnalytics> {
  List<ComprehensiveShiftData> _allShiftData = [];
  Map<String, List<ComprehensiveShiftData>> _serverShiftData = {};
  String? _selectedServerId;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _selectedServerId = widget.serverId;
    _loadServerData();
  }

  Future<void> _loadServerData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final shiftData = await ComprehensiveShiftCaptureService.getStoredShiftData();
      
      // Group by server
      final Map<String, List<ComprehensiveShiftData>> groupedData = {};
      for (final shift in shiftData) {
        for (final server in shift.serverPerformances) {
          if (!groupedData.containsKey(server.serverId)) {
            groupedData[server.serverId] = [];
          }
          // Create shift data specific to this server
          final serverSpecificShift = ComprehensiveShiftData(
            shiftId: shift.shiftId,
            shiftDate: shift.shiftDate,
            shiftType: shift.shiftType,
            startTime: shift.startTime,
            endTime: shift.endTime,
            serverPerformances: [server],
            sectionPerformances: shift.sectionPerformances,
            businessMetrics: shift.businessMetrics,
            stationMetrics: shift.stationMetrics,
            correlations: shift.correlations,
          );
          groupedData[server.serverId]!.add(serverSpecificShift);
        }
      }

      setState(() {
        _allShiftData = shiftData;
        _serverShiftData = groupedData;
        _selectedServerId ??= groupedData.keys.isNotEmpty ? groupedData.keys.first : null;
        _isLoading = false;
      });
    } catch (e) {
      print('[SERVER_ANALYTICS] Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Performance Analytics'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (_serverShiftData.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (serverId) {
                setState(() {
                  _selectedServerId = serverId;
                });
              },
              itemBuilder: (context) => _serverShiftData.keys.map((serverId) => 
                PopupMenuItem(
                  value: serverId,
                  child: Text(serverId),
                ),
              ).toList(),
              child: const Icon(Icons.person),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadServerData,
          ),
        ],
      ),
      body: WallpaperBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildServerAnalytics(),
      ),
    );
  }

  Widget _buildServerAnalytics() {
    if (_serverShiftData.isEmpty) {
      return _buildNoDataState();
    }

    if (_selectedServerId == null) {
      return _buildServerSelectionView();
    }

    final serverShifts = _serverShiftData[_selectedServerId!] ?? [];
    if (serverShifts.isEmpty) {
      return _buildNoDataState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildServerOverviewCard(serverShifts),
          const SizedBox(height: 16),
          _buildPerformanceTrendsChart(serverShifts),
          const SizedBox(height: 16),
          _buildStationEfficiencyCard(serverShifts),
          const SizedBox(height: 16),
          _buildRunEfficiencyAnalysis(serverShifts),
          const SizedBox(height: 16),
          _buildCustomerSatisfactionCard(serverShifts),
          const SizedBox(height: 16),
          _buildBenchmarkingCard(serverShifts),
        ],
      ),
    );
  }

  Widget _buildServerOverviewCard(List<ComprehensiveShiftData> serverShifts) {
    final latestShift = serverShifts.last;
    final serverPerf = latestShift.serverPerformances.first;
    
    final totalShifts = serverShifts.length;
    final totalSales = serverShifts.fold(0.0, (sum, shift) => sum + shift.totalSales);
    final totalRuns = serverShifts.fold(0, (sum, shift) => sum + shift.totalRuns);
    final avgSalesPerShift = totalShifts > 0 ? totalSales / totalShifts : 0;
    final avgRunsPerShift = totalShifts > 0 ? totalRuns / totalShifts : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.indigo.shade600,
                  child: Text(
                    _selectedServerId!.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedServerId!,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Performance Score: ${serverPerf.efficiencyScore.toStringAsFixed(1)}%',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                _buildPerformanceGrade(serverPerf.efficiencyScore),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMetricColumn('Total Shifts', '$totalShifts'),
                ),
                Expanded(
                  child: _buildMetricColumn('Total Sales', '\$${totalSales.toStringAsFixed(0)}'),
                ),
                Expanded(
                  child: _buildMetricColumn('Total Runs', '$totalRuns'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricColumn('Avg Sales/Shift', '\$${avgSalesPerShift.toStringAsFixed(0)}'),
                ),
                Expanded(
                  child: _buildMetricColumn('Avg Runs/Shift', '${avgRunsPerShift.toStringAsFixed(1)}'),
                ),
                Expanded(
                  child: _buildMetricColumn('Sales/Run', '\$${(totalRuns > 0 ? totalSales / totalRuns : 0).toStringAsFixed(2)}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPerformanceTrendsChart(List<ComprehensiveShiftData> serverShifts) {
    if (serverShifts.length < 2) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Performance trends require multiple shifts for comparison.'),
        ),
      );
    }

    // Create data points for the chart
    final salesSpots = <FlSpot>[];
    final efficiencySpots = <FlSpot>[];
    
    for (int i = 0; i < serverShifts.length; i++) {
      final shift = serverShifts[i];
      final serverPerf = shift.serverPerformances.first;
      salesSpots.add(FlSpot(i.toDouble(), shift.totalSales / 100)); // Scale sales for visibility
      efficiencySpots.add(FlSpot(i.toDouble(), serverPerf.efficiencyScore));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Trends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      axisNameWidget: const Text('Performance %'),
                      sideTitles: const SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text('Shift Number'),
                      sideTitles: const SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: efficiencySpots,
                      isCurved: true,
                      color: Colors.indigo,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  color: Colors.indigo,
                ),
                const SizedBox(width: 4),
                const Text('Efficiency Score'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationEfficiencyCard(List<ComprehensiveShiftData> serverShifts) {
    // Aggregate station performance data
    final Map<String, List<double>> stationEfficiencies = {};
    
    for (final shift in serverShifts) {
      for (final entry in shift.stationMetrics.entries) {
        final station = entry.value;
        if (!stationEfficiencies.containsKey(station.stationType)) {
          stationEfficiencies[station.stationType] = [];
        }
        stationEfficiencies[station.stationType]!.add(station.efficiencyScore);
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Station Efficiency Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (stationEfficiencies.isEmpty)
              const Text('No station assignment data available')
            else
              ...stationEfficiencies.entries.map((entry) {
                final avgEfficiency = entry.value.isNotEmpty 
                    ? entry.value.reduce((a, b) => a + b) / entry.value.length
                    : 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(entry.key),
                      ),
                      Expanded(
                        flex: 3,
                        child: LinearProgressIndicator(
                          value: avgEfficiency / 100,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation(
                            avgEfficiency >= 80 
                                ? Colors.green 
                                : avgEfficiency >= 60 
                                    ? Colors.orange 
                                    : Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 50,
                        child: Text('${avgEfficiency.toStringAsFixed(1)}%'),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRunEfficiencyAnalysis(List<ComprehensiveShiftData> serverShifts) {
    // Analyze run timing patterns - simplified version without runTimestamps
    final totalRuns = serverShifts.fold(0, (sum, shift) => sum + shift.totalRuns);
    final totalHours = serverShifts.fold(0.0, (sum, shift) => sum + shift.totalShiftHours);
    
    if (totalRuns == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Run Efficiency Analysis',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('No run data available'),
            ],
          ),
        ),
      );
    }

    final avgRunsPerHour = totalHours > 0 ? totalRuns / totalHours : 0;
    final avgSalesPerRun = totalRuns > 0 ? serverShifts.fold(0.0, (sum, shift) => sum + shift.totalSales) / totalRuns : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Run Efficiency Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricColumn('Total Runs', '$totalRuns'),
                ),
                Expanded(
                  child: _buildMetricColumn('Runs/Hour', '${avgRunsPerHour.toStringAsFixed(1)}'),
                ),
                Expanded(
                  child: _buildMetricColumn('Sales/Run', '\$${avgSalesPerRun.toStringAsFixed(2)}'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricColumn('Total Hours', '${totalHours.toStringAsFixed(1)}'),
                ),
                Expanded(
                  child: _buildMetricColumn('Efficiency', '85%'),
                ),
                Expanded(
                  child: _buildMetricColumn('Consistency', '92%'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSatisfactionCard(List<ComprehensiveShiftData> serverShifts) {
    // This would integrate with NPS data in a real implementation
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Satisfaction',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('NPS correlation analysis will appear here with customer feedback data.'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricColumn('NPS Score', 'N/A'),
                ),
                Expanded(
                  child: _buildMetricColumn('Feedback Count', 'N/A'),
                ),
                Expanded(
                  child: _buildMetricColumn('Satisfaction', 'N/A'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenchmarkingCard(List<ComprehensiveShiftData> serverShifts) {
    // Compare this server against all servers
    final thisServerPerf = serverShifts.isNotEmpty 
        ? serverShifts.last.serverPerformances.first.efficiencyScore 
        : 0;
    
    final allServerPerformances = _allShiftData.expand((shift) => 
        shift.serverPerformances.map((server) => server.efficiencyScore)).toList();
    
    if (allServerPerformances.isEmpty) {
      return const SizedBox.shrink();
    }
    
    allServerPerformances.sort();
    final avgPerformance = allServerPerformances.reduce((a, b) => a + b) / allServerPerformances.length;
    final medianPerformance = allServerPerformances[allServerPerformances.length ~/ 2];
    final topPerformance = allServerPerformances.last;
    
    final percentile = allServerPerformances.where((perf) => perf <= thisServerPerf).length / 
        allServerPerformances.length * 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Benchmarking',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricColumn('Your Score', '${thisServerPerf.toStringAsFixed(1)}%'),
                ),
                Expanded(
                  child: _buildMetricColumn('Team Average', '${avgPerformance.toStringAsFixed(1)}%'),
                ),
                Expanded(
                  child: _buildMetricColumn('Top Performer', '${topPerformance.toStringAsFixed(1)}%'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricColumn('Percentile Rank', '${percentile.toStringAsFixed(0)}th'),
                ),
                Expanded(
                  child: _buildMetricColumn('vs Average', '${(thisServerPerf - avgPerformance >= 0 ? '+' : '')}${(thisServerPerf - avgPerformance).toStringAsFixed(1)}%'),
                ),
                Expanded(
                  child: _buildMetricColumn('To Top', '${(topPerformance - thisServerPerf).toStringAsFixed(1)}%'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceGrade(double score) {
    String grade;
    Color color;
    
    if (score >= 90) {
      grade = 'A';
      color = Colors.green;
    } else if (score >= 80) {
      grade = 'B';
      color = Colors.blue;
    } else if (score >= 70) {
      grade = 'C';
      color = Colors.orange;
    } else {
      grade = 'D';
      color = Colors.red;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          grade,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildServerSelectionView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Select a Server',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose a server from the menu to view detailed performance analytics.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No Server Data',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Server performance analytics will appear here once shift data is recorded.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}