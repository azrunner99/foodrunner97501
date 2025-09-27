import 'dart:convert';
import '../storage.dart';
import '../storage/database_factory.dart';
import '../storage/nps_database_adapter.dart';
import 'unified_storage_service.dart';
import '../models.dart';
import '../utils/log.dart';

/// Storage Migration Service
/// 
/// This service handles the migration of data from the old multi-storage
/// architecture (Hive + SQLite + Enhanced Business Data) to the new unified
/// Drift database. It ensures data integrity and provides rollback capabilities.
class StorageMigrationService {
  static bool _migrationCompleted = false;
  
  /// Check if migration is needed and execute if required
  static Future<bool> migrateIfNeeded() async {
    if (_migrationCompleted) return true;
    
    try {
      d('[StorageMigrationService] Starting migration check...');
      
      // Check if unified storage is already initialized
      final unifiedService = UnifiedStorageService.instance;
      await unifiedService.init();
      
      // Check if data already exists in unified storage
      final stats = await unifiedService.getDatabaseStats();
      if (stats['servers']! > 0) {
        d('[StorageMigrationService] Unified storage already contains data, skipping migration');
        _migrationCompleted = true;
        return true;
      }
      
      // Perform migration
      await _migrateAllData();
      
      _migrationCompleted = true;
      d('[StorageMigrationService] Migration completed successfully');
      return true;
      
    } catch (e) {
      d('[StorageMigrationService] Migration failed: $e');
      return false;
    }
  }
  
  /// Migrate all data from old storage systems to unified storage
  static Future<void> _migrateAllData() async {
    d('[StorageMigrationService] Starting comprehensive data migration...');
    
    final unifiedService = UnifiedStorageService.instance;
    
    // Migrate Hive data
    await _migrateHiveData(unifiedService);
    
    // Migrate SQLite data
    await _migrateSQLiteData(unifiedService);
    
    // Migrate Enhanced Business Data
    await _migrateEnhancedBusinessData(unifiedService);
    
    d('[StorageMigrationService] All data migration completed');
  }
  
  /// Migrate data from Hive storage
  static Future<void> _migrateHiveData(UnifiedStorageService unifiedService) async {
    d('[StorageMigrationService] Migrating Hive data...');
    
    try {
      // Migrate servers
      final servers = await Storage.serversBox.get('list') as List? ?? [];
      d('[StorageMigrationService] Found ${servers.length} servers in Hive');
      
      for (final serverData in servers) {
        try {
          final server = Server.fromMap(Map<String, dynamic>.from(serverData));
          await unifiedService.saveServer(server);
        } catch (e) {
          d('[StorageMigrationService] Error migrating server: $e');
        }
      }
      
      // Migrate shifts
      final shifts = await Storage.shiftsBox.get('list') as List? ?? [];
      d('[StorageMigrationService] Found ${shifts.length} shifts in Hive');
      
      for (final shiftData in shifts) {
        try {
          final shift = ShiftRecord.fromMap(Map<String, dynamic>.from(shiftData));
          await unifiedService.saveShift(shift);
        } catch (e) {
          d('[StorageMigrationService] Error migrating shift: $e');
        }
      }
      
      // Migrate profiles
      final profiles = await Storage.profilesBox.getAll();
      d('[StorageMigrationService] Found ${profiles.length} profiles in Hive');
      
      for (final entry in profiles.entries) {
        try {
          final profile = ServerProfile.fromMap(Map<String, dynamic>.from(entry.value));
          await unifiedService.saveServerProfile(entry.key, profile);
        } catch (e) {
          d('[StorageMigrationService] Error migrating profile: $e');
        }
      }
      
      // Migrate settings
      final settings = await Storage.settingsBox.getAll();
      d('[StorageMigrationService] Found ${settings.length} settings in Hive');
      
      for (final entry in settings.entries) {
        try {
          await unifiedService.setSetting(entry.key, entry.value);
        } catch (e) {
          d('[StorageMigrationService] Error migrating setting: $e');
        }
      }
      
      // Migrate day plans
      final dayPlans = await Storage.dayPlanBox.getAll();
      d('[StorageMigrationService] Found ${dayPlans.length} day plans in Hive');
      
      for (final entry in dayPlans.entries) {
        try {
          await unifiedService.saveDayPlanData(entry.key, Map<String, dynamic>.from(entry.value));
        } catch (e) {
          d('[StorageMigrationService] Error migrating day plan: $e');
        }
      }
      
      // Migrate tap logs
      final tapLogs = await Storage.tapBox.getAll();
      d('[StorageMigrationService] Found ${tapLogs.length} tap logs in Hive');
      
      for (final entry in tapLogs.entries) {
        try {
          await unifiedService.saveTapLogData(entry.key, Map<String, dynamic>.from(entry.value));
        } catch (e) {
          d('[StorageMigrationService] Error migrating tap log: $e');
        }
      }
      
      // Migrate tap timestamps
      final tapTimestamps = await Storage.tapTimestampsBox.getAll();
      d('[StorageMigrationService] Found ${tapTimestamps.length} tap timestamps in Hive');
      
      for (final entry in tapTimestamps.entries) {
        try {
          await unifiedService.saveTapLogData('timestamps_${entry.key}', Map<String, dynamic>.from(entry.value));
        } catch (e) {
          d('[StorageMigrationService] Error migrating tap timestamp: $e');
        }
      }
      
      d('[StorageMigrationService] Hive data migration completed');
      
    } catch (e) {
      d('[StorageMigrationService] Error migrating Hive data: $e');
      rethrow;
    }
  }
  
  /// Migrate data from SQLite/Sqflite storage
  static Future<void> _migrateSQLiteData(UnifiedStorageService unifiedService) async {
    d('[StorageMigrationService] Migrating SQLite data...');
    
    try {
      final npsAdapter = NPSDatabaseAdapter(DatabaseFactory.instance);
      
      // Migrate NPS feedback
      final feedback = await npsAdapter.getAllNPSFeedback();
      d('[StorageMigrationService] Found ${feedback.length} NPS feedback records');
      
      for (final record in feedback) {
        try {
          await unifiedService.saveNPSFeedback(record);
        } catch (e) {
          d('[StorageMigrationService] Error migrating NPS feedback: $e');
        }
      }
      
      // Migrate monthly reports
      final reports = await npsAdapter.getAllMonthlyReports();
      d('[StorageMigrationService] Found ${reports.length} monthly reports');
      
      for (final report in reports) {
        try {
          await unifiedService.saveMonthlyReport(report);
        } catch (e) {
          d('[StorageMigrationService] Error migrating monthly report: $e');
        }
      }
      
      d('[StorageMigrationService] SQLite data migration completed');
      
    } catch (e) {
      d('[StorageMigrationService] Error migrating SQLite data: $e');
      // Don't rethrow - SQLite data might not exist yet
      d('[StorageMigrationService] Continuing without SQLite data...');
    }
  }
  
  /// Migrate Enhanced Business Data
  static Future<void> _migrateEnhancedBusinessData(UnifiedStorageService unifiedService) async {
    d('[StorageMigrationService] Migrating Enhanced Business Data...');
    
    try {
      // Migrate performance data
      final performanceData = await Storage.performanceBox.getAll();
      d('[StorageMigrationService] Found ${performanceData.length} performance data records');
      
      for (final entry in performanceData.entries) {
        try {
          final data = Map<String, dynamic>.from(entry.value);
          final serverId = data['serverId'] as String? ?? entry.key;
          await unifiedService.savePerformanceData(serverId, 'performance', data);
        } catch (e) {
          d('[StorageMigrationService] Error migrating performance data: $e');
        }
      }
      
      // Migrate business data
      final businessData = await Storage.businessDataBox.getAll();
      d('[StorageMigrationService] Found ${businessData.length} business data records');
      
      for (final entry in businessData.entries) {
        try {
          final data = Map<String, dynamic>.from(entry.value);
          final monthYear = data['month'] as String? ?? entry.key;
          await unifiedService.saveBusinessData(monthYear, 'monthly', data);
        } catch (e) {
          d('[StorageMigrationService] Error migrating business data: $e');
        }
      }
      
      // Migrate enhanced business data
      final enhancedBusinessData = await Storage.enhancedBusinessDataBox.getAll();
      d('[StorageMigrationService] Found ${enhancedBusinessData.length} enhanced business data records');
      
      for (final entry in enhancedBusinessData.entries) {
        try {
          final data = Map<String, dynamic>.from(entry.value);
          final monthYear = data['month'] as String? ?? entry.key;
          await unifiedService.saveBusinessData(monthYear, 'enhanced', data);
        } catch (e) {
          d('[StorageMigrationService] Error migrating enhanced business data: $e');
        }
      }
      
      // Migrate performance settings
      final performanceSettings = await Storage.performanceSettingsBox.getAll();
      d('[StorageMigrationService] Found ${performanceSettings.length} performance settings');
      
      for (final entry in performanceSettings.entries) {
        try {
          await unifiedService.setSetting('performance_${entry.key}', entry.value);
        } catch (e) {
          d('[StorageMigrationService] Error migrating performance setting: $e');
        }
      }
      
      // Migrate station data
      final stationData = await Storage.stationsBox.getAll();
      d('[StorageMigrationService] Found ${stationData.length} station data records');
      
      for (final entry in stationData.entries) {
        try {
          await unifiedService.setSetting('station_${entry.key}', entry.value);
        } catch (e) {
          d('[StorageMigrationService] Error migrating station data: $e');
        }
      }
      
      // Migrate assets
      final assets = await Storage.assetsBox.getAll();
      d('[StorageMigrationService] Found ${assets.length} asset records');
      
      for (final entry in assets.entries) {
        try {
          await unifiedService.saveAssetData(entry.key, Map<String, dynamic>.from(entry.value));
        } catch (e) {
          d('[StorageMigrationService] Error migrating asset: $e');
        }
      }
      
      d('[StorageMigrationService] Enhanced Business Data migration completed');
      
    } catch (e) {
      d('[StorageMigrationService] Error migrating Enhanced Business Data: $e');
      // Don't rethrow - Enhanced Business Data might not exist yet
      d('[StorageMigrationService] Continuing without Enhanced Business Data...');
    }
  }
  
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
