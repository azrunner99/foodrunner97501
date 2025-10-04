/// Advanced Station Analytics Dashboard
/// Phase 3: Displays trend analysis, efficiency scoring, and performance comparisons

import 'package:flutter/material.dart';
import '../services/advanced_station_analytics_service.dart';
import '../utils/log.dart';

class AdvancedStationAnalyticsDashboard extends StatefulWidget {
  final String sectionName;
  final String stationType;
  final List<dynamic> allSectionData;

  const AdvancedStationAnalyticsDashboard({
    Key? key,
    required this.sectionName,
    required this.stationType,
    required this.allSectionData,
  }) : super(key: key);

  @override
  State<AdvancedStationAnalyticsDashboard> createState() => _AdvancedStationAnalyticsDashboardState();
}

class _AdvancedStationAnalyticsDashboardState extends State<AdvancedStationAnalyticsDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  AdvancedStationAnalytics? _analytics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    try {
      setState(() => _isLoading = true);
      
      final service = AdvancedStationAnalyticsService();
      final analytics = await service.generateAdvancedAnalytics(
        sectionName: widget.sectionName,
        stationType: widget.stationType,
        shiftRecords: [], // Would be passed from parent
        allSectionData: widget.allSectionData,
      );
      
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      d('[AdvancedAnalyticsDashboard] Error loading analytics: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text('Error loading analytics', style: TextStyle(fontSize: 18, color: Colors.red.shade700)),
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Colors.red.shade600)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAnalytics,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_analytics == null) {
      return const Center(child: Text('No analytics data available'));
    }

    return Column(
      children: [
        // Tab bar
        Container(
          color: Colors.blue.shade50,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.blue.shade700,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: Colors.blue.shade700,
            tabs: const [
              Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
              Tab(text: 'Trends', icon: Icon(Icons.trending_up)),
              Tab(text: 'Efficiency', icon: Icon(Icons.speed)),
              Tab(text: 'Comparison', icon: Icon(Icons.compare)),
            ],
          ),
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildTrendsTab(),
              _buildEfficiencyTab(),
              _buildComparisonTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.analytics, color: Colors.blue.shade600, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _analytics!.sectionName,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_analytics!.stationType} Station',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  _buildEfficiencyBadge(_analytics!.efficiencyScore.grade),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Key metrics
          Row(
            children: [
              Expanded(child: _buildMetricCard('Efficiency Score', '${_analytics!.efficiencyScore.overallScore.toStringAsFixed(1)}%', Icons.speed, Colors.green)),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricCard('Rank', '#${_analytics!.comparison.rank.toStringAsFixed(0)}', Icons.leaderboard, Colors.blue)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildMetricCard('Percentile', '${_analytics!.comparison.percentile.toStringAsFixed(0)}%', Icons.percent, Colors.orange)),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricCard('Trends', '${_analytics!.trends.length}', Icons.trending_up, Colors.purple)),
            ],
          ),
          const SizedBox(height: 16),
          
          // Recent insights
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.amber.shade600),
                      const SizedBox(width: 8),
                      const Text('Recent Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._analytics!.insights.take(3).map((insight) => _buildInsightItem(insight)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Performance Trends', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ..._analytics!.trends.map((trend) => _buildTrendCard(trend)),
        ],
      ),
    );
  }

  Widget _buildEfficiencyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Efficiency Analysis', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildEfficiencyCard(_analytics!.efficiencyScore),
        ],
      ),
    );
  }

  Widget _buildComparisonTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Performance Comparison', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildComparisonCard(_analytics!.comparison),
        ],
      ),
    );
  }

  Widget _buildEfficiencyBadge(EfficiencyGrade grade) {
    Color color;
    String text;
    
    switch (grade) {
      case EfficiencyGrade.excellent:
        color = Colors.green;
        text = 'Excellent';
        break;
      case EfficiencyGrade.good:
        color = Colors.blue;
        text = 'Good';
        break;
      case EfficiencyGrade.average:
        color = Colors.orange;
        text = 'Average';
        break;
      case EfficiencyGrade.belowAverage:
        color = Colors.red;
        text = 'Below Avg';
        break;
      case EfficiencyGrade.poor:
        color = Colors.red.shade800;
        text = 'Poor';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(PerformanceInsight insight) {
    Color priorityColor;
    switch (insight.priority) {
      case InsightPriority.high:
        priorityColor = Colors.red;
        break;
      case InsightPriority.medium:
        priorityColor = Colors.orange;
        break;
      case InsightPriority.low:
        priorityColor = Colors.blue;
        break;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: priorityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: priorityColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: priorityColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  insight.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(insight.description),
        ],
      ),
    );
  }

  Widget _buildTrendCard(PerformanceTrend trend) {
    Color directionColor;
    IconData directionIcon;
    
    switch (trend.direction) {
      case TrendDirection.improving:
        directionColor = Colors.green;
        directionIcon = Icons.trending_up;
        break;
      case TrendDirection.declining:
        directionColor = Colors.red;
        directionIcon = Icons.trending_down;
        break;
      case TrendDirection.stable:
        directionColor = Colors.blue;
        directionIcon = Icons.trending_flat;
        break;
      case TrendDirection.volatile:
        directionColor = Colors.orange;
        directionIcon = Icons.trending_up;
        break;
      case TrendDirection.unknown:
        directionColor = Colors.grey;
        directionIcon = Icons.help;
        break;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(directionIcon, color: directionColor),
                const SizedBox(width: 8),
                Text(
                  trend.metricName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${(trend.trendStrength * 100).toStringAsFixed(0)}%',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(trend.description),
            const SizedBox(height: 12),
            // Simple trend visualization
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Trend Chart Placeholder',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEfficiencyCard(EfficiencyScore efficiency) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text('Efficiency Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                _buildEfficiencyBadge(efficiency.grade),
              ],
            ),
            const SizedBox(height: 16),
            _buildEfficiencyBar('Overall Score', efficiency.overallScore, Colors.blue),
            _buildEfficiencyBar('Runs Efficiency', efficiency.runsEfficiency, Colors.green),
            _buildEfficiencyBar('Sales Efficiency', efficiency.salesEfficiency, Colors.orange),
            _buildEfficiencyBar('Time Efficiency', efficiency.timeEfficiency, Colors.purple),
            _buildEfficiencyBar('Consistency', efficiency.consistencyScore, Colors.red),
            const SizedBox(height: 16),
            if (efficiency.improvementAreas.isNotEmpty) ...[
              const Text('Improvement Areas:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...efficiency.improvementAreas.map((area) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.arrow_right, size: 16, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Text(area),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEfficiencyBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('${value.toStringAsFixed(1)}%'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(PerformanceComparison comparison) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.compare, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text('Section Comparison', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildComparisonMetric('Rank', '#${comparison.rank.toStringAsFixed(0)}', Colors.blue),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildComparisonMetric('Percentile', '${comparison.percentile.toStringAsFixed(0)}%', Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Metric Comparison:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...comparison.metrics.map((metric) => _buildComparisonMetricItem(metric)),
            const SizedBox(height: 16),
            Text(comparison.comparisonSummary),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildComparisonMetricItem(ComparisonMetric metric) {
    Color statusColor;
    IconData statusIcon;
    
    switch (metric.status) {
      case ComparisonStatus.aboveAverage:
        statusColor = Colors.green;
        statusIcon = Icons.arrow_upward;
        break;
      case ComparisonStatus.atAverage:
        statusColor = Colors.blue;
        statusIcon = Icons.remove;
        break;
      case ComparisonStatus.belowAverage:
        statusColor = Colors.red;
        statusIcon = Icons.arrow_downward;
        break;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(metric.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${metric.value.toStringAsFixed(1)} vs ${metric.average.toStringAsFixed(1)} avg'),
              ],
            ),
          ),
          Text(
            '${metric.percentageDifference > 0 ? '+' : ''}${metric.percentageDifference.toStringAsFixed(1)}%',
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}


