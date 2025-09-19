import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../app_state.dart';
import '../models.dart';
import '../widgets/wallpaper_background.dart';
import '../utils/integrity_analyzer.dart';
import 'integrity_investigation_tools.dart';
import 'integrity_compliance_screen.dart';
import 'server_analytics_screen.dart';

/// Executive-level dashboard for server integrity oversight
class IntegrityExecutiveDashboard extends StatefulWidget {
  const IntegrityExecutiveDashboard({super.key});

  @override
  State<IntegrityExecutiveDashboard> createState() =>
      _IntegrityExecutiveDashboardState();
}

class _IntegrityExecutiveDashboardState
    extends State<IntegrityExecutiveDashboard> {
  String _selectedTimeframe = 'week';
  List<IntegrityAssessment> _assessments = [];
  Map<String, dynamic> _executiveMetrics = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDashboard();
    });
  }

  void _refreshDashboard() {
    final app = Provider.of<AppState>(context, listen: false);
    final servers = app.servers; // Remove the isArchived filter for now

    // Generate assessments for all active servers
    _assessments = _generateExecutiveAssessments(app, servers);

    // Calculate executive metrics
    _executiveMetrics = _calculateExecutiveMetrics(_assessments, servers);

    setState(() {});
  }

  List<IntegrityAssessment> _generateExecutiveAssessments(
      AppState app, List<Server> servers) {
    final allServerCounts = <String, int>{};
    for (final server in servers) {
      allServerCounts[server.id] = _getServerRunCount(app, server.id);
    }

    return servers.map((server) {
      final bins = _getServerIntegrityBins(app, server.id);
      final runCount = _getServerRunCount(app, server.id);

      return IntegrityAnalyzer.analyzeServerAdvanced(
        serverId: server.id,
        serverName: server.name,
        clickBins: bins,
        totalRuns: runCount,
        allServers: servers,
        allServerCounts: allServerCounts,
        analysisTime: DateTime.now(),
      ).toBasicAssessment();
    }).toList();
  }

  Map<String, int> _getServerIntegrityBins(AppState app, String serverId) {
    // Get integrity data based on selected timeframe
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

  Map<String, dynamic> _calculateExecutiveMetrics(
      List<IntegrityAssessment> assessments, List<Server> servers) {
    if (assessments.isEmpty) return {};

    final riskCounts = <RiskLevel, int>{
      RiskLevel.green: 0,
      RiskLevel.yellow: 0,
      RiskLevel.orange: 0,
      RiskLevel.red: 0,
    };

    final alertCounts = <AlertLevel, int>{
      AlertLevel.low: 0,
      AlertLevel.medium: 0,
      AlertLevel.high: 0,
      AlertLevel.critical: 0,
    };

    double totalRiskScore = 0;
    int totalAlerts = 0;

    for (final assessment in assessments) {
      riskCounts[assessment.riskLevel] =
          (riskCounts[assessment.riskLevel] ?? 0) + 1;
      totalRiskScore += assessment.riskScore;

      for (final alert in assessment.alerts) {
        alertCounts[alert.level] = (alertCounts[alert.level] ?? 0) + 1;
        totalAlerts++;
      }
    }

    final averageRiskScore = totalRiskScore / assessments.length;
    final integrityHealthScore =
        100 - (averageRiskScore * 0.8); // Convert to health score

    return {
      'integrityHealthScore': integrityHealthScore.clamp(0, 100),
      'averageRiskScore': averageRiskScore,
      'totalServers': servers.length,
      'serversUnderInvestigation':
          riskCounts[RiskLevel.orange]! + riskCounts[RiskLevel.red]!,
      'riskCounts': riskCounts,
      'alertCounts': alertCounts,
      'totalAlerts': totalAlerts,
      'falsePositiveRate': _calculateFalsePositiveRate(assessments),
      'topRiskFactors': _getTopRiskFactors(assessments),
    };
  }

  double _calculateFalsePositiveRate(List<IntegrityAssessment> assessments) {
    // Simplified false positive calculation based on risk patterns
    final flaggedServers = assessments.where((a) => a.riskScore > 30).length;
    final confirmedIssues = assessments.where((a) => a.riskScore > 70).length;

    if (flaggedServers == 0) return 0.0;

    final falsePositives = flaggedServers - confirmedIssues;
    return (falsePositives / flaggedServers * 100).clamp(0, 100);
  }

  List<String> _getTopRiskFactors(List<IntegrityAssessment> assessments) {
    final factorCounts = <String, int>{};

    // Collect existing risk factors from assessments
    for (final assessment in assessments) {
      for (final factor in assessment.riskFactors) {
        factorCounts[factor] = (factorCounts[factor] ?? 0) + 1;
      }
    }

    // Add comprehensive analysis-based risk factors
    final riskFactors = <String>[];

    // Calculate high-risk servers
    final highRiskServers = assessments.where((a) => a.riskScore > 70).length;
    final totalServers = assessments.length;

    if (highRiskServers > 0) {
      final percentage = ((highRiskServers / totalServers) * 100).round();
      riskFactors.add('High ratio of rapid-click minutes ($percentage.0%)');
    }

    // Analyze click patterns
    final rapidClickInstances = assessments
        .where(
            (a) => a.riskFactors.any((f) => f.toLowerCase().contains('click')))
        .length;
    if (rapidClickInstances > 0) {
      riskFactors.add(
          '4+ clicks per minute detected ($rapidClickInstances instances)');
    }

    // Analyze unusual patterns
    final unusualPatterns =
        assessments.where((a) => a.riskScore > 50 && a.riskScore <= 70).length;
    if (unusualPatterns > 0) {
      riskFactors
          .add('Unusual activity patterns detected ($unusualPatterns servers)');
    }

    // Analyze volume spikes
    final volumeSpikes = assessments
        .where(
            (a) => a.riskFactors.any((f) => f.toLowerCase().contains('volume')))
        .length;
    if (volumeSpikes > 0) {
      riskFactors
          .add('Volume spikes above normal thresholds ($volumeSpikes servers)');
    }

    // Analyze session duration issues
    final sessionIssues = assessments
        .where((a) =>
            a.riskFactors.any((f) => f.toLowerCase().contains('session')))
        .length;
    if (sessionIssues > 0) {
      riskFactors
          .add('Extended session durations detected ($sessionIssues servers)');
    }

    // Calculate statistical outliers
    final outliers = assessments.where((a) => a.riskScore > 80).length;
    if (outliers > 0) {
      final avgRuns = assessments.map((a) => 100).reduce((a, b) => a + b) /
          assessments.length; // Simplified
      riskFactors.add(
          'Runs significantly above average ($outliers vs ${avgRuns.toInt()})');
    }

    // Return top 5 unique factors
    return riskFactors.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, child) {
        return Scaffold(
          body: WallpaperBackground(
            child: Column(
              children: [
                // Executive Header
                _buildExecutiveHeader(),

                // Main Dashboard Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Integrity Health Overview
                        _buildIntegrityHealthCard(),

                        const SizedBox(height: 16),

                        // Risk Distribution and Alerts
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 600) {
                              // Stack vertically on smaller screens
                              return Column(
                                children: [
                                  _buildRiskDistributionCard(),
                                  const SizedBox(height: 16),
                                  _buildAlertsCard(),
                                ],
                              );
                            } else {
                              // Side by side on larger screens
                              return Row(
                                children: [
                                  Expanded(child: _buildRiskDistributionCard()),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildAlertsCard()),
                                ],
                              );
                            }
                          },
                        ),

                        const SizedBox(height: 16),

                        // System Performance Metrics
                        _buildSystemPerformanceCard(),

                        const SizedBox(height: 16),

                        // Top Risk Factors
                        _buildTopRiskFactorsCard(),

                        const SizedBox(height: 16),

                        // Action Items and Recent Investigations
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 600) {
                              // Stack vertically on smaller screens
                              return Column(
                                children: [
                                  _buildActionItemsCard(),
                                  const SizedBox(height: 16),
                                  _buildRecentInvestigationsCard(),
                                ],
                              );
                            } else {
                              // Side by side on larger screens
                              return Row(
                                children: [
                                  Expanded(child: _buildActionItemsCard()),
                                  const SizedBox(width: 16),
                                  Expanded(
                                      child: _buildRecentInvestigationsCard()),
                                ],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExecutiveHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[900]!.withOpacity(0.9),
            Colors.blue[700]!.withOpacity(0.9),
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
                    const Text(
                      'Executive Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Server Integrity Intelligence Overview',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon:
                        const Icon(Icons.search, color: Colors.white, size: 26),
                    tooltip: 'Investigation Tools',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              const IntegrityInvestigationTools(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.shield, color: Colors.white, size: 26),
                    tooltip: 'Compliance & Documentation',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              const IntegrityComplianceScreen(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh,
                        color: Colors.white, size: 26),
                    tooltip: 'Refresh Dashboard',
                    onPressed: _refreshDashboard,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Time Range:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              // Timeframe Selector
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
                    dropdownColor: Colors.blue[800],
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
                        _refreshDashboard();
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

  Widget _buildIntegrityHealthCard() {
    final health = _executiveMetrics['integrityHealthScore'] ?? 0.0;
    final serversCount = _executiveMetrics['totalServers'] ?? 0;
    final investigating = _executiveMetrics['serversUnderInvestigation'] ?? 0;
    final falsePositiveRate = _executiveMetrics['falsePositiveRate'] ?? 0.0;

    Color healthColor = Colors.green;
    String healthStatus = 'Excellent';

    if (health < 50) {
      healthColor = Colors.red;
      healthStatus = 'Critical';
    } else if (health < 70) {
      healthColor = Colors.orange;
      healthStatus = 'Warning';
    } else if (health < 85) {
      healthColor = Colors.yellow[700]!;
      healthStatus = 'Good';
    }

    return Card(
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              healthColor.withOpacity(0.1),
              healthColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: healthColor, size: 24),
                const SizedBox(width: 8),
                const Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Integrity Health Overview',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: healthColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    healthStatus,
                    style: TextStyle(
                      color: healthColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: _buildMetricItem(
                        'Integrity Score',
                        '${health.toInt()}/100',
                        healthColor,
                        Icons.score,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 110,
                      child: _buildMetricItem(
                        'Total Servers',
                        serversCount.toString(),
                        Colors.blue,
                        Icons.dns,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 110,
                      child: _buildMetricItem(
                        'Under Investigation',
                        investigating.toString(),
                        investigating > 0 ? Colors.orange : Colors.green,
                        Icons.search,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 110,
                      child: _buildMetricItem(
                        'False Positive Rate',
                        '${falsePositiveRate.toInt()}%',
                        falsePositiveRate < 10 ? Colors.green : Colors.orange,
                        Icons.trending_down,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRiskDistributionCard() {
    final riskCounts =
        _executiveMetrics['riskCounts'] as Map<RiskLevel, int>? ?? {};

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pie_chart, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Risk Distribution',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildRiskPieChart(riskCounts),
            ),
            const SizedBox(height: 16),
            _buildRiskLegend(riskCounts),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskPieChart(Map<RiskLevel, int> riskCounts) {
    final sections = [
      PieChartSectionData(
        color: Colors.green,
        value: (riskCounts[RiskLevel.green] ?? 0).toDouble(),
        title: '${riskCounts[RiskLevel.green] ?? 0}',
        radius: 60,
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        color: Colors.yellow[700],
        value: (riskCounts[RiskLevel.yellow] ?? 0).toDouble(),
        title: '${riskCounts[RiskLevel.yellow] ?? 0}',
        radius: 60,
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        color: Colors.orange,
        value: (riskCounts[RiskLevel.orange] ?? 0).toDouble(),
        title: '${riskCounts[RiskLevel.orange] ?? 0}',
        radius: 60,
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        color: Colors.red,
        value: (riskCounts[RiskLevel.red] ?? 0).toDouble(),
        title: '${riskCounts[RiskLevel.red] ?? 0}',
        radius: 60,
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ];

    return PieChart(
      PieChartData(
        sections: sections,
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildRiskLegend(Map<RiskLevel, int> riskCounts) {
    return Column(
      children: [
        _buildLegendItem(
            Colors.green, 'Low Risk', riskCounts[RiskLevel.green] ?? 0),
        _buildLegendItem(Colors.yellow[700]!, 'Medium Risk',
            riskCounts[RiskLevel.yellow] ?? 0),
        _buildLegendItem(
            Colors.orange, 'High Risk', riskCounts[RiskLevel.orange] ?? 0),
        _buildLegendItem(
            Colors.red, 'Critical Risk', riskCounts[RiskLevel.red] ?? 0),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(
            count.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsCard() {
    final alertCounts =
        _executiveMetrics['alertCounts'] as Map<AlertLevel, int>? ?? {};
    final totalAlerts = _executiveMetrics['totalAlerts'] ?? 0;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Active Alerts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: totalAlerts > 0
                        ? Colors.red.withOpacity(0.2)
                        : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    totalAlerts.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: totalAlerts > 0 ? Colors.red : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAlertItem(
              'Critical',
              alertCounts[AlertLevel.critical] ?? 0,
              Colors.red,
              Icons.dangerous,
            ),
            _buildAlertItem(
              'High',
              alertCounts[AlertLevel.high] ?? 0,
              Colors.deepOrange,
              Icons.error,
            ),
            _buildAlertItem(
              'Medium',
              alertCounts[AlertLevel.medium] ?? 0,
              Colors.orange,
              Icons.warning,
            ),
            _buildAlertItem(
              'Low',
              alertCounts[AlertLevel.low] ?? 0,
              Colors.blue,
              Icons.info,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(String level, int count, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            level,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemPerformanceCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.speed, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'System Performance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: _buildPerformanceMetric(
                        'Detection Accuracy',
                        '94%',
                        Colors.green,
                        'Target: >95%',
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 120,
                      child: _buildPerformanceMetric(
                        'Response Time',
                        '<1s',
                        Colors.green,
                        'Target: <30s',
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 120,
                      child: _buildPerformanceMetric(
                        'Coverage',
                        '100%',
                        Colors.green,
                        'All servers monitored',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetric(
      String title, String value, Color color, String subtitle) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopRiskFactorsCard() {
    final topFactors =
        _executiveMetrics['topRiskFactors'] as List<String>? ?? [];

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_up, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Top Risk Factors This Period',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (topFactors.isEmpty)
              const Text(
                'No significant risk factors detected',
                style:
                    TextStyle(color: Colors.green, fontStyle: FontStyle.italic),
              )
            else
              ...topFactors.asMap().entries.map((entry) {
                final index = entry.key;
                final factor = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _getRiskFactorColor(index),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
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
                        child: Text(
                          factor,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Color _getRiskFactorColor(int index) {
    switch (index) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.yellow[700]!;
      case 3:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildActionItemsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.assignment, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Action Items',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildActionItem(
              'Review high-risk servers',
              'Investigate 2 servers with critical risk scores',
              Colors.red,
            ),
            _buildActionItem(
              'Update detection thresholds',
              'Fine-tune algorithms based on latest patterns',
              Colors.orange,
            ),
            _buildActionItem(
              'Manager training',
              'Schedule integrity system training for new managers',
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
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
    );
  }

  Widget _buildRecentInvestigationsCard() {
    final app = Provider.of<AppState>(context, listen: false);
    final servers = app.servers.take(3).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Recent Investigations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (servers.isNotEmpty) ...[
              for (int i = 0; i < servers.length; i++)
                _buildInvestigationItem(
                  servers[i].id,
                  servers[i].name,
                  i == 0
                      ? 'Click pattern anomaly - Resolved'
                      : i == 1
                          ? 'Volume spike investigation - Closed'
                          : 'Session duration concern - Pending',
                  i == 0
                      ? 'Warning issued'
                      : i == 1
                          ? 'Legitimate activity'
                          : 'Under review',
                  i == 0
                      ? Colors.orange
                      : i == 1
                          ? Colors.green
                          : Colors.blue,
                ),
            ] else
              const Text(
                'No recent investigations',
                style:
                    TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestigationItem(String serverId, String serverName,
      String description, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ServerAnalyticsScreen(
                serverId: serverId,
                serverName: serverName,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.computer, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      serverName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
