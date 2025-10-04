import 'dart:math' as math;
import '../models/historical_nps_data.dart';
import '../models/monthly_report.dart' hide PerformanceTrend;
import '../storage/database_factory.dart';
import '../utils/log.dart';
import '../app_state.dart';

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

  /// Load historical NPS data for all servers with AppState server mapping
  Future<List<HistoricalNPSData>> getAllHistoricalDataWithAppState(List<dynamic> appStateServers) async {
    try {
      d('[HistoricalNPSAggregationService] Loading historical data for all servers with AppState mapping');
      print('🔍🔍🔍 [HistoricalNPSAggregationService] STARTING getAllHistoricalDataWithAppState() 🔍🔍🔍');
      print('🔍 [HistoricalNPSAggregationService] Received ${appStateServers.length} AppState servers for mapping');
      
      // Instead of starting with servers table, start with monthly reports
      // This mirrors the logic used in the summary calculation
      final allReports = await _database.queryTable('nps_monthly_reports');
      d('[HistoricalNPSAggregationService] Found ${allReports.length} total monthly reports');
      print('🔍 [HistoricalNPSAggregationService] Found ${allReports.length} total monthly reports');
      
      // Filter out old server ID format (numeric IDs like "1", "2") to avoid duplicates
      // Keep only reports with complex server IDs (the new format)
      final filteredReports = allReports.where((report) {
        final serverId = report['server_id'].toString();
        final isOldFormat = RegExp(r'^\d+$').hasMatch(serverId) && serverId.length <= 2;
        if (isOldFormat) {
          print('🔍 [HistoricalNPSAggregationService] Filtering out old format server_id: $serverId');
        }
        return !isOldFormat; // Keep only non-old format IDs
      }).toList();
      
      print('🔍 [HistoricalNPSAggregationService] After filtering: ${filteredReports.length} reports (removed ${allReports.length - filteredReports.length} old format reports)');
      
      if (filteredReports.isEmpty) {
        d('[HistoricalNPSAggregationService] No monthly reports found after filtering - returning empty list');
        return [];
      }
      
      // Group reports by server ID
      final serverReports = <String, List<Map<String, dynamic>>>{};
      for (final report in filteredReports) {
        final serverId = report['server_id'].toString();
        serverReports.putIfAbsent(serverId, () => []).add(report);
      }
      
      d('[HistoricalNPSAggregationService] Found reports for ${serverReports.length} unique servers: ${serverReports.keys.toList()}');
      
      final List<HistoricalNPSData> allHistoricalData = [];
      
      // Process each server that has reports
      for (final entry in serverReports.entries) {
        final serverId = entry.key;
        final reports = entry.value;
        
        d('[HistoricalNPSAggregationService] Processing server: $serverId with ${reports.length} reports');
        
        try {
          // Get server name with comprehensive lookup using provided AppState servers
          print('🔍 [HistoricalNPSAggregationService] Getting server name for ID: $serverId');
          final serverName = await _getServerNameComprehensive(serverId, appStateServers: appStateServers);
          print('🔍 [HistoricalNPSAggregationService] Got server name: $serverName for ID: $serverId');
          
          // Convert monthly reports to MonthlyPerformance objects
          final monthlyData = reports.map((report) => _convertToMonthlyPerformance(report)).toList();
          
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
          
          allHistoricalData.add(historicalData);
          d('[HistoricalNPSAggregationService] ✅ Added historical data for server: $serverId ($serverName) with ${monthlyData.length} months');
        } catch (e) {
          d('[HistoricalNPSAggregationService] ❌ Error processing server $serverId: $e');
        }
      }
      
      d('[HistoricalNPSAggregationService] Successfully loaded historical data for ${allHistoricalData.length} servers');
      return allHistoricalData;
    } catch (e) {
      d('[HistoricalNPSAggregationService] Error loading all historical data: $e');
      return [];
    }
  }

  /// Load historical NPS data for all servers
  Future<List<HistoricalNPSData>> getAllHistoricalData() async {
    try {
      d('[HistoricalNPSAggregationService] Loading historical data for all servers');
      print('🔍🔍🔍 [HistoricalNPSAggregationService] STARTING getAllHistoricalData() 🔍🔍🔍');
      
      // Instead of starting with servers table, start with monthly reports
      // This mirrors the logic used in the summary calculation
      final allReports = await _database.queryTable('nps_monthly_reports');
      d('[HistoricalNPSAggregationService] Found ${allReports.length} total monthly reports');
      print('🔍 [HistoricalNPSAggregationService] Found ${allReports.length} total monthly reports');
      
      if (allReports.isEmpty) {
        d('[HistoricalNPSAggregationService] No monthly reports found - returning empty list');
        return [];
      }
      
      // Group reports by server ID
      final serverReports = <String, List<Map<String, dynamic>>>{};
      for (final report in allReports) {
        final serverId = report['server_id'].toString();
        serverReports.putIfAbsent(serverId, () => []).add(report);
      }
      
      d('[HistoricalNPSAggregationService] Found reports for ${serverReports.length} unique servers: ${serverReports.keys.toList()}');
      
      final List<HistoricalNPSData> allHistoricalData = [];
      
      // Process each server that has reports
      for (final entry in serverReports.entries) {
        final serverId = entry.key;
        final reports = entry.value;
        
        d('[HistoricalNPSAggregationService] Processing server: $serverId with ${reports.length} reports');
        
        try {
          // Get server name with comprehensive lookup
          print('🔍 [HistoricalNPSAggregationService] Getting server name for ID: $serverId');
          final serverName = await _getServerNameComprehensive(serverId);
          print('🔍 [HistoricalNPSAggregationService] Got server name: $serverName for ID: $serverId');
          
          // Convert monthly reports to MonthlyPerformance objects
          final monthlyData = reports.map((report) => _convertToMonthlyPerformance(report)).toList();
          
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
          
          allHistoricalData.add(historicalData);
          d('[HistoricalNPSAggregationService] ✅ Added historical data for server: $serverId ($serverName) with ${monthlyData.length} months');
        } catch (e) {
          d('[HistoricalNPSAggregationService] ❌ Error processing server $serverId: $e');
        }
      }
      
      d('[HistoricalNPSAggregationService] Successfully loaded historical data for ${allHistoricalData.length} servers');
      return allHistoricalData;
    } catch (e) {
      d('[HistoricalNPSAggregationService] Error loading all historical data: $e');
      return [];
    }
  }

  /// Get monthly reports for a specific server
  Future<List<Map<String, dynamic>>> _getMonthlyReportsForServer(String serverId) async {
    try {
      d('[HistoricalNPSAggregationService] Getting monthly reports for server: $serverId');
      
      // Handle different database schemas
      List<Map<String, dynamic>> results;
      if (DatabaseFactory.implementationType.contains('Sqflite')) {
        // Sqflite uses month_year column
        results = await _database.queryTable(
          'nps_monthly_reports',
          where: 'server_id = ?',
          whereArgs: [serverId], // Use string serverId directly
          orderBy: 'month_year DESC',
        );
      } else {
        // Drift uses separate report_month and report_year columns
        results = await _database.queryTable(
          'nps_monthly_reports',
          where: 'server_id = ?',
          whereArgs: [serverId], // Use string serverId directly
          orderBy: 'report_year DESC, report_month DESC',
        );
      }
      
      d('[HistoricalNPSAggregationService] Found ${results.length} monthly reports for server $serverId');
      if (results.isEmpty) {
        // Debug: Let's also try querying without the where clause to see all data
        final allReports = await _database.queryTable('nps_monthly_reports');
        final matchingReports = allReports.where((r) => r['server_id'].toString() == serverId).toList();
        d('[HistoricalNPSAggregationService] Alternative search found ${matchingReports.length} reports for server $serverId');
        if (allReports.isNotEmpty) {
          d('[HistoricalNPSAggregationService] Sample report data: ${allReports.first}');
        }
      }
      
      return results;
    } catch (e) {
      d('[HistoricalNPSAggregationService] Error getting monthly reports for server $serverId: $e');
      return [];
    }
  }

  /// Get server name with comprehensive lookup strategy
  Future<String> _getServerNameComprehensive(String serverId, {List<dynamic>? appStateServers}) async {
    try {
      d('[HistoricalNPSAggregationService] Comprehensive server name lookup for ID: $serverId');
      
      // Strategy 1: Try the basic lookup first (NPS database)
      final basicLookup = await _getServerName(serverId);
      if (!basicLookup.startsWith('Server ')) {
        return basicLookup; // Found a real name
      }
      
        // Strategy 2: Try to get server names from AppState (passed as parameter)
        if (appStateServers != null && appStateServers.isNotEmpty) {
          d('[HistoricalNPSAggregationService] Using provided AppState servers for lookup...');
        
          d('[HistoricalNPSAggregationService] Found ${appStateServers.length} servers in AppState');
          
          // Debug: Show available servers first
          print('🔍 [HistoricalNPSAggregationService] Found ${appStateServers.length} servers in AppState');
          for (int i = 0; i < appStateServers.length && i < 5; i++) {
            final server = appStateServers[i];
            d('[HistoricalNPSAggregationService] AppState server ${i + 1}: id=${server.id}, name=${server.name}');
            print('🔍 [HistoricalNPSAggregationService] AppState server ${i + 1}: id=${server.id}, name=${server.name}');
          }
        
        // Try direct ID match first
        for (final server in appStateServers) {
          if (server.id == serverId) {
            d('[HistoricalNPSAggregationService] Found exact match in AppState: ${server.name} for ID $serverId');
            return server.name;
          }
        }
        
        // Strategy 2b: If serverId looks like a number, map it to AppState servers by index
        if (RegExp(r'^\d+$').hasMatch(serverId)) {
          final serverIndex = int.tryParse(serverId);
          if (serverIndex != null && serverIndex > 0 && serverIndex <= appStateServers.length) {
            final server = appStateServers[serverIndex - 1]; // Convert 1-based to 0-based index
            d('[HistoricalNPSAggregationService] Found server by index ${serverIndex}: ${server.name}');
            return server.name;
          }
        }
        
        // Strategy 2c: If we have servers and serverId is numeric, map them by index
        if (appStateServers.isNotEmpty && RegExp(r'^\d+$').hasMatch(serverId)) {
          final index = int.tryParse(serverId);
          if (index != null && index >= 1 && index <= appStateServers.length) {
            final mappedServer = appStateServers[index - 1]; // Convert 1-based to 0-based
            d('[HistoricalNPSAggregationService] Mapping serverId "$serverId" to server at index ${index - 1}: ${mappedServer.name}');
            return mappedServer.name;
          }
        }
        
        // Strategy 2d: Alphabetical fallback mapping for known IDs
        if (appStateServers.length >= 3) {
          // Sort servers alphabetically to get consistent mapping
          final sortedServers = [...appStateServers]..sort((a, b) => a.name.compareTo(b.name));
          
          if (serverId == '1' && sortedServers.isNotEmpty) {
            d('[HistoricalNPSAggregationService] Alphabetical mapping serverId "1" to: ${sortedServers[0].name}');
            return sortedServers[0].name;
          } else if (serverId == '2' && sortedServers.length > 1) {
            d('[HistoricalNPSAggregationService] Alphabetical mapping serverId "2" to: ${sortedServers[1].name}');
            return sortedServers[1].name;
          } else if (serverId == '3' && sortedServers.length > 2) {
            d('[HistoricalNPSAggregationService] Alphabetical mapping serverId "3" to: ${sortedServers[2].name}');
            return sortedServers[2].name;
          }
        }
      }
      
      // Strategy 3: Use a more descriptive fallback
      return 'Server $serverId (Name not found)';
    } catch (e) {
      d('[HistoricalNPSAggregationService] Comprehensive lookup error: $e');
      return 'Server $serverId';
    }
  }

  /// Get server name by ID
  Future<String> _getServerName(String serverId) async {
    try {
      d('[HistoricalNPSAggregationService] Looking up server name for ID: $serverId');
      
      // First try exact match
      final server = await _database.queryTable(
        'servers',
        where: 'id = ?',
        whereArgs: [serverId],
        limit: 1,
      );
      
      if (server.isNotEmpty) {
        final name = server.first['name'] as String;
        d('[HistoricalNPSAggregationService] Found server name: $name for ID $serverId');
        return name;
      }
      
      // Try looking up by original_id (in case this is a main app server ID)
      try {
        final serverByOriginalId = await _database.queryTable(
          'servers',
          where: 'original_id = ?',
          whereArgs: [serverId],
          limit: 1,
        );
      
        if (serverByOriginalId.isNotEmpty) {
          final name = serverByOriginalId.first['name'] as String;
          d('[HistoricalNPSAggregationService] Found server by original_id: $name for ID $serverId');
          return name;
        }
      } catch (e) {
        d('[HistoricalNPSAggregationService] original_id column lookup failed (expected): $e');
        // This is expected if the database doesn't have the original_id column
      }
      
      // Try numeric conversion if serverId is numeric
      if (RegExp(r'^\d+$').hasMatch(serverId)) {
        final numericServer = await _database.queryTable(
          'servers',
          where: 'CAST(id AS TEXT) = ?',
          whereArgs: [serverId],
          limit: 1,
        );
        
        if (numericServer.isNotEmpty) {
          final name = numericServer.first['name'] as String;
          d('[HistoricalNPSAggregationService] Found server by numeric cast: $name for ID $serverId');
          return name;
        }
      }
      
      // Debug: Show all servers to understand the structure
      d('[HistoricalNPSAggregationService] No server found for ID $serverId. Debug: checking all servers...');
      final allServers = await _database.queryTable('servers');
      for (final s in allServers.take(5)) { // Show first 5 for debugging
        d('[HistoricalNPSAggregationService] Server: id=${s['id']}, original_id=${s['original_id']}, name=${s['name']}');
      }
      
      // Fallback to a descriptive name with the server ID
      d('[HistoricalNPSAggregationService] Using fallback name for server ID: $serverId');
      return 'Server $serverId';
    } catch (e) {
      d('[HistoricalNPSAggregationService] Error getting server name for ID $serverId: $e');
      return 'Server $serverId';
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
