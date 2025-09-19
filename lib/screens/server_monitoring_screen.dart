import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../widgets/wallpaper_background.dart';
import '../models.dart';

class ServerMonitoringScreen extends StatefulWidget {
  const ServerMonitoringScreen({super.key});

  @override
  State<ServerMonitoringScreen> createState() => _ServerMonitoringScreenState();
}

class _ServerMonitoringScreenState extends State<ServerMonitoringScreen> {
  String _selectedTimeFrame = 'Today';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Monitoring'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.shade600.withOpacity(0.8),
                Colors.blue.shade400.withOpacity(0.6),
              ],
            ),
          ),
        ),
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
          child: Column(
            children: [
              _buildTimeFrameSelector(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildQuickInsights(app),
                    const SizedBox(height: 16),
                    _buildCurrentShiftOverview(app),
                    const SizedBox(height: 16),
                    _buildServerPerformanceList(app),
                    const SizedBox(height: 16),
                    _buildActivityPatterns(app),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeFrameSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          for (final timeFrame in [
            'Today',
            'Last 3 Days',
            'Last Week',
            'Last Month'
          ])
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTimeFrame = timeFrame),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedTimeFrame == timeFrame
                        ? Colors.blue.shade500
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    timeFrame,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _selectedTimeFrame == timeFrame
                          ? Colors.white
                          : Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickInsights(AppState app) {
    final insights = _calculateQuickInsights(app);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
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
              Icon(Icons.insights, color: Colors.blue.shade600, size: 24),
              const SizedBox(width: 12),
              Text(
                'Quick Insights',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInsightCard(
                  'Active Servers',
                  '${insights['activeServers']}',
                  Colors.green,
                  Icons.people,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInsightCard(
                  'Total Runs',
                  '${insights['totalRuns']}',
                  Colors.orange,
                  Icons.directions_run,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInsightCard(
                  'Avg Runs/Server',
                  '${insights['avgRunsPerServer']}',
                  Colors.purple,
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInsightCard(
                  'Top Performer',
                  insights['topPerformer'] ?? 'None',
                  Colors.blue,
                  Icons.star,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentShiftOverview(AppState app) {
    if (app.shiftStart == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Text(
              'No active shift',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final duration = DateTime.now().difference(app.shiftStart!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade50,
            Colors.green.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.green.shade600, size: 24),
              const SizedBox(width: 12),
              Text(
                'Current Shift',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade500,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Duration: ${hours}h ${minutes}m',
            style: TextStyle(
              fontSize: 16,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Started: ${_formatTime(app.shiftStart!)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.green.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerPerformanceList(AppState app) {
    final serverStats = _calculateServerStats(app);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.leaderboard, color: Colors.blue.shade600, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Server Performance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          if (serverStats.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No activity data available for the selected time frame.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            )
          else
            ...serverStats.map((stat) => _buildServerStatRow(stat)),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildServerStatRow(Map<String, dynamic> stat) {
    final status = _getServerStatus(stat['runs'] as int);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: status['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: status['color'].withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: status['color'],
            child: Text(
              stat['name'].toString().substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat['name'].toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stat['runs']} runs • ${status['label']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${stat['runs']}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: status['color'],
                ),
              ),
              if (stat['lastActivity'] != null)
                Text(
                  _formatLastActivity(stat['lastActivity']),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityPatterns(AppState app) {
    final patterns = _calculateActivityPatterns(app);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
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
              Icon(Icons.analytics, color: Colors.purple.shade600, size: 24),
              const SizedBox(width: 12),
              Text(
                'Activity Insights',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (patterns['needsAttention'].isNotEmpty) ...[
            _buildPatternInsight(
              'Needs Attention',
              '${patterns['needsAttention'].length} server(s)',
              Icons.warning,
              Colors.orange,
            ),
            const SizedBox(height: 12),
          ],
          _buildPatternInsight(
            'Average Runs/Hour',
            '${patterns['avgRunsPerHour']}',
            Icons.speed,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildPatternInsight(
            'Peak Performance',
            patterns['topPerformerName'] ?? 'No data',
            Icons.trending_up,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildPatternInsight(
      String title, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _calculateQuickInsights(AppState app) {
    final shifts = _getShiftsForTimeFrame(app);
    final serverCounts = <String, int>{};
    int totalRuns = 0;

    for (final shift in shifts) {
      for (final entry in shift.counts.entries) {
        serverCounts[entry.key] = (serverCounts[entry.key] ?? 0) + entry.value;
        totalRuns += entry.value;
      }
    }

    final activeServers = serverCounts.keys.length;
    final avgRunsPerServer =
        activeServers > 0 ? (totalRuns / activeServers).round() : 0;

    String? topPerformer;
    if (serverCounts.isNotEmpty) {
      final topEntry =
          serverCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
      final server = app.servers.firstWhere((s) => s.id == topEntry.key,
          orElse: () => Server(id: '', name: 'Unknown'));
      topPerformer = server.name;
    }

    return {
      'activeServers': activeServers,
      'totalRuns': totalRuns,
      'avgRunsPerServer': avgRunsPerServer,
      'topPerformer': topPerformer,
    };
  }

  List<Map<String, dynamic>> _calculateServerStats(AppState app) {
    final shifts = _getShiftsForTimeFrame(app);
    final serverCounts = <String, int>{};
    final serverLastActivity = <String, DateTime>{};

    for (final shift in shifts) {
      for (final entry in shift.counts.entries) {
        serverCounts[entry.key] = (serverCounts[entry.key] ?? 0) + entry.value;
        if (entry.value > 0) {
          serverLastActivity[entry.key] = shift.start;
        }
      }
    }

    final stats = <Map<String, dynamic>>[];
    for (final entry in serverCounts.entries) {
      final server = app.servers.firstWhere(
        (s) => s.id == entry.key,
        orElse: () => Server(id: entry.key, name: 'Unknown Server'),
      );

      stats.add({
        'id': entry.key,
        'name': server.name,
        'runs': entry.value,
        'lastActivity': serverLastActivity[entry.key],
      });
    }

    // Sort by runs (descending)
    stats.sort((a, b) => (b['runs'] as int).compareTo(a['runs'] as int));

    return stats;
  }

  Map<String, dynamic> _calculateActivityPatterns(AppState app) {
    final shifts = _getShiftsForTimeFrame(app);
    final serverCounts = <String, int>{};
    final needsAttention = <String>[];

    for (final shift in shifts) {
      for (final entry in shift.counts.entries) {
        serverCounts[entry.key] = (serverCounts[entry.key] ?? 0) + entry.value;
      }
    }

    // Calculate patterns
    final totalRuns = serverCounts.values.fold(0, (sum, runs) => sum + runs);
    final totalHours =
        shifts.isNotEmpty ? shifts.length * 4 : 1; // Estimate 4 hours per shift
    final avgRunsPerHour =
        totalHours > 0 ? (totalRuns / totalHours).round() : 0;

    String? topPerformerName;
    if (serverCounts.isNotEmpty) {
      final topEntry =
          serverCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
      final server = app.servers.firstWhere((s) => s.id == topEntry.key,
          orElse: () => Server(id: '', name: 'Unknown'));
      topPerformerName = server.name;
    }

    // Find servers that need attention (low activity)
    for (final entry in serverCounts.entries) {
      if (entry.value < 3) {
        // Less than 3 runs needs attention
        final server = app.servers.firstWhere((s) => s.id == entry.key,
            orElse: () => Server(id: '', name: 'Unknown'));
        needsAttention.add(server.name);
      }
    }

    return {
      'avgRunsPerHour': avgRunsPerHour,
      'topPerformerName': topPerformerName,
      'needsAttention': needsAttention,
    };
  }

  List<ShiftRecord> _getShiftsForTimeFrame(AppState app) {
    final now = DateTime.now();
    final shifts = app.history;

    switch (_selectedTimeFrame) {
      case 'Today':
        return shifts
            .where((s) =>
                s.start.year == now.year &&
                s.start.month == now.month &&
                s.start.day == now.day)
            .toList();
      case 'Last 3 Days':
        final threeDaysAgo = now.subtract(const Duration(days: 3));
        return shifts.where((s) => s.start.isAfter(threeDaysAgo)).toList();
      case 'Last Week':
        final oneWeekAgo = now.subtract(const Duration(days: 7));
        return shifts.where((s) => s.start.isAfter(oneWeekAgo)).toList();
      case 'Last Month':
        final oneMonthAgo = now.subtract(const Duration(days: 30));
        return shifts.where((s) => s.start.isAfter(oneMonthAgo)).toList();
      default:
        return shifts;
    }
  }

  Map<String, dynamic> _getServerStatus(int runs) {
    if (runs == 0) {
      return {'label': 'No Activity', 'color': Colors.grey};
    } else if (runs <= 3) {
      return {'label': 'Low Activity', 'color': Colors.orange};
    } else if (runs <= 8) {
      return {'label': 'Normal Activity', 'color': Colors.blue};
    } else if (runs <= 15) {
      return {'label': 'High Activity', 'color': Colors.green};
    } else {
      return {'label': 'Very High Activity', 'color': Colors.purple};
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatLastActivity(DateTime? time) {
    if (time == null) return 'Never';

    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
