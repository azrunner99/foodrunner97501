import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../utils/log.dart';
import '../storage/database_factory.dart';
import '../storage/database_interface.dart';
import '../services/platform_service.dart';

/// SQLite Backup Service
/// 
/// Provides comprehensive backup and restore functionality for SQLite databases
/// including NPS data, monthly reports, and all related tables.
class SQLiteBackupService {
  static SQLiteBackupService? _instance;
  static SQLiteBackupService get instance => _instance ??= SQLiteBackupService._();
  
  SQLiteBackupService._();

  /// Backup all SQLite data to a JSON structure
  Future<Map<String, dynamic>> backupSQLiteData() async {
    try {
      d('[SQLiteBackupService] Starting SQLite data backup...');
      
      final sqliteData = <String, dynamic>{
        'metadata': {
          'backup_type': 'sqlite',
          'timestamp': DateTime.now().toIso8601String(),
          'platform': PlatformService.platformName,
        },
        'servers': await _backupServersTable(),
        'nps_feedback': await _backupNPSFeedbackTable(),
        'monthly_reports': await _backupMonthlyReportsTable(),
        'calculation_logs': await _backupCalculationLogsTable(),
      };
      
      d('[SQLiteBackupService] SQLite backup completed: ${sqliteData.keys.join(', ')}');
      return sqliteData;
      
    } catch (e) {
      d('[SQLiteBackupService] Error backing up SQLite data: $e');
      return {
        'error': e.toString(),
        'metadata': {
          'backup_type': 'sqlite',
          'timestamp': DateTime.now().toIso8601String(),
          'platform': PlatformService.platformName,
          'error': true,
        },
      };
    }
  }

  /// Restore SQLite data from backup
  Future<bool> restoreSQLiteData(Map<String, dynamic> sqliteData) async {
    try {
      d('[SQLiteBackupService] Starting SQLite data restore...');
      
      if (sqliteData.containsKey('error')) {
        d('[SQLiteBackupService] Backup contains errors, skipping restore');
        return false;
      }
      
      // Get database instance
      final db = DatabaseFactory.instance;
      
      // Clear existing data first
      await _clearExistingSQLiteData(db);
      
      // Restore servers
      if (sqliteData.containsKey('servers')) {
        await _restoreServersTable(db, sqliteData['servers'] as List<dynamic>);
      }
      
      // Restore NPS feedback
      if (sqliteData.containsKey('nps_feedback')) {
        await _restoreNPSFeedbackTable(db, sqliteData['nps_feedback'] as List<dynamic>);
      }
      
      // Restore monthly reports
      if (sqliteData.containsKey('monthly_reports')) {
        await _restoreMonthlyReportsTable(db, sqliteData['monthly_reports'] as List<dynamic>);
      }
      
      // Restore calculation logs
      if (sqliteData.containsKey('calculation_logs')) {
        await _restoreCalculationLogsTable(db, sqliteData['calculation_logs'] as List<dynamic>);
      }
      
      d('[SQLiteBackupService] SQLite restore completed successfully');
      return true;
      
    } catch (e) {
      d('[SQLiteBackupService] Error restoring SQLite data: $e');
      return false;
    }
  }

  /// Backup servers table
  Future<List<Map<String, dynamic>>> _backupServersTable() async {
    try {
      final db = DatabaseFactory.instance;
      final servers = await db.queryTable('servers');
      d('[SQLiteBackupService] Backed up ${servers.length} servers');
      return servers;
    } catch (e) {
      d('[SQLiteBackupService] Error backing up servers: $e');
      return [];
    }
  }

  /// Backup NPS feedback table
  Future<List<Map<String, dynamic>>> _backupNPSFeedbackTable() async {
    try {
      final db = DatabaseFactory.instance;
      final feedback = await db.queryTable('nps_feedback');
      d('[SQLiteBackupService] Backed up ${feedback.length} NPS feedback records');
      return feedback;
    } catch (e) {
      d('[SQLiteBackupService] Error backing up NPS feedback: $e');
      return [];
    }
  }

  /// Backup monthly reports table
  Future<List<Map<String, dynamic>>> _backupMonthlyReportsTable() async {
    try {
      final db = DatabaseFactory.instance;
      final reports = await db.queryTable('nps_monthly_reports');
      d('[SQLiteBackupService] Backed up ${reports.length} monthly reports');
      return reports;
    } catch (e) {
      d('[SQLiteBackupService] Error backing up monthly reports: $e');
      return [];
    }
  }

  /// Backup calculation logs table
  Future<List<Map<String, dynamic>>> _backupCalculationLogsTable() async {
    try {
      final db = DatabaseFactory.instance;
      final logs = await db.queryTable('nps_calculation_log');
      d('[SQLiteBackupService] Backed up ${logs.length} calculation logs');
      return logs;
    } catch (e) {
      d('[SQLiteBackupService] Error backing up calculation logs: $e');
      return [];
    }
  }

  /// Clear existing SQLite data
  Future<void> _clearExistingSQLiteData(DatabaseInterface db) async {
    try {
      d('[SQLiteBackupService] Clearing existing SQLite data...');
      
      // Delete in reverse order of dependencies
      await db.execute('DELETE FROM nps_calculation_log');
      await db.execute('DELETE FROM nps_monthly_reports');
      await db.execute('DELETE FROM nps_feedback');
      await db.execute('DELETE FROM servers');
      
      d('[SQLiteBackupService] Existing SQLite data cleared');
    } catch (e) {
      d('[SQLiteBackupService] Error clearing SQLite data: $e');
    }
  }

  /// Restore servers table
  Future<void> _restoreServersTable(DatabaseInterface db, List<dynamic> servers) async {
    try {
      d('[SQLiteBackupService] Restoring ${servers.length} servers...');
      
      for (final server in servers) {
        final serverMap = server as Map<String, dynamic>;
        await db.insertInto('servers', serverMap);
      }
      
      d('[SQLiteBackupService] Servers restored successfully');
    } catch (e) {
      d('[SQLiteBackupService] Error restoring servers: $e');
    }
  }

  /// Restore NPS feedback table
  Future<void> _restoreNPSFeedbackTable(DatabaseInterface db, List<dynamic> feedback) async {
    try {
      d('[SQLiteBackupService] Restoring ${feedback.length} NPS feedback records...');
      
      for (final record in feedback) {
        final feedbackMap = record as Map<String, dynamic>;
        await db.insertInto('nps_feedback', feedbackMap);
      }
      
      d('[SQLiteBackupService] NPS feedback restored successfully');
    } catch (e) {
      d('[SQLiteBackupService] Error restoring NPS feedback: $e');
    }
  }

  /// Restore monthly reports table
  Future<void> _restoreMonthlyReportsTable(DatabaseInterface db, List<dynamic> reports) async {
    try {
      d('[SQLiteBackupService] Restoring ${reports.length} monthly reports...');
      
      for (final report in reports) {
        final reportMap = report as Map<String, dynamic>;
        await db.insertInto('nps_monthly_reports', reportMap);
      }
      
      d('[SQLiteBackupService] Monthly reports restored successfully');
    } catch (e) {
      d('[SQLiteBackupService] Error restoring monthly reports: $e');
    }
  }

  /// Restore calculation logs table
  Future<void> _restoreCalculationLogsTable(DatabaseInterface db, List<dynamic> logs) async {
    try {
      d('[SQLiteBackupService] Restoring ${logs.length} calculation logs...');
      
      for (final log in logs) {
        final logMap = log as Map<String, dynamic>;
        await db.insertInto('nps_calculation_log', logMap);
      }
      
      d('[SQLiteBackupService] Calculation logs restored successfully');
    } catch (e) {
      d('[SQLiteBackupService] Error restoring calculation logs: $e');
    }
  }

  /// Get SQLite database file path for direct file backup
  Future<String?> getSQLiteDatabasePath() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final dbPath = path.join(documentsDir.path, 'nps_database.db');
      
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        d('[SQLiteBackupService] SQLite database found at: $dbPath');
        return dbPath;
      } else {
        d('[SQLiteBackupService] SQLite database not found at: $dbPath');
        return null;
      }
    } catch (e) {
      d('[SQLiteBackupService] Error getting SQLite database path: $e');
      return null;
    }
  }

  /// Create a direct file backup of the SQLite database
  Future<File?> createSQLiteFileBackup(String backupDir) async {
    try {
      final dbPath = await getSQLiteDatabasePath();
      if (dbPath == null) {
        d('[SQLiteBackupService] No SQLite database file found for backup');
        return null;
      }
      
      final sourceFile = File(dbPath);
      final timestamp = DateTime.now();
      final backupFileName = 'nps_database_${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}-${timestamp.minute.toString().padLeft(2, '0')}.db';
      final backupFile = File(path.join(backupDir, backupFileName));
      
      await sourceFile.copy(backupFile.path);
      
      d('[SQLiteBackupService] SQLite file backup created: ${backupFile.path}');
      return backupFile;
      
    } catch (e) {
      d('[SQLiteBackupService] Error creating SQLite file backup: $e');
      return null;
    }
  }

  /// Restore from SQLite file backup
  Future<bool> restoreSQLiteFileBackup(String backupFilePath) async {
    try {
      final backupFile = File(backupFilePath);
      if (!await backupFile.exists()) {
        d('[SQLiteBackupService] Backup file not found: $backupFilePath');
        return false;
      }
      
      final documentsDir = await getApplicationDocumentsDirectory();
      final dbPath = path.join(documentsDir.path, 'nps_database.db');
      final targetFile = File(dbPath);
      
      // Backup existing database first
      if (await targetFile.exists()) {
        final backupExisting = File('${dbPath}.backup');
        await targetFile.copy(backupExisting.path);
        d('[SQLiteBackupService] Existing database backed up to: ${backupExisting.path}');
      }
      
      // Restore from backup
      await backupFile.copy(targetFile.path);
      
      d('[SQLiteBackupService] SQLite file restore completed: $dbPath');
      return true;
      
    } catch (e) {
      d('[SQLiteBackupService] Error restoring SQLite file backup: $e');
      return false;
    }
  }
}
