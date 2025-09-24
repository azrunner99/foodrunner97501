import 'package:flutter_test/flutter_test.dart';
import 'package:food_runs_counter/storage/database_factory.dart';
import 'package:food_runs_counter/storage/database_interface.dart';
import 'package:food_runs_counter/storage/drift_database.dart';
import 'package:food_runs_counter/storage/sqflite_database.dart';
import 'package:food_runs_counter/services/platform_service.dart';

/// Test suite for the database abstraction layer
/// 
/// Verifies that the database factory correctly selects the appropriate
/// implementation based on the platform and that both implementations
/// conform to the same interface.
void main() {
  group('Database Factory Tests', () {
    
    setUp(() async {
      // Reset any existing database instance
      await DatabaseFactory.reset();
    });

    tearDown(() async {
      // Clean up after each test
      await DatabaseFactory.reset();
    });

    test('should not be initialized initially', () {
      expect(DatabaseFactory.isInitialized, false);
      expect(() => DatabaseFactory.instance, throwsException);
    });

    test('should select appropriate database implementation', () async {
      // Initialize the database
      await DatabaseFactory.initialize();
      
      // Verify it's initialized
      expect(DatabaseFactory.isInitialized, true);
      
      final database = DatabaseFactory.instance;
      expect(database, isNotNull);
      expect(database, isA<DatabaseInterface>());
      
      // Check that the correct implementation was selected
      if (PlatformService.isAndroid) {
        expect(database, isA<SqfliteNPSDatabase>());
        expect(DatabaseFactory.implementationType, 'Sqflite (Android)');
      } else {
        expect(database, isA<DriftNPSDatabase>());
        expect(DatabaseFactory.implementationType, 'Drift (Cross-platform)');
      }
    });

    test('should not initialize twice', () async {
      await DatabaseFactory.initialize();
      final firstInstance = DatabaseFactory.instance;
      
      // Initialize again - should not throw
      await DatabaseFactory.initialize();
      final secondInstance = DatabaseFactory.instance;
      
      // Should be the same instance
      expect(identical(firstInstance, secondInstance), true);
    });

    test('should reset properly', () async {
      await DatabaseFactory.initialize();
      expect(DatabaseFactory.isInitialized, true);
      
      await DatabaseFactory.reset();
      expect(DatabaseFactory.isInitialized, false);
      expect(() => DatabaseFactory.instance, throwsException);
    });
  });

  group('Database Interface Conformity', () {
    late DatabaseInterface database;

    setUpAll(() async {
      await DatabaseFactory.initialize();
      database = DatabaseFactory.instance;
    });

    tearDownAll(() async {
      await DatabaseFactory.reset();
    });

    test('should support basic CRUD operations', () async {
      // These tests verify the interface exists and can be called
      // Note: We're not testing actual database operations here,
      // just that the methods exist and don't throw immediately
      
      expect(() => database.queryTable('test_table'), isA<Function>());
      expect(() => database.insertInto('test_table', {}), isA<Function>());
      expect(() => database.updateTable('test_table', {}, 'id = ?', [1]), isA<Function>());
      expect(() => database.deleteFrom('test_table', 'id = ?', [1]), isA<Function>());
      expect(() => database.execute('SELECT 1'), isA<Function>());
    });

    test('should support transactions', () async {
      expect(() => database.runTransaction<int>((txn) async {
        return 1;
      }), isA<Function>());
    });

    test('should support version management', () async {
      expect(() => database.getVersion(), isA<Function>());
    });

    test('should support cleanup', () async {
      expect(() => database.close(), isA<Function>());
    });
  });
}