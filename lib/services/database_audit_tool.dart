import 'dart:async';
import '../utils/log.dart';
import '../storage/database_factory.dart';
import '../storage.dart';
import 'server_id_resolver.dart';

/// Database Audit Tool for Server ID Analysis
/// 
/// Scans all database tables and storage to identify server ID inconsistencies,
/// orphaned records, and data integrity issues.
class DatabaseAuditTool {
  static DatabaseAuditTool? _instance;
  static DatabaseAuditTool get instance => _instance ??= DatabaseAuditTool._();
  
  DatabaseAuditTool._();

  /// Run comprehensive audit of all server ID usage across the system
  static Future<DatabaseAuditResult> runFullAudit() async {
    return await instance._runFullAudit();
  }

  /// Audit specific table for server ID issues
  static Future<TableAuditResult> auditTable(String tableName) async {
    return await instance._auditTable(tableName);
  }

  /// Generate detailed audit report
  static Future<String> generateAuditReport() async {
    return await instance._generateAuditReport();
  }

  Future<DatabaseAuditResult> _runFullAudit() async {
    final result = DatabaseAuditResult();
    
    try {
      d('[DatabaseAuditTool] Starting comprehensive database audit...');
      
      // Audit main storage
      await _auditMainStorage(result);
      
      // Audit NPS database tables
      await _auditNPSDatabase(result);
      
      // Audit performance data
      await _auditPerformanceData(result);
      
      // Cross-reference analysis
      await _crossReferenceAnalysis(result);
      
      d('[DatabaseAuditTool] Audit completed with ${result.issues.length} issues found');
      
    } catch (e) {
      d('[DatabaseAuditTool] Error during audit: $e');
      result.addIssue(DatabaseIssue(
        severity: IssueSeverity.critical,
        type: IssueType.systemError,
        table: 'system',
        description: 'Audit process failed: $e',
      ));
    }
    
    return result;
  }

  Future<void> _auditMainStorage(DatabaseAuditResult result) async {
    try {
      // Check servers storage
      final serversData = await Storage.serversBox.get('list');
      if (serversData != null) {
        final serversList = (serversData as List).cast<Map<String, dynamic>>();
        
        result.mainStorageServerCount = serversList.length;
        
        // Check for duplicate IDs
        final ids = serversList.map((s) => s['id'] as String).toList();
        final duplicates = ids.where((id) => ids.where((other) => other == id).length > 1).toSet();
        
        if (duplicates.isNotEmpty) {
          result.addIssue(DatabaseIssue(
            severity: IssueSeverity.critical,
            type: IssueType.duplicateIds,
            table: 'main_storage_servers',
            description: 'Duplicate server IDs found: ${duplicates.join(', ')}',
            affectedIds: duplicates.toList(),
          ));
        }
        
        // Check for missing names
        final missingNames = serversList.where((s) => 
          s['name'] == null || (s['name'] as String).isEmpty).toList();
          
        if (missingNames.isNotEmpty) {
          result.addIssue(DatabaseIssue(
            severity: IssueSeverity.warning,
            type: IssueType.missingData,
            table: 'main_storage_servers',
            description: 'Servers with missing names: ${missingNames.length}',
            affectedIds: missingNames.map((s) => s['id'] as String).toList(),
          ));
        }
        
        d('[DatabaseAuditTool] Main storage audit: ${serversList.length} servers, ${duplicates.length} duplicates');
      }
    } catch (e) {
      result.addIssue(DatabaseIssue(
        severity: IssueSeverity.error,
        type: IssueType.accessError,
        table: 'main_storage',
        description: 'Failed to access main storage: $e',
      ));
    }
  }

  Future<void> _auditNPSDatabase(DatabaseAuditResult result) async {
    try {
      final db = DatabaseFactory.instance;
      
      // Audit servers table in NPS database
      final npsServers = await db.queryTable('servers');
      result.npsStorageServerCount = npsServers.length;
      
      // Check for duplicate IDs in NPS database
      final npsIds = npsServers.map((s) => s['id']?.toString() ?? '').toList();
      final npsDuplicates = npsIds.where((id) => npsIds.where((other) => other == id).length > 1).toSet();
      
      if (npsDuplicates.isNotEmpty) {
        result.addIssue(DatabaseIssue(
          severity: IssueSeverity.critical,
          type: IssueType.duplicateIds,
          table: 'nps_servers',
          description: 'Duplicate NPS server IDs: ${npsDuplicates.join(', ')}',
          affectedIds: npsDuplicates.toList(),
        ));
      }
      
      // Audit NPS feedback table
      final npsCount = await _countRecordsWithServerReferences(db, 'nps_feedback', 'server_id');
      result.npsFeedbackCount = npsCount['total'] ?? 0;
      result.npsFeedbackOrphanCount = npsCount['orphaned'] ?? 0;
      
      if (result.npsFeedbackOrphanCount > 0) {
        result.addIssue(DatabaseIssue(
          severity: IssueSeverity.warning,
          type: IssueType.orphanedRecords,
          table: 'nps_feedback',
          description: 'Orphaned NPS feedback records: ${result.npsFeedbackOrphanCount}',
        ));
      }
      
      // Audit monthly reports table
      final monthlyCount = await _countRecordsWithServerReferences(db, 'monthly_reports', 'server_id');
      result.monthlyReportsCount = monthlyCount['total'] ?? 0;
      result.monthlyReportsOrphanCount = monthlyCount['orphaned'] ?? 0;
      
      if (result.monthlyReportsOrphanCount > 0) {
        result.addIssue(DatabaseIssue(
          severity: IssueSeverity.warning,
          type: IssueType.orphanedRecords,
          table: 'monthly_reports',
          description: 'Orphaned monthly report records: ${result.monthlyReportsOrphanCount}',
        ));
      }
      
      d('[DatabaseAuditTool] NPS database audit: ${npsServers.length} servers, ${result.npsFeedbackCount} feedback, ${result.monthlyReportsCount} reports');
      
    } catch (e) {
      result.addIssue(DatabaseIssue(
        severity: IssueSeverity.error,
        type: IssueType.accessError,
        table: 'nps_database',
        description: 'Failed to access NPS database: $e',
      ));
    }
  }

  Future<void> _auditPerformanceData(DatabaseAuditResult result) async {
    try {
      // Check shifts data for server references
      final shiftsData = await Storage.shiftsBox.get('list');
      if (shiftsData != null) {
        final shiftsList = (shiftsData as List).cast<Map<String, dynamic>>();
        result.shiftsCount = shiftsList.length;
        
        int totalServerReferences = 0;
        int unresolvedReferences = 0;
        
        for (final shift in shiftsList) {
          final counts = shift['counts'] as Map<String, dynamic>?;
          if (counts != null) {
            totalServerReferences += counts.length;
            
            // Check if each server ID can be resolved
            for (final serverId in counts.keys) {
              final resolved = await ServerIdResolver.resolveToServerObject(serverId);
              if (resolved == null) {
                unresolvedReferences++;
              }
            }
          }
        }
        
        result.performanceReferencesCount = totalServerReferences;
        result.performanceOrphanCount = unresolvedReferences;
        
        if (unresolvedReferences > 0) {
          result.addIssue(DatabaseIssue(
            severity: IssueSeverity.warning,
            type: IssueType.orphanedReferences,
            table: 'shifts_data',
            description: 'Unresolved server references in shifts: $unresolvedReferences/$totalServerReferences',
          ));
        }
        
        d('[DatabaseAuditTool] Performance data audit: ${shiftsList.length} shifts, $totalServerReferences references, $unresolvedReferences unresolved');
      }
    } catch (e) {
      result.addIssue(DatabaseIssue(
        severity: IssueSeverity.error,
        type: IssueType.accessError,
        table: 'performance_data',
        description: 'Failed to audit performance data: $e',
      ));
    }
  }

  Future<void> _crossReferenceAnalysis(DatabaseAuditResult result) async {
    try {
      // Get all server IDs from main storage
      final mainServers = <String>[];
      final serversData = await Storage.serversBox.get('list');
      if (serversData != null) {
        final serversList = (serversData as List).cast<Map<String, dynamic>>();
        mainServers.addAll(serversList.map((s) => s['id'] as String));
      }
      
      // Get all server IDs from NPS database
      final npsServers = <String>[];
      try {
        final db = DatabaseFactory.instance;
        final npsServerData = await db.queryTable('servers');
        npsServers.addAll(npsServerData.map((s) => s['id']?.toString() ?? ''));
      } catch (e) {
        // NPS database might not exist yet
      }
      
      // Find servers in main but not in NPS
      final missingInNPS = mainServers.where((id) => !npsServers.contains(id)).toList();
      if (missingInNPS.isNotEmpty) {
        result.addIssue(DatabaseIssue(
          severity: IssueSeverity.warning,
          type: IssueType.synchronizationIssue,
          table: 'cross_reference',
          description: 'Servers in main storage but not in NPS database: ${missingInNPS.length}',
          affectedIds: missingInNPS,
        ));
      }
      
      // Find servers in NPS but not in main
      final missingInMain = npsServers.where((id) => !mainServers.contains(id) && id.isNotEmpty).toList();
      if (missingInMain.isNotEmpty) {
        result.addIssue(DatabaseIssue(
          severity: IssueSeverity.error,
          type: IssueType.synchronizationIssue,
          table: 'cross_reference',
          description: 'Servers in NPS database but not in main storage: ${missingInMain.length}',
          affectedIds: missingInMain,
        ));
      }
      
      result.synchronizationIssues = missingInNPS.length + missingInMain.length;
      
      d('[DatabaseAuditTool] Cross-reference analysis: ${mainServers.length} main, ${npsServers.length} NPS, ${result.synchronizationIssues} sync issues');
      
    } catch (e) {
      result.addIssue(DatabaseIssue(
        severity: IssueSeverity.error,
        type: IssueType.accessError,
        table: 'cross_reference',
        description: 'Failed cross-reference analysis: $e',
      ));
    }
  }

  Future<Map<String, int>> _countRecordsWithServerReferences(
    dynamic db, String tableName, String serverIdColumn) async {
    try {
      final allRecords = await db.queryTable(tableName);
      final total = allRecords.length;
      
      int orphaned = 0;
      for (final record in allRecords) {
        final serverId = record[serverIdColumn];
        if (serverId != null) {
          final resolved = await ServerIdResolver.resolveToServerObject(serverId);
          if (resolved == null) {
            orphaned++;
          }
        }
      }
      
      return {'total': total, 'orphaned': orphaned};
    } catch (e) {
      d('[DatabaseAuditTool] Error counting records in $tableName: $e');
      return {'total': 0, 'orphaned': 0};
    }
  }

  Future<TableAuditResult> _auditTable(String tableName) async {
    // Implementation for specific table audit
    // This would be more detailed analysis of a single table
    return TableAuditResult(tableName: tableName);
  }

  Future<String> _generateAuditReport() async {
    final result = await _runFullAudit();
    final report = StringBuffer();
    
    report.writeln('=== DATABASE AUDIT REPORT ===');
    report.writeln('Generated: ${DateTime.now()}');
    report.writeln('');
    
    // Summary statistics
    report.writeln('=== SUMMARY ===');
    report.writeln('Main Storage Servers: ${result.mainStorageServerCount}');
    report.writeln('NPS Database Servers: ${result.npsStorageServerCount}');
    report.writeln('NPS Feedback Records: ${result.npsFeedbackCount}');
    report.writeln('Monthly Report Records: ${result.monthlyReportsCount}');
    report.writeln('Shifts Records: ${result.shiftsCount}');
    report.writeln('');
    
    // Issues summary
    report.writeln('=== ISSUES SUMMARY ===');
    final criticalIssues = result.issues.where((i) => i.severity == IssueSeverity.critical).length;
    final errorIssues = result.issues.where((i) => i.severity == IssueSeverity.error).length;
    final warningIssues = result.issues.where((i) => i.severity == IssueSeverity.warning).length;
    
    report.writeln('Critical Issues: $criticalIssues');
    report.writeln('Error Issues: $errorIssues');
    report.writeln('Warning Issues: $warningIssues');
    report.writeln('Total Issues: ${result.issues.length}');
    report.writeln('');
    
    // Detailed issues
    if (result.issues.isNotEmpty) {
      report.writeln('=== DETAILED ISSUES ===');
      for (final issue in result.issues) {
        report.writeln('${_severityToString(issue.severity)} [${issue.table}]: ${issue.description}');
        if (issue.affectedIds.isNotEmpty) {
          report.writeln('  Affected IDs: ${issue.affectedIds.join(', ')}');
        }
        report.writeln('');
      }
    }
    
    // Recommendations
    report.writeln('=== RECOMMENDATIONS ===');
    if (criticalIssues > 0) {
      report.writeln('🔴 CRITICAL: Address duplicate IDs and system errors immediately');
    }
    if (errorIssues > 0) {
      report.writeln('🟠 ERROR: Fix synchronization issues and access problems');
    }
    if (warningIssues > 0) {
      report.writeln('🟡 WARNING: Clean up orphaned records and missing data');
    }
    if (result.issues.isEmpty) {
      report.writeln('✅ No critical issues found. System appears healthy.');
    }
    
    return report.toString();
  }

  String _severityToString(IssueSeverity severity) {
    switch (severity) {
      case IssueSeverity.critical:
        return '🔴 CRITICAL';
      case IssueSeverity.error:
        return '🟠 ERROR';
      case IssueSeverity.warning:
        return '🟡 WARNING';
    }
  }
}

/// Result of database audit containing all findings
class DatabaseAuditResult {
  final List<DatabaseIssue> issues = [];
  
  // Statistics
  int mainStorageServerCount = 0;
  int npsStorageServerCount = 0;
  int npsFeedbackCount = 0;
  int npsFeedbackOrphanCount = 0;
  int monthlyReportsCount = 0;
  int monthlyReportsOrphanCount = 0;
  int shiftsCount = 0;
  int performanceReferencesCount = 0;
  int performanceOrphanCount = 0;
  int synchronizationIssues = 0;
  
  void addIssue(DatabaseIssue issue) {
    issues.add(issue);
  }
  
  bool get hasIssues => issues.isNotEmpty;
  bool get hasCriticalIssues => issues.any((i) => i.severity == IssueSeverity.critical);
  
  int get totalRecords => npsFeedbackCount + monthlyReportsCount + shiftsCount;
  int get totalOrphanedRecords => npsFeedbackOrphanCount + monthlyReportsOrphanCount + performanceOrphanCount;
}

/// Individual database issue found during audit
class DatabaseIssue {
  final IssueSeverity severity;
  final IssueType type;
  final String table;
  final String description;
  final List<String> affectedIds;
  
  DatabaseIssue({
    required this.severity,
    required this.type,
    required this.table,
    required this.description,
    this.affectedIds = const [],
  });
}

/// Result of auditing a specific table
class TableAuditResult {
  final String tableName;
  final List<DatabaseIssue> issues = [];
  
  TableAuditResult({required this.tableName});
}

/// Severity levels for database issues
enum IssueSeverity {
  critical,  // System-breaking issues
  error,     // Significant problems affecting functionality
  warning,   // Minor issues that should be addressed
}

/// Types of issues that can be found
enum IssueType {
  duplicateIds,
  orphanedRecords,
  orphanedReferences,
  missingData,
  synchronizationIssue,
  accessError,
  systemError,
}