import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../utils/log.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// SQLite database manager for the Server NPS system
///
/// This class handles database initialization, schema creation, and migrations
/// for the comprehensive Server NPS tracking system.
class NPSDatabase {
  static NPSDatabase? _instance;
  static Database? _database;

  NPSDatabase._();

  static NPSDatabase get instance {
    _instance ??= NPSDatabase._();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'nps_database.db');

  d('[NPSDatabase] Initializing database at: $path');

      return await openDatabase(
        path,
        version: 2, // Increased version for original_id migration
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onDowngrade: _onDowngrade,
      );
    } catch (e) {
  d('[NPSDatabase] Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
  d('[NPSDatabase] Creating database schema version $version');

    try {
      // Create servers table
      await db.execute('''
        CREATE TABLE servers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          original_id TEXT, 
          hire_date DATE NOT NULL,
          active INTEGER DEFAULT 1,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // Create indexes for servers table
      await db.execute('CREATE INDEX idx_servers_active ON servers(active)');
      await db
          .execute('CREATE INDEX idx_servers_hire_date ON servers(hire_date)');

      // Create nps_feedback table
      await db.execute('''
        CREATE TABLE nps_feedback (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          server_id INTEGER NOT NULL,
          feedback_type TEXT NOT NULL CHECK(feedback_type IN ('yes', 'maybe', 'no')),
          feedback_date DATE NOT NULL,
          sales_amount REAL,
          table_number INTEGER,
          shift_period TEXT CHECK(shift_period IN ('breakfast', 'lunch', 'dinner', 'late_night')),
          guest_count INTEGER,
          notes TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE RESTRICT
        )
      ''');

      // Create indexes for nps_feedback table
      await db.execute(
          'CREATE INDEX idx_feedback_server_id ON nps_feedback(server_id)');
      await db.execute(
          'CREATE INDEX idx_feedback_date ON nps_feedback(feedback_date)');
      await db.execute(
          'CREATE INDEX idx_feedback_server_date ON nps_feedback(server_id, feedback_date)');
      await db.execute(
          'CREATE INDEX idx_feedback_type ON nps_feedback(feedback_type)');

      // Create nps_monthly_reports table
      await db.execute('''
        CREATE TABLE nps_monthly_reports (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          server_id INTEGER NOT NULL,
          report_month INTEGER NOT NULL,
          report_year INTEGER NOT NULL,
          all_time_nps_percentage REAL,
          three_month_nps_percentage REAL,
          one_month_nps_percentage REAL,
          all_time_sales REAL DEFAULT 0.00,
          all_time_table_count INTEGER DEFAULT 0,
          month_feedback_yes INTEGER DEFAULT 0,
          month_feedback_maybe INTEGER DEFAULT 0,
          month_feedback_no INTEGER DEFAULT 0,
          three_month_feedback_yes INTEGER DEFAULT 0,
          three_month_feedback_maybe INTEGER DEFAULT 0,
          three_month_feedback_no INTEGER DEFAULT 0,
          all_time_feedback_yes INTEGER DEFAULT 0,
          all_time_feedback_maybe INTEGER DEFAULT 0,
          all_time_feedback_no INTEGER DEFAULT 0,
          generated_at TEXT DEFAULT CURRENT_TIMESTAMP,
          data_as_of_date DATE NOT NULL,
          FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE RESTRICT,
          UNIQUE(server_id, report_month)
        )
      ''');

      // Create indexes for nps_monthly_reports table
      await db.execute(
          'CREATE INDEX idx_monthly_reports_server_id ON nps_monthly_reports(server_id)');
      await db.execute(
          'CREATE INDEX idx_monthly_reports_month ON nps_monthly_reports(report_month)');
      await db.execute(
          'CREATE INDEX idx_monthly_reports_year ON nps_monthly_reports(report_year)');
      await db.execute(
          'CREATE INDEX idx_monthly_reports_server_month ON nps_monthly_reports(server_id, report_month)');

      // Create nps_calculation_log table for audit trail
      await db.execute('''
        CREATE TABLE nps_calculation_log (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          calculation_type TEXT NOT NULL,
          server_id INTEGER,
          report_month INTEGER,
          calculation_start TEXT NOT NULL,
          calculation_end TEXT NOT NULL,
          records_processed INTEGER NOT NULL,
          success INTEGER NOT NULL,
          error_message TEXT,
          created_by TEXT,
          FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE SET NULL
        )
      ''');

      // Create indexes for calculation log
      await db.execute(
          'CREATE INDEX idx_calc_log_type ON nps_calculation_log(calculation_type)');
      await db.execute(
          'CREATE INDEX idx_calc_log_date ON nps_calculation_log(calculation_start)');

  d('[NPSDatabase] Database schema created successfully');
    } catch (e) {
  d('[NPSDatabase] Error creating database schema: $e');
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  d(
        '[NPSDatabase] Upgrading database from version $oldVersion to $newVersion');

    if (oldVersion < 2) {
      // Add original_id column to servers table
      try {
        await db.execute('ALTER TABLE servers ADD COLUMN original_id TEXT');
  d('[NPSDatabase] ✅ Added original_id column to servers table');
      } catch (e) {
  d(
            '[NPSDatabase] ⚠️ Could not add original_id column (may already exist): $e');
      }
    }
  }

  Future<void> _onDowngrade(Database db, int oldVersion, int newVersion) async {
  d(
        '[NPSDatabase] Downgrading database from version $oldVersion to $newVersion');

    // Handle downgrade scenarios if needed
    // Generally, we should avoid downgrades in production
  }

  // Server CRUD Operations

  /// Insert a new server into the database
  Future<int> insertServer(Map<String, dynamic> server) async {
    try {
      final db = await database;
      final id = await db.insert('servers', server);
  d('[NPSDatabase] Inserted server with ID: $id');
      return id;
    } catch (e) {
  d('[NPSDatabase] Error inserting server: $e');
      rethrow;
    }
  }

  /// Get all servers from the database
  Future<List<Map<String, dynamic>>> getAllServers(
      {bool activeOnly = false}) async {
    try {
      final db = await database;
      final where = activeOnly ? 'active = 1' : null;
      final servers =
          await db.query('servers', where: where, orderBy: 'name ASC');
  d('[NPSDatabase] Retrieved ${servers.length} servers');
      return servers;
    } catch (e) {
  d('[NPSDatabase] Error getting servers: $e');
      rethrow;
    }
  }

  /// Get a specific server by ID
  Future<Map<String, dynamic>?> getServerById(int serverId) async {
    try {
      final db = await database;
      final servers =
          await db.query('servers', where: 'id = ?', whereArgs: [serverId]);
      return servers.isNotEmpty ? servers.first : null;
    } catch (e) {
  d('[NPSDatabase] Error getting server by ID: $e');
      rethrow;
    }
  }

  /// Update a server in the database
  Future<int> updateServer(int serverId, Map<String, dynamic> server) async {
    try {
      final db = await database;
      server['updated_at'] = DateTime.now().toIso8601String();
      final rowsAffected = await db
          .update('servers', server, where: 'id = ?', whereArgs: [serverId]);
  d(
          '[NPSDatabase] Updated server $serverId, rows affected: $rowsAffected');
      return rowsAffected;
    } catch (e) {
  d('[NPSDatabase] Error updating server: $e');
      rethrow;
    }
  }

  /// Delete a server from the database (soft delete by setting active = 0)
  Future<int> deleteServer(int serverId) async {
    try {
      final db = await database;
      final rowsAffected = await db.update(
        'servers',
        {'active': 0, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [serverId],
      );
  d(
          '[NPSDatabase] Soft deleted server $serverId, rows affected: $rowsAffected');
      return rowsAffected;
    } catch (e) {
  d('[NPSDatabase] Error deleting server: $e');
      rethrow;
    }
  }

  // Feedback CRUD Operations

  /// Insert feedback into the database
  Future<int> insertFeedback(Map<String, dynamic> feedback) async {
    try {
      final db = await database;
      final id = await db.insert('nps_feedback', feedback);
  d('[NPSDatabase] Inserted feedback with ID: $id');
      return id;
    } catch (e) {
  d('[NPSDatabase] Error inserting feedback: $e');
      rethrow;
    }
  }

  /// Get feedback for a specific server
  Future<List<Map<String, dynamic>>> getFeedbackForServer(
    int serverId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await database;
      String where = 'server_id = ?';
      List<dynamic> whereArgs = [serverId];

      if (startDate != null) {
        where += ' AND feedback_date >= ?';
        whereArgs.add(startDate.toIso8601String().split('T')[0]);
      }

      if (endDate != null) {
        where += ' AND feedback_date <= ?';
        whereArgs.add(endDate.toIso8601String().split('T')[0]);
      }

      final feedback = await db.query(
        'nps_feedback',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'feedback_date DESC',
      );

  d(
          '[NPSDatabase] Retrieved ${feedback.length} feedback entries for server $serverId');
      return feedback;
    } catch (e) {
  d('[NPSDatabase] Error getting feedback for server: $e');
      rethrow;
    }
  }

  /// Get all feedback within a date range
  Future<List<Map<String, dynamic>>> getFeedbackInDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await database;
      final feedback = await db.query(
        'nps_feedback',
        where: 'feedback_date >= ? AND feedback_date <= ?',
        whereArgs: [
          startDate.toIso8601String().split('T')[0],
          endDate.toIso8601String().split('T')[0],
        ],
        orderBy: 'feedback_date DESC',
      );

  d(
          '[NPSDatabase] Retrieved ${feedback.length} feedback entries in date range');
      return feedback;
    } catch (e) {
  d('[NPSDatabase] Error getting feedback in date range: $e');
      rethrow;
    }
  }

  // Monthly Reports CRUD Operations

  /// Insert or update a monthly report
  Future<int> insertOrUpdateMonthlyReport(Map<String, dynamic> report) async {
    try {
      final db = await database;

      // Try to insert first
      try {
        final id = await db.insert('nps_monthly_reports', report);
  d('[NPSDatabase] Inserted monthly report with ID: $id');
        return id;
      } on DatabaseException catch (e) {
        // If insertion fails due to unique constraint, update instead
        if (e.isUniqueConstraintError()) {
          final rowsAffected = await db.update(
            'nps_monthly_reports',
            report,
            where: 'server_id = ? AND report_month = ?',
            whereArgs: [report['server_id'], report['report_month']],
          );
          d(
              '[NPSDatabase] Updated existing monthly report, rows affected: $rowsAffected');
          return rowsAffected;
        } else {
          rethrow;
        }
      }
    } catch (e) {
  d('[NPSDatabase] Error inserting/updating monthly report: $e');
      rethrow;
    }
  }

  /// Get monthly report for a specific server and month
  Future<Map<String, dynamic>?> getMonthlyReport(
      int serverId, int reportMonth) async {
    try {
      final db = await database;
      final reports = await db.query(
        'nps_monthly_reports',
        where: 'server_id = ? AND report_month = ?',
        whereArgs: [serverId, reportMonth],
      );
      return reports.isNotEmpty ? reports.first : null;
    } catch (e) {
  d('[NPSDatabase] Error getting monthly report: $e');
      rethrow;
    }
  }

  /// Get all monthly reports for a specific month
  Future<List<Map<String, dynamic>>> getMonthlyReportsForMonth(
      int reportMonth) async {
    try {
      final db = await database;
      final reports = await db.query(
        'nps_monthly_reports',
        where: 'report_month = ?',
        whereArgs: [reportMonth],
        orderBy: 'all_time_nps_percentage DESC',
      );
  d(
          '[NPSDatabase] Retrieved ${reports.length} monthly reports for month $reportMonth');
      return reports;
    } catch (e) {
  d('[NPSDatabase] Error getting monthly reports for month: $e');
      rethrow;
    }
  }

  /// Get all available months that have saved reports
  Future<List<Map<String, dynamic>>> getAvailableReportMonths() async {
    try {
      final db = await database;
      final months = await db.rawQuery('''
        SELECT DISTINCT report_month, report_year, 
               COUNT(*) as server_count
        FROM nps_monthly_reports 
        GROUP BY report_year, report_month
        ORDER BY report_year DESC, report_month DESC
      ''');
  d('[NPSDatabase] Retrieved ${months.length} available report months');
      return months;
    } catch (e) {
  d('[NPSDatabase] Error getting available report months: $e');
      rethrow;
    }
  }

  /// Get server NPS data for a specific month
  Future<List<Map<String, dynamic>>> getServerNPSDataForMonth(
      int reportMonth, int reportYear) async {
    try {
      final db = await database;
      final serverData = await db.rawQuery('''
        SELECT 
          s.name as server_name,
          s.id as server_id,
          nmr.all_time_nps_percentage,
          nmr.three_month_nps_percentage,
          nmr.one_month_nps_percentage,
          nmr.month_feedback_yes,
          nmr.month_feedback_maybe,
          nmr.month_feedback_no,
          nmr.three_month_feedback_yes,
          nmr.three_month_feedback_maybe,
          nmr.three_month_feedback_no,
          nmr.all_time_feedback_yes,
          nmr.all_time_feedback_maybe,
          nmr.all_time_feedback_no
        FROM nps_monthly_reports nmr
        JOIN servers s ON nmr.server_id = s.id
        WHERE nmr.report_month = ? AND nmr.report_year = ?
        ORDER BY s.name ASC
      ''', [reportMonth, reportYear]);

  d(
          '[NPSDatabase] Retrieved NPS data for ${serverData.length} servers for $reportMonth/$reportYear');
      return serverData;
    } catch (e) {
  d('[NPSDatabase] Error getting server NPS data for month: $e');
      rethrow;
    }
  }

  // Utility methods

  /// Close the database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
  d('[NPSDatabase] Database connection closed');
    }
  }

  /// Check if database is initialized and ready
  Future<bool> isDatabaseReady() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT 1');
      return result.isNotEmpty;
    } catch (e) {
  d('[NPSDatabase] Database readiness check failed: $e');
      return false;
    }
  }

  /// Get database schema version
  Future<int> getDatabaseVersion() async {
    try {
      final db = await database;
      return await db.getVersion();
    } catch (e) {
  d('[NPSDatabase] Error getting database version: $e');
      return 0;
    }
  }

  /// Clear all data (for testing purposes)
  Future<void> clearAllData() async {
    try {
      final db = await database;
      await db.transaction((txn) async {
        await txn.delete('nps_calculation_log');
        await txn.delete('nps_monthly_reports');
        await txn.delete('nps_feedback');
        await txn.delete('servers');
      });
  d('[NPSDatabase] All data cleared successfully');
    } catch (e) {
  d('[NPSDatabase] Error clearing all data: $e');
      rethrow;
    }
  }
}
