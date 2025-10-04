import 'dart:async';
import '../storage/nps_database.dart';
import '../utils/log.dart';

/// Emergency NPS Database Schema Repair
/// Fixes missing columns and ensures data can be saved properly
class NPSDatabaseSchemaRepair {
  static Future<void> repairDatabase() async {
    try {
      d('🔧 EMERGENCY NPS DATABASE SCHEMA REPAIR');
      
      final npsDb = NPSDatabase.instance;
      final db = await npsDb.database;
      
      // Check if servers table has original_id column
      final tableInfo = await db.rawQuery('PRAGMA table_info(servers)');
      final hasOriginalId = tableInfo.any((column) => column['name'] == 'original_id');
      
      if (!hasOriginalId) {
        d('❌ Missing original_id column in servers table - ADDING IT NOW');
        await db.execute('ALTER TABLE servers ADD COLUMN original_id TEXT');
        d('✅ Added original_id column to servers table');
      } else {
        d('✅ servers table already has original_id column');
      }
      
      // Verify table structure is correct
      final updatedTableInfo = await db.rawQuery('PRAGMA table_info(servers)');
      d('📋 Updated servers table structure:');
      for (final column in updatedTableInfo) {
        d('   • ${column['name']}: ${column['type']} ${column['notnull'] == 1 ? 'NOT NULL' : ''}');
      }
      
      // Clear any existing server data to force fresh sync
      await db.execute('DELETE FROM servers');
      d('🗑️ Cleared existing server data to force fresh sync');
      
      d('✅ DATABASE SCHEMA REPAIR COMPLETED');
      d('💡 Server data will sync on next app restart');
      
    } catch (e) {
      d('❌ Database schema repair failed: $e');
      rethrow;
    }
  }
}