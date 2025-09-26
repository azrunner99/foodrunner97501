import 'package:flutter/material.dart';
import 'package:food_runs_counter/models/performance_models.dart';
import 'package:food_runs_counter/services/unified_data_service.dart';
import 'package:food_runs_counter/utils/performance_calculator.dart';
import 'package:food_runs_counter/services/performance_flags.dart';
import 'package:food_runs_counter/utils/log.dart';

class ServerPerformanceScreenRestored extends StatefulWidget {
  @override
  _ServerPerformanceScreenRestoredState createState() => _ServerPerformanceScreenRestoredState();
}

class _ServerPerformanceScreenRestoredState extends State<ServerPerformanceScreenRestored> {
  List<ServerPerformanceData> _performanceData = [];
  Map<String, String> _serverNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPerformanceData();
  }

  Future<void> _loadPerformanceData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      d('[ServerPerformanceScreen] Loading unified server data...');
      final unifiedServers = await UnifiedDataService.instance.getAllServersWithData();
      d('[ServerPerformanceScreen] Found ${unifiedServers.length} servers, calculating performance...');

      final performanceList = <ServerPerformanceData>[];
      
      for (final unifiedServer in unifiedServers) {
        d('[ServerPerformanceScreen] Processing server: ${unifiedServer.serverName}');
        
        // Store server name
        _serverNames[unifiedServer.serverId] = unifiedServer.serverName;
        
        // Calculate performance metrics
        final performanceScore = _calculateOverallPerformanceScore(unifiedServer);
        final rating = _getPerformanceRating(unifiedServer);
        final flags = _generatePerformanceFlags(unifiedServer);
        final insights = _generatePerformanceInsights(unifiedServer, unifiedServer.serverId);
        
        // Create performance data
        final performance = ServerPerformanceData(
          serverId: unifiedServer.serverId,
          startDate: DateTime.now().subtract(Duration(days: 30)),
          endDate: DateTime.now(),
          totalFoodRuns: unifiedServer.shiftData.totalRuns,
          shiftsWorked: unifiedServer.shiftData.shiftsWorked,
          daysEmployed: unifiedServer.daysEmployed,
          totalGuestCount: unifiedServer.totalGuestCount,
          totalSales: unifiedServer.totalSales,
          shiftTypes: unifiedServer.shiftTypes,
          metrics: PerformanceMetrics(
            rawEfficiency: unifiedServer.shiftData.shiftsWorked > 0 
                ? unifiedServer.shiftData.totalRuns / unifiedServer.shiftData.shiftsWorked 
                : 0.0,
            guestEfficiency: unifiedServer.totalGuestCount > 0 
                ? unifiedServer.shiftData.totalRuns / unifiedServer.totalGuestCount 
                : 0.0,
            salesEfficiency: unifiedServer.totalSales > 0 
                ? unifiedServer.shiftData.totalRuns / unifiedServer.totalSales 
                : 0.0,
            consistencyScore: _calculateConsistencyScore(unifiedServer),
            experienceFactor: (unifiedServer.daysEmployed / 365.0).clamp(0.1, 1.0),
            adjustedPerformance: performanceScore,
            npsScore: unifiedServer.npsData.monthlyScore ?? 50.0,
            npsThreeMonth: unifiedServer.npsData.threeMonthAverage ?? 50.0,
            npsOneMonth: unifiedServer.npsData.monthlyScore ?? 50.0,
          ),
          performanceScore: performanceScore,
          rating: rating,
          flags: flags,
          insights: insights,
          calculatedDate: DateTime.now(),
        );
        
        performanceList.add(performance);
        d('[ServerPerformanceScreen] ✅ Processed ${unifiedServer.serverName}: ${performanceScore.toStringAsFixed(1)} score');
      }

      // Sort by performance score (highest first)
      performanceList.sort((a, b) => b.performanceScore.compareTo(a.performanceScore));

      setState(() {
        _performanceData = performanceList;
        _isLoading = false;
      });
      
      d('[ServerPerformanceScreen] ✅ Successfully loaded ${performanceList.length} performance records');
    } catch (e) {
      d('[ServerPerformanceScreen] ❌ Error loading performance data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Server Performance'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPerformanceData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _performanceData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        'No server data available',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _performanceData.length,
                  itemBuilder: (context, index) {
                    final performance = _performanceData[index];
                    return _buildServerCard(performance, index + 1);
                  },
                ),
    );
  }

  Widget _buildServerCard(ServerPerformanceData performance, int rank) {
    final serverName = _getServerName(performance.serverId);
    final isTopThree = rank <= 3;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: isTopThree
            ? Border.all(
                color: rank == 1
                    ? const Color(0xFFFFD700)
                    : rank == 2
                        ? const Color(0xFFC0C0C0)
                        : const Color(0xFFCD7F32),
                width: 3,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _showServerDetails(performance, serverName),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Rank Badge
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getRankColor(rank),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _getRankColor(rank).withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$rank',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Server Name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            serverName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            performance.rating.displayName,
                            style: TextStyle(
                              fontSize: 14,
                              color: _getRatingColor(performance.rating),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Performance Score
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getScoreColor(performance.performanceScore).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getScoreColor(performance.performanceScore).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${performance.performanceScore.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getScoreColor(performance.performanceScore),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Metrics Row
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        icon: Icons.directions_run,
                        label: 'Total Runs',
                        value: '${performance.totalFoodRuns}',
                        color: Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        icon: Icons.work,
                        label: 'Shifts',
                        value: '${performance.shiftsWorked}',
                        color: Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        icon: Icons.trending_up,
                        label: 'Avg/Shift',
                        value: performance.shiftsWorked > 0 
                            ? '${(performance.totalFoodRuns / performance.shiftsWorked).toStringAsFixed(1)}'
                            : '0.0',
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // NPS Score (if available)
                if (performance.metrics.npsScore != null && performance.metrics.npsScore > 0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getNPSColor(performance.metrics.npsScore).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getNPSColor(performance.metrics.npsScore).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sentiment_satisfied,
                          color: _getNPSColor(performance.metrics.npsScore),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'NPS Score: ${performance.metrics.npsScore.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _getNPSColor(performance.metrics.npsScore),
                          ),
                        ),
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

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
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
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  void _showServerDetails(ServerPerformanceData performance, String serverName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$serverName - Performance Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailSection('Overall Performance', [
                _buildDetailRow('Performance Score', '${performance.performanceScore.toStringAsFixed(1)}%'),
                _buildDetailRow('Rating', performance.rating.displayName),
                _buildDetailRow('Total Runs', '${performance.totalFoodRuns}'),
                _buildDetailRow('Shifts Worked', '${performance.shiftsWorked}'),
                _buildDetailRow('Days Employed', '${performance.daysEmployed}'),
              ]),
              const SizedBox(height: 16),
              _buildDetailSection('Efficiency Metrics', [
                _buildDetailRow('Runs per Shift', performance.shiftsWorked > 0 
                    ? '${(performance.totalFoodRuns / performance.shiftsWorked).toStringAsFixed(1)}'
                    : '0.0'),
                _buildDetailRow('Consistency Score', '${performance.metrics.consistencyScore.toStringAsFixed(1)}%'),
                _buildDetailRow('Experience Factor', '${(performance.metrics.experienceFactor * 100).toStringAsFixed(1)}%'),
              ]),
              if (performance.metrics.npsScore != null && performance.metrics.npsScore > 0) ...[
                const SizedBox(height: 16),
                _buildDetailSection('NPS Scores', [
                  _buildDetailRow('Current Month', '${performance.metrics.npsScore.toStringAsFixed(0)}%'),
                  _buildDetailRow('3-Month Average', '${performance.metrics.npsThreeMonth.toStringAsFixed(0)}%'),
                ]),
              ],
              const SizedBox(height: 16),
              _buildDetailSection('Financial Data', [
                _buildDetailRow('Total Sales', '\$${performance.totalSales.toStringAsFixed(2)}'),
                _buildDetailRow('Total Guests', '${performance.totalGuestCount.toStringAsFixed(0)}'),
                _buildDetailRow('Avg Check', performance.totalGuestCount > 0 
                    ? '\$${(performance.totalSales / performance.totalGuestCount).toStringAsFixed(2)}'
                    : '\$0.00'),
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _getServerName(String serverId) {
    return _serverNames[serverId] ?? 'Server $serverId';
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700); // Gold
    if (rank == 2) return const Color(0xFFC0C0C0); // Silver
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze
    if (rank <= 5) return Colors.green;
    if (rank <= 10) return Colors.blue;
    return Colors.grey;
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return const Color(0xFF1B5E20); // Dark Green
    if (score >= 80) return const Color(0xFF2E7D32); // Green
    if (score >= 70) return const Color(0xFF388E3C); // Light Green
    if (score >= 60) return const Color(0xFFF57C00); // Orange
    if (score >= 50) return const Color(0xFFFF9800); // Light Orange
    if (score >= 40) return const Color(0xFFD32F2F); // Red
    return const Color(0xFFB71C1C); // Dark Red
  }

  Color _getRatingColor(PerformanceRating rating) {
    switch (rating) {
      case PerformanceRating.elite:
        return const Color(0xFF1B5E20);
      case PerformanceRating.strong:
        return const Color(0xFF2E7D32);
      case PerformanceRating.developing:
        return const Color(0xFFF57C00);
      case PerformanceRating.needsAttention:
        return const Color(0xFFD32F2F);
      case PerformanceRating.critical:
        return const Color(0xFFB71C1C);
    }
  }

  Color _getNPSColor(double score) {
    if (score >= 80) return const Color(0xFF1B5E20);
    if (score >= 60) return const Color(0xFF2E7D32);
    if (score >= 40) return const Color(0xFFF57C00);
    return const Color(0xFFD32F2F);
  }

  // Helper methods for calculations
  double _calculateOverallPerformanceScore(UnifiedServerData server) {
    final efficiencyScore = server.shiftData.shiftsWorked > 0 
        ? (server.shiftData.totalRuns / server.shiftData.shiftsWorked * 20).clamp(0, 100)
        : 0.0;
    
    final consistencyScore = _calculateConsistencyScore(server);
    final npsScore = server.npsData.monthlyScore ?? 50.0;
    
    // Weighted average: 60% efficiency, 20% consistency, 20% NPS
    final overallScore = (efficiencyScore * 0.6) + (consistencyScore * 0.2) + (npsScore * 0.2);
    return overallScore.clamp(0.0, 100.0);
  }

  double _calculateConsistencyScore(UnifiedServerData server) {
    if (server.shiftData.shiftsWorked < 2) return 0.0;
    
    final avgRunsPerShift = server.shiftData.totalRuns / server.shiftData.shiftsWorked;
    final variance = server.shiftData.recentShifts.map((shift) {
      final runs = shift.counts[server.serverId] ?? 0;
      return (runs - avgRunsPerShift) * (runs - avgRunsPerShift);
    }).fold(0.0, (sum, v) => sum + v) / server.shiftData.shiftsWorked;
    
    final consistency = (100 - (variance / avgRunsPerShift * 10)).clamp(0.0, 100.0);
    return consistency;
  }

  PerformanceRating _getPerformanceRating(UnifiedServerData server) {
    if (server.shiftData.shiftsWorked == 0) return PerformanceRating.developing;
    
    final avgRunsPerShift = server.shiftData.totalRuns / server.shiftData.shiftsWorked;
    if (avgRunsPerShift >= 4.0) return PerformanceRating.elite;
    if (avgRunsPerShift >= 3.0) return PerformanceRating.strong;
    if (avgRunsPerShift >= 2.0) return PerformanceRating.developing;
    if (avgRunsPerShift >= 1.0) return PerformanceRating.needsAttention;
    return PerformanceRating.critical;
  }

  List<PerformanceFlag> _generatePerformanceFlags(UnifiedServerData server) {
    final flags = <PerformanceFlag>[];
    
    if (server.shiftData.shiftsWorked == 0) {
      flags.add(PerformanceFlag.coachingNeeded);
    }
    
    if (!server.npsData.hasActualData) {
      flags.add(PerformanceFlag.coachingNeeded);
    }
    
    if (server.shiftData.totalRuns == 0) {
      flags.add(PerformanceFlag.lowEfficiency);
    }
    
    if (server.daysEmployed < 30) {
      flags.add(PerformanceFlag.newHire);
    }
    
    if (server.shiftData.shiftsWorked >= 10) {
      flags.add(PerformanceFlag.teamLeader);
    }
    
    if (server.shiftData.shiftsWorked > 0) {
      final avgRunsPerShift = server.shiftData.totalRuns / server.shiftData.shiftsWorked;
      if (avgRunsPerShift >= 4.0) {
        flags.add(PerformanceFlag.highPerformer);
      }
    }
    
    return flags;
  }

  List<PerformanceInsight> _generatePerformanceInsights(UnifiedServerData server, String serverId) {
    final insights = <PerformanceInsight>[];
    
    if (server.shiftData.shiftsWorked > 0) {
      final avgRunsPerShift = server.shiftData.totalRuns / server.shiftData.shiftsWorked;
      insights.add(PerformanceInsight(
        type: 'recommendation',
        title: 'Performance Summary',
        description: 'Averages ${avgRunsPerShift.toStringAsFixed(1)} runs per shift',
        priority: 'medium',
        actionItems: [],
        generatedDate: DateTime.now(),
        serverId: serverId,
      ));
    }
    
    if (server.npsData.hasActualData && server.npsData.monthlyScore != null) {
      final npsScore = server.npsData.monthlyScore!;
      if (npsScore >= 80) {
        insights.add(PerformanceInsight(
          type: 'recognition',
          title: 'Excellent NPS Performance',
          description: 'NPS score: ${npsScore.toStringAsFixed(0)}% - Outstanding customer satisfaction!',
          priority: 'high',
          actionItems: ['Consider for recognition', 'Share best practices with team'],
          generatedDate: DateTime.now(),
          serverId: serverId,
        ));
      } else if (npsScore < 40) {
        insights.add(PerformanceInsight(
          type: 'alert',
          title: 'NPS Needs Improvement',
          description: 'NPS score: ${npsScore.toStringAsFixed(0)}% - Customer satisfaction below target',
          priority: 'high',
          actionItems: ['Schedule coaching session', 'Review customer feedback', 'Identify improvement areas'],
          generatedDate: DateTime.now(),
          serverId: serverId,
        ));
      }
    }
    
    return insights;
  }
}
