/// Real-Time Station Monitor Widget
/// Live monitoring of station performance during active shifts

import 'package:flutter/material.dart';
import 'dart:async';

import '../models/station_performance_metric.dart';
import '../services/station_analytics_service.dart';

class RealTimeStationMonitor extends StatefulWidget {
  final Map<String, int> currentCounts;
  final Map<String, String> stationAssignments;

  const RealTimeStationMonitor({
    Key? key,
    required this.currentCounts,
    required this.stationAssignments,
  }) : super(key: key);

  @override
  State<RealTimeStationMonitor> createState() => _RealTimeStationMonitorState();
}

class _RealTimeStationMonitorState extends State<RealTimeStationMonitor> {
  List<RealTimeStationMetric> _stationMetrics = [];
  Timer? _refreshTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRealTimeData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(RealTimeStationMonitor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentCounts != oldWidget.currentCounts ||
        widget.stationAssignments != oldWidget.stationAssignments) {
      _loadRealTimeData();
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadRealTimeData();
      }
    });
  }

  Future<void> _loadRealTimeData() async {
    try {
      final metrics = await StationAnalyticsService.getRealTimeStationMetrics(
        currentCounts: widget.currentCounts,
        currentStationAssignments: widget.stationAssignments,
      );
      
      if (mounted) {
        setState(() {
          _stationMetrics = metrics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_stationMetrics.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment, size: 32, color: Colors.grey),
              SizedBox(height: 8),
              Text('No station assignments', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            const Text(
              'Station Performance',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Icon(Icons.refresh, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              'Auto-refresh 30s',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _stationMetrics.length,
          itemBuilder: (context, index) {
            return _buildStationCard(_stationMetrics[index]);
          },
        ),
        if (_stationMetrics.any((m) => m.isAlert))
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _buildAlertSummary(),
          ),
      ],
    );
  }

  Widget _buildStationCard(RealTimeStationMetric metric) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: metric.isAlert ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: metric.isAlert ? Colors.red.shade200 : Colors.green.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  metric.stationType,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (metric.isAlert)
                Icon(
                  Icons.warning,
                  color: Colors.red.shade600,
                  size: 16,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${metric.currentRuns}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              const Text('runs', style: TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.people, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                '${metric.activeServers} servers',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.speed, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                '${metric.currentRunRate.toStringAsFixed(1)}/hr',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertSummary() {
    final alertMetrics = _stationMetrics.where((m) => m.isAlert).toList();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.red.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Performance Alerts (${alertMetrics.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...alertMetrics.map((metric) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Text(
                  '• ${metric.stationType}:',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    metric.alertMessage ?? 'Performance below target',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}

/// Station Performance Summary Card for dashboard overview
class StationPerformanceSummaryCard extends StatelessWidget {
  final String stationType;
  final double efficiency;
  final int totalRuns;
  final double trendPercentage;
  final VoidCallback? onTap;

  const StationPerformanceSummaryCard({
    Key? key,
    required this.stationType,
    required this.efficiency,
    required this.totalRuns,
    required this.trendPercentage,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      stationType,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _buildTrendIndicator(),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildMetricColumn(
                    'Efficiency',
                    '${efficiency.toStringAsFixed(1)}%',
                    _getEfficiencyColor(efficiency),
                  ),
                  const SizedBox(width: 24),
                  _buildMetricColumn(
                    'Total Runs',
                    totalRuns.toString(),
                    Colors.blue.shade600,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendIndicator() {
    Color color;
    IconData icon;
    
    if (trendPercentage > 5) {
      color = Colors.green;
      icon = Icons.trending_up;
    } else if (trendPercentage < -5) {
      color = Colors.red;
      icon = Icons.trending_down;
    } else {
      color = Colors.grey;
      icon = Icons.trending_flat;
    }
    
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          '${trendPercentage.abs().toStringAsFixed(1)}%',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Color _getEfficiencyColor(double efficiency) {
    if (efficiency >= 80) return Colors.green;
    if (efficiency >= 60) return Colors.orange;
    return Colors.red;
  }
}