import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:sqlite3/sqlite3.dart';
import '../lib/storage/drift_database.dart';
import '../lib/core/types.dart';

void main() {
  group('Foreign Key Guard Tests', () {
    late DriftNPSDatabase db;

    setUpAll(() async {
      // Initialize SQLite3
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    });

    setUp(() async {
      // Create in-memory database for each test
      db = DriftNPSDatabase.testInMemory();
      await db.init();
    });

    tearDown(() async {
      await db.close();
    });

    test('should accept valid server_id references', () async {
      // Insert a valid server
      const serverId = 'valid_server_123';
      await db.customStatement('''
        INSERT INTO servers (id, name, hire_date, active) 
        VALUES (?, ?, '2023-01-01', 1)
      ''', [serverId, 'Test Server']);

      // Insert monthly report with valid server_id should succeed
      await db.customStatement('''
        INSERT INTO nps_monthly_reports (
          server_id, report_month, report_year,
          month_feedback_yes, month_feedback_maybe, month_feedback_no,
          three_month_feedback_yes, three_month_feedback_maybe, three_month_feedback_no,
          all_time_feedback_yes, all_time_feedback_maybe, all_time_feedback_no,
          data_as_of_date
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        serverId, 202401, 2024,
        5, 2, 1, 15, 8, 3, 50, 20, 10,
        '2024-01-01'
      ]);

      // Verify the insert succeeded
      final count = await db.customSelect(
        'SELECT COUNT(*) as count FROM nps_monthly_reports WHERE server_id = "$serverId"'
      ).get();
      
      expect(count.first.data['count'], equals(1),
        reason: 'Valid server_id reference should be accepted');
    });

    test('should reject invalid server_id references', () async {
      // Insert a valid server first
      const validServerId = 'valid_server_456';
      await db.customStatement('''
        INSERT INTO servers (id, name, hire_date, active) 
        VALUES (?, ?, '2023-01-01', 1)
      ''', [validServerId, 'Valid Server']);

      // Try to insert monthly report with non-existent server_id
      expect(
        () async => await db.customStatement('''
          INSERT INTO nps_monthly_reports (
            server_id, report_month, report_year,
            month_feedback_yes, month_feedback_maybe, month_feedback_no,
            three_month_feedback_yes, three_month_feedback_maybe, three_month_feedback_no,
            all_time_feedback_yes, all_time_feedback_maybe, all_time_feedback_no,
            data_as_of_date
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', [
          'does_not_exist', 202401, 2024,
          5, 2, 1, 15, 8, 3, 50, 20, 10,
          '2024-01-01'
        ]),
        throwsA(isA<SqliteException>().having(
          (e) => e.message.toLowerCase(),
          'message',
          anyOf([
            contains('foreign key constraint'),
            contains('foreign key'),
            contains('constraint')
          ])
        )),
        reason: 'Foreign key constraint should prevent invalid server_id references'
      );

      // Verify no invalid data was inserted
      final invalidCount = await db.customSelect(
        'SELECT COUNT(*) as count FROM nps_monthly_reports WHERE server_id = "does_not_exist"'
      ).get();
      
      expect(invalidCount.first.data['count'], equals(0),
        reason: 'Invalid server_id should not create any records');
    });

    test('should handle cascade behaviors correctly', () async {
      const serverId = 'cascade_test_server';
      
      // Insert server and monthly report
      await db.customStatement('''
        INSERT INTO servers (id, name, hire_date, active) 
        VALUES (?, ?, '2023-01-01', 1)
      ''', [serverId, 'Cascade Test Server']);

      await db.customStatement('''
        INSERT INTO nps_monthly_reports (
          server_id, report_month, report_year,
          month_feedback_yes, month_feedback_maybe, month_feedback_no,
          three_month_feedback_yes, three_month_feedback_maybe, three_month_feedback_no,
          all_time_feedback_yes, all_time_feedback_maybe, all_time_feedback_no,
          data_as_of_date
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        serverId, 202401, 2024,
        3, 1, 0, 9, 3, 0, 30, 10, 0,
        '2024-01-01'
      ]);

      // Verify both records exist
      final serverCount = await db.customSelect(
        'SELECT COUNT(*) as count FROM servers WHERE id = "$serverId"'
      ).get();
      
      final reportCount = await db.customSelect(
        'SELECT COUNT(*) as count FROM nps_monthly_reports WHERE server_id = "$serverId"'
      ).get();
      
      expect(serverCount.first.data['count'], equals(1));
      expect(reportCount.first.data['count'], equals(1));

      // Test RESTRICT behavior - should prevent server deletion if reports exist
      expect(
        () async => await db.customStatement(
          'DELETE FROM servers WHERE id = ?',
          [serverId]
        ),
        throwsA(isA<SqliteException>().having(
          (e) => e.message.toLowerCase(),
          'message',
          anyOf([
            contains('foreign key constraint'),
            contains('foreign key'),
            contains('constraint')
          ])
        )),
        reason: 'RESTRICT constraint should prevent server deletion when reports exist'
      );
    });

    test('should handle nullable server_id in calculation_log', () async {
      // Insert calculation log with NULL server_id should succeed
      await db.customStatement('''
        INSERT INTO nps_calculation_log (
          calculation_type, server_id, calculation_start, calculation_end,
          records_processed, success
        ) VALUES (?, ?, ?, ?, ?, ?)
      ''', [
        'system_cleanup', null, '2024-01-01 00:00:00', '2024-01-01 23:59:59',
        50, 1
      ]);

      // Verify the insert succeeded
      final count = await db.customSelect(
        'SELECT COUNT(*) as count FROM nps_calculation_log WHERE server_id IS NULL'
      ).get();
      
      expect(count.first.data['count'], equals(1),
        reason: 'NULL server_id should be allowed in nps_calculation_log');
    });
  });
}
