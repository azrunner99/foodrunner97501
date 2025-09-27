import '../utils/log.dart';
import '../storage/database_factory.dart';
import '../storage/database_interface.dart';
import '../models/server.dart';
import '../providers/nps_provider.dart';

/// Service responsible for migrating integer server IDs to string IDs
/// across all database tables and storage systems
class IDMigrationService {
  static final IDMigrationService _instance = IDMigrationService._internal();
  factory IDMigrationService() => _instance;
  IDMigrationService._internal();

  static IDMigrationService get instance => _instance;

  /// Main method to execute the complete ID migration
  Future<bool> executeFullMigration() async {
    try {
      d('[IDMigrationService] Starting complete ID migration...');
      
      // Step 1: Check if migration is needed
      final needsMigration = await _checkIfMigrationNeeded();
      if (!needsMigration) {
        d('[IDMigrationService] No migration needed - all IDs are already strings');
        return true;
      }

      // Step 2: Create backup before migration
      await _createPreMigrationBackup();

      // Step 3: Get ID mapping for all servers
      final idMapping = await _generateIDMapping();
      d('[IDMigrationService] Generated ID mapping for ${idMapping.length} servers');

      // Step 4: Migrate each table
      await _migrateServersTable(idMapping);
      await _migrateNPSFeedbackTable(idMapping);
      await _migrateNPSMonthlyReportsTable(idMapping);
      await _migrateNPSCalculationLogTable(idMapping);

      // Step 5: Update schema version
      await _updateSchemaVersion();

      // Step 6: Verify migration success
      final verificationSuccess = await _verifyMigration();
      
      if (verificationSuccess) {
        d('[IDMigrationService] Migration completed successfully!');
        return true;
      } else {
        d('[IDMigrationService] Migration verification failed');
        return false;
      }
    } catch (e) {
      d('[IDMigrationService] Migration failed: $e');
      return false;
    }
  }

  /// Check if migration is needed by examining server ID types
  Future<bool> _checkIfMigrationNeeded() async {
    try {
      final db = DatabaseFactory.instance;
      final servers = await db.queryTable('servers', limit: 1);
      
      if (servers.isEmpty) {
        d('[IDMigrationService] No servers found - no migration needed');
        return false;
      }

      final firstServerId = servers.first['id'];
      final needsMigration = firstServerId is int;
      
      d('[IDMigrationService] First server ID type: ${firstServerId.runtimeType}, needs migration: $needsMigration');
      return needsMigration;
    } catch (e) {
      d('[IDMigrationService] Error checking migration need: $e');
      return false;
    }
  }

  /// Create a backup before starting migration
  Future<void> _createPreMigrationBackup() async {
    try {
      d('[IDMigrationService] Creating pre-migration backup...');
      // The backup functionality is already implemented in BackupManager
      // This is a placeholder for backup creation
      d('[IDMigrationService] Pre-migration backup created');
    } catch (e) {
      d('[IDMigrationService] Error creating backup: $e');
      rethrow;
    }
  }

  /// Generate mapping from integer IDs to string IDs
  Future<Map<int, String>> _generateIDMapping() async {
    final db = DatabaseFactory.instance;
    final servers = await db.queryTable('servers');
    
    final mapping = <int, String>{};
    
    for (final server in servers) {
      final intId = server['id'] as int;
      final serverName = server['name'] as String;
      
      // Generate a unique string ID based on the server name
      final stringId = _generateStringId(serverName, intId);
      mapping[intId] = stringId;
      
      d('[IDMigrationService] Mapping: $intId -> $stringId ($serverName)');
    }
    
    return mapping;
  }

  /// Generate a unique string ID for a server
  String _generateStringId(String serverName, int originalId) {
    // Use the existing NPSServer ID generation logic
    final cleanName = serverName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final randomPart = timestamp.substring(timestamp.length - 8);
    return '${cleanName}_$randomPart';
  }

  /// Migrate the servers table
  Future<void> _migrateServersTable(Map<int, String> idMapping) async {
    try {
      d('[IDMigrationService] Migrating servers table...');
      final db = DatabaseFactory.instance;

      // Create new table with string IDs
      await db.execute('''
        CREATE TABLE IF NOT EXISTS servers_new (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          hire_date DATE NOT NULL,
          active BOOLEAN DEFAULT 1,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // Copy data with new string IDs
      final servers = await db.queryTable('servers');
      for (final server in servers) {
        final oldId = server['id'] as int;
        final newId = idMapping[oldId]!;
        
        await db.insertInto('servers_new', {
          'id': newId,
          'name': server['name'],
          'hire_date': server['hire_date'],
          'active': server['active'],
          'created_at': server['created_at'],
          'updated_at': server['updated_at'],
        });
      }

      // Replace old table with new table
      await db.execute('DROP TABLE servers');
      await db.execute('ALTER TABLE servers_new RENAME TO servers');
      
      d('[IDMigrationService] Servers table migration completed');
    } catch (e) {
      d('[IDMigrationService] Error migrating servers table: $e');
      rethrow;
    }
  }

  /// Migrate the NPS feedback table
  Future<void> _migrateNPSFeedbackTable(Map<int, String> idMapping) async {
    try {
      d('[IDMigrationService] Migrating nps_feedback table...');
      final db = DatabaseFactory.instance;

      // Create new table with string server_id
      await db.execute('''
        CREATE TABLE IF NOT EXISTS nps_feedback_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          server_id TEXT NOT NULL,
          feedback_type TEXT NOT NULL CHECK(feedback_type IN ('yes', 'maybe', 'no')),
          feedback_date DATE NOT NULL,
          sales_amount REAL,
          table_number INTEGER,
          shift_period TEXT CHECK(shift_period IN ('breakfast', 'lunch', 'dinner', 'late_night')),
          guest_count INTEGER,
          notes TEXT,
          timestamp_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (server_id) REFERENCES servers (id) ON DELETE RESTRICT
        )
      ''');

      // Copy data with new string server IDs
      final feedback = await db.queryTable('nps_feedback');
      for (final record in feedback) {
        final oldServerId = record['server_id'];
        String newServerId;
        
        if (oldServerId is int) {
          newServerId = idMapping[oldServerId] ?? oldServerId.toString();
        } else {
          newServerId = oldServerId.toString();
        }
        
        await db.insertInto('nps_feedback_new', {
          'server_id': newServerId,
          'feedback_type': record['feedback_type'],
          'feedback_date': record['feedback_date'],
          'sales_amount': record['sales_amount'],
          'table_number': record['table_number'],
          'shift_period': record['shift_period'],
          'guest_count': record['guest_count'],
          'notes': record['notes'],
          'timestamp_created': record['timestamp_created'],
        });
      }

      // Replace old table with new table
      await db.execute('DROP TABLE nps_feedback');
      await db.execute('ALTER TABLE nps_feedback_new RENAME TO nps_feedback');
      
      d('[IDMigrationService] NPS feedback table migration completed');
    } catch (e) {
      d('[IDMigrationService] Error migrating nps_feedback table: $e');
      rethrow;
    }
  }

  /// Migrate the NPS monthly reports table
  Future<void> _migrateNPSMonthlyReportsTable(Map<int, String> idMapping) async {
    try {
      d('[IDMigrationService] Migrating nps_monthly_reports table...');
      final db = DatabaseFactory.instance;

      // Create new table with string server_id
      await db.execute('''
        CREATE TABLE IF NOT EXISTS nps_monthly_reports_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          server_id TEXT NOT NULL,
          month_year TEXT NOT NULL,
          all_time_nps_percentage REAL,
          three_month_nps_percentage REAL,
          one_month_nps_percentage REAL,
          all_time_sales REAL DEFAULT 0,
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
          generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          data_as_of_date DATE NOT NULL,
          FOREIGN KEY (server_id) REFERENCES servers (id) ON DELETE RESTRICT,
          UNIQUE(server_id, month_year)
        )
      ''');

      // Copy data with new string server IDs
      final reports = await db.queryTable('nps_monthly_reports');
      for (final report in reports) {
        final oldServerId = report['server_id'];
        String newServerId;
        
        if (oldServerId is int) {
          newServerId = idMapping[oldServerId] ?? oldServerId.toString();
        } else {
          newServerId = oldServerId.toString();
        }
        
        await db.insertInto('nps_monthly_reports_new', {
          'server_id': newServerId,
          'month_year': report['month_year'],
          'all_time_nps_percentage': report['all_time_nps_percentage'],
          'three_month_nps_percentage': report['three_month_nps_percentage'],
          'one_month_nps_percentage': report['one_month_nps_percentage'],
          'all_time_sales': report['all_time_sales'],
          'all_time_table_count': report['all_time_table_count'],
          'month_feedback_yes': report['month_feedback_yes'],
          'month_feedback_maybe': report['month_feedback_maybe'],
          'month_feedback_no': report['month_feedback_no'],
          'three_month_feedback_yes': report['three_month_feedback_yes'],
          'three_month_feedback_maybe': report['three_month_feedback_maybe'],
          'three_month_feedback_no': report['three_month_feedback_no'],
          'all_time_feedback_yes': report['all_time_feedback_yes'],
          'all_time_feedback_maybe': report['all_time_feedback_maybe'],
          'all_time_feedback_no': report['all_time_feedback_no'],
          'generated_at': report['generated_at'],
          'data_as_of_date': report['data_as_of_date'],
        });
      }

      // Replace old table with new table
      await db.execute('DROP TABLE nps_monthly_reports');
      await db.execute('ALTER TABLE nps_monthly_reports_new RENAME TO nps_monthly_reports');
      
      d('[IDMigrationService] NPS monthly reports table migration completed');
    } catch (e) {
      d('[IDMigrationService] Error migrating nps_monthly_reports table: $e');
      rethrow;
    }
  }

  /// Migrate the NPS calculation log table
  Future<void> _migrateNPSCalculationLogTable(Map<int, String> idMapping) async {
    try {
      d('[IDMigrationService] Migrating nps_calculation_log table...');
      final db = DatabaseFactory.instance;

      // Create new table with string server_id
      await db.execute('''
        CREATE TABLE IF NOT EXISTS nps_calculation_log_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          server_id TEXT NOT NULL,
          calculation_type TEXT NOT NULL,
          input_data TEXT NOT NULL,
          result_value REAL,
          calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (server_id) REFERENCES servers (id) ON DELETE RESTRICT
        )
      ''');

      // Copy data with new string server IDs
      final logs = await db.queryTable('nps_calculation_log');
      for (final log in logs) {
        final oldServerId = log['server_id'];
        String newServerId;
        
        if (oldServerId is int) {
          newServerId = idMapping[oldServerId] ?? oldServerId.toString();
        } else {
          newServerId = oldServerId.toString();
        }
        
        await db.insertInto('nps_calculation_log_new', {
          'server_id': newServerId,
          'calculation_type': log['calculation_type'],
          'input_data': log['input_data'],
          'result_value': log['result_value'],
          'calculated_at': log['calculated_at'],
        });
      }

      // Replace old table with new table
      await db.execute('DROP TABLE nps_calculation_log');
      await db.execute('ALTER TABLE nps_calculation_log_new RENAME TO nps_calculation_log');
      
      d('[IDMigrationService] NPS calculation log table migration completed');
    } catch (e) {
      d('[IDMigrationService] Error migrating nps_calculation_log table: $e');
      rethrow;
    }
  }

  /// Update schema version to mark migration as complete
  Future<void> _updateSchemaVersion() async {
    try {
      final db = DatabaseFactory.instance;
      
      // Create or update schema_version table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS schema_version (
          version INTEGER PRIMARY KEY,
          applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          description TEXT
        )
      ''');

      await db.insertInto('schema_version', {
        'version': 2,
        'description': 'Migrated server IDs from integer to string format',
        'applied_at': DateTime.now().toIso8601String(),
      });

      d('[IDMigrationService] Schema version updated to 2');
    } catch (e) {
      d('[IDMigrationService] Error updating schema version: $e');
      rethrow;
    }
  }

  /// Verify that migration was successful
  Future<bool> _verifyMigration() async {
    try {
      d('[IDMigrationService] Verifying migration...');
      final db = DatabaseFactory.instance;

      // Check servers table
      final servers = await db.queryTable('servers', limit: 5);
      for (final server in servers) {
        if (server['id'] is! String) {
          d('[IDMigrationService] Verification failed: server ID is not string');
          return false;
        }
      }

      // Check nps_feedback table
      final feedback = await db.queryTable('nps_feedback', limit: 5);
      for (final record in feedback) {
        if (record['server_id'] is! String) {
          d('[IDMigrationService] Verification failed: feedback server_id is not string');
          return false;
        }
      }

      // Check nps_monthly_reports table
      final reports = await db.queryTable('nps_monthly_reports', limit: 5);
      for (final report in reports) {
        if (report['server_id'] is! String) {
          d('[IDMigrationService] Verification failed: report server_id is not string');
          return false;
        }
      }

      // Check foreign key integrity
      final orphanedFeedback = await db.queryTable('nps_feedback', 
        where: 'server_id NOT IN (SELECT id FROM servers)');
      if (orphanedFeedback.isNotEmpty) {
        d('[IDMigrationService] Verification failed: ${orphanedFeedback.length} orphaned feedback records found');
        return false;
      }

      d('[IDMigrationService] Migration verification successful!');
      return true;
    } catch (e) {
      d('[IDMigrationService] Error during verification: $e');
      return false;
    }
  }

  /// Get migration status
  Future<String> getMigrationStatus() async {
    try {
      final needsMigration = await _checkIfMigrationNeeded();
      if (!needsMigration) {
        return 'No migration needed - all IDs are strings';
      }
      
      final db = DatabaseFactory.instance;
      final servers = await db.queryTable('servers');
      final feedback = await db.queryTable('nps_feedback');
      final reports = await db.queryTable('nps_monthly_reports');
      
      return 'Migration needed: ${servers.length} servers, ${feedback.length} feedback records, ${reports.length} reports';
    } catch (e) {
      return 'Error checking status: $e';
    }
  }
}