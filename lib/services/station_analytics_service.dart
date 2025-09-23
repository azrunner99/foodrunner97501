/// Station Analytics Service
/// Business logic layer for station performance analysis and insights

import 'dart:math' as math;
import 'package:collection/collection.dart';

import '../models.dart';
import '../models/station_performance_metric.dart';
import '../utils/station_analytics_calculator.dart';
import '../storage.dart';

class StationAnalyticsService {
  
  /// Calculate efficiency metrics for all stations from historical shift data
  static Future<Map<String, double>> calculateStationEfficiency(
    List<ShiftRecord> records,
  ) async {
    final stationEfficiencies = <String, double>{};
    final stationData = <String, Map<String, dynamic>>{};
    
    // Aggregate data by station type
    for (final record in records) {
      if (record.stationAssignments == null) continue;
      
      record.stationAssignments!.forEach((serverId, stationType) {
        final serverRuns = record.counts[serverId] ?? 0;
        if (serverRuns == 0) return; // Skip servers with no runs
        
        stationData.putIfAbsent(stationType, () => {
          'totalRuns': 0,
          'totalHours': 0.0,
          'activeServers': <String>{},
          'shifts': 0,
        });
        
        stationData[stationType]!['totalRuns'] += serverRuns;
        stationData[stationType]!['totalHours'] += 8.0; // Assume 8-hour shifts
        (stationData[stationType]!['activeServers'] as Set<String>).add(serverId);
        stationData[stationType]!['shifts']++;
      });
    }
    
    // Calculate efficiency for each station
    stationData.forEach((stationType, data) {
      final totalRuns = data['totalRuns'] as int;
      final totalHours = data['totalHours'] as double;
      final activeServers = (data['activeServers'] as Set<String>).length;
      final shifts = data['shifts'] as int;
      
      final efficiency = StationAnalyticsCalculator.calculateStationEfficiency(
        totalRuns: totalRuns,
        totalHours: totalHours,
        activeServers: activeServers,
        scheduledServers: math.max(activeServers, shifts), // Use shift count as scheduled minimum
      );
      
      stationEfficiencies[stationType] = efficiency;
    });
    
    return stationEfficiencies;
  }

  /// Get historical performance trends for a specific station type
  static Future<List<StationPerformanceMetric>> getHistoricalTrends(
    String stationType,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Load shift records from storage
    final List<Map> rawRecords = 
        (await Storage.shiftsBox.get('list') as List?)?.cast<Map>() ?? [];
    
    // Convert to ShiftRecord objects  
    final allRecords = rawRecords.map((json) => ShiftRecord.fromMap(Map<String, dynamic>.from(json))).toList();
    final relevantRecords = allRecords.where((record) =>
        record.start.isAfter(startDate.subtract(const Duration(days: 1))) &&
        record.start.isBefore(endDate.add(const Duration(days: 1))) &&
        record.stationAssignments != null &&
        record.stationAssignments!.values.contains(stationType)).toList();
    
    // Group records by day
    final dailyMetrics = <String, List<ShiftRecord>>{};
    for (final record in relevantRecords) {
      final dateKey = '${record.start.year}-${record.start.month}-${record.start.day}';
      dailyMetrics.putIfAbsent(dateKey, () => []).add(record);
    }
    
    final trends = <StationPerformanceMetric>[];
    
    dailyMetrics.forEach((dateKey, dayRecords) {
      int totalRuns = 0;
      int totalHours = 0;
      final serverContributions = <String, double>{};
      final activeServers = <String>{};
      
      for (final record in dayRecords) {
        record.stationAssignments!.forEach((serverId, assignedStationType) {
          if (assignedStationType == stationType) {
            final serverRuns = record.counts[serverId] ?? 0;
            totalRuns += serverRuns;
            totalHours += 8; // Assume 8-hour shifts
            activeServers.add(serverId);
            serverContributions[serverId] = (serverContributions[serverId] ?? 0) + serverRuns;
          }
        });
      }
      
      if (totalRuns > 0) {
        final efficiency = StationAnalyticsCalculator.calculateStationEfficiency(
          totalRuns: totalRuns,
          totalHours: totalHours.toDouble(),
          activeServers: activeServers.length,
          scheduledServers: activeServers.length,
        );
        
        final utilizationRate = StationAnalyticsCalculator.calculateUtilizationRate(
          activeServers: activeServers.length,
          scheduledServers: activeServers.length,
          activeHours: totalHours.toDouble(),
          scheduledHours: totalHours.toDouble(),
        );
        
        // Convert server contributions to percentages
        final contributionPercentages = StationAnalyticsCalculator.calculateServerContributions(
          serverContributions.map((k, v) => MapEntry(k, v.toInt())),
          totalRuns,
        );
        
        trends.add(StationPerformanceMetric(
          stationId: stationType,
          stationType: stationType,
          timestamp: DateTime.parse('$dateKey 12:00:00'),
          efficiencyScore: efficiency,
          totalRuns: totalRuns,
          averageRunTime: totalHours > 0 ? (totalHours * 60) / totalRuns : 0,
          activeServers: activeServers.length,
          serverContributions: contributionPercentages,
          totalHours: totalHours,
          utilizationRate: utilizationRate,
        ));
      }
    });
    
    trends.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return trends;
  }

  /// Get server performance across different stations
  static Future<Map<String, List<double>>> getServerStationPerformance(String serverId) async {
    // Load shift records from storage
    final List<Map> rawRecords = 
        (await Storage.shiftsBox.get('list') as List?)?.cast<Map>() ?? [];
    
    // Convert to ShiftRecord objects  
    final allRecords = rawRecords.map((json) => ShiftRecord.fromMap(Map<String, dynamic>.from(json))).toList();
    final serverPerformance = <String, List<double>>{};
    
    for (final record in allRecords) {
      if (record.stationAssignments == null || !record.stationAssignments!.containsKey(serverId)) {
        continue;
      }
      
      final stationType = record.stationAssignments![serverId]!;
      final serverRuns = record.counts[serverId] ?? 0;
      
      if (serverRuns > 0) {
        // Calculate runs per hour for this shift
        final runsPerHour = serverRuns / 8.0; // Assume 8-hour shift
        serverPerformance.putIfAbsent(stationType, () => []).add(runsPerHour);
      }
    }
    
    return serverPerformance;
  }

  /// Compare performance across all station types
  static Future<List<StationComparisonData>> compareStationPerformance() async {
    // Load shift records from storage
    final List<Map> rawRecords = 
        (await Storage.shiftsBox.get('list') as List?)?.cast<Map>() ?? [];
    
    // Convert to ShiftRecord objects  
    final allRecords = rawRecords.map((json) => ShiftRecord.fromMap(Map<String, dynamic>.from(json))).toList();
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final sixtyDaysAgo = now.subtract(const Duration(days: 60));
    
    // Get current period (last 30 days) and previous period (30-60 days ago)
    final currentPeriodRecords = allRecords.where((r) => 
        r.start.isAfter(thirtyDaysAgo) && r.stationAssignments != null).toList();
    final previousPeriodRecords = allRecords.where((r) => 
        r.start.isAfter(sixtyDaysAgo) && r.start.isBefore(thirtyDaysAgo) && r.stationAssignments != null).toList();
    
    // Get all unique station types
    final allStationTypes = <String>{};
    for (final record in allRecords) {
      if (record.stationAssignments != null) {
        allStationTypes.addAll(record.stationAssignments!.values);
      }
    }
    
    final comparisons = <StationComparisonData>[];
    
    for (final stationType in allStationTypes) {
      // Calculate current period efficiency
      final currentEfficiency = await _calculatePeriodEfficiency(currentPeriodRecords, stationType);
      final previousEfficiency = await _calculatePeriodEfficiency(previousPeriodRecords, stationType);
      
      // Calculate trend
      final trendPercentage = StationAnalyticsCalculator.calculateTrendPercentage(
        currentEfficiency, 
        previousEfficiency,
      );
      
      // Identify top performers and improvement areas
      final topPerformers = await _getTopPerformersForStation(currentPeriodRecords, stationType);
      final improvementAreas = await _getImprovementAreasForStation(currentPeriodRecords, stationType);
      
      comparisons.add(StationComparisonData(
        stationType: stationType,
        currentEfficiency: currentEfficiency,
        previousEfficiency: previousEfficiency,
        trendPercentage: trendPercentage,
        topPerformers: topPerformers,
        improvementAreas: improvementAreas,
        totalShifts: currentPeriodRecords.where((r) => 
            r.stationAssignments!.values.contains(stationType)).length,
        lastUpdated: now,
      ));
    }
    
    // Sort by current efficiency (highest first)
    comparisons.sort((a, b) => b.currentEfficiency.compareTo(a.currentEfficiency));
    return comparisons;
  }

  /// Get real-time metrics for active stations during current shift
  static Future<List<RealTimeStationMetric>> getRealTimeStationMetrics({
    required Map<String, int> currentCounts,
    required Map<String, String> currentStationAssignments,
  }) async {
    final now = DateTime.now();
    final stationGroups = <String, List<String>>{};
    
    // Group servers by station type
    currentStationAssignments.forEach((serverId, stationType) {
      stationGroups.putIfAbsent(stationType, () => []).add(serverId);
    });
    
    final realTimeMetrics = <RealTimeStationMetric>[];
    
    stationGroups.forEach((stationType, serverIds) {
      final metric = RealTimeStationMetric.fromCurrentState(
        stationId: stationType,
        stationType: stationType,
        currentCounts: currentCounts,
        stationServerIds: serverIds,
        timestamp: now,
      );
      realTimeMetrics.add(metric);
    });
    
    return realTimeMetrics;
  }

  /// Get performance insights and recommendations
  static Future<List<String>> getPerformanceInsights() async {
    final comparisons = await compareStationPerformance();
    final insights = <String>[];
    
    if (comparisons.isNotEmpty) {
      // Best performing station
      final bestStation = comparisons.first;
      insights.add('${bestStation.stationType} is your top performing station with ${bestStation.currentEfficiency.toStringAsFixed(1)}% efficiency');
      
      // Biggest improvement
      final biggestImprovement = comparisons.where((c) => c.trendPercentage > 10).toList();
      if (biggestImprovement.isNotEmpty) {
        insights.add('${biggestImprovement.first.stationType} showed the biggest improvement (+${biggestImprovement.first.trendPercentage.toStringAsFixed(1)}%)');
      }
      
      // Needs attention
      final needsAttention = comparisons.where((c) => c.currentEfficiency < 60).toList();
      if (needsAttention.isNotEmpty) {
        insights.add('${needsAttention.first.stationType} needs attention - efficiency below 60%');
      }
      
      // Declining performance
      final declining = comparisons.where((c) => c.trendPercentage < -10).toList();
      if (declining.isNotEmpty) {
        insights.add('${declining.first.stationType} performance declining (-${declining.first.trendPercentage.abs().toStringAsFixed(1)}%)');
      }
      
      // Overall trends
      final averageEfficiency = comparisons.fold<double>(0, (sum, c) => sum + c.currentEfficiency) / comparisons.length;
      insights.add('Overall station efficiency: ${averageEfficiency.toStringAsFixed(1)}%');
    }
    
    return insights;
  }

  // Helper methods
  
  static Future<double> _calculatePeriodEfficiency(List<ShiftRecord> records, String stationType) async {
    int totalRuns = 0;
    double totalHours = 0;
    int activeServers = 0;
    
    for (final record in records) {
      if (record.stationAssignments == null) continue;
      
      record.stationAssignments!.forEach((serverId, assignedStationType) {
        if (assignedStationType == stationType) {
          totalRuns += record.counts[serverId] ?? 0;
          totalHours += 8.0; // Assume 8-hour shifts
          activeServers++;
        }
      });
    }
    
    if (totalHours == 0) return 0.0;
    
    return StationAnalyticsCalculator.calculateStationEfficiency(
      totalRuns: totalRuns,
      totalHours: totalHours,
      activeServers: activeServers,
      scheduledServers: activeServers,
    );
  }
  
  static Future<List<String>> _getTopPerformersForStation(List<ShiftRecord> records, String stationType) async {
    final serverPerformance = <String, double>{};
    
    for (final record in records) {
      if (record.stationAssignments == null) continue;
      
      record.stationAssignments!.forEach((serverId, assignedStationType) {
        if (assignedStationType == stationType) {
          final runs = record.counts[serverId] ?? 0;
          serverPerformance[serverId] = (serverPerformance[serverId] ?? 0) + runs;
        }
      });
    }
    
    final sortedPerformers = serverPerformance.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedPerformers.take(3).map((e) => e.key).toList();
  }
  
  static Future<List<String>> _getImprovementAreasForStation(List<ShiftRecord> records, String stationType) async {
    final areas = <String>[];
    
    // Simple improvement area identification
    final efficiency = await _calculatePeriodEfficiency(records, stationType);
    
    if (efficiency < 50) areas.add('Low overall efficiency');
    if (efficiency < 70) areas.add('Performance consistency');
    
    return areas;
  }
}