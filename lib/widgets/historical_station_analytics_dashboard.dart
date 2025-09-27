/// Historical Station Analytics Dashboard
/// Phase 4: Displays big picture insights, seasonal patterns, and long-term trends

import 'package:flutter/material.dart';
import '../services/historical_station_analytics_service.dart';
import '../utils/log.dart';

class HistoricalStationAnalyticsDashboard extends StatefulWidget {
  final String sectionName;
  final String stationType;
  final List<dynamic> allSectionData;

  const HistoricalStationAnalyticsDashboard({
    Key? key,
    required this.sectionName,
    required this.stationType,
    required this.allSectionData,
  }) : super(key: key);

  @override
  State<HistoricalStationAnalyticsDashboard> createState() => _HistoricalStationAnalyticsDashboardState();
}

class _HistoricalStationAnalyticsDashboardState extends State<HistoricalStationAnalyticsDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  HistoricalStationAnalysis? _analysis;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAnalysis();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalysis() async {
    try {
      setState(() => _isLoading = true);
      
      final service = HistoricalStationAnalyticsService();
      final analysis = await service.generateHistoricalAnalysis(
        sectionName: widget.sectionName,
        stationType: widget.stationType,
        shiftRecords: [], // Would be passed from parent
        servers: [], // Would be passed from parent
        monthsToAnalyze: 6,
      );
      
      setState(() {
        _analysis = analysis;
        _isLoading = false;
      });
    } catch (e) {
      d('[HistoricalAnalyticsDashboard] Error loading analysis: $e');
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
            Text('Error loading historical analysis', style: TextStyle(fontSize: 18, color: Colors.red.shade700)),
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Colors.red.shade600)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAnalysis,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_analysis == null) {
      return const Center(child: Text('No historical data available'));
    }

    return Column(
      children: [
        // Tab bar
        Container(
          color: Colors.purple.shade50,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.purple.shade700,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: Colors.purple.shade700,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
              Tab(text: 'Seasonal', icon: Icon(Icons.calendar_today)),
              Tab(text: 'Monthly', icon: Icon(Icons.trending_up)),
              Tab(text: 'Staffing', icon: Icon(Icons.people)),
              Tab(text: 'Capacity', icon: Icon(Icons.analytics)),
            ],
          ),
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildSeasonalTab(),
              _buildMonthlyTab(),
              _buildStaffingTab(),
              _buildCapacityTab(),
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
          // Analysis header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.history, color: Colors.purple.shade600, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _analysis!.sectionName,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_analysis!.stationType} Station - Historical Analysis',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                        Text(
                          '${_analysis!.totalMonthsAnalyzed} months analyzed',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Key metrics
          Row(
            children: [
              Expanded(child: _buildMetricCard('Seasons', '${_analysis!.seasonalPatterns.length}', Icons.calendar_today, Colors.blue)),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricCard('Peak Periods', '${_analysis!.peakPeriods.length}', Icons.trending_up, Colors.green)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildMetricCard('Staff Patterns', '${_analysis!.staffingPatterns.length}', Icons.people, Colors.orange)),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricCard('Insights', '${_analysis!.insights.length}', Icons.lightbulb, Colors.purple)),
            ],
          ),
          const SizedBox(height: 16),
          
          // Top insights
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
                      const Text('Key Historical Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._analysis!.insights.take(3).map((insight) => _buildInsightItem(insight)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Seasonal Performance Patterns', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ..._analysis!.seasonalPatterns.map((pattern) => _buildSeasonalCard(pattern)),
        ],
      ),
    );
  }

  Widget _buildMonthlyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Monthly Performance Trends', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ..._analysis!.monthlyTrends.map((trend) => _buildMonthlyCard(trend)),
        ],
      ),
    );
  }

  Widget _buildStaffingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Staffing Pattern Analysis', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ..._analysis!.staffingPatterns.map((pattern) => _buildStaffingCard(pattern)),
        ],
      ),
    );
  }

  Widget _buildCapacityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Capacity Planning Insights', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildCapacityCard(_analysis!.capacityInsights),
        ],
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

  Widget _buildInsightItem(HistoricalInsight insight) {
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
              Text(
                '${(insight.confidence * 100).toStringAsFixed(0)}%',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(insight.description),
        ],
      ),
    );
  }

  Widget _buildSeasonalCard(SeasonalPattern pattern) {
    Color trendColor;
    IconData trendIcon;
    
    switch (pattern.trend) {
      case SeasonalTrend.improving:
        trendColor = Colors.green;
        trendIcon = Icons.trending_up;
        break;
      case SeasonalTrend.declining:
        trendColor = Colors.red;
        trendIcon = Icons.trending_down;
        break;
      case SeasonalTrend.stable:
        trendColor = Colors.blue;
        trendIcon = Icons.trending_flat;
        break;
      case SeasonalTrend.volatile:
        trendColor = Colors.orange;
        trendIcon = Icons.trending_up;
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
                Icon(trendIcon, color: trendColor),
                const SizedBox(width: 8),
                Text(
                  pattern.season,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${pattern.averagePerformance.toStringAsFixed(1)} avg',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(pattern.description),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: pattern.characteristics.map((char) => Chip(
                label: Text(char),
                backgroundColor: trendColor.withOpacity(0.1),
                labelStyle: TextStyle(color: trendColor),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyCard(MonthlyPerformance monthly) {
    Color trendColor;
    IconData trendIcon;
    
    switch (monthly.trend) {
      case MonthlyTrend.improving:
        trendColor = Colors.green;
        trendIcon = Icons.trending_up;
        break;
      case MonthlyTrend.declining:
        trendColor = Colors.red;
        trendIcon = Icons.trending_down;
        break;
      case MonthlyTrend.stable:
        trendColor = Colors.blue;
        trendIcon = Icons.trending_flat;
        break;
      case MonthlyTrend.newData:
        trendColor = Colors.grey;
        trendIcon = Icons.new_releases;
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
                Icon(trendIcon, color: trendColor),
                const SizedBox(width: 8),
                Text(
                  '${monthly.month.month}/${monthly.month.year}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${monthly.performanceScore.toStringAsFixed(1)}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMiniMetric('Runs', '${monthly.totalRuns}', Icons.directions_run),
                ),
                Expanded(
                  child: _buildMiniMetric('Shifts', '${monthly.totalShifts}', Icons.work),
                ),
                Expanded(
                  child: _buildMiniMetric('Avg/Shift', '${monthly.averageRunsPerShift.toStringAsFixed(1)}', Icons.analytics),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildStaffingCard(StaffingPattern pattern) {
    Color recommendationColor;
    IconData recommendationIcon;
    
    switch (pattern.recommendation) {
      case StaffingRecommendation.increase:
        recommendationColor = Colors.green;
        recommendationIcon = Icons.arrow_upward;
        break;
      case StaffingRecommendation.maintain:
        recommendationColor = Colors.blue;
        recommendationIcon = Icons.remove;
        break;
      case StaffingRecommendation.decrease:
        recommendationColor = Colors.orange;
        recommendationIcon = Icons.arrow_downward;
        break;
      case StaffingRecommendation.train:
        recommendationColor = Colors.amber;
        recommendationIcon = Icons.school;
        break;
      case StaffingRecommendation.reassign:
        recommendationColor = Colors.red;
        recommendationIcon = Icons.swap_horiz;
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
                Icon(recommendationIcon, color: recommendationColor),
                const SizedBox(width: 8),
                Text(
                  pattern.serverName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${pattern.averagePerformanceWhenInSection.toStringAsFixed(1)}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${pattern.totalShiftsInSection} shifts in section'),
            const SizedBox(height: 12),
            if (pattern.strengths.isNotEmpty) ...[
              const Text('Strengths:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: pattern.strengths.map((strength) => Chip(
                  label: Text(strength),
                  backgroundColor: Colors.green.withOpacity(0.1),
                  labelStyle: const TextStyle(color: Colors.green, fontSize: 12),
                )).toList(),
              ),
              const SizedBox(height: 8),
            ],
            if (pattern.improvementAreas.isNotEmpty) ...[
              const Text('Areas for Improvement:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: pattern.improvementAreas.map((area) => Chip(
                  label: Text(area),
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  labelStyle: const TextStyle(color: Colors.orange, fontSize: 12),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCapacityCard(CapacityPlanningInsights capacity) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.purple.shade600),
                const SizedBox(width: 8),
                const Text('Capacity Planning', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Text(capacity.summary),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCapacityMetric('Min Staffing', '${capacity.recommendedMinStaffing}', Colors.blue),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCapacityMetric('Max Staffing', '${capacity.recommendedMaxStaffing}', Colors.green),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCapacityMetric('Utilization', '${(capacity.utilizationRate * 100).toStringAsFixed(0)}%', Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (capacity.recommendations.isNotEmpty) ...[
              const Text('Recommendations:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...capacity.recommendations.map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: Colors.purple.shade600)),
                    Expanded(child: Text(rec)),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCapacityMetric(String label, String value, Color color) {
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
}

