import 'dart:async';
import '../storage/nps_database.dart';
import '../utils/log.dart';

/// Emergency NPS Database Inspector
/// Quick diagnostic tool to check what's actually in the NPS database
class NPSDatabaseInspector {
  static Future<void> inspectDatabase() async {
    try {
      d('🔍 EMERGENCY NPS DATABASE INSPECTION');
      
      final npsDb = NPSDatabase.instance;
      final db = await npsDb.database;
      
      // Check if the table exists
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='nps_entries'"
      );
      
      if (tables.isEmpty) {
        d('❌ NPS_ENTRIES TABLE DOES NOT EXIST!');
        return;
      }
      
      d('✅ nps_entries table exists');
      
      // Check table structure
      final tableInfo = await db.rawQuery('PRAGMA table_info(nps_entries)');
      d('📋 Table structure:');
      for (final column in tableInfo) {
        d('   • ${column['name']}: ${column['type']} ${column['notnull'] == 1 ? 'NOT NULL' : ''}');
      }
      
      // Count total entries
      final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM nps_entries');
      final totalCount = countResult.first['count'] as int;
      d('📊 Total entries: $totalCount');
      
      if (totalCount == 0) {
        d('❌ DATABASE IS EMPTY - NO NPS ENTRIES FOUND');
        d('💡 You need to enter some NPS data first!');
        return;
      }
      
      // Show recent entries
      final recentEntries = await db.rawQuery('''
        SELECT 
          id, server_id, rating, date, shift_type, comment, timestamp, created_at
        FROM nps_entries 
        ORDER BY created_at DESC 
        LIMIT 10
      ''');
      
      d('📋 Recent entries:');
      for (final entry in recentEntries) {
        d('   • ID: ${entry['id']}, Server: ${entry['server_id']}, Rating: ${entry['rating']}, Date: ${entry['date']}');
      }
      
      // Check for data issues
      final nullServerIds = await db.rawQuery(
        'SELECT COUNT(*) as count FROM nps_entries WHERE server_id IS NULL OR server_id = ""'
      );
      final nullCount = nullServerIds.first['count'] as int;
      if (nullCount > 0) {
        d('⚠️ Warning: $nullCount entries have null/empty server_ids');
      }
      
      // Check date distribution
      final dateDistribution = await db.rawQuery('''
        SELECT 
          date,
          COUNT(*) as count
        FROM nps_entries 
        GROUP BY date
        ORDER BY date DESC
        LIMIT 5
      ''');
      
      d('📅 Date distribution:');
      for (final row in dateDistribution) {
        d('   • ${row['date']}: ${row['count']} entries');
      }
      
      d('✅ Database inspection complete');
      
    } catch (e) {
      d('❌ Database inspection failed: $e');
    }
  }
}