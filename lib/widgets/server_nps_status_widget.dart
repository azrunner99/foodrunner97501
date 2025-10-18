import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nps_provider.dart';
import '../models/monthly_report.dart' hide PerformanceTrend;
import '../models/historical_nps_data.dart';
import '../services/intelligent_performance_classifier.dart';
import '../utils/log.dart';
import '../models/performance_models.dart' as performance_models;
import '../core/types.dart';
import '../app_state.dart';
import '../services/application_update_service.dart';
import '../mixins/server_data_mixin.dart';

/// Server NPS Status Widget
/// Displays Intelligent Performance Classification and server status
/// 
/// ✅ Refactored to use ServerDataMixin for standardized data access
class ServerNPSStatusWidget extends StatefulWidget {
  const ServerNPSStatusWidget({super.key});

  @override
  State<ServerNPSStatusWidget> createState() => _ServerNPSStatusWidgetState();
}

class _ServerNPSStatusWidgetState extends State<ServerNPSStatusWidget> with ServerDataMixin {
  List<HistoricalNPSData> _historicalData = [];
  Map<String, performance_models.PerformanceClassification> _serverClassifications = {};
  bool _isLoading = true;
  performance_models.IntelligentPerformanceTier? _selectedTierFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      d('[ServerNPSStatusWidget] Starting to load data...');
      
      // ✅ Use mixin method - automatic filtering, ID resolution, and typing
      final allReports = await getAllNPSMonthlyReports();
      d('[ServerNPSStatusWidget] Found ${allReports.length} reports (orphaned IDs already filtered)');
      
      if (allReports.isEmpty) {
        d('[ServerNPSStatusWidget] No monthly reports found - returning empty list');
        setState(() {
          _historicalData = [];
          _serverClassifications = {};
          _isLoading = false;
        });
        return;
      }
      
      // Load historical data with proper server name resolution
      final historicalData = <HistoricalNPSData>[];
      final Map<String, List<NPSMonthlyReport>> reportsByServer = {};
      
      // Get active servers list to filter out archived servers
      final activeServers = context.read<AppState>().activeServers;
      final activeServerIds = activeServers.map((s) => s.id).toSet();
      
      // Group reports by server ID
      for (final report in allReports) {
        reportsByServer.putIfAbsent(report.serverId, () => []).add(report);
      }
      
      // Create HistoricalNPSData for each server with proper name resolution
      for (final entry in reportsByServer.entries) {
        final serverId = entry.key;
        final npsReports = entry.value;
        
        // Skip archived servers
        if (!activeServerIds.contains(serverId)) {
          d('[ServerNPSStatusWidget] Skipping archived server: $serverId');
          continue;
        }
        
        // ✅ Use mixin method for server name lookup
        final serverName = await getServerName(serverId);
        d('[ServerNPSStatusWidget] Got server name: $serverName for ID: $serverId');
        
        historicalData.add(HistoricalNPSData(
          serverId: serverId,
          serverName: serverName,
          monthlyData: npsReports.map((report) => MonthlyPerformance(
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
          totalMonthsReported: npsReports.length,
        ));
      }
      
      // Load intelligent performance classifications
      final classifications = <String, performance_models.PerformanceClassification>{};
      final classifier = IntelligentPerformanceClassifier();
      
      for (final data in historicalData) {
        // ✅ Use mixin method instead of direct DB access
        final monthlyReports = await getServerNPSHistory(data.serverId);
        final classification = classifier.classifyServerPerformance(
          monthlyReports: monthlyReports,
          serverName: data.serverName,
          serverId: data.serverId,
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
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Get a quick overview of your team\'s performance health, identify top performers, and spot who might need extra coaching or support.',
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
    final isSelected = _selectedTierFilter == tier;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedTierFilter == tier) {
            _selectedTierFilter = null; // Clear filter if same tier is clicked
          } else {
            _selectedTierFilter = tier; // Set filter to selected tier
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
            ? _getTierColor(tier).withOpacity(0.2)
            : _getTierColor(tier).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
              ? _getTierColor(tier)
              : _getTierColor(tier).withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
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
      ),
    );
  }

  /// Build detailed classifications
  Widget _buildDetailedClassifications() {
    // Filter classifications based on selected tier
    final filteredClassifications = _selectedTierFilter != null
        ? _serverClassifications.entries
            .where((entry) => entry.value.tier == _selectedTierFilter)
            .toList()
        : _serverClassifications.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Detailed Classifications',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (_selectedTierFilter != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTierColor(_selectedTierFilter!).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getTierColor(_selectedTierFilter!)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedTierFilter!.emoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Filtered by ${_selectedTierFilter!.displayName}',
                      style: TextStyle(
                        color: _getTierColor(_selectedTierFilter!),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTierFilter = null;
                        });
                      },
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: _getTierColor(_selectedTierFilter!),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (filteredClassifications.isEmpty && _selectedTierFilter != null)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.filter_list_off,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No servers found in ${_selectedTierFilter!.displayName} tier',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try selecting a different performance tier',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 400, // Fixed height to enable scrolling
            child: ListView.builder(
              itemCount: filteredClassifications.length,
              itemBuilder: (context, index) {
                final entry = filteredClassifications[index];
                return _buildClassificationCard(entry.key, entry.value);
              },
            ),
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
                        '${(classification.confidence * 100).toStringAsFixed(1)}%',
                        _getConfidenceColor(classification.confidence * 100),
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
                if (classification.improvements.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Recommendations:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...classification.improvements.map((rec) => 
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
