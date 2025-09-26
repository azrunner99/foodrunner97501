import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path/path.dart';
import '../utils/log.dart';
import 'database_interface.dart';

/// SQLflite-based database implementation for Android
/// 
/// This implementation provides Android-compatible SQLite operations using
/// the sqflite package while maintaining the same API as the Drift implementation.
class SqfliteNPSDatabase implements DatabaseInterface {
  sqflite.Database? _database;
  String? _databasePath;

  /// Initialize the database connection
  @override
  Future<void> init() async {
    try {
      final databasesPath = await sqflite.getDatabasesPath();
      _databasePath = join(databasesPath, 'nps_database.db');

      _database = await sqflite.openDatabase(
        _databasePath!,
        version: 5, // Increment to force schema recreation with new indexes
        onCreate: _createDatabase,
        onUpgrade: _upgradeDatabase,
      );

      d('[SqfliteNPSDatabase] Database initialized successfully');
    } catch (e) {
      d('[SqfliteNPSDatabase] Error initializing database: $e');
      rethrow;
    }
  }

  /// Create database schema
  Future<void> _createDatabase(sqflite.Database db, int version) async {
    await db.execute('''
      CREATE TABLE servers (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        original_id TEXT,
        hire_date TEXT NOT NULL,
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE nps_feedback (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER NOT NULL,
        score INTEGER NOT NULL,
        comment TEXT,
        customer_name TEXT,
        shift_date TEXT NOT NULL,
        shift_type TEXT NOT NULL,
        timestamp_created TEXT NOT NULL,
        timestamp_updated TEXT,
        FOREIGN KEY (server_id) REFERENCES servers (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE nps_monthly_reports (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER NOT NULL,
        month_year TEXT NOT NULL,
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
        UNIQUE(server_id, month_year)
      )
    ''');

    await db.execute('''
      CREATE TABLE nps_calculation_log (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER NOT NULL,
        calculation_date TEXT NOT NULL,
        month_year TEXT NOT NULL,
        total_responses INTEGER NOT NULL,
        average_score REAL NOT NULL,
        nps_score INTEGER NOT NULL,
        promoters INTEGER NOT NULL,
        passives INTEGER NOT NULL,
        detractors INTEGER NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (server_id) REFERENCES servers (id)
      )
    ''');

    // Create comprehensive indexes for performance optimization
    await db.execute('CREATE INDEX idx_servers_active ON servers (active)');
    await db.execute('CREATE INDEX idx_servers_name ON servers (name)');
    await db.execute('CREATE INDEX idx_servers_hire_date ON servers (hire_date)');
    
    // NPS Feedback indexes - optimized for frequent queries
    await db.execute('CREATE INDEX idx_nps_feedback_server_id ON nps_feedback (server_id)');
    await db.execute('CREATE INDEX idx_nps_feedback_shift_date ON nps_feedback (shift_date)');
    await db.execute('CREATE INDEX idx_nps_feedback_server_date ON nps_feedback (server_id, shift_date)');
    await db.execute('CREATE INDEX idx_nps_feedback_type ON nps_feedback (feedback_type)');
    await db.execute('CREATE INDEX idx_nps_feedback_server_type ON nps_feedback (server_id, feedback_type)');
    
    // Monthly reports indexes - critical for data entry performance
    await db.execute('CREATE INDEX idx_nps_monthly_reports_server_month ON nps_monthly_reports (server_id, month_year)');
    await db.execute('CREATE INDEX idx_nps_monthly_reports_month_year ON nps_monthly_reports (month_year)');
    await db.execute('CREATE INDEX idx_nps_monthly_reports_server_id ON nps_monthly_reports (server_id)');
    await db.execute('CREATE INDEX idx_nps_monthly_reports_nps_score ON nps_monthly_reports (all_time_nps_percentage)');
    
    // Calculation log indexes
    await db.execute('CREATE INDEX idx_nps_calculation_log_server_date ON nps_calculation_log (server_id, calculation_date)');
    await db.execute('CREATE INDEX idx_nps_calculation_log_date ON nps_calculation_log (calculation_date)');
  }

  /// Upgrade database schema
  Future<void> _upgradeDatabase(sqflite.Database db, int oldVersion, int newVersion) async {
    d('[SqfliteNPSDatabase] Upgrading database from version $oldVersion to $newVersion');
    
    if (oldVersion < 5) {
      // Migrate from old schema to new schema
      try {
        // Drop the old table if it exists
        await db.execute('DROP TABLE IF EXISTS nps_monthly_reports');
        
        // Create the new table with Android Sqflite schema
        await db.execute('''
          CREATE TABLE nps_monthly_reports (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            server_id INTEGER NOT NULL,
            month_year TEXT NOT NULL,
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
            UNIQUE(server_id, month_year)
          )
        ''');
        
        // Create indexes
        await db.execute('CREATE INDEX idx_monthly_reports_server_id ON nps_monthly_reports(server_id)');
        await db.execute('CREATE INDEX idx_monthly_reports_month_year ON nps_monthly_reports(month_year)');
        await db.execute('CREATE INDEX idx_monthly_reports_server_month ON nps_monthly_reports(server_id, month_year)');
        
        d('[SqfliteNPSDatabase] Successfully migrated nps_monthly_reports table to new schema');
      } catch (e) {
        d('[SqfliteNPSDatabase] Error during migration: $e');
        rethrow;
      }
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
      if (_database == null) {
        throw Exception('Database not initialized');
      }

      return await _database!.query(
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
    } catch (e) {
      d('[SqfliteNPSDatabase] Error in query: $e');
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
      if (_database == null) {
        throw Exception('Database not initialized');
      }

      return await _database!.insert(
        table,
        data,
        nullColumnHack: nullColumnHack,
        conflictAlgorithm: _mapConflictAlgorithm(conflictAlgorithm),
      );
    } catch (e) {
      d('[SqfliteNPSDatabase] Error in insert: $e');
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
      if (_database == null) {
        throw Exception('Database not initialized');
      }

      return await _database!.update(
        table,
        data,
        where: where,
        whereArgs: args,
        conflictAlgorithm: _mapConflictAlgorithm(conflictAlgorithm),
      );
    } catch (e) {
      d('[SqfliteNPSDatabase] Error in update: $e');
      rethrow;
    }
  }

  @override
  Future<int> deleteFrom(
    String table,
    String where,
    List<dynamic> args,
  ) async {
    try {
      if (_database == null) {
        throw Exception('Database not initialized');
      }

      return await _database!.delete(
        table,
        where: where,
        whereArgs: args,
      );
    } catch (e) {
      d('[SqfliteNPSDatabase] Error in delete: $e');
      rethrow;
    }
  }

  @override
  Future<void> execute(String sql) async {
    try {
      if (_database == null) {
        throw Exception('Database not initialized');
      }

      await _database!.execute(sql);
    } catch (e) {
      d('[SqfliteNPSDatabase] Error executing SQL: $e');
      rethrow;
    }
  }

  @override
  Future<T> runTransaction<T>(Future<T> Function(DatabaseTransaction txn) action) async {
    try {
      if (_database == null) {
        throw Exception('Database not initialized');
      }

      return await _database!.transaction<T>((txn) async {
        final transaction = SqfliteDatabaseTransaction(txn);
        return await action(transaction);
      });
    } catch (e) {
      d('[SqfliteNPSDatabase] Error in transaction: $e');
      rethrow;
    }
  }

  @override
  Future<int> getVersion() async {
    try {
      if (_database == null) {
        throw Exception('Database not initialized');
      }

      return await _database!.getVersion();
    } catch (e) {
      d('[SqfliteNPSDatabase] Error getting version: $e');
      return 0;
    }
  }

  @override
  Future<void> close() async {
    try {
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
    } catch (e) {
      d('[SqfliteNPSDatabase] Error closing database: $e');
    }
  }

  /// Map our ConflictAlgorithm enum to sqflite's ConflictAlgorithm
  sqflite.ConflictAlgorithm? _mapConflictAlgorithm(ConflictAlgorithm? algorithm) {
    if (algorithm == null) return null;
    
    switch (algorithm) {
      case ConflictAlgorithm.rollback:
        return sqflite.ConflictAlgorithm.rollback;
      case ConflictAlgorithm.abort:
        return sqflite.ConflictAlgorithm.abort;
      case ConflictAlgorithm.fail:
        return sqflite.ConflictAlgorithm.fail;
      case ConflictAlgorithm.ignore:
        return sqflite.ConflictAlgorithm.ignore;
      case ConflictAlgorithm.replace:
        return sqflite.ConflictAlgorithm.replace;
    }
  }
}

/// Sqflite-specific transaction implementation
class SqfliteDatabaseTransaction implements DatabaseTransaction {
  final sqflite.Transaction _transaction;
  
  SqfliteDatabaseTransaction(this._transaction);

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
    return await _transaction.query(
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
    return await _transaction.insert(table, data);
  }

  @override
  Future<int> updateTable(String table, Map<String, dynamic> data, String where, List<dynamic> args) async {
    return await _transaction.update(table, data, where: where, whereArgs: args);
  }

  @override
  Future<int> deleteFrom(String table, String where, List<dynamic> args) async {
    return await _transaction.delete(table, where: where, whereArgs: args);
  }

  @override
  Future<void> execute(String sql) async {
    await _transaction.execute(sql);
  }
}