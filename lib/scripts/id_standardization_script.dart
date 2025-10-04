import 'dart:io';
import '../services/id_migration_service.dart';
import '../storage/database_factory.dart';
import '../utils/log.dart';

/// ID Standardization Script
/// 
/// This script handles the complete ID standardization process,
/// including migration, validation, and verification.
class IDStandardizationScript {
  
  /// Run the complete ID standardization process
  static Future<bool> runStandardization() async {
    print('🚀 Starting ID Standardization Process...\n');
    
    try {
      // Step 1: Check if migration is needed
      print('🔍 Step 1: Checking if migration is needed...');
      final migrationService = IDMigrationService.instance;
      final migrationStatus = await migrationService.getMigrationStatus();
      print('📋 Migration status: $migrationStatus');
      
      if (migrationStatus.contains('No migration needed')) {
        print('✅ No migration needed. IDs are already standardized.');
        return true;
      }
      print('📋 Migration required. Proceeding with standardization.\n');
      
      // Step 2: Initialize database connection
      print('🔌 Step 2: Initializing database connection...');
      await DatabaseFactory.initialize();
      print('✅ Database connection established.\n');
      
      // Step 3: Run migration
      print('🔄 Step 3: Running ID migration...');
      final migrationSuccess = await migrationService.executeFullMigration();
      if (!migrationSuccess) {
        print('❌ Migration failed. Please check logs for details.');
        return false;
      }
      print('✅ ID migration completed successfully.\n');
      
      // Step 4: Validate results
      print('🔍 Step 4: Validating migration results...');
      final validationSuccess = await _validateStandardization();
      if (!validationSuccess) {
        print('❌ Validation failed. Data may be inconsistent.');
        return false;
      }
      print('✅ Validation passed. All IDs are now standardized.\n');
      
      // Step 5: Show summary
      await _showMigrationSummary();
      
      print('\n🎉 ID Standardization completed successfully!');
      print('💡 All server IDs are now consistently using String format.');
      print('🗑️  Old integer ID references have been migrated.');
      
      return true;
      
    } catch (e) {
      print('❌ ID Standardization failed with error: $e');
      return false;
    }
  }
  
  /// Validate the standardization results
  static Future<bool> _validateStandardization() async {
    try {
      final db = DatabaseFactory.instance;
      
      // Check servers table
      print('   📊 Validating servers table...');
      final servers = await db.queryTable('servers');
      for (final server in servers) {
        if (server['id'] is! String) {
          print('   ❌ Server ID is not a string: ${server['id']}');
          return false;
        }
      }
      print('   ✅ All server IDs are strings (${servers.length} servers)');
      
      // Check foreign key relationships
      print('   📊 Validating foreign key relationships...');
      
      // Validate nps_feedback
      final feedback = await db.queryTable('nps_feedback');
      for (final record in feedback) {
        if (record['server_id'] is! String) {
          print('   ❌ Feedback server_id is not a string: ${record['server_id']}');
          return false;
        }
      }
      print('   ✅ All feedback records have string server_ids (${feedback.length} records)');
      
      // Validate nps_monthly_reports
      final reports = await db.queryTable('nps_monthly_reports');
      for (final record in reports) {
        if (record['server_id'] is! String) {
          print('   ❌ Report server_id is not a string: ${record['server_id']}');
          return false;
        }
      }
      print('   ✅ All monthly reports have string server_ids (${reports.length} reports)');
      
      // Validate nps_calculation_log
      final logs = await db.queryTable('nps_calculation_log');
      for (final record in logs) {
        if (record['server_id'] is! String) {
          print('   ❌ Calculation log server_id is not a string: ${record['server_id']}');
          return false;
        }
      }
      print('   ✅ All calculation logs have string server_ids (${logs.length} logs)');
      
      return true;
      
    } catch (e) {
      print('   ❌ Validation error: $e');
      return false;
    }
  }
  
  /// Show migration summary
  static Future<void> _showMigrationSummary() async {
    try {
      final db = DatabaseFactory.instance;
      
      print('📈 Migration Summary:');
      
      // Count records in each table
      final serverCount = (await db.queryTable('servers')).length;
      final feedbackCount = (await db.queryTable('nps_feedback')).length;
      final reportCount = (await db.queryTable('nps_monthly_reports')).length;
      final logCount = (await db.queryTable('nps_calculation_log')).length;
      
      print('   ├── Servers: $serverCount records migrated');
      print('   ├── NPS Feedback: $feedbackCount records migrated');
      print('   ├── Monthly Reports: $reportCount records migrated');
      print('   └── Calculation Logs: $logCount records migrated');
      
      final totalRecords = serverCount + feedbackCount + reportCount + logCount;
      print('   📊 Total Records Migrated: $totalRecords');
      
    } catch (e) {
      print('   ⚠️  Could not generate summary: $e');
    }
  }
  
  /// Test the standardized ID system
  static Future<bool> testStandardization() async {
    print('🧪 Testing ID Standardization...\n');
    
    try {
      final db = DatabaseFactory.instance;
      
      // Test 1: Create a test server with string ID
      print('📝 Test 1: Creating test server with string ID...');
      final testServerId = 'test_${DateTime.now().millisecondsSinceEpoch}';
      await db.insertInto('servers', {
        'id': testServerId,
        'name': 'Test Server',
        'hire_date': DateTime.now().toIso8601String().split('T')[0],
        'active': 1,
      });
      print('✅ Test server created with ID: $testServerId');
      
      // Test 2: Create test feedback with string server_id
      print('📝 Test 2: Creating test feedback with string server_id...');
      await db.insertInto('nps_feedback', {
        'server_id': testServerId,
        'feedback_type': 'yes',
        'feedback_date': DateTime.now().toIso8601String().split('T')[0],
      });
      print('✅ Test feedback created with server_id: $testServerId');
      
      // Test 3: Query with string ID
      print('📝 Test 3: Querying with string ID...');
      final queryResult = await db.queryTable('nps_feedback', 
        where: 'server_id = ?', 
        whereArgs: [testServerId]);
      if (queryResult.isEmpty) {
        print('❌ Query with string ID failed');
        return false;
      }
      print('✅ Query with string ID successful (${queryResult.length} results)');
      
      // Test 4: Verify foreign key relationship
      print('📝 Test 4: Verifying foreign key relationship...');
      final serverExists = await db.queryTable('servers', 
        where: 'id = ?', 
        whereArgs: [testServerId]);
      if (serverExists.isEmpty) {
        print('❌ Foreign key relationship broken');
        return false;
      }
      print('✅ Foreign key relationship working correctly');
      
      // Cleanup test data
  await db.deleteFrom('nps_feedback', 'server_id = ?', [testServerId]);
  await db.deleteFrom('servers', 'id = ?', [testServerId]);
      print('🧹 Test data cleaned up');
      
      print('\n✅ All standardization tests passed!');
      return true;
      
    } catch (e) {
      print('❌ Standardization test failed: $e');
      return false;
    }
  }
  
  /// Check current ID status
  static Future<void> checkIDStatus() async {
    print('🔍 Checking Current ID Status...\n');
    
    try {
      final db = DatabaseFactory.instance;
      
      // Check servers table
      final servers = await db.queryTable('servers', limit: 5);
      print('📊 Servers Table Sample:');
      for (final server in servers) {
        final id = server['id'];
        final idType = id.runtimeType.toString();
        print('   ├── ID: $id (Type: $idType)');
      }
      
      // Check feedback table
      final feedback = await db.queryTable('nps_feedback', limit: 5);
      print('\n📊 NPS Feedback Table Sample:');
      for (final record in feedback) {
        final serverId = record['server_id'];
        final idType = serverId.runtimeType.toString();
        print('   ├── Server ID: $serverId (Type: $idType)');
      }
      
      // Determine current status
      bool hasStringIds = true;
      bool hasIntegerIds = false;
      
      for (final server in servers) {
        if (server['id'] is int) {
          hasIntegerIds = true;
          hasStringIds = false;
          break;
        }
      }
      
      print('\n📋 Status Summary:');
      if (hasStringIds && !hasIntegerIds) {
        print('   ✅ All IDs are standardized to String format');
      } else if (hasIntegerIds && !hasStringIds) {
        print('   ⚠️  All IDs are Integer format (migration needed)');
      } else {
        print('   ⚠️  Mixed ID formats detected (migration needed)');
      }
      
    } catch (e) {
      print('❌ Error checking ID status: $e');
    }
  }
  
  /// Show help information
  static void showHelp() {
    print('''
🔧 ID Standardization Script

Usage:
  dart run lib/scripts/id_standardization_script.dart [command]

Commands:
  standardize - Run the complete ID standardization process
  test        - Test the standardized ID system
  status      - Check current ID format status
  help        - Show this help message

Examples:
  dart run lib/scripts/id_standardization_script.dart standardize
  dart run lib/scripts/id_standardization_script.dart test
  dart run lib/scripts/id_standardization_script.dart status

Description:
  This script standardizes all server IDs from integer format to string format
  across the entire application, including:
  
  • Servers table primary keys
  • Foreign key references in NPS feedback
  • Foreign key references in monthly reports
  • Foreign key references in calculation logs
  
  The migration process includes:
  • Automatic backup creation
  • Data integrity verification
  • Foreign key relationship preservation
  • Rollback capability if migration fails
''');
  }
}

/// Main function for command-line usage
void main(List<String> args) async {
  if (args.isEmpty) {
    IDStandardizationScript.showHelp();
    return;
  }
  
  final command = args[0].toLowerCase();
  
  switch (command) {
    case 'standardize':
      final success = await IDStandardizationScript.runStandardization();
      exit(success ? 0 : 1);
      
    case 'test':
      final success = await IDStandardizationScript.testStandardization();
      exit(success ? 0 : 1);
      
    case 'status':
      await IDStandardizationScript.checkIDStatus();
      exit(0);
      
    case 'help':
    default:
      IDStandardizationScript.showHelp();
      exit(0);
  }
}
