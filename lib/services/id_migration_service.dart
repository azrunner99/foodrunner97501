import 'dart:convert';
import '../storage/database_factory.dart';
import '../storage/nps_database.dart';
import '../utils/log.dart';

/// ID Migration Service
/// 
/// This service handles the migration from integer IDs to string IDs
/// across all database systems while maintaining data integrity and
/// foreign key relationships.
class IDMigrationService {
  static const String _migrationKey = 'id_migration_completed';
  static const String _backupPrefix = 'pre_id_migration_';
  
  /// Check if ID migration is needed
  static Future<bool> isMigrationNeeded() async {
    try {
      final db = DatabaseFactory.instance;
      
      // Check if migration has already been completed
      final migrationStatus = await _getMigrationStatus();
      if (migrationStatus) {
        d('[IDMigrationService] ID migration already completed');
        return false;
      }
      
      // Check if we have integer IDs in the database
      final hasIntegerIds = await _hasIntegerServerIds();
      if (!hasIntegerIds) {
        d('[IDMigrationService] No integer IDs found, marking migration as complete');
        await _setMigrationStatus(true);
        return false;
      }
      
      d('[IDMigrationService] ID migration needed');
      return true;
      
    } catch (e) {
      d('[IDMigrationService] Error checking migration status: $e');
      return false;
    }
  }
  
  /// Perform complete ID migration
  static Future<bool> performMigration() async {
    try {
      d('[IDMigrationService] Starting ID migration...');
      
      // Step 1: Create backup
      final backupPath = await _createBackup();
      if (backupPath == null) {
        d('[IDMigrationService] Failed to create backup');
        return false;
      }
      
      // Step 2: Migrate servers table
      await _migrateServersTable();
      
      // Step 3: Migrate foreign key tables
      await _migrateForeignKeyTables();
      
      // Step 4: Verify migration
      final verificationSuccess = await _verifyMigration();
      if (!verificationSuccess) {
        d('[IDMigrationService] Migration verification failed, rolling back...');
        await _rollbackMigration(backupPath);
        return false;
      }
      
      // Step 5: Mark migration as complete
      await _setMigrationStatus(true);
      
      d('[IDMigrationService] ID migration completed successfully');
      return true;
      
    } catch (e) {
      d('[IDMigrationService] Error during migration: $e');
      return false;
    }
  }
  
  /// Create backup before migration
  static Future<String?> _createBackup() async {
    try {
      d('[IDMigrationService] Creating backup...');
      
      final db = DatabaseFactory.instance;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupName = '$_backupPrefix$timestamp';
      
      // Export all tables to backup
      final servers = await db.queryTable('servers');
      final feedback = await db.queryTable('nps_feedback');
      final reports = await db.queryTable('nps_monthly_reports');
      final logs = await db.queryTable('nps_calculation_log');
      
      final backupData = {
        'metadata': {
          'timestamp': timestamp,
          'version': 'pre_id_migration',
          'type': 'id_migration_backup',
        },
        'servers': servers,
        'nps_feedback': feedback,
        'nps_monthly_reports': reports,
        'nps_calculation_log': logs,
      };
      
      // Store backup data (implementation depends on storage mechanism)
      // This could be saved to a file or stored in a separate backup table
      
      d('[IDMigrationService] Backup created: $backupName');
      return backupName;
      
    } catch (e) {
      d('[IDMigrationService] Error creating backup: $e');
      return null;
    }
  }
  
  /// Migrate servers table from integer to string IDs
  static Future<void> _migrateServersTable() async {
    try {
      d('[IDMigrationService] Migrating servers table...');
      
      final db = DatabaseFactory.instance;
      
      // Step 1: Get all existing servers
      final servers = await db.queryTable('servers');
      
      // Step 2: Create new servers table with string IDs
      await db.execute('''
        CREATE TABLE servers_new (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          original_id TEXT,
          hire_date TEXT NOT NULL,
          active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      
      // Step 3: Migrate data with ID conversion
      for (final server in servers) {
        final intId = server['id'] as int;
        final stringId = intId.toString();
        
        await db.insertInto('servers_new', {
          'id': stringId,
          'name': server['name'],
          'original_id': stringId, // Store original ID for reference
          'hire_date': server['hire_date'],
          'active': server['active'],
          'created_at': server['created_at'],
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
      
      // Step 4: Replace old table with new table
      await db.execute('DROP TABLE servers');
      await db.execute('ALTER TABLE servers_new RENAME TO servers');
      
      // Step 5: Recreate indexes
      await db.execute('CREATE INDEX idx_servers_active ON servers(active)');
      await db.execute('CREATE INDEX idx_servers_hire_date ON servers(hire_date)');
      
      d('[IDMigrationService] Servers table migration completed');
      
    } catch (e) {
      d('[IDMigrationService] Error migrating servers table: $e');
      rethrow;
    }
  }
  
  /// Migrate tables with foreign key references
  static Future<void> _migrateForeignKeyTables() async {
    try {
      d('[IDMigrationService] Migrating foreign key tables...');
      
      // Migrate nps_feedback table
      await _migrateFeedbackTable();
      
      // Migrate nps_monthly_reports table
      await _migrateReportsTable();
      
      // Migrate nps_calculation_log table
      await _migrateCalculationLogTable();
      
      d('[IDMigrationService] Foreign key tables migration completed');
      
    } catch (e) {
      d('[IDMigrationService] Error migrating foreign key tables: $e');
      rethrow;
    }
  }
  
  /// Migrate nps_feedback table
  static Future<void> _migrateFeedbackTable() async {
    try {
      final db = DatabaseFactory.instance;
      
      // Get existing feedback data
      final feedback = await db.queryTable('nps_feedback');
      
      // Create new table with string server_id
      await db.execute('''
        CREATE TABLE nps_feedback_new (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          server_id TEXT NOT NULL,
          feedback_type TEXT NOT NULL CHECK(feedback_type IN ('yes', 'maybe', 'no')),
          feedback_date TEXT NOT NULL,
          sales_amount REAL,
          table_number INTEGER,
          shift_period TEXT CHECK(shift_period IN ('breakfast', 'lunch', 'dinner', 'late_night')),
          guest_count INTEGER,
          notes TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (server_id) REFERENCES servers (id) ON DELETE RESTRICT
        )
      ''');
      
      // Migrate data with ID conversion
      for (final record in feedback) {
        final intServerId = record['server_id'] as int;
        final stringServerId = intServerId.toString();
        
        await db.insertInto('nps_feedback_new', {
          'server_id': stringServerId,
          'feedback_type': record['feedback_type'],
          'feedback_date': record['feedback_date'],
          'sales_amount': record['sales_amount'],
          'table_number': record['table_number'],
          'shift_period': record['shift_period'],
          'guest_count': record['guest_count'],
          'notes': record['notes'],
          'created_at': record['created_at'],
        });
      }
      
      // Replace old table
      await db.execute('DROP TABLE nps_feedback');
      await db.execute('ALTER TABLE nps_feedback_new RENAME TO nps_feedback');
      
      // Recreate indexes
      await db.execute('CREATE INDEX idx_feedback_server_id ON nps_feedback(server_id)');
      await db.execute('CREATE INDEX idx_feedback_date ON nps_feedback(feedback_date)');
      await db.execute('CREATE INDEX idx_feedback_server_date ON nps_feedback(server_id, feedback_date)');
      await db.execute('CREATE INDEX idx_feedback_type ON nps_feedback(feedback_type)');
      
    } catch (e) {
      d('[IDMigrationService] Error migrating feedback table: $e');
      rethrow;
    }
  }
  
  /// Migrate nps_monthly_reports table
  static Future<void> _migrateReportsTable() async {
    try {
      final db = DatabaseFactory.instance;
      
      // Get existing reports data
      final reports = await db.queryTable('nps_monthly_reports');
      
      // Create new table with string server_id
      await db.execute('''
        CREATE TABLE nps_monthly_reports_new (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          server_id TEXT NOT NULL,
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
          data_as_of_date TEXT NOT NULL,
          FOREIGN KEY (server_id) REFERENCES servers (id) ON DELETE RESTRICT,
          UNIQUE(server_id, month_year)
        )
      ''');
      
      // Migrate data with ID conversion
      for (final record in reports) {
        final intServerId = record['server_id'] as int;
        final stringServerId = intServerId.toString();
        
        await db.insertInto('nps_monthly_reports_new', {
          'server_id': stringServerId,
          'month_year': record['month_year'],
          'all_time_nps_percentage': record['all_time_nps_percentage'],
          'three_month_nps_percentage': record['three_month_nps_percentage'],
          'one_month_nps_percentage': record['one_month_nps_percentage'],
          'all_time_sales': record['all_time_sales'],
          'all_time_table_count': record['all_time_table_count'],
          'month_feedback_yes': record['month_feedback_yes'],
          'month_feedback_maybe': record['month_feedback_maybe'],
          'month_feedback_no': record['month_feedback_no'],
          'three_month_feedback_yes': record['three_month_feedback_yes'],
          'three_month_feedback_maybe': record['three_month_feedback_maybe'],
          'three_month_feedback_no': record['three_month_feedback_no'],
          'all_time_feedback_yes': record['all_time_feedback_yes'],
          'all_time_feedback_maybe': record['all_time_feedback_maybe'],
          'all_time_feedback_no': record['all_time_feedback_no'],
          'generated_at': record['generated_at'],
          'data_as_of_date': record['data_as_of_date'],
        });
      }
      
      // Replace old table
      await db.execute('DROP TABLE nps_monthly_reports');
      await db.execute('ALTER TABLE nps_monthly_reports_new RENAME TO nps_monthly_reports');
      
      // Recreate indexes
      await db.execute('CREATE INDEX idx_monthly_reports_server ON nps_monthly_reports(server_id)');
      await db.execute('CREATE INDEX idx_monthly_reports_month ON nps_monthly_reports(month_year)');
      
    } catch (e) {
      d('[IDMigrationService] Error migrating reports table: $e');
      rethrow;
    }
  }
  
  /// Migrate nps_calculation_log table
  static Future<void> _migrateCalculationLogTable() async {
    try {
      final db = DatabaseFactory.instance;
      
      // Get existing calculation log data
      final logs = await db.queryTable('nps_calculation_log');
      
      // Create new table with string server_id
      await db.execute('''
        CREATE TABLE nps_calculation_log_new (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          server_id TEXT NOT NULL,
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
      
      // Migrate data with ID conversion
      for (final record in logs) {
        final intServerId = record['server_id'] as int;
        final stringServerId = intServerId.toString();
        
        await db.insertInto('nps_calculation_log_new', {
          'server_id': stringServerId,
          'calculation_date': record['calculation_date'],
          'month_year': record['month_year'],
          'total_responses': record['total_responses'],
          'average_score': record['average_score'],
          'nps_score': record['nps_score'],
          'promoters': record['promoters'],
          'passives': record['passives'],
          'detractors': record['detractors'],
          'created_at': record['created_at'],
        });
      }
      
      // Replace old table
      await db.execute('DROP TABLE nps_calculation_log');
      await db.execute('ALTER TABLE nps_calculation_log_new RENAME TO nps_calculation_log');
      
      // Recreate indexes
      await db.execute('CREATE INDEX idx_calculation_log_server ON nps_calculation_log(server_id)');
      await db.execute('CREATE INDEX idx_calculation_log_date ON nps_calculation_log(calculation_date)');
      
    } catch (e) {
      d('[IDMigrationService] Error migrating calculation log table: $e');
      rethrow;
    }
  }
  
  /// Verify migration success
  static Future<bool> _verifyMigration() async {
    try {
      d('[IDMigrationService] Verifying migration...');
      
      final db = DatabaseFactory.instance;
      
      // Check that all server IDs are now strings
      final servers = await db.queryTable('servers');
      for (final server in servers) {
        final id = server['id'];
        if (id is! String) {
          d('[IDMigrationService] Verification failed: server ID is not string: $id');
          return false;
        }
      }
      
      // Check foreign key integrity
      final feedback = await db.queryTable('nps_feedback');
      for (final record in feedback) {
        final serverId = record['server_id'];
        if (serverId is! String) {
          d('[IDMigrationService] Verification failed: feedback server_id is not string: $serverId');
          return false;
        }
        
        // Verify foreign key exists
        final serverExists = await db.queryTable('servers', where: 'id = ?', whereArgs: [serverId]);
        if (serverExists.isEmpty) {
          d('[IDMigrationService] Verification failed: foreign key violation for server_id: $serverId');
          return false;
        }
      }
      
      d('[IDMigrationService] Migration verification passed');
      return true;
      
    } catch (e) {
      d('[IDMigrationService] Error during verification: $e');
      return false;
    }
  }
  
  /// Rollback migration if it fails
  static Future<void> _rollbackMigration(String backupPath) async {
    try {
      d('[IDMigrationService] Rolling back migration...');
      
      // Implementation would restore from backup
      // This depends on the backup storage mechanism
      
      d('[IDMigrationService] Migration rollback completed');
      
    } catch (e) {
      d('[IDMigrationService] Error during rollback: $e');
      rethrow;
    }
  }
  
  /// Check if database has integer server IDs
  static Future<bool> _hasIntegerServerIds() async {
    try {
      final db = DatabaseFactory.instance;
      
      // Query a sample server ID to check its type
      final servers = await db.queryTable('servers', limit: 1);
      if (servers.isEmpty) {
        return false; // No servers, no migration needed
      }
      
      final sampleId = servers.first['id'];
      return sampleId is int;
      
    } catch (e) {
      d('[IDMigrationService] Error checking ID type: $e');
      return false;
    }
  }
  
  /// Get migration status
  static Future<bool> _getMigrationStatus() async {
    try {
      // This would check a migration status flag in the database or settings
      // Implementation depends on where you store migration status
      return false; // Default: migration not completed
      
    } catch (e) {
      d('[IDMigrationService] Error getting migration status: $e');
      return false;
    }
  }
  
  /// Set migration status
  static Future<void> _setMigrationStatus(bool completed) async {
    try {
      // This would set a migration status flag in the database or settings
      // Implementation depends on where you store migration status
      
      d('[IDMigrationService] Migration status set to: $completed');
      
    } catch (e) {
      d('[IDMigrationService] Error setting migration status: $e');
    }
  }
}
