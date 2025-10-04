import 'package:flutter/foundation.dart';
import 'package:food_runs_counter/services/enhanced_error_handling_service.dart';
import 'package:food_runs_counter/utils/log.dart';

/// Performance monitoring service
class PerformanceMonitoringService {
  static PerformanceMonitoringService? _instance;
  static PerformanceMonitoringService get instance => _instance ??= PerformanceMonitoringService._();
  
  PerformanceMonitoringService._();

  final List<PerformanceMetric> _metrics = [];
  final List<PerformanceAlert> _alerts = [];

  /// Initialize the service
  Future<void> initialize() async {
    d('[PerformanceMonitoringService] Initialized');
  }

  /// Record a performance metric
  Future<void> recordMetric(
    String name,
    double value, {
    String? category,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final metric = PerformanceMetric(
        name: name,
        value: value,
        category: category ?? 'General',
        metadata: metadata ?? {},
        timestamp: DateTime.now(),
      );

      _metrics.add(metric);
      
      // Keep only last 1000 metrics
      if (_metrics.length > 1000) {
        _metrics.removeRange(0, _metrics.length - 1000);
      }
      
    } catch (e) {
      await EnhancedErrorHandlingService.instance.handleError(
        'performance_metric_recording_failed',
        'Failed to record performance metric: $name',
        context: 'PerformanceMonitoringService',
        metadata: {'name': name, 'value': value, 'error': e.toString()},
        severity: ErrorSeverity.medium,
      );
    }
  }

  /// Record data quality metric
  Future<void> recordDataQualityMetric(
    String dataSource,
    double qualityScore, {
    Map<String, dynamic>? metadata,
  }) async {
    await recordMetric(
      'data_quality_$dataSource',
      qualityScore,
      category: 'DataQuality',
      metadata: {
        'dataSource': dataSource,
        'qualityScore': qualityScore,
        ...?metadata,
      },
    );
  }

  /// Get performance statistics
  PerformanceStatistics getStatistics() {
    final recentMetrics = _metrics.where((m) => 
      DateTime.now().difference(m.timestamp).inDays <= 1).toList();
    
    return PerformanceStatistics(
      totalMetrics: _metrics.length,
      recentMetrics: recentMetrics.length,
      activeAlerts: _alerts.where((a) => !a.acknowledged).length,
      totalAlerts: _alerts.length,
    );
  }

  /// Get active alerts
  List<PerformanceAlert> getActiveAlerts() {
    return _alerts.where((a) => !a.acknowledged).toList();
  }

  /// Clear old data
  Future<void> clearOldData({Duration? olderThan}) async {
    final cutoff = olderThan ?? Duration(days: 30);
    final cutoffDate = DateTime.now().subtract(cutoff);
    
    _metrics.removeWhere((m) => m.timestamp.isBefore(cutoffDate));
    _alerts.removeWhere((a) => a.timestamp.isBefore(cutoffDate));
    
    d('[PerformanceMonitoringService] Cleared data older than $cutoff');
  }
}

/// Performance metric
class PerformanceMetric {
  final String name;
  final double value;
  final String category;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  PerformanceMetric({
    required this.name,
    required this.value,
    required this.category,
    required this.metadata,
    required this.timestamp,
  });
}

/// Performance alert
class PerformanceAlert {
  final String id;
  final String message;
  final PerformanceAlertSeverity severity;
  final String category;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  bool acknowledged;

  PerformanceAlert({
    required this.id,
    required this.message,
    required this.severity,
    required this.category,
    required this.metadata,
    required this.timestamp,
    this.acknowledged = false,
  });
}

/// Performance statistics
class PerformanceStatistics {
  final int totalMetrics;
  final int recentMetrics;
  final int activeAlerts;
  final int totalAlerts;

  PerformanceStatistics({
    required this.totalMetrics,
    required this.recentMetrics,
    required this.activeAlerts,
    required this.totalAlerts,
  });
}

/// Performance alert severity
enum PerformanceAlertSeverity {
  info,
  warning,
  critical,
}