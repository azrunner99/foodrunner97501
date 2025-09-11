import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../app_state.dart';
import '../models.dart';
import '../widgets/wallpaper_background.dart';
import '../utils/integrity_analyzer.dart';

class ServerIntegrityScreen extends StatefulWidget {
  const ServerIntegrityScreen({super.key});

  @override
  State<ServerIntegrityScreen> createState() => _ServerIntegrityScreenState();
}

class _ServerIntegrityScreenState extends State<ServerIntegrityScreen> {
  String _dateRange = 'today'; // 'today', 'week', '2weeks', 'month', 'custom'
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  String _sortBy = 'risk'; // 'risk', 'name', 'runs'
  List<IntegrityAssessment> _assessments = [];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    
    final servers = _shouldFilterByRoster()
        ? app.workingServerIds.map((id) => app.serverById(id)).whereType<Server>().toList()
        : app.servers;

    // Generate integrity assessments
    _assessments = _generateAssessments(app, servers);
    _sortAssessments();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Integrity'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.red.shade600.withOpacity(0.8),
                Colors.red.shade400.withOpacity(0.6),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortOptions,
          ),
        ],
      ),
      body: WallpaperBackground(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.1),
                Colors.black.withOpacity(0.3),
              ],
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Alert Summary Card
                _buildAlertSummary(),
                
                // System Health Overview
                _buildSystemHealth(),
                
                // Filter Controls
                _buildFilterControls(),
                
                // Server Risk Assessment List
                _buildServerAssessmentList(),
                
                // Bottom padding to prevent cut-off
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertSummary() {
    final criticalAlerts = _assessments
        .expand((a) => a.alerts)
        .where((alert) => alert.level == AlertLevel.critical)
        .length;
    
    final highAlerts = _assessments
        .expand((a) => a.alerts)
        .where((alert) => alert.level == AlertLevel.high)
        .length;
    
    final mediumAlerts = _assessments
        .expand((a) => a.alerts)
        .where((alert) => alert.level == AlertLevel.medium)
        .length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.85),
          ],
        ),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.security, color: Colors.red.shade700),
              ),
              const SizedBox(width: 12),
              Text(
                'Security Dashboard',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAlertCounter(
                  'Critical', criticalAlerts, Colors.red, Icons.dangerous
                ),
              ),
              Expanded(
                child: _buildAlertCounter(
                  'High', highAlerts, Colors.deepOrange, Icons.error
                ),
              ),
              Expanded(
                child: _buildAlertCounter(
                  'Medium', mediumAlerts, Colors.orange, Icons.warning
                ),
              ),
              Expanded(
                child: _buildOverallHealth(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCounter(String label, int count, Color color, IconData icon) {
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            '$count',
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
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallHealth() {
    final averageRisk = _assessments.isEmpty 
        ? 0.0 
        : _assessments.map((a) => a.riskScore).reduce((a, b) => a + b) / _assessments.length;
    
    final healthScore = (100 - averageRisk).clamp(0.0, 100.0);
    Color healthColor = Colors.green;
    
    if (healthScore < 40) {
      healthColor = Colors.red;
    } else if (healthScore < 70) {
      healthColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: healthColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: healthColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.health_and_safety, color: healthColor, size: 24),
          const SizedBox(height: 4),
          Text(
            '${healthScore.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: healthColor,
            ),
          ),
          Text(
            'Health',
            style: TextStyle(
              fontSize: 12,
              color: healthColor.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemHealth() {
    final highRiskServers = _assessments.where((a) => a.riskLevel == RiskLevel.red).length;
    final mediumRiskServers = _assessments.where((a) => a.riskLevel == RiskLevel.orange).length;
    final totalServers = _assessments.length;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.9),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Analyzing $totalServers servers for suspicious activity patterns, click anomalies, and behavioral irregularities.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildHealthStat(
                  'High Risk', highRiskServers, Colors.red
                ),
              ),
              Expanded(
                child: _buildHealthStat(
                  'Medium Risk', mediumRiskServers, Colors.orange
                ),
              ),
              Expanded(
                child: _buildHealthStat(
                  'Normal', totalServers - highRiskServers - mediumRiskServers, Colors.green
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthStat(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            '$count',
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
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControls() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[100]?.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.red[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Analysis Period',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Dropdown for date range selection
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _dateRange,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: Colors.red[700]),
                style: TextStyle(color: Colors.red[700], fontSize: 14),
                items: const [
                  DropdownMenuItem(value: 'today', child: Text('Today Only')),
                  DropdownMenuItem(value: 'all', child: Text('All Time')),
                  DropdownMenuItem(value: 'week', child: Text('Last Week')),
                  DropdownMenuItem(value: '2weeks', child: Text('Last 2 Weeks')),
                  DropdownMenuItem(value: 'month', child: Text('Last Month')),
                  DropdownMenuItem(value: 'custom', child: Text('Custom Range')),
                ],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _dateRange = newValue;
                      if (newValue != 'custom') {
                        _customStartDate = null;
                        _customEndDate = null;
                      }
                    });
                  }
                },
              ),
            ),
          ),
          
          // Custom date picker (only show when custom is selected)
          if (_dateRange == 'custom') ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _selectDateRange(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.date_range, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _customStartDate != null && _customEndDate != null
                          ? '${DateFormat('MMM d, y').format(_customStartDate!)} - ${DateFormat('MMM d, y').format(_customEndDate!)}'
                          : 'Select date range',
                        style: TextStyle(
                          color: (_customStartDate != null && _customEndDate != null) ? Colors.red[700] : Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(Icons.calendar_today, color: Colors.red[700], size: 16),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper methods for date range functionality
  bool _shouldFilterByRoster() {
    return _dateRange == 'today';
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 180)),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 7)),
              end: DateTime.now(),
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.red.shade600,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
    }
  }

  Widget _buildServerAssessmentList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.9),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              gradient: LinearGradient(
                colors: [
                  Colors.red.shade400.withOpacity(0.8),
                  Colors.red.shade600.withOpacity(0.6),
                ],
              ),
            ),
            child: Row(
              children: const [
                Expanded(flex: 3, child: Text(
                  'Server',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                )),
                Expanded(flex: 2, child: Text(
                  'Risk Score',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                )),
                Expanded(flex: 2, child: Text(
                  'Status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                )),
                Expanded(flex: 2, child: Text(
                  'Alerts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                )),
              ],
            ),
          ),
          
          // Data Rows
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: _assessments.asMap().entries.map((entry) {
                final index = entry.key;
                final assessment = entry.value;
                return _buildAssessmentRow(assessment, index % 2 == 0);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentRow(IntegrityAssessment assessment, bool isEven) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isEven 
            ? Colors.red.withOpacity(0.05)
            : Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showServerDetails(assessment),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assessment.serverName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${assessment.clickData.totalRuns} runs',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: assessment.riskColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: assessment.riskColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          assessment.riskScore.toStringAsFixed(0),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: assessment.riskColor,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: assessment.riskColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      assessment.riskDescription,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: assessment.riskColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (assessment.alerts.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: assessment.alerts.first.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${assessment.alerts.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: assessment.alerts.first.color,
                            ),
                          ),
                        ),
                      ] else ...[
                        Icon(Icons.check_circle_outline, 
                             color: Colors.green, size: 18),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<IntegrityAssessment> _generateAssessments(AppState app, List<Server> servers) {
    final allServerCounts = <String, int>{};
    for (final server in servers) {
      allServerCounts[server.id] = _getRunCountForDateRange(app, server.id);
    }

    return servers.map((server) {
      final bins = _getIntegrityBinsForDateRange(app, server.id);
      final runCount = _getRunCountForDateRange(app, server.id);
      
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
    }).toList();
  }

  int _getRunCountForDateRange(AppState app, String serverId) {
    switch (_dateRange) {
      case 'today':
        // For today only, use current counts
        return app.currentCounts[serverId] ?? 0;
      case 'all':
        // For all time, use the reconstructed historical totals
        // Try profile first, then _totals as fallback
        final profile = app.profiles[serverId];
        if (profile != null && profile.allTimeRuns > 0) {
          return profile.allTimeRuns;
        }
        return app.totals[serverId] ?? 0;
      case 'week':
      case '2weeks':
      case 'month':
      case 'custom':
        // For specific date ranges, calculate from tap data
        print('DEBUG: Processing date range $_dateRange for server $serverId');
        final bins = _getIntegrityBinsForDateRange(app, serverId);
        int historicalCount = bins.values.fold(0, (sum, count) => sum + count);
        
        // If the date range includes today, add current counts
        final includesToday = _dateRangeIncludesToday();
        final currentCount = app.currentCounts[serverId] ?? 0;
        
        // Debug logging for custom range
        if (_dateRange == 'custom' && serverId == '4f55jaewuhldbaoi') {
          print('DEBUG Custom range for server $serverId:');
          print('  Start date: $_customStartDate');
          print('  End date: $_customEndDate');
          print('  Today: ${DateTime.now()}');
          print('  Includes today: $includesToday');
          print('  Historical count: $historicalCount');
          print('  Current count: $currentCount');
          print('  Bins: $bins');
        }
        
        if (includesToday) {
          historicalCount += currentCount;
        }
        
        return historicalCount;
      default:
        return app.currentCounts[serverId] ?? 0;
    }
  }

  bool _dateRangeIncludesToday() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    
    switch (_dateRange) {
      case 'week':
        final weekAgo = today.subtract(const Duration(days: 7));
        return todayStart.isAfter(weekAgo) || todayStart.isAtSameMomentAs(weekAgo);
      case '2weeks':
        final twoWeeksAgo = today.subtract(const Duration(days: 14));
        return todayStart.isAfter(twoWeeksAgo) || todayStart.isAtSameMomentAs(twoWeeksAgo);
      case 'month':
        final monthAgo = today.subtract(const Duration(days: 30));
        return todayStart.isAfter(monthAgo) || todayStart.isAtSameMomentAs(monthAgo);
      case 'custom':
        if (_customStartDate != null && _customEndDate != null) {
          // Use the same end-of-day logic as integrityBinsForDateRange
          final filterEndDate = DateTime(_customEndDate!.year, _customEndDate!.month, _customEndDate!.day, 23, 59, 59, 999);
          return (todayStart.isAfter(_customStartDate!) || todayStart.isAtSameMomentAs(_customStartDate!)) &&
                 (todayStart.isBefore(filterEndDate) || todayStart.isAtSameMomentAs(DateTime(filterEndDate.year, filterEndDate.month, filterEndDate.day)));
        }
        return false;
      default:
        return false;
    }
  }

  Map<String, int> _getIntegrityBinsForDateRange(AppState app, String serverId) {
    final now = DateTime.now();
    
    switch (_dateRange) {
      case 'today':
        return app.integrityBinsForDateRange(serverId, todayOnly: true);
      case 'all':
        return app.integrityBinsFor(serverId, todayOnly: false);
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return app.integrityBinsForDateRange(
          serverId,
          startDate: weekAgo,
          endDate: now,
        );
      case '2weeks':
        final twoWeeksAgo = now.subtract(const Duration(days: 14));
        return app.integrityBinsForDateRange(
          serverId,
          startDate: twoWeeksAgo,
          endDate: now,
        );
      case 'month':
        final monthAgo = now.subtract(const Duration(days: 30));
        return app.integrityBinsForDateRange(
          serverId,
          startDate: monthAgo,
          endDate: now,
        );
      case 'custom':
        if (_customStartDate != null && _customEndDate != null) {
          return app.integrityBinsForDateRange(
            serverId,
            startDate: _customStartDate!,
            endDate: _customEndDate!,
          );
        } else {
          // Fallback to today if custom dates not set
          return app.integrityBinsForDateRange(serverId, todayOnly: true);
        }
      default:
        return app.integrityBinsForDateRange(serverId, todayOnly: true);
    }
  }

  void _sortAssessments() {
    switch (_sortBy) {
      case 'risk':
        _assessments.sort((a, b) => b.riskScore.compareTo(a.riskScore));
        break;
      case 'name':
        _assessments.sort((a, b) => a.serverName.compareTo(b.serverName));
        break;
      case 'runs':
        _assessments.sort((a, b) => b.clickData.totalRuns.compareTo(a.clickData.totalRuns));
        break;
    }
  }

  void _showSortOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort By'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile(
              title: const Text('Risk Score'),
              value: 'risk',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() => _sortBy = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('Server Name'),
              value: 'name',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() => _sortBy = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('Run Count'),
              value: 'runs',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() => _sortBy = value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showServerDetails(IntegrityAssessment assessment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${assessment.serverName} - Integrity Report'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Risk Score Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: assessment.riskColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: assessment.riskColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: assessment.riskColor),
                    const SizedBox(width: 8),
                    Text(
                      'Risk Score: ${assessment.riskScore.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: assessment.riskColor,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: assessment.riskColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        assessment.riskDescription,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Click Data
              Text(
                'Click Analysis',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              _buildClickDataGrid(assessment.clickData),
              
              const SizedBox(height: 16),
              
              // Risk Factors
              if (assessment.riskFactors.isNotEmpty) ...[
                Text(
                  'Risk Factors',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                ...assessment.riskFactors.map((factor) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber, 
                           color: Colors.orange, size: 16),
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
                const SizedBox(height: 16),
              ],
              
              // Alerts
              if (assessment.alerts.isNotEmpty) ...[
                Text(
                  'Active Alerts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                ...assessment.alerts.map((alert) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: alert.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: alert.color.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(alert.icon, color: alert.color, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: alert.color,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              alert.message,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildClickDataGrid(ClickAnalysisData data) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildDataCell('Total Runs', '${data.totalRuns}')),
              Expanded(child: _buildDataCell('Active Minutes', '${data.totalClickMinutes}')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildDataCell('Single Clicks', '${data.singleClickMinutes}')),
              Expanded(child: _buildDataCell('Double Clicks', '${data.doubleClickMinutes}')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildDataCell('Triple Clicks', '${data.tripleClickMinutes}')),
              Expanded(child: _buildDataCell('4+ Clicks', '${data.quadPlusClickMinutes}')),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: data.rapidClickRatio > 0.2 ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  data.rapidClickRatio > 0.2 ? Icons.warning : Icons.check_circle,
                  color: data.rapidClickRatio > 0.2 ? Colors.orange : Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Rapid Click Ratio: ${(data.rapidClickRatio * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: data.rapidClickRatio > 0.2 ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCell(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
