import 'package:shared_preferences/shared_preferences.dart';
import 'hive_storage.dart';
import 'shared_prefs_storage.dart';
import 'storage_factory.dart';
import '../services/platform_service.dart';

/// Service for migrating data between storage backends
/// 
/// Handles the seamless transition from SharedPreferences (Android/iOS)
/// to Hive storage (Windows/Desktop) while preserving all user data.
class StorageMigrationService {
  static const String _migrationKey = '_migration_completed';
  static const String _migrationVersion = 'v1.0';
  
  /// Check if migration is needed for the current platform
  static bool needsMigration() {
    return PlatformService.isWindows || PlatformService.isDesktop;
  }
  
  /// Perform migration from SharedPreferences to Hive if needed
  /// 
  /// This method:
  /// 1. Checks if migration is needed and not already completed
  /// 2. Exports all data from SharedPreferences
  /// 3. Imports data into Hive storage
  /// 4. Marks migration as completed
  /// 
  /// Returns true if migration was performed, false if not needed
  static Future<bool> migrateIfNeeded() async {
    if (!needsMigration()) {
      print('[Migration] No migration needed on ${PlatformService.platformName}');
      return false;
    }
    
    try {
      // Create Hive storage instance
      final hiveStorage = HiveStorage();
      await hiveStorage.init();
      
      // Check if migration already completed
      final migrationCompleted = await hiveStorage.get(_migrationKey);
      if (migrationCompleted == _migrationVersion) {
        print('[Migration] Migration already completed');
        return false;
      }
      
      // Get data from SharedPreferences
      final sharedPrefs = await SharedPreferences.getInstance();
      final allKeys = sharedPrefs.getKeys();
      
      if (allKeys.isEmpty) {
        print('[Migration] No SharedPreferences data found, skipping migration');
        await hiveStorage.put(_migrationKey, _migrationVersion);
        return false;
      }
      
      print('[Migration] Starting migration of ${allKeys.length} keys...');
      
      // Export data from SharedPreferences
      final migrationData = <String, String>{};
      for (final key in allKeys) {
        final value = sharedPrefs.getString(key);
        if (value != null) {
          migrationData[key] = value;
        }
      }
      
      // Import data into Hive
      await hiveStorage.migrateFromMap(migrationData);
      
      // Mark migration as completed
      await hiveStorage.put(_migrationKey, _migrationVersion);
      
      print('[Migration] Successfully migrated ${migrationData.length} keys');
      return true;
      
    } catch (e) {
      print('[Migration] Migration failed: $e');
      rethrow;
    }
  }
  
  /// Get migration status information
  static Future<Map<String, dynamic>> getMigrationStatus() async {
    try {
      final status = <String, dynamic>{
        'platform': PlatformService.platformName,
        'needsMigration': needsMigration(),
        'backendType': StorageFactory.getBackendType(),
      };
      
      if (needsMigration()) {
        final hiveStorage = HiveStorage();
        await hiveStorage.init();
        
        final migrationCompleted = await hiveStorage.get(_migrationKey);
        status['migrationCompleted'] = migrationCompleted == _migrationVersion;
        status['migrationVersion'] = migrationCompleted ?? 'none';
        
        // Get storage statistics
        final stats = await hiveStorage.getStorageStats();
        status['storageStats'] = stats;
      }
      
      return status;
      
    } catch (e) {
      return {
        'error': e.toString(),
        'platform': PlatformService.platformName,
      };
    }
  }
  
  /// Force re-migration (for testing or recovery)
  static Future<void> resetMigration() async {
    if (!needsMigration()) return;
    
    try {
      final hiveStorage = HiveStorage();
      await hiveStorage.init();
      await hiveStorage.delete(_migrationKey);
      print('[Migration] Migration reset - will run again on next startup');
    } catch (e) {
      print('[Migration] Failed to reset migration: $e');
    }
  }
  
  /// Create a backup of SharedPreferences data before migration
  static Future<Map<String, String>> createBackup() async {
    try {
      final sharedPrefs = await SharedPreferences.getInstance();
      final allKeys = sharedPrefs.getKeys();
      final backup = <String, String>{};
      
      for (final key in allKeys) {
        final value = sharedPrefs.getString(key);
        if (value != null) {
          backup[key] = value;
        }
      }
      
      print('[Migration] Created backup of ${backup.length} keys');
      return backup;
      
    } catch (e) {
      print('[Migration] Failed to create backup: $e');
      return <String, String>{};
    }
  }
  
  /// Validate that migration was successful by comparing key counts
  static Future<bool> validateMigration() async {
    if (!needsMigration()) return true;
    
    try {
      final sharedPrefs = await SharedPreferences.getInstance();
      final sharedPrefsKeys = sharedPrefs.getKeys();
      
      final hiveStorage = HiveStorage();
      await hiveStorage.init();
      final hiveKeys = await hiveStorage.getKeys();
      
      // Remove migration key from comparison
      final hiveDataKeys = hiveKeys.where((key) => key != _migrationKey).toSet();
      
      final isValid = sharedPrefsKeys.length == hiveDataKeys.length;
      
      print('[Migration] Validation: SharedPrefs=${sharedPrefsKeys.length}, Hive=${hiveDataKeys.length}, Valid=$isValid');
      
      return isValid;
      
    } catch (e) {
      print('[Migration] Validation failed: $e');
      return false;
    }
  }
}