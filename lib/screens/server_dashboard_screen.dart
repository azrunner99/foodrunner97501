import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../utils/integrity_analyzer.dart';
import 'integrity_monitoring_info_screen.dart';
import 'server_integrity_profile_screen.dart';

class ServerDashboardScreen extends StatefulWidget {
  const ServerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ServerDashboardScreen> createState() => _ServerDashboardScreenState();
}

class _ServerDashboardScreenState extends State<ServerDashboardScreen> {
  String selectedPeriod = 'Today';
  bool _systemHealthExpanded = false;
  String _sortBy = 'name'; // 'name', 'integrity', 'alerts'
  bool _activeShiftOnly = false; // Toggle for filtering active shift servers only
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Monitoring Dashboard'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodSelector(),
            const SizedBox(height: 20),
            _buildOverviewCards(),
            const SizedBox(height: 20),
            _buildSystemHealth(),
            const SizedBox(height: 20),
            _buildSmartInsights(),
            const SizedBox(height: 20),
            _buildServerWatchlist(),
            const SizedBox(height: 20),
            _buildServerList(),
            const SizedBox(height: 20),
            _buildShiftStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemHealth() {
    final app = context.watch<AppState>();
    final servers = app.servers;
    final assessments = _generateIntegrityAssessments(app, servers);
    
    final highRisk = assessments.where((a) => a.riskScore >= 70).length;
    final mediumRisk = assessments.where((a) => a.riskScore >= 40 && a.riskScore < 70).length;
    final totalServers = assessments.length;
    
    String healthStatus;
    Color healthColor;
    IconData healthIcon;
    
    if (highRisk == 0 && mediumRisk <= 1) {
      healthStatus = "All systems running smoothly";
      healthColor = Colors.green;
      healthIcon = Icons.verified;
    } else if (highRisk == 0 && mediumRisk <= 3) {
      healthStatus = "System stable with minor observations";
      healthColor = Colors.orange;
      healthIcon = Icons.info;
    } else if (highRisk <= 2) {
      healthStatus = "Some servers need attention";
      healthColor = Colors.orange;
      healthIcon = Icons.warning;
    } else {
      healthStatus = "Multiple integrity concerns detected";
      healthColor = Colors.red;
      healthIcon = Icons.error;
    }
    
    return Card(
      elevation: 2,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _systemHealthExpanded = !_systemHealthExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      const Text(
                        'System Health',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Icon(
                        _systemHealthExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const IntegrityMonitoringInfoScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Learn more about integrity monitoring systems',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[600],
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: healthColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: healthColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(healthIcon, color: healthColor, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                healthStatus,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: healthColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$totalServers servers monitored • ${highRisk + mediumRisk} requiring review',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_systemHealthExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'System Details:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  _buildHealthDetailRow('Total Servers Monitored', '$totalServers', Icons.computer),
                  _buildHealthDetailRow('Green Status (Normal)', '${totalServers - highRisk - mediumRisk}', Icons.check_circle, Colors.green),
                  if (mediumRisk > 0)
                    _buildHealthDetailRow('Medium Risk Servers', '$mediumRisk', Icons.warning, Colors.orange),
                  if (highRisk > 0)
                    _buildHealthDetailRow('High Risk Servers', '$highRisk', Icons.error, Colors.red),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Last updated: ${DateTime.now().toString().substring(11, 19)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSmartInsights() {
    final app = context.watch<AppState>();
    final servers = app.servers;
    final assessments = _generateIntegrityAssessments(app, servers);
    final insights = _generateSmartInsights(assessments);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.purple[600]),
                const SizedBox(width: 8),
                const Text(
                  'Smart Insights',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (insights.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No unusual patterns detected. Everything looks normal.',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...insights.map((insight) => _buildInsightItem(insight)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(Map<String, dynamic> insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: insight['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: insight['color'].withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            insight['icon'],
            color: insight['color'],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insight['message'],
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerWatchlist() {
    final app = context.watch<AppState>();
    final servers = app.servers;
    final assessments = _generateIntegrityAssessments(app, servers);
    final flaggedServers = assessments.where((a) => a.riskScore >= 40).toList();
    flaggedServers.sort((a, b) => b.riskScore.compareTo(a.riskScore));
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.visibility, color: Colors.orange[600]),
                const SizedBox(width: 8),
                const Text(
                  'Server Watchlist',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (flaggedServers.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No servers on watchlist. All activity patterns look normal.',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...flaggedServers.take(5).map((assessment) => _buildWatchlistItem(assessment, app)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchlistItem(IntegrityAssessment assessment, AppState app) {
    final server = app.serverById(assessment.serverId);
    final profile = app.profiles[assessment.serverId];
    final explanation = _getPlainEnglishExplanation(assessment);
    
    Color riskColor;
    String riskLevel;
    
    if (assessment.riskScore >= 70) {
      riskColor = Colors.red;
      riskLevel = 'High';
    } else if (assessment.riskScore >= 40) {
      riskColor = Colors.orange;
      riskLevel = 'Medium';
    } else {
      riskColor = Colors.yellow;
      riskLevel = 'Low';
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: riskColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: profile?.avatarPath != null 
                    ? AssetImage(profile!.avatarPath!) 
                    : const AssetImage('assets/avatars/image001.png'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  server?.name ?? 'Unknown Server',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$riskLevel Risk',
                  style: TextStyle(
                    fontSize: 12,
                    color: riskColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            explanation,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['Today', 'This Week', 'This Month', 'All Time'];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time Period',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: periods.map((period) {
                final isSelected = period == selectedPeriod;
                return ChoiceChip(
                  label: Text(period),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      selectedPeriod = period;
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    final app = context.watch<AppState>();
    final servers = app.servers;
    final profiles = app.profiles;
    final activeServers = servers.where((s) => (profiles[s.id]?.allTimeRuns ?? 0) > 0).length;
    final totalRuns = servers.fold(0, (sum, s) => sum + (profiles[s.id]?.allTimeRuns ?? 0));
    final avgRuns = activeServers > 0 ? (totalRuns / activeServers).round() : 0;
    
    return Row(
      children: [
        Expanded(
          child: _buildOverviewCard(
            'Active Servers',
            activeServers.toString(),
            Icons.computer,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOverviewCard(
            'Total Runs',
            totalRuns.toString(),
            Icons.directions_run,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOverviewCard(
            'Average',
            avgRuns.toString(),
            Icons.analytics,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerList() {
    final app = context.watch<AppState>();
    final servers = app.servers;
    final profiles = app.profiles;
    final assessments = _generateIntegrityAssessments(app, servers);
    
    // Create a list of server data
    final serverData = servers
        .map((server) => {
              'server': server,
              'profile': profiles[server.id],
              'runs': profiles[server.id]?.allTimeRuns ?? 0,
              'assessment': assessments.firstWhere(
                (a) => a.serverId == server.id,
                orElse: () => IntegrityAssessment(
                  serverId: server.id,
                  serverName: server.name,
                  riskScore: 0,
                  riskLevel: RiskLevel.green,
                  riskFactors: [],
                  alerts: [],
                  analysisTime: DateTime.now(),
                  clickData: ClickAnalysisData(
                    totalClickMinutes: 0,
                    singleClickMinutes: 0,
                    doubleClickMinutes: 0,
                    tripleClickMinutes: 0,
                    quadPlusClickMinutes: 0,
                    totalRuns: 0,
                  ),
                ),
              ),
            })
        .where((data) {
          // Filter by active shift if toggle is enabled
          if (_activeShiftOnly && app.shiftActive) {
            final server = data['server'] as Server;
            return app.workingServerIds.contains(server.id);
          }
          return true; // Show all servers when toggle is off or no active shift
        })
        .toList();
    
    // Sort based on selected criteria
    switch (_sortBy) {
      case 'name':
        serverData.sort((a, b) => (a['server'] as Server).name.compareTo((b['server'] as Server).name));
        break;
      case 'integrity':
        serverData.sort((a, b) => (b['assessment'] as IntegrityAssessment).riskScore.compareTo((a['assessment'] as IntegrityAssessment).riskScore));
        break;
      case 'alerts':
        serverData.sort((a, b) {
          final aAlerts = (a['assessment'] as IntegrityAssessment).alerts.length;
          final bAlerts = (b['assessment'] as IntegrityAssessment).alerts.length;
          return bAlerts.compareTo(aAlerts);
        });
        break;
      default:
        serverData.sort((a, b) => (b['runs'] as int).compareTo(a['runs'] as int));
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'All Servers - Integrity Scores (Tap any server to view profile)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                // Active Shift Only toggle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: _activeShiftOnly ? Colors.orange[300]! : Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                    color: _activeShiftOnly ? Colors.orange[50] : Colors.transparent,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Active Shift Only',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _activeShiftOnly ? FontWeight.w600 : FontWeight.normal,
                          color: _activeShiftOnly ? Colors.orange[800] : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: _activeShiftOnly,
                          onChanged: (bool value) {
                            setState(() {
                              _activeShiftOnly = value;
                            });
                          },
                          activeColor: Colors.orange,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _sortBy,
                    onChanged: (String? newValue) {
                      setState(() {
                        _sortBy = newValue!;
                      });
                    },
                    underline: const SizedBox.shrink(),
                    icon: const Icon(Icons.sort, size: 18),
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                    items: const [
                      DropdownMenuItem(
                        value: 'name',
                        child: Text('Sort by Name'),
                      ),
                      DropdownMenuItem(
                        value: 'integrity',
                        child: Text('Sort by Integrity'),
                      ),
                      DropdownMenuItem(
                        value: 'alerts',
                        child: Text('Sort by Alerts'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (serverData.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No servers found',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              // Make the server list scrollable and show all servers
              Container(
                height: 400, // Fixed height for scrollable area
                child: ListView.builder(
                  itemCount: serverData.length,
                  itemBuilder: (context, index) {
                    return _buildServerItem(serverData[index], app);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerItem(Map<String, dynamic> data, AppState app) {
    final server = data['server'] as Server;
    final profile = data['profile'] as ServerProfile?;
    final runs = data['runs'] as int;
    final assessment = data['assessment'] as IntegrityAssessment;
    final hasAlerts = assessment.alerts.isNotEmpty;
    final hasHighRiskAlerts = assessment.alerts.any((alert) => 
        alert.level == AlertLevel.high || alert.level == AlertLevel.critical);
    
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ServerIntegrityProfileScreen(
            server: server,
            assessment: assessment,
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasAlerts ? Colors.orange[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: hasAlerts ? Border.all(color: Colors.orange.withOpacity(0.3), width: 1) : null,
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: profile?.avatarPath != null 
                      ? AssetImage(profile!.avatarPath!) 
                      : const AssetImage('assets/avatars/image001.png'),
                ),
                if (hasAlerts)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: hasHighRiskAlerts ? Colors.red : Colors.orange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Icon(
                        Icons.warning,
                        size: 8,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        server.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.touch_app,
                        size: 14,
                        color: Colors.blue[600],
                      ),
                      Text(
                        ' View profile',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (_activeShiftOnly && app.shiftActive) ...[
                        // Show current shift runs when toggle is active
                        Text(
                          '${app.currentCounts[server.id] ?? 0} runs (current shift)',
                          style: TextStyle(color: Colors.orange[600], fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ] else ...[
                        // Show all-time runs when toggle is off
                        Text(
                          '$runs runs',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                      if (hasAlerts) ...[
                        Text(
                          ' • ${assessment.alerts.length} alert${assessment.alerts.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            color: hasHighRiskAlerts ? Colors.red[600] : Colors.orange[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: assessment.riskColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shield,
                    size: 12,
                    color: assessment.riskColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${assessment.riskScore.toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: assessment.riskColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftStatus() {
    final app = context.watch<AppState>();
    final isActive = app.shiftActive;
    final shiftType = app.shiftType;
    final workingCount = app.workingServerIds.length;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Shift Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive ? Colors.green[50] : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive ? Colors.green[300]! : Colors.grey[300]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? Colors.green : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isActive ? 'Shift Active' : 'Restaurant Closed',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.green[700] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Shift Type: $shiftType'),
                  Text('Working Servers: $workingCount'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<IntegrityAssessment> _generateIntegrityAssessments(AppState app, List<Server> servers) {
    final allServerCounts = <String, int>{};
    for (final server in servers) {
      allServerCounts[server.id] = _getRunCountForDateRange(app, server.id);
    }

    return servers.map((server) {
      final bins = _getIntegrityBinsForDateRange(app, server.id);
      final runCount = _getRunCountForDateRange(app, server.id);
      
      try {
        // Generate enhanced assessment with advanced pattern recognition
        final enhancedAssessment = IntegrityAnalyzer.analyzeServerAdvanced(
          serverId: server.id,
          serverName: server.name,
          clickBins: bins,
          totalRuns: runCount,
          allServers: servers,
          allServerCounts: allServerCounts,
          analysisTime: DateTime.now(),
        );
        
        // Return the enhanced assessment which contains all advanced analytics
        return enhancedAssessment.toBasicAssessment();
      } catch (e) {
        // Fallback to basic assessment if enhanced fails
        return IntegrityAnalyzer.analyzeServer(
          serverId: server.id,
          serverName: server.name,
          clickBins: bins,
          totalRuns: runCount,
          allServers: servers,
          allServerCounts: allServerCounts,
          analysisTime: DateTime.now(),
        );
      }
    }).toList();
  }

  Map<String, int> _getIntegrityBinsForDateRange(AppState app, String serverId) {
    final now = DateTime.now();
    
    switch (selectedPeriod) {
      case 'Today':
        return app.integrityBinsForDateRange(serverId, todayOnly: true);
      case 'This Week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return app.integrityBinsForDateRange(
          serverId,
          startDate: weekAgo,
          endDate: now,
        );
      case 'This Month':
        final monthAgo = now.subtract(const Duration(days: 30));
        return app.integrityBinsForDateRange(
          serverId,
          startDate: monthAgo,
          endDate: now,
        );
      case 'All Time':
        return app.integrityBinsFor(serverId, todayOnly: false);
      default:
        return app.integrityBinsForDateRange(serverId, todayOnly: true);
    }
  }

  int _getRunCountForDateRange(AppState app, String serverId) {
    switch (selectedPeriod) {
      case 'Today':
        return app.currentCounts[serverId] ?? 0;
      case 'This Week':
      case 'This Month':
        // For week/month, we need to calculate from the integrity bins
        final bins = _getIntegrityBinsForDateRange(app, serverId);
        return bins.values.fold(0, (sum, value) => sum + value);
      case 'All Time':
        return app.profiles[serverId]?.allTimeRuns ?? 0;
      default:
        return app.currentCounts[serverId] ?? 0;
    }
  }

  List<Map<String, dynamic>> _generateSmartInsights(List<IntegrityAssessment> assessments) {
    final insights = <Map<String, dynamic>>[];
    
    // High risk servers
    final highRiskServers = assessments.where((a) => a.riskScore >= 70).toList();
    if (highRiskServers.isNotEmpty) {
      insights.add({
        'icon': Icons.warning,
        'color': Colors.red,
        'message': '${highRiskServers.length} server${highRiskServers.length > 1 ? 's show' : ' shows'} unusual activity patterns that need immediate attention.',
      });
    }
    
    // Medium risk servers
    final mediumRiskServers = assessments.where((a) => a.riskScore >= 40 && a.riskScore < 70).toList();
    if (mediumRiskServers.isNotEmpty) {
      insights.add({
        'icon': Icons.info,
        'color': Colors.orange,
        'message': '${mediumRiskServers.length} server${mediumRiskServers.length > 1 ? 's have' : ' has'} moderate concerns worth monitoring.',
      });
    }
    
    // Alert analysis
    final serversWithAlerts = assessments.where((a) => a.alerts.isNotEmpty).length;
    if (serversWithAlerts > 0) {
      insights.add({
        'icon': Icons.notification_important,
        'color': Colors.orange,
        'message': '$serversWithAlerts server${serversWithAlerts > 1 ? 's have' : ' has'} active alerts requiring review.',
      });
    }
    
    // Performance insights
    final totalRuns = assessments.fold(0, (sum, a) => sum + a.clickData.totalRuns);
    if (totalRuns > 0) {
      final avgRuns = totalRuns / assessments.length;
      final topPerformers = assessments.where((a) => a.clickData.totalRuns > avgRuns * 1.5).length;
      if (topPerformers > 0) {
        insights.add({
          'icon': Icons.star,
          'color': Colors.green,
          'message': '$topPerformers server${topPerformers > 1 ? 's are' : ' is'} performing exceptionally well this period.',
        });
      }
    }
    
    // If no concerns, show positive message
    if (insights.isEmpty || insights.every((i) => i['color'] == Colors.green)) {
      insights.insert(0, {
        'icon': Icons.check_circle,
        'color': Colors.green,
        'message': 'All servers are operating within normal parameters.',
      });
    }
    
    return insights;
  }

  Widget _buildHealthDetailRow(String label, String value, IconData icon, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color ?? Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color ?? Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  String _getPlainEnglishExplanation(IntegrityAssessment assessment) {
    final reasons = <String>[];
    
    // Base the explanation on risk score and factors
    if (assessment.riskScore >= 80) {
      reasons.add('Shows very unusual activity patterns');
    } else if (assessment.riskScore >= 60) {
      reasons.add('Has concerning activity patterns');
    } else if (assessment.riskScore >= 40) {
      reasons.add('Shows some irregular patterns');
    }
    
    // Include specific risk factors mentioned in the assessment
    if (assessment.riskFactors.isNotEmpty) {
      for (final factor in assessment.riskFactors.take(2)) {
        if (factor.toLowerCase().contains('cluster')) {
          reasons.add('has periods of very rapid clicking');
        } else if (factor.toLowerCase().contains('session')) {
          reasons.add('works for unusually long periods');
        } else if (factor.toLowerCase().contains('peer') || factor.toLowerCase().contains('outlier')) {
          reasons.add('performs very differently from other servers');
        } else if (factor.toLowerCase().contains('volume')) {
          reasons.add('has unusually high activity levels');
        } else if (factor.toLowerCase().contains('temporal') || factor.toLowerCase().contains('time')) {
          reasons.add('shows unusual timing patterns');
        } else if (factor.toLowerCase().contains('pattern')) {
          reasons.add('has mechanical or repetitive patterns');
        }
      }
    }
    
    // Check for alerts
    if (assessment.alerts.isNotEmpty) {
      final alertCount = assessment.alerts.length;
      if (alertCount == 1) {
        reasons.add('has 1 active alert');
      } else {
        reasons.add('has $alertCount active alerts');
      }
    }
    
    if (reasons.isEmpty) {
      return 'Activity patterns are slightly unusual but within acceptable range.';
    }
    
    if (reasons.length == 1) {
      return reasons.first.capitalize() + '.';
    } else if (reasons.length == 2) {
      return '${reasons[0].capitalize()} and ${reasons[1]}.';
    } else {
      return '${reasons.take(reasons.length - 1).map((r) => r.capitalize()).join(', ')}, and ${reasons.last}.';
    }
  }
}

extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
