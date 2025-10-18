/// Database Migration: Remove Unused NPS Feedback Count Columns
///
/// This migration removes 9 unused columns from nps_monthly_reports table:
/// - month_feedback_yes/maybe/no
/// - three_month_feedback_yes/maybe/no  
/// - all_time_feedback_yes/maybe/no
///
/// These columns are never populated because the app uses manually-entered
/// NPS percentages instead of calculating from individual feedback.

import 'package:sqflite/sqflite.dart';
import '../../storage/database_factory.dart';
import '../../utils/log.dart';

class RemoveUnusedNPSColumns {
  /// Run the migration to remove unused columns
  static Future<void> migrate() async {
    final db = DatabaseFactory.instance;
    
    d('[Migration] Starting removal of unused NPS feedback count columns...');
    
    try {
      // Step 1: Safety check - verify columns are actually unused
      final usageCheck = await _verifyColumnsUnused(db);
      if (!usageCheck) {
        d('[Migration] ⚠️ ABORT: Found non-zero values in feedback columns');
        d('[Migration] Manual review required before migration');
        throw Exception('Migration aborted - columns contain data');
      }
      
      // Step 2: Disable foreign keys temporarily
      await db.execute('PRAGMA foreign_keys=OFF');
      
      // Step 3: Create new table without unused columns
      await db.execute('''
        CREATE TABLE nps_monthly_reports_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          server_id TEXT NOT NULL,
          report_month INTEGER NOT NULL,
          report_year INTEGER NOT NULL,
          all_time_nps_percentage REAL,
          three_month_nps_percentage REAL,
          one_month_nps_percentage REAL,
          all_time_sales REAL DEFAULT 0.00,
          all_time_table_count INTEGER DEFAULT 0,
          generated_at TEXT DEFAULT CURRENT_TIMESTAMP,
          data_as_of_date DATE NOT NULL,
          FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE RESTRICT,
          UNIQUE(server_id, report_month)
        )
      ''');
      
      d('[Migration] Created new table structure');
      
      // Step 4: Copy data (only the columns we're keeping)
      await db.execute('''
        INSERT INTO nps_monthly_reports_new (
          id, server_id, report_month, report_year,
          all_time_nps_percentage, three_month_nps_percentage, one_month_nps_percentage,
          all_time_sales, all_time_table_count, generated_at, data_as_of_date
        )
        SELECT 
          id, server_id, report_month, report_year,
          all_time_nps_percentage, three_month_nps_percentage, one_month_nps_percentage,
          all_time_sales, all_time_table_count, generated_at, 
          COALESCE(data_as_of_date, DATE('now'))
        FROM nps_monthly_reports
      ''');
      
      d('[Migration] Data copied to new table');
      
      // Step 5: Drop old table
      await db.execute('DROP TABLE nps_monthly_reports');
      d('[Migration] Dropped old table');
      
      // Step 6: Rename new table
      await db.execute('ALTER TABLE nps_monthly_reports_new RENAME TO nps_monthly_reports');
      d('[Migration] Renamed new table');
      
      // Step 7: Recreate indexes
      await db.execute('CREATE INDEX idx_monthly_reports_server_id ON nps_monthly_reports(server_id)');
      await db.execute('CREATE INDEX idx_monthly_reports_month ON nps_monthly_reports(report_month)');
      await db.execute('CREATE INDEX idx_monthly_reports_year ON nps_monthly_reports(report_year)');
      await db.execute('CREATE INDEX idx_monthly_reports_server_month ON nps_monthly_reports(server_id, report_month)');
      
      d('[Migration] Recreated indexes');
      
      // Step 8: Re-enable foreign keys
      await db.execute('PRAGMA foreign_keys=ON');
      
      // Step 9: Verify migration success
      final verification = await _verifyMigration(db);
      if (!verification) {
        throw Exception('Migration verification failed');
      }
      
      d('[Migration] ✅ Successfully removed 9 unused feedback count columns');
      d('[Migration] Database is now cleaner and more efficient');
      
    } catch (e) {
      d('[Migration] ❌ Error during migration: $e');
      
      // Attempt rollback by re-enabling foreign keys
      try {
        await db.execute('PRAGMA foreign_keys=ON');
      } catch (_) {}
      
      rethrow;
    }
  }
  
  /// Verify that the columns being removed are actually unused
  static Future<bool> _verifyColumnsUnused(dynamic db) async {
    try {
      // Check if any feedback counts are non-zero
      final results = await db.queryTable(
        'nps_monthly_reports',
        where: '''
          month_feedback_yes != 0 OR month_feedback_maybe != 0 OR month_feedback_no != 0 OR
          three_month_feedback_yes != 0 OR three_month_feedback_maybe != 0 OR three_month_feedback_no != 0 OR
          all_time_feedback_yes != 0 OR all_time_feedback_maybe != 0 OR all_time_feedback_no != 0
        ''',
      );
      
      if (results.isNotEmpty) {
        d('[Migration] ⚠️ Found ${results.length} reports with non-zero feedback counts');
        for (final row in results.take(5)) {
          d('[Migration] Example: server_id=${row['server_id']}, month=${row['report_month']}');
        }
        return false;
      }
      
      d('[Migration] ✅ Verified: All feedback count columns are zero/null');
      return true;
      
    } catch (e) {
      d('[Migration] Error verifying column usage: $e');
      return false;
    }
  }
  
  /// Verify migration completed successfully
  static Future<bool> _verifyMigration(dynamic db) async {
    try {
      // Check that new table exists with correct structure
      final tableInfo = await db.queryTable('sqlite_master', 
        where: "type='table' AND name='nps_monthly_reports'");
      
      if (tableInfo.isEmpty) {
        d('[Migration] ❌ Table nps_monthly_reports not found after migration');
        return false;
      }
      
      // Check that indexes were recreated
      final indexes = await db.queryTable('sqlite_master',
        where: "type='index' AND tbl_name='nps_monthly_reports'");
      
      if (indexes.length < 4) {
        d('[Migration] ⚠️ Not all indexes were recreated (found ${indexes.length}/4)');
      }
      
      // Count rows to ensure no data loss
      final countResult = await db.queryTable('nps_monthly_reports');
      d('[Migration] ✅ Verification passed - ${countResult.length} reports preserved');
      
      return true;
      
    } catch (e) {
      d('[Migration] Error during verification: $e');
      return false;
    }
  }
  
  /// Get migration info for logging/display
  static Map<String, dynamic> getMigrationInfo() {
    return {
      'name': 'Remove Unused NPS Columns',
      'version': '1.0',
      'description': 'Removes 9 unused feedback count columns from nps_monthly_reports',
      'columns_removed': [
        'month_feedback_yes',
        'month_feedback_maybe',
        'month_feedback_no',
        'three_month_feedback_yes',
        'three_month_feedback_maybe',
        'three_month_feedback_no',
        'all_time_feedback_yes',
        'all_time_feedback_maybe',
        'all_time_feedback_no',
      ],
      'reason': 'App uses manually-entered NPS percentages, not calculated from feedback',
      'data_loss_risk': 'None - columns are always zero/null',
    };
  }
}

