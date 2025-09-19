import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/performance_models.dart';
import '../utils/trend_analyzer.dart';

/// Performance visualization widgets using fl_chart
class PerformanceChartWidgets {
  /// Performance trend line chart with rolling averages
  static Widget performanceTrendChart({
    required PerformanceTrendAnalysis trendAnalysis,
    required BuildContext context,
    double? height,
  }) {
    return Container(
      height: height ?? 300,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 20,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return const FlLine(
                color: Colors.grey,
                strokeWidth: 0.5,
              );
            },
            getDrawingVerticalLine: (value) {
              return const FlLine(
                color: Colors.grey,
                strokeWidth: 0.5,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 5,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 &&
                      value.toInt() < trendAnalysis.dailyTrends.length) {
                    final date = trendAnalysis.dailyTrends[value.toInt()].date;
                    return Text(
                      '${date.month}/${date.day}',
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  );
                },
                reservedSize: 42,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xff37434d)),
          ),
          minX: 0,
          maxX: trendAnalysis.dailyTrends.length.toDouble() - 1,
          minY: 0,
          maxY: _getMaxScore(trendAnalysis.dailyTrends),
          lineBarsData: [
            // Daily performance line
            LineChartBarData(
              spots: trendAnalysis.dailyTrends
                  .asMap()
                  .entries
                  .map((entry) =>
                      FlSpot(entry.key.toDouble(), entry.value.score))
                  .toList(),
              isCurved: true,
              gradient: LinearGradient(
                colors: [
                  _getTrendColor(trendAnalysis.trendDirection),
                  _getTrendColor(trendAnalysis.trendDirection).withOpacity(0.3),
                ],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    _getTrendColor(trendAnalysis.trendDirection)
                        .withOpacity(0.1),
                    _getTrendColor(trendAnalysis.trendDirection)
                        .withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // 7-day rolling average
            if (trendAnalysis.rollingAverages.sevenDay.isNotEmpty)
              LineChartBarData(
                spots: trendAnalysis.rollingAverages.sevenDay
                    .asMap()
                    .entries
                    .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
                    .toList(),
                isCurved: true,
                color: Colors.orange,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                dashArray: [5, 5],
              ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final flSpot = barSpot;
                  if (flSpot.x.toInt() < trendAnalysis.dailyTrends.length) {
                    final trend = trendAnalysis.dailyTrends[flSpot.x.toInt()];
                    return LineTooltipItem(
                      '${trend.date.month}/${trend.date.day}\nScore: ${flSpot.y.toStringAsFixed(1)}\nRuns: ${trend.totalRuns}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                  return null;
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Performance distribution pie chart
  static Widget performanceDistributionChart({
    required Map<PerformanceRating, int> distribution,
    required BuildContext context,
    double? size,
  }) {
    return SizedBox(
      width: size ?? 200,
      height: size ?? 200,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              // Handle touch events if needed
            },
          ),
          borderData: FlBorderData(show: false),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: _buildPieChartSections(distribution),
        ),
      ),
    );
  }

  /// Performance comparison bar chart
  static Widget performanceComparisonChart({
    required Map<String, double> performanceData,
    required String currentServerId,
    required BuildContext context,
    double? height,
  }) {
    return Container(
      height: height ?? 300,
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxValue(performanceData.values.toList()) * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final serverName = performanceData.keys.elementAt(groupIndex);
                final score = rod.toY;
                return BarTooltipItem(
                  '$serverName\nScore: ${score.toStringAsFixed(1)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value.toInt() < performanceData.length) {
                    final serverName =
                        performanceData.keys.elementAt(value.toInt());
                    final isCurrentServer = serverName == currentServerId;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        serverName.length > 10
                            ? '${serverName.substring(0, 8)}...'
                            : serverName,
                        style: TextStyle(
                          color: isCurrentServer
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                          fontSize: 10,
                          fontWeight: isCurrentServer
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 32,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  );
                },
                reservedSize: 40,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: performanceData.entries
              .map((entry) => entry.key)
              .toList()
              .asMap()
              .entries
              .map((entry) {
            final index = entry.key;
            final serverName = entry.value;
            final score = performanceData[serverName]!;
            final isCurrentServer = serverName == currentServerId;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: score,
                  color: isCurrentServer
                      ? Theme.of(context).primaryColor
                      : _getPerformanceColor(score),
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: _getMaxValue(performanceData.values.toList()) * 1.2,
                    color: Colors.grey.withOpacity(0.1),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Weekly performance pattern radar chart
  static Widget weeklyPatternChart({
    required Map<int, double> dayOfWeekPatterns,
    required BuildContext context,
    double? size,
  }) {
    return SizedBox(
      width: size ?? 250,
      height: size ?? 250,
      child: RadarChart(
        RadarChartData(
          radarBackgroundColor: Colors.transparent,
          radarBorderData: const BorderSide(color: Colors.grey, width: 1),
          titlePositionPercentageOffset: 0.2,
          titleTextStyle: const TextStyle(color: Colors.grey, fontSize: 10),
          getTitle: (index, angle) {
            final dayNames = [
              '',
              'Mon',
              'Tue',
              'Wed',
              'Thu',
              'Fri',
              'Sat',
              'Sun'
            ];
            final dayIndex = index + 1;
            if (dayIndex < dayNames.length) {
              return RadarChartTitle(text: dayNames[dayIndex]);
            }
            return const RadarChartTitle(text: '');
          },
          dataSets: [
            RadarDataSet(
              fillColor: Theme.of(context).primaryColor.withOpacity(0.2),
              borderColor: Theme.of(context).primaryColor,
              entryRadius: 3,
              dataEntries: _buildRadarDataEntries(dayOfWeekPatterns),
            ),
          ],
          tickCount: 5,
          ticksTextStyle: const TextStyle(color: Colors.grey, fontSize: 8),
          tickBorderData: const BorderSide(color: Colors.grey, width: 1),
          gridBorderData: const BorderSide(color: Colors.grey, width: 1),
        ),
      ),
    );
  }

  /// Performance velocity indicator
  static Widget performanceVelocityIndicator({
    required PerformanceVelocity velocity,
    required BuildContext context,
  }) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildVelocityGauge(
              title: 'Short Term',
              value: velocity.shortTermVelocity,
              maxValue: 5.0,
              color: _getVelocityColor(velocity.shortTermVelocity),
              context: context,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildVelocityGauge(
              title: 'Long Term',
              value: velocity.longTermVelocity,
              maxValue: 2.0,
              color: _getVelocityColor(velocity.longTermVelocity),
              context: context,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildVelocityGauge(
              title: 'Acceleration',
              value: velocity.acceleration,
              maxValue: 2.0,
              color: _getVelocityColor(velocity.acceleration),
              context: context,
            ),
          ),
        ],
      ),
    );
  }

  /// Monthly performance heatmap
  static Widget monthlyPerformanceHeatmap({
    required Map<String, double> monthlyData,
    required BuildContext context,
    double? height,
  }) {
    return Container(
      height: height ?? 150,
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          childAspectRatio: 2,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: monthlyData.length,
        itemBuilder: (context, index) {
          final entry = monthlyData.entries.elementAt(index);
          final intensity =
              _normalizeValue(entry.value, monthlyData.values.toList());

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(intensity),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(
                        fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    entry.value.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper methods

  static double _getMaxScore(List<DailyTrend> trends) {
    if (trends.isEmpty) return 100;
    return trends.map((t) => t.score).reduce((a, b) => a > b ? a : b) * 1.1;
  }

  static double _getMaxValue(List<double> values) {
    if (values.isEmpty) return 100;
    return values.reduce((a, b) => a > b ? a : b);
  }

  static Color _getTrendColor(TrendDirection direction) {
    switch (direction) {
      case TrendDirection.improving:
        return Colors.green;
      case TrendDirection.declining:
        return Colors.red;
      case TrendDirection.stable:
        return Colors.blue;
    }
  }

  static Color _getPerformanceColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.lightGreen;
    if (score >= 60) return Colors.orange;
    if (score >= 45) return Colors.deepOrange;
    return Colors.red;
  }

  static Color _getVelocityColor(double velocity) {
    if (velocity > 1.0) return Colors.green;
    if (velocity > 0.5) return Colors.lightGreen;
    if (velocity > -0.5) return Colors.grey;
    if (velocity > -1.0) return Colors.orange;
    return Colors.red;
  }

  static List<PieChartSectionData> _buildPieChartSections(
      Map<PerformanceRating, int> distribution) {
    final total = distribution.values.fold<int>(0, (sum, count) => sum + count);
    if (total == 0) return [];

    final colors = {
      PerformanceRating.elite: Colors.green,
      PerformanceRating.strong: Colors.lightGreen,
      PerformanceRating.developing: Colors.orange,
      PerformanceRating.needsAttention: Colors.deepOrange,
      PerformanceRating.critical: Colors.red,
    };

    return distribution.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      return PieChartSectionData(
        color: colors[entry.key] ?? Colors.grey,
        value: percentage,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  static List<RadarEntry> _buildRadarDataEntries(
      Map<int, double> dayOfWeekPatterns) {
    final entries = <RadarEntry>[];
    for (int day = 1; day <= 7; day++) {
      final value = dayOfWeekPatterns[day] ?? 0.0;
      entries.add(RadarEntry(value: value));
    }
    return entries;
  }

  static Widget _buildVelocityGauge({
    required String title,
    required double value,
    required double maxValue,
    required Color color,
    required BuildContext context,
  }) {
    final normalizedValue = (value.abs() / maxValue).clamp(0.0, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          width: 60,
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey.withOpacity(0.3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: normalizedValue,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.toStringAsFixed(2),
          style: const TextStyle(fontSize: 8),
        ),
      ],
    );
  }

  static double _normalizeValue(double value, List<double> allValues) {
    if (allValues.isEmpty) return 0.0;
    final minValue = allValues.reduce((a, b) => a < b ? a : b);
    final maxValue = allValues.reduce((a, b) => a > b ? a : b);
    if (maxValue == minValue) return 0.5;
    return (value - minValue) / (maxValue - minValue);
  }
}

/// Performance insights widget with statistical summaries
class PerformanceInsightsWidget extends StatelessWidget {
  final PerformanceTrendAnalysis trendAnalysis;
  final SeasonalAnalysis? seasonalAnalysis;

  const PerformanceInsightsWidget({
    super.key,
    required this.trendAnalysis,
    this.seasonalAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Insights',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildTrendSummary(context),
            const SizedBox(height: 12),
            if (trendAnalysis.patterns.anomalies.isNotEmpty) ...[
              _buildAnomalies(context),
              const SizedBox(height: 12),
            ],
            _buildPredictions(context),
            if (seasonalAnalysis != null) ...[
              const SizedBox(height: 12),
              _buildSeasonalInsights(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrendSummary(BuildContext context) {
    final direction = trendAnalysis.trendDirection;
    final momentum = trendAnalysis.momentum;
    final confidence = trendAnalysis.confidence;

    return Row(
      children: [
        Icon(
          _getTrendIcon(direction),
          color: _getTrendColor(direction),
          size: 24,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trend: ${_getTrendDescription(direction, momentum)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Confidence: ${(confidence * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnomalies(BuildContext context) {
    final anomalies = trendAnalysis.patterns.anomalies;
    final recentAnomalies = anomalies.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Anomalies:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        ...recentAnomalies.map((anomaly) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '${anomaly.date.month}/${anomaly.date.day}: ${_getAnomalyDescription(anomaly)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildPredictions(BuildContext context) {
    final predictions = trendAnalysis.predictions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Predictions:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Next week: ${predictions.nextWeek.toStringAsFixed(1)} points',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        Text(
          'Next month: ${predictions.nextMonth.toStringAsFixed(1)} points',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildSeasonalInsights(BuildContext context) {
    final seasonal = seasonalAnalysis!;
    final bestDay = seasonal.dayOfWeekPatterns.entries
        .reduce((a, b) => a.value > b.value ? a : b);

    final dayNames = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seasonal Patterns:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Best day: ${dayNames[bestDay.key]} (${bestDay.value.toStringAsFixed(1)} avg)',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        Text(
          'Peak month: ${seasonal.performancePeaks.bestMonth}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  IconData _getTrendIcon(TrendDirection direction) {
    switch (direction) {
      case TrendDirection.improving:
        return Icons.trending_up;
      case TrendDirection.declining:
        return Icons.trending_down;
      case TrendDirection.stable:
        return Icons.trending_flat;
    }
  }

  Color _getTrendColor(TrendDirection direction) {
    switch (direction) {
      case TrendDirection.improving:
        return Colors.green;
      case TrendDirection.declining:
        return Colors.red;
      case TrendDirection.stable:
        return Colors.blue;
    }
  }

  String _getTrendDescription(
      TrendDirection direction, TrendMomentum momentum) {
    final directionText = direction.name
        .replaceFirst(direction.name[0], direction.name[0].toUpperCase());
    final momentumText = momentum.name
        .replaceFirst(momentum.name[0], momentum.name[0].toUpperCase());
    return '$directionText ($momentumText momentum)';
  }

  String _getAnomalyDescription(AnomalyPoint anomaly) {
    final typeText = anomaly.type == AnomalyType.unusuallyHigh ? 'High' : 'Low';
    return '$typeText performance (${anomaly.score.toStringAsFixed(1)})';
  }
}
