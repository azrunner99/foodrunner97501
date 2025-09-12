import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../app_state.dart';
import '../models.dart';
import '../utils/integrity_analyzer.dart';
import 'shift_click_analysis_screen.dart';

class ServerIntegrityProfileScreen extends StatefulWidget {
  final Server server;
  final IntegrityAssessment assessment;

  const ServerIntegrityProfileScreen({
    Key? key,
    required this.server,
    required this.assessment,
  }) : super(key: key);

  @override
  State<ServerIntegrityProfileScreen> createState() => _ServerIntegrityProfileScreenState();
}

class _ServerIntegrityProfileScreenState extends State<ServerIntegrityProfileScreen> {
  String selectedTimeframe = 'Today';
  Timer? _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    _startRefreshTimer();
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    if (selectedTimeframe == 'Current Shift') {
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        setState(() {}); // Refresh the UI with current data
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final profile = app.profiles[widget.server.id];
    
    // Generate assessment based on selected timeframe
    final assessment = _getAssessmentForTimeframe(app);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.server.name} - Audit Server Profile'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh the assessment
              setState(() {});
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildServerHeader(profile),
            const SizedBox(height: 20),
            _buildTimeframeSelector(),
            const SizedBox(height: 20),
            _buildIntegrityScoreCard(assessment),
            const SizedBox(height: 20),
            _buildRiskFactorsCard(assessment),
            const SizedBox(height: 20),
            _buildClickPatternAnalysis(assessment),
            const SizedBox(height: 20),
            _buildPerformanceMetrics(profile),
            const SizedBox(height: 20),
            _buildActivityTimeline(),
            const SizedBox(height: 20),
            _buildAlertHistory(assessment),
          ],
        ),
      ),
    );
  }

  IntegrityAssessment _getAssessmentForTimeframe(AppState app) {
    if (selectedTimeframe == 'Current Shift' && app.shiftActive) {
      // Generate real-time assessment for current shift
      return _generateCurrentShiftAssessment(app);
    } else {
      // Use the existing assessment passed to the screen
      return widget.assessment;
    }
  }

  IntegrityAssessment _generateCurrentShiftAssessment(AppState app) {
    final serverId = widget.server.id;
    final profile = app.profiles[serverId];
    
    // Get current shift data
    final currentShiftRuns = app.currentCounts[serverId] ?? 0;
    
    // Calculate current shift risk factors
    final riskFactors = <String>[];
    var riskScore = 0.0;
    
    // Analyze current shift patterns
    if (currentShiftRuns > 15) {
      riskFactors.add('High activity during current shift (${currentShiftRuns} runs)');
      riskScore += 20;
    }
    
    if (profile != null) {
      final avgSpeed = profile.avgSecondsBetweenRuns;
      if (avgSpeed < 30) {
        riskFactors.add('Very fast average click speed in current shift');
        riskScore += 25;
      }
    }
    
    // Generate current shift alerts
    final alerts = <Alert>[];
    if (currentShiftRuns > 20) {
      alerts.add(Alert(
        level: AlertLevel.medium,
        title: 'High Current Shift Activity',
        message: 'Server has completed $currentShiftRuns runs in current shift',
        serverId: serverId,
        timestamp: DateTime.now(),
      ));
    }
    
    // Create risk level based on score
    RiskLevel riskLevel;
    if (riskScore >= 70) {
      riskLevel = RiskLevel.red;
    } else if (riskScore >= 40) {
      riskLevel = RiskLevel.orange;
    } else if (riskScore >= 20) {
      riskLevel = RiskLevel.yellow;
    } else {
      riskLevel = RiskLevel.green;
    }
    
    return IntegrityAssessment(
      serverId: serverId,
      serverName: widget.server.name,
      riskScore: riskScore,
      riskLevel: riskLevel,
      riskFactors: riskFactors,
      alerts: alerts,
      analysisTime: DateTime.now(),
      clickData: ClickAnalysisData(
        totalClickMinutes: currentShiftRuns,
        singleClickMinutes: (currentShiftRuns * 0.7).round(),
        doubleClickMinutes: (currentShiftRuns * 0.2).round(),
        tripleClickMinutes: (currentShiftRuns * 0.08).round(),
        quadPlusClickMinutes: (currentShiftRuns * 0.02).round(),
        totalRuns: currentShiftRuns,
      ),
    );
  }

  Widget _buildServerHeader(ServerProfile? profile) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: profile?.avatarPath != null 
                  ? AssetImage(profile!.avatarPath!) 
                  : const AssetImage('assets/avatars/image001.png'),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.server.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.badge, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Server ID: ${widget.server.id}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.work, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Total Runs: ${profile?.allTimeRuns ?? 0}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (profile?.hireDate.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Hire Date: ${profile!.hireDate}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    final app = context.watch<AppState>();
    final isShiftActive = app.shiftActive;
    final shiftType = app.shiftType;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analysis Timeframe',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Current Shift option (only show if shift is active)
                  if (isShiftActive) ...[
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('Current $shiftType'),
                          ],
                        ),
                        selected: selectedTimeframe == 'Current Shift',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              selectedTimeframe = 'Current Shift';
                            });
                            _startRefreshTimer();
                          }
                        },
                      ),
                    ),
                  ],
                  // Standard timeframe options
                  ...['Today', 'This Week', 'This Month', 'All Time']
                      .map((period) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(period),
                              selected: selectedTimeframe == period,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    selectedTimeframe = period;
                                  });
                                  _startRefreshTimer();
                                }
                              },
                            ),
                          ))
                      .toList(),
                ],
              ),
            ),
            if (selectedTimeframe == 'Current Shift' && isShiftActive) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.green[600], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Live data from active $shiftType shift',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green[600],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIntegrityScoreCard(IntegrityAssessment assessment) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Colors.blue[600]),
                const SizedBox(width: 8),
                const Text(
                  'Integrity Score',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: assessment.riskColor,
                        width: 8,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${assessment.riskScore.toInt()}%',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: assessment.riskColor,
                            ),
                          ),
                          Text(
                            assessment.riskDescription,
                            style: TextStyle(
                              fontSize: 12,
                              color: assessment.riskColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Last updated: ${_formatTime(assessment.analysisTime)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildScoreBreakdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBreakdown() {
    // Simulated breakdown for enhanced assessment
    final breakdowns = [
      {'name': 'Click Pattern Analysis', 'score': 85, 'weight': 25},
      {'name': 'Volume Consistency', 'score': 75, 'weight': 30},
      {'name': 'Timing Patterns', 'score': 90, 'weight': 25},
      {'name': 'Peer Comparison', 'score': 80, 'weight': 20},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Score Breakdown',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...breakdowns.map((item) => _buildScoreBreakdownItem(
          item['name'] as String,
          item['score'] as int,
          item['weight'] as int,
        )).toList(),
      ],
    );
  }

  Widget _buildScoreBreakdownItem(String name, int score, int weight) {
    final color = score >= 80 ? Colors.green : score >= 60 ? Colors.orange : Colors.red;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${score}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          Text(
            ' (${weight}%)',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskFactorsCard(IntegrityAssessment assessment) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[600]),
                const SizedBox(width: 8),
                const Text(
                  'Risk Factors',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (assessment.riskFactors.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600]),
                    const SizedBox(width: 8),
                    const Text(
                      'No risk factors detected - excellent behavior!',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )
            else
              ...assessment.riskFactors.map((factor) => _buildRiskFactorItem(factor)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskFactorItem(String factor) {
    // Check if this is a clickable 4+ clicks per minute factor
    final isClickableFactor = factor.toLowerCase().contains('4+ clicks per minute detected');
    final instanceCount = _extractInstanceCount(factor);
    
    Widget cardContent = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
        // Add elevation and shadow for clickable items
        boxShadow: isClickableFactor ? [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Row(
        children: [
          Icon(
            isClickableFactor ? Icons.touch_app : Icons.info, 
            color: Colors.orange[600], 
            size: 16
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              factor,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isClickableFactor ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (isClickableFactor) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.orange[600],
              size: 12,
            ),
          ],
        ],
      ),
    );

    // Make clickable if it's a 4+ clicks factor
    if (isClickableFactor) {
      return GestureDetector(
        onTap: () => _navigateToClickInstances(instanceCount),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          child: cardContent,
        ),
      );
    }
    
    return cardContent;
  }

  int _extractInstanceCount(String factor) {
    // Extract number from factor text like "4+ clicks per minute detected (3 instances)"
    final match = RegExp(r'\((\d+) instances?\)').firstMatch(factor);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '0') ?? 0;
    }
    
    // Fallback: look for just a number before "instances"
    final fallbackMatch = RegExp(r'(\d+) instances?').firstMatch(factor);
    if (fallbackMatch != null) {
      return int.tryParse(fallbackMatch.group(1) ?? '0') ?? 0;
    }
    
    return 3; // Default fallback value
  }

  void _navigateToClickInstances(int instanceCount) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ShiftClickAnalysisScreen(
          server: widget.server,
        ),
      ),
    );
  }

  Widget _buildClickPatternAnalysis(IntegrityAssessment assessment) {
    final clickData = assessment.clickData;
    
    return Card(
      elevation: 6,
      shadowColor: Colors.purple.withOpacity(0.3),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ShiftClickAnalysisScreen(
                server: widget.server,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                Colors.purple.withOpacity(0.02),
                Colors.purple.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.mouse, color: Colors.purple[600]),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Click Pattern Analysis',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Details',
                            style: TextStyle(
                              color: Colors.purple[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.purple[700],
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildClickStatCard(
                        'Total Minutes',
                        clickData.totalClickMinutes.toString(),
                        Icons.schedule,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildClickStatCard(
                        'Total Runs',
                        clickData.totalRuns.toString(),
                        Icons.directions_run,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Click Distribution per Minute',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _buildClickDistributionChart(clickData),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClickStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickDistributionChart(ClickAnalysisData clickData) {
    final total = clickData.totalClickMinutes;
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No click data available',
          style: TextStyle(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      );
    }

    final data = [
      {'label': '1 click', 'value': clickData.singleClickMinutes, 'color': Colors.green},
      {'label': '2 clicks', 'value': clickData.doubleClickMinutes, 'color': Colors.yellow[700]!},
      {'label': '3 clicks', 'value': clickData.tripleClickMinutes, 'color': Colors.orange},
      {'label': '4+ clicks', 'value': clickData.quadPlusClickMinutes, 'color': Colors.red},
    ];

    return Column(
      children: data.map((item) {
        final percentage = total > 0 ? (item['value'] as int) / total : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  item['label'] as String,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(item['color'] as Color),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${item['value']} (${(percentage * 100).toInt()}%)',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPerformanceMetrics(ServerProfile? profile) {
    final app = context.watch<AppState>();
    
    if (profile == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No profile data available',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.green[600]),
                const SizedBox(width: 8),
                Text(
                  selectedTimeframe == 'Current Shift' ? 'Current Shift Performance' : 'Performance Metrics',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (selectedTimeframe == 'Current Shift' && app.shiftActive) ...[
              // Current shift specific metrics
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Shift Runs',
                      '${app.currentCounts[widget.server.id] ?? 0}',
                      Icons.directions_run,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      'Shift Type',
                      app.shiftType,
                      Icons.schedule,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Status',
                      app.workingServerIds.contains(widget.server.id) ? 'Active' : 'Inactive',
                      app.workingServerIds.contains(widget.server.id) ? Icons.play_circle : Icons.pause_circle,
                      app.workingServerIds.contains(widget.server.id) ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      'Last Update',
                      _formatTime(DateTime.now()),
                      Icons.refresh,
                      Colors.indigo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
            ],
            // Standard performance metrics
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Best Shift',
                    '${profile.bestShiftRuns} runs',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    'Best Streak',
                    '${profile.streakBest}',
                    Icons.local_fire_department,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Points',
                    '${profile.points}',
                    Icons.emoji_events,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    'Pizookie Runs',
                    '${profile.pizookieRuns}',
                    Icons.cake,
                    Colors.brown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'MVP Shifts',
                    '${profile.shiftsAsMvp}',
                    Icons.military_tech,
                    Colors.amber,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    'Avg Speed',
                    '${profile.avgSecondsBetweenRuns.toInt()}s',
                    Icons.speed,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
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
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTimeline() {
    final app = context.watch<AppState>();
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: Colors.indigo[600]),
                const SizedBox(width: 8),
                Text(
                  selectedTimeframe == 'Current Shift' ? 'Current Shift Activity' : 'Recent Activity Timeline',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (selectedTimeframe == 'Current Shift' && app.shiftActive) ...[
              // Current shift specific timeline
              _buildTimelineItem(
                'Shift Status',
                app.workingServerIds.contains(widget.server.id) ? 'Currently active in ${app.shiftType} shift' : 'Not active in current shift',
                'Now',
                app.workingServerIds.contains(widget.server.id) ? Icons.play_circle : Icons.pause_circle,
                app.workingServerIds.contains(widget.server.id) ? Colors.green : Colors.grey,
              ),
              _buildTimelineItem(
                'Shift Progress',
                '${app.currentCounts[widget.server.id] ?? 0} runs completed this shift',
                'Real-time',
                Icons.trending_up,
                Colors.blue,
              ),
              _buildTimelineItem(
                'System Check',
                'Integrity monitoring active',
                'Continuous',
                Icons.security,
                Colors.purple,
              ),
            ] else ...[
              // Standard timeline
              _buildTimelineItem(
                'Last Activity',
                'Food delivery completed',
                '2 minutes ago',
                Icons.check_circle,
                Colors.green,
              ),
              _buildTimelineItem(
                'Previous Session',
                'Active shift completed',
                '1 hour ago',
                Icons.work,
                Colors.blue,
              ),
              _buildTimelineItem(
                'Pattern Analysis',
                'Integrity assessment updated',
                '3 hours ago',
                Icons.analytics,
                Colors.purple,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(String title, String description, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
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
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertHistory(IntegrityAssessment assessment) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.red[600]),
                const SizedBox(width: 8),
                const Text(
                  'Alert History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (assessment.alerts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600]),
                    const SizedBox(width: 8),
                    const Text(
                      'No alerts in recent history - clean record!',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )
            else
              ...assessment.alerts.map((alert) => _buildAlertHistoryItem(alert)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertHistoryItem(Alert alert) {
    Color alertColor;
    IconData alertIcon;
    
    switch (alert.level) {
      case AlertLevel.low:
        alertColor = Colors.yellow[700]!;
        alertIcon = Icons.info;
        break;
      case AlertLevel.medium:
        alertColor = Colors.orange;
        alertIcon = Icons.warning;
        break;
      case AlertLevel.high:
        alertColor = Colors.red;
        alertIcon = Icons.error;
        break;
      case AlertLevel.critical:
        alertColor = Colors.red[900]!;
        alertIcon = Icons.dangerous;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: alertColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: alertColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(alertIcon, color: alertColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  alert.message,
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            alert.level.toString().split('.').last.toUpperCase(),
            style: TextStyle(
              color: alertColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
