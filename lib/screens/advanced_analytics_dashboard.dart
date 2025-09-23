/// Advanced Restaurant Analytics Dashboard
/// Comprehensive visualization of performance correlations and insights

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../app_state.dart';
import '../models/comprehensive_shift_data.dart';
import '../services/multi_variable_correlation_engine.dart';
import '../services/comprehensive_shift_capture_service.dart';
import '../widgets/wallpaper_background.dart';

class AdvancedAnalyticsDashboard extends StatefulWidget {
  const AdvancedAnalyticsDashboard({super.key});

  @override
  State<AdvancedAnalyticsDashboard> createState() => _AdvancedAnalyticsDashboardState();
}

class _AdvancedAnalyticsDashboardState extends State<AdvancedAnalyticsDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  CorrelationAnalysisResult? _analysisResult;
  List<ComprehensiveShiftData> _shiftData = [];
  bool _isLoading = false;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load comprehensive shift data
      final shiftData = await ComprehensiveShiftCaptureService.getStoredShiftData();
      
      // Run correlation analysis
      final analysisResult = await MultiVariableCorrelationEngine.runFullCorrelationAnalysis(
        startDate: _selectedDateRange?.start,
        endDate: _selectedDateRange?.end,
      );

      setState(() {
        _shiftData = shiftData;
        _analysisResult = analysisResult;
        _isLoading = false;
      });
    } catch (e) {
      print('[ADVANCED_ANALYTICS] Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Analytics'),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
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
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.insights), text: 'Insights'),
            Tab(icon: Icon(Icons.trending_up), text: 'Correlations'),
            Tab(icon: Icon(Icons.people), text: 'Server Profiles'),
            Tab(icon: Icon(Icons.money), text: 'Revenue Analytics'),
            Tab(icon: Icon(Icons.psychology), text: 'Predictions'),
          ],
        ),
      ),
      body: WallpaperBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildInsightsTab(),
                  _buildCorrelationsTab(),
                  _buildServerProfilesTab(),
                  _buildRevenueAnalyticsTab(),
                  _buildPredictionsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildInsightsTab() {
    if (_analysisResult == null) {
      return _buildNoDataState('Performance insights will appear here once you have sufficient shift data.');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalysisSummaryCard(),
          const SizedBox(height: 16),
          ..._analysisResult!.insights.map((insight) => _buildInsightCard(insight)),
        ],
      ),
    );
  }

  Widget _buildCorrelationsTab() {
    if (_analysisResult?.significantCorrelations.isEmpty ?? true) {
      return _buildNoDataState('Correlation analysis will show relationships between performance variables.');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Significant Performance Correlations',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ..._analysisResult!.significantCorrelations.map((correlation) => 
            _buildCorrelationCard(correlation)),
        ],
      ),
    );
  }

  Widget _buildServerProfilesTab() {
    if (_analysisResult?.serverProfiles.isEmpty ?? true) {
      return _buildNoDataState('Individual server performance profiles will appear here.');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Server Performance Profiles',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ..._analysisResult!.serverProfiles.values.map((profile) => 
            _buildServerProfileCard(profile)),
        ],
      ),
    );
  }

  Widget _buildRevenueAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRevenueOverviewCard(),
          const SizedBox(height: 16),
          _buildSalesCorrelationChart(),
          const SizedBox(height: 16),
          _buildStationProfitabilityCard(),
        ],
      ),
    );
  }

  Widget _buildPredictionsTab() {
    if (_analysisResult?.predictiveModels.isEmpty ?? true) {
      return _buildNoDataState('Predictive models will be built from correlation analysis.');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Predictive Performance Models',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ..._analysisResult!.predictiveModels.map((model) => 
            _buildPredictiveModelCard(model)),
        ],
      ),
    );
  }

  Widget _buildAnalysisSummaryCard() {
    final result = _analysisResult!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.deepPurple.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Analysis Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryMetric('Insights Found', '${result.insights.length}'),
                ),
                Expanded(
                  child: _buildSummaryMetric('Correlations', '${result.significantCorrelations.length}'),
                ),
                Expanded(
                  child: _buildSummaryMetric('Server Profiles', '${result.serverProfiles.length}'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Analysis Date: ${DateFormat('MMM dd, yyyy HH:mm').format(result.analysisDate)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildInsightCard(PerformanceInsight insight) {
    Color categoryColor;
    IconData categoryIcon;
    
    switch (insight.category) {
      case 'correlation':
        categoryColor = Colors.blue;
        categoryIcon = Icons.insights;
        break;
      case 'pattern':
        categoryColor = Colors.green;
        categoryIcon = Icons.pattern;
        break;
      case 'optimization':
        categoryColor = Colors.orange;
        categoryIcon = Icons.tune;
        break;
      case 'anomaly':
        categoryColor = Colors.red;
        categoryIcon = Icons.warning;
        break;
      default:
        categoryColor = Colors.grey;
        categoryIcon = Icons.info;
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
                Icon(categoryIcon, color: categoryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    insight.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Chip(
                  label: Text(
                    '${(insight.confidence * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: categoryColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(insight.description),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.blue.shade600, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insight.recommendation,
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
            if (insight.supportingData.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                children: insight.supportingData.map((data) => 
                  Chip(
                    label: Text(data, style: const TextStyle(fontSize: 12)),
                    backgroundColor: Colors.grey.shade100,
                  ),
                ).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCorrelationCard(VariableCorrelation correlation) {
    final strengthColor = correlation.isStrongCorrelation 
        ? Colors.red 
        : correlation.isModerateCorrelation 
            ? Colors.orange 
            : Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${correlation.variable1} ↔ ${correlation.variable2}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: strengthColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'r = ${correlation.correlation.toStringAsFixed(3)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(correlation.interpretation),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('R²: ${correlation.rSquared.toStringAsFixed(3)}'),
                const SizedBox(width: 16),
                Text('p-value: ${correlation.pValue.toStringAsFixed(3)}'),
                const SizedBox(width: 16),
                Text('n = ${correlation.sampleSize}'),
              ],
            ),
            if (correlation.dataPoints.length > 5 && correlation.dataPoints.length < 50) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: _buildCorrelationScatterPlot(correlation),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCorrelationScatterPlot(VariableCorrelation correlation) {
    final spots = correlation.dataPoints.map((point) => 
        ScatterSpot(point.x, point.y)).toList();

    return ScatterChart(
      ScatterChartData(
        scatterSpots: spots,
        minX: spots.map((s) => s.x).reduce((a, b) => a < b ? a : b) - 1,
        maxX: spots.map((s) => s.x).reduce((a, b) => a > b ? a : b) + 1,
        minY: spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 1,
        maxY: spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 1,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: Text(correlation.variable2, style: const TextStyle(fontSize: 12)),
            sideTitles: const SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: Text(correlation.variable1, style: const TextStyle(fontSize: 12)),
            sideTitles: const SideTitles(showTitles: true, reservedSize: 40),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: true),
      ),
    );
  }

  Widget _buildServerProfileCard(ServerCorrelationProfile profile) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(profile.serverName.substring(0, 1)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.serverName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Performance Score: ${profile.overallPerformanceScore.toStringAsFixed(1)}%',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                _buildPerformanceGrade(profile.overallPerformanceScore),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Key Metrics:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: profile.variableAverages.entries.map((entry) =>
                _buildMetricChip(entry.key, entry.value),
              ).toList(),
            ),
            if (profile.improvementAreas.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Improvement Areas:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: profile.improvementAreas.map((area) =>
                  Chip(
                    label: Text(area, style: const TextStyle(fontSize: 12)),
                    backgroundColor: Colors.orange.shade100,
                  ),
                ).toList(),
              ),
            ],
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

  Widget _buildMetricChip(String label, double value) {
    String formattedValue;
    if (label.contains('efficiency') || label.contains('score')) {
      formattedValue = '${value.toStringAsFixed(1)}%';
    } else if (label.contains('sales') || label.contains('tips')) {
      formattedValue = '\$${value.toStringAsFixed(0)}';
    } else {
      formattedValue = value.toStringAsFixed(1);
    }

    return Chip(
      label: Text('$label: $formattedValue', style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.blue.shade50,
    );
  }

  Widget _buildRevenueOverviewCard() {
    if (_shiftData.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Revenue analytics require shift data with sales information.'),
        ),
      );
    }

    final totalSales = _shiftData.fold(0.0, (sum, shift) => sum + shift.totalSales);
    final totalRuns = _shiftData.fold(0, (sum, shift) => sum + shift.totalRuns);
    final avgSalesPerRun = totalRuns > 0 ? totalSales / totalRuns : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryMetric('Total Sales', '\$${totalSales.toStringAsFixed(0)}'),
                ),
                Expanded(
                  child: _buildSummaryMetric('Total Runs', '$totalRuns'),
                ),
                Expanded(
                  child: _buildSummaryMetric('Sales/Run', '\$${avgSalesPerRun.toStringAsFixed(2)}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesCorrelationChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sales vs Runs Correlation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              child: const Center(
                child: Text('Sales correlation chart will display with sufficient data'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationProfitabilityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Station Profitability Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 150,
              child: const Center(
                child: Text('Station profitability metrics will appear with station assignment data'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictiveModelCard(PredictiveModel model) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.purple.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    model.modelName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Chip(
                  label: Text(
                    'Accuracy: ${(model.accuracy * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: Colors.purple.shade600,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Predicts: ${model.targetVariable}'),
            Text('Based on: ${model.predictorVariables.join(', ')}'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                model.formula,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Analytics Coming Soon',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      _loadAnalyticsData();
    }
  }
}