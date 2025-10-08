import 'dart:io';
import '../services/storage_migration_service.dart';
import '../services/unified_storage_service.dart';
import '../utils/log.dart';

/// Migration Script for Unified Storage
/// 
/// This script helps migrate from the old multi-storage architecture
/// to the new unified Drift-based storage system.
class UnifiedStorageMigrationScript {
  
  /// Run the complete migration process
  static Future<bool> runMigration() async {
    print('🚀 Starting Unified Storage Migration...\n');
    
    try {
      // Step 1: Create backup
      print('📦 Step 1: Creating pre-migration backup...');
      final backupPath = await StorageMigrationService.createPreMigrationBackup();
      if (backupPath == null) {
        print('❌ Failed to create backup. Migration aborted.');
        return false;
      }
      print('✅ Backup created: $backupPath\n');
      
      // Step 2: Run migration
      print('🔄 Step 2: Migrating data to unified storage...');
      final migrationSuccess = await StorageMigrationService.migrateIfNeeded();
      if (!migrationSuccess) {
        print('❌ Migration failed. Attempting rollback...');
        await StorageMigrationService.rollbackMigration(backupPath);
        return false;
      }
      print('✅ Data migration completed\n');
      
      // Step 3: Validate migration
      print('🔍 Step 3: Validating migration results...');
      final validationSuccess = await StorageMigrationService.validateMigration();
      if (!validationSuccess) {
        print('❌ Migration validation failed. Attempting rollback...');
        await StorageMigrationService.rollbackMigration(backupPath);
        return false;
      }
      print('✅ Migration validation passed\n');
      
      // Step 4: Show statistics
      print('📊 Step 4: Migration statistics:');
      await _showMigrationStats();
      
      print('\n🎉 Migration completed successfully!');
      print('💡 You can now use the unified storage system.');
      print('🗑️  Old storage files can be safely removed after testing.');
      
      return true;
      
    } catch (e) {
      print('❌ Migration failed with error: $e');
      return false;
    }
  }
  
  /// Show migration statistics
  static Future<void> _showMigrationStats() async {
    try {
      final unifiedService = UnifiedStorageService.instance;
      final stats = await unifiedService.getDatabaseStats();
      
      print('   📈 Database Statistics:');
      print('   ├── Servers: ${stats['servers'] ?? 0}');
      print('   ├── Shifts: ${stats['shifts'] ?? 0}');
      print('   ├── NPS Feedback: ${stats['nps_feedback'] ?? 0}');
      print('   └── Monthly Reports: ${stats['monthly_reports'] ?? 0}');
      
      final totalRecords = stats.values.fold(0, (sum, count) => sum + (count ?? 0));
      print('   📊 Total Records: $totalRecords');
      
    } catch (e) {
      print('   ⚠️  Could not retrieve statistics: $e');
    }
  }
  
  /// Test the unified storage system
  static Future<bool> testUnifiedStorage() async {
    print('🧪 Testing Unified Storage System...\n');
    
    try {
      final unifiedService = UnifiedStorageService.instance;
      await unifiedService.init();
      
      // Test basic operations
      print('📝 Testing basic operations...');
      
      // Test server operations
      final testServer = Server(
        id: 'test_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Test Server',
        teamColor: '#FF0000',
        stationType: 'test',
        hireDate: DateTime.now(),
      );
      
      await unifiedService.saveServer(testServer);
      final servers = await unifiedService.getAllServers();
      final serverFound = servers.any((s) => s.id == testServer.id);
      
      if (!serverFound) {
        print('❌ Server operations test failed');
        return false;
      }
      print('✅ Server operations working');
      
      // Test settings operations
      await unifiedService.setSetting('test_key', 'test_value');
      final settingValue = await unifiedService.getSetting<String>('test_key');
      
      if (settingValue != 'test_value') {
        print('❌ Settings operations test failed');
        return false;
      }
      print('✅ Settings operations working');
      
      // Clean up test data
      await unifiedService.deleteServer(testServer.id);
      await unifiedService.setSetting('test_key', null);
      
      print('✅ Unified storage system is working correctly\n');
      return true;
      
    } catch (e) {
      print('❌ Unified storage test failed: $e\n');
      return false;
    }
  }
  
  /// Rollback migration
  static Future<bool> rollbackMigration(String backupPath) async {
    print('🔄 Rolling back migration...\n');
    
    try {
      final success = await StorageMigrationService.rollbackMigration(backupPath);
      if (success) {
        print('✅ Migration rollback completed successfully');
      } else {
        print('❌ Migration rollback failed');
      }
      return success;
    } catch (e) {
      print('❌ Rollback failed with error: $e');
      return false;
    }
  }
  
  /// Show help information
  static void showHelp() {
    print('''
🔧 Unified Storage Migration Script

Usage:
  dart run lib/scripts/migrate_to_unified_storage.dart [command]

Commands:
  migrate     - Run the complete migration process
  test        - Test the unified storage system
  rollback    - Rollback migration (requires backup path)
  help        - Show this help message

Examples:
  dart run lib/scripts/migrate_to_unified_storage.dart migrate
  dart run lib/scripts/migrate_to_unified_storage.dart test
  dart run lib/scripts/migrate_to_unified_storage.dart rollback /path/to/backup.json

Notes:
  - Always create a backup before migration
  - Test the unified storage system after migration
  - Keep the backup until you're confident everything works
  - Old storage files can be removed after successful migration
''');
  }
}

/// Main function for command-line usage
void main(List<String> args) async {
  if (args.isEmpty) {
    UnifiedStorageMigrationScript.showHelp();
    return;
  }
  
  final command = args[0].toLowerCase();
  
  switch (command) {
    case 'migrate':
      final success = await UnifiedStorageMigrationScript.runMigration();
      exit(success ? 0 : 1);
      
    case 'test':
      final success = await UnifiedStorageMigrationScript.testUnifiedStorage();
      exit(success ? 0 : 1);
      
    case 'rollback':
      if (args.length < 2) {
        print('❌ Rollback requires backup path');
        print('Usage: dart run lib/scripts/migrate_to_unified_storage.dart rollback /path/to/backup.json');
        exit(1);
      }
      final success = await UnifiedStorageMigrationScript.rollbackMigration(args[1]);
      exit(success ? 0 : 1);
      
    case 'help':
    default:
      UnifiedStorageMigrationScript.showHelp();
      exit(0);
  }
}





