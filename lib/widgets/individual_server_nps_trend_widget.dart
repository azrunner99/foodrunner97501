import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nps_provider.dart';
import '../models/monthly_report.dart' hide PerformanceTrend;
import '../models/historical_nps_data.dart';
// import '../services/intelligent_performance_classifier.dart';
import '../services/advanced_trend_analysis_service.dart' as trend_analysis;
import '../storage/database_factory.dart';
import '../storage/nps_database_adapter.dart';
import '../utils/log.dart';
import '../app_state.dart';
import '../services/application_update_service.dart';

/// Individual Server NPS Trend Widget
/// Contains the Advanced Trend Analysis section
class IndividualServerNPSTrendWidget extends StatefulWidget {
  const IndividualServerNPSTrendWidget({super.key});

  @override
  State<IndividualServerNPSTrendWidget> createState() => _IndividualServerNPSTrendWidgetState();
}

class _IndividualServerNPSTrendWidgetState extends State<IndividualServerNPSTrendWidget> {
  List<NPSMonthlyReport> _monthlyReports = [];
  bool _isLoading = true;
  Map<String, trend_analysis.AdvancedTrendAnalysis> _serverTrendAnalyses = {};
  trend_analysis.TrendDirection? _selectedTrendFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      d('[IndividualServerNPSTrendWidget] Loading monthly reports...');
      
      // Use the same data loading approach as the working HistoricalNPSAggregationService
      final database = DatabaseFactory.instance;
      
      // Load all monthly reports
      final allReports = await database.queryTable('nps_monthly_reports');
      d('[IndividualServerNPSTrendWidget] Found ${allReports.length} total monthly reports');
      
      if (allReports.isEmpty) {
        d('[IndividualServerNPSTrendWidget] No monthly reports found - returning empty list');
        setState(() {
          _monthlyReports = [];
          _serverTrendAnalyses = {};
          _isLoading = false;
        });
        return;
      }
      
      // Filter out integer server IDs (EXACT same logic as HistoricalNPSAggregationService)
      final filteredReports = allReports.where((report) {
        final serverId = report['server_id'].toString();
        final isNumericId = RegExp(r'^\d+$').hasMatch(serverId);
        if (isNumericId) {
          d('[IndividualServerNPSTrendWidget] Filtering out numeric server_id: $serverId');
        }
        return !isNumericId;
      }).toList();
      
      d('[IndividualServerNPSTrendWidget] After filtering: ${filteredReports.length} reports (removed ${allReports.length - filteredReports.length} old format reports)');
      
      // Convert to NPSMonthlyReport objects
      final reports = filteredReports.map((row) => NPSMonthlyReport.fromMap(row)).toList();
      d('[IndividualServerNPSTrendWidget] Loaded ${reports.length} monthly reports');
      
      // Load trend analyses with proper server name resolution
      final trendAnalyses = <String, trend_analysis.AdvancedTrendAnalysis>{};
      
      // Group reports by server ID
      final Map<String, List<NPSMonthlyReport>> reportsByServer = {};
      for (final report in reports) {
        final serverId = report.serverId.toString();
        reportsByServer.putIfAbsent(serverId, () => []).add(report);
      }
      
      // Analyze trends for each server with proper name resolution
      for (final entry in reportsByServer.entries) {
        final serverId = entry.key;
        final serverReports = entry.value;
        
        // Get server name directly from AppState (same approach as working IMPACT tab)
        final servers = context.read<AppState>().servers;
        String serverName = 'Server $serverId';
        for (final server in servers) {
          if (server.id == serverId) {
            serverName = server.name;
            break;
          }
        }
        d('[IndividualServerNPSTrendWidget] Got server name: $serverName for ID: $serverId');
        
        // Analyze trends
        final trendAnalysis = trend_analysis.AdvancedTrendAnalysisService().analyzeServerTrends(
          monthlyReports: serverReports,
          serverName: serverName,
          serverId: serverId,
        );
        
        trendAnalyses[serverId] = trendAnalysis;
      }
      
      setState(() {
        _monthlyReports = reports;
        _serverTrendAnalyses = trendAnalyses;
        _isLoading = false;
      });
      
      d('[IndividualServerNPSTrendWidget] Loaded ${trendAnalyses.length} trend analyses');
    } catch (e) {
      d('[IndividualServerNPSTrendWidget] Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Advanced Trend Analysis
            _buildAdvancedTrendAnalysis(),
          ],
        ),
      ),
    );
  }

  /// Build Advanced Trend Analysis section
  Widget _buildAdvancedTrendAnalysis() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.indigo.shade600),
                const SizedBox(width: 8),
                Text(
                  'Advanced Trend Analysis',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade800,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'See which servers are trending up or down, spot performance patterns, and make informed decisions about training and scheduling.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            if (_serverTrendAnalyses.isEmpty)
              _buildNoTrendAnalysisMessage()
            else
              Column(
                children: [
                  _buildTrendAnalysisSummary(),
                  const SizedBox(height: 16),
                  _buildDetailedTrendAnalyses(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Build message when no trend analyses are available
  Widget _buildNoTrendAnalysisMessage() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.trending_up, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Trend Analysis Available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Enter monthly NPS data to enable advanced trend analysis',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build trend analysis summary
  Widget _buildTrendAnalysisSummary() {
    final trendCounts = <trend_analysis.TrendDirection, int>{};
    
    for (final analysis in _serverTrendAnalyses.values) {
      trendCounts[analysis.trendDirection] = (trendCounts[analysis.trendDirection] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trend Distribution',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTrendSummaryItem(
                  trend_analysis.TrendDirection.stronglyImproving,
                  trendCounts[trend_analysis.TrendDirection.stronglyImproving] ?? 0,
                  _serverTrendAnalyses.length,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTrendSummaryItem(
                  trend_analysis.TrendDirection.improving,
                  trendCounts[trend_analysis.TrendDirection.improving] ?? 0,
                  _serverTrendAnalyses.length,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTrendSummaryItem(
                  trend_analysis.TrendDirection.stable,
                  trendCounts[trend_analysis.TrendDirection.stable] ?? 0,
                  _serverTrendAnalyses.length,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTrendSummaryItem(
                  trend_analysis.TrendDirection.declining,
                  trendCounts[trend_analysis.TrendDirection.declining] ?? 0,
                  _serverTrendAnalyses.length,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTrendSummaryItem(
                  trend_analysis.TrendDirection.stronglyDeclining,
                  trendCounts[trend_analysis.TrendDirection.stronglyDeclining] ?? 0,
                  _serverTrendAnalyses.length,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTrendSummaryItem(
                  trend_analysis.TrendDirection.unknown,
                  trendCounts[trend_analysis.TrendDirection.unknown] ?? 0,
                  _serverTrendAnalyses.length,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build trend summary item
  Widget _buildTrendSummaryItem(trend_analysis.TrendDirection trend, int count, int total) {
    final percentage = total > 0 ? (count / total * 100).round() : 0;
    final isSelected = _selectedTrendFilter == trend;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedTrendFilter == trend) {
            _selectedTrendFilter = null; // Clear filter if same trend is clicked
          } else {
            _selectedTrendFilter = trend; // Set filter to selected trend
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _getAdvancedTrendColor(trend).withOpacity(isSelected ? 0.3 : 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getAdvancedTrendColor(trend).withOpacity(isSelected ? 0.8 : 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  trend.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 4),
                Text(
                  trend.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getAdvancedTrendColor(trend),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$count ($percentage%)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getAdvancedTrendColor(trend),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build detailed trend analyses
  Widget _buildDetailedTrendAnalyses() {
    // Filter servers based on selected trend
    final filteredEntries = _selectedTrendFilter == null
        ? _serverTrendAnalyses.entries.toList()
        : _serverTrendAnalyses.entries
            .where((entry) => entry.value.trendDirection == _selectedTrendFilter)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Detailed Trend Analysis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (_selectedTrendFilter != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getAdvancedTrendColor(_selectedTrendFilter!).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getAdvancedTrendColor(_selectedTrendFilter!)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedTrendFilter!.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Filtered by ${_selectedTrendFilter!.displayName}',
                      style: TextStyle(
                        color: _getAdvancedTrendColor(_selectedTrendFilter!),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTrendFilter = null;
                        });
                      },
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: _getAdvancedTrendColor(_selectedTrendFilter!),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (filteredEntries.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.filter_list_off,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No servers found for this trend',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try selecting a different trend category',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 400, // Fixed height to make it scrollable
            child: ListView.builder(
              itemCount: filteredEntries.length,
              itemBuilder: (context, index) {
                final entry = filteredEntries[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTrendAnalysisCard(entry.key, entry.value),
                );
              },
            ),
          ),
      ],
    );
  }

  /// Build individual trend analysis card (collapsible)
  Widget _buildTrendAnalysisCard(String serverId, trend_analysis.AdvancedTrendAnalysis analysis) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _getAdvancedTrendColor(analysis.trendDirection).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getAdvancedTrendColor(analysis.trendDirection).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Text(
              analysis.trendDirection.emoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                analysis.serverName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getAdvancedTrendColor(analysis.trendDirection).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getAdvancedTrendColor(analysis.trendDirection)),
              ),
              child: Text(
                analysis.trendDirection.displayName,
                style: TextStyle(
                  color: _getAdvancedTrendColor(analysis.trendDirection),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Most important metrics in collapsed view
                Row(
                  children: [
                    Expanded(
                      child: _buildTrendMetric(
                        'Strength',
                        analysis.trendStrength < 0 ? 'Insufficient Data' : '${analysis.trendStrength.toStringAsFixed(1)}%',
                        analysis.trendStrength < 0 ? Colors.grey : _getTrendStrengthColor(analysis.trendStrength),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTrendMetric(
                        'Velocity',
                        '${analysis.trendVelocity.toStringAsFixed(1)}/mo',
                        _getVelocityColor(analysis.trendVelocity),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTrendMetric(
                        'Confidence',
                        '${analysis.trendConfidence.toStringAsFixed(1)}%',
                        _getConfidenceColor(analysis.trendConfidence),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTrendMetric(
                        'Momentum',
                        analysis.momentum.displayName,
                        _getMomentumColor(analysis.momentum),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTrendMetric(
                        'Persistence',
                        '${analysis.trendPersistence}mo',
                        _getPersistenceColor(analysis.trendPersistence),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTrendMetric(
                        'Volatility',
                        analysis.volatility <= 0 ? 'Insufficient Data' : '${analysis.volatility.toStringAsFixed(1)}',
                        analysis.volatility <= 0 ? Colors.grey : _getAdvancedVolatilityColor(analysis.volatility),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Key Insights:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                ...analysis.trendInsights.take(2).map((insight) =>
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 2),
                    child: Text(
                      '• $insight',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                if (analysis.trendRecommendations.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Recommendations:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...analysis.trendRecommendations.take(2).map((rec) =>
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 2),
                      child: Text(
                        '• $rec',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build trend metric
  Widget _buildTrendMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for colors
  Color _getAdvancedTrendColor(trend_analysis.TrendDirection trend) {
    switch (trend) {
      case trend_analysis.TrendDirection.stronglyImproving:
        return Colors.green;
      case trend_analysis.TrendDirection.improving:
        return Colors.lightGreen;
      case trend_analysis.TrendDirection.stable:
        return Colors.blue;
      case trend_analysis.TrendDirection.declining:
        return Colors.orange;
      case trend_analysis.TrendDirection.stronglyDeclining:
        return Colors.red;
      case trend_analysis.TrendDirection.unknown:
        return Colors.grey;
    }
  }

  Color _getTrendStrengthColor(double strength) {
    if (strength >= 0.8) return Colors.green;
    if (strength >= 0.6) return Colors.lightGreen;
    if (strength >= 0.4) return Colors.orange;
    return Colors.red;
  }

  Color _getVelocityColor(double velocity) {
    if (velocity > 0) return Colors.green;
    if (velocity < 0) return Colors.red;
    return Colors.grey;
  }

  Color _getMomentumColor(trend_analysis.MomentumType momentum) {
    switch (momentum) {
      case trend_analysis.MomentumType.strongPositive:
        return Colors.green;
      case trend_analysis.MomentumType.positive:
        return Colors.lightGreen;
      case trend_analysis.MomentumType.weakPositive:
        return Colors.blue;
      case trend_analysis.MomentumType.neutral:
        return Colors.grey;
      case trend_analysis.MomentumType.weakNegative:
        return Colors.orange;
      case trend_analysis.MomentumType.negative:
        return Colors.deepOrange;
      case trend_analysis.MomentumType.strongNegative:
        return Colors.red;
    }
  }

  Color _getPersistenceColor(int persistence) {
    if (persistence >= 3) return Colors.green;
    if (persistence >= 2) return Colors.orange;
    return Colors.red;
  }

  Color _getAdvancedVolatilityColor(double volatility) {
    if (volatility <= 5) return Colors.green;
    if (volatility <= 10) return Colors.orange;
    return Colors.red;
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) return Colors.green;
    if (confidence >= 60) return Colors.orange;
    return Colors.red;
  }
}
