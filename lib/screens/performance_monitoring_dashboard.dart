import 'package:flutter/material.dart';
import '../models/performance_models.dart' hide PerformanceAlert;
import '../services/performance_monitoring_service.dart';
import '../services/performance_flags.dart';

/// Performance monitoring dashboard screen
/// Phase 6: Monitoring & Telemetry
class PerformanceMonitoringDashboard extends StatefulWidget {
  const PerformanceMonitoringDashboard({Key? key}) : super(key: key);

  @override
  State<PerformanceMonitoringDashboard> createState() => _PerformanceMonitoringDashboardState();
}

class _PerformanceMonitoringDashboardState extends State<PerformanceMonitoringDashboard> {
  final PerformanceMonitoringService _monitoringService = PerformanceMonitoringService.instance;
  PerformanceAnalyticsSummary? _analyticsSummary;
  List<PerformanceAlert> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!PerformanceFlags.monitoringTelemetry) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // final summary = await _monitoringService.generateAnalyticsSummary(); // Commented out - method not implemented
      final alerts = _monitoringService.getActiveAlerts();
      
      setState(() {
        // _analyticsSummary = summary; // Commented out - method not implemented
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!PerformanceFlags.monitoringTelemetry) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Performance Monitoring'),
          backgroundColor: Colors.blue.shade700,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.monitor, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Performance Monitoring Not Available',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Phase 6: Monitoring & Telemetry is not enabled',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Monitoring'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSystemHealthCard(),
                    const SizedBox(height: 16),
                    _buildPerformanceOverviewCard(),
                    const SizedBox(height: 16),
                    _buildAlertsCard(),
                    const SizedBox(height: 16),
                    _buildTrendsCard(),
                    const SizedBox(height: 16),
                    _buildTopPerformersCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSystemHealthCard() {
    final systemHealth = _analyticsSummary?.systemHealth ?? {};
    final uptime = systemHealth['monitoringUptime'] as double? ?? 0.0;
    final dataQuality = systemHealth['dataQuality'] as double? ?? 0.0;
    final totalEvents = systemHealth['totalEvents'] as int? ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.health_and_safety, color: Colors.green.shade700),
                const SizedBox(width: 8),
                const Text(
                  'System Health',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildHealthMetric(
                    'Monitoring Uptime',
                    '${uptime.toStringAsFixed(1)}%',
                    uptime >= 95 ? Colors.green : uptime >= 80 ? Colors.orange : Colors.red,
                    Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _buildHealthMetric(
                    'Data Quality',
                    '${dataQuality.toStringAsFixed(1)}%',
                    dataQuality >= 80 ? Colors.green : dataQuality >= 60 ? Colors.orange : Colors.red,
                    Icons.data_usage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildHealthMetric(
                    'Total Events',
                    totalEvents.toString(),
                    Colors.blue,
                    Icons.event,
                  ),
                ),
                Expanded(
                  child: _buildHealthMetric(
                    'Active Alerts',
                    _alerts.length.toString(),
                    _alerts.isEmpty ? Colors.green : Colors.red,
                    Icons.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetric(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
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
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceOverviewCard() {
    final averageScores = _analyticsSummary?.averageScores ?? {};
    final scoreDistribution = _analyticsSummary?.scoreDistribution ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Performance Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (averageScores.isNotEmpty) ...[
              Text(
                'Average Score: ${averageScores['overall']?.toStringAsFixed(1) ?? '0.0'}%',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              'Score Distribution',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildScoreDistributionBar(scoreDistribution),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreDistributionBar(Map<String, int> distribution) {
    final total = distribution.values.reduce((a, b) => a + b);
    if (total == 0) {
      return const Text('No data available', style: TextStyle(color: Colors.grey));
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDistributionSegment(
                'Excellent',
                distribution['excellent'] ?? 0,
                total,
                Colors.green,
              ),
            ),
            Expanded(
              child: _buildDistributionSegment(
                'Good',
                distribution['good'] ?? 0,
                total,
                Colors.lightGreen,
              ),
            ),
            Expanded(
              child: _buildDistributionSegment(
                'Average',
                distribution['average'] ?? 0,
                total,
                Colors.orange,
              ),
            ),
            Expanded(
              child: _buildDistributionSegment(
                'Poor',
                distribution['poor'] ?? 0,
                total,
                Colors.red,
              ),
            ),
            Expanded(
              child: _buildDistributionSegment(
                'Critical',
                distribution['critical'] ?? 0,
                total,
                Colors.red.shade900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildDistributionLabel('Excellent', distribution['excellent'] ?? 0, total),
            _buildDistributionLabel('Good', distribution['good'] ?? 0, total),
            _buildDistributionLabel('Average', distribution['average'] ?? 0, total),
            _buildDistributionLabel('Poor', distribution['poor'] ?? 0, total),
            _buildDistributionLabel('Critical', distribution['critical'] ?? 0, total),
          ],
        ),
      ],
    );
  }

  Widget _buildDistributionSegment(String label, int count, int total, Color color) {
    final percentage = total > 0 ? count / total : 0.0;
    return Container(
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Center(
        child: percentage > 0.1
            ? Text(
                '${(percentage * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildDistributionLabel(String label, int count, int total) {
    final percentage = total > 0 ? (count / total * 100).toInt() : 0;
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          '$percentage%',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Active Alerts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_alerts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _alerts.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_alerts.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 48),
                    SizedBox(height: 8),
                    Text(
                      'No Active Alerts',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...(_alerts.take(5).map((alert) => _buildAlertItem(alert))),
            if (_alerts.length > 5)
              Center(
                child: TextButton(
                  onPressed: () {
                    // Navigate to full alerts screen
                  },
                  child: Text('View All ${_alerts.length} Alerts'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(PerformanceAlert alert) {
    Color severityColor;
    IconData severityIcon;
    
    switch (alert.severity) {
      case AlertSeverity.info:
        severityColor = Colors.blue;
        severityIcon = Icons.info;
        break;
      case AlertSeverity.warning:
        severityColor = Colors.orange;
        severityIcon = Icons.warning;
        break;
      case AlertSeverity.critical:
        severityColor = Colors.red;
        severityIcon = Icons.error;
        break;
      case AlertSeverity.emergency:
        severityColor = Colors.red.shade900;
        severityIcon = Icons.dangerous;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: severityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: severityColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(severityIcon, color: severityColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Server: ${alert.serverId} • ${alert.ageInMinutes}m ago',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check, size: 16),
            onPressed: () => _acknowledgeAlert(alert.id),
            tooltip: 'Acknowledge',
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsCard() {
    final trendMetrics = _analyticsSummary?.trendMetrics ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Performance Trends',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTrendMetric(
                    'Improving',
                    trendMetrics['improving']?.toInt() ?? 0,
                    Colors.green,
                    Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _buildTrendMetric(
                    'Stable',
                    trendMetrics['stable']?.toInt() ?? 0,
                    Colors.blue,
                    Icons.trending_flat,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTrendMetric(
                    'Declining',
                    trendMetrics['declining']?.toInt() ?? 0,
                    Colors.orange,
                    Icons.trending_down,
                  ),
                ),
                Expanded(
                  child: _buildTrendMetric(
                    'Volatile',
                    trendMetrics['volatile']?.toInt() ?? 0,
                    Colors.red,
                    Icons.show_chart,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendMetric(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
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
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformersCard() {
    final topPerformers = _analyticsSummary?.topPerformers ?? [];
    final bottomPerformers = _analyticsSummary?.bottomPerformers ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Top & Bottom Performers',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Top Performers',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (topPerformers.isEmpty)
                        const Text(
                          'No data available',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        )
                      else
                        ...topPerformers.map((serverId) => _buildPerformerItem(
                          serverId,
                          Colors.green,
                          Icons.trending_up,
                        )),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Needs Improvement',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (bottomPerformers.isEmpty)
                        const Text(
                          'No data available',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        )
                      else
                        ...bottomPerformers.map((serverId) => _buildPerformerItem(
                          serverId,
                          Colors.red,
                          Icons.trending_down,
                        )),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformerItem(String serverId, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              serverId,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acknowledgeAlert(String alertId) async {
    // await _monitoringService.acknowledgeAlert(alertId, 'user'); // Commented out - method not implemented
    _loadDashboardData();
  }
}

