import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../models/performance_models.dart';
import '../utils/performance_calculator.dart';
import '../utils/performance_analyzer.dart';
import '../utils/trend_analyzer.dart';
import '../widgets/performance_charts.dart';
import '../storage.dart';
import 'bulk_data_entry_screen.dart';
import 'server_performance_profile_screen.dart';

class ServerPerformanceScreen extends StatefulWidget {
  const ServerPerformanceScreen({super.key});

  @override
  State<ServerPerformanceScreen> createState() => _ServerPerformanceScreenState();
}

class _ServerPerformanceScreenState extends State<ServerPerformanceScreen> {
  bool _isLoading = true;
  String _selectedTimeframe = '30_days';
  List<ServerPerformanceData> _performanceData = [];
  MonthlyBusinessData? _currentBusinessData;
  bool _showDataEntryPrompt = false;
  
  // Advanced analytics data
  Map<String, PerformanceTrendAnalysis> _trendAnalyses = {};
  TeamAnalytics? _teamAnalytics;
  Map<String, PeerAnalysis> _peerAnalyses = {};
  Map<String, SeasonalAnalysis> _seasonalAnalyses = {};

  final Map<String, String> _timeframeOptions = {
    '7_days': 'Last 7 Days',
    '30_days': 'Last 30 Days',
    '90_days': 'Last 90 Days',
    'all_time': 'All Time',
  };

  @override
  void initState() {
    super.initState();
    _loadPerformanceData();
    _checkDataEntryStatus();
  }

  Future<void> _loadPerformanceData() async {
    setState(() => _isLoading = true);
    
    try {
      final app = context.read<AppState>();
      final endDate = DateTime.now();
      final startDate = _getStartDateForTimeframe(endDate, _selectedTimeframe);
      
      // Get shifts for the selected period
      final shifts = app.history.where((shift) {
        return shift.start.isAfter(startDate.subtract(const Duration(days: 1))) &&
               shift.start.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();

      // Get business data for the current month
      final monthKey = Storage.generateMonthKey(DateTime.now());
      final businessDataMap = await Storage.getMonthlyBusinessData(monthKey);
      _currentBusinessData = businessDataMap != null 
          ? MonthlyBusinessData.fromMap(businessDataMap)
          : null;

      // Calculate performance for each server
      final performanceDataList = <ServerPerformanceData>[];
      final trendAnalyses = <String, PerformanceTrendAnalysis>{};
      final peerAnalyses = <String, PeerAnalysis>{};
      final seasonalAnalyses = <String, SeasonalAnalysis>{};
      
      // Load NPS history for performance calculations
      final npsHistory = await PerformanceCalculator.loadNPSHistory(
        startDate: startDate,
        endDate: endDate,
      );
      
      for (final server in app.servers) {
        // Use actual hire date or default to 6 months ago for servers without hire date
        final hireDate = server.hireDate ?? DateTime.now().subtract(const Duration(days: 180));
        
        final performance = PerformanceCalculator.calculateServerPerformance(
          serverId: server.id,
          startDate: startDate,
          endDate: endDate,
          shifts: shifts,
          businessData: _currentBusinessData,
          hireDate: hireDate,
          npsHistory: npsHistory,
          totalServerCount: app.servers.length,
        );
        
        performanceDataList.add(performance);
        
        // Generate trend analysis
        final trendAnalysis = TrendAnalyzer.analyzePerformanceTrends(
          serverId: server.id,
          shifts: shifts,
          analysisWindowDays: _getAnalysisWindowDays(_selectedTimeframe),
        );
        trendAnalyses[server.id] = trendAnalysis;
        
        // Generate seasonal analysis
        final seasonalAnalysis = TrendAnalyzer.analyzeSeasonalPatterns(
          serverId: server.id,
          shifts: app.history, // Use all history for seasonal patterns
          monthsToAnalyze: 12,
        );
        seasonalAnalyses[server.id] = seasonalAnalysis;
      }

      // Generate team analytics
      TeamAnalytics? teamAnalytics;
      if (performanceDataList.isNotEmpty) {
        final scores = performanceDataList.map((p) => p.performanceScore).toList();
        final meanScore = scores.reduce((a, b) => a + b) / scores.length;
        final variance = scores.map((s) => (s - meanScore) * (s - meanScore)).reduce((a, b) => a + b) / scores.length;
        final standardDeviation = math.sqrt(variance);
        
        teamAnalytics = TeamAnalytics(
          totalServers: performanceDataList.length,
          averageScore: meanScore,
          standardDeviation: standardDeviation,
          highestScore: scores.reduce((a, b) => a > b ? a : b),
          lowestScore: scores.reduce((a, b) => a < b ? a : b),
          distribution: PerformanceDistribution(
            elite: performanceDataList.where((p) => p.rating == PerformanceRating.elite).length,
            strong: performanceDataList.where((p) => p.rating == PerformanceRating.strong).length,
            developing: performanceDataList.where((p) => p.rating == PerformanceRating.developing).length,
            needsAttention: performanceDataList.where((p) => p.rating == PerformanceRating.needsAttention).length,
            critical: performanceDataList.where((p) => p.rating == PerformanceRating.critical).length,
          ),
          topPerformers: performanceDataList.take(3).toList(),
          bottomPerformers: performanceDataList.skip(performanceDataList.length > 3 ? performanceDataList.length - 3 : 0).toList(),
          teamTrends: TeamTrends(improving: 0, stable: performanceDataList.length, declining: 0),
          riskAssessment: RiskAssessment(
            overallRiskLevel: 'Low',
            highRiskServers: performanceDataList.where((p) => p.rating == PerformanceRating.critical).length,
            mediumRiskServers: performanceDataList.where((p) => p.rating == PerformanceRating.needsAttention).length,
            lowRiskServers: performanceDataList.where((p) => p.rating != PerformanceRating.critical && p.rating != PerformanceRating.needsAttention).length,
          ),
        );
      }

      // Generate peer analyses
      for (final server in app.servers) {
        final serverPerformance = performanceDataList.firstWhere(
          (p) => p.serverId == server.id,
          orElse: () => performanceDataList.first,
        );
        
        final peerAnalysis = PeerAnalysis(
          serverPerformance: serverPerformance,
          tenureBracket: 'regular', // Simplified
          totalPeers: performanceDataList.length,
          peerRanking: performanceDataList.indexWhere((p) => p.serverId == server.id) + 1,
          peerPercentile: ((performanceDataList.length - performanceDataList.indexWhere((p) => p.serverId == server.id)) / performanceDataList.length) * 100,
          averageScore: teamAnalytics?.averageScore ?? 0.0,
          topPerformerScore: teamAnalytics?.highestScore ?? 0.0,
          bottomPerformerScore: teamAnalytics?.lowestScore ?? 0.0,
          comparativeMetrics: ComparativeMetrics.empty(),
          insights: ['Performance analysis available'],
        );
        peerAnalyses[server.id] = peerAnalysis;
      }

      // Sort by performance score (highest first)
      performanceDataList.sort((a, b) => b.performanceScore.compareTo(a.performanceScore));

      setState(() {
        _performanceData = performanceDataList;
        _trendAnalyses = trendAnalyses;
        _teamAnalytics = teamAnalytics;
        _peerAnalyses = peerAnalyses;
        _seasonalAnalyses = seasonalAnalyses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading performance data: $e')),
        );
      }
    }
  }

  Future<void> _checkDataEntryStatus() async {
    final isDue = await Storage.isBusinessDataEntryDue();
    setState(() => _showDataEntryPrompt = isDue);
  }

  DateTime _getStartDateForTimeframe(DateTime endDate, String timeframe) {
    switch (timeframe) {
      case '7_days':
        return endDate.subtract(const Duration(days: 7));
      case '30_days':
        return endDate.subtract(const Duration(days: 30));
      case '90_days':
        return endDate.subtract(const Duration(days: 90));
      case 'all_time':
        return DateTime(2020, 1, 1); // Far back date
      default:
        return endDate.subtract(const Duration(days: 30));
    }
  }

  int _getAnalysisWindowDays(String timeframe) {
    switch (timeframe) {
      case '7_days':
        return 7;
      case '30_days':
        return 30;
      case '90_days':
        return 90;
      case 'all_time':
        return 365;
      default:
        return 30;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Server Performance'),
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadPerformanceData,
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showSettingsDialog,
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.leaderboard), text: 'Rankings'),
              Tab(icon: Icon(Icons.trending_up), text: 'Trends'),
              Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
              Tab(icon: Icon(Icons.bar_chart), text: 'Charts'),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.green.shade50,
                Colors.white,
              ],
            ),
          ),
          child: Column(
            children: [
              if (_showDataEntryPrompt) _buildDataEntryPrompt(),
              _buildTimeframeSelector(),
              if (_isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildPerformanceRankings(),
                      _buildTrendsView(),
                      _buildAnalyticsView(),
                      _buildChartsView(),
                    ],
                  ),
                ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showDataEntryDialog,
          backgroundColor: Colors.green.shade700,
          child: const Icon(Icons.add_chart, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildDataEntryPrompt() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Data Entry Due',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                const Text('Guest counts and sales data needed for accurate performance analysis'),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _showDataEntryDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enter Data'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('Timeframe: ', style: TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedTimeframe,
              isExpanded: true,
              items: _timeframeOptions.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedTimeframe = value);
                  _loadPerformanceData();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceRankings() {
    if (_performanceData.isEmpty) {
      return _buildEmptyState();
    }
    return _buildPerformanceList();
  }

  Widget _buildTrendsView() {
    if (_performanceData.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performance Trends',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if (_trendAnalyses.isNotEmpty)
                  ..._performanceData.take(3).map((performance) {
                    final trendAnalysis = _trendAnalyses[performance.serverId];
                    if (trendAnalysis == null) return const SizedBox();
                    
                    final server = context.read<AppState>().servers.firstWhere(
                      (s) => s.id == performance.serverId,
                      orElse: () => Server(id: performance.serverId, name: 'Unknown'),
                    );
                    
                    return Column(
                      children: [
                        ListTile(
                          title: Text(server.name),
                          subtitle: Text('${trendAnalysis.trendDirection.name.toUpperCase()} trend'),
                          trailing: Text(
                            '${(trendAnalysis.confidence * 100).toStringAsFixed(0)}% confidence',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        Container(
                          height: 200,
                          child: PerformanceChartWidgets.performanceTrendChart(
                            trendAnalysis: trendAnalysis,
                            context: context,
                          ),
                        ),
                        const Divider(),
                      ],
                    );
                  })
                else
                  const Center(
                    child: Text('No trend data available'),
                  ),
              ],
            ),
          ),
        ),
        if (_seasonalAnalyses.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seasonal Patterns',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ..._seasonalAnalyses.entries.take(2).map((entry) {
                    final server = context.read<AppState>().servers.firstWhere(
                      (s) => s.id == entry.key,
                      orElse: () => Server(id: entry.key, name: 'Unknown'),
                    );
                    
                    return Column(
                      children: [
                        ListTile(
                          title: Text('${server.name} - Weekly Pattern'),
                        ),
                        Container(
                          height: 200,
                          child: PerformanceChartWidgets.weeklyPatternChart(
                            dayOfWeekPatterns: entry.value.dayOfWeekPatterns,
                            context: context,
                          ),
                        ),
                        const Divider(),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAnalyticsView() {
    if (_teamAnalytics == null) {
      return _buildEmptyState();
    }
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Team Overview Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Team Analytics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildAnalyticsMetric(
                        'Team Average',
                        _teamAnalytics!.averageScore.toStringAsFixed(1),
                        Icons.group,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildAnalyticsMetric(
                        'Top Performer',
                        _teamAnalytics!.highestScore.toStringAsFixed(1),
                        Icons.star,
                        Colors.amber, // Changed from Colors.gold
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildAnalyticsMetric(
                        'Total Servers',
                        _teamAnalytics!.totalServers.toString(),
                        Icons.people,
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildAnalyticsMetric(
                        'Risk Level',
                        _teamAnalytics!.riskAssessment.overallRiskLevel,
                        Icons.warning,
                        _getRiskColor(_teamAnalytics!.riskAssessment.overallRiskLevel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Performance Distribution
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performance Distribution',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Container(
                  height: 200,
                  child: PerformanceChartWidgets.performanceDistributionChart(
                    distribution: {
                      PerformanceRating.elite: _teamAnalytics!.distribution.elite,
                      PerformanceRating.strong: _teamAnalytics!.distribution.strong,
                      PerformanceRating.developing: _teamAnalytics!.distribution.developing,
                      PerformanceRating.needsAttention: _teamAnalytics!.distribution.needsAttention,
                      PerformanceRating.critical: _teamAnalytics!.distribution.critical,
                    },
                    context: context,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Peer Comparisons
        if (_peerAnalyses.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Peer Comparisons',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ..._peerAnalyses.entries.take(5).map((entry) {
                    final server = context.read<AppState>().servers.firstWhere(
                      (s) => s.id == entry.key,
                      orElse: () => Server(id: entry.key, name: 'Unknown'),
                    );
                    final peerAnalysis = entry.value;
                    
                    return ListTile(
                      title: Text(server.name),
                      subtitle: Text('Rank ${peerAnalysis.peerRanking} of ${peerAnalysis.totalPeers}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${peerAnalysis.peerPercentile.toStringAsFixed(1)}%',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'percentile',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChartsView() {
    if (_performanceData.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Performance Comparison Chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performance Comparison',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Container(
                  height: 300,
                  child: PerformanceChartWidgets.performanceComparisonChart(
                    performanceData: Map.fromEntries(
                      _performanceData.map((p) {
                        final server = context.read<AppState>().servers.firstWhere(
                          (s) => s.id == p.serverId,
                          orElse: () => Server(id: p.serverId, name: 'Unknown'),
                        );
                        return MapEntry(server.name, p.performanceScore);
                      }),
                    ),
                    currentServerId: _performanceData.isNotEmpty ? 
                      context.read<AppState>().servers.firstWhere(
                        (s) => s.id == _performanceData.first.serverId,
                        orElse: () => Server(id: '', name: ''),
                      ).name : '',
                    context: context,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Performance Velocity Indicators
        if (_trendAnalyses.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance Velocity',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ..._trendAnalyses.entries.take(3).map((entry) {
                    final server = context.read<AppState>().servers.firstWhere(
                      (s) => s.id == entry.key,
                      orElse: () => Server(id: entry.key, name: 'Unknown'),
                    );
                    
                    // Calculate velocity from trend data
                    final velocity = TrendAnalyzer.calculatePerformanceVelocity(
                      entry.value.dailyTrends.map((d) => PerformanceTrend(
                        date: d.date,
                        score: d.score,
                        foodRuns: d.totalRuns,
                        shifts: d.shiftsWorked,
                      )).toList(),
                    );
                    
                    return Column(
                      children: [
                        ListTile(
                          title: Text(server.name),
                          subtitle: Text('Velocity Category: ${velocity.category.name}'),
                        ),
                        PerformanceChartWidgets.performanceVelocityIndicator(
                          velocity: velocity,
                          context: context,
                        ),
                        const Divider(),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
        
        const SizedBox(height: 16),
        
        // Performance Insights
        if (_trendAnalyses.isNotEmpty) ...[
          ..._trendAnalyses.entries.take(2).map((entry) {
            final seasonalAnalysis = _seasonalAnalyses[entry.key];
            
            return Column(
              children: [
                PerformanceInsightsWidget(
                  trendAnalysis: entry.value,
                  seasonalAnalysis: seasonalAnalysis,
                ),
                const SizedBox(height: 16),
              ],
            );
          }),
        ],
      ],
    );
  }

  Widget _buildAnalyticsMetric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Performance Data Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add business data to see performance metrics',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showDataEntryDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Business Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _performanceData.length,
      itemBuilder: (context, index) {
        final performance = _performanceData[index];
        final server = context.read<AppState>().servers.firstWhere(
          (s) => s.id == performance.serverId,
          orElse: () => Server(id: performance.serverId, name: 'Unknown Server'),
        );
        
        return _buildPerformanceCard(server, performance, index + 1);
      },
    );
  }

  Widget _buildPerformanceCard(Server server, ServerPerformanceData performance, int rank) {
    final rankColor = _getRankColor(rank);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showPerformanceDetails(server, performance),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: rankColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '#$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          server.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${performance.rating.emoji} ${performance.rating.displayName}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        performance.formattedScore,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _getScoreColor(performance.performanceScore),
                        ),
                      ),
                      Text(
                        'Performance Score',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildMetricChip('Runs', '${performance.totalFoodRuns}', Icons.local_dining),
                  const SizedBox(width: 8),
                  _buildMetricChip('Shifts', '${performance.shiftsWorked}', Icons.schedule),
                  const SizedBox(width: 8),
                  _buildMetricChip(
                    'Avg/Shift', 
                    performance.shiftsWorked > 0 
                        ? (performance.totalFoodRuns / performance.shiftsWorked).toStringAsFixed(1)
                        : '0.0', 
                    Icons.trending_up,
                  ),
                ],
              ),
              if (performance.flags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: performance.flags.take(3).map((flag) {
                    return Chip(
                      label: Text(
                        '${flag.emoji} ${flag.displayName}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.green.shade700),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber.shade600; // Gold
    if (rank == 2) return Colors.grey.shade600; // Silver
    if (rank == 3) return Colors.brown.shade600; // Bronze
    return Colors.blue.shade600; // Default
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green.shade700;
    if (score >= 75) return Colors.blue.shade700;
    if (score >= 60) return Colors.orange.shade700;
    if (score >= 45) return Colors.red.shade700;
    return Colors.red.shade900;
  }

  void _showPerformanceDetails(Server server, ServerPerformanceData performance) {
    // Navigate to the dedicated Server Performance Profile Screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServerPerformanceProfileScreen(
          server: server,
          performance: performance,
        ),
      ),
    );
  }

  void _showDataEntryDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BulkDataEntryScreen(
          initialMonth: DateTime.now(),
          existingBusinessData: _currentBusinessData,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadPerformanceData(); // Refresh the performance data
      }
    });
  }

  void _showSettingsDialog() {
    // TODO: Implement settings dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Performance Settings'),
        content: const Text('Performance calculation settings coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}