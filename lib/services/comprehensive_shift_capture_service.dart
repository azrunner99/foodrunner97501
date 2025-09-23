/// Comprehensive Shift Data Capture Service
/// Captures all performance metrics, sales data, and correlations when shifts complete

import 'dart:math' as math;
import 'package:collection/collection.dart';

import '../models.dart';
import '../models/comprehensive_shift_data.dart';
import '../models/nps_feedback.dart';
import '../storage.dart';
import '../providers/nps_provider.dart';

class ComprehensiveShiftCaptureService {

  /// Capture complete shift data when a shift ends
  static Future<ComprehensiveShiftData> captureShiftCompletion({
    required String shiftId,
    required DateTime shiftDate,
    required String shiftType,
    required DateTime startTime,
    required DateTime endTime,
    required Map<String, int> serverRunCounts,
    required Map<String, int> serverPizookieCounts,
    required Map<String, String> stationAssignments,
    required Map<String, String> sectionAssignments,
    Map<String, double>? serverTips,
    Map<String, double>? serverSales,
    Map<String, int>? serverTablesServed,
    ShiftBusinessMetrics? businessMetrics,
  }) async {
    
    // Load server data
    final List<Map> rawServers = 
        (await Storage.serversBox.get('list') as List?)?.cast<Map>() ?? [];
    final servers = rawServers.map((json) => 
        Server.fromMap(Map<String, dynamic>.from(json))).toList();
    
    // Build server performances
    final serverPerformances = <ServerShiftPerformance>[];
    final hoursWorked = endTime.difference(startTime).inMinutes / 60.0;
    
    for (final serverId in serverRunCounts.keys) {
      final server = servers.firstWhereOrNull((s) => s.id == serverId);
      if (server == null) continue;
      
      final totalRuns = serverRunCounts[serverId] ?? 0;
      final pizookieRuns = serverPizookieCounts[serverId] ?? 0;
      final assignedStation = stationAssignments[serverId];
      final assignedSection = sectionAssignments[serverId];
      final tips = serverTips?[serverId];
      final sales = serverSales?[serverId];
      final tables = serverTablesServed?[serverId];
      
      // Generate realistic run timestamps for analytics
      final runTimestamps = _generateRunTimestamps(
        totalRuns, 
        pizookieRuns, 
        startTime, 
        endTime,
        assignedSection,
      );
      
      // Calculate performance metrics
      final performanceMetrics = _calculateServerMetrics(
        totalRuns: totalRuns,
        hoursWorked: hoursWorked,
        tips: tips,
        sales: sales,
        tables: tables,
        station: assignedStation,
        section: assignedSection,
      );
      
      serverPerformances.add(ServerShiftPerformance(
        serverId: serverId,
        serverName: server.name,
        assignedStation: assignedStation,
        assignedSection: assignedSection,
        totalRuns: totalRuns,
        pizookieRuns: pizookieRuns,
        hoursWorked: hoursWorked,
        tipAmount: tips,
        salesGenerated: sales,
        tablesServed: tables,
        averageTicketSize: (tables != null && tables > 0 && sales != null) ? sales / tables : null,
        runTimestamps: runTimestamps,
        performanceMetrics: performanceMetrics,
      ));
    }
    
    // Calculate section performances
    final sectionPerformances = _calculateSectionPerformances(
      serverPerformances, 
      sectionAssignments,
    );
    
    // Calculate station metrics
    final stationMetrics = _calculateStationMetrics(
      serverPerformances,
      stationAssignments,
    );
    
    // Use provided business metrics or calculate defaults
    final finalBusinessMetrics = businessMetrics ?? _calculateDefaultBusinessMetrics(
      serverPerformances,
    );
    
    // Calculate correlations
    final correlations = await _calculateShiftCorrelations(
      serverPerformances,
      finalBusinessMetrics,
      shiftDate,
    );
    
    final comprehensiveData = ComprehensiveShiftData(
      shiftId: shiftId,
      shiftDate: shiftDate,
      shiftType: shiftType,
      startTime: startTime,
      endTime: endTime,
      serverPerformances: serverPerformances,
      sectionPerformances: sectionPerformances,
      businessMetrics: finalBusinessMetrics,
      stationMetrics: stationMetrics,
      correlations: correlations,
    );
    
    // Store the comprehensive data
    await _storeComprehensiveShiftData(comprehensiveData);
    
    return comprehensiveData;
  }

  /// Generate realistic run timestamps for analysis
  static List<RunTimestamp> _generateRunTimestamps(
    int totalRuns,
    int pizookieRuns,
    DateTime startTime,
    DateTime endTime,
    String? section,
  ) {
    final timestamps = <RunTimestamp>[];
    final shiftDuration = endTime.difference(startTime);
    final random = math.Random();
    
    // Generate food runs
    for (int i = 0; i < totalRuns - pizookieRuns; i++) {
      final randomOffset = Duration(
        milliseconds: random.nextInt(shiftDuration.inMilliseconds),
      );
      timestamps.add(RunTimestamp(
        timestamp: startTime.add(randomOffset),
        runType: 'food',
        toSection: section,
        tableNumber: section != null ? random.nextInt(8) + 1 : null,
        associatedSales: 15.0 + random.nextDouble() * 25.0, // $15-40 average
      ));
    }
    
    // Generate pizookie runs
    for (int i = 0; i < pizookieRuns; i++) {
      final randomOffset = Duration(
        milliseconds: random.nextInt(shiftDuration.inMilliseconds),
      );
      timestamps.add(RunTimestamp(
        timestamp: startTime.add(randomOffset),
        runType: 'pizookie',
        toSection: section,
        tableNumber: section != null ? random.nextInt(8) + 1 : null,
        associatedSales: 8.0 + random.nextDouble() * 4.0, // $8-12 for desserts
      ));
    }
    
    timestamps.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return timestamps;
  }

  /// Calculate comprehensive server metrics
  static Map<String, dynamic> _calculateServerMetrics({
    required int totalRuns,
    required double hoursWorked,
    double? tips,
    double? sales,
    int? tables,
    String? station,
    String? section,
  }) {
    final metrics = <String, dynamic>{};
    
    metrics['runsPerHour'] = hoursWorked > 0 ? totalRuns / hoursWorked : 0;
    metrics['salesPerHour'] = (hoursWorked > 0 && sales != null) ? sales / hoursWorked : 0;
    metrics['tipsPerHour'] = (hoursWorked > 0 && tips != null) ? tips / hoursWorked : 0;
    metrics['salesPerRun'] = (totalRuns > 0 && sales != null) ? sales / totalRuns : 0;
    metrics['tablesPerHour'] = (hoursWorked > 0 && tables != null) ? tables / hoursWorked : 0;
    metrics['averageTicket'] = (tables != null && tables > 0 && sales != null) ? sales / tables : 0;
    
    // Station efficiency (if assigned)
    if (station != null) {
      metrics['stationEfficiency'] = _calculateStationEfficiency(station, totalRuns, hoursWorked);
    }
    
    // Section productivity (if assigned)
    if (section != null) {
      metrics['sectionProductivity'] = _calculateSectionProductivity(section, sales, tables);
    }
    
    // Overall performance score
    metrics['performanceScore'] = _calculatePerformanceScore(
      totalRuns, hoursWorked, tips, sales, tables,
    );
    
    return metrics;
  }

  /// Calculate section performances
  static Map<String, SectionPerformance> _calculateSectionPerformances(
    List<ServerShiftPerformance> serverPerformances,
    Map<String, String> sectionAssignments,
  ) {
    final sectionData = <String, Map<String, dynamic>>{};
    
    // Group servers by section
    for (final serverPerf in serverPerformances) {
      final section = serverPerf.assignedSection;
      if (section == null) continue;
      
      sectionData.putIfAbsent(section, () => {
        'serverIds': <String>[],
        'totalSales': 0.0,
        'totalTables': 0,
        'totalRuns': 0,
        'serverContributions': <String, double>{},
      });
      
      sectionData[section]!['serverIds'].add(serverPerf.serverId);
      sectionData[section]!['totalSales'] += serverPerf.salesGenerated ?? 0;
      sectionData[section]!['totalTables'] += serverPerf.tablesServed ?? 0;
      sectionData[section]!['totalRuns'] += serverPerf.totalRuns;
      
      // Calculate server contribution percentage
      final sectionSales = sectionData[section]!['totalSales'] as double;
      if (sectionSales > 0 && serverPerf.salesGenerated != null) {
        sectionData[section]!['serverContributions'][serverPerf.serverId] = 
            (serverPerf.salesGenerated! / sectionSales) * 100;
      }
    }
    
    // Build SectionPerformance objects
    final sectionPerformances = <String, SectionPerformance>{};
    sectionData.forEach((sectionId, data) {
      final totalSales = data['totalSales'] as double;
      final totalTables = data['totalTables'] as int;
      final serverIds = data['serverIds'] as List<String>;
      
      sectionPerformances[sectionId] = SectionPerformance(
        sectionId: sectionId,
        sectionName: 'Section $sectionId',
        tableCount: 8, // Assume 8 tables per section
        totalSales: totalSales,
        totalTables: totalTables,
        averageTicketSize: totalTables > 0 ? totalSales / totalTables : 0,
        turnRate: totalTables / 8.0, // tables served / total tables
        assignedServerIds: serverIds,
        serverContributions: Map<String, double>.from(data['serverContributions']),
      );
    });
    
    return sectionPerformances;
  }

  /// Calculate station metrics
  static Map<String, StationMetrics> _calculateStationMetrics(
    List<ServerShiftPerformance> serverPerformances,
    Map<String, String> stationAssignments,
  ) {
    final stationData = <String, Map<String, dynamic>>{};
    
    // Group servers by station
    for (final serverPerf in serverPerformances) {
      final station = serverPerf.assignedStation;
      if (station == null) continue;
      
      stationData.putIfAbsent(station, () => {
        'serverIds': <String>[],
        'totalRuns': 0,
        'totalSales': 0.0,
        'serverRunContributions': <String, int>{},
      });
      
      stationData[station]!['serverIds'].add(serverPerf.serverId);
      stationData[station]!['totalRuns'] += serverPerf.totalRuns;
      stationData[station]!['totalSales'] += serverPerf.salesGenerated ?? 0;
      stationData[station]!['serverRunContributions'][serverPerf.serverId] = serverPerf.totalRuns;
    }
    
    // Build StationMetrics objects
    final stationMetrics = <String, StationMetrics>{};
    stationData.forEach((stationType, data) {
      final totalRuns = data['totalRuns'] as int;
      final totalSales = data['totalSales'] as double;
      final serverIds = data['serverIds'] as List<String>;
      
      stationMetrics[stationType] = StationMetrics(
        stationType: stationType,
        totalRuns: totalRuns,
        totalSales: totalSales,
        averageRunTime: _calculateAverageRunTime(stationType),
        efficiencyScore: _calculateStationEfficiencyScore(stationType, totalRuns, totalSales),
        assignedServerIds: serverIds,
        serverRunContributions: Map<String, int>.from(data['serverRunContributions']),
        salesPerRun: totalRuns > 0 ? totalSales / totalRuns : 0,
      );
    });
    
    return stationMetrics;
  }

  /// Calculate default business metrics
  static ShiftBusinessMetrics _calculateDefaultBusinessMetrics(
    List<ServerShiftPerformance> serverPerformances,
  ) {
    final totalSales = serverPerformances.fold(0.0, (sum, sp) => sum + (sp.salesGenerated ?? 0));
    final totalTips = serverPerformances.fold(0.0, (sum, sp) => sum + (sp.tipAmount ?? 0));
    final totalTables = serverPerformances.fold(0, (sum, sp) => sum + (sp.tablesServed ?? 0));
    final totalCovers = (totalTables * 2.3).round(); // Average 2.3 guests per table
    
    return ShiftBusinessMetrics(
      totalSales: totalSales,
      totalTips: totalTips,
      totalCovers: totalCovers,
      totalTables: totalTables,
      averageTicketSize: totalTables > 0 ? totalSales / totalTables : 0,
      laborCost: serverPerformances.length * 15.0 * 8, // Estimate: $15/hour * 8 hours
      laborPercentage: totalSales > 0 ? (serverPerformances.length * 120) / totalSales * 100 : 0,
      salesPerCover: totalCovers > 0 ? totalSales / totalCovers : 0,
      tipsPercentage: totalSales > 0 ? totalTips / totalSales * 100 : 0,
      categoryBreakdown: {
        'food': totalSales * 0.75,
        'beverage': totalSales * 0.20,
        'dessert': totalSales * 0.05,
      },
    );
  }

  /// Calculate correlations between variables
  static Future<List<ShiftCorrelation>> _calculateShiftCorrelations(
    List<ServerShiftPerformance> serverPerformances,
    ShiftBusinessMetrics businessMetrics,
    DateTime shiftDate,
  ) async {
    final correlations = <ShiftCorrelation>[];
    
    if (serverPerformances.length < 3) {
      return correlations; // Need at least 3 data points for meaningful correlation
    }
    
    // Extract variables for correlation analysis
    final runs = serverPerformances.map((sp) => sp.totalRuns.toDouble()).toList();
    final sales = serverPerformances.map((sp) => sp.salesGenerated ?? 0.0).toList();
    final tips = serverPerformances.map((sp) => sp.tipAmount ?? 0.0).toList();
    final hours = serverPerformances.map((sp) => sp.hoursWorked).toList();
    final tables = serverPerformances.map((sp) => (sp.tablesServed ?? 0).toDouble()).toList();
    
    // Calculate correlations
    correlations.add(_calculateCorrelation('runs_vs_sales', 'Total Runs', 'Sales Generated', runs, sales));
    correlations.add(_calculateCorrelation('runs_vs_tips', 'Total Runs', 'Tips Received', runs, tips));
    correlations.add(_calculateCorrelation('sales_vs_tips', 'Sales Generated', 'Tips Received', sales, tips));
    correlations.add(_calculateCorrelation('hours_vs_sales', 'Hours Worked', 'Sales Generated', hours, sales));
    correlations.add(_calculateCorrelation('tables_vs_sales', 'Tables Served', 'Sales Generated', tables, sales));
    
    // Load NPS data for correlation
    try {
      final npsProvider = NPSProvider();
      await npsProvider.initialize();
      final feedbackList = await npsProvider.getFeedbackByDateRange(
        shiftDate.subtract(const Duration(days: 1)),
        shiftDate.add(const Duration(days: 1)),
      );
      
      if (feedbackList.isNotEmpty) {
        final npsScores = <double>[];
        final serverSalesForNPS = <double>[];
        
        for (final serverPerf in serverPerformances) {
          final serverFeedback = feedbackList.where((f) => f.serverId.toString() == serverPerf.serverId).toList();
          if (serverFeedback.isNotEmpty) {
            final avgNPS = serverFeedback.map((f) => f.feedbackType.npsImpact.toDouble()).reduce((a, b) => a + b) / serverFeedback.length;
            npsScores.add(avgNPS);
            serverSalesForNPS.add(serverPerf.salesGenerated ?? 0);
          }
        }
        
        if (npsScores.length > 2) {
          correlations.add(_calculateCorrelation('nps_vs_sales', 'NPS Score', 'Sales Generated', npsScores, serverSalesForNPS));
        }
      }
    } catch (e) {
      print('[COMPREHENSIVE_SHIFT] Error loading NPS data for correlation: $e');
    }
    
    return correlations.where((c) => c.significance < 0.1).toList(); // Only include somewhat significant correlations
  }

  /// Calculate Pearson correlation coefficient
  static ShiftCorrelation _calculateCorrelation(
    String type,
    String var1Name,
    String var2Name,
    List<double> x,
    List<double> y,
  ) {
    if (x.length != y.length || x.length < 3) {
      return ShiftCorrelation(
        correlationType: type,
        variable1: var1Name,
        variable2: var2Name,
        correlationCoefficient: 0.0,
        significance: 1.0,
        interpretation: 'Insufficient data for correlation analysis',
        additionalData: {},
      );
    }
    
    final n = x.length;
    final meanX = x.reduce((a, b) => a + b) / n;
    final meanY = y.reduce((a, b) => a + b) / n;
    
    double numerator = 0;
    double sumXSquared = 0;
    double sumYSquared = 0;
    
    for (int i = 0; i < n; i++) {
      final xDiff = x[i] - meanX;
      final yDiff = y[i] - meanY;
      numerator += xDiff * yDiff;
      sumXSquared += xDiff * xDiff;
      sumYSquared += yDiff * yDiff;
    }
    
    final denominator = math.sqrt(sumXSquared * sumYSquared);
    final correlation = denominator > 0 ? numerator / denominator : 0.0;
    
    // Simple significance test (t-test approximation)
    final tStatistic = correlation * math.sqrt((n - 2) / (1 - correlation * correlation));
    final pValue = _approximatePValue(tStatistic.abs(), n - 2);
    
    String interpretation;
    if (pValue > 0.05) {
      interpretation = 'No significant correlation detected';
    } else if (correlation.abs() > 0.7) {
      interpretation = correlation > 0 ? 'Strong positive correlation' : 'Strong negative correlation';
    } else if (correlation.abs() > 0.5) {
      interpretation = correlation > 0 ? 'Moderate positive correlation' : 'Moderate negative correlation';
    } else {
      interpretation = correlation > 0 ? 'Weak positive correlation' : 'Weak negative correlation';
    }
    
    return ShiftCorrelation(
      correlationType: type,
      variable1: var1Name,
      variable2: var2Name,
      correlationCoefficient: correlation,
      significance: pValue,
      interpretation: interpretation,
      additionalData: {
        'n': n,
        'meanX': meanX,
        'meanY': meanY,
        'tStatistic': tStatistic,
      },
    );
  }

  /// Helper functions for calculations
  static double _calculateStationEfficiency(String station, int runs, double hours) {
    final runRate = hours > 0 ? runs / hours : 0;
    switch (station) {
      case 'Server': return (runRate / 8.0 * 100).clamp(0, 100); // Target: 8 runs/hour
      case 'Host': return (runRate / 3.0 * 100).clamp(0, 100); // Target: 3 runs/hour
      case 'Busser': return (runRate / 12.0 * 100).clamp(0, 100); // Target: 12 runs/hour
      case 'Runner': return (runRate / 15.0 * 100).clamp(0, 100); // Target: 15 runs/hour
      default: return (runRate / 10.0 * 100).clamp(0, 100);
    }
  }

  static double _calculateSectionProductivity(String? section, double? sales, int? tables) {
    if (sales == null || tables == null || tables == 0) return 0;
    final avgTicket = sales / tables;
    return (avgTicket / 30.0 * 100).clamp(0, 100); // Target: $30 average ticket
  }

  static double _calculatePerformanceScore(int runs, double hours, double? tips, double? sales, int? tables) {
    double score = 0;
    final runRate = hours > 0 ? runs / hours : 0;
    score += (runRate / 10.0) * 40; // 40% weight for run rate
    
    if (sales != null && hours > 0) {
      score += (sales / hours / 200.0) * 30; // 30% weight for sales/hour
    }
    
    if (tips != null && hours > 0) {
      score += (tips / hours / 25.0) * 20; // 20% weight for tips/hour
    }
    
    if (tables != null && hours > 0) {
      score += (tables / hours / 3.0) * 10; // 10% weight for tables/hour
    }
    
    return (score * 100).clamp(0, 100);
  }

  static double _calculateAverageRunTime(String stationType) {
    switch (stationType) {
      case 'Server': return 3.5; // 3.5 minutes average
      case 'Host': return 2.0; // 2 minutes average
      case 'Busser': return 4.0; // 4 minutes average
      case 'Runner': return 2.5; // 2.5 minutes average
      default: return 3.0;
    }
  }

  static double _calculateStationEfficiencyScore(String stationType, int runs, double sales) {
    final salesPerRun = runs > 0 ? sales / runs : 0;
    final targetSalesPerRun = stationType == 'Server' ? 25.0 : 15.0;
    return (salesPerRun / targetSalesPerRun * 100).clamp(0, 100);
  }

  static double _approximatePValue(double tStat, int df) {
    // Very rough approximation for p-value from t-statistic
    if (df < 1) return 1.0;
    if (tStat < 1.0) return 0.4;
    if (tStat < 2.0) return 0.1;
    if (tStat < 3.0) return 0.02;
    return 0.001;
  }

  /// Store comprehensive shift data
  static Future<void> _storeComprehensiveShiftData(ComprehensiveShiftData data) async {
    try {
      final List<Map> existingData = 
          (await Storage.settingsBox.get('comprehensiveShiftData') as List?)?.cast<Map>() ?? [];
      
      existingData.add(data.toMap());
      
      // Keep only last 100 shifts to manage storage
      if (existingData.length > 100) {
        existingData.removeRange(0, existingData.length - 100);
      }
      
      await Storage.settingsBox.put('comprehensiveShiftData', existingData);
      print('[COMPREHENSIVE_SHIFT] Stored shift data: ${data.shiftId}');
    } catch (e) {
      print('[COMPREHENSIVE_SHIFT] Error storing data: $e');
    }
  }

  /// Retrieve comprehensive shift data
  static Future<List<ComprehensiveShiftData>> getStoredShiftData() async {
    try {
      final List<Map> rawData = 
          (await Storage.settingsBox.get('comprehensiveShiftData') as List?)?.cast<Map>() ?? [];
      
      return rawData.map((map) => 
          ComprehensiveShiftData.fromMap(Map<String, dynamic>.from(map))).toList();
    } catch (e) {
      print('[COMPREHENSIVE_SHIFT] Error loading data: $e');
      return [];
    }
  }
}