import '../storage.dart';
import '../services/unified_storage_service.dart';
import '../models.dart';
import '../app_state.dart' show ServerProfile;
import '../utils/log.dart';

/// Phase 2.5: Hive to Unified Database Migration Service
/// 
/// Migrates data from Hive boxes (legacy storage) to UnifiedDatabase (new storage)
/// Maintains data integrity and provides rollback capability.
class HiveToUnifiedMigrationService {
  static HiveToUnifiedMigrationService? _instance;
  static HiveToUnifiedMigrationService get instance => _instance ??= HiveToUnifiedMigrationService._();
  
  HiveToUnifiedMigrationService._();
  
  /// Check if migration is needed
  Future<bool> isMigrationNeeded() async {
    try {
      // Check if UnifiedDatabase has any data
      final stats = await UnifiedStorageService.instance.getDatabaseStats();
      final hasData = stats.values.any((count) => count > 0);
      
      if (hasData) {
        d('[HiveMigration] UnifiedDatabase has data, migration may not be needed');
        return false;
      }
      
      // Check if Hive has data to migrate
      final hiveServers = (await Storage.serversBox.get('list') as List?)?.cast<Map>() ?? [];
      final hiveShifts = (await Storage.shiftsBox.get('list') as List?)?.cast<Map>() ?? [];
      
      final hiveHasData = hiveServers.isNotEmpty || hiveShifts.isNotEmpty;
      
      d('[HiveMigration] Migration needed: $hiveHasData (Servers: ${hiveServers.length}, Shifts: ${hiveShifts.length})');
      return hiveHasData;
    } catch (e) {
      d('[HiveMigration] Error checking migration status: $e');
      return false;
    }
  }
  
  /// Migrate all data from Hive to UnifiedDatabase
  Future<Map<String, dynamic>> migrateAllData({bool dryRun = false}) async {
    d('[HiveMigration] ${dryRun ? 'DRY RUN:' : ''} Starting data migration...');
    
    final result = {
      'servers': await _migrateServers(dryRun: dryRun),
      'shifts': await _migrateShifts(dryRun: dryRun),
      'profiles': await _migrateProfiles(dryRun: dryRun),
      'settings': await _migrateSettings(dryRun: dryRun),
      'tapLogs': await _migrateTapLogs(dryRun: dryRun),
      'dayPlans': await _migrateDayPlans(dryRun: dryRun),
      'assets': await _migrateAssets(dryRun: dryRun),
    };
    
    final totalMigrated = result.values.fold<int>(0, (sum, r) => sum + (r['migrated'] as int));
    final totalErrors = result.values.fold<int>(0, (sum, r) => sum + (r['errors'] as int));
    
    result['summary'] = {
      'totalMigrated': totalMigrated,
      'totalErrors': totalErrors,
      'success': totalErrors == 0,
      'dryRun': dryRun,
    };
    
    d('[HiveMigration] ${dryRun ? 'DRY RUN ' : ''}Migration complete: $totalMigrated migrated, $totalErrors errors');
    
    return result;
  }
  
  /// Migrate servers from Hive to UnifiedDatabase
  Future<Map<String, dynamic>> _migrateServers({bool dryRun = false}) async {
    d('[HiveMigration] Migrating servers...');
    
    try {
      final serversList = (await Storage.serversBox.get('list') as List?)?.cast<Map>() ?? [];
      
      if (serversList.isEmpty) {
        d('[HiveMigration] No servers to migrate');
        return {'migrated': 0, 'errors': 0, 'skipped': 0};
      }
      
      int migrated = 0;
      int errors = 0;
      final errorDetails = <String>[];
      
      for (final serverMap in serversList) {
        try {
          final server = Server.fromMap(Map<String, dynamic>.from(serverMap));
          
          if (!dryRun) {
            await UnifiedStorageService.instance.saveServer(server);
          }
          
          migrated++;
          d('[HiveMigration] ${dryRun ? '[DRY RUN] ' : ''}Migrated server: ${server.name} (${server.id})');
        } catch (e) {
          errors++;
          errorDetails.add('Server error: $e');
          d('[HiveMigration] Error migrating server: $e');
        }
      }
      
      return {
        'migrated': migrated,
        'errors': errors,
        'errorDetails': errorDetails,
        'total': serversList.length,
      };
    } catch (e) {
      d('[HiveMigration] Error migrating servers: $e');
      return {'migrated': 0, 'errors': 1, 'errorDetails': [e.toString()]};
    }
  }
  
  /// Migrate shifts from Hive to UnifiedDatabase
  Future<Map<String, dynamic>> _migrateShifts({bool dryRun = false}) async {
    d('[HiveMigration] Migrating shifts...');
    
    try {
      final shiftsList = (await Storage.shiftsBox.get('list') as List?)?.cast<Map>() ?? [];
      
      if (shiftsList.isEmpty) {
        d('[HiveMigration] No shifts to migrate');
        return {'migrated': 0, 'errors': 0, 'skipped': 0};
      }
      
      int migrated = 0;
      int errors = 0;
      final errorDetails = <String>[];
      
      for (final shiftMap in shiftsList) {
        try {
          final shift = ShiftRecord.fromMap(Map<String, dynamic>.from(shiftMap));
          
          if (!dryRun) {
            await UnifiedStorageService.instance.saveShift(shift);
          }
          
          migrated++;
          d('[HiveMigration] ${dryRun ? '[DRY RUN] ' : ''}Migrated shift: ${shift.label} (${shift.id})');
        } catch (e) {
          errors++;
          errorDetails.add('Shift error: $e');
          d('[HiveMigration] Error migrating shift: $e');
        }
      }
      
      return {
        'migrated': migrated,
        'errors': errors,
        'errorDetails': errorDetails,
        'total': shiftsList.length,
      };
    } catch (e) {
      d('[HiveMigration] Error migrating shifts: $e');
      return {'migrated': 0, 'errors': 1, 'errorDetails': [e.toString()]};
    }
  }
  
  /// Migrate server profiles from Hive to UnifiedDatabase
  Future<Map<String, dynamic>> _migrateProfiles({bool dryRun = false}) async {
    d('[HiveMigration] Migrating server profiles...');
    
    try {
      // Get list of servers to know which profiles to migrate
      final serversList = (await Storage.serversBox.get('list') as List?)?.cast<Map>() ?? [];
      
      int migrated = 0;
      int errors = 0;
      final errorDetails = <String>[];
      
      for (final serverMap in serversList) {
        try {
          final serverId = serverMap['id'] as String;
          final profileMap = (await Storage.profilesBox.get(serverId) as Map?) ?? {};
          
          if (profileMap.isEmpty) {
            continue;  // No profile for this server
          }
          
          final profile = ServerProfile.fromMap(profileMap);
          
          if (!dryRun) {
            await UnifiedStorageService.instance.saveServerProfile(serverId, profile);
          }
          
          migrated++;
          d('[HiveMigration] ${dryRun ? '[DRY RUN] ' : ''}Migrated profile for: $serverId');
        } catch (e) {
          errors++;
          errorDetails.add('Profile error: $e');
          d('[HiveMigration] Error migrating profile: $e');
        }
      }
      
      return {
        'migrated': migrated,
        'errors': errors,
        'errorDetails': errorDetails,
        'total': serversList.length,
      };
    } catch (e) {
      d('[HiveMigration] Error migrating profiles: $e');
      return {'migrated': 0, 'errors': 1, 'errorDetails': [e.toString()]};
    }
  }
  
  /// Migrate settings from Hive to UnifiedDatabase
  Future<Map<String, dynamic>> _migrateSettings({bool dryRun = false}) async {
    d('[HiveMigration] Migrating settings...');
    
    try {
      // Key settings to migrate
      final settingsKeys = [
        'adminPin',
        'weekly_hours',
        'schemaVersion',
        'gamificationEnabled',
        'transition_checkpoint',
      ];
      
      int migrated = 0;
      int errors = 0;
      
      for (final key in settingsKeys) {
        try {
          final value = await Storage.settingsBox.get(key);
          
          if (value != null) {
            if (!dryRun) {
              await UnifiedStorageService.instance.setSetting(key, value);
            }
            migrated++;
            d('[HiveMigration] ${dryRun ? '[DRY RUN] ' : ''}Migrated setting: $key');
          }
        } catch (e) {
          errors++;
          d('[HiveMigration] Error migrating setting $key: $e');
        }
      }
      
      return {
        'migrated': migrated,
        'errors': errors,
        'total': settingsKeys.length,
      };
    } catch (e) {
      d('[HiveMigration] Error migrating settings: $e');
      return {'migrated': 0, 'errors': 1, 'errorDetails': [e.toString()]};
    }
  }
  
  /// Migrate tap logs
  Future<Map<String, dynamic>> _migrateTapLogs({bool dryRun = false}) async {
    d('[HiveMigration] Migrating tap logs...');
    // For now, skip tap logs - they can be regenerated
    return {'migrated': 0, 'errors': 0, 'skipped': true};
  }
  
  /// Migrate day plans
  Future<Map<String, dynamic>> _migrateDayPlans({bool dryRun = false}) async {
    d('[HiveMigration] Migrating day plans...');
    // Day plans can be kept in Hive for now
    return {'migrated': 0, 'errors': 0, 'skipped': true};
  }
  
  /// Migrate assets
  Future<Map<String, dynamic>> _migrateAssets({bool dryRun = false}) async {
    d('[HiveMigration] Migrating assets...');
    // Assets (avatars/banners) can stay in Hive for now
    return {'migrated': 0, 'errors': 0, 'skipped': true};
  }
  
  /// Verify migration integrity
  Future<Map<String, dynamic>> verifyMigration() async {
    d('[HiveMigration] Verifying migration integrity...');
    
    try {
      // Compare counts
      final hiveServers = ((await Storage.serversBox.get('list') as List?)?.cast<Map>() ?? []).length;
      final hiveShifts = ((await Storage.shiftsBox.get('list') as List?)?.cast<Map>() ?? []).length;
      
      final unifiedServers = (await UnifiedStorageService.instance.getAllServers()).length;
      final unifiedShifts = (await UnifiedStorageService.instance.getAllShifts()).length;
      
      final result = {
        'servers': {
          'hive': hiveServers,
          'unified': unifiedServers,
          'match': hiveServers == unifiedServers,
        },
        'shifts': {
          'hive': hiveShifts,
          'unified': unifiedShifts,
          'match': hiveShifts == unifiedShifts,
        },
        'overallMatch': hiveServers == unifiedServers && hiveShifts == unifiedShifts,
      };
      
      d('[HiveMigration] Verification: ${result['overallMatch'] == true ? '✅ PASS' : '⚠️ MISMATCH'}');
      d('[HiveMigration] Servers: Hive=$hiveServers, Unified=$unifiedServers');
      d('[HiveMigration] Shifts: Hive=$hiveShifts, Unified=$unifiedShifts');
      
      return result;
    } catch (e) {
      d('[HiveMigration] Error verifying migration: $e');
      return {'error': e.toString(), 'overallMatch': false};
    }
  }
  
  /// Generate migration report
  Future<String> generateMigrationReport() async {
    final buffer = StringBuffer();
    
    buffer.writeln('=== Hive to Unified Database Migration Report ===');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('');
    
    // Check if migration is needed
    final needed = await isMigrationNeeded();
    buffer.writeln('Migration Needed: ${needed ? 'YES' : 'NO'}');
    buffer.writeln('');
    
    // Current state
    final hiveServers = ((await Storage.serversBox.get('list') as List?)?.cast<Map>() ?? []).length;
    final hiveShifts = ((await Storage.shiftsBox.get('list') as List?)?.cast<Map>() ?? []).length;
    
    final unifiedStats = await UnifiedStorageService.instance.getDatabaseStats();
    
    buffer.writeln('Current Data Counts:');
    buffer.writeln('  Hive Storage:');
    buffer.writeln('    Servers: $hiveServers');
    buffer.writeln('    Shifts: $hiveShifts');
    buffer.writeln('');
    buffer.writeln('  UnifiedDatabase:');
    for (final entry in unifiedStats.entries) {
      buffer.writeln('    ${entry.key}: ${entry.value}');
    }
    
    return buffer.toString();
  }
}

