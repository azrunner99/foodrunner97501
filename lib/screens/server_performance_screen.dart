import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../models/performance_models.dart';
import '../providers/nps_provider.dart';
import '../utils/performance_calculator.dart';
import '../utils/performance_analyzer.dart';
import '../utils/trend_analyzer.dart';
import '../widgets/performance_charts.dart';
import '../storage.dart';
import 'bulk_data_entry_screen.dart';
import 'server_performance_profile_screen.dart';
import '../services/server_data_service.dart';

class ServerPerformanceScreen extends StatefulWidget {
  const ServerPerformanceScreen({super.key});

  @override
  State<ServerPerformanceScreen> createState() =>
      _ServerPerformanceScreenState();
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
      final npsProvider = context.read<NPSProvider>();
      final endDate = DateTime.now();
      final startDate = _getStartDateForTimeframe(endDate, _selectedTimeframe);

      // Get shifts for the selected period
      final shifts = app.history.where((shift) {
        return shift.start
                .isAfter(startDate.subtract(const Duration(days: 1))) &&
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

      // Load NPS history for performance calculations with NPSProvider
      final npsHistory = await PerformanceCalculator.loadNPSHistory(
        startDate: startDate,
        endDate: endDate,
        npsProvider: npsProvider,
      );

      // ⭐ Phase 1.4: Get servers using ServerDataService for unified access
      final servers = await ServerDataService.instance.getAllServers();

      for (final server in servers) {
        // Use actual hire date or default to 6 months ago for servers without hire date
        final hireDate = server.hireDate ??
            DateTime.now().subtract(const Duration(days: 180));

        final performance = PerformanceCalculator.calculateServerPerformance(
          serverId: server.id,
          startDate: startDate,
          endDate: endDate,
          shifts: shifts,
          businessData: _currentBusinessData,
          hireDate: hireDate,
          npsHistory: npsHistory,
          totalServerCount: servers.length,
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

      // Deterministic ranking: score desc, then experienceFactor desc, then serverId asc
      final sortedByScore = List<ServerPerformanceData>.from(performanceDataList)
        ..sort((a, b) {
          final scoreCmp = b.performanceScore.compareTo(a.performanceScore);
          if (scoreCmp != 0) return scoreCmp;
          final expCmp = (b.metrics.experienceFactor)
              .compareTo(a.metrics.experienceFactor);
          if (expCmp != 0) return expCmp;
          return a.serverId.compareTo(b.serverId);
        });

      // Generate team analytics using sorted data for top/bottom performers
      TeamAnalytics? teamAnalytics;
      if (sortedByScore.isNotEmpty) {
        final scores = sortedByScore.map((p) => p.performanceScore).toList();
        final meanScore = scores.reduce((a, b) => a + b) / scores.length;
        final variance = scores
                .map((s) => (s - meanScore) * (s - meanScore))
                .reduce((a, b) => a + b) /
            scores.length;
        final standardDeviation = math.sqrt(variance);

        teamAnalytics = TeamAnalytics(
          totalServers: sortedByScore.length,
          averageScore: meanScore,
          standardDeviation: standardDeviation,
          highestScore: scores.reduce((a, b) => a > b ? a : b),
          lowestScore: scores.reduce((a, b) => a < b ? a : b),
          distribution: PerformanceDistribution(
            elite: sortedByScore
                .where((p) => p.rating == PerformanceRating.elite)
                .length,
            strong: sortedByScore
                .where((p) => p.rating == PerformanceRating.strong)
                .length,
            developing: sortedByScore
                .where((p) => p.rating == PerformanceRating.developing)
                .length,
            needsAttention: sortedByScore
                .where((p) => p.rating == PerformanceRating.needsAttention)
                .length,
            critical: sortedByScore
                .where((p) => p.rating == PerformanceRating.critical)
                .length,
          ),
          topPerformers: sortedByScore.take(3).toList(),
          bottomPerformers: sortedByScore
              .skip(sortedByScore.length > 3 ? sortedByScore.length - 3 : 0)
              .toList(),
          teamTrends: TeamTrends(
              improving: 0, stable: sortedByScore.length, declining: 0),
          riskAssessment: RiskAssessment(
            overallRiskLevel: 'Low',
            highRiskServers: sortedByScore
                .where((p) => p.rating == PerformanceRating.critical)
                .length,
            mediumRiskServers: sortedByScore
                .where((p) => p.rating == PerformanceRating.needsAttention)
                .length,
            lowRiskServers: sortedByScore
                .where((p) =>
                    p.rating != PerformanceRating.critical &&
                    p.rating != PerformanceRating.needsAttention)
                .length,
          ),
        );
      }

      // Generate peer analyses using deterministic ranking
      for (int i = 0; i < sortedByScore.length; i++) {
        final perf = sortedByScore[i];
        final ranking = i + 1;
        final percentile = ((sortedByScore.length - i) / sortedByScore.length) * 100;
        peerAnalyses[perf.serverId] = PeerAnalysis(
          serverPerformance: perf,
          tenureBracket: 'regular', // TODO: integrate actual tenure bracket logic
          totalPeers: sortedByScore.length,
          peerRanking: ranking,
          peerPercentile: percentile,
          averageScore: teamAnalytics?.averageScore ?? 0.0,
          topPerformerScore: teamAnalytics?.highestScore ?? 0.0,
          bottomPerformerScore: teamAnalytics?.lowestScore ?? 0.0,
          comparativeMetrics: ComparativeMetrics.empty(),
          insights: ['Performance analysis available'],
        );
      }

      setState(() {
        _performanceData = sortedByScore;
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
    return Scaffold(
        appBar: AppBar(
          title: const Text('Server Performance'),
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
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
                  child: _buildPerformanceRankings(),
                ),
            ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.insights_outlined, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How These Scores Are Built',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Only months inside the selected timeframe contribute to NPS and timeframe-aligned sales/guest counts when month-level fields are available. Missing month fields fall back to broader historical data so scores still compute. NPS weight auto-adjusts when recent feedback is limited. Extremely high per-shift averages are capped for readability.',
                  style: TextStyle(fontSize: 12, height: 1.25),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {
                    // Optional: navigate to a deeper explanation screen or docs (placeholder)
                  },
                  child: Text(
                    'Learn more in Performance Scoring Docs',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade800,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
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
          const Text('Timeframe: ',
              style: TextStyle(fontWeight: FontWeight.w600)),
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

  Widget _buildAnalyticsMetric(
      String label, String value, IconData icon, Color color) {
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
              orElse: () =>
                  Server(id: performance.serverId, name: 'Unknown Server'),
            );

        return _buildPerformanceCard(server, performance, index + 1);
      },
    );
  }

  Widget _buildPerformanceCard(
      Server server, ServerPerformanceData performance, int rank) {
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
                  _buildMetricChip('Runs', '${performance.totalFoodRuns}',
                      Icons.local_dining),
                  const SizedBox(width: 8),
          _buildMetricChip(
            'Active Shifts', '${performance.shiftsWorked}', Icons.schedule),
                  const SizedBox(width: 8),
                  () {
                    if (performance.shiftsWorked <= 0) {
                      return _buildMetricChip('Avg/Shift', '—', Icons.trending_up);
                    }
                    final raw = performance.totalFoodRuns / performance.shiftsWorked;
                    const cap = 200.0; // display safeguard
                    final isCapped = raw > cap;
                    final shown = raw > cap ? cap : raw;
                    return _buildMetricChipWithTooltip(
                      'Avg/Shift',
                      _fmt1(shown),
                      Icons.trending_up,
                      isCapped
                          ? 'Actual value ${raw.toStringAsFixed(1)} capped at ${cap.toStringAsFixed(0)} for readability.'
                          : null,
                    );
                  }(),
                ],
              ),
              if (performance.shiftsWorked == 0) ...[
                const SizedBox(height: 6),
                Text(
                  'No shifts in selected timeframe',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
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
    return _buildMetricChipWithTooltip(label, value, icon, null);
  }

  // Extended version allowing optional tooltip (for capped values etc.)
  Widget _buildMetricChipWithTooltip(
    String label,
    String value,
    IconData icon,
    String? tooltip,
  ) {
    final chip = Container(
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
          if (tooltip != null) ...[
            const SizedBox(width: 2),
            Icon(Icons.info_outline, size: 14, color: Colors.green.shade700),
          ]
        ],
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: chip);
    }
    return chip;
  }

  // Helper to format a double with at most one decimal and strip trailing .0
  String _fmt1(double v) {
    final s = v.toStringAsFixed(1);
    if (s.endsWith('.0')) return s.substring(0, s.length - 2);
    return s;
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

  void _showPerformanceDetails(
      Server server, ServerPerformanceData performance) {
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
}
