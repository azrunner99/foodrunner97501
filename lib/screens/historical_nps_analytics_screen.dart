import 'package:flutter/material.dart';
import '../models/historical_nps_data.dart';
import '../services/historical_nps_aggregation_service.dart';
import '../services/performance_timeline_service.dart';
import '../services/historical_data_validation_service.dart';
import '../utils/log.dart';

/// Screen to demonstrate Phase 1: Historical Data Foundation
class HistoricalNPSAnalyticsScreen extends StatefulWidget {
  @override
  _HistoricalNPSAnalyticsScreenState createState() => _HistoricalNPSAnalyticsScreenState();
}

class _HistoricalNPSAnalyticsScreenState extends State<HistoricalNPSAnalyticsScreen> {
  List<HistoricalNPSData> _historicalData = [];
  List<PerformanceTimeline> _timelines = [];
  ValidationReport? _validationReport;
  bool _isLoading = true;
  String _selectedServerId = '';

  @override
  void initState() {
    super.initState();
    _loadHistoricalData();
  }

  Future<void> _loadHistoricalData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      d('[HistoricalNPSAnalyticsScreen] Loading historical data...');
      
      // Load historical data for all servers
      final historicalData = await HistoricalNPSAggregationService.instance.getAllHistoricalData();
      
      // Load performance timelines
      final timelines = await PerformanceTimelineService.instance.getAllTimelines();
      
      // Run data validation
      final validationReport = await HistoricalDataValidationService.instance.validateAllHistoricalData();
      
      setState(() {
        _historicalData = historicalData;
        _timelines = timelines;
        _validationReport = validationReport;
        _isLoading = false;
      });
      
      d('[HistoricalNPSAnalyticsScreen] Loaded ${historicalData.length} servers with historical data');
    } catch (e) {
      d('[HistoricalNPSAnalyticsScreen] Error loading historical data: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading historical data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historical NPS Analytics'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistoricalData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_historicalData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildValidationSummary(),
          const SizedBox(height: 20),
          _buildServerSelector(),
          const SizedBox(height: 20),
          if (_selectedServerId.isNotEmpty) _buildServerDetails(),
          const SizedBox(height: 20),
          _buildAllServersOverview(),
        ],
      ),
    );
  }

  Widget _buildValidationSummary() {
    if (_validationReport == null) return const SizedBox.shrink();

    final stats = _validationReport!.summaryStats;
    final healthScore = _validationReport!.overallHealthScore;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: healthScore >= 0.8 ? Colors.green : healthScore >= 0.6 ? Colors.orange : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Data Quality Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Overall Health',
                    '${(healthScore * 100).toStringAsFixed(1)}%',
                    healthScore >= 0.8 ? Colors.green : healthScore >= 0.6 ? Colors.orange : Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Total Servers',
                    stats['totalServers'].toString(),
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Critical Issues',
                    stats['criticalIssues'].toString(),
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'High Quality',
                    stats['highQuality'].toString(),
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
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
          ),
        ],
      ),
    );
  }

  Widget _buildServerSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Server for Detailed Analysis',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
                color: Colors.white,
              ),
              child: InkWell(
                onTap: () => _showServerPicker(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedServerId.isEmpty 
                            ? 'Select Server' 
                            : _historicalData
                                .firstWhere((data) => data.serverId == _selectedServerId, orElse: () => _historicalData.first)
                                .serverName,
                          style: TextStyle(
                            color: _selectedServerId.isEmpty ? Colors.grey : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.black),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showServerPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Server'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _historicalData.length,
              itemBuilder: (context, index) {
                final data = _historicalData[index];
                return ListTile(
                  title: Text(
                    data.serverName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedServerId = data.serverId;
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildServerDetails() {
    if (_historicalData.isEmpty || _timelines.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No historical data available',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );
    }

    final historicalData = _historicalData.firstWhere(
      (data) => data.serverId == _selectedServerId,
      orElse: () => _historicalData.first,
    );

    final timeline = _timelines.firstWhere(
      (t) => t.serverId == _selectedServerId,
      orElse: () => _timelines.first,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getClassificationColor(historicalData.classification).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getClassificationColor(historicalData.classification).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '${historicalData.classification.emoji} ${historicalData.classification.displayName}',
                    style: TextStyle(
                      color: _getClassificationColor(historicalData.classification),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Overall Score',
                    '${historicalData.overallPerformanceScore.toStringAsFixed(1)}%',
                    _getScoreColor(historicalData.overallPerformanceScore),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Trend',
                    _getTrendText(timeline.trend.direction),
                    _getTrendColor(timeline.trend.direction),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Volatility',
                    '${timeline.volatility.toStringAsFixed(1)}',
                    _getVolatilityColor(timeline.volatility),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Monthly Performance History',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...historicalData.monthlyData.take(6).map((monthly) => _buildMonthlyPerformanceCard(monthly)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
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
              fontSize: 16,
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
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyPerformanceCard(MonthlyPerformance monthly) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${monthly.month.month}/${monthly.month.year}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              '1M: ${monthly.oneMonthNPS.toStringAsFixed(1)}%',
              style: TextStyle(
                color: _getScoreColor(monthly.oneMonthNPS),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '3M: ${monthly.threeMonthNPS.toStringAsFixed(1)}%',
              style: TextStyle(
                color: _getScoreColor(monthly.threeMonthNPS),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'All: ${monthly.allTimeNPS.toStringAsFixed(1)}%',
              style: TextStyle(
                color: _getScoreColor(monthly.allTimeNPS),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllServersOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Servers Overview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ..._historicalData.map((data) => _buildServerOverviewCard(data)),
          ],
        ),
      ),
    );
  }

  Widget _buildServerOverviewCard(HistoricalNPSData data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              '${data.overallPerformanceScore.toStringAsFixed(1)}%',
              style: TextStyle(
                color: _getScoreColor(data.overallPerformanceScore),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              data.classification.displayName,
              style: TextStyle(
                color: _getClassificationColor(data.classification),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${data.totalMonthsReported} months',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getClassificationColor(PerformanceClassification classification) {
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

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getTrendText(TrendDirection direction) {
    switch (direction) {
      case TrendDirection.improving:
        return '↗ Improving';
      case TrendDirection.declining:
        return '↘ Declining';
      case TrendDirection.volatile:
        return '↕ Volatile';
      case TrendDirection.stable:
        return '→ Stable';
    }
  }

  Color _getTrendColor(TrendDirection direction) {
    switch (direction) {
      case TrendDirection.improving:
        return Colors.green;
      case TrendDirection.declining:
        return Colors.red;
      case TrendDirection.volatile:
        return Colors.orange;
      case TrendDirection.stable:
        return Colors.blue;
    }
  }

  Color _getVolatilityColor(double volatility) {
    if (volatility < 10) return Colors.green;
    if (volatility < 20) return Colors.orange;
    return Colors.red;
  }
}






