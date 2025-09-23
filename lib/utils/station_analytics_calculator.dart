/// Station analytics calculation utilities
/// Mathematical operations and statistical analysis for station performance

import 'dart:math' as math;
import '../models.dart';
import '../models/station_performance_metric.dart';

class StationAnalyticsCalculator {
  
  /// Calculate efficiency score for a station based on performance metrics
  /// Formula: (totalRuns / totalHours) * utilizationFactor * qualityFactor
  static double calculateStationEfficiency({
    required int totalRuns,
    required double totalHours,
    required int activeServers,
    required int scheduledServers,
    double qualityFactor = 1.0,
  }) {
    if (totalHours <= 0 || scheduledServers <= 0) return 0.0;
    
    // Base efficiency: runs per hour
    final runsPerHour = totalRuns / totalHours;
    
    // Utilization factor: how well staffed the station was
    final utilizationFactor = activeServers / scheduledServers;
    
    // Calculate raw efficiency
    final rawEfficiency = runsPerHour * utilizationFactor * qualityFactor;
    
    // Convert to percentage (assuming 5 runs/hour/server as 100% benchmark)
    final benchmarkRunsPerHour = 5.0;
    final efficiencyPercentage = (rawEfficiency / benchmarkRunsPerHour) * 100;
    
    // Cap at 150% to handle exceptional performance
    return math.min(efficiencyPercentage, 150.0);
  }

  /// Calculate trend percentage between two time periods
  static double calculateTrendPercentage(double current, double previous) {
    if (previous <= 0) return current > 0 ? 100.0 : 0.0;
    return ((current - previous) / previous) * 100;
  }

  /// Calculate moving average for trend smoothing
  static List<double> calculateMovingAverage(List<double> values, int windowSize) {
    if (values.length < windowSize) return values;
    
    final result = <double>[];
    for (int i = windowSize - 1; i < values.length; i++) {
      double sum = 0;
      for (int j = i - windowSize + 1; j <= i; j++) {
        sum += values[j];
      }
      result.add(sum / windowSize);
    }
    return result;
  }

  /// Calculate standard deviation for performance consistency analysis
  static double calculateStandardDeviation(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final sumSquaredDifferences = values
        .map((value) => math.pow(value - mean, 2))
        .reduce((a, b) => a + b);
    
    return math.sqrt(sumSquaredDifferences / values.length);
  }

  /// Calculate correlation coefficient between two data series
  static double calculateCorrelation(List<double> x, List<double> y) {
    if (x.length != y.length || x.isEmpty) return 0.0;
    
    final n = x.length;
    final meanX = x.reduce((a, b) => a + b) / n;
    final meanY = y.reduce((a, b) => a + b) / n;
    
    double numerator = 0;
    double sumXSquared = 0;
    double sumYSquared = 0;
    
    for (int i = 0; i < n; i++) {
      final deltaX = x[i] - meanX;
      final deltaY = y[i] - meanY;
      numerator += deltaX * deltaY;
      sumXSquared += deltaX * deltaX;
      sumYSquared += deltaY * deltaY;
    }
    
    final denominator = math.sqrt(sumXSquared * sumYSquared);
    return denominator != 0 ? numerator / denominator : 0.0;
  }

  /// Calculate server contribution to station performance
  static Map<String, double> calculateServerContributions(
    Map<String, int> serverCounts,
    int totalStationRuns,
  ) {
    if (totalStationRuns == 0) return {};
    
    return serverCounts.map((serverId, runs) => 
      MapEntry(serverId, (runs / totalStationRuns) * 100));
  }

  /// Calculate utilization rate for a station
  static double calculateUtilizationRate({
    required int activeServers,
    required int scheduledServers,
    required double activeHours,
    required double scheduledHours,
  }) {
    if (scheduledServers == 0 || scheduledHours == 0) return 0.0;
    
    final serverUtilization = activeServers / scheduledServers;
    final timeUtilization = activeHours / scheduledHours;
    
    // Average of server and time utilization
    return (serverUtilization + timeUtilization) / 2 * 100;
  }

  /// Calculate performance consistency score (lower standard deviation = higher consistency)
  static double calculateConsistencyScore(List<double> performanceValues) {
    if (performanceValues.length < 2) return 100.0;
    
    final standardDev = calculateStandardDeviation(performanceValues);
    final mean = performanceValues.reduce((a, b) => a + b) / performanceValues.length;
    
    if (mean == 0) return 0.0;
    
    // Coefficient of variation (lower = more consistent)
    final coefficientOfVariation = standardDev / mean;
    
    // Convert to consistency score (0-100, higher = more consistent)
    return math.max(0, 100 - (coefficientOfVariation * 100));
  }

  /// Calculate peak performance hours for a station
  static Map<int, double> calculatePeakHours(List<ShiftRecord> records) {
    final hourlyPerformance = <int, List<double>>{};
    
    for (final record in records) {
      final hour = record.start.hour;
      final totalRuns = record.counts.values.fold<int>(0, (sum, count) => sum + count);
      final shiftDuration = 1.0; // Assume 1-hour intervals for this calculation
      final performance = totalRuns / shiftDuration;
      
      hourlyPerformance.putIfAbsent(hour, () => []).add(performance);
    }
    
    return hourlyPerformance.map((hour, performances) => 
      MapEntry(hour, performances.reduce((a, b) => a + b) / performances.length));
  }

  /// Calculate improvement potential based on historical data
  static double calculateImprovementPotential({
    required double currentEfficiency,
    required List<double> historicalEfficiencies,
    required double benchmarkEfficiency,
  }) {
    if (historicalEfficiencies.isEmpty) return 0.0;
    
    final maxHistorical = historicalEfficiencies.reduce(math.max);
    final averageHistorical = historicalEfficiencies.reduce((a, b) => a + b) / historicalEfficiencies.length;
    
    // Potential is the difference between current and realistic target
    final realisticTarget = math.min(
      math.max(maxHistorical, averageHistorical * 1.2), // 20% above average or historical max
      benchmarkEfficiency, // But not above benchmark
    );
    
    return math.max(0, realisticTarget - currentEfficiency);
  }

  /// Calculate weighted efficiency score considering multiple factors
  static double calculateWeightedEfficiency({
    required double baseEfficiency,
    required double consistencyScore,
    required double utilizationRate,
    double efficiencyWeight = 0.5,
    double consistencyWeight = 0.3,
    double utilizationWeight = 0.2,
  }) {
    return (baseEfficiency * efficiencyWeight) +
           (consistencyScore * consistencyWeight) +
           (utilizationRate * utilizationWeight);
  }

  /// Get performance metrics summary for display
  static Map<String, dynamic> getPerformanceSummary(
    List<StationPerformanceMetric> metrics,
  ) {
    if (metrics.isEmpty) {
      return {
        'averageEfficiency': 0.0,
        'totalRuns': 0,
        'totalHours': 0,
        'consistencyScore': 0.0,
        'trendDirection': 'stable',
        'improvementAreas': <String>[],
      };
    }
    
    final efficiencies = metrics.map((m) => m.efficiencyScore).toList();
    final totalRuns = metrics.fold<int>(0, (sum, m) => sum + m.totalRuns);
    final totalHours = metrics.fold<int>(0, (sum, m) => sum + m.totalHours);
    
    final averageEfficiency = efficiencies.reduce((a, b) => a + b) / efficiencies.length;
    final consistencyScore = calculateConsistencyScore(efficiencies);
    
    // Determine trend direction
    String trendDirection = 'stable';
    if (efficiencies.length >= 2) {
      final recent = efficiencies.last;
      final previous = efficiencies[efficiencies.length - 2];
      final change = calculateTrendPercentage(recent, previous);
      
      if (change > 5) trendDirection = 'improving';
      else if (change < -5) trendDirection = 'declining';
    }
    
    // Identify improvement areas
    final improvementAreas = <String>[];
    if (averageEfficiency < 70) improvementAreas.add('Overall Efficiency');
    if (consistencyScore < 60) improvementAreas.add('Performance Consistency');
    if (totalRuns < 50) improvementAreas.add('Volume Output');
    
    return {
      'averageEfficiency': averageEfficiency,
      'totalRuns': totalRuns,
      'totalHours': totalHours,
      'consistencyScore': consistencyScore,
      'trendDirection': trendDirection,
      'improvementAreas': improvementAreas,
    };
  }

  /// Calculate station ranking based on multiple criteria
  static List<String> rankStations(
    Map<String, StationPerformanceMetric> stationMetrics,
  ) {
    final rankings = stationMetrics.entries.map((entry) {
      final metric = entry.value;
      final score = calculateWeightedEfficiency(
        baseEfficiency: metric.efficiencyScore,
        consistencyScore: 100 - (metric.efficiencyScore * 0.1), // Simplified consistency
        utilizationRate: metric.utilizationRate,
      );
      return MapEntry(entry.key, score);
    }).toList();
    
    rankings.sort((a, b) => b.value.compareTo(a.value));
    return rankings.map((entry) => entry.key).toList();
  }
}