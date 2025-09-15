import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math';

/// Audit log levels for categorizing log entries
enum AuditLogLevel {
  info,
  warning,
  error,
  critical,
  security,
}

/// Audit event categories
enum AuditCategory {
  authentication,
  authorization,
  dataAccess,
  dataModification,
  dataExport,
  systemConfiguration,
  userManagement,
  security,
  compliance,
  backup,
  reporting,
  notification,
}

/// Audit log entry with comprehensive tracking
class AuditLogEntry {
  final String id;
  final DateTime timestamp;
  final String userId;
  final String userName;
  final String sessionId;
  final AuditLogLevel level;
  final AuditCategory category;
  final String action;
  final String resource;
  final String description;
  final Map<String, dynamic> details;
  final Map<String, dynamic> beforeState;
  final Map<String, dynamic> afterState;
  final String ipAddress;
  final String userAgent;
  final bool success;
  final String? errorMessage;
  final Duration? processingTime;
  final Map<String, dynamic> metadata;

  const AuditLogEntry({
    required this.id,
    required this.timestamp,
    required this.userId,
    required this.userName,
    required this.sessionId,
    required this.level,
    required this.category,
    required this.action,
    required this.resource,
    required this.description,
    this.details = const {},
    this.beforeState = const {},
    this.afterState = const {},
    required this.ipAddress,
    required this.userAgent,
    required this.success,
    this.errorMessage,
    this.processingTime,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'userName': userName,
      'sessionId': sessionId,
      'level': level.name,
      'category': category.name,
      'action': action,
      'resource': resource,
      'description': description,
      'details': details,
      'beforeState': beforeState,
      'afterState': afterState,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'success': success,
      'errorMessage': errorMessage,
      'processingTimeMs': processingTime?.inMilliseconds,
      'metadata': metadata,
    };
  }

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      userId: json['userId'],
      userName: json['userName'],
      sessionId: json['sessionId'],
      level: AuditLogLevel.values.firstWhere((l) => l.name == json['level']),
      category: AuditCategory.values.firstWhere((c) => c.name == json['category']),
      action: json['action'],
      resource: json['resource'],
      description: json['description'],
      details: json['details'] ?? {},
      beforeState: json['beforeState'] ?? {},
      afterState: json['afterState'] ?? {},
      ipAddress: json['ipAddress'],
      userAgent: json['userAgent'],
      success: json['success'],
      errorMessage: json['errorMessage'],
      processingTime: json['processingTimeMs'] != null 
          ? Duration(milliseconds: json['processingTimeMs']) 
          : null,
      metadata: json['metadata'] ?? {},
    );
  }

  /// Get severity score for prioritizing logs
  int get severityScore {
    switch (level) {
      case AuditLogLevel.critical:
        return 5;
      case AuditLogLevel.security:
        return 4;
      case AuditLogLevel.error:
        return 3;
      case AuditLogLevel.warning:
        return 2;
      case AuditLogLevel.info:
        return 1;
    }
  }

  /// Check if this is a security-relevant log
  bool get isSecurityRelevant {
    return level == AuditLogLevel.security ||
           category == AuditCategory.authentication ||
           category == AuditCategory.authorization ||
           category == AuditCategory.security ||
           !success;
  }
}

/// Audit query parameters for filtering logs
class AuditQuery {
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? userIds;
  final List<AuditLogLevel>? levels;
  final List<AuditCategory>? categories;
  final List<String>? actions;
  final List<String>? resources;
  final bool? successOnly;
  final bool? securityOnly;
  final int? limit;
  final int? offset;
  final String? searchTerm;

  const AuditQuery({
    this.startDate,
    this.endDate,
    this.userIds,
    this.levels,
    this.categories,
    this.actions,
    this.resources,
    this.successOnly,
    this.securityOnly,
    this.limit,
    this.offset,
    this.searchTerm,
  });
}

/// Audit configuration settings
class AuditConfig {
  final bool enabled;
  final Duration retentionPeriod;
  final int maxLogEntries;
  final bool enableRealTimeAlerts;
  final List<AuditLogLevel> alertLevels;
  final bool enableCompression;
  final bool enableEncryption;
  final bool enableRemoteBackup;
  final Duration backupInterval;
  final Map<AuditCategory, bool> categoryFilters;

  const AuditConfig({
    this.enabled = true,
    this.retentionPeriod = const Duration(days: 365 * 7), // 7 years
    this.maxLogEntries = 1000000,
    this.enableRealTimeAlerts = true,
    this.alertLevels = const [AuditLogLevel.error, AuditLogLevel.critical, AuditLogLevel.security],
    this.enableCompression = true,
    this.enableEncryption = true,
    this.enableRemoteBackup = false,
    this.backupInterval = const Duration(days: 1),
    this.categoryFilters = const {},
  });

  bool shouldLogCategory(AuditCategory category) {
    return categoryFilters[category] ?? true;
  }
}

/// Audit trail integrity verification
class AuditIntegrityCheck {
  final String id;
  final DateTime timestamp;
  final int totalEntries;
  final String checksum;
  final bool isValid;
  final List<String> tamperedEntries;
  final Map<String, dynamic> statistics;

  const AuditIntegrityCheck({
    required this.id,
    required this.timestamp,
    required this.totalEntries,
    required this.checksum,
    required this.isValid,
    required this.tamperedEntries,
    required this.statistics,
  });
}

/// Comprehensive audit logging service
class NPSAuditService extends ChangeNotifier {
  final List<AuditLogEntry> _auditLogs = [];
  final List<AuditIntegrityCheck> _integrityChecks = [];
  AuditConfig _config = const AuditConfig();
  final Random _random = Random.secure();
  int _logCounter = 0;

  // Getters
  List<AuditLogEntry> get auditLogs => List.unmodifiable(_auditLogs);
  List<AuditIntegrityCheck> get integrityChecks => List.unmodifiable(_integrityChecks);
  AuditConfig get config => _config;
  
  /// Initialize audit service
  void initialize() {
    _log(
      userId: 'SYSTEM',
      userName: 'System',
      sessionId: 'system_init',
      level: AuditLogLevel.info,
      category: AuditCategory.systemConfiguration,
      action: 'AUDIT_SERVICE_INITIALIZED',
      resource: 'audit_service',
      description: 'NPS Audit Service initialized successfully',
      ipAddress: '127.0.0.1',
      userAgent: 'System',
    );
  }

  /// Log an audit entry
  void log({
    required String userId,
    required String userName,
    required String sessionId,
    required AuditLogLevel level,
    required AuditCategory category,
    required String action,
    required String resource,
    required String description,
    Map<String, dynamic> details = const {},
    Map<String, dynamic> beforeState = const {},
    Map<String, dynamic> afterState = const {},
    required String ipAddress,
    required String userAgent,
    bool success = true,
    String? errorMessage,
    Duration? processingTime,
    Map<String, dynamic> metadata = const {},
  }) {
    if (!_config.enabled || !_config.shouldLogCategory(category)) {
      return;
    }

    _log(
      userId: userId,
      userName: userName,
      sessionId: sessionId,
      level: level,
      category: category,
      action: action,
      resource: resource,
      description: description,
      details: details,
      beforeState: beforeState,
      afterState: afterState,
      ipAddress: ipAddress,
      userAgent: userAgent,
      success: success,
      errorMessage: errorMessage,
      processingTime: processingTime,
      metadata: metadata,
    );
  }

  /// Internal logging method
  void _log({
    required String userId,
    required String userName,
    required String sessionId,
    required AuditLogLevel level,
    required AuditCategory category,
    required String action,
    required String resource,
    required String description,
    Map<String, dynamic> details = const {},
    Map<String, dynamic> beforeState = const {},
    Map<String, dynamic> afterState = const {},
    required String ipAddress,
    required String userAgent,
    bool success = true,
    String? errorMessage,
    Duration? processingTime,
    Map<String, dynamic> metadata = const {},
  }) {
    final logEntry = AuditLogEntry(
      id: _generateLogId(),
      timestamp: DateTime.now(),
      userId: userId,
      userName: userName,
      sessionId: sessionId,
      level: level,
      category: category,
      action: action,
      resource: resource,
      description: description,
      details: details,
      beforeState: beforeState,
      afterState: afterState,
      ipAddress: ipAddress,
      userAgent: userAgent,
      success: success,
      errorMessage: errorMessage,
      processingTime: processingTime,
      metadata: metadata,
    );

    _auditLogs.add(logEntry);
    _logCounter++;

    // Maintain log size limit
    if (_auditLogs.length > _config.maxLogEntries) {
      _auditLogs.removeRange(0, _auditLogs.length - _config.maxLogEntries);
    }

    // Check for real-time alerts
    if (_config.enableRealTimeAlerts && _config.alertLevels.contains(level)) {
      _triggerAlert(logEntry);
    }

    notifyListeners();
  }

  /// Generate unique log ID
  String _generateLogId() {
    return 'audit_${DateTime.now().millisecondsSinceEpoch}_${_logCounter}_${_random.nextInt(1000)}';
  }

  /// Trigger alert for critical log entries
  void _triggerAlert(AuditLogEntry logEntry) {
    // In production, send to monitoring system, SIEM, or notification service
    if (kDebugMode) {
      print('🚨 AUDIT ALERT: ${logEntry.level.name.toUpperCase()} - ${logEntry.action}');
      print('   User: ${logEntry.userName} (${logEntry.userId})');
      print('   Resource: ${logEntry.resource}');
      print('   Description: ${logEntry.description}');
      if (!logEntry.success && logEntry.errorMessage != null) {
        print('   Error: ${logEntry.errorMessage}');
      }
    }
  }

  /// Query audit logs with filters
  List<AuditLogEntry> queryLogs(AuditQuery query) {
    var logs = _auditLogs.toList();

    // Date range filter
    if (query.startDate != null) {
      logs = logs.where((log) => log.timestamp.isAfter(query.startDate!)).toList();
    }
    if (query.endDate != null) {
      logs = logs.where((log) => log.timestamp.isBefore(query.endDate!)).toList();
    }

    // User filter
    if (query.userIds != null && query.userIds!.isNotEmpty) {
      logs = logs.where((log) => query.userIds!.contains(log.userId)).toList();
    }

    // Level filter
    if (query.levels != null && query.levels!.isNotEmpty) {
      logs = logs.where((log) => query.levels!.contains(log.level)).toList();
    }

    // Category filter
    if (query.categories != null && query.categories!.isNotEmpty) {
      logs = logs.where((log) => query.categories!.contains(log.category)).toList();
    }

    // Action filter
    if (query.actions != null && query.actions!.isNotEmpty) {
      logs = logs.where((log) => query.actions!.any((action) =>
          log.action.toLowerCase().contains(action.toLowerCase()))).toList();
    }

    // Resource filter
    if (query.resources != null && query.resources!.isNotEmpty) {
      logs = logs.where((log) => query.resources!.any((resource) =>
          log.resource.toLowerCase().contains(resource.toLowerCase()))).toList();
    }

    // Success filter
    if (query.successOnly != null) {
      logs = logs.where((log) => log.success == query.successOnly).toList();
    }

    // Security filter
    if (query.securityOnly == true) {
      logs = logs.where((log) => log.isSecurityRelevant).toList();
    }

    // Search term filter
    if (query.searchTerm != null && query.searchTerm!.isNotEmpty) {
      final searchLower = query.searchTerm!.toLowerCase();
      logs = logs.where((log) =>
          log.action.toLowerCase().contains(searchLower) ||
          log.description.toLowerCase().contains(searchLower) ||
          log.resource.toLowerCase().contains(searchLower) ||
          log.userName.toLowerCase().contains(searchLower)).toList();
    }

    // Sort by timestamp (most recent first)
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Apply pagination
    if (query.offset != null && query.offset! > 0) {
      logs = logs.skip(query.offset!).toList();
    }
    if (query.limit != null && query.limit! > 0) {
      logs = logs.take(query.limit!).toList();
    }

    return logs;
  }

  /// Get audit statistics
  Map<String, dynamic> getAuditStatistics() {
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));
    final last7d = now.subtract(const Duration(days: 7));
    final last30d = now.subtract(const Duration(days: 30));

    final logs24h = _auditLogs.where((log) => log.timestamp.isAfter(last24h));
    final logs7d = _auditLogs.where((log) => log.timestamp.isAfter(last7d));
    final logs30d = _auditLogs.where((log) => log.timestamp.isAfter(last30d));

    // Category breakdown
    final categoryStats = <String, int>{};
    for (final category in AuditCategory.values) {
      categoryStats[category.name] = _auditLogs
          .where((log) => log.category == category)
          .length;
    }

    // Level breakdown
    final levelStats = <String, int>{};
    for (final level in AuditLogLevel.values) {
      levelStats[level.name] = _auditLogs
          .where((log) => log.level == level)
          .length;
    }

    // Security events
    final securityEvents = _auditLogs.where((log) => log.isSecurityRelevant).length;
    final failedOperations = _auditLogs.where((log) => !log.success).length;

    // Top users by activity
    final userActivity = <String, int>{};
    for (final log in logs7d) {
      userActivity[log.userName] = (userActivity[log.userName] ?? 0) + 1;
    }
    final topUsers = userActivity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Recent critical events
    final criticalEvents = _auditLogs
        .where((log) => log.level == AuditLogLevel.critical || 
                       log.level == AuditLogLevel.security)
        .take(10)
        .toList();

    return {
      'total_logs': _auditLogs.length,
      'logs_24h': logs24h.length,
      'logs_7d': logs7d.length,
      'logs_30d': logs30d.length,
      'security_events': securityEvents,
      'failed_operations': failedOperations,
      'category_breakdown': categoryStats,
      'level_breakdown': levelStats,
      'top_users_7d': topUsers.take(10).map((e) => {
        'user': e.key,
        'activity_count': e.value,
      }).toList(),
      'recent_critical_events': criticalEvents.map((log) => {
        'timestamp': log.timestamp.toIso8601String(),
        'level': log.level.name,
        'action': log.action,
        'user': log.userName,
        'resource': log.resource,
      }).toList(),
      'integrity_checks': _integrityChecks.length,
      'last_integrity_check': _integrityChecks.isNotEmpty
          ? _integrityChecks.last.timestamp.toIso8601String()
          : null,
      'config': {
        'enabled': _config.enabled,
        'retention_days': _config.retentionPeriod.inDays,
        'max_entries': _config.maxLogEntries,
        'real_time_alerts': _config.enableRealTimeAlerts,
        'encryption_enabled': _config.enableEncryption,
      },
    };
  }

  /// Perform integrity check on audit logs
  AuditIntegrityCheck performIntegrityCheck() {
    final checkId = 'integrity_${DateTime.now().millisecondsSinceEpoch}';
    final timestamp = DateTime.now();
    
    // Calculate checksum of all log entries
    final allLogsJson = _auditLogs.map((log) => log.toJson()).toList();
    final logsString = json.encode(allLogsJson);
    final checksum = _calculateChecksum(logsString);
    
    // Look for potential tampering (simplified check)
    final tamperedEntries = <String>[];
    var previousTimestamp = DateTime(1970);
    
    for (final log in _auditLogs) {
      // Check timestamp order (logs should be chronological)
      if (log.timestamp.isBefore(previousTimestamp)) {
        tamperedEntries.add('${log.id}: Invalid timestamp order');
      }
      
      // Check for required fields
      if (log.id.isEmpty || log.userId.isEmpty || log.action.isEmpty) {
        tamperedEntries.add('${log.id}: Missing required fields');
      }
      
      previousTimestamp = log.timestamp;
    }
    
    final statistics = {
      'total_entries': _auditLogs.length,
      'date_range': {
        'earliest': _auditLogs.isNotEmpty 
            ? _auditLogs.first.timestamp.toIso8601String()
            : null,
        'latest': _auditLogs.isNotEmpty 
            ? _auditLogs.last.timestamp.toIso8601String()
            : null,
      },
      'checksum_algorithm': 'simple_hash',
      'tampered_count': tamperedEntries.length,
    };
    
    final integrityCheck = AuditIntegrityCheck(
      id: checkId,
      timestamp: timestamp,
      totalEntries: _auditLogs.length,
      checksum: checksum,
      isValid: tamperedEntries.isEmpty,
      tamperedEntries: tamperedEntries,
      statistics: statistics,
    );
    
    _integrityChecks.add(integrityCheck);
    
    // Log the integrity check
    _log(
      userId: 'SYSTEM',
      userName: 'System',
      sessionId: 'integrity_check',
      level: integrityCheck.isValid ? AuditLogLevel.info : AuditLogLevel.security,
      category: AuditCategory.security,
      action: 'INTEGRITY_CHECK_PERFORMED',
      resource: 'audit_logs',
      description: integrityCheck.isValid 
          ? 'Audit log integrity check passed'
          : 'Audit log integrity check failed - potential tampering detected',
      details: {
        'check_id': checkId,
        'total_entries': integrityCheck.totalEntries,
        'tampered_entries': integrityCheck.tamperedEntries.length,
      },
      ipAddress: '127.0.0.1',
      userAgent: 'System',
      success: integrityCheck.isValid,
      errorMessage: integrityCheck.isValid ? null : 'Integrity check failed',
    );
    
    return integrityCheck;
  }

  /// Calculate simple checksum for integrity
  String _calculateChecksum(String data) {
    int hash = 0;
    for (int i = 0; i < data.length; i++) {
      hash = ((hash << 5) - hash + data.codeUnitAt(i)) & 0xffffffff;
    }
    return hash.toString();
  }

  /// Export audit logs to JSON
  String exportToJson({
    DateTime? startDate,
    DateTime? endDate,
    bool includeSystemLogs = false,
  }) {
    var logs = _auditLogs.toList();
    
    if (startDate != null) {
      logs = logs.where((log) => log.timestamp.isAfter(startDate)).toList();
    }
    
    if (endDate != null) {
      logs = logs.where((log) => log.timestamp.isBefore(endDate)).toList();
    }
    
    if (!includeSystemLogs) {
      logs = logs.where((log) => log.userId != 'SYSTEM').toList();
    }
    
    final exportData = {
      'export_timestamp': DateTime.now().toIso8601String(),
      'total_entries': logs.length,
      'date_range': {
        'start': startDate?.toIso8601String(),
        'end': endDate?.toIso8601String(),
      },
      'logs': logs.map((log) => log.toJson()).toList(),
    };
    
    return json.encode(exportData);
  }

  /// Update audit configuration
  void updateConfig(AuditConfig config) {
    final oldConfig = _config;
    _config = config;
    
    _log(
      userId: 'SYSTEM',
      userName: 'System',
      sessionId: 'config_update',
      level: AuditLogLevel.info,
      category: AuditCategory.systemConfiguration,
      action: 'AUDIT_CONFIG_UPDATED',
      resource: 'audit_config',
      description: 'Audit service configuration updated',
      beforeState: {
        'enabled': oldConfig.enabled,
        'retention_days': oldConfig.retentionPeriod.inDays,
        'max_entries': oldConfig.maxLogEntries,
      },
      afterState: {
        'enabled': config.enabled,
        'retention_days': config.retentionPeriod.inDays,
        'max_entries': config.maxLogEntries,
      },
      ipAddress: '127.0.0.1',
      userAgent: 'System',
    );
    
    notifyListeners();
  }

  /// Cleanup old audit logs based on retention policy
  int cleanupOldLogs() {
    final cutoffDate = DateTime.now().subtract(_config.retentionPeriod);
    final initialCount = _auditLogs.length;
    
    _auditLogs.removeWhere((log) => log.timestamp.isBefore(cutoffDate));
    
    final removedCount = initialCount - _auditLogs.length;
    
    if (removedCount > 0) {
      _log(
        userId: 'SYSTEM',
        userName: 'System',
        sessionId: 'log_cleanup',
        level: AuditLogLevel.info,
        category: AuditCategory.systemConfiguration,
        action: 'AUDIT_LOGS_CLEANED',
        resource: 'audit_logs',
        description: 'Old audit logs cleaned up according to retention policy',
        details: {
          'removed_count': removedCount,
          'cutoff_date': cutoffDate.toIso8601String(),
          'retention_days': _config.retentionPeriod.inDays,
        },
        ipAddress: '127.0.0.1',
        userAgent: 'System',
      );
      
      notifyListeners();
    }
    
    return removedCount;
  }
}