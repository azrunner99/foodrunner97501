/// Station Analytics Dashboard Screen
/// Comprehensive analytics interface for station performance monitoring

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../app_state.dart';
import '../models.dart';
import '../storage.dart';
import '../models/station_performance_metric.dart';
import '../services/station_analytics_service.dart';
import '../widgets/real_time_station_monitor.dart';

class StationAnalyticsScreen extends StatefulWidget {
  const StationAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<StationAnalyticsScreen> createState() => _StationAnalyticsScreenState();
}

class _StationAnalyticsScreenState extends State<StationAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<StationComparisonData> _stationComparisons = [];
  List<String> _performanceInsights = [];
  Map<String, double> _stationEfficiencies = {};
  DateTime _selectedStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _selectedEndDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load actual shift records from storage
      final List<Map> rawRecords = 
          (await Storage.shiftsBox.get('list') as List?)?.cast<Map>() ?? [];
      
      // Convert to ShiftRecord objects  
      final allRecords = rawRecords.map((json) => 
          ShiftRecord.fromMap(Map<String, dynamic>.from(json))).toList();
      
      print('[STATION_ANALYTICS] Loaded ${allRecords.length} shift records');
      
      // Load analytics with real data
      final comparisons = await StationAnalyticsService.compareStationPerformance();
      final insights = await StationAnalyticsService.getPerformanceInsights();
      final efficiencies = await StationAnalyticsService.calculateStationEfficiency(allRecords);
      
      print('[STATION_ANALYTICS] Station efficiencies: $efficiencies');
      print('[STATION_ANALYTICS] Comparisons: ${comparisons.length} items');
      
      setState(() {
        _stationComparisons = comparisons;
        _performanceInsights = insights;
        _stationEfficiencies = efficiencies;
        _isLoading = false;
      });
    } catch (e) {
      print('[STATION_ANALYTICS] Error loading data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Station Analytics'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.trending_up), text: 'Trends'),
            Tab(icon: Icon(Icons.insights), text: 'Insights'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildTrendsTab(),
                _buildInsightsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRealTimeSection(),
            const SizedBox(height: 24),
            _buildStationComparisonSection(),
            const SizedBox(height: 24),
            _buildEfficiencyOverviewSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDateRangeSelector(),
          const SizedBox(height: 24),
          _buildTrendChartsSection(),
          const SizedBox(height: 24),
          _buildPerformanceMatrixSection(),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInsightsSection(),
          const SizedBox(height: 24),
          _buildRecommendationsSection(),
        ],
      ),
    );
  }

  Widget _buildRealTimeSection() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.live_tv, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    const Text(
                      'Real-Time Monitoring',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (appState.shiftActive)
                  RealTimeStationMonitor(
                    currentCounts: appState.currentCounts,
                    stationAssignments: appState.currentStationAssignments,
                  )
                else
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pause_circle_outline, size: 32, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('No active shift', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStationComparisonSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Station Performance Comparison',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_stationComparisons.isEmpty)
              Container(
                height: 200,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, size: 48, color: Colors.amber.shade600),
                    const SizedBox(height: 12),
                    const Text(
                      'Station Performance Comparison',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Charts will appear when you have shift data with station assignments.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 300,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() < _stationComparisons.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _stationComparisons[value.toInt()].stationType,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text('${value.toInt()}%');
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: _stationComparisons.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: data.currentEfficiency,
                            color: _getEfficiencyColor(data.currentEfficiency),
                            width: 20,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEfficiencyOverviewSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Station Efficiency Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_stationEfficiencies.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade600),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'No station data available yet. Station analytics will appear once shifts with station assignments are completed.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: _stationEfficiencies.entries.map((entry) => 
                  _buildStationEfficiencyRow(entry.key, entry.value)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationEfficiencyRow(String stationType, double efficiency) {
    final color = _getEfficiencyColor(efficiency);
    final grade = _getEfficiencyGrade(efficiency);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              stationType,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${efficiency.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                'Grade: $grade',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getEfficiencyGrade(double efficiency) {
    if (efficiency >= 90) return 'A+';
    if (efficiency >= 80) return 'A';
    if (efficiency >= 70) return 'B';
    if (efficiency >= 60) return 'C';
    if (efficiency >= 50) return 'D';
    return 'F';
  }

  Widget _buildStationEfficiencyCard(StationComparisonData data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.stationType,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${data.currentEfficiency.toStringAsFixed(1)}% efficiency',
                  style: TextStyle(color: _getEfficiencyColor(data.currentEfficiency)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(
                    data.trendPercentage > 0 ? Icons.trending_up : 
                    data.trendPercentage < 0 ? Icons.trending_down : Icons.trending_flat,
                    color: data.trendPercentage > 0 ? Colors.green : 
                           data.trendPercentage < 0 ? Colors.red : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${data.trendPercentage.abs().toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: data.trendPercentage > 0 ? Colors.green : 
                             data.trendPercentage < 0 ? Colors.red : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '${data.totalShifts} shifts',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ListTile(
                leading: const Icon(Icons.date_range),
                title: Text(DateFormat.yMd().format(_selectedStartDate)),
                subtitle: const Text('Start Date'),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedStartDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _selectedStartDate = date);
                    _loadAnalyticsData();
                  }
                },
              ),
            ),
            Expanded(
              child: ListTile(
                leading: const Icon(Icons.date_range),
                title: Text(DateFormat.yMd().format(_selectedEndDate)),
                subtitle: const Text('End Date'),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedEndDate,
                    firstDate: _selectedStartDate,
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _selectedEndDate = date);
                    _loadAnalyticsData();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChartsSection() {
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
            Container(
              height: 250,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up, size: 48, color: Colors.purple.shade600),
                  const SizedBox(height: 12),
                  const Text(
                    'Performance Trends',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Historical trend analysis will appear as you accumulate more shift data over time.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMatrixSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Server-Station Performance Matrix',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.grid_view, size: 48, color: Colors.teal.shade600),
                  const SizedBox(height: 12),
                  const Text(
                    'Performance Matrix',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Detailed server performance by station will show here when you have sufficient data.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Performance Insights',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_performanceInsights.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.psychology, color: Colors.orange.shade600),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'AI-powered insights will appear here as you collect more data from your restaurant operations.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: _performanceInsights.map((insight) => _buildInsightCard(insight)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(String insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(insight)),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.green.shade600),
                const SizedBox(width: 8),
                const Text(
                  'AI Recommendations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Smart recommendations will be available in Phase 2'),
          ],
        ),
      ),
    );
  }

  Color _getEfficiencyColor(double efficiency) {
    if (efficiency >= 80) return Colors.green;
    if (efficiency >= 60) return Colors.orange;
    return Colors.red;
  }

  // Helper to get current station assignments from app state
  Map<String, String> get currentStationAssignments {
    final appState = Provider.of<AppState>(context, listen: false);
    // This would need to be implemented in AppState to provide current station assignments
    // For now, return empty map
    return {};
  }
}