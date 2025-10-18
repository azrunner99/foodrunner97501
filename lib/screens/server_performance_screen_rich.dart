import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../models/performance_models.dart';
import '../providers/nps_provider.dart';
import '../utils/performance_calculator.dart';
import '../utils/performance_analyzer.dart' as pa;
import '../utils/trend_analyzer.dart' as ta;
import '../widgets/performance_charts.dart';
import '../storage.dart';
import 'bulk_data_entry_screen.dart';
import 'server_performance_profile_screen.dart';

class ServerPerformanceScreenRich extends StatefulWidget {
  const ServerPerformanceScreenRich({super.key});

  @override
  State<ServerPerformanceScreenRich> createState() =>
      _ServerPerformanceScreenRichState();
}

class _ServerPerformanceScreenRichState extends State<ServerPerformanceScreenRich> {    
  bool _isLoading = true;
  String _selectedTimeframe = '30_days';
  List<ServerPerformanceData> _performanceData = [];
  MonthlyBusinessData? _currentBusinessData;
  bool _showDataEntryPrompt = false;

  // Advanced analytics data
  Map<String, ta.PerformanceTrendAnalysis> _trendAnalyses = {};
  pa.TeamAnalytics? _teamAnalytics;
  Map<String, pa.PeerAnalysis> _peerAnalyses = {};
  Map<String, ta.SeasonalAnalysis> _seasonalAnalyses = {};

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
  final trendAnalyses = <String, ta.PerformanceTrendAnalysis>{};
  final peerAnalyses = <String, pa.PeerAnalysis>{};
  final seasonalAnalyses = <String, ta.SeasonalAnalysis>{};

      // Load NPS history for performance calculations with NPSProvider
      final npsHistory = await PerformanceCalculator.loadNPSHistory(
        startDate: startDate,
        endDate: endDate,
        npsProvider: npsProvider,
      );

      for (final server in app.activeServers) { // Only show active servers in rankings
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
          totalServerCount: app.activeServers.length,
        );

        performanceDataList.add(performance);

        // Calculate trend analysis
        final trendAnalysis = pa.PerformanceAnalyzer.analyzePerformanceTrend(
          serverId: server.id,
          shifts: shifts,
          startDate: startDate,
          endDate: endDate,
        );
        trendAnalyses[server.id] = trendAnalysis;

        // Calculate seasonal analysis
        final seasonalAnalysis = ta.TrendAnalyzer.analyzeSeasonalPatterns(
          serverId: server.id,
          shifts: shifts,
          monthsToAnalyze: 6,
        );
        seasonalAnalyses[server.id] = seasonalAnalysis;
      }

      // Sort by performance score
      final sortedByScore = performanceDataList
        ..sort((a, b) => b.performanceScore.compareTo(a.performanceScore));

      // Calculate team analytics
      final teamAnalytics = pa.PerformanceAnalyzer.calculateTeamAnalytics(
        performanceDataList,
      );

      // Calculate peer analyses
      for (int i = 0; i < sortedByScore.length; i++) {
        final performance = sortedByScore[i];
        final ranking = i + 1;
        final percentile = (ranking / sortedByScore.length * 100).round();
        String _bracket(int days) {
          if (days <= 30) return 'new';
          if (days <= 90) return 'junior';
          if (days <= 180) return 'regular';
          return 'senior';
        }
        final peerAnalysis = pa.PeerAnalysis(
          serverPerformance: performance,
          tenureBracket: _bracket(performance.daysEmployed),
          totalPeers: sortedByScore.length,
          peerRanking: ranking,
            peerPercentile: percentile.toDouble(),
          averageScore: teamAnalytics.averageScore,
          topPerformerScore: teamAnalytics.highestScore,
          bottomPerformerScore: teamAnalytics.lowestScore,
          comparativeMetrics: pa.ComparativeMetrics.empty(),
          insights: const ['Peer comparison available'],
        );
        peerAnalyses[performance.serverId] = peerAnalysis;
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Business data entry is due. Update sales and guest counts for accurate performance calculations.',
              style: TextStyle(color: Colors.orange.shade700),
            ),
          ),
          TextButton(
            onPressed: _showDataEntryDialog,
            child: const Text('Enter Data'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Colors.green),
          const SizedBox(width: 8),
          const Text('Timeframe: '),
          DropdownButton<String>(
            value: _selectedTimeframe,
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() => _selectedTimeframe = newValue);
                _loadPerformanceData();
              }
            },
            items: _timeframeOptions.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceRankings() {
    if (_performanceData.isEmpty) {
      return const Center(
        child: Text('No performance data available for the selected timeframe.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _performanceData.length,
      itemBuilder: (context, index) {
        final performance = _performanceData[index];
        final server = context.read<AppState>().servers.firstWhere(
          (s) => s.id == performance.serverId,
          orElse: () => Server(id: performance.serverId, name: 'Unknown'),
        );
        return _buildRichPerformanceCard(server, performance, index + 1);
      },
    );
  }

  Widget _buildRichPerformanceCard(
      Server server, ServerPerformanceData performance, int rank) {
    final rankColor = _getRankColor(rank);
    final trendAnalysis = _trendAnalyses[server.id];
  final peerAnalysis = _peerAnalyses[server.id];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showPerformanceDetails(server, performance),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Rank Badge
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: rankColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: rankColor.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '#$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Server Name and Rating
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          server.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '${performance.rating.emoji} ${performance.rating.displayName}',
                          style: TextStyle(
                            fontSize: 14,
                            color: _getRatingColor(performance.rating),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Performance Score
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getScoreColor(performance.performanceScore).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getScoreColor(performance.performanceScore).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      performance.formattedScore,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(performance.performanceScore),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Performance Flags and Insights (Rich Display)
              if (performance.flags.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: performance.flags.map((flag) {
                    return _buildFlagChip(flag);
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],

              // Metrics Row
              Row(
                children: [
                  Expanded(
                    child: _buildMetricChip(
                      'Runs', 
                      '${performance.totalFoodRuns}', 
                      Icons.local_dining,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricChip(
                      'Shifts', 
                      '${performance.shiftsWorked}', 
                      Icons.schedule,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricChip(
                      'Avg/Shift',
                      performance.shiftsWorked > 0
                          ? (performance.totalFoodRuns / performance.shiftsWorked)
                              .toStringAsFixed(1)
                          : '—',
                      Icons.trending_up,
                      Colors.orange,
                    ),
                  ),
                ],
              ),

              // Additional Performance Indicators
              if (trendAnalysis != null) ...[
                const SizedBox(height: 12),
                _buildTrendIndicator(trendAnalysis),
              ],

              // NPS Score if available
              if (performance.metrics.npsScore > 0) ...[
                const SizedBox(height: 12),
                _buildNPSIndicator(performance.metrics.npsScore),
              ],

              // Action Items
              if (performance.insights.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: performance.insights.take(2).map((insight) {
                    return _buildInsightChip(insight);
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlagChip(PerformanceFlag flag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getFlagColor(flag).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getFlagColor(flag).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getFlagIcon(flag),
            size: 14,
            color: _getFlagColor(flag),
          ),
          const SizedBox(width: 4),
          Text(
            '${flag.emoji} ${flag.displayName}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getFlagColor(flag),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(ta.PerformanceTrendAnalysis trend) {
    final trendColor = _getTrendColor(trend.trendDirection);
    final trendIcon = _getTrendIcon(trend.trendDirection);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: trendColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: trendColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(trendIcon, color: trendColor, size: 16),
          const SizedBox(width: 8),
          Text(
            'Trend: ${_getTrendText(trend.trendDirection)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: trendColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNPSIndicator(double npsScore) {
    final npsColor = _getNPSColor(npsScore);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: npsColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: npsColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.sentiment_satisfied, color: npsColor, size: 16),
          const SizedBox(width: 8),
          Text(
            'NPS Score: ${npsScore.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: npsColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightChip(PerformanceInsight insight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getInsightColor(insight.type).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getInsightColor(insight.type).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getInsightIcon(insight.type),
            size: 14,
            color: _getInsightColor(insight.type),
          ),
          const SizedBox(width: 4),
          Text(
            insight.title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getInsightColor(insight.type),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for colors and icons
  Color _getRankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700); // Gold
    if (rank == 2) return const Color(0xFFC0C0C0); // Silver
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze
    if (rank <= 5) return Colors.green;
    if (rank <= 10) return Colors.blue;
    return Colors.grey;
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return const Color(0xFF1B5E20);
    if (score >= 80) return const Color(0xFF2E7D32);
    if (score >= 70) return const Color(0xFF388E3C);
    if (score >= 60) return const Color(0xFFF57C00);
    if (score >= 50) return const Color(0xFFFF9800);
    if (score >= 40) return const Color(0xFFD32F2F);
    return const Color(0xFFB71C1C);
  }

  Color _getRatingColor(PerformanceRating rating) {
    switch (rating) {
      case PerformanceRating.elite:
        return const Color(0xFF1B5E20);
      case PerformanceRating.strong:
        return const Color(0xFF2E7D32);
      case PerformanceRating.developing:
        return const Color(0xFFF57C00);
      case PerformanceRating.needsAttention:
        return const Color(0xFFD32F2F);
      case PerformanceRating.critical:
        return const Color(0xFFB71C1C);
    }
  }

  Color _getFlagColor(PerformanceFlag flag) {
    switch (flag) {
      case PerformanceFlag.highPerformer:
        return Colors.purple;
      case PerformanceFlag.decliningTrend:
        return Colors.orange;
      case PerformanceFlag.inconsistent:
        return Colors.orange;
      case PerformanceFlag.lowEfficiency:
        return Colors.red;
      case PerformanceFlag.newHire:
        return Colors.blue;
      case PerformanceFlag.teamLeader:
        return Colors.green;
      case PerformanceFlag.recognitionDue:
        return Colors.amber;
      case PerformanceFlag.coachingNeeded:
        return Colors.red;
    }
  }

  IconData _getFlagIcon(PerformanceFlag flag) {
    switch (flag) {
      case PerformanceFlag.highPerformer:
        return Icons.star;
      case PerformanceFlag.decliningTrend:
        return Icons.trending_down;
      case PerformanceFlag.inconsistent:
        return Icons.trending_flat;
      case PerformanceFlag.lowEfficiency:
        return Icons.warning;
      case PerformanceFlag.newHire:
        return Icons.person_add;
      case PerformanceFlag.teamLeader:
        return Icons.leaderboard;
      case PerformanceFlag.recognitionDue:
        return Icons.emoji_events;
      case PerformanceFlag.coachingNeeded:
        return Icons.school;
    }
  }

  Color _getTrendColor(ta.TrendDirection direction) {
    switch (direction) {
      case ta.TrendDirection.improving:
        return Colors.green;
      case ta.TrendDirection.stable:
        return Colors.blue;
      case ta.TrendDirection.declining:
        return Colors.orange;
    }
    return Colors.grey;
  }

  IconData _getTrendIcon(ta.TrendDirection direction) {
    switch (direction) {
      case ta.TrendDirection.improving:
        return Icons.trending_up;
      case ta.TrendDirection.stable:
        return Icons.trending_flat;
      case ta.TrendDirection.declining:
        return Icons.trending_down;
    }
    return Icons.help_outline;
  }

  String _getTrendText(ta.TrendDirection direction) {
    switch (direction) {
      case ta.TrendDirection.improving:
        return 'Improving';
      case ta.TrendDirection.stable:
        return 'Stable';
      case ta.TrendDirection.declining:
        return 'Declining';
    }
    return 'Unknown';
  }

  Color _getNPSColor(double score) {
    if (score >= 80) return const Color(0xFF1B5E20);
    if (score >= 60) return const Color(0xFF2E7D32);
    if (score >= 40) return const Color(0xFFF57C00);
    return const Color(0xFFD32F2F);
  }

  Color _getInsightColor(String type) {
    switch (type) {
      case 'recommendation':
        return Colors.blue;
      case 'alert':
        return Colors.red;
      case 'recognition':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getInsightIcon(String type) {
    switch (type) {
      case 'recommendation':
        return Icons.lightbulb;
      case 'alert':
        return Icons.warning;
      case 'recognition':
        return Icons.emoji_events;
      default:
        return Icons.info;
    }
  }

  void _showPerformanceDetails(Server server, ServerPerformanceData performance) {
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
        _loadPerformanceData();
      }
    });
  }
}








