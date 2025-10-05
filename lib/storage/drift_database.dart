import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
// Native database import for in-memory / test fallback
import 'package:drift/native.dart' as drift_native;
import '../services/platform_service.dart';
import '../utils/log.dart';
import 'database_interface.dart';

part 'drift_database.g.dart';

/// Drift-based cross-platform database implementation
/// 
/// This implementation provides Windows-compatible SQLite operations using
/// the Drift ORM while maintaining the same API as the sqflite implementation.
@DriftDatabase(include: {'nps_schema.drift'})
class DriftNPSDatabase extends _$DriftNPSDatabase implements DatabaseInterface {
  /// Primary constructor using on-disk (path_provider) backed Drift database.
  DriftNPSDatabase() : this._internal(_openConnection());

  /// Internal constructor allowing custom executors.
  DriftNPSDatabase._internal(QueryExecutor executor) : super(executor);

  /// In-memory constructor used for test environments where method channel
  /// plugins (e.g. path_provider) are unavailable, preventing normal
  /// file system database initialization.
  factory DriftNPSDatabase.testInMemory() =>
      DriftNPSDatabase._internal(drift_native.NativeDatabase.memory());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 3) {
        // Enable foreign keys for migration
        await customStatement('PRAGMA foreign_keys=OFF');
        
        // Rebuild nps_monthly_reports with server_id TEXT
        await customStatement('''
          CREATE TABLE nps_monthly_reports_new (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            server_id TEXT NOT NULL,
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
            FOREIGN KEY (server_id) REFERENCES servers (id) ON DELETE RESTRICT,
            UNIQUE(server_id, report_month)
          )
        ''');
        
        // Copy data with INTEGER to TEXT conversion
        await customStatement('''
          INSERT INTO nps_monthly_reports_new 
          SELECT id, CAST(server_id AS TEXT), report_month, report_year,
                 all_time_nps_percentage, three_month_nps_percentage, one_month_nps_percentage,
                 all_time_sales, all_time_table_count, month_feedback_yes, month_feedback_maybe,
                 month_feedback_no, three_month_feedback_yes, three_month_feedback_maybe,
                 three_month_feedback_no, all_time_feedback_yes, all_time_feedback_maybe,
                 all_time_feedback_no, generated_at, COALESCE(data_as_of_date, DATE('now'))
          FROM nps_monthly_reports
        ''');
        
        // Drop old table and rename new one
        await customStatement('DROP TABLE nps_monthly_reports');
        await customStatement('ALTER TABLE nps_monthly_reports_new RENAME TO nps_monthly_reports');
        
        // Recreate indexes for nps_monthly_reports
        await customStatement('CREATE INDEX idx_monthly_reports_server_id ON nps_monthly_reports(server_id)');
        await customStatement('CREATE INDEX idx_monthly_reports_month ON nps_monthly_reports(report_month)');
        await customStatement('CREATE INDEX idx_monthly_reports_year ON nps_monthly_reports(report_year)');
        await customStatement('CREATE INDEX idx_monthly_reports_server_month ON nps_monthly_reports(server_id, report_month)');
        
        // Rebuild nps_calculation_log with server_id TEXT NULL
        await customStatement('''
          CREATE TABLE nps_calculation_log_new (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            calculation_type TEXT NOT NULL,
            server_id TEXT,
            report_month INTEGER,
            calculation_start TEXT NOT NULL,
            calculation_end TEXT NOT NULL,
            records_processed INTEGER NOT NULL,
            success INTEGER NOT NULL,
            error_message TEXT,
            created_by TEXT,
            FOREIGN KEY (server_id) REFERENCES servers (id) ON DELETE SET NULL
          )
        ''');
        
        // Copy data with INTEGER to TEXT conversion (nullable)
        await customStatement('''
          INSERT INTO nps_calculation_log_new 
          SELECT id, calculation_type, 
                 CASE WHEN server_id IS NULL THEN NULL ELSE CAST(server_id AS TEXT) END,
                 report_month, calculation_start, calculation_end, records_processed,
                 success, error_message, created_by
          FROM nps_calculation_log
        ''');
        
        // Drop old table and rename new one
        await customStatement('DROP TABLE nps_calculation_log');
        await customStatement('ALTER TABLE nps_calculation_log_new RENAME TO nps_calculation_log');
        
        // Recreate indexes for nps_calculation_log
        await customStatement('CREATE INDEX idx_calc_log_type ON nps_calculation_log(calculation_type)');
        await customStatement('CREATE INDEX idx_calc_log_date ON nps_calculation_log(calculation_start)');
        
        // Re-enable foreign keys
        await customStatement('PRAGMA foreign_keys=ON');
      }
    },
    beforeOpen: (OpeningDetails details) async {
      await customStatement('PRAGMA foreign_keys=ON;');
    },
  );

  /// Open database connection with platform-appropriate configuration
  static QueryExecutor _openConnection() {
    // Use drift_flutter helper (will attempt to resolve application documents
    // directory via path_provider). This can throw a MissingPluginException in
    // pure Dart test environments where the plugin channel isn't registered.
    return driftDatabase(name: 'nps_database');
  }

  @override
  Future<void> init() async {
    try {
      // Initialize database - Drift handles schema creation automatically
      await select(npsCalculationLog).get();
      d('[DriftNPSDatabase] Database initialized successfully');
    } catch (e) {
      d('[DriftNPSDatabase] Error initializing database: $e');
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> queryTable(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    try {
      // Build SQL query dynamically
      String sql = 'SELECT ';
      
      if (distinct == true) sql += 'DISTINCT ';
      
      if (columns != null && columns.isNotEmpty) {
        sql += columns.join(', ');
      } else {
        sql += '*';
      }
      
      sql += ' FROM $table';
      
      if (where != null) {
        sql += ' WHERE $where';
      }
      
      if (groupBy != null) {
        sql += ' GROUP BY $groupBy';
      }
      
      if (having != null) {
        sql += ' HAVING $having';
      }
      
      if (orderBy != null) {
        sql += ' ORDER BY $orderBy';
      }
      
      if (limit != null) {
        sql += ' LIMIT $limit';
      }
      
      if (offset != null) {
        sql += ' OFFSET $offset';
      }

      final result = await customSelect(
        sql, 
        variables: whereArgs?.map((arg) => Variable(arg)).toList() ?? [],
      ).get();

      return result.map((row) => row.data).toList();
    } catch (e) {
      d('[DriftNPSDatabase] Error in query: $e');
      rethrow;
    }
  }

  @override
  Future<int> insertInto(
    String table, 
    Map<String, dynamic> data, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    try {
      final columns = data.keys.join(', ');
      final placeholders = data.keys.map((_) => '?').join(', ');
      final values = data.values.toList();
      
      String conflictClause = '';
      if (conflictAlgorithm != null) {
        switch (conflictAlgorithm) {
          case ConflictAlgorithm.replace:
            conflictClause = ' OR REPLACE';
            break;
          case ConflictAlgorithm.ignore:
            conflictClause = ' OR IGNORE';
            break;
          case ConflictAlgorithm.abort:
            conflictClause = ' OR ABORT';
            break;
          case ConflictAlgorithm.fail:
            conflictClause = ' OR FAIL';
            break;
          case ConflictAlgorithm.rollback:
            conflictClause = ' OR ROLLBACK';
            break;
        }
      }

      final sql = 'INSERT$conflictClause INTO $table ($columns) VALUES ($placeholders)';
      
      await customInsert(
        sql,
        variables: values.map((v) => Variable(v)).toList(),
      );

      // Get last inserted row ID
      final lastId = await customSelect('SELECT last_insert_rowid() as id').getSingle();
      return lastId.data['id'] as int;
    } catch (e) {
      d('[DriftNPSDatabase] Error in insert: $e');
      rethrow;
    }
  }

  @override
  Future<int> updateTable(
    String table, 
    Map<String, dynamic> data, 
    String where, 
    List<dynamic> args, {
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    try {
      final setClause = data.keys.map((key) => '$key = ?').join(', ');
      final values = [...data.values, ...args];
      
      String conflictClause = '';
      if (conflictAlgorithm != null) {
        switch (conflictAlgorithm) {
          case ConflictAlgorithm.replace:
            conflictClause = ' OR REPLACE';
            break;
          case ConflictAlgorithm.ignore:
            conflictClause = ' OR IGNORE';
            break;
          case ConflictAlgorithm.abort:
            conflictClause = ' OR ABORT';
            break;
          case ConflictAlgorithm.fail:
            conflictClause = ' OR FAIL';
            break;
          case ConflictAlgorithm.rollback:
            conflictClause = ' OR ROLLBACK';
            break;
        }
      }

      final sql = 'UPDATE$conflictClause $table SET $setClause WHERE $where';
      
      return await customUpdate(
        sql,
        variables: values.map((v) => Variable(v)).toList(),
      );
    } catch (e) {
      d('[DriftNPSDatabase] Error in update: $e');
      rethrow;
    }
  }

  @override
  Future<int> deleteFrom(String table, String where, List<dynamic> args) async {
    try {
      final sql = 'DELETE FROM $table WHERE $where';
      
      return await customUpdate(
        sql,
        variables: args.map((v) => Variable(v)).toList(),
      );
    } catch (e) {
      d('[DriftNPSDatabase] Error in delete: $e');
      rethrow;
    }
  }

  @override
  Future<void> execute(String sql) async {
    try {
      await customStatement(sql);
    } catch (e) {
      d('[DriftNPSDatabase] Error executing SQL: $e');
      rethrow;
    }
  }

  @override
  Future<T> runTransaction<T>(Future<T> Function(DatabaseTransaction txn) action) async {
    try {
      return await super.transaction(() async {
        final txn = DriftDatabaseTransaction(this);
        return await action(txn);
      });
    } catch (e) {
      d('[DriftNPSDatabase] Error in transaction: $e');
      rethrow;
    }
  }

  @override
  Future<int> getVersion() async {
    try {
      final result = await customSelect('PRAGMA user_version').getSingle();
      return result.data['user_version'] as int? ?? 0;
    } catch (e) {
      d('[DriftNPSDatabase] Error getting version: $e');
      return 0;
    }
  }
}

/// Drift-specific transaction implementation
class DriftDatabaseTransaction implements DatabaseTransaction {
  final DriftNPSDatabase _database;
  
  DriftDatabaseTransaction(this._database);

  @override
  Future<List<Map<String, dynamic>>> queryTable(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    return await _database.queryTable(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<int> insertInto(String table, Map<String, dynamic> data) async {
    return await _database.insertInto(table, data);
  }

  @override
  Future<int> updateTable(String table, Map<String, dynamic> data, String where, List<dynamic> args) async {
    return await _database.updateTable(table, data, where, args);
  }

  @override
  Future<int> deleteFrom(String table, String where, List<dynamic> args) async {
    return await _database.deleteFrom(table, where, args);
  }

  @override
  Future<void> execute(String sql) async {
    await _database.execute(sql);
  }
}