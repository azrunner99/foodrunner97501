import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../utils/log.dart';

/// Enhanced error handling service
/// 
/// This service provides comprehensive error handling, user feedback,
/// and error recovery mechanisms across the application.
class EnhancedErrorHandlingService {
  static EnhancedErrorHandlingService? _instance;
  static EnhancedErrorHandlingService get instance => _instance ??= EnhancedErrorHandlingService._();
  
  EnhancedErrorHandlingService._();

  final List<ErrorLog> _errorLogs = [];
  final List<RecoveryAction> _recoveryActions = [];

  /// Handle and log an error with context
  Future<void> handleError(
    String errorId,
    String message, {
    String? context,
    Map<String, dynamic>? metadata,
    ErrorSeverity severity = ErrorSeverity.medium,
    bool showToUser = true,
    String? recoveryAction,
  }) async {
    try {
      final errorLog = ErrorLog(
        id: errorId,
        message: message,
        context: context ?? 'Unknown',
        metadata: metadata ?? {},
        severity: severity,
        timestamp: DateTime.now(),
        recoveryAction: recoveryAction,
      );

      _errorLogs.add(errorLog);
      
      // Log to console in debug mode
      if (kDebugMode) {
        d('[ErrorHandler] $errorId: $message');
        if (context != null) d('[ErrorHandler] Context: $context');
        if (metadata != null) d('[ErrorHandler] Metadata: $metadata');
      }

      // Store error in persistent storage
      await _storeErrorLog(errorLog);

      // Show user notification if requested
      if (showToUser) {
        await _showUserNotification(errorLog);
      }

      // Attempt recovery if action is provided
      if (recoveryAction != null) {
        await _attemptRecovery(errorLog);
      }

    } catch (e) {
      // Fallback error handling
      d('[ErrorHandler] Failed to handle error: $e');
    }
  }

  /// Handle data validation errors
  Future<void> handleValidationError(
    String serverId,
    String serverName,
    List<ValidationIssue> issues,
    List<ValidationWarning> warnings,
  ) async {
    final criticalIssues = issues.where((i) => i.severity == ValidationSeverity.critical).toList();
    final highIssues = issues.where((i) => i.severity == ValidationSeverity.high).toList();

    if (criticalIssues.isNotEmpty) {
      await handleError(
        'validation_critical_$serverId',
        'Critical validation issues found for $serverName',
        context: 'DataValidation',
        metadata: {
          'serverId': serverId,
          'serverName': serverName,
          'criticalIssues': criticalIssues.length,
          'issues': issues.map((i) => i.message).toList(),
        },
        severity: ErrorSeverity.critical,
        recoveryAction: 'validate_data_sources',
      );
    } else if (highIssues.isNotEmpty) {
      await handleError(
        'validation_high_$serverId',
        'High priority validation issues found for $serverName',
        context: 'DataValidation',
        metadata: {
          'serverId': serverId,
          'serverName': serverName,
          'highIssues': highIssues.length,
          'issues': issues.map((i) => i.message).toList(),
        },
        severity: ErrorSeverity.high,
        recoveryAction: 'review_data_quality',
      );
    } else if (warnings.isNotEmpty) {
      await handleError(
        'validation_warnings_$serverId',
        'Data quality warnings for $serverName',
        context: 'DataValidation',
        metadata: {
          'serverId': serverId,
          'serverName': serverName,
          'warnings': warnings.length,
          'warningsList': warnings.map((w) => w.message).toList(),
        },
        severity: ErrorSeverity.low,
        showToUser: false,
      );
    }
  }

  /// Handle data loading errors
  Future<void> handleDataLoadingError(
    String dataSource,
    String operation,
    dynamic error, {
    Map<String, dynamic>? context,
  }) async {
    await handleError(
      'data_loading_${dataSource}_${DateTime.now().millisecondsSinceEpoch}',
      'Failed to load data from $dataSource during $operation',
      context: 'DataLoading',
      metadata: {
        'dataSource': dataSource,
        'operation': operation,
        'error': error.toString(),
        ...?context,
      },
      severity: ErrorSeverity.high,
      recoveryAction: 'retry_data_loading',
    );
  }

  /// Handle performance calculation errors
  Future<void> handlePerformanceCalculationError(
    String serverId,
    String operation,
    dynamic error,
  ) async {
    await handleError(
      'performance_calc_${serverId}_${DateTime.now().millisecondsSinceEpoch}',
      'Failed to calculate performance for server $serverId during $operation',
      context: 'PerformanceCalculation',
      metadata: {
        'serverId': serverId,
        'operation': operation,
        'error': error.toString(),
      },
      severity: ErrorSeverity.medium,
      recoveryAction: 'recalculate_performance',
    );
  }

  /// Show user notification for error
  Future<void> _showUserNotification(ErrorLog errorLog) async {
    // This would integrate with the UI to show user notifications
    // For now, we'll just log the notification
    d('[ErrorHandler] User notification: ${errorLog.message}');
  }

  /// Attempt error recovery
  Future<void> _attemptRecovery(ErrorLog errorLog) async {
    try {
      switch (errorLog.recoveryAction) {
        case 'validate_data_sources':
          await _recoverDataValidation();
          break;
        case 'review_data_quality':
          await _recoverDataQuality();
          break;
        case 'retry_data_loading':
          await _recoverDataLoading();
          break;
        case 'recalculate_performance':
          await _recoverPerformanceCalculation();
          break;
        default:
          d('[ErrorHandler] Unknown recovery action: ${errorLog.recoveryAction}');
      }
    } catch (e) {
      d('[ErrorHandler] Recovery failed: $e');
    }
  }

  /// Recover from data validation errors
  Future<void> _recoverDataValidation() async {
    d('[ErrorHandler] Attempting data validation recovery...');
    // Implement data validation recovery logic
  }

  /// Recover from data quality issues
  Future<void> _recoverDataQuality() async {
    d('[ErrorHandler] Attempting data quality recovery...');
    // Implement data quality recovery logic
  }

  /// Recover from data loading errors
  Future<void> _recoverDataLoading() async {
    d('[ErrorHandler] Attempting data loading recovery...');
    // Implement data loading recovery logic
  }

  /// Recover from performance calculation errors
  Future<void> _recoverPerformanceCalculation() async {
    d('[ErrorHandler] Attempting performance calculation recovery...');
    // Implement performance calculation recovery logic
  }

  /// Store error log in persistent storage
  Future<void> _storeErrorLog(ErrorLog errorLog) async {
    // This would store the error log in persistent storage
    // For now, we'll just keep it in memory
    d('[ErrorHandler] Stored error log: ${errorLog.id}');
  }

  /// Get error statistics
  ErrorStatistics getErrorStatistics() {
    final now = DateTime.now();
    final last24Hours = now.subtract(Duration(hours: 24));
    final last7Days = now.subtract(Duration(days: 7));

    final recentErrors = _errorLogs.where((e) => e.timestamp.isAfter(last24Hours)).toList();
    final weeklyErrors = _errorLogs.where((e) => e.timestamp.isAfter(last7Days)).toList();

    return ErrorStatistics(
      totalErrors: _errorLogs.length,
      recentErrors: recentErrors.length,
      weeklyErrors: weeklyErrors.length,
      criticalErrors: _errorLogs.where((e) => e.severity == ErrorSeverity.critical).length,
      highErrors: _errorLogs.where((e) => e.severity == ErrorSeverity.high).length,
      mediumErrors: _errorLogs.where((e) => e.severity == ErrorSeverity.medium).length,
      lowErrors: _errorLogs.where((e) => e.severity == ErrorSeverity.low).length,
      lastError: _errorLogs.isNotEmpty ? _errorLogs.last.timestamp : null,
    );
  }

  /// Get recent errors
  List<ErrorLog> getRecentErrors({int limit = 10}) {
    final sortedErrors = List<ErrorLog>.from(_errorLogs);
    sortedErrors.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sortedErrors.take(limit).toList();
  }

  /// Clear old error logs
  Future<void> clearOldErrorLogs({Duration? olderThan}) async {
    final cutoff = olderThan ?? Duration(days: 30);
    final cutoffDate = DateTime.now().subtract(cutoff);
    
    _errorLogs.removeWhere((error) => error.timestamp.isBefore(cutoffDate));
    
    d('[ErrorHandler] Cleared error logs older than $cutoff');
  }
}

/// Error log entry
class ErrorLog {
  final String id;
  final String message;
  final String context;
  final Map<String, dynamic> metadata;
  final ErrorSeverity severity;
  final DateTime timestamp;
  final String? recoveryAction;

  ErrorLog({
    required this.id,
    required this.message,
    required this.context,
    required this.metadata,
    required this.severity,
    required this.timestamp,
    this.recoveryAction,
  });
}

/// Recovery action
class RecoveryAction {
  final String id;
  final String name;
  final String description;
  final Future<void> Function() action;

  RecoveryAction({
    required this.id,
    required this.name,
    required this.description,
    required this.action,
  });
}

/// Error statistics
class ErrorStatistics {
  final int totalErrors;
  final int recentErrors;
  final int weeklyErrors;
  final int criticalErrors;
  final int highErrors;
  final int mediumErrors;
  final int lowErrors;
  final DateTime? lastError;

  ErrorStatistics({
    required this.totalErrors,
    required this.recentErrors,
    required this.weeklyErrors,
    required this.criticalErrors,
    required this.highErrors,
    required this.mediumErrors,
    required this.lowErrors,
    this.lastError,
  });
}

/// Error severity levels
enum ErrorSeverity {
  low,
  medium,
  high,
  critical,
}

/// Validation severity (imported from data_validation_service.dart)
enum ValidationSeverity {
  none,
  low,
  medium,
  high,
  critical,
}

/// Validation issue (imported from data_validation_service.dart)
class ValidationIssue {
  final ValidationIssueType type;
  final ValidationSeverity severity;
  final String message;
  final String field;
  final String suggestedAction;

  ValidationIssue({
    required this.type,
    required this.severity,
    required this.message,
    required this.field,
    required this.suggestedAction,
  });
}

/// Validation warning (imported from data_validation_service.dart)
class ValidationWarning {
  final ValidationWarningType type;
  final String message;
  final String field;
  final String suggestedAction;

  ValidationWarning({
    required this.type,
    required this.message,
    required this.field,
    required this.suggestedAction,
  });
}

/// Validation issue types (imported from data_validation_service.dart)
enum ValidationIssueType {
  missingData,
  dataInconsistency,
  dataOutOfRange,
  systemError,
  performanceIssue,
}

/// Validation warning types (imported from data_validation_service.dart)
enum ValidationWarningType {
  dataQuality,
  performance,
  consistency,
  recommendation,
}

