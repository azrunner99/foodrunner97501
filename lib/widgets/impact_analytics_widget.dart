import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nps_provider.dart';
import '../models/monthly_report.dart';
import '../storage/database_factory.dart';
import '../utils/log.dart';

/// Impact Analytics Widget
/// Displays Restaurant Impact Rankings and server performance impact analysis
class ImpactAnalyticsWidget extends StatefulWidget {
  const ImpactAnalyticsWidget({super.key});

  @override
  State<ImpactAnalyticsWidget> createState() => _ImpactAnalyticsWidgetState();
}

class _ImpactAnalyticsWidgetState extends State<ImpactAnalyticsWidget> {
  List<NPSMonthlyReport> _monthlyReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMonthlyReports();
  }

  Future<void> _loadMonthlyReports() async {
    try {
      d('[ImpactAnalyticsWidget] Starting to load monthly reports...');
      
      // Use the database factory to get the correct database instance
      final db = DatabaseFactory.instance;
      d('[ImpactAnalyticsWidget] Database factory type: ${DatabaseFactory.implementationType}');
      
      List<Map<String, dynamic>> reportMaps;
      
      // Handle different database schemas
      final dbType = DatabaseFactory.implementationType;
      d('[ImpactAnalyticsWidget] Detected database type: $dbType');
      
      if (dbType.contains('Sqflite')) {
        // Sqflite uses month_year column (YYYYMM format)
        d('[ImpactAnalyticsWidget] Using Sqflite schema with month_year column');
        reportMaps = await db.queryTable(
          'nps_monthly_reports',
          orderBy: 'month_year DESC',
        );
      } else {
        // Drift uses separate report_month and report_year columns
        d('[ImpactAnalyticsWidget] Using Drift schema with report_month and report_year columns');
        reportMaps = await db.queryTable(
        'nps_monthly_reports',
        orderBy: 'report_year DESC, report_month DESC',
      );
      }
      
      d('[ImpactAnalyticsWidget] Retrieved ${reportMaps.length} monthly reports from database');
      
      // Convert to NPSMonthlyReport objects
      final reports = reportMaps.map((map) => NPSMonthlyReport.fromMap(map)).toList();
      
      d('[ImpactAnalyticsWidget] Successfully loaded ${reports.length} monthly reports');
      
      setState(() {
        _monthlyReports = reports;
        _isLoading = false;
      });
    } catch (e) {
      d('[ImpactAnalyticsWidget] Error loading monthly reports: $e');
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
            // Restaurant Impact Rankings
            _buildServerRankings(_monthlyReports, context.read<NPSProvider>().servers),
          ],
        ),
      ),
    );
  }

  Widget _buildServerRankings(
      List<NPSMonthlyReport> monthlyReports, List<dynamic> servers) {
    // Group reports by server ID and aggregate their performance
    final Map<int, List<NPSMonthlyReport>> reportsByServer = {};
    for (final report in monthlyReports) {
      reportsByServer.putIfAbsent(report.serverId, () => []).add(report);
    }

    // Calculate aggregated performance scores for each server
    final serverScores = reportsByServer.entries.map((entry) {
      final serverId = entry.key;
      final serverReports = entry.value;
      return _calculateAggregatedServerPerformance(
          serverId, serverReports, monthlyReports);
    }).toList();

    // Sort by performance score (descending)
    serverScores.sort((a, b) => b['score'].compareTo(a['score']));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Colors.orange.shade600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Restaurant Impact Rankings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Who\'s helping vs hurting the restaurant - based on sales impact & most recent 3-month NPS performance',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (serverScores.isEmpty)
              const Center(
                child: Text(
                  'No monthly report data available',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...serverScores.take(5).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final scoreData = entry.value;
                final serverId = scoreData['serverId'] as int;
                final performanceScore = scoreData['score'] as double;
                final recentPerformance =
                    scoreData['recentPerformance'] as double;
                final historicalInsight =
                    scoreData['historicalInsight'] as String;
                final salesPercentage = scoreData['salesPercentage'] as double;
                final impactLevel = scoreData['impactLevel'] as String;
                final impactColor = scoreData['impactColor'] as Color;
                final simpleSummary = scoreData['simpleSummary'] as String;
                final trend = scoreData['trend'] as String;
                final trendIcon = scoreData['trendIcon'] as String;
                final improvementRate = scoreData['improvementRate'] as double;

                final medal = index == 0
                    ? '🥇'
                    : index == 1
                        ? '🥈'
                        : index == 2
                            ? '🥉'
                            : '${index + 1}';

                // Find corresponding server name - extract just the name
                final server = servers.cast<dynamic>().firstWhere(
                      (server) => server.id == serverId,
                      orElse: () => null,
                    );

                // Extract clean server name (just the name part)
                String serverName = 'Server $serverId';
                if (server != null) {
                  final serverStr = server.toString();
                  // Extract name from pattern like "NPSServer(id: 2, name: b, hireDate: ...)"
                  final nameMatch =
                      RegExp(r'name:\s*([^,]+)').firstMatch(serverStr);
                  if (nameMatch != null) {
                    serverName =
                        nameMatch.group(1)?.trim() ?? 'Server $serverId';
                  }
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade100,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 50,
                          child: Text(
                            medal,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Server name and primary impact indicator
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      serverName,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  // Simple impact indicator
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: impactColor,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      impactLevel,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Simple summary - dummy proof
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: impactColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: impactColor.withOpacity(0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      simpleSummary,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            impactColor.computeLuminance() > 0.5
                                                ? Colors.grey.shade800
                                                : impactColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        // Sales percentage - clear format
                                        Icon(
                                          Icons.pie_chart,
                                          size: 18,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${salesPercentage.toStringAsFixed(1)}% of restaurant sales',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        // Trend emoji icon
                                        Text(
                                          trendIcon,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${recentPerformance.toStringAsFixed(0)}% NPS',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: recentPerformance >= 80
                                                ? Colors.green.shade700
                                                : Colors.red.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Trend indicator badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getTrendBadgeColor(
                                                improvementRate),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            _getTrendLabel(improvementRate),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Clear benchmark context
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: recentPerformance >= 80
                                                ? Colors.green.withOpacity(0.1)
                                                : Colors.red.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: recentPerformance >= 80
                                                  ? Colors.green
                                                      .withOpacity(0.3)
                                                  : Colors.red.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Text(
                                            recentPerformance >= 80
                                                ? 'Above 80% target'
                                                : 'Below 80% target',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: recentPerformance >= 80
                                                  ? Colors.green.shade700
                                                  : Colors.red.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Historical insight (simplified)
                              Text(
                                historicalInsight,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Simple score indicator with restaurant impact
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: impactColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: impactColor,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    performanceScore.toStringAsFixed(0),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: impactColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Impact Score',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: impactColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ], // Closing bracket for Row children
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  /// Calculate aggregated performance for a server across all their monthly reports
  Map<String, dynamic> _calculateAggregatedServerPerformance(int serverId,
      List<NPSMonthlyReport> serverReports, List<NPSMonthlyReport> allReports) {
    if (serverReports.isEmpty) {
      return {
        'serverId': serverId,
        'score': 0.0,
        'trend': 'No Data',
        'trendIcon': '❓',
        'performanceLevel': 'No Data',
        'performanceColor': Colors.grey,
        'benchmarkGap': -80.0,
        'recentPerformance': 0.0,
        'overallPerformance': 0.0,
        'monthsReporting': 0,
        'consistencyScore': 0.0,
        'improvementRate': 0.0,
        'historicalInsight': 'No historical data available',
        'performanceHistory': <double>[],
        'monthNames': <String>[],
        'salesPercentage': 0.0,
        'restaurantImpact': 'No Impact',
        'impactLevel': 'None',
        'impactColor': Colors.grey,
        'simpleSummary': 'No data available',
      };
    }

    // Sort reports by month to get chronological order
    serverReports.sort((a, b) => a.reportMonth.compareTo(b.reportMonth));

    // Extract all available performance data with month tracking
    final List<double> performanceHistory = [];
    final List<String> monthNames = [];

    for (final report in serverReports) {
      final performance =
          report.threeMonthNpsPercentage ?? report.oneMonthNpsPercentage ?? report.allTimeNpsPercentage ?? 0.0;
      performanceHistory.add(performance);

      // Extract month name from YYYYMM format
      final month = report.reportMonth % 100;
      monthNames.add(_getMonthName(month));
    }

    // Calculate aggregated performance metrics
    final recentPerformance =
        performanceHistory.isNotEmpty ? performanceHistory.last : 0.0;
    final overallPerformance = performanceHistory.isNotEmpty
        ? performanceHistory.reduce((a, b) => a + b) / performanceHistory.length
        : 0.0;

    // Calculate consistency score (lower standard deviation = more consistent)
    double consistencyScore = 0.0;
    if (performanceHistory.length > 1) {
      final mean = overallPerformance;
      final variance = performanceHistory
              .map((x) => (x - mean) * (x - mean))
              .reduce((a, b) => a + b) /
          performanceHistory.length;
      final standardDeviation =
          variance > 0 ? (variance).abs() : 0.0; // Simplified sqrt
      consistencyScore = 100.0 -
          (standardDeviation > 20
              ? 20
              : standardDeviation); // Max penalty of 20 points
    }

    // Calculate improvement rate
    double improvementRate = 0.0;
    if (performanceHistory.length >= 2) {
      final firstPerformance = performanceHistory.first;
      final lastPerformance = performanceHistory.last;
      improvementRate = lastPerformance - firstPerformance;
    }

    // Generate historical insight
    String historicalInsight = _generateHistoricalInsight(performanceHistory,
        monthNames, consistencyScore, improvementRate, overallPerformance);

    // Calculate sales percentage and restaurant impact
    final totalRestaurantSales = allReports
        .map((r) => r.allTimeSales)
        .fold(0.0, (sum, sales) => sum + sales);

    final serverTotalSales = serverReports
        .map((r) => r.allTimeSales)
        .fold(0.0, (sum, sales) => sum + sales);

    final salesPercentage = totalRestaurantSales > 0
        ? (serverTotalSales / totalRestaurantSales) * 100
        : 0.0;

    // Calculate restaurant impact (simple and clear)
    String restaurantImpact;
    String impactLevel;
    Color impactColor;
    String simpleSummary;

    // Calculate trend description for admin insights
    String trendDescription = "";
    if (performanceHistory.length >= 2) {
      if (improvementRate > 5.0) {
        trendDescription =
            " and improving significantly (+${improvementRate.toStringAsFixed(1)}%)";
      } else if (improvementRate > 2.0) {
        trendDescription =
            " and trending upward (+${improvementRate.toStringAsFixed(1)}%)";
      } else if (improvementRate >= -2.0) {
        trendDescription = " and performance is stable";
      } else if (improvementRate < -5.0) {
        trendDescription =
            " and declining significantly (${improvementRate.toStringAsFixed(1)}%)";
      } else {
        trendDescription =
            " and trending downward (${improvementRate.toStringAsFixed(1)}%)";
      }
    }

    if (salesPercentage < 5.0) {
      // Low sales impact
      if (recentPerformance >= 80) {
        restaurantImpact = 'Minor Boost';
        impactLevel = 'Good';
        impactColor = Colors.green.shade300;
        simpleSummary =
            'Good performance but low sales impact$trendDescription';
      } else {
        restaurantImpact = 'Minor Drag';
        impactLevel = 'Bad';
        impactColor = Colors.orange.shade300;
        simpleSummary = 'Below standard but low sales impact$trendDescription';
      }
    } else if (salesPercentage < 15.0) {
      // Medium sales impact
      if (recentPerformance >= 85) {
        restaurantImpact = 'Restaurant Booster';
        impactLevel = 'Excellent';
        impactColor = Colors.green.shade600;
        simpleSummary = 'HELPING the restaurant succeed$trendDescription';
      } else if (recentPerformance >= 80) {
        restaurantImpact = 'Above Standard';
        impactLevel = 'Good';
        impactColor = Colors.green.shade400;
        simpleSummary = 'Meeting our 80% standard$trendDescription';
      } else if (recentPerformance >= 70) {
        restaurantImpact = 'Below Standard';
        impactLevel = 'Okay';
        impactColor = Colors.yellow.shade600;
        simpleSummary = 'Below our 80% standard$trendDescription';
      } else {
        restaurantImpact = 'Restaurant Drag';
        impactLevel = 'Problem';
        impactColor = Colors.red.shade500;
        simpleSummary = 'HURTING the restaurant$trendDescription';
      }
    } else {
      // High sales impact
      if (recentPerformance >= 85) {
        restaurantImpact = 'STAR PERFORMER';
        impactLevel = 'Superstar';
        impactColor = Colors.green.shade800;
        simpleSummary =
            'MAJOR restaurant booster - keep this server!$trendDescription';
      } else if (recentPerformance >= 80) {
        restaurantImpact = 'High Volume Above Standard';
        impactLevel = 'Excellent';
        impactColor = Colors.green.shade600;
        simpleSummary =
            'High sales and meeting our 80% standard$trendDescription';
      } else if (recentPerformance >= 70) {
        restaurantImpact = 'High Volume Below Standard';
        impactLevel = 'Concerning';
        impactColor = Colors.orange.shade600;
        simpleSummary =
            'High sales but below our 80% standard - needs improvement$trendDescription';
      } else {
        restaurantImpact = 'RESTAURANT KILLER';
        impactLevel = 'Crisis';
        impactColor = Colors.red.shade800;
        simpleSummary =
            'MAJOR problem - high sales but terrible NPS!$trendDescription';
      }
    }

    const double performanceBenchmark = 80.0;

    // Calculate performance level relative to 80% benchmark
    String performanceLevel;
    Color performanceColor;
    double performanceMultiplier;

    if (recentPerformance >= 90.0) {
      performanceLevel = 'Exceptional';
      performanceColor = Colors.green.shade700;
      performanceMultiplier = 1.25;
    } else if (recentPerformance >= performanceBenchmark) {
      performanceLevel = 'Above Standard';
      performanceColor = Colors.green;
      performanceMultiplier = 1.1;
    } else if (recentPerformance >= 70.0) {
      performanceLevel = 'Below Standard';
      performanceColor = Colors.orange;
      performanceMultiplier = 0.9;
    } else if (recentPerformance >= 50.0) {
      performanceLevel = 'Needs Improvement';
      performanceColor = Colors.red;
      performanceMultiplier = 0.7;
    } else {
      performanceLevel = 'Critical';
      performanceColor = Colors.red.shade700;
      performanceMultiplier = 0.5;
    }

    // Calculate trend across all reports
    String trend;
    String trendIcon;
    double trendMultiplier;

    if (serverReports.length >= 2) {
      if (improvementRate > 5.0 && recentPerformance >= performanceBenchmark) {
        trend = 'Strong Improvement';
        trendIcon = '🚀';
        trendMultiplier = 1.2;
      } else if (improvementRate > 2.0) {
        trend = 'Improving';
        trendIcon = '📈';
        trendMultiplier = 1.15;
      } else if (improvementRate >= -2.0 &&
          recentPerformance >= performanceBenchmark) {
        trend = 'Stable Above Standard';
        trendIcon = '✅';
        trendMultiplier = 1.1;
      } else if (improvementRate >= -2.0) {
        trend = 'Stable';
        trendIcon = '➡️';
        trendMultiplier = 1.0;
      } else if (improvementRate < -5.0) {
        trend = 'Declining';
        trendIcon = '📉';
        trendMultiplier = 0.8;
      } else {
        trend = 'Slight Decline';
        trendIcon = '⬇️';
        trendMultiplier = 0.9;
      }
    } else {
      // Single report - assess based on performance level
      if (recentPerformance >= performanceBenchmark) {
        trend = 'Above Standard';
        trendIcon = '✅';
        trendMultiplier = 1.0;
      } else {
        trend = 'Below Standard';
        trendIcon = '⚠️';
        trendMultiplier = 0.8;
      }
    }

    // Calculate final score with sales impact weighting
    double baseScore = recentPerformance;

    // Sales impact multiplier (higher sales = higher impact on restaurant)
    double salesImpactMultiplier = 1.0 +
        (salesPercentage / 100.0); // Each 1% of sales adds 1% to multiplier

    // Bonus for meeting/exceeding 80% benchmark
    double benchmarkBonus = 1.0;
    if (recentPerformance >= performanceBenchmark) {
      benchmarkBonus = 1.0 +
          ((recentPerformance - performanceBenchmark) /
              200.0); // Moderate bonus
    } else {
      benchmarkBonus = recentPerformance /
          performanceBenchmark; // Penalty for below standard
    }

    // Consistency bonus (reward consistent performers)
    double consistencyBonus =
        1.0 + (consistencyScore / 1000.0); // Small bonus for consistency

    // Restaurant impact modifier - amplifies or reduces based on actual business impact
    double restaurantImpactModifier = 1.0;
    if (salesPercentage >= 15.0) {
      // High sales servers get amplified scores (good or bad)
      restaurantImpactModifier = recentPerformance >= 70
          ? 1.3
          : 0.7; // Major boost for good, penalty for bad
    } else if (salesPercentage >= 5.0) {
      // Medium sales servers get moderate adjustment
      restaurantImpactModifier = recentPerformance >= 80 ? 1.15 : 0.9;
    }

    // Apply all multipliers
    final finalScore = baseScore *
        trendMultiplier *
        performanceMultiplier *
        benchmarkBonus *
        consistencyBonus *
        salesImpactMultiplier *
        restaurantImpactModifier;

    return {
      'serverId': serverId,
      'score': finalScore,
      'trend': trend,
      'trendIcon': trendIcon,
      'performanceLevel': performanceLevel,
      'performanceColor': performanceColor,
      'benchmarkGap': recentPerformance - performanceBenchmark,
      'recentPerformance': recentPerformance,
      'overallPerformance': overallPerformance,
      'monthsReporting': serverReports.length,
      'consistencyScore': consistencyScore,
      'improvementRate': improvementRate,
      'historicalInsight': historicalInsight,
      'performanceHistory': performanceHistory,
      'monthNames': monthNames,
      'salesPercentage': salesPercentage,
      'restaurantImpact': restaurantImpact,
      'impactLevel': impactLevel,
      'impactColor': impactColor,
      'simpleSummary': simpleSummary,
    };
  }

  /// Generate historical insight based on performance data
  String _generateHistoricalInsight(
    List<double> performanceHistory,
    List<String> monthNames,
    double consistencyScore,
    double improvementRate,
    double averagePerformance,
  ) {
    if (performanceHistory.isEmpty) return 'No data available';
    if (performanceHistory.length == 1) return 'Single month reporting';

    final monthCount = performanceHistory.length;
    final months = monthNames.join(', ');

    // Analyze patterns
    if (consistencyScore > 90 && averagePerformance >= 80) {
      return 'Consistently excellent performer across $monthCount months ($months)';
    } else if (consistencyScore > 85) {
      return 'Very reliable performer with minimal variation ($months)';
    } else if (improvementRate > 10) {
      return 'Dramatic improvement trend: +${improvementRate.toStringAsFixed(1)}% since $months';
    } else if (improvementRate > 5) {
      return 'Strong upward trajectory over $monthCount months ($months)';
    } else if (improvementRate < -10) {
      return 'Concerning decline: ${improvementRate.toStringAsFixed(1)}% drop since $months';
    } else if (improvementRate < -5) {
      return 'Performance has declined over $monthCount months ($months)';
    } else if (consistencyScore < 70) {
      return 'Inconsistent performance across $monthCount months - needs attention';
    } else {
      return 'Stable performance over $monthCount months ($months)';
    }
  }

  String _getMonthName(int month) {
    const monthNames = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return monthNames[month];
  }

  /// Get trend badge color based on improvement rate
  Color _getTrendBadgeColor(double improvementRate) {
    if (improvementRate > 5.0) {
      return Colors.green.shade600; // Strong improvement
    } else if (improvementRate > 2.0) {
      return Colors.green.shade400; // Improving
    } else if (improvementRate >= -2.0) {
      return Colors.blue.shade400; // Stable
    } else if (improvementRate < -5.0) {
      return Colors.red.shade600; // Declining
    } else {
      return Colors.orange.shade500; // Slight decline
    }
  }

  /// Get trend label based on improvement rate
  String _getTrendLabel(double improvementRate) {
    if (improvementRate > 5.0) {
      return 'Rising';
    } else if (improvementRate > 2.0) {
      return 'Up';
    } else if (improvementRate >= -2.0) {
      return 'Stable';
    } else if (improvementRate < -5.0) {
      return 'Falling';
    } else {
      return 'Down';
    }
  }
}
