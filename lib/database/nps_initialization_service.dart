import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../storage/nps_database.dart';
import '../utils/log.dart';

/// NPS Database Initialization Service
/// Creates the necessary database structure for NPS tracking
class NPSInitializationService {
  static const String _tag = 'NPSInit';

  Future<NPSInitializationReport> initializeNPSDatabase() async {
    final stopwatch = Stopwatch()..start();
    final report = NPSInitializationReport();
    
    try {
      d('[$_tag] 🚀 Starting NPS Database Initialization');
      
      // Step 1: Get database instance
      final npsDb = NPSDatabase.instance;
      final db = await npsDb.database;
      
      d('[$_tag] ✅ Database instance created');
      
      // Step 2: Check if table already exists
      final existingTables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='nps_entries'"
      );
      
      if (existingTables.isNotEmpty) {
        report.tableAlreadyExists = true;
        d('[$_tag] ⚠️ Table already exists');
      } else {
        // Step 3: Create the nps_entries table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS nps_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            server_id TEXT NOT NULL,
            rating INTEGER NOT NULL,
            comment TEXT,
            date TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            shift_type TEXT,
            business_date TEXT,
            created_at INTEGER DEFAULT (strftime('%s', 'now'))
          )
        ''');
        
        d('[$_tag] ✅ Created nps_entries table');
        
        // Step 4: Create indexes for performance
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_nps_server_id 
          ON nps_entries(server_id)
        ''');
        
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_nps_date 
          ON nps_entries(date)
        ''');
        
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_nps_business_date 
          ON nps_entries(business_date)
        ''');
        
        d('[$_tag] ✅ Created performance indexes');
        report.tablesCreated = true;
        report.indexesCreated = true;
      }
      
      // Step 5: Verify table structure
      final tableInfo = await db.rawQuery("PRAGMA table_info(nps_entries)");
      report.columnCount = tableInfo.length;
      report.columns = tableInfo.map((col) => '${col['name']} (${col['type']})').toList();
      
      // Step 6: Check if we can insert/query test data
      await _performBasicOperationTest(db, report);
      
      report.executionTimeMs = stopwatch.elapsedMilliseconds;
      report.success = true;
      
      d('[$_tag] ✅ NPS Database initialization completed successfully');
      
    } catch (e) {
      report.success = false;
      report.errors.add('Initialization failed: $e');
      d('[$_tag] ❌ Initialization failed: $e');
    } finally {
      stopwatch.stop();
    }
    
    return report;
  }
  
  Future<void> _performBasicOperationTest(Database db, NPSInitializationReport report) async {
    try {
      // Test insert
      final testId = await db.insert('nps_entries', {
        'server_id': 'test_server',
        'rating': 5,
        'comment': 'Test entry for database verification',
        'date': DateTime.now().toIso8601String().split('T')[0],
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'shift_type': 'lunch',
        'business_date': DateTime.now().toIso8601String().split('T')[0],
      });
      
      // Test query
      final testResult = await db.query('nps_entries', where: 'id = ?', whereArgs: [testId]);
      
      // Clean up test data
      await db.delete('nps_entries', where: 'id = ?', whereArgs: [testId]);
      
      if (testResult.isNotEmpty) {
        report.operationTestPassed = true;
        d('[$_tag] ✅ Basic operations test passed');
      }
      
    } catch (e) {
      report.operationTestPassed = false;
      report.errors.add('Operation test failed: $e');
      d('[$_tag] ❌ Operation test failed: $e');
    }
  }
}

class NPSInitializationReport {
  bool success = false;
  int executionTimeMs = 0;
  bool tableAlreadyExists = false;
  bool tablesCreated = false;
  bool indexesCreated = false;
  bool operationTestPassed = false;
  int columnCount = 0;
  List<String> columns = [];
  List<String> errors = [];
  
  String get status {
    if (!success) return 'Failed';
    if (tableAlreadyExists) return 'Already Initialized';
    if (tablesCreated) return 'Successfully Initialized';
    return 'Unknown';
  }
  
  Map<String, dynamic> toJson() => {
    'success': success,
    'executionTimeMs': executionTimeMs,
    'tableAlreadyExists': tableAlreadyExists,
    'tablesCreated': tablesCreated,
    'indexesCreated': indexesCreated,
    'operationTestPassed': operationTestPassed,
    'columnCount': columnCount,
    'columns': columns,
    'errors': errors,
    'status': status,
  };
}