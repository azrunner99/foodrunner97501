import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../storage/nps_database.dart';
import '../utils/log.dart';

/// Basic NPS database structure test
class NPSTableTest {
  static Future<Map<String, dynamic>> checkDatabaseStructure() async {
    final result = <String, dynamic>{
      'databaseExists': false,
      'tableExists': false,
      'tableInfo': <String>[],
      'sampleData': <String>[],
      'error': null,
    };

    try {
      d('NPSTableTest: Starting database structure check...');
      
      // Get database instance
      final npsDb = NPSDatabase.instance;
      final db = await npsDb.database;
      result['databaseExists'] = true;
      d('NPSTableTest: Database instance created successfully');
      
      // Check if nps_entries table exists
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='nps_entries'");
      result['tableExists'] = tables.isNotEmpty;
      d('NPSTableTest: Table exists: ${result['tableExists']}');
      
      if (result['tableExists']) {
        // Get table structure
        final tableInfo = await db.rawQuery("PRAGMA table_info(nps_entries)");
        result['tableInfo'] = tableInfo.map((row) => '${row['name']} (${row['type']})').toList();
        d('NPSTableTest: Table columns: ${result['tableInfo']}');
        
        // Get sample data
        final sampleData = await db.rawQuery("SELECT server_id, date, rating FROM nps_entries LIMIT 5");
        result['sampleData'] = sampleData.map((row) => 'ID: ${row['server_id']}, Date: ${row['date']}, Rating: ${row['rating']}').toList();
        d('NPSTableTest: Sample data count: ${sampleData.length}');
      } else {
        d('NPSTableTest: nps_entries table does not exist');
      }
      
    } catch (e) {
      result['error'] = e.toString();
      d('NPSTableTest: Error occurred: $e');
    }

    return result;
  }
}