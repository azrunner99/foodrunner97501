/// Missing classes for intelligent performance classification system
/// These classes are required by IntelligentPerformanceClassifier
import 'package:flutter/material.dart';

/// Alert severity levels (used by performance alert system)
enum AlertSeverity { 
  info,
  low, 
  warning,
  medium, 
  high, 
  critical,
  emergency
}

/// Performance analytics summary for monitoring dashboard
class PerformanceAnalyticsSummary {
  final int totalServers;
  final double averagePerformanceScore;
  final Map<String, int> tierDistribution;
  final List<String> topPerformers;
  final List<String> needsAttention;
  final DateTime lastAnalysis;
  final double teamConsistency;
  final double dataQuality;
  
  // Additional properties for dashboard compatibility
  final Map<String, dynamic> systemHealth;
  final Map<String, double> averageScores;
  final Map<String, int> scoreDistribution;
  final Map<String, dynamic> trendMetrics;
  final List<String> bottomPerformers;

  PerformanceAnalyticsSummary({
    required this.totalServers,
    required this.averagePerformanceScore,
    required this.tierDistribution,
    required this.topPerformers,
    required this.needsAttention,
    required this.lastAnalysis,
    required this.teamConsistency,
    required this.dataQuality,
    this.systemHealth = const {},
    this.averageScores = const {},
    this.scoreDistribution = const {},
    this.trendMetrics = const {},
    this.bottomPerformers = const [],
  });

  /// Create empty summary for initialization
  static PerformanceAnalyticsSummary empty() => PerformanceAnalyticsSummary(
    totalServers: 0,
    averagePerformanceScore: 0.0,
    tierDistribution: {},
    topPerformers: [],
    needsAttention: [],
    lastAnalysis: DateTime.now(),
    teamConsistency: 0.0,
    dataQuality: 0.0,
  );
}

/// Performance alert for the monitoring system
class PerformanceAlert {
  final String id;
  final String serverId;
  final String serverName;
  final AlertSeverity severity;
  final String title;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  
  PerformanceAlert({
    required this.id,
    required this.serverId,
    required this.serverName,
    required this.severity,
    required this.title,
    required this.message,
    required this.timestamp,
    this.metadata = const {},
  });
  
  /// Get description (same as message for compatibility)
  String get description => message;
  
  /// Get age in minutes
  int get ageInMinutes => DateTime.now().difference(timestamp).inMinutes;
  
  /// Get color for alert severity
  Color get severityColor {
    switch (severity) {
      case AlertSeverity.info:
      case AlertSeverity.low:
        return Colors.blue;
      case AlertSeverity.warning:
      case AlertSeverity.medium:
        return Colors.orange;
      case AlertSeverity.high:
        return Colors.red;
      case AlertSeverity.critical:
      case AlertSeverity.emergency:
        return Colors.red.shade900;
    }
  }
}