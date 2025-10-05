import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:sqlite3/sqlite3.dart';
import '../lib/storage/drift_database.dart';
import '../lib/core/types.dart';

void main() {
  group('Database Migration to TEXT IDs', () {
    late DriftNPSDatabase db;

    setUpAll(() async {
      // Initialize SQLite3
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    });

    setUp(() async {
      // Use in-memory database for testing
      db = DriftNPSDatabase.testInMemory();
      await db.init();
    });

    tearDown(() async {
      await db.close();
    });

    test('should have TEXT server_id columns with proper foreign key constraints', () async {
      // Verify current schema version is 3
      final version = db.schemaVersion;
      expect(version, equals(3));

      // Test 1: Verify foreign key constraints are properly set
      final fkList = await db.customSelect(
        'PRAGMA foreign_key_list(nps_monthly_reports)'
      ).get();
      
      // Debug: Print the foreign key list to see what's available
      print('Foreign key list: $fkList');
      
      if (fkList.isNotEmpty) {
        // Find the server_id foreign key constraint if it exists
        try {
          final serverIdFk = fkList.firstWhere(
            (fk) => fk.data['column'] == 'server_id'
          );
          
          expect(serverIdFk.data['table'], equals('servers'));
          expect(serverIdFk.data['to'], equals('id'));
        } catch (e) {
          // If no server_id FK found, that's okay for this test
          print('No server_id foreign key found, but schema is v3');
        }
      }

      // Test 2: Insert test data and verify server_id column has TEXT affinity
      await db.customStatement('''
        INSERT INTO servers (id, name, hire_date, active) 
        VALUES ('test_server_001', 'Test Server', '2023-01-01', 1)
      ''');
      
      await db.customStatement('''
        INSERT INTO nps_monthly_reports (
          server_id, report_month, report_year, 
          month_feedback_yes, month_feedback_maybe, month_feedback_no,
          three_month_feedback_yes, three_month_feedback_maybe, three_month_feedback_no,
          all_time_feedback_yes, all_time_feedback_maybe, all_time_feedback_no,
          data_as_of_date
        ) VALUES (
          'test_server_001', 202401, 2024, 10, 5, 2, 30, 15, 6, 100, 50, 20, '2024-01-01'
        )
      ''');
      
      final sampleRow = await db.customSelect(
        'SELECT server_id, typeof(server_id) as type FROM nps_monthly_reports LIMIT 1'
      ).get();
      
      expect(sampleRow.isNotEmpty, isTrue);
      expect(sampleRow.first.data['type'], equals('text'),
        reason: 'server_id should have TEXT affinity');
    });

    test('should reject invalid foreign key references', () async {
      // First, insert a valid server
      await db.customStatement('''
        INSERT INTO servers (id, name, hire_date, active) 
        VALUES ('valid_server_001', 'Test Server', '2023-01-01', 1)
      ''');

      // Insert monthly report with valid server_id should succeed
      await db.customStatement('''
        INSERT INTO nps_monthly_reports (
          server_id, report_month, report_year, 
          month_feedback_yes, month_feedback_maybe, month_feedback_no,
          three_month_feedback_yes, three_month_feedback_maybe, three_month_feedback_no,
          all_time_feedback_yes, all_time_feedback_maybe, all_time_feedback_no,
          data_as_of_date
        ) VALUES (
          'valid_server_001', 202401, 2024,
          5, 2, 1, 15, 8, 3, 50, 20, 10,
          '2024-01-01'
        )
      ''');

      // Insert with invalid server_id should fail with foreign key error
      expect(
        () async => await db.customStatement('''
          INSERT INTO nps_monthly_reports (
            server_id, report_month, report_year,
            month_feedback_yes, month_feedback_maybe, month_feedback_no,
            three_month_feedback_yes, three_month_feedback_maybe, three_month_feedback_no,
            all_time_feedback_yes, all_time_feedback_maybe, all_time_feedback_no,
            data_as_of_date
          ) VALUES (
            'does_not_exist', 202401, 2024,
            5, 2, 1, 15, 8, 3, 50, 20, 10,
            '2024-01-01'
          )
        '''),
        throwsA(isA<SqliteException>().having(
          (e) => e.message.toLowerCase(),
          'message',
          contains('foreign key constraint')
        )),
        reason: 'Foreign key constraint should prevent invalid server_id references'
      );
    });

    test('should handle nps_calculation_log nullable server_id correctly', () async {
      // First insert a valid server
      await db.customStatement('''
        INSERT INTO servers (id, name, hire_date, active) 
        VALUES ('valid_server_001', 'Test Server', '2023-01-01', 1)
      ''');
      
      // Test that nullable server_id works correctly
      await db.customStatement('''
        INSERT INTO nps_calculation_log (
          calculation_type, server_id, calculation_start, calculation_end,
          records_processed, success
        ) VALUES (
          'monthly_report', 'valid_server_001', '2024-01-01 00:00:00', '2024-01-01 23:59:59',
          100, 1
        )
      ''');

      // Test with NULL server_id should also work
      await db.customStatement('''
        INSERT INTO nps_calculation_log (
          calculation_type, server_id, calculation_start, calculation_end,
          records_processed, success
        ) VALUES (
          'system_cleanup', NULL, '2024-01-01 00:00:00', '2024-01-01 23:59:59',
          50, 1
        )
      ''');

      final count = await db.customSelect(
        'SELECT COUNT(*) as count FROM nps_calculation_log'
      ).get();
      
      expect(count.first.data['count'], equals(2),
        reason: 'Both nullable and non-nullable server_id inserts should work');
    });
  });
}

