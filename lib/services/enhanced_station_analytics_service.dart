/// Enhanced Station Analytics Service
/// Phase 2: Integrates NPS data, sales data, and guest count tracking with station/section assignments

import '../models.dart';
import '../models/performance_models.dart';
import '../models/monthly_report.dart';
import '../storage/nps_database.dart';
import '../utils/log.dart';
import 'dart:math' as math;

// Import SectionPerformanceData from the screen file
// This will be resolved at runtime when the service is used

class EnhancedStationAnalyticsService {
  static final EnhancedStationAnalyticsService _instance = EnhancedStationAnalyticsService._internal();
  factory EnhancedStationAnalyticsService() => _instance;
  EnhancedStationAnalyticsService._internal();

  /// Get NPS data for servers in a specific section
  Future<Map<String, NPSData>> getNPSDataForSection({
    required List<String> serverIds,
    required int monthsToLookBack,
  }) async {
    try {
      d('[EnhancedStationAnalytics] Getting NPS data for ${serverIds.length} servers');
      
      // For now, return empty data as NPS integration needs to be implemented
      // This is a placeholder for Phase 2 implementation
      final npsData = <String, NPSData>{};
      
      d('[EnhancedStationAnalytics] NPS data integration not yet implemented - returning empty data');
      return npsData;
    } catch (e) {
      d('[EnhancedStationAnalytics] Error getting NPS data: $e');
      return {};
    }
  }

  /// Get sales data for servers in a specific section
  Future<Map<String, double>> getSalesDataForSection({
    required List<String> serverIds,
    required List<ShiftRecord> shiftRecords,
  }) async {
    try {
      d('[EnhancedStationAnalytics] Getting sales data for ${serverIds.length} servers');
      
      final salesData = <String, double>{};
      
      for (final serverId in serverIds) {
        double totalSales = 0.0;
        int shiftsWithSales = 0;
        
        for (final shift in shiftRecords) {
          if (shift.counts.containsKey(serverId)) {
            // Estimate sales based on runs (this would be replaced with actual sales data)
            final runs = shift.counts[serverId] ?? 0;
            final estimatedSales = runs * 25.0; // $25 average per run
            totalSales += estimatedSales;
            shiftsWithSales++;
          }
        }
        
        if (shiftsWithSales > 0) {
          salesData[serverId] = totalSales;
        }
      }
      
      d('[EnhancedStationAnalytics] Retrieved sales data for ${salesData.length} servers');
      return salesData;
    } catch (e) {
      d('[EnhancedStationAnalytics] Error getting sales data: $e');
      return {};
    }
  }

  /// Get guest count data for servers in a specific section
  Future<Map<String, int>> getGuestCountDataForSection({
    required List<String> serverIds,
    required List<ShiftRecord> shiftRecords,
  }) async {
    try {
      d('[EnhancedStationAnalytics] Getting guest count data for ${serverIds.length} servers');
      
      final guestData = <String, int>{};
      
      for (final serverId in serverIds) {
        int totalGuests = 0;
        
        for (final shift in shiftRecords) {
          if (shift.counts.containsKey(serverId)) {
            // Estimate guest count based on runs (this would be replaced with actual guest data)
            final runs = shift.counts[serverId] ?? 0;
            final estimatedGuests = (runs * 0.8).round(); // 0.8 guests per run average
            totalGuests += estimatedGuests;
          }
        }
        
        guestData[serverId] = totalGuests;
      }
      
      d('[EnhancedStationAnalytics] Retrieved guest count data for ${guestData.length} servers');
      return guestData;
    } catch (e) {
      d('[EnhancedStationAnalytics] Error getting guest count data: $e');
      return {};
    }
  }

  /// Calculate comprehensive performance metrics for a section
  Future<Map<String, double>> calculateServerPerformanceScores({
    required List<String> serverIds,
    required Map<String, NPSData> npsData,
    required Map<String, double> salesData,
    required Map<String, int> guestData,
    required List<ShiftRecord> shiftRecords,
  }) async {
    try {
      d('[EnhancedStationAnalytics] Calculating performance scores for ${serverIds.length} servers');
      
      final performanceScores = <String, double>{};
      
      for (final serverId in serverIds) {
        double score = 0.0;
        int components = 0;
        
        // NPS Component (40% weight)
        if (npsData.containsKey(serverId) && npsData[serverId]!.hasActualNpsData) {
          final npsScore = npsData[serverId]!.threeMonthAverage;
          score += (npsScore / 100) * 40; // Convert to 0-40 scale
          components++;
        }
        
        // Sales Component (30% weight)
        if (salesData.containsKey(serverId)) {
          final sales = salesData[serverId]!;
          final salesScore = (sales / 1000) * 30; // $1000 = 30 points
          score += math.min(salesScore, 30); // Cap at 30
          components++;
        }
        
        // Efficiency Component (30% weight) - based on runs per shift
        final serverRuns = shiftRecords.fold(0, (sum, shift) => 
            sum + (shift.counts[serverId] ?? 0));
        final serverShifts = shiftRecords.where((shift) => 
            shift.counts.containsKey(serverId)).length;
        
        if (serverShifts > 0) {
          final runsPerShift = serverRuns / serverShifts;
          final efficiencyScore = (runsPerShift / 20) * 30; // 20 runs/shift = 30 points
          score += math.min(efficiencyScore, 30); // Cap at 30
          components++;
        }
        
        if (components > 0) {
          performanceScores[serverId] = score;
        }
      }
      
      d('[EnhancedStationAnalytics] Calculated performance scores for ${performanceScores.length} servers');
      return performanceScores;
    } catch (e) {
      d('[EnhancedStationAnalytics] Error calculating performance scores: $e');
      return {};
    }
  }

  /// Generate performance insights for a section
  List<String> generatePerformanceInsights({
    required dynamic sectionData,
    required Map<String, NPSData> npsData,
    required Map<String, double> salesData,
  }) {
    final insights = <String>[];
    
    // NPS Insights
    if (sectionData.hasNPSData == true && sectionData.threeMonthNPSAverage != null) {
      final nps = sectionData.threeMonthNPSAverage;
      if (nps >= 80) {
        insights.add('Exceptional guest satisfaction (${nps.toStringAsFixed(1)}% NPS)');
      } else if (nps >= 70) {
        insights.add('Strong guest satisfaction (${nps.toStringAsFixed(1)}% NPS)');
      } else if (nps >= 60) {
        insights.add('Good guest satisfaction (${nps.toStringAsFixed(1)}% NPS)');
      } else if (nps < 50) {
        insights.add('Guest satisfaction needs improvement (${nps.toStringAsFixed(1)}% NPS)');
      }
    }
    
    // Sales Insights
    if (sectionData.hasSalesData == true && sectionData.averageSalesPerRun != null) {
      final salesPerRun = sectionData.averageSalesPerRun;
      if (salesPerRun >= 30) {
        insights.add('High sales performance (\$${salesPerRun.toStringAsFixed(0)} per run)');
      } else if (salesPerRun < 20) {
        insights.add('Sales performance could improve (\$${salesPerRun.toStringAsFixed(0)} per run)');
      }
    }
    
    // Efficiency Insights
    if (sectionData.averageRunsPerShift >= 20) {
      insights.add('Excellent efficiency (${sectionData.averageRunsPerShift.toStringAsFixed(1)} runs/shift)');
    } else if (sectionData.averageRunsPerShift < 15) {
      insights.add('Efficiency could improve (${sectionData.averageRunsPerShift.toStringAsFixed(1)} runs/shift)');
    }
    
    // Team Size Insights
    if (sectionData.totalServers > 3) {
      insights.add('Well-staffed section (${sectionData.totalServers} servers)');
    } else if (sectionData.totalServers < 2) {
      insights.add('Understaffed section (${sectionData.totalServers} servers)');
    }
    
    return insights;
  }
}
