import 'package:flutter/foundation.dart';
import '../services/server_id_resolver.dart';
import '../services/application_update_service.dart';
import '../providers/nps_provider.dart';
import '../app_state.dart';
import '../storage/database_factory.dart';
import '../utils/log.dart';

/// Phase 4: Comprehensive Testing & Validation Service
/// 
/// This service validates the entire server ID standardization system
/// and provides detailed reports on data integrity, performance, and consistency.
class Phase4ValidationService {
  
  /// Run comprehensive validation of the entire server ID system
  static Future<ValidationReport> runComprehensiveValidation() async {
    d('[Phase4] Starting comprehensive server ID system validation...');
    
    final stopwatch = Stopwatch()..start();
    final report = ValidationReport();
    
    try {
      // Test 1: Database Integrity Validation
      await _validateDatabaseIntegrity(report);
      
      // Test 2: ID Resolution Performance
      await _validateIdResolutionPerformance(report);
      
      // Test 3: Data Consistency Across Systems
      await _validateDataConsistency(report);
      
      // Test 4: Widget Integration Testing
      await _validateWidgetIntegration(report);
      
      // Test 5: Error Handling & Edge Cases
      await _validateErrorHandling(report);
      
      // Test 6: NPS System Validation
      await _validateNpsSystemIntegration(report);
      
      stopwatch.stop();
      report.totalExecutionTime = stopwatch.elapsedMilliseconds;
      
      d('[Phase4] Validation completed in ${report.totalExecutionTime}ms');
      return report;
      
    } catch (e) {
      report.addError('Critical validation failure: $e');
      stopwatch.stop();
      report.totalExecutionTime = stopwatch.elapsedMilliseconds;
      return report;
    }
  }
  
  /// Test 1: Database Integrity Validation
  static Future<void> _validateDatabaseIntegrity(ValidationReport report) async {
    d('[Phase4] Testing database integrity...');
    
    try {
      final db = DatabaseFactory.instance;
      
      // Check main app servers table
      final appServers = await db.queryTable('servers');
      report.appServerCount = appServers.length;
      d('[Phase4] Found ${appServers.length} servers in app database');
      
      // Check NPS monthly reports table
      final npsReports = await db.queryTable('nps_monthly_reports');
      report.npsReportCount = npsReports.length;
      d('[Phase4] Found ${npsReports.length} NPS reports in database');
      
      // Validate ID format consistency
      int validIdCount = 0;
      int invalidIdCount = 0;
      
      for (final server in appServers) {
        final serverId = server['id']?.toString() ?? '';
        if (_isValidServerIdFormat(serverId)) {
          validIdCount++;
        } else {
          invalidIdCount++;
          report.addWarning('Invalid server ID format: $serverId');
        }
      }
      
      report.validIdCount = validIdCount;
      report.invalidIdCount = invalidIdCount;
      report.addSuccess('Database integrity check completed: ${validIdCount} valid IDs, ${invalidIdCount} invalid');
      
    } catch (e) {
      report.addError('Database integrity validation failed: $e');
    }
  }
  
  /// Test 2: ID Resolution Performance Testing
  static Future<void> _validateIdResolutionPerformance(ValidationReport report) async {
    d('[Phase4] Testing ID resolution performance...');
    
    try {
      final testIds = ['hjemzqy3sslvtt3o', 'jmwkqxav22yi4ek6', '128', 'nonexistent_id'];
      final resolutionTimes = <int>[];
      
      for (final testId in testIds) {
        final stopwatch = Stopwatch()..start();
        
        try {
          final resolvedName = await ApplicationUpdateService.resolveServerName(testId);
          stopwatch.stop();
          
          final timeMs = stopwatch.elapsedMilliseconds;
          resolutionTimes.add(timeMs);
          
          d('[Phase4] ID "$testId" resolved to "$resolvedName" in ${timeMs}ms');
          
          if (timeMs > 10) {
            report.addWarning('Slow ID resolution: $testId took ${timeMs}ms (target: <10ms)');
          } else {
            report.addSuccess('Fast ID resolution: $testId resolved in ${timeMs}ms');
          }
          
        } catch (e) {
          stopwatch.stop();
          report.addError('Failed to resolve ID "$testId": $e');
        }
      }
      
      if (resolutionTimes.isNotEmpty) {
        final avgTime = resolutionTimes.reduce((a, b) => a + b) / resolutionTimes.length;
        report.averageResolutionTime = avgTime;
        d('[Phase4] Average resolution time: ${avgTime.toStringAsFixed(2)}ms');
      }
      
    } catch (e) {
      report.addError('Performance validation failed: $e');
    }
  }
  
  /// Test 3: Data Consistency Across Systems
  static Future<void> _validateDataConsistency(ValidationReport report) async {
    d('[Phase4] Testing data consistency across systems...');
    
    try {
      final db = DatabaseFactory.instance;
      
      // Get servers from main app table
      final appServers = await db.queryTable('servers');
      final appServerIds = appServers.map((s) => s['id']?.toString()).where((id) => id != null).toSet();
      
      // Get server IDs referenced in NPS reports
      final npsReports = await db.queryTable('nps_monthly_reports');
      final npsServerIds = npsReports.map((r) => r['server_id']?.toString()).where((id) => id != null).toSet();
      
      // Find mismatches
      final missingInApp = npsServerIds.difference(appServerIds);
      final missingInNps = appServerIds.difference(npsServerIds);
      
      report.consistentServerIds = appServerIds.intersection(npsServerIds).length;
      report.missingInApp = missingInApp.length;
      report.missingInNps = missingInNps.length;
      
      if (missingInApp.isEmpty && missingInNps.isEmpty) {
        report.addSuccess('Perfect data consistency: all server IDs match across systems');
      } else {
        if (missingInApp.isNotEmpty) {
          report.addWarning('${missingInApp.length} server IDs in NPS but missing from app: ${missingInApp.take(5).join(", ")}');
        }
        if (missingInNps.isNotEmpty) {
          report.addWarning('${missingInNps.length} server IDs in app but missing from NPS: ${missingInNps.take(5).join(", ")}');
        }
      }
      
    } catch (e) {
      report.addError('Data consistency validation failed: $e');
    }
  }
  
  /// Test 4: Widget Integration Testing
  static Future<void> _validateWidgetIntegration(ValidationReport report) async {
    d('[Phase4] Testing widget integration...');
    
    try {
      // Test ApplicationUpdateService helper methods
      final testServerId = 'hjemzqy3sslvtt3o';  // Known server ID
      
      // Test resolveServerName
      final serverName = await ApplicationUpdateService.resolveServerName(testServerId);
      if (serverName.contains('Server $testServerId')) {
        report.addWarning('Widget integration issue: Server name resolution falling back to generic name');
      } else {
        report.addSuccess('Widget integration working: "$testServerId" resolves to "$serverName"');
      }
      
      // Test resolveServerDisplayInfo
      final displayInfo = await ApplicationUpdateService.resolveServerDisplayInfo(testServerId);
      if (displayInfo.displayName == serverName) {
        report.addSuccess('Display info consistency: name matches resolved name');
      } else {
        report.addWarning('Display info inconsistency: "${displayInfo.displayName}" vs "$serverName"');
      }
      
      report.widgetIntegrationWorking = !serverName.contains('Server $testServerId');
      
    } catch (e) {
      report.addError('Widget integration validation failed: $e');
    }
  }
  
  /// Test 5: Error Handling & Edge Cases
  static Future<void> _validateErrorHandling(ValidationReport report) async {
    d('[Phase4] Testing error handling and edge cases...');
    
    try {
      // Test null ID handling
      try {
        final result = await ApplicationUpdateService.resolveServerName(null);
        if (result == 'Unknown Server') {
          report.addSuccess('Null ID handling working correctly');
        } else {
          report.addWarning('Unexpected null ID result: $result');
        }
      } catch (e) {
        report.addError('Null ID handling failed: $e');
      }
      
      // Test empty string handling
      try {
        final result = await ApplicationUpdateService.resolveServerName('');
        if (result == 'Unknown Server') {
          report.addSuccess('Empty string handling working correctly');
        } else {
          report.addWarning('Unexpected empty string result: $result');
        }
      } catch (e) {
        report.addError('Empty string handling failed: $e');
      }
      
      // Test invalid ID handling
      try {
        final result = await ApplicationUpdateService.resolveServerName('invalid_nonexistent_id_12345');
        if (result == 'Server invalid_nonexistent_id_12345') {
          report.addSuccess('Invalid ID fallback working correctly');
        } else {
          report.addWarning('Unexpected invalid ID result: $result');
        }
      } catch (e) {
        report.addError('Invalid ID handling failed: $e');
      }
      
    } catch (e) {
      report.addError('Error handling validation failed: $e');
    }
  }
  
  /// Test 6: NPS System Integration
  static Future<void> _validateNpsSystemIntegration(ValidationReport report) async {
    d('[Phase4] Testing NPS system integration...');
    
    try {
      // Test server ID resolution in NPS context
      final db = DatabaseFactory.instance;
      final npsReports = await db.queryTable('nps_monthly_reports', limit: 5);
      
      int resolvedCount = 0;
      int failedCount = 0;
      
      for (final npsReport in npsReports) {
        final serverId = npsReport['server_id']?.toString();
        if (serverId != null) {
          try {
            final resolvedName = await ApplicationUpdateService.resolveServerName(serverId);
            if (!resolvedName.contains('Server $serverId')) {
              resolvedCount++;
              d('[Phase4] NPS report server ID "$serverId" resolved to "$resolvedName"');
            } else {
              failedCount++;
              d('[Phase4] NPS report server ID "$serverId" failed to resolve properly');
            }
          } catch (e) {
            failedCount++;
            d('[Phase4] Error resolving NPS server ID "$serverId": $e');
          }
        }
      }
      
      report.npsResolvedCount = resolvedCount;
      report.npsFailedCount = failedCount;
      
      if (failedCount == 0) {
        report.addSuccess('Perfect NPS integration: all server IDs resolve correctly');
      } else {
        report.addWarning('NPS integration issues: $failedCount of ${resolvedCount + failedCount} IDs failed to resolve');
      }
      
    } catch (e) {
      report.addError('NPS system validation failed: $e');
    }
  }
  
  /// Validate server ID format (basic check)
  static bool _isValidServerIdFormat(String serverId) {
    if (serverId.isEmpty) return false;
    
    // Valid formats: alphanumeric strings (legacy or new format)
    return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(serverId) && serverId.length >= 3;
  }
}

/// Comprehensive validation report
class ValidationReport {
  int totalExecutionTime = 0;
  
  // Database metrics
  int appServerCount = 0;
  int npsReportCount = 0;
  int validIdCount = 0;
  int invalidIdCount = 0;
  
  // Performance metrics
  double averageResolutionTime = 0.0;
  
  // Consistency metrics
  int consistentServerIds = 0;
  int missingInApp = 0;
  int missingInNps = 0;
  
  // Integration metrics
  bool widgetIntegrationWorking = false;
  int npsResolvedCount = 0;
  int npsFailedCount = 0;
  
  // Results
  final List<String> successes = [];
  final List<String> warnings = [];
  final List<String> errors = [];
  
  void addSuccess(String message) {
    successes.add(message);
    d('[Phase4] ✅ $message');
  }
  
  void addWarning(String message) {
    warnings.add(message);
    d('[Phase4] ⚠️ $message');
  }
  
  void addError(String message) {
    errors.add(message);
    d('[Phase4] ❌ $message');
  }
  
  /// Get overall system health score (0-100)
  int get healthScore {
    int score = 100;
    
    // Deduct for errors (major issues)
    score -= errors.length * 20;
    
    // Deduct for warnings (minor issues)
    score -= warnings.length * 5;
    
    // Performance penalty
    if (averageResolutionTime > 10) {
      score -= 10;
    }
    
    // Consistency penalty
    if (missingInApp > 0 || missingInNps > 0) {
      score -= 15;
    }
    
    // Integration penalty
    if (!widgetIntegrationWorking) {
      score -= 20;
    }
    
    return score.clamp(0, 100);
  }
  
  /// Get summary string
  String get summary {
    final buffer = StringBuffer();
    buffer.writeln('🏥 Server ID System Health Report');
    buffer.writeln('═' * 50);
    buffer.writeln('Overall Health Score: ${healthScore}/100');
    buffer.writeln('Execution Time: ${totalExecutionTime}ms');
    buffer.writeln();
    
    buffer.writeln('📊 Database Metrics:');
    buffer.writeln('  • App Servers: $appServerCount');
    buffer.writeln('  • NPS Reports: $npsReportCount');
    buffer.writeln('  • Valid IDs: $validIdCount');
    buffer.writeln('  • Invalid IDs: $invalidIdCount');
    buffer.writeln();
    
    buffer.writeln('⚡ Performance Metrics:');
    buffer.writeln('  • Avg Resolution Time: ${averageResolutionTime.toStringAsFixed(2)}ms');
    buffer.writeln();
    
    buffer.writeln('🔄 Consistency Metrics:');
    buffer.writeln('  • Consistent IDs: $consistentServerIds');
    buffer.writeln('  • Missing in App: $missingInApp');
    buffer.writeln('  • Missing in NPS: $missingInNps');
    buffer.writeln();
    
    buffer.writeln('🔧 Integration Status:');
    buffer.writeln('  • Widget Integration: ${widgetIntegrationWorking ? "✅ Working" : "❌ Issues"}');
    buffer.writeln('  • NPS Resolution: $npsResolvedCount/$npsFailedCount success/failed');
    buffer.writeln();
    
    if (successes.isNotEmpty) {
      buffer.writeln('✅ Successes (${successes.length}):');
      for (final success in successes.take(5)) {
        buffer.writeln('  • $success');
      }
      if (successes.length > 5) {
        buffer.writeln('  • ... and ${successes.length - 5} more');
      }
      buffer.writeln();
    }
    
    if (warnings.isNotEmpty) {
      buffer.writeln('⚠️ Warnings (${warnings.length}):');
      for (final warning in warnings.take(5)) {
        buffer.writeln('  • $warning');
      }
      if (warnings.length > 5) {
        buffer.writeln('  • ... and ${warnings.length - 5} more');
      }
      buffer.writeln();
    }
    
    if (errors.isNotEmpty) {
      buffer.writeln('❌ Errors (${errors.length}):');
      for (final error in errors.take(5)) {
        buffer.writeln('  • $error');
      }
      if (errors.length > 5) {
        buffer.writeln('  • ... and ${errors.length - 5} more');
      }
      buffer.writeln();
    }
    
    buffer.writeln('═' * 50);
    return buffer.toString();
  }
}