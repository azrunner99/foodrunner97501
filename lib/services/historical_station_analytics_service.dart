/// Historical Station Analytics Service
/// Phase 4: Big picture insights, seasonal patterns, and long-term performance trends

import '../models.dart';
import '../utils/log.dart';
import 'dart:math' as math;

/// Historical analysis data for station/section performance
class HistoricalStationAnalysis {
  final String sectionName;
  final String stationType;
  final List<SeasonalPattern> seasonalPatterns;
  final List<MonthlyPerformance> monthlyTrends;
  final List<StaffingPattern> staffingPatterns;
  final List<PeakPerformancePeriod> peakPeriods;
  final CapacityPlanningInsights capacityInsights;
  final List<HistoricalInsight> insights;
  final DateTime analysisDate;
  final int totalMonthsAnalyzed;

  HistoricalStationAnalysis({
    required this.sectionName,
    required this.stationType,
    required this.seasonalPatterns,
    required this.monthlyTrends,
    required this.staffingPatterns,
    required this.peakPeriods,
    required this.capacityInsights,
    required this.insights,
    required this.analysisDate,
    required this.totalMonthsAnalyzed,
  });
}

/// Seasonal performance pattern
class SeasonalPattern {
  final String season; // "Spring", "Summer", "Fall", "Winter"
  final double averagePerformance;
  final double performanceVariance;
  final List<String> characteristics;
  final SeasonalTrend trend; // "improving", "declining", "stable"
  final String description;

  SeasonalPattern({
    required this.season,
    required this.averagePerformance,
    required this.performanceVariance,
    required this.characteristics,
    required this.trend,
    required this.description,
  });
}

/// Seasonal trend direction
enum SeasonalTrend {
  improving,
  declining,
  stable,
  volatile
}

/// Monthly performance data
class MonthlyPerformance {
  final DateTime month;
  final double performanceScore;
  final int totalRuns;
  final int totalShifts;
  final double averageRunsPerShift;
  final double npsScore;
  final int guestCount;
  final double salesVolume;
  final MonthlyTrend trend;

  MonthlyPerformance({
    required this.month,
    required this.performanceScore,
    required this.totalRuns,
    required this.totalShifts,
    required this.averageRunsPerShift,
    required this.npsScore,
    required this.guestCount,
    required this.salesVolume,
    required this.trend,
  });
}

/// Monthly trend direction
enum MonthlyTrend {
  improving,
  declining,
  stable,
  newData
}

/// Staffing pattern analysis
class StaffingPattern {
  final String serverId;
  final String serverName;
  final int totalShiftsInSection;
  final double averagePerformanceWhenInSection;
  final double performanceVariance;
  final List<String> strengths;
  final List<String> improvementAreas;
  final StaffingRecommendation recommendation;

  StaffingPattern({
    required this.serverId,
    required this.serverName,
    required this.totalShiftsInSection,
    required this.averagePerformanceWhenInSection,
    required this.performanceVariance,
    required this.strengths,
    required this.improvementAreas,
    required this.recommendation,
  });
}

/// Staffing recommendation
enum StaffingRecommendation {
  increase,
  maintain,
  decrease,
  train,
  reassign
}

/// Peak performance period
class PeakPerformancePeriod {
  final DateTime startDate;
  final DateTime endDate;
  final double peakScore;
  final String periodType; // "week", "month", "season"
  final List<String> contributingFactors;
  final String description;

  PeakPerformancePeriod({
    required this.startDate,
    required this.endDate,
    required this.peakScore,
    required this.periodType,
    required this.contributingFactors,
    required this.description,
  });
}

/// Capacity planning insights
class CapacityPlanningInsights {
  final int recommendedMinStaffing;
  final int recommendedMaxStaffing;
  final List<DateTime> highDemandPeriods;
  final List<DateTime> lowDemandPeriods;
  final double utilizationRate;
  final List<String> recommendations;
  final String summary;

  CapacityPlanningInsights({
    required this.recommendedMinStaffing,
    required this.recommendedMaxStaffing,
    required this.highDemandPeriods,
    required this.lowDemandPeriods,
    required this.utilizationRate,
    required this.recommendations,
    required this.summary,
  });
}

/// Historical insight
class HistoricalInsight {
  final String title;
  final String description;
  final InsightCategory category;
  final InsightPriority priority;
  final List<String> recommendations;
  final double confidence; // 0.0 to 1.0

  HistoricalInsight({
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.recommendations,
    required this.confidence,
  });
}

/// Insight categories
enum InsightCategory {
  seasonal,
  staffing,
  performance,
  capacity,
  trend,
  recommendation
}

/// Insight priority levels
enum InsightPriority {
  high,
  medium,
  low
}

class HistoricalStationAnalyticsService {
  static final HistoricalStationAnalyticsService _instance = HistoricalStationAnalyticsService._internal();
  factory HistoricalStationAnalyticsService() => _instance;
  HistoricalStationAnalyticsService._internal();

  /// Generate historical analysis for a section
  Future<HistoricalStationAnalysis> generateHistoricalAnalysis({
    required String sectionName,
    required String stationType,
    required List<ShiftRecord> shiftRecords,
    required List<Server> servers,
    required int monthsToAnalyze,
  }) async {
    try {
      d('[HistoricalStationAnalytics] Generating historical analysis for $sectionName');
      
      // Filter shift records for this section and time period
      final cutoffDate = DateTime.now().subtract(Duration(days: monthsToAnalyze * 30));
      final sectionShifts = _filterShiftsForSection(shiftRecords, sectionName, cutoffDate);
      
      // Generate seasonal patterns
      final seasonalPatterns = _generateSeasonalPatterns(sectionShifts);
      
      // Generate monthly trends
      final monthlyTrends = _generateMonthlyTrends(sectionShifts);
      
      // Generate staffing patterns
      final staffingPatterns = _generateStaffingPatterns(sectionShifts, servers);
      
      // Generate peak performance periods
      final peakPeriods = _generatePeakPerformancePeriods(sectionShifts);
      
      // Generate capacity planning insights
      final capacityInsights = _generateCapacityPlanningInsights(sectionShifts, monthlyTrends);
      
      // Generate historical insights
      final insights = _generateHistoricalInsights(
        seasonalPatterns,
        monthlyTrends,
        staffingPatterns,
        peakPeriods,
        capacityInsights,
      );
      
      return HistoricalStationAnalysis(
        sectionName: sectionName,
        stationType: stationType,
        seasonalPatterns: seasonalPatterns,
        monthlyTrends: monthlyTrends,
        staffingPatterns: staffingPatterns,
        peakPeriods: peakPeriods,
        capacityInsights: capacityInsights,
        insights: insights,
        analysisDate: DateTime.now(),
        totalMonthsAnalyzed: monthsToAnalyze,
      );
    } catch (e) {
      d('[HistoricalStationAnalytics] Error generating historical analysis: $e');
      rethrow;
    }
  }

  /// Filter shift records for a specific section and time period
  List<ShiftRecord> _filterShiftsForSection(List<ShiftRecord> shiftRecords, String sectionName, DateTime cutoffDate) {
    return shiftRecords.where((shift) {
      // Check if shift is within time period
      if (shift.start.isBefore(cutoffDate)) return false;
      
      // Check if shift has section assignments
      if (shift.sectionAssignments == null || shift.sectionAssignments!.isEmpty) return false;
      
      // Check if any server was assigned to this section
      return shift.sectionAssignments!.values.any((sections) => 
          sections.toLowerCase().contains(sectionName.toLowerCase()));
    }).toList();
  }

  /// Generate seasonal patterns
  List<SeasonalPattern> _generateSeasonalPatterns(List<ShiftRecord> shifts) {
    final patterns = <SeasonalPattern>[];
    final seasonData = <String, List<double>>{};
    
    // Group shifts by season
    for (final shift in shifts) {
      final season = _getSeason(shift.start);
      final performance = _calculateShiftPerformance(shift);
      
      seasonData.putIfAbsent(season, () => []).add(performance);
    }
    
    // Analyze each season
    for (final entry in seasonData.entries) {
      final season = entry.key;
      final performances = entry.value;
      
      if (performances.length < 3) continue; // Need at least 3 data points
      
      final average = performances.reduce((a, b) => a + b) / performances.length;
      final variance = _calculateVariance(performances, average);
      final trend = _analyzeSeasonalTrend(performances);
      final characteristics = _generateSeasonalCharacteristics(season, average, variance);
      
      patterns.add(SeasonalPattern(
        season: season,
        averagePerformance: average,
        performanceVariance: variance,
        characteristics: characteristics,
        trend: trend,
        description: _generateSeasonalDescription(season, average, trend),
      ));
    }
    
    return patterns;
  }

  /// Generate monthly trends
  List<MonthlyPerformance> _generateMonthlyTrends(List<ShiftRecord> shifts) {
    final monthlyData = <DateTime, List<ShiftRecord>>{};
    
    // Group shifts by month
    for (final shift in shifts) {
      final monthKey = DateTime(shift.start.year, shift.start.month);
      monthlyData.putIfAbsent(monthKey, () => []).add(shift);
    }
    
    final monthlyTrends = <MonthlyPerformance>[];
    final sortedMonths = monthlyData.keys.toList()..sort();
    
    for (int i = 0; i < sortedMonths.length; i++) {
      final month = sortedMonths[i];
      final monthShifts = monthlyData[month]!;
      
      final totalRuns = monthShifts.fold(0, (sum, shift) => 
          sum + shift.counts.values.fold(0, (s, runs) => s + runs));
      final totalShifts = monthShifts.length;
      final averageRunsPerShift = totalShifts > 0 ? totalRuns / totalShifts : 0.0;
      final performanceScore = _calculateMonthlyPerformanceScore(monthShifts);
      final npsScore = _calculateMonthlyNPSScore(monthShifts); // Placeholder
      final guestCount = _calculateMonthlyGuestCount(monthShifts); // Placeholder
      final salesVolume = _calculateMonthlySalesVolume(monthShifts); // Placeholder
      
      // Determine trend
      MonthlyTrend trend = MonthlyTrend.newData;
      if (i > 0) {
        final previousMonth = monthlyTrends[i - 1];
        if (performanceScore > previousMonth.performanceScore * 1.05) {
          trend = MonthlyTrend.improving;
        } else if (performanceScore < previousMonth.performanceScore * 0.95) {
          trend = MonthlyTrend.declining;
        } else {
          trend = MonthlyTrend.stable;
        }
      }
      
      monthlyTrends.add(MonthlyPerformance(
        month: month,
        performanceScore: performanceScore,
        totalRuns: totalRuns,
        totalShifts: totalShifts,
        averageRunsPerShift: averageRunsPerShift,
        npsScore: npsScore,
        guestCount: guestCount,
        salesVolume: salesVolume,
        trend: trend,
      ));
    }
    
    return monthlyTrends;
  }

  /// Generate staffing patterns
  List<StaffingPattern> _generateStaffingPatterns(List<ShiftRecord> shifts, List<Server> servers) {
    final patterns = <StaffingPattern>[];
    final serverPerformance = <String, List<double>>{};
    
    // Calculate performance for each server in this section
    for (final shift in shifts) {
      if (shift.sectionAssignments == null) continue;
      
      for (final entry in shift.sectionAssignments!.entries) {
        final serverId = entry.key;
        final sections = entry.value;
        
        if (sections.toLowerCase().contains('section')) {
          final performance = _calculateShiftPerformance(shift);
          serverPerformance.putIfAbsent(serverId, () => []).add(performance);
        }
      }
    }
    
    // Analyze each server's performance in this section
    for (final entry in serverPerformance.entries) {
      final serverId = entry.key;
      final performances = entry.value;
      
      if (performances.length < 2) continue; // Need at least 2 data points
      
      final server = servers.firstWhere((s) => s.id == serverId, orElse: () => Server(id: serverId, name: 'Unknown'));
      final averagePerformance = performances.reduce((a, b) => a + b) / performances.length;
      final variance = _calculateVariance(performances, averagePerformance);
      
      final strengths = _generateServerStrengths(averagePerformance, variance);
      final improvementAreas = _generateServerImprovementAreas(averagePerformance, variance);
      final recommendation = _generateStaffingRecommendation(averagePerformance, variance, performances.length);
      
      patterns.add(StaffingPattern(
        serverId: serverId,
        serverName: server.name,
        totalShiftsInSection: performances.length,
        averagePerformanceWhenInSection: averagePerformance,
        performanceVariance: variance,
        strengths: strengths,
        improvementAreas: improvementAreas,
        recommendation: recommendation,
      ));
    }
    
    return patterns;
  }

  /// Generate peak performance periods
  List<PeakPerformancePeriod> _generatePeakPerformancePeriods(List<ShiftRecord> shifts) {
    final periods = <PeakPerformancePeriod>[];
    
    if (shifts.length < 7) return periods; // Need at least a week of data
    
    // Group shifts by week
    final weeklyData = <DateTime, List<ShiftRecord>>{};
    for (final shift in shifts) {
      final weekStart = _getWeekStart(shift.start);
      weeklyData.putIfAbsent(weekStart, () => []).add(shift);
    }
    
    // Find peak weeks
    final weeklyScores = <DateTime, double>{};
    for (final entry in weeklyData.entries) {
      final weekShifts = entry.value;
      final score = _calculateWeeklyPerformanceScore(weekShifts);
      weeklyScores[entry.key] = score;
    }
    
    // Identify peaks (top 20% of weeks)
    final sortedScores = weeklyScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topCount = math.max(1, (sortedScores.length * 0.2).round());
    
    for (int i = 0; i < topCount; i++) {
      final entry = sortedScores[i];
      final weekStart = entry.key;
      final weekEnd = weekStart.add(const Duration(days: 6));
      final score = entry.value;
      
      periods.add(PeakPerformancePeriod(
        startDate: weekStart,
        endDate: weekEnd,
        peakScore: score,
        periodType: 'week',
        contributingFactors: _identifyPeakFactors(weeklyData[weekStart]!),
        description: _generatePeakDescription(score, weekStart),
      ));
    }
    
    return periods;
  }

  /// Generate capacity planning insights
  CapacityPlanningInsights _generateCapacityPlanningInsights(
    List<ShiftRecord> shifts,
    List<MonthlyPerformance> monthlyTrends,
  ) {
    if (shifts.isEmpty) {
      return CapacityPlanningInsights(
        recommendedMinStaffing: 1,
        recommendedMaxStaffing: 3,
        highDemandPeriods: [],
        lowDemandPeriods: [],
        utilizationRate: 0.0,
        recommendations: ['Insufficient data for capacity planning'],
        summary: 'No data available for capacity analysis',
      );
    }
    
    // Calculate utilization rates
    final utilizationRates = <double>[];
    for (final shift in shifts) {
      final totalRuns = shift.counts.values.fold(0, (sum, runs) => sum + runs);
      final maxCapacity = shift.counts.length * 20; // Assume 20 runs per server max
      final utilization = maxCapacity > 0 ? totalRuns / maxCapacity : 0.0;
      utilizationRates.add(utilization);
    }
    
    final avgUtilization = utilizationRates.reduce((a, b) => a + b) / utilizationRates.length;
    
    // Identify high/low demand periods
    final highDemandPeriods = <DateTime>[];
    final lowDemandPeriods = <DateTime>[];
    
    for (final month in monthlyTrends) {
      if (month.performanceScore > 80) {
        highDemandPeriods.add(month.month);
      } else if (month.performanceScore < 60) {
        lowDemandPeriods.add(month.month);
      }
    }
    
    // Calculate recommended staffing
    final avgServersPerShift = shifts.fold(0, (sum, shift) => sum + shift.counts.length) / shifts.length;
    final recommendedMin = math.max(1, (avgServersPerShift * 0.8).round());
    final recommendedMax = (avgServersPerShift * 1.5).round();
    
    // Generate recommendations
    final recommendations = <String>[];
    if (avgUtilization > 0.9) {
      recommendations.add('Consider increasing staffing during peak periods');
    } else if (avgUtilization < 0.6) {
      recommendations.add('Current staffing may be excessive for demand');
    }
    
    if (highDemandPeriods.length > lowDemandPeriods.length) {
      recommendations.add('Focus on capacity planning for high-demand periods');
    }
    
    return CapacityPlanningInsights(
      recommendedMinStaffing: recommendedMin,
      recommendedMaxStaffing: recommendedMax,
      highDemandPeriods: highDemandPeriods,
      lowDemandPeriods: lowDemandPeriods,
      utilizationRate: avgUtilization,
      recommendations: recommendations,
      summary: _generateCapacitySummary(avgUtilization, recommendedMin, recommendedMax),
    );
  }

  /// Generate historical insights
  List<HistoricalInsight> _generateHistoricalInsights(
    List<SeasonalPattern> seasonalPatterns,
    List<MonthlyPerformance> monthlyTrends,
    List<StaffingPattern> staffingPatterns,
    List<PeakPerformancePeriod> peakPeriods,
    CapacityPlanningInsights capacityInsights,
  ) {
    final insights = <HistoricalInsight>[];
    
    // Seasonal insights
    for (final pattern in seasonalPatterns) {
      if (pattern.trend == SeasonalTrend.improving) {
        insights.add(HistoricalInsight(
          title: 'Strong ${pattern.season} Performance',
          description: pattern.description,
          category: InsightCategory.seasonal,
          priority: InsightPriority.high,
          recommendations: ['Maintain current strategies for ${pattern.season}', 'Document best practices'],
          confidence: 0.8,
        ));
      } else if (pattern.trend == SeasonalTrend.declining) {
        insights.add(HistoricalInsight(
          title: '${pattern.season} Performance Decline',
          description: pattern.description,
          category: InsightCategory.seasonal,
          priority: InsightPriority.high,
          recommendations: ['Investigate causes of ${pattern.season} decline', 'Develop improvement plan'],
          confidence: 0.7,
        ));
      }
    }
    
    // Staffing insights
    for (final pattern in staffingPatterns) {
      if (pattern.recommendation == StaffingRecommendation.increase) {
        insights.add(HistoricalInsight(
          title: 'Increase ${pattern.serverName} in Section',
          description: '${pattern.serverName} shows strong performance in this section',
          category: InsightCategory.staffing,
          priority: InsightPriority.medium,
          recommendations: ['Schedule ${pattern.serverName} more frequently in this section'],
          confidence: 0.8,
        ));
      } else if (pattern.recommendation == StaffingRecommendation.train) {
        insights.add(HistoricalInsight(
          title: 'Training Needed for ${pattern.serverName}',
          description: '${pattern.serverName} shows potential but needs development',
          category: InsightCategory.staffing,
          priority: InsightPriority.medium,
          recommendations: ['Provide additional training for ${pattern.serverName}', 'Consider mentoring'],
          confidence: 0.6,
        ));
      }
    }
    
    // Capacity insights
    if (capacityInsights.utilizationRate > 0.9) {
      insights.add(HistoricalInsight(
        title: 'High Capacity Utilization',
        description: 'Section is operating at ${(capacityInsights.utilizationRate * 100).toStringAsFixed(0)}% capacity',
        category: InsightCategory.capacity,
        priority: InsightPriority.high,
        recommendations: capacityInsights.recommendations,
        confidence: 0.9,
      ));
    }
    
    // Peak performance insights
    if (peakPeriods.isNotEmpty) {
      insights.add(HistoricalInsight(
        title: 'Peak Performance Identified',
        description: 'Found ${peakPeriods.length} peak performance periods',
        category: InsightCategory.performance,
        priority: InsightPriority.medium,
        recommendations: ['Analyze peak periods for best practices', 'Replicate successful strategies'],
        confidence: 0.7,
      ));
    }
    
    return insights;
  }

  // Helper methods
  String _getSeason(DateTime date) {
    final month = date.month;
    if (month >= 3 && month <= 5) return 'Spring';
    if (month >= 6 && month <= 8) return 'Summer';
    if (month >= 9 && month <= 11) return 'Fall';
    return 'Winter';
  }

  double _calculateShiftPerformance(ShiftRecord shift) {
    final totalRuns = shift.counts.values.fold(0, (sum, runs) => sum + runs);
    final serverCount = shift.counts.length;
    return serverCount > 0 ? totalRuns / serverCount : 0.0;
  }

  double _calculateVariance(List<double> values, double mean) {
    if (values.length < 2) return 0.0;
    final squaredDiffs = values.map((v) => math.pow(v - mean, 2)).toList();
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  SeasonalTrend _analyzeSeasonalTrend(List<double> performances) {
    if (performances.length < 3) return SeasonalTrend.stable;
    
    final firstHalf = performances.take(performances.length ~/ 2).toList();
    final secondHalf = performances.skip(performances.length ~/ 2).toList();
    
    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
    
    final change = (secondAvg - firstAvg) / firstAvg;
    
    if (change > 0.1) return SeasonalTrend.improving;
    if (change < -0.1) return SeasonalTrend.declining;
    return SeasonalTrend.stable;
  }

  List<String> _generateSeasonalCharacteristics(String season, double average, double variance) {
    final characteristics = <String>[];
    
    if (average > 15) {
      characteristics.add('High performance');
    } else if (average < 10) {
      characteristics.add('Low performance');
    }
    
    if (variance < 5) {
      characteristics.add('Consistent');
    } else if (variance > 15) {
      characteristics.add('Variable');
    }
    
    characteristics.add('${season} pattern');
    
    return characteristics;
  }

  String _generateSeasonalDescription(String season, double average, SeasonalTrend trend) {
    final trendText = trend == SeasonalTrend.improving ? 'improving' : 
                     trend == SeasonalTrend.declining ? 'declining' : 'stable';
    return '$season shows $trendText performance with ${average.toStringAsFixed(1)} average runs per server';
  }

  double _calculateMonthlyPerformanceScore(List<ShiftRecord> shifts) {
    if (shifts.isEmpty) return 0.0;
    
    final totalRuns = shifts.fold(0, (sum, shift) => 
        sum + shift.counts.values.fold(0, (s, runs) => s + runs));
    final totalShifts = shifts.length;
    final avgServersPerShift = shifts.fold(0, (sum, shift) => sum + shift.counts.length) / shifts.length;
    
    return totalShifts > 0 ? (totalRuns / totalShifts) / avgServersPerShift : 0.0;
  }

  double _calculateMonthlyNPSScore(List<ShiftRecord> shifts) {
    // Placeholder - would integrate with NPS data
    return 75.0;
  }

  int _calculateMonthlyGuestCount(List<ShiftRecord> shifts) {
    // Placeholder - would calculate from actual guest data
    return shifts.length * 50; // Estimate 50 guests per shift
  }

  double _calculateMonthlySalesVolume(List<ShiftRecord> shifts) {
    // Placeholder - would calculate from actual sales data
    return shifts.fold(0.0, (sum, shift) => 
        sum + shift.counts.values.fold(0.0, (s, runs) => s + runs * 25.0)); // $25 per run estimate
  }

  List<String> _generateServerStrengths(double performance, double variance) {
    final strengths = <String>[];
    
    if (performance > 15) {
      strengths.add('High productivity');
    }
    if (variance < 5) {
      strengths.add('Consistent performance');
    }
    if (performance > 12 && variance < 8) {
      strengths.add('Reliable performer');
    }
    
    return strengths;
  }

  List<String> _generateServerImprovementAreas(double performance, double variance) {
    final areas = <String>[];
    
    if (performance < 10) {
      areas.add('Increase productivity');
    }
    if (variance > 10) {
      areas.add('Improve consistency');
    }
    if (performance < 12) {
      areas.add('Skill development');
    }
    
    return areas;
  }

  StaffingRecommendation _generateStaffingRecommendation(double performance, double variance, int shiftCount) {
    if (shiftCount < 3) return StaffingRecommendation.maintain;
    
    if (performance > 15 && variance < 5) return StaffingRecommendation.increase;
    if (performance < 8 || variance > 15) return StaffingRecommendation.train;
    if (performance < 5) return StaffingRecommendation.reassign;
    
    return StaffingRecommendation.maintain;
  }

  DateTime _getWeekStart(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  double _calculateWeeklyPerformanceScore(List<ShiftRecord> shifts) {
    return _calculateMonthlyPerformanceScore(shifts);
  }

  List<String> _identifyPeakFactors(List<ShiftRecord> shifts) {
    final factors = <String>[];
    
    final totalRuns = shifts.fold(0, (sum, shift) => 
        sum + shift.counts.values.fold(0, (s, runs) => s + runs));
    final avgRunsPerShift = totalRuns / shifts.length;
    
    if (avgRunsPerShift > 20) {
      factors.add('High run volume');
    }
    if (shifts.length > 5) {
      factors.add('Frequent scheduling');
    }
    
    return factors;
  }

  String _generatePeakDescription(double score, DateTime weekStart) {
    return 'Peak performance week starting ${weekStart.toString().split(' ')[0]} with score ${score.toStringAsFixed(1)}';
  }

  String _generateCapacitySummary(double utilization, int minStaff, int maxStaff) {
    return 'Utilization: ${(utilization * 100).toStringAsFixed(0)}%, Recommended staffing: $minStaff-$maxStaff servers';
  }
}
