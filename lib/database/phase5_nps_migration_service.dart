import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../storage.dart';
import '../storage/nps_database.dart';
import '../services/server_id_resolver.dart';
import '../utils/log.dart';

class Phase5NPSMigrationService {
  static const String _tag = 'Phase5NPSMigration';

  Future<Phase5MigrationReport> migrateNPSDatabase() async {
    final stopwatch = Stopwatch()..start();
    final report = Phase5MigrationReport();
    
    try {
      d('[$_tag] 🚀 Starting NPS Database ID Migration');
      
      // Step 1: Initialize services
      final npsDb = NPSDatabase.instance;
      final resolver = ServerIdResolver.instance;
      
      // Step 2: Get all records with integer IDs
      final integerRecords = await _findIntegerIDRecords(npsDb);
      report.totalRecords = integerRecords.length;
      d('[$_tag] Found ${integerRecords.length} records with integer IDs');
      
      // Step 3: Load server mapping
      final serverMapping = await _buildServerMapping();
      report.availableMappings = serverMapping.length;
      d('[$_tag] Built mapping for ${serverMapping.length} servers');
      
      // Step 4: Migrate each record
      int successCount = 0;
      int failureCount = 0;
      
      for (final record in integerRecords) {
        try {
          final intId = record['server_id'].toString();
          final stringId = serverMapping[intId];
          
          if (stringId != null) {
            await _migrateRecord(npsDb, record, stringId);
            successCount++;
            d('[$_tag] ✅ Migrated server $intId -> $stringId');
          } else {
            failureCount++;
            d('[$_tag] ❌ No mapping found for server ID: $intId');
            report.unmappedIds.add(intId);
          }
        } catch (e) {
          failureCount++;
          d('[$_tag] ❌ Failed to migrate record: $e');
          report.errors.add('Record migration failed: $e');
        }
      }
      
      report.successfulMigrations = successCount;
      report.failedMigrations = failureCount;
      
      // Step 5: Verify migration
      await _verifyMigration(npsDb, report);
      
      report.executionTimeMs = stopwatch.elapsedMilliseconds;
      report.success = failureCount == 0;
      
      d('[$_tag] ✅ Migration completed: $successCount success, $failureCount failures');
      
    } catch (e) {
      report.success = false;
      report.errors.add('Migration failed: $e');
      d('[$_tag] ❌ Migration failed: $e');
    } finally {
      stopwatch.stop();
    }
    
    return report;
  }
  
  Future<List<Map<String, dynamic>>> _findIntegerIDRecords(NPSDatabase npsDb) async {
    // Find all records where server_id looks like an integer
    final db = await npsDb.database;
    
    // Get all unique server_ids that are numeric
    final results = await db.rawQuery('''
      SELECT DISTINCT server_id, COUNT(*) as record_count
      FROM nps_entries 
      WHERE server_id GLOB '[0-9]*'
      AND LENGTH(server_id) < 10
      GROUP BY server_id
      ORDER BY CAST(server_id AS INTEGER)
    ''');
    
    return results;
  }
  
  Future<Map<String, String>> _buildServerMapping() async {
    final mapping = <String, String>{};
    
    try {
      // Get servers from main app storage
      final serversList = (await Storage.serversBox.get('list') as List?)?.cast<Map>() ?? [];
      final servers = serversList;
      
      // Build mapping from old integer IDs to new string IDs
      // This assumes servers were originally added in order
      for (int i = 0; i < servers.length; i++) {
        final server = servers[i];
        final oldId = (i + 1).toString(); // Integer IDs started from 1
        final newId = server['id'].toString();
        mapping[oldId] = newId;
        
        d('[$_tag] Mapping: $oldId -> $newId (${server['name']})');
      }
      
    } catch (e) {
      d('[$_tag] ❌ Failed to build server mapping: $e');
    }
    
    return mapping;
  }
  
  Future<void> _migrateRecord(NPSDatabase npsDb, Map<String, dynamic> record, String newServerId) async {
    final db = await npsDb.database;
    final oldServerId = record['server_id'].toString();
    
    // Update all records with this server_id
    await db.rawUpdate('''
      UPDATE nps_entries 
      SET server_id = ? 
      WHERE server_id = ?
    ''', [newServerId, oldServerId]);
  }
  
  Future<void> _verifyMigration(NPSDatabase npsDb, Phase5MigrationReport report) async {
    try {
      final db = await npsDb.database;
      
      // Count remaining integer IDs
      final remainingInts = await db.rawQuery('''
        SELECT COUNT(*) as count
        FROM nps_entries 
        WHERE server_id GLOB '[0-9]*'
        AND LENGTH(server_id) < 10
      ''');
      
      final remainingCount = remainingInts.first['count'] as int;
      report.remainingIntegerIds = remainingCount;
      
      // Count total records
      final totalRecords = await db.rawQuery('SELECT COUNT(*) as count FROM nps_entries');
      report.totalRecordsAfter = totalRecords.first['count'] as int;
      
      d('[$_tag] Verification: $remainingCount integer IDs remaining, ${report.totalRecordsAfter} total records');
      
    } catch (e) {
      report.errors.add('Verification failed: $e');
    }
  }
}

class Phase5MigrationReport {
  bool success = false;
  int executionTimeMs = 0;
  int totalRecords = 0;
  int availableMappings = 0;
  int successfulMigrations = 0;
  int failedMigrations = 0;
  int remainingIntegerIds = 0;
  int totalRecordsAfter = 0;
  List<String> unmappedIds = [];
  List<String> errors = [];
  
  double get successRate => totalRecords > 0 ? (successfulMigrations / totalRecords) * 100 : 0;
  
  bool get isComplete => remainingIntegerIds == 0;
  
  String get status {
    if (!success) return 'Failed';
    if (isComplete) return 'Complete';
    if (successfulMigrations > 0) return 'Partial';
    return 'Not Started';
  }
  
  Map<String, dynamic> toJson() => {
    'success': success,
    'executionTimeMs': executionTimeMs,
    'totalRecords': totalRecords,
    'availableMappings': availableMappings,
    'successfulMigrations': successfulMigrations,
    'failedMigrations': failedMigrations,
    'remainingIntegerIds': remainingIntegerIds,
    'totalRecordsAfter': totalRecordsAfter,
    'unmappedIds': unmappedIds,
    'errors': errors,
    'successRate': successRate,
    'isComplete': isComplete,
    'status': status,
  };
}