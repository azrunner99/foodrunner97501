/// Station performance analytics data models
/// Supports the station analytics dashboard functionality

import 'package:flutter/foundation.dart';

/// Represents performance metrics for a specific station over a time period
class StationPerformanceMetric {
  final String stationId;
  final String stationType;
  final DateTime timestamp;
  final double efficiencyScore;
  final int totalRuns;
  final double averageRunTime;
  final int activeServers;
  final Map<String, double> serverContributions;
  final int totalHours;
  final double utilizationRate;

  const StationPerformanceMetric({
    required this.stationId,
    required this.stationType,
    required this.timestamp,
    required this.efficiencyScore,
    required this.totalRuns,
    required this.averageRunTime,
    required this.activeServers,
    required this.serverContributions,
    required this.totalHours,
    required this.utilizationRate,
  });

  /// Serialization support for persistence and data transfer
  Map<String, dynamic> toMap() {
    return {
      'stationId': stationId,
      'stationType': stationType,
      'timestamp': timestamp.toIso8601String(),
      'efficiencyScore': efficiencyScore,
      'totalRuns': totalRuns,
      'averageRunTime': averageRunTime,
      'activeServers': activeServers,
      'serverContributions': serverContributions,
      'totalHours': totalHours,
      'utilizationRate': utilizationRate,
    };
  }

  /// Deserialization from stored data
  factory StationPerformanceMetric.fromMap(Map<String, dynamic> map) {
    return StationPerformanceMetric(
      stationId: map['stationId'] ?? '',
      stationType: map['stationType'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      efficiencyScore: (map['efficiencyScore'] ?? 0.0).toDouble(),
      totalRuns: map['totalRuns'] ?? 0,
      averageRunTime: (map['averageRunTime'] ?? 0.0).toDouble(),
      activeServers: map['activeServers'] ?? 0,
      serverContributions: Map<String, double>.from(map['serverContributions'] ?? {}),
      totalHours: map['totalHours'] ?? 0,
      utilizationRate: (map['utilizationRate'] ?? 0.0).toDouble(),
    );
  }

  /// Calculate performance grade based on efficiency score
  String get performanceGrade {
    if (efficiencyScore >= 90) return 'A+';
    if (efficiencyScore >= 80) return 'A';
    if (efficiencyScore >= 70) return 'B';
    if (efficiencyScore >= 60) return 'C';
    return 'D';
  }

  /// Get color indicator for performance level
  String get performanceColor {
    if (efficiencyScore >= 80) return 'green';
    if (efficiencyScore >= 60) return 'yellow';
    return 'red';
  }

  @override
  String toString() {
    return 'StationPerformanceMetric(station: $stationType, efficiency: ${efficiencyScore.toStringAsFixed(1)}%, runs: $totalRuns)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StationPerformanceMetric &&
        other.stationId == stationId &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => stationId.hashCode ^ timestamp.hashCode;
}

/// Comparison data between different stations for relative performance analysis
class StationComparisonData {
  final String stationType;
  final double currentEfficiency;
  final double previousEfficiency;
  final double trendPercentage;
  final List<String> topPerformers;
  final List<String> improvementAreas;
  final int totalShifts;
  final DateTime lastUpdated;

  const StationComparisonData({
    required this.stationType,
    required this.currentEfficiency,
    required this.previousEfficiency,
    required this.trendPercentage,
    required this.topPerformers,
    required this.improvementAreas,
    required this.totalShifts,
    required this.lastUpdated,
  });

  /// Serialization support
  Map<String, dynamic> toMap() {
    return {
      'stationType': stationType,
      'currentEfficiency': currentEfficiency,
      'previousEfficiency': previousEfficiency,
      'trendPercentage': trendPercentage,
      'topPerformers': topPerformers,
      'improvementAreas': improvementAreas,
      'totalShifts': totalShifts,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Deserialization from stored data
  factory StationComparisonData.fromMap(Map<String, dynamic> map) {
    return StationComparisonData(
      stationType: map['stationType'] ?? '',
      currentEfficiency: (map['currentEfficiency'] ?? 0.0).toDouble(),
      previousEfficiency: (map['previousEfficiency'] ?? 0.0).toDouble(),
      trendPercentage: (map['trendPercentage'] ?? 0.0).toDouble(),
      topPerformers: List<String>.from(map['topPerformers'] ?? []),
      improvementAreas: List<String>.from(map['improvementAreas'] ?? []),
      totalShifts: map['totalShifts'] ?? 0,
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }

  /// Get trend direction indicator
  String get trendDirection {
    if (trendPercentage > 5) return 'up';
    if (trendPercentage < -5) return 'down';
    return 'stable';
  }

  /// Get trend description for display
  String get trendDescription {
    if (trendPercentage > 10) return 'Strong Improvement';
    if (trendPercentage > 5) return 'Improving';
    if (trendPercentage > -5) return 'Stable';
    if (trendPercentage > -10) return 'Declining';
    return 'Needs Attention';
  }

  /// Calculate efficiency change from previous period
  double get efficiencyChange => currentEfficiency - previousEfficiency;

  @override
  String toString() {
    return 'StationComparisonData(station: $stationType, efficiency: ${currentEfficiency.toStringAsFixed(1)}%, trend: ${trendPercentage.toStringAsFixed(1)}%)';
  }
}

/// Real-time station monitoring data for live dashboard updates
class RealTimeStationMetric {
  final String stationId;
  final String stationType;
  final DateTime timestamp;
  final int currentRuns;
  final int activeServers;
  final double currentRunRate; // runs per hour
  final List<String> serverIds;
  final bool isAlert; // performance alert status
  final String? alertMessage;

  const RealTimeStationMetric({
    required this.stationId,
    required this.stationType,
    required this.timestamp,
    required this.currentRuns,
    required this.activeServers,
    required this.currentRunRate,
    required this.serverIds,
    this.isAlert = false,
    this.alertMessage,
  });

  /// Create real-time metric from current app state
  factory RealTimeStationMetric.fromCurrentState({
    required String stationId,
    required String stationType,
    required Map<String, int> currentCounts,
    required List<String> stationServerIds,
    required DateTime timestamp,
  }) {
    final activeServers = stationServerIds.length;
    final currentRuns = stationServerIds.fold<int>(
      0, 
      (sum, serverId) => sum + (currentCounts[serverId] ?? 0),
    );
    
    // Calculate runs per hour based on shift duration
    final now = timestamp;
    final shiftStart = DateTime(now.year, now.month, now.day, 11, 0); // Assume 11 AM start
    final hoursElapsed = now.difference(shiftStart).inMinutes / 60.0;
    final currentRunRate = hoursElapsed > 0 ? currentRuns / hoursElapsed : 0.0;
    
    // Determine if alert needed (< 3 runs per hour per server)
    final expectedRunRate = activeServers * 3.0;
    final isAlert = currentRunRate < expectedRunRate * 0.7; // 70% of expected
    
    String? alertMessage;
    if (isAlert) {
      final deficit = (expectedRunRate * 0.7 - currentRunRate).toStringAsFixed(1);
      alertMessage = 'Performance below target by $deficit runs/hour';
    }
    
    return RealTimeStationMetric(
      stationId: stationId,
      stationType: stationType,
      timestamp: timestamp,
      currentRuns: currentRuns,
      activeServers: activeServers,
      currentRunRate: currentRunRate,
      serverIds: stationServerIds,
      isAlert: isAlert,
      alertMessage: alertMessage,
    );
  }

  /// Serialization support
  Map<String, dynamic> toMap() {
    return {
      'stationId': stationId,
      'stationType': stationType,
      'timestamp': timestamp.toIso8601String(),
      'currentRuns': currentRuns,
      'activeServers': activeServers,
      'currentRunRate': currentRunRate,
      'serverIds': serverIds,
      'isAlert': isAlert,
      'alertMessage': alertMessage,
    };
  }

  @override
  String toString() {
    return 'RealTimeStationMetric(station: $stationType, runs: $currentRuns, rate: ${currentRunRate.toStringAsFixed(1)}/hr)';
  }
}