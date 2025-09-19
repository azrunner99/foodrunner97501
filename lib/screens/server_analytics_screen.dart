import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../app_state.dart';
import '../widgets/wallpaper_background.dart';
import '../utils/integrity_analyzer.dart';

/// Advanced analytics screen for individual server analysis
class ServerAnalyticsScreen extends StatefulWidget {
  final String serverId;
  final String serverName;

  const ServerAnalyticsScreen({
    super.key,
    required this.serverId,
    required this.serverName,
  });

  @override
  State<ServerAnalyticsScreen> createState() => _ServerAnalyticsScreenState();
}

class _ServerAnalyticsScreenState extends State<ServerAnalyticsScreen> {
  String _selectedTimeframe = 'week';
  Map<String, dynamic> _analyticsData = {};
  List<EnhancedIntegrityAssessment> _historicalAssessments = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAnalytics();
    });
  }

  void _refreshAnalytics() {
    final app = Provider.of<AppState>(context, listen: false);
    _generateAnalyticsData(app);
  }

  void _generateAnalyticsData(AppState app) {
    final servers = app.servers;

    // Get integrity data for the timeframe
    final bins = _getServerIntegrityBins(app);
    final runCount = _getServerRunCount(app);

    // Get all server counts for peer comparison
    final allServerCounts = <String, int>{};
    for (final s in servers) {
      allServerCounts[s.id] = _getServerRunCountById(app, s.id);
    }

    // Generate enhanced assessment
    final assessment = IntegrityAnalyzer.analyzeServerAdvanced(
      serverId: widget.serverId,
      serverName: widget.serverName,
      clickBins: bins,
      totalRuns: runCount,
      allServers: servers,
      allServerCounts: allServerCounts,
      analysisTime: DateTime.now(),
    );

    // Generate historical data (simulate for now)
    _historicalAssessments = _generateHistoricalAssessments(app);

    _analyticsData = {
      'currentAssessment': assessment,
      'totalRuns': runCount,
      'clickBins': bins,
      'riskTrend': _calculateRiskTrend(),
      'peerRanking': _calculatePeerRanking(allServerCounts),
      'patternAnalysis': _analyzePatterns(bins),
      'recommendations': _generateRecommendations(assessment),
    };

    setState(() {});
  }

  Map<String, int> _getServerIntegrityBins(AppState app) {
    switch (_selectedTimeframe) {
      case 'today':
        return app.integrityBinsForDateRange(widget.serverId, todayOnly: true);
      case 'week':
        final weekAgo = DateTime.now().subtract(const Duration(days: 7));
        return app.integrityBinsForDateRange(widget.serverId,
            startDate: weekAgo);
      case 'month':
        final monthAgo = DateTime.now().subtract(const Duration(days: 30));
        return app.integrityBinsForDateRange(widget.serverId,
            startDate: monthAgo);
      default:
        return app.integrityBinsForDateRange(widget.serverId, todayOnly: true);
    }
  }

  int _getServerRunCount(AppState app) {
    switch (_selectedTimeframe) {
      case 'today':
        return app.currentCounts[widget.serverId] ?? 0;
      case 'week':
      case 'month':
        final bins = _getServerIntegrityBins(app);
        return bins.values.fold(0, (sum, count) => sum + count);
      default:
        return app.currentCounts[widget.serverId] ?? 0;
    }
  }

  int _getServerRunCountById(AppState app, String serverId) {
    switch (_selectedTimeframe) {
      case 'today':
        return app.currentCounts[serverId] ?? 0;
      case 'week':
      case 'month':
        final weekAgo = _selectedTimeframe == 'week'
            ? DateTime.now().subtract(const Duration(days: 7))
            : DateTime.now().subtract(const Duration(days: 30));
        final bins =
            app.integrityBinsForDateRange(serverId, startDate: weekAgo);
        return bins.values.fold(0, (sum, count) => sum + count);
      default:
        return app.currentCounts[serverId] ?? 0;
    }
  }

  List<EnhancedIntegrityAssessment> _generateHistoricalAssessments(
      AppState app) {
    // Generate sample historical data for trend analysis
    final assessments = <EnhancedIntegrityAssessment>[];
    final now = DateTime.now();

    for (int i = 7; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final bins = app.integrityBinsForDateRange(widget.serverId,
          startDate: date, endDate: date.add(const Duration(days: 1)));

      if (bins.isNotEmpty) {
        final assessment = IntegrityAnalyzer.analyzeServerAdvanced(
          serverId: widget.serverId,
          serverName: widget.serverName,
          clickBins: bins,
          totalRuns: bins.values.fold(0, (sum, count) => sum + count),
          allServers: app.servers,
          allServerCounts: {
            widget.serverId: bins.values.fold(0, (sum, count) => sum + count)
          },
          analysisTime: date,
        );
        assessments.add(assessment);
      }
    }

    return assessments;
  }

  Map<String, dynamic> _calculateRiskTrend() {
    if (_historicalAssessments.length < 2) {
      return {'trend': 'stable', 'change': 0.0};
    }

    final recent = _historicalAssessments.last.riskScore;
    final previous =
        _historicalAssessments[_historicalAssessments.length - 2].riskScore;
    final change = recent - previous;

    String trend = 'stable';
    if (change > 10) trend = 'increasing';
    if (change < -10) trend = 'decreasing';

    return {'trend': trend, 'change': change};
  }

  Map<String, dynamic> _calculatePeerRanking(Map<String, int> allServerCounts) {
    final serverRuns = allServerCounts[widget.serverId] ?? 0;
    final sortedRuns = allServerCounts.values.toList()
      ..sort((a, b) => b.compareTo(a));
    final rank = sortedRuns.indexOf(serverRuns) + 1;
    final percentile =
        ((sortedRuns.length - rank) / sortedRuns.length * 100).round();

    return {
      'rank': rank,
      'totalServers': sortedRuns.length,
      'percentile': percentile,
      'runs': serverRuns,
    };
  }

  Map<String, dynamic> _analyzePatterns(Map<String, int> bins) {
    if (bins.isEmpty) return {};

    final values = bins.values.toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
            values.length;
    final stdDev = variance > 0 ? math.sqrt(variance) : 0.0;
    final coefficientOfVariation = mean > 0 ? stdDev / mean : 0.0;

    return {
      'mean': mean,
      'standardDeviation': stdDev,
      'coefficientOfVariation': coefficientOfVariation,
      'consistency': coefficientOfVariation < 0.3
          ? 'High'
          : coefficientOfVariation < 0.6
              ? 'Medium'
              : 'Low',
      'peakHours': _identifyPeakHours(bins),
    };
  }

  List<String> _identifyPeakHours(Map<String, int> bins) {
    final sorted = bins.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).map((e) => e.key).toList();
  }

  List<String> _generateRecommendations(
      EnhancedIntegrityAssessment assessment) {
    final recommendations = <String>[];

    if (assessment.riskScore > 80) {
      recommendations
          .add('Immediate investigation recommended due to high risk score');
    }

    if (assessment.clickClusters.isNotEmpty) {
      recommendations
          .add('Monitor click clustering patterns during peak hours');
    }

    if (assessment.mechanicalScore > 0.7) {
      recommendations
          .add('Review automated processes - high mechanical pattern detected');
    }

    if (assessment.zScore > 2.0) {
      recommendations
          .add('Server performance significantly differs from peers');
    }

    if (assessment.sessionDurationScore > 0.8) {
      recommendations.add('Investigate extended session durations');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Server operating within normal parameters');
    }

    return recommendations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WallpaperBackground(
        child: Column(
          children: [
            _buildAnalyticsHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Risk Assessment Overview
                    _buildRiskAssessmentCard(),

                    const SizedBox(height: 16),

                    // Peer Comparison and Trends
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 600) {
                          return Column(
                            children: [
                              _buildPeerComparisonCard(),
                              const SizedBox(height: 16),
                              _buildTrendAnalysisCard(),
                            ],
                          );
                        } else {
                          return Row(
                            children: [
                              Expanded(child: _buildPeerComparisonCard()),
                              const SizedBox(width: 16),
                              Expanded(child: _buildTrendAnalysisCard()),
                            ],
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // Pattern Analysis and Recommendations
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 600) {
                          return Column(
                            children: [
                              _buildPatternAnalysisCard(),
                              const SizedBox(height: 16),
                              _buildRecommendationsCard(),
                            ],
                          );
                        } else {
                          return Row(
                            children: [
                              Expanded(child: _buildPatternAnalysisCard()),
                              const SizedBox(width: 16),
                              Expanded(child: _buildRecommendationsCard()),
                            ],
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // Detailed Analysis
                    _buildDetailedAnalysisCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.indigo[900]!.withOpacity(0.9),
            Colors.indigo[700]!.withOpacity(0.9),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.serverName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Advanced Server Analytics',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white, size: 26),
                tooltip: 'Refresh Analytics',
                onPressed: _refreshAnalytics,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Analysis Period:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTimeframe,
                    dropdownColor: Colors.indigo[800],
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    items: const [
                      DropdownMenuItem(value: 'today', child: Text('Today')),
                      DropdownMenuItem(value: 'week', child: Text('Week')),
                      DropdownMenuItem(value: 'month', child: Text('Month')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedTimeframe = value;
                        });
                        _refreshAnalytics();
                      }
                    },
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskAssessmentCard() {
    final assessment =
        _analyticsData['currentAssessment'] as EnhancedIntegrityAssessment?;
    if (assessment == null) return const SizedBox();

    Color riskColor = Colors.green;
    String riskLevel = 'Low';

    if (assessment.riskScore > 80) {
      riskColor = Colors.red;
      riskLevel = 'Critical';
    } else if (assessment.riskScore > 60) {
      riskColor = Colors.orange;
      riskLevel = 'High';
    } else if (assessment.riskScore > 40) {
      riskColor = Colors.yellow[700]!;
      riskLevel = 'Medium';
    }

    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.assessment, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Risk Assessment Overview',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: riskColor.withOpacity(0.1),
                          border: Border.all(color: riskColor, width: 3),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${assessment.riskScore.toInt()}',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: riskColor,
                                ),
                              ),
                              Text(
                                riskLevel,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: riskColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRiskMetric(
                          'Overall Risk', assessment.riskScore / 100),
                      const SizedBox(height: 8),
                      _buildRiskMetric(
                          'Mechanical Score', assessment.mechanicalScore),
                      const SizedBox(height: 8),
                      _buildRiskMetric(
                          'Session Score', assessment.sessionDurationScore),
                      const SizedBox(height: 8),
                      _buildRiskMetric('Z-Score Risk',
                          (assessment.zScore.abs() / 3.0).clamp(0.0, 1.0)),
                    ],
                  ),
                ),
              ],
            ),
            if (assessment.riskFactors.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Risk Factors:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...assessment.riskFactors.map((factor) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            factor,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRiskMetric(String label, double value) {
    Color color = Colors.green;
    if (value > 0.8) {
      color = Colors.red;
    } else if (value > 0.6)
      color = Colors.orange;
    else if (value > 0.4) color = Colors.yellow[700]!;

    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '${(value * 100).toInt()}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeerComparisonCard() {
    final peerData =
        _analyticsData['peerRanking'] as Map<String, dynamic>? ?? {};

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.compare_arrows, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Peer Comparison',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (peerData.isNotEmpty) ...[
              _buildStatItem(
                  'Rank', '${peerData['rank']} of ${peerData['totalServers']}'),
              _buildStatItem('Percentile', '${peerData['percentile']}th'),
              _buildStatItem('Total Runs', '${peerData['runs']}'),
            ] else
              const Text('No peer data available'),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendAnalysisCard() {
    final trendData =
        _analyticsData['riskTrend'] as Map<String, dynamic>? ?? {};

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_up, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Risk Trend',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (trendData.isNotEmpty) ...[
              _buildStatItem('Trend', trendData['trend'] ?? 'stable'),
              _buildStatItem('Change',
                  '${trendData['change']?.toStringAsFixed(1) ?? '0.0'}%'),
            ] else
              const Text('Insufficient data for trend analysis'),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternAnalysisCard() {
    final patternData =
        _analyticsData['patternAnalysis'] as Map<String, dynamic>? ?? {};

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pattern, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Pattern Analysis',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (patternData.isNotEmpty) ...[
              _buildStatItem(
                  'Consistency', patternData['consistency'] ?? 'Unknown'),
              _buildStatItem('Avg Clicks/Hour',
                  '${patternData['mean']?.toStringAsFixed(1) ?? '0.0'}'),
              _buildStatItem('Coefficient of Variation',
                  '${(patternData['coefficientOfVariation'] ?? 0.0).toStringAsFixed(2)}'),
            ] else
              const Text('No pattern data available'),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    final recommendations =
        _analyticsData['recommendations'] as List<String>? ?? [];

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Recommendations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recommendations.isNotEmpty)
              ...recommendations.map((rec) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.arrow_right,
                            color: Colors.grey, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rec,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ))
            else
              const Text('No recommendations available'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedAnalysisCard() {
    final assessment =
        _analyticsData['currentAssessment'] as EnhancedIntegrityAssessment?;
    if (assessment == null) return const SizedBox();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  'Detailed Analysis',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatItem('Click Clusters Detected',
                '${assessment.clickClusters.length}'),
            _buildStatItem('Mechanical Score',
                '${(assessment.mechanicalScore * 100).toInt()}%'),
            _buildStatItem('Session Duration Score',
                '${(assessment.sessionDurationScore * 100).toInt()}%'),
            _buildStatItem(
                'Z-Score vs Peers', assessment.zScore.toStringAsFixed(2)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
