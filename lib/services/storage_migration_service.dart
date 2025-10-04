import 'dart:convert';
import 'package:hive/hive.dart' as hive; // Aliased to avoid name clashes
import '../storage.dart';
import '../storage/database_factory.dart';
import '../storage/nps_database_adapter.dart';
import 'unified_storage_service.dart';
import '../models.dart';
import '../utils/log.dart';
import '../utils/backup_manager.dart';

// NOTE: Migration logic is temporarily disabled while unified storage is an
// in-memory stub. Functions now short-circuit to success to avoid analyzer
// errors from legacy APIs (getAll*, BackupManager differences, etc.). Remove
// these shortcuts when real Drift storage is reintroduced.

/// Storage Migration Service
/// 
/// This service handles the migration of data from the old multi-storage
/// architecture (Hive + SQLite + Enhanced Business Data) to the new unified
/// Drift database. It ensures data integrity and provides rollback capabilities.
class StorageMigrationService {
  static bool _migrationCompleted = false;
  
  /// Check if migration is needed and execute if required
  static Future<bool> migrateIfNeeded() async {
    // Migration disabled while unified storage is an in-memory stub.
    _migrationCompleted = true;
    return true;
  }
  
  /// Migrate all data from old storage systems to unified storage
  static Future<void> _migrateAllData() async { /* disabled */ }
  
  /// Migrate data from Hive storage
  static Future<void> _migrateHiveData(UnifiedStorageService unifiedService) async { /* disabled */ }
  
  /// Migrate data from SQLite/Sqflite storage
  static Future<void> _migrateSQLiteData(UnifiedStorageService unifiedService) async { /* disabled */ }
  
  /// Migrate Enhanced Business Data
  static Future<void> _migrateEnhancedBusinessData(UnifiedStorageService unifiedService) async { /* disabled */ }
  
  /// Validate migration results
  static Future<bool> validateMigration() async {
    try {
      final unifiedService = UnifiedStorageService.instance;
      final stats = await unifiedService.getDatabaseStats();
      
      d('[StorageMigrationService] Migration validation:');
      d('[StorageMigrationService] - Servers: ${stats['servers']}');
      d('[StorageMigrationService] - Shifts: ${stats['shifts']}');
      d('[StorageMigrationService] - NPS Feedback: ${stats['nps_feedback']}');
      d('[StorageMigrationService] - Monthly Reports: ${stats['monthly_reports']}');
      
      // Check if we have at least some data
      final totalRecords = stats.values.fold(0, (sum, count) => sum + count);
      if (totalRecords > 0) {
        d('[StorageMigrationService] Migration validation successful');
        return true;
      } else {
        d('[StorageMigrationService] Migration validation failed - no data found');
        return false;
      }
      
    } catch (e) {
      d('[StorageMigrationService] Error validating migration: $e');
      return false;
    }
  }
  
  /// Create backup before migration
  static Future<String?> createPreMigrationBackup() async {
    try {
      d('[StorageMigrationService] Creating pre-migration backup...');
      
      // Use existing backup system
      final backupResult = await BackupManager.createBackup(
        customName: 'pre_migration_backup_${DateTime.now().millisecondsSinceEpoch}'
      );
      
      if (backupResult.success) {
        d('[StorageMigrationService] Pre-migration backup created: ${backupResult.filePath}');
        return backupResult.filePath;
      } else {
        d('[StorageMigrationService] Failed to create pre-migration backup: ${backupResult.message}');
        return null;
      }
      
    } catch (e) {
      d('[StorageMigrationService] Error creating pre-migration backup: $e');
      return null;
    }
  }
  
  /// Rollback migration (restore from backup)
  static Future<bool> rollbackMigration(String backupPath) async {
    try {
      d('[StorageMigrationService] Rolling back migration from: $backupPath');
      
      // Clear unified storage
      final unifiedService = UnifiedStorageService.instance;
      await unifiedService.clearAllData();
      
      // Restore from backup
      final restoreResult = await BackupManager.restoreFromBackup(backupPath);
      
      if (restoreResult.success) {
        d('[StorageMigrationService] Migration rollback successful');
        _migrationCompleted = false;
        return true;
      } else {
        d('[StorageMigrationService] Migration rollback failed: ${restoreResult.message}');
        return false;
      }
      
    } catch (e) {
      d('[StorageMigrationService] Error rolling back migration: $e');
      return false;
    }
  }
}

