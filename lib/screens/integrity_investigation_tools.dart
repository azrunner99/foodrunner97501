import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../app_state.dart';
import '../models.dart';
import '../widgets/wallpaper_background.dart';
import '../utils/integrity_analyzer.dart';

/// Advanced investigation tools for detailed server analysis
class IntegrityInvestigationTools extends StatefulWidget {
  final String? initialServerId;
  
  const IntegrityInvestigationTools({
    super.key,
    this.initialServerId,
  });

  @override
  State<IntegrityInvestigationTools> createState() => _IntegrityInvestigationToolsState();
}

class _IntegrityInvestigationToolsState extends State<IntegrityInvestigationTools> {
  String? _selectedServerId;
  String _selectedTimeframe = 'week';
  Map<String, dynamic> _investigationData = {};
  List<InvestigationCase> _activeCases = [];

  @override
  void initState() {
    super.initState();
    _selectedServerId = widget.initialServerId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInvestigationData();
      _loadActiveCases();
    });
  }

  void _loadInvestigationData() {
    if (_selectedServerId == null) return;
    
    final app = Provider.of<AppState>(context, listen: false);
    final server = app.servers.firstWhere((s) => s.id == _selectedServerId);
    
    // Get comprehensive analysis data
    final bins = _getServerIntegrityBins(app, _selectedServerId!);
    final runCount = _getServerRunCount(app, _selectedServerId!);
    
    final allServerCounts = <String, int>{};
    for (final s in app.servers) {
      allServerCounts[s.id] = _getServerRunCount(app, s.id);
    }
    
    final enhancedAssessment = IntegrityAnalyzer.analyzeServerAdvanced(
      serverId: _selectedServerId!,
      serverName: server.name,
      clickBins: bins,
      totalRuns: runCount,
      allServers: app.servers,
      allServerCounts: allServerCounts,
      analysisTime: DateTime.now(),
    );
    
    _investigationData = {
      'server': server,
      'assessment': enhancedAssessment,
      'bins': bins,
      'runCount': runCount,
      'timeline': _generateTimeline(app, _selectedServerId!),
      'patterns': _analyzePatterns(bins),
      'peerComparison': _generatePeerComparison(app, _selectedServerId!, allServerCounts),
    };
    
    setState(() {});
  }

  void _loadActiveCases() {
    // Simulate active investigation cases
    _activeCases = [
      InvestigationCase(
        id: 'INV-001',
        serverId: '4f55jaewuhldbaoi',
        serverName: 'Server #4f55',
        issueType: 'Click Pattern Anomaly',
        severity: CaseSeverity.high,
        status: CaseStatus.active,
        createdDate: DateTime.now().subtract(const Duration(days: 2)),
        description: 'Unusual click clustering detected during evening shifts',
        assignedTo: 'Manager A',
      ),
      InvestigationCase(
        id: 'INV-002',
        serverId: '7a2b8c3d',
        serverName: 'Server #7a2b',
        issueType: 'Volume Spike',
        severity: CaseSeverity.medium,
        status: CaseStatus.review,
        createdDate: DateTime.now().subtract(const Duration(days: 5)),
        description: 'Sudden increase in run count without corresponding shift changes',
        assignedTo: 'Manager B',
      ),
      InvestigationCase(
        id: 'INV-003',
        serverId: '9c4d5e6f',
        serverName: 'Server #9c4d',
        issueType: 'Session Duration',
        severity: CaseSeverity.low,
        status: CaseStatus.pending,
        createdDate: DateTime.now().subtract(const Duration(hours: 6)),
        description: 'Extended session duration beyond normal parameters',
        assignedTo: 'Manager C',
      ),
    ];
  }

  Map<String, int> _getServerIntegrityBins(AppState app, String serverId) {
    switch (_selectedTimeframe) {
      case 'today':
        return app.integrityBinsForDateRange(serverId, todayOnly: true);
      case 'week':
        final weekAgo = DateTime.now().subtract(const Duration(days: 7));
        return app.integrityBinsForDateRange(serverId, startDate: weekAgo);
      case 'month':
        final monthAgo = DateTime.now().subtract(const Duration(days: 30));
        return app.integrityBinsForDateRange(serverId, startDate: monthAgo);
      default:
        return app.integrityBinsForDateRange(serverId, todayOnly: true);
    }
  }

  int _getServerRunCount(AppState app, String serverId) {
    switch (_selectedTimeframe) {
      case 'today':
        return app.currentCounts[serverId] ?? 0;
      case 'week':
      case 'month':
        final bins = _getServerIntegrityBins(app, serverId);
        return bins.values.fold(0, (sum, count) => sum + count);
      default:
        return app.currentCounts[serverId] ?? 0;
    }
  }

  List<TimelineEvent> _generateTimeline(AppState app, String serverId) {
    // Generate timeline events from tap data
    final events = <TimelineEvent>[];
    
    // Add some sample events - in real implementation, this would come from actual data
    events.add(TimelineEvent(
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      type: EventType.alert,
      description: 'High click rate detected',
      severity: CaseSeverity.medium,
    ));
    
    events.add(TimelineEvent(
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      type: EventType.pattern,
      description: 'Click clustering pattern identified',
      severity: CaseSeverity.high,
    ));
    
    events.add(TimelineEvent(
      timestamp: DateTime.now().subtract(const Duration(hours: 6)),
      type: EventType.session,
      description: 'Extended session started',
      severity: CaseSeverity.low,
    ));
    
    return events..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Map<String, dynamic> _analyzePatterns(Map<String, int> bins) {
    final values = bins.values.toList();
    if (values.isEmpty) return {};
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / values.length;
    final standardDeviation = variance.sqrt();
    final coefficientOfVariation = standardDeviation / mean;
    
    return {
      'mean': mean,
      'variance': variance,
      'standardDeviation': standardDeviation,
      'coefficientOfVariation': coefficientOfVariation,
      'minValue': values.reduce((a, b) => a < b ? a : b),
      'maxValue': values.reduce((a, b) => a > b ? a : b),
      'range': values.reduce((a, b) => a > b ? a : b) - values.reduce((a, b) => a < b ? a : b),
    };
  }

  Map<String, dynamic> _generatePeerComparison(AppState app, String serverId, Map<String, int> allServerCounts) {
    final serverCount = allServerCounts[serverId] ?? 0;
    final otherCounts = allServerCounts.values.where((count) => count != serverCount).toList();
    
    if (otherCounts.isEmpty) return {};
    
    final mean = otherCounts.reduce((a, b) => a + b) / otherCounts.length;
    final variance = otherCounts.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / otherCounts.length;
    final standardDeviation = variance.sqrt();
    final zScore = standardDeviation > 0 ? (serverCount - mean) / standardDeviation : 0.0;
    
    // Calculate percentile
    final sortedCounts = [...otherCounts, serverCount]..sort();
    final rank = sortedCounts.indexOf(serverCount) + 1;
    final percentile = (rank / sortedCounts.length) * 100;
    
    return {
      'serverCount': serverCount,
      'peerMean': mean,
      'peerStandardDeviation': standardDeviation,
      'zScore': zScore,
      'percentile': percentile,
      'rank': rank,
      'totalServers': sortedCounts.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, child) {
        return Scaffold(
          body: WallpaperBackground(
            child: Column(
              children: [
                // Investigation Header
                _buildInvestigationHeader(app),
                
                // Main Investigation Content
                Expanded(
                  child: Row(
                    children: [
                      // Left Panel - Investigation Cases
                      Container(
                        width: 300,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          border: Border(
                            right: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: _buildCasesPanel(),
                      ),
                      
                      // Right Panel - Detailed Analysis
                      Expanded(
                        child: _selectedServerId != null 
                          ? _buildAnalysisPanel()
                          : _buildNoCaseSelectedPanel(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInvestigationHeader(AppState app) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
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
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Investigation Tools',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Advanced Forensic Analysis & Case Management',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          // Server Selector
          if (app.servers.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedServerId,
                  hint: const Text('Select Server', style: TextStyle(color: Colors.white)),
                  dropdownColor: Colors.indigo[800],
                  style: const TextStyle(color: Colors.white),
                  items: app.servers.map((server) => 
                    DropdownMenuItem(
                      value: server.id,
                      child: Text('${server.name} (${server.id.substring(0, 4)}...)'),
                    ),
                  ).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedServerId = value;
                    });
                    _loadInvestigationData();
                  },
                ),
              ),
            ),
          const SizedBox(width: 16),
          // Timeframe Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTimeframe,
                dropdownColor: Colors.indigo[800],
                style: const TextStyle(color: Colors.white),
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
                    _loadInvestigationData();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _loadInvestigationData();
              _loadActiveCases();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCasesPanel() {
    return Column(
      children: [
        // Cases Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.indigo[50],
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.folder_open, color: Colors.indigo),
              const SizedBox(width: 8),
              const Text(
                'Active Cases',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _activeCases.length.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Cases List
        Expanded(
          child: ListView.builder(
            itemCount: _activeCases.length,
            itemBuilder: (context, index) {
              final caseItem = _activeCases[index];
              return _buildCaseItem(caseItem);
            },
          ),
        ),
        
        // Add Case Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showNewCaseDialog(),
            icon: const Icon(Icons.add),
            label: const Text('New Investigation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCaseItem(InvestigationCase caseItem) {
    final isSelected = _selectedServerId == caseItem.serverId;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.indigo[100] : Colors.white,
        border: Border.all(
          color: isSelected ? Colors.indigo : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: () {
          setState(() {
            _selectedServerId = caseItem.serverId;
          });
          _loadInvestigationData();
        },
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getSeverityColor(caseItem.severity).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getSeverityIcon(caseItem.severity),
            color: _getSeverityColor(caseItem.severity),
          ),
        ),
        title: Text(
          caseItem.serverName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              caseItem.issueType,
              style: TextStyle(
                color: _getSeverityColor(caseItem.severity),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _getTimeAgo(caseItem.createdDate),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _getStatusColor(caseItem.status).withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            caseItem.status.name.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _getStatusColor(caseItem.status),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisPanel() {
    if (_investigationData.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Server Overview
          _buildServerOverviewCard(),
          
          const SizedBox(height: 16),
          
          // Risk Assessment
          _buildRiskAssessmentCard(),
          
          const SizedBox(height: 16),
          
          // Timeline Analysis
          _buildTimelineAnalysisCard(),
          
          const SizedBox(height: 16),
          
          // Pattern Analysis
          _buildPatternAnalysisCard(),
          
          const SizedBox(height: 16),
          
          // Peer Comparison
          _buildPeerComparisonCard(),
          
          const SizedBox(height: 16),
          
          // Investigation Actions
          _buildInvestigationActionsCard(),
        ],
      ),
    );
  }

  Widget _buildNoCaseSelectedPanel() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Select a Case or Server',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose an investigation case from the left panel\nor select a server to begin analysis',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildServerOverviewCard() {
    final server = _investigationData['server'] as Server;
    final assessment = _investigationData['assessment'] as EnhancedIntegrityAssessment;
    final runCount = _investigationData['runCount'] as int;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.computer,
                  color: _getRiskLevelColor(assessment.riskLevel),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${server.id}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getRiskLevelColor(assessment.riskLevel).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    assessment.riskLevel.name.toUpperCase(),
                    style: TextStyle(
                      color: _getRiskLevelColor(assessment.riskLevel),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewMetric(
                    'Risk Score',
                    '${assessment.riskScore.toInt()}/100',
                    _getRiskLevelColor(assessment.riskLevel),
                    Icons.warning,
                  ),
                ),
                Expanded(
                  child: _buildOverviewMetric(
                    'Total Runs',
                    runCount.toString(),
                    Colors.blue,
                    Icons.directions_run,
                  ),
                ),
                Expanded(
                  child: _buildOverviewMetric(
                    'Active Alerts',
                    assessment.alerts.length.toString(),
                    assessment.alerts.isNotEmpty ? Colors.red : Colors.green,
                    Icons.notifications,
                  ),
                ),
                Expanded(
                  child: _buildOverviewMetric(
                    'Z-Score',
                    assessment.zScore.toStringAsFixed(2),
                    assessment.zScore > 2 ? Colors.red : Colors.green,
                    Icons.analytics,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewMetric(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
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
    );
  }

  Widget _buildRiskAssessmentCard() {
    final assessment = _investigationData['assessment'] as EnhancedIntegrityAssessment;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.security, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Risk Assessment',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Risk Factors
            if (assessment.riskFactors.isNotEmpty) ...[
              const Text(
                'Risk Factors:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...assessment.riskFactors.map((factor) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(factor)),
                  ],
                ),
              )).toList(),
              const SizedBox(height: 16),
            ],
            
            // Advanced Metrics
            Row(
              children: [
                Expanded(
                  child: _buildRiskMetric(
                    'Mechanical Score',
                    assessment.mechanicalScore,
                    'Higher values indicate bot-like behavior',
                  ),
                ),
                Expanded(
                  child: _buildRiskMetric(
                    'Session Score',
                    assessment.sessionDurationScore,
                    'Extended session detection',
                  ),
                ),
                Expanded(
                  child: _buildRiskMetric(
                    'Click Clusters',
                    assessment.clickClusters.length.toDouble(),
                    'Number of burst patterns detected',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskMetric(String label, double value, String description) {
    Color color = Colors.green;
    if (value > 0.7) {
      color = Colors.red;
    } else if (value > 0.4) {
      color = Colors.orange;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineAnalysisCard() {
    final timeline = _investigationData['timeline'] as List<TimelineEvent>;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.timeline, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Activity Timeline',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 300,
              child: ListView.builder(
                itemCount: timeline.length,
                itemBuilder: (context, index) {
                  final event = timeline[index];
                  final isLast = index == timeline.length - 1;
                  
                  return IntrinsicHeight(
                    child: Row(
                      children: [
                        // Timeline indicator
                        Column(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getSeverityColor(event.severity),
                                shape: BoxShape.circle,
                              ),
                            ),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: Colors.grey[300],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        
                        // Event content
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: _getSeverityColor(event.severity).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getSeverityColor(event.severity).withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _getEventTypeIcon(event.type),
                                      color: _getSeverityColor(event.severity),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDateTime(event.timestamp),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  event.description,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternAnalysisCard() {
    final patterns = _investigationData['patterns'] as Map<String, dynamic>;
    final bins = _investigationData['bins'] as Map<String, int>;
    
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
            
            // Statistical Summary
            Row(
              children: [
                Expanded(
                  child: _buildPatternStat(
                    'Mean',
                    patterns['mean']?.toStringAsFixed(1) ?? '0',
                    'Average runs per time period',
                  ),
                ),
                Expanded(
                  child: _buildPatternStat(
                    'Std Dev',
                    patterns['standardDeviation']?.toStringAsFixed(2) ?? '0',
                    'Variability in run patterns',
                  ),
                ),
                Expanded(
                  child: _buildPatternStat(
                    'CoV',
                    patterns['coefficientOfVariation']?.toStringAsFixed(2) ?? '0',
                    'Coefficient of Variation',
                  ),
                ),
                Expanded(
                  child: _buildPatternStat(
                    'Range',
                    patterns['range']?.toString() ?? '0',
                    'Max - Min runs',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Run Distribution Chart
            Container(
              height: 200,
              child: _buildRunDistributionChart(bins),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternStat(String label, String value, String description) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRunDistributionChart(Map<String, int> bins) {
    final data = bins.entries.map((entry) {
      return BarChartGroupData(
        x: int.parse(entry.key.replaceAll('+', '')),
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: Colors.purple,
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: bins.values.isEmpty ? 10 : bins.values.reduce((a, b) => a > b ? a : b).toDouble() * 1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value == 4 ? '4+' : value.toInt().toString(),
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data,
      ),
    );
  }

  Widget _buildPeerComparisonCard() {
    final peerData = _investigationData['peerComparison'] as Map<String, dynamic>;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.compare_arrows, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Peer Comparison',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildComparisonMetric(
                    'Server Runs',
                    peerData['serverCount']?.toString() ?? '0',
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildComparisonMetric(
                    'Peer Average',
                    peerData['peerMean']?.toStringAsFixed(1) ?? '0',
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildComparisonMetric(
                    'Z-Score',
                    peerData['zScore']?.toStringAsFixed(2) ?? '0',
                    _getZScoreColor(peerData['zScore'] ?? 0),
                  ),
                ),
                Expanded(
                  child: _buildComparisonMetric(
                    'Percentile',
                    '${peerData['percentile']?.toInt() ?? 0}%',
                    Colors.purple,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Z-Score Interpretation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getZScoreColor(peerData['zScore'] ?? 0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getZScoreColor(peerData['zScore'] ?? 0).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statistical Interpretation:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(_getZScoreInterpretation(peerData['zScore'] ?? 0)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInvestigationActionsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.gavel, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Investigation Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildActionButton(
                  'Create Case',
                  Icons.create_new_folder,
                  Colors.blue,
                  () => _showCreateCaseDialog(),
                ),
                _buildActionButton(
                  'Export Evidence',
                  Icons.download,
                  Colors.green,
                  () => _exportEvidence(),
                ),
                _buildActionButton(
                  'Add Note',
                  Icons.note_add,
                  Colors.orange,
                  () => _showAddNoteDialog(),
                ),
                _buildActionButton(
                  'Flag for Review',
                  Icons.flag,
                  Colors.red,
                  () => _flagForReview(),
                ),
                _buildActionButton(
                  'Schedule Follow-up',
                  Icons.schedule,
                  Colors.purple,
                  () => _scheduleFollowUp(),
                ),
                _buildActionButton(
                  'Close Investigation',
                  Icons.check_circle,
                  Colors.grey,
                  () => _closeInvestigation(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  // Utility methods for UI
  Color _getSeverityColor(CaseSeverity severity) {
    switch (severity) {
      case CaseSeverity.low: return Colors.green;
      case CaseSeverity.medium: return Colors.orange;
      case CaseSeverity.high: return Colors.red;
      case CaseSeverity.critical: return Colors.red[900]!;
    }
  }

  IconData _getSeverityIcon(CaseSeverity severity) {
    switch (severity) {
      case CaseSeverity.low: return Icons.info;
      case CaseSeverity.medium: return Icons.warning;
      case CaseSeverity.high: return Icons.error;
      case CaseSeverity.critical: return Icons.dangerous;
    }
  }

  Color _getStatusColor(CaseStatus status) {
    switch (status) {
      case CaseStatus.pending: return Colors.blue;
      case CaseStatus.active: return Colors.orange;
      case CaseStatus.review: return Colors.purple;
      case CaseStatus.closed: return Colors.green;
      case CaseStatus.escalated: return Colors.red;
    }
  }

  Color _getRiskLevelColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.green: return Colors.green;
      case RiskLevel.yellow: return Colors.yellow[700]!;
      case RiskLevel.orange: return Colors.orange;
      case RiskLevel.red: return Colors.red;
    }
  }

  IconData _getEventTypeIcon(EventType type) {
    switch (type) {
      case EventType.alert: return Icons.notification_important;
      case EventType.pattern: return Icons.pattern;
      case EventType.session: return Icons.access_time;
      case EventType.action: return Icons.play_arrow;
    }
  }

  Color _getZScoreColor(double zScore) {
    if (zScore.abs() > 3) return Colors.red;
    if (zScore.abs() > 2) return Colors.orange;
    if (zScore.abs() > 1) return Colors.yellow[700]!;
    return Colors.green;
  }

  String _getZScoreInterpretation(double zScore) {
    if (zScore.abs() > 3) {
      return 'Extreme outlier - Very unusual activity pattern (>99.7% confidence)';
    } else if (zScore.abs() > 2) {
      return 'Significant outlier - Unusual activity pattern (>95% confidence)';
    } else if (zScore.abs() > 1) {
      return 'Moderate outlier - Somewhat unusual activity pattern (>68% confidence)';
    } else {
      return 'Normal range - Activity pattern within expected parameters';
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.day}/${dateTime.month}';
  }

  // Action methods (simplified for demo)
  void _showNewCaseDialog() {
    // Implementation for creating new investigation case
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('New investigation case creation dialog')),
    );
  }

  void _showCreateCaseDialog() {
    // Implementation for creating case from current analysis
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create case from current analysis')),
    );
  }

  void _exportEvidence() {
    // Implementation for exporting evidence
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Evidence export functionality')),
    );
  }

  void _showAddNoteDialog() {
    // Implementation for adding investigation notes
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add investigation note dialog')),
    );
  }

  void _flagForReview() {
    // Implementation for flagging server for review
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Server flagged for manager review')),
    );
  }

  void _scheduleFollowUp() {
    // Implementation for scheduling follow-up
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Follow-up scheduled')),
    );
  }

  void _closeInvestigation() {
    // Implementation for closing investigation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Investigation closed')),
    );
  }
}

// Data classes for investigation tools
class InvestigationCase {
  final String id;
  final String serverId;
  final String serverName;
  final String issueType;
  final CaseSeverity severity;
  final CaseStatus status;
  final DateTime createdDate;
  final String description;
  final String assignedTo;

  InvestigationCase({
    required this.id,
    required this.serverId,
    required this.serverName,
    required this.issueType,
    required this.severity,
    required this.status,
    required this.createdDate,
    required this.description,
    required this.assignedTo,
  });
}

class TimelineEvent {
  final DateTime timestamp;
  final EventType type;
  final String description;
  final CaseSeverity severity;

  TimelineEvent({
    required this.timestamp,
    required this.type,
    required this.description,
    required this.severity,
  });
}

enum CaseSeverity { low, medium, high, critical }
enum CaseStatus { pending, active, review, closed, escalated }
enum EventType { alert, pattern, session, action }

extension DoubleExtension on double {
  double sqrt() => math.sqrt(this);
}

class math {
  static double sqrt(double value) {
    if (value < 0) return double.nan;
    if (value == 0) return 0;
    
    double guess = value / 2;
    double prevGuess = 0;
    
    while ((guess - prevGuess).abs() > 0.0001) {
      prevGuess = guess;
      guess = (guess + value / guess) / 2;
    }
    
    return guess;
  }
}
