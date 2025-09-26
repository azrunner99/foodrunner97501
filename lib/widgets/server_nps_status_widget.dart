import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nps_provider.dart';
import '../models/monthly_report.dart' hide PerformanceTrend;
import '../models/historical_nps_data.dart';
import '../services/intelligent_performance_classifier.dart';
import '../storage/database_factory.dart';
import '../utils/log.dart';
import '../models/performance_models.dart' as performance_models;

/// Server NPS Status Widget
/// Displays Intelligent Performance Classification and server status
class ServerNPSStatusWidget extends StatefulWidget {
  const ServerNPSStatusWidget({super.key});

  @override
  State<ServerNPSStatusWidget> createState() => _ServerNPSStatusWidgetState();
}

class _ServerNPSStatusWidgetState extends State<ServerNPSStatusWidget> {
  List<HistoricalNPSData> _historicalData = [];
  Map<String, performance_models.PerformanceClassification> _serverClassifications = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      d('[ServerNPSStatusWidget] Starting to load data...');
      
      // Load monthly reports
      final db = DatabaseFactory.instance;
      final dbType = DatabaseFactory.implementationType;
      
      List<Map<String, dynamic>> reportMaps;
      
      if (dbType.contains('Sqflite')) {
        reportMaps = await db.queryTable(
          'nps_monthly_reports',
          orderBy: 'month_year DESC',
        );
      } else {
        reportMaps = await db.queryTable(
          'nps_monthly_reports',
          orderBy: 'report_year DESC, report_month DESC',
        );
      }
      
      final reports = reportMaps.map((map) => NPSMonthlyReport.fromMap(map)).toList();
      
      // Load historical data
      final historicalData = <HistoricalNPSData>[];
      final Map<int, List<NPSMonthlyReport>> reportsByServer = {};
      
      for (final report in reports) {
        reportsByServer.putIfAbsent(report.serverId, () => []).add(report);
      }
      
      for (final entry in reportsByServer.entries) {
        final serverId = entry.key;
        final serverReports = entry.value;
        
        // Get server name
        final npsProvider = context.read<NPSProvider>();
        final servers = npsProvider.servers;
        String serverName = 'Server $serverId';
        final server = servers.cast<dynamic>().firstWhere(
          (server) => server.id == serverId,
          orElse: () => null,
        );
        
        if (server != null) {
          final serverStr = server.toString();
          final nameMatch = RegExp(r'name:\s*([^,]+)').firstMatch(serverStr);
          if (nameMatch != null) {
            serverName = nameMatch.group(1)?.trim() ?? 'Server $serverId';
          }
        }
        
        historicalData.add(HistoricalNPSData(
          serverId: serverId.toString(),
          serverName: serverName,
          monthlyData: serverReports.map((report) => MonthlyPerformance(
            month: DateTime(report.reportYear, report.reportMonth),
            oneMonthNPS: report.oneMonthNpsPercentage ?? 0.0,
            threeMonthNPS: report.threeMonthNpsPercentage ?? 0.0,
            allTimeNPS: report.allTimeNpsPercentage ?? 0.0,
            responseCount: 0, // Default value
            context: PerformanceContext(
              isNewHire: false,
              isTrainingPeriod: false,
              isSeasonalPeak: false,
              isSeasonalLow: false,
              notes: '',
            ),
            tableCount: report.allTimeTableCount,
            sales: report.allTimeSales,
          )).toList(),
          trend: PerformanceTrend(
            direction: TrendDirection.stable,
            slope: 0.0,
            strength: 0.0,
            volatility: 0.0,
            movingAverages: [],
            description: 'Stable performance',
          ),
          volatility: 0.0,
          classification: PerformanceClassification.unknown,
          lastUpdated: DateTime.now(),
          totalMonthsReported: serverReports.length,
        ));
      }
      
      // Load intelligent performance classifications
      final classifications = <String, performance_models.PerformanceClassification>{};
      final classifier = IntelligentPerformanceClassifier();
      
      for (final data in historicalData) {
        final monthlyReports = await _getMonthlyReportsForServer(data.serverId);
        final classification = classifier.classifyServerPerformance(
          monthlyReports: monthlyReports,
          serverName: data.serverName,
          serverId: int.parse(data.serverId),
        );
        classifications[data.serverId] = classification;
      }
      
      d('[ServerNPSStatusWidget] Loaded ${historicalData.length} servers with classifications');
      
      setState(() {
        _historicalData = historicalData;
        _serverClassifications = classifications;
        _isLoading = false;
      });
    } catch (e) {
      d('[ServerNPSStatusWidget] Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<NPSMonthlyReport>> _getMonthlyReportsForServer(String serverId) async {
    try {
      final database = DatabaseFactory.instance;
      final isSqflite = database.runtimeType.toString().contains('Sqflite');

      final results = await database.queryTable(
        'nps_monthly_reports',
        where: 'server_id = ?',
        whereArgs: [int.parse(serverId)],
        orderBy: isSqflite ? 'month_year DESC' : 'report_year DESC, report_month DESC',
      );

      return results.map((row) => NPSMonthlyReport.fromMap(row)).toList();
    } catch (e) {
      d('[ServerNPSStatusWidget] Error loading monthly reports for server $serverId: $e');
      return [];
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
            // Intelligent Performance Classification
            _buildIntelligentClassifications(),
          ],
        ),
      ),
    );
  }

  /// Build intelligent performance classifications section
  Widget _buildIntelligentClassifications() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.purple.shade600),
                const SizedBox(width: 8),
                Text(
                  'Intelligent Performance Classification',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade800,
                    fontSize: 24,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.purple.shade300),
                  ),
                  child: Text(
                    'Phase 2',
                    style: TextStyle(
                      color: Colors.purple.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'AI-powered performance analysis using multi-dimensional scoring and contextual intelligence.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            if (_serverClassifications.isEmpty)
              _buildNoClassificationsMessage()
            else
              Column(
                children: [
                  _buildClassificationSummary(),
                  const SizedBox(height: 16),
                  _buildDetailedClassifications(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Build message when no classifications are available
  Widget _buildNoClassificationsMessage() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.psychology, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Performance Classifications Available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Enter monthly NPS data to enable intelligent performance analysis',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build classification summary
  Widget _buildClassificationSummary() {
    final tierCounts = <performance_models.IntelligentPerformanceTier, int>{};
    for (final classification in _serverClassifications.values) {
      tierCounts[classification.tier] = (tierCounts[classification.tier] ?? 0) + 1;
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
            'Performance Distribution',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTierSummaryItem(
                  performance_models.IntelligentPerformanceTier.elite,
                  tierCounts[performance_models.IntelligentPerformanceTier.elite] ?? 0,
                  _serverClassifications.length,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTierSummaryItem(
                  performance_models.IntelligentPerformanceTier.strong,
                  tierCounts[performance_models.IntelligentPerformanceTier.strong] ?? 0,
                  _serverClassifications.length,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTierSummaryItem(
                  performance_models.IntelligentPerformanceTier.developing,
                  tierCounts[performance_models.IntelligentPerformanceTier.developing] ?? 0,
                  _serverClassifications.length,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTierSummaryItem(
                  performance_models.IntelligentPerformanceTier.concerning,
                  tierCounts[performance_models.IntelligentPerformanceTier.concerning] ?? 0,
                  _serverClassifications.length,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTierSummaryItem(
                  performance_models.IntelligentPerformanceTier.critical,
                  tierCounts[performance_models.IntelligentPerformanceTier.critical] ?? 0,
                  _serverClassifications.length,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTierSummaryItem(
                  performance_models.IntelligentPerformanceTier.unknown,
                  tierCounts[performance_models.IntelligentPerformanceTier.unknown] ?? 0,
                  _serverClassifications.length,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build tier summary item
  Widget _buildTierSummaryItem(performance_models.IntelligentPerformanceTier tier, int count, int total) {
    final percentage = total > 0 ? (count / total * 100).round() : 0;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getTierColor(tier).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getTierColor(tier).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                tier.emoji,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 4),
              Text(
                tier.displayName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getTierColor(tier),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$count ($percentage%)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _getTierColor(tier),
            ),
          ),
        ],
      ),
    );
  }

  /// Build detailed classifications
  Widget _buildDetailedClassifications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Classifications',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        ..._serverClassifications.entries.map((entry) => 
          _buildClassificationCard(entry.key, entry.value)
        ),
      ],
    );
  }

  /// Build individual classification card (collapsible)
  Widget _buildClassificationCard(String serverId, performance_models.PerformanceClassification classification) {
    final serverData = _historicalData.firstWhere(
      (data) => data.serverId == serverId,
      orElse: () => _historicalData.first,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _getTierColor(classification.tier).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getTierColor(classification.tier).withOpacity(0.2)),
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
              classification.tier.emoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                serverData.serverName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getTierColor(classification.tier).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getTierColor(classification.tier)),
              ),
              child: Text(
                classification.tier.displayName,
                style: TextStyle(
                  color: _getTierColor(classification.tier),
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
                // Score and Confidence Metrics
                Row(
                  children: [
                    Expanded(
                      child: _buildClassificationMetric(
                        'Score',
                        '${classification.score.toStringAsFixed(1)}%',
                        _getClassificationScoreColor(classification.score),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildClassificationMetric(
                        'Confidence',
                        '${classification.confidence.toStringAsFixed(1)}%',
                        _getConfidenceColor(classification.confidence),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Reasoning Section
                Text(
                  'Reasoning:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  classification.reasoning,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
                
                // Recommendations Section
                if (classification.recommendations.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Recommendations:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...classification.recommendations.map((rec) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 6, right: 8),
                            decoration: BoxDecoration(
                              color: _getTierColor(classification.tier),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              rec,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
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

  /// Build classification metric
  Widget _buildClassificationMetric(String label, String value, Color color) {
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
              fontSize: 18,
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
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Get tier color
  Color _getTierColor(performance_models.IntelligentPerformanceTier tier) {
    switch (tier) {
      case performance_models.IntelligentPerformanceTier.elite:
        return Colors.purple;
      case performance_models.IntelligentPerformanceTier.strong:
        return Colors.green;
      case performance_models.IntelligentPerformanceTier.developing:
        return Colors.blue;
      case performance_models.IntelligentPerformanceTier.concerning:
        return Colors.orange;
      case performance_models.IntelligentPerformanceTier.critical:
        return Colors.red;
      case performance_models.IntelligentPerformanceTier.unknown:
        return Colors.grey;
    }
  }

  /// Get classification score color
  Color _getClassificationScoreColor(double score) {
    if (score >= 90) return Colors.purple;
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  /// Get confidence color
  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) return Colors.green;
    if (confidence >= 60) return Colors.blue;
    if (confidence >= 40) return Colors.orange;
    return Colors.red;
  }
}
