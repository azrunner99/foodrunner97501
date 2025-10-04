import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../storage/nps_database.dart';
import '../storage.dart';
import '../utils/log.dart';
import 'nps_table_test.dart';

/// Simplified Phase 5 diagnostic service to identify the exact issue
class Phase5DiagnosticService {
  static const String _tag = 'Phase5Diagnostic';

  Future<Map<String, dynamic>> runDiagnostic() async {
    final result = <String, dynamic>{
      'success': false,
      'errors': <String>[],
      'npsRecordCount': 0,
      'integerIdCount': 0,
      'sampleIntegerIds': <String>[],
      'serverCount': 0,
      'sampleServers': <String>[],
      'databaseExists': false,
      'tableExists': false,
      'tableColumns': <String>[],
    };

    try {
      d('[$_tag] 🔍 Starting diagnostic...');

      // Test 1: Check NPS database structure first
      try {
        final structureTest = await NPSTableTest.checkDatabaseStructure();
        result['databaseExists'] = structureTest['databaseExists'];
        result['tableExists'] = structureTest['tableExists'];
        result['tableColumns'] = structureTest['tableInfo'];
        
        if (!structureTest['databaseExists']) {
          result['errors'].add('NPS Database does not exist');
          d('[$_tag] ❌ NPS Database does not exist');
          return result;
        }
        
        if (!structureTest['tableExists']) {
          result['errors'].add('NPS table "nps_entries" does not exist');
          d('[$_tag] ❌ NPS table does not exist');
          return result;
        }
        
        d('[$_tag] ✅ NPS Database structure OK');
        
      } catch (e) {
        result['errors'].add('Database structure test failed: $e');
        d('[$_tag] ❌ Database structure test failed: $e');
        return result;
      }

      // Test 2: Check NPS database access
      try {
        final npsDb = NPSDatabase.instance;
        final db = await npsDb.database;
        
        // Count total NPS records
        final totalRecords = await db.rawQuery('SELECT COUNT(*) as count FROM nps_entries');
        result['npsRecordCount'] = totalRecords.first['count'] as int;
        d('[$_tag] ✅ NPS Database accessible: ${result['npsRecordCount']} records');
        
        // Find integer server IDs
        final integerIds = await db.rawQuery('''
          SELECT DISTINCT server_id, COUNT(*) as record_count
          FROM nps_entries 
          WHERE server_id GLOB '[0-9]*'
          AND LENGTH(server_id) < 10
          GROUP BY server_id
          ORDER BY CAST(server_id AS INTEGER)
          LIMIT 10
        ''');
        
        result['integerIdCount'] = integerIds.length;
        result['sampleIntegerIds'] = integerIds.map((row) => '${row['server_id']} (${row['record_count']} records)').toList();
        d('[$_tag] Found ${integerIds.length} distinct integer IDs');
        
      } catch (e) {
        result['errors'].add('NPS Database error: $e');
        d('[$_tag] ❌ NPS Database error: $e');
      }

      // Test 3: Check main app server storage
      try {
        final serversList = (await Storage.serversBox.get('list') as List?)?.cast<Map>() ?? [];
        result['serverCount'] = serversList.length;
        result['sampleServers'] = serversList.take(5).map((server) => '${server['name']} (ID: ${server['id']})').toList();
        d('[$_tag] ✅ Main storage accessible: ${serversList.length} servers');
      } catch (e) {
        result['errors'].add('Main storage error: $e');
        d('[$_tag] ❌ Main storage error: $e');
      }

      result['success'] = result['errors'].isEmpty;
      d('[$_tag] Diagnostic complete: ${result['success'] ? 'SUCCESS' : 'ERRORS FOUND'}');
      
    } catch (e) {
      result['errors'].add('Diagnostic failed: $e');
      d('[$_tag] ❌ Diagnostic failed: $e');
    }

    return result;
  }
}