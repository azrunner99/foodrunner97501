import 'dart:math' as math;
import '../models/historical_nps_data.dart';
import '../models/monthly_report.dart' hide PerformanceTrend;
import '../storage/database_factory.dart';
import '../utils/log.dart';

/// Service for aggregating and analyzing historical NPS data
class HistoricalNPSAggregationService {
  static final HistoricalNPSAggregationService _instance = HistoricalNPSAggregationService._internal();
  factory HistoricalNPSAggregationService() => _instance;
  HistoricalNPSAggregationService._internal();

  static HistoricalNPSAggregationService get instance => _instance;

  late dynamic _database;

  Future<void> initialize() async {
    _database = DatabaseFactory.instance;
    d('[HistoricalNPSAggregationService] Initialized');
  }

  /// Load historical NPS data for a specific server
  Future<HistoricalNPSData?> getHistoricalDataForServer(String serverId) async {
    try {
      d('[HistoricalNPSAggregationService] Loading historical data for server: $serverId');
      
      // Get all monthly reports for this server
      final monthlyReports = await _getMonthlyReportsForServer(serverId);
      if (monthlyReports.isEmpty) {
        d('[HistoricalNPSAggregationService] No monthly reports found for server: $serverId');
        return null;
      }

      // Get server name
      final serverName = await _getServerName(serverId);
      
      // Convert monthly reports to MonthlyPerformance objects
      final monthlyData = monthlyReports.map((report) => _convertToMonthlyPerformance(report)).toList();
      
      // Sort by month (most recent first)
      monthlyData.sort((a, b) => b.month.compareTo(a.month));
      
      // Calculate trend analysis
      final trend = _calculatePerformanceTrend(monthlyData);
      
      // Calculate volatility
      final volatility = _calculateVolatility(monthlyData);
      
      // Detect seasonal patterns
      final seasonalPattern = _detectSeasonalPattern(monthlyData);
      
      // Classify performance
      final classification = _classifyPerformance(monthlyData, trend, volatility);
      
      final historicalData = HistoricalNPSData(
        serverId: serverId,
        serverName: serverName,
        monthlyData: monthlyData,
        trend: trend,
        volatility: volatility,
        seasonalPattern: seasonalPattern,
        classification: classification,
        lastUpdated: DateTime.now(),
        totalMonthsReported: monthlyData.length,
      );

      d('[HistoricalNPSAggregationService] Loaded ${monthlyData.length} months of data for server: $serverName');
      return historicalData;
    } catch (e) {
      d('[HistoricalNPSAggregationService] Error loading historical data for server $serverId: $e');
      return null;
    }
  }

  /// Load historical NPS data for all servers
  Future<List<HistoricalNPSData>> getAllHistoricalData() async {
    try {
      d('[HistoricalNPSAggregationService] Loading historical data for all servers');
      
      // Get all servers
      final servers = await _database.queryTable('servers', where: 'active = ?', whereArgs: [1]);
      
      final List<HistoricalNPSData> allHistoricalData = [];
      
      for (final server in servers) {
        final serverId = server['id'].toString();
        final historicalData = await getHistoricalDataForServer(serverId);
        if (historicalData != null) {
          allHistoricalData.add(historicalData);
        }
      }
      
      d('[HistoricalNPSAggregationService] Loaded historical data for ${allHistoricalData.length} servers');
      return allHistoricalData;
    } catch (e) {
      d('[HistoricalNPSAggregationService] Error loading all historical data: $e');
      return [];
    }
  }

  /// Get monthly reports for a specific server
  Future<List<Map<String, dynamic>>> _getMonthlyReportsForServer(String serverId) async {
    try {
      // Handle different database schemas
      if (DatabaseFactory.implementationType.contains('Sqflite')) {
        // Sqflite uses month_year column
        return await _database.queryTable(
          'nps_monthly_reports',
          where: 'server_id = ?',
          whereArgs: [int.parse(serverId)],
          orderBy: 'month_year DESC',
        );
      } else {
        // Drift uses separate report_month and report_year columns
        return await _database.queryTable(
          'nps_monthly_reports',
          where: 'server_id = ?',
          whereArgs: [int.parse(serverId)],
          orderBy: 'report_year DESC, report_month DESC',
        );
      }
    } catch (e) {
      d('[HistoricalNPSAggregationService] Error getting monthly reports for server $serverId: $e');
      return [];
    }
  }

  /// Get server name by ID
  Future<String> _getServerName(String serverId) async {
    try {
      final server = await _database.queryTable(
        'servers',
        where: 'id = ?',
        whereArgs: [int.parse(serverId)],
        limit: 1,
      );
      
      if (server.isNotEmpty) {
        return server.first['name'] as String;
      }
      
      return 'Unknown Server';
    } catch (e) {
      d('[HistoricalNPSAggregationService] Error getting server name for ID $serverId: $e');
      return 'Unknown Server';
    }
  }

  /// Convert monthly report to MonthlyPerformance
  MonthlyPerformance _convertToMonthlyPerformance(Map<String, dynamic> report) {
    // Handle different database schemas for month extraction
    DateTime month;
    if (DatabaseFactory.implementationType.contains('Sqflite')) {
      // Sqflite uses month_year in YYYYMM format
      final monthYear = report['month_year'] as String;
      final year = int.parse(monthYear.substring(0, 4));
      final monthNum = int.parse(monthYear.substring(4, 6));
      month = DateTime(year, monthNum, 1);
    } else {
      // Drift uses separate report_month and report_year
      final year = report['report_year'] as int;
      final monthNum = report['report_month'] as int;
      month = DateTime(year, monthNum, 1);
    }

    return MonthlyPerformance(
      month: month,
      oneMonthNPS: (report['one_month_nps_percentage'] as num?)?.toDouble() ?? 0.0,
      threeMonthNPS: (report['three_month_nps_percentage'] as num?)?.toDouble() ?? 0.0,
      allTimeNPS: (report['all_time_nps_percentage'] as num?)?.toDouble() ?? 0.0,
      responseCount: (report['month_feedback_yes'] as int? ?? 0) + 
                    (report['month_feedback_maybe'] as int? ?? 0) + 
                    (report['month_feedback_no'] as int? ?? 0),
      context: PerformanceContext(
        isNewHire: false, // TODO: Implement based on hire date
        isTrainingPeriod: false, // TODO: Implement based on business logic
        isSeasonalPeak: _isSeasonalPeak(month.month),
        isSeasonalLow: _isSeasonalLow(month.month),
        notes: '',
      ),
      sales: (report['all_time_sales'] as num?)?.toDouble() ?? 0.0,
      tableCount: report['all_time_table_count'] as int? ?? 0,
    );
  }

  /// Calculate performance trend from monthly data
  PerformanceTrend _calculatePerformanceTrend(List<MonthlyPerformance> monthlyData) {
    if (monthlyData.length < 2) {
      return PerformanceTrend(
        direction: TrendDirection.stable,
        slope: 0.0,
        strength: 0.0,
        volatility: 0.0,
        movingAverages: [],
        description: 'Insufficient data for trend analysis',
      );
    }

    final scores = monthlyData.map((m) => m.oneMonthNPS).toList();
    final n = scores.length;
    
    // Calculate linear regression slope
    final xValues = List.generate(n, (i) => i.toDouble());
    final yValues = scores;
    
    final xMean = xValues.reduce((a, b) => a + b) / n;
    final yMean = yValues.reduce((a, b) => a + b) / n;
    
    double numerator = 0.0;
    double denominator = 0.0;
    
    for (int i = 0; i < n; i++) {
      final xDiff = xValues[i] - xMean;
      final yDiff = yValues[i] - yMean;
      numerator += xDiff * yDiff;
      denominator += xDiff * xDiff;
    }
    
    final slope = denominator > 0 ? numerator / denominator : 0.0;
    
    // Calculate trend strength (R-squared)
    double strength = 0.0;
    if (denominator > 0) {
      double yVariance = 0.0;
      for (int i = 0; i < n; i++) {
        final yDiff = yValues[i] - yMean;
        yVariance += yDiff * yDiff;
      }
      strength = (numerator * numerator) / (denominator * yVariance);
    }
    
    // Calculate volatility (standard deviation)
    final volatility = _calculateVolatility(monthlyData);
    
    // Determine trend direction
    TrendDirection direction;
    if (slope > 1.0 && strength > 0.5) {
      direction = TrendDirection.improving;
    } else if (slope < -1.0 && strength > 0.5) {
      direction = TrendDirection.declining;
    } else if (volatility > 15.0) {
      direction = TrendDirection.volatile;
    } else {
      direction = TrendDirection.stable;
    }
    
    // Calculate moving averages (3-month)
    final movingAverages = _calculateMovingAverages(scores, 3);
    
    // Generate description
    final description = _generateTrendDescription(direction, slope, strength, volatility);
    
    return PerformanceTrend(
      direction: direction,
      slope: slope,
      strength: strength,
      volatility: volatility,
      movingAverages: movingAverages,
      description: description,
    );
  }

  /// Calculate volatility (standard deviation) of performance scores
  double _calculateVolatility(List<MonthlyPerformance> monthlyData) {
    if (monthlyData.length < 2) return 0.0;
    
    final scores = monthlyData.map((m) => m.oneMonthNPS).toList();
    final mean = scores.reduce((a, b) => a + b) / scores.length;
    final variance = scores.map((score) => (score - mean) * (score - mean)).reduce((a, b) => a + b) / scores.length;
    return math.sqrt(variance);
  }

  /// Calculate moving averages
  List<double> _calculateMovingAverages(List<double> scores, int window) {
    if (scores.length < window) return scores;
    
    final List<double> movingAverages = [];
    for (int i = window - 1; i < scores.length; i++) {
      final windowScores = scores.sublist(i - window + 1, i + 1);
      final average = windowScores.reduce((a, b) => a + b) / window;
      movingAverages.add(average);
    }
    
    return movingAverages;
  }

  /// Detect seasonal patterns in performance
  SeasonalPattern? _detectSeasonalPattern(List<MonthlyPerformance> monthlyData) {
    if (monthlyData.length < 12) return null; // Need at least a year of data
    
    // Group by month
    final Map<int, List<double>> monthlyScores = {};
    for (final data in monthlyData) {
      final month = data.month.month;
      monthlyScores.putIfAbsent(month, () => []).add(data.oneMonthNPS);
    }
    
    // Calculate average for each month
    final Map<int, double> monthlyAverages = {};
    for (final entry in monthlyScores.entries) {
      final month = entry.key;
      final scores = entry.value;
      monthlyAverages[month] = scores.reduce((a, b) => a + b) / scores.length;
    }
    
    if (monthlyAverages.length < 6) return null; // Need at least 6 months of data
    
    // Find peak and low months
    final sortedMonths = monthlyAverages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final peakMonths = sortedMonths.take(3).map((e) => e.key).toList();
    final lowMonths = sortedMonths.reversed.take(3).map((e) => e.key).toList();
    
    // Calculate seasonality strength (coefficient of variation)
    final values = monthlyAverages.values.toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / values.length;
    final seasonalityStrength = mean > 0 ? math.sqrt(variance) / mean : 0.0;
    
    return SeasonalPattern(
      monthlyAverages: monthlyAverages,
      seasonalityStrength: seasonalityStrength,
      peakMonths: peakMonths,
      lowMonths: lowMonths,
    );
  }

  /// Classify performance based on historical data
  PerformanceClassification _classifyPerformance(
    List<MonthlyPerformance> monthlyData,
    PerformanceTrend trend,
    double volatility,
  ) {
    if (monthlyData.isEmpty) return PerformanceClassification.unknown;
    
    final recentMonths = monthlyData.take(3).toList();
    final recentAvg = recentMonths.map((m) => m.oneMonthNPS).reduce((a, b) => a + b) / recentMonths.length;
    final allTimeAvg = monthlyData.map((m) => m.allTimeNPS).reduce((a, b) => a + b) / monthlyData.length;
    
    // Elite: Consistently high performance (90%+) with low volatility
    if (allTimeAvg >= 90.0 && recentAvg >= 85.0 && volatility < 10.0) {
      return PerformanceClassification.elite;
    }
    
    // Strong: Good overall performance (80%+) with reasonable consistency
    if (allTimeAvg >= 80.0 && recentAvg >= 75.0 && volatility < 15.0) {
      return PerformanceClassification.strong;
    }
    
    // Critical: Consistently poor performance (50% or below)
    if (allTimeAvg <= 50.0 && recentAvg <= 50.0) {
      return PerformanceClassification.critical;
    }
    
    // Concerning: Declining trend or high volatility
    if (trend.direction == TrendDirection.declining || volatility > 20.0) {
      return PerformanceClassification.concerning;
    }
    
    // Developing: Improving trend or new to role
    if (trend.direction == TrendDirection.improving || monthlyData.length < 6) {
      return PerformanceClassification.developing;
    }
    
    // Default to concerning if we can't classify
    return PerformanceClassification.concerning;
  }

  /// Check if a month is typically a seasonal peak
  bool _isSeasonalPeak(int month) {
    // Common restaurant peak months (adjust based on your business)
    return [11, 12, 1, 2, 6, 7, 8].contains(month); // Holiday season and summer
  }

  /// Check if a month is typically a seasonal low
  bool _isSeasonalLow(int month) {
    // Common restaurant low months
    return [3, 4, 9, 10].contains(month); // Spring and fall
  }

  /// Generate trend description
  String _generateTrendDescription(TrendDirection direction, double slope, double strength, double volatility) {
    switch (direction) {
      case TrendDirection.improving:
        return 'Performance is improving with a ${slope.toStringAsFixed(1)} point monthly increase (${(strength * 100).toStringAsFixed(0)}% confidence)';
      case TrendDirection.declining:
        return 'Performance is declining with a ${slope.abs().toStringAsFixed(1)} point monthly decrease (${(strength * 100).toStringAsFixed(0)}% confidence)';
      case TrendDirection.volatile:
        return 'Performance is highly variable (${volatility.toStringAsFixed(1)} point standard deviation)';
      case TrendDirection.stable:
        return 'Performance is stable with minimal variation (${volatility.toStringAsFixed(1)} point standard deviation)';
    }
  }
}
