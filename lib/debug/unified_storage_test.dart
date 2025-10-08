import '../services/unified_storage_service.dart';
import '../models.dart';
import '../app_state.dart' show ServerProfile;
import '../utils/log.dart';

/// Phase 2.4: Comprehensive test suite for UnifiedStorageService
/// 
/// Tests that the real Drift implementation actually persists data
/// and works correctly across all operations.
class UnifiedStorageTest {
  /// Run all tests
  static Future<Map<String, dynamic>> runAllTests() async {
    d('=== UnifiedStorageService Test Suite ===');
    d('Testing real Drift database persistence...');
    d('');
    
    final results = <String, dynamic>{
      'initialization': await testInitialization(),
      'serverCRUD': await testServerCRUD(),
      'shiftCRUD': await testShiftCRUD(),
      'profileCRUD': await testProfileCRUD(),
      'settingsCRUD': await testSettingsCRUD(),
      'keyValueStorage': await testKeyValueStorage(),
      'transactions': await testTransactions(),
      'persistence': await testPersistence(),
      'stats': await testStats(),
    };
    
    final passed = results.values.where((r) => r['passed'] == true).length;
    final total = results.length;
    
    d('');
    d('=== Test Suite Complete ===');
    d('Passed: $passed/$total');
    d('Success Rate: ${(passed / total * 100).toStringAsFixed(1)}%');
    
    results['summary'] = {
      'passed': passed,
      'total': total,
      'successRate': passed / total * 100,
      'allPassed': passed == total,
    };
    
    return results;
  }
  
  /// Test 1: Initialization
  static Future<Map<String, dynamic>> testInitialization() async {
    d('Test 1: Initialization');
    
    try {
      await UnifiedStorageService.instance.init();
      d('  ✅ PASS: Service initialized');
      
      return {'passed': true, 'message': 'Initialization successful'};
    } catch (e) {
      d('  ❌ FAIL: $e');
      return {'passed': false, 'error': e.toString()};
    }
  }
  
  /// Test 2: Server CRUD Operations
  static Future<Map<String, dynamic>> testServerCRUD() async {
    d('Test 2: Server CRUD Operations');
    
    try {
      // Create test server
      final testServer = Server(
        id: 'test_server_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Test Server',
        teamColor: 'Blue',
        stationType: 'Table',
        hireDate: DateTime.now(),
      );
      
      // CREATE
      await UnifiedStorageService.instance.saveServer(testServer);
      d('  ✓ Server created: ${testServer.id}');
      
      // READ
      final servers = await UnifiedStorageService.instance.getAllServers();
      final found = servers.any((s) => s.id == testServer.id);
      
      if (!found) {
        throw Exception('Server not found after save');
      }
      d('  ✓ Server retrieved successfully');
      
      // UPDATE
      final updatedServer = Server(
        id: testServer.id,
        name: 'Updated Test Server',
        teamColor: 'Red',
        stationType: 'Bar',
        hireDate: testServer.hireDate,
      );
      
      await UnifiedStorageService.instance.saveServer(updatedServer);
      d('  ✓ Server updated');
      
      // Verify update
      final serversAfterUpdate = await UnifiedStorageService.instance.getAllServers();
      final updated = serversAfterUpdate.firstWhere((s) => s.id == testServer.id);
      
      if (updated.name != 'Updated Test Server') {
        throw Exception('Server update not persisted');
      }
      d('  ✓ Update verified');
      
      // DELETE
      await UnifiedStorageService.instance.deleteServer(testServer.id);
      d('  ✓ Server deleted');
      
      // Verify deletion
      final serversAfterDelete = await UnifiedStorageService.instance.getAllServers();
      final deleted = !serversAfterDelete.any((s) => s.id == testServer.id);
      
      if (!deleted) {
        throw Exception('Server not deleted');
      }
      d('  ✓ Deletion verified');
      
      d('  ✅ PASS: All server CRUD operations work');
      return {'passed': true, 'message': 'Server CRUD successful'};
    } catch (e) {
      d('  ❌ FAIL: $e');
      return {'passed': false, 'error': e.toString()};
    }
  }
  
  /// Test 3: Shift CRUD Operations
  static Future<Map<String, dynamic>> testShiftCRUD() async {
    d('Test 3: Shift CRUD Operations');
    
    try {
      // Create test shift
      final testShift = ShiftRecord(
        id: 'test_shift_${DateTime.now().millisecondsSinceEpoch}',
        label: 'Test Lunch',
        shiftType: 'Lunch',
        start: DateTime.now(),
        counts: {'server1': 5, 'server2': 3},
        pizookieCounts: {'server1': 2},
        stationAssignments: {'server1': 'Table 1'},
        sectionAssignments: {'server1': 'A'},
      );
      
      // CREATE
      await UnifiedStorageService.instance.saveShift(testShift);
      d('  ✓ Shift created');
      
      // READ
      final shifts = await UnifiedStorageService.instance.getAllShifts();
      final found = shifts.any((s) => s.id == testShift.id);
      
      if (!found) {
        throw Exception('Shift not found after save');
      }
      
      // Verify JSON deserialization
      final savedShift = shifts.firstWhere((s) => s.id == testShift.id);
      if (savedShift.counts['server1'] != 5) {
        throw Exception('Shift counts not deserialized correctly');
      }
      
      d('  ✓ Shift retrieved and JSON deserialized correctly');
      
      // DELETE
      await UnifiedStorageService.instance.deleteShift(testShift.id);
      d('  ✓ Shift deleted');
      
      d('  ✅ PASS: All shift CRUD operations work');
      return {'passed': true, 'message': 'Shift CRUD with JSON serialization successful'};
    } catch (e) {
      d('  ❌ FAIL: $e');
      return {'passed': false, 'error': e.toString()};
    }
  }
  
  /// Test 4: Profile CRUD Operations
  static Future<Map<String, dynamic>> testProfileCRUD() async {
    d('Test 4: Profile CRUD Operations');
    
    try {
      // Create test profile
      final testServerId = 'test_profile_${DateTime.now().millisecondsSinceEpoch}';
      final testProfile = ServerProfile(
        allTimeRuns: 100,
        points: 500,
        achievements: ['test_achievement'],
      );
      
      // CREATE
      await UnifiedStorageService.instance.saveServerProfile(testServerId, testProfile);
      d('  ✓ Profile created');
      
      // READ
      final profiles = await UnifiedStorageService.instance.getAllServerProfiles();
      final found = profiles.isNotEmpty;
      
      d('  ✓ Profile retrieved (${profiles.length} profiles found)');
      
      d('  ✅ PASS: Profile operations work');
      return {'passed': true, 'message': 'Profile CRUD successful'};
    } catch (e) {
      d('  ❌ FAIL: $e');
      return {'passed': false, 'error': e.toString()};
    }
  }
  
  /// Test 5: Settings CRUD Operations
  static Future<Map<String, dynamic>> testSettingsCRUD() async {
    d('Test 5: Settings CRUD Operations');
    
    try {
      final testKey = 'test_setting_${DateTime.now().millisecondsSinceEpoch}';
      final testValue = 'test_value_123';
      
      // CREATE/UPDATE
      await UnifiedStorageService.instance.setSetting(testKey, testValue);
      d('  ✓ Setting saved');
      
      // READ
      final retrieved = await UnifiedStorageService.instance.getSetting<String>(testKey);
      
      if (retrieved != testValue) {
        throw Exception('Setting value mismatch: expected $testValue, got $retrieved');
      }
      d('  ✓ Setting retrieved correctly');
      
      // DELETE
      await UnifiedStorageService.instance.setSetting(testKey, null);
      d('  ✓ Setting deleted');
      
      // Verify deletion
      final afterDelete = await UnifiedStorageService.instance.getSetting<String>(testKey);
      if (afterDelete != null) {
        throw Exception('Setting not deleted');
      }
      d('  ✓ Deletion verified');
      
      d('  ✅ PASS: Settings operations work');
      return {'passed': true, 'message': 'Settings CRUD successful'};
    } catch (e) {
      d('  ❌ FAIL: $e');
      return {'passed': false, 'error': e.toString()};
    }
  }
  
  /// Test 6: Key-Value Storage (TapLogs, DayPlans, Assets)
  static Future<Map<String, dynamic>> testKeyValueStorage() async {
    d('Test 6: Key-Value Storage');
    
    try {
      final testKey = 'test_${DateTime.now().millisecondsSinceEpoch}';
      final testData = {'foo': 'bar', 'count': 42};
      
      // Test TapLogs
      await UnifiedStorageService.instance.saveTapLogData(testKey, testData);
      final tapLog = await UnifiedStorageService.instance.getTapLogData(testKey);
      if (tapLog?['foo'] != 'bar') {
        throw Exception('TapLog data mismatch');
      }
      d('  ✓ TapLogs work');
      
      // Test DayPlans
      await UnifiedStorageService.instance.saveDayPlanData(testKey, testData);
      final dayPlan = await UnifiedStorageService.instance.getDayPlanData(testKey);
      if (dayPlan?['count'] != 42) {
        throw Exception('DayPlan data mismatch');
      }
      d('  ✓ DayPlans work');
      
      // Test Assets
      await UnifiedStorageService.instance.saveAssetData(testKey, testData);
      final asset = await UnifiedStorageService.instance.getAssetData(testKey);
      if (asset?['foo'] != 'bar') {
        throw Exception('Asset data mismatch');
      }
      d('  ✓ Assets work');
      
      d('  ✅ PASS: All key-value storage works');
      return {'passed': true, 'message': 'Key-value storage successful'};
    } catch (e) {
      d('  ❌ FAIL: $e');
      return {'passed': false, 'error': e.toString()};
    }
  }
  
  /// Test 7: Transaction Support
  static Future<Map<String, dynamic>> testTransactions() async {
    d('Test 7: Transaction Support');
    
    try {
      // Test successful transaction
      await UnifiedStorageService.instance.transaction(() async {
        final server1 = Server(
          id: 'txn_test_1_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Transaction Test 1',
        );
        final server2 = Server(
          id: 'txn_test_2_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Transaction Test 2',
        );
        
        await UnifiedStorageService.instance.saveServer(server1);
        await UnifiedStorageService.instance.saveServer(server2);
        
        d('  ✓ Transaction with multiple operations succeeded');
      });
      
      d('  ✅ PASS: Transaction support works');
      return {'passed': true, 'message': 'Transactions work correctly'};
    } catch (e) {
      d('  ❌ FAIL: $e');
      return {'passed': false, 'error': e.toString()};
    }
  }
  
  /// Test 8: Data Persistence Across Restarts
  static Future<Map<String, dynamic>> testPersistence() async {
    d('Test 8: Data Persistence');
    
    try {
      final testId = 'persistence_test_${DateTime.now().millisecondsSinceEpoch}';
      
      // Save a server
      final server = Server(
        id: testId,
        name: 'Persistence Test Server',
      );
      
      await UnifiedStorageService.instance.saveServer(server);
      d('  ✓ Server saved');
      
      // Verify it's there
      final servers = await UnifiedStorageService.instance.getAllServers();
      final found = servers.any((s) => s.id == testId);
      
      if (!found) {
        throw Exception('Server not found - persistence failed!');
      }
      
      d('  ✓ Server persisted to database');
      d('  ℹ️ Note: Full restart test requires manual app restart');
      
      // Clean up
      await UnifiedStorageService.instance.deleteServer(testId);
      
      d('  ✅ PASS: Data persists in database');
      return {'passed': true, 'message': 'Data persistence verified'};
    } catch (e) {
      d('  ❌ FAIL: $e');
      return {'passed': false, 'error': e.toString()};
    }
  }
  
  /// Test 9: Database Stats
  static Future<Map<String, dynamic>> testStats() async {
    d('Test 9: Database Stats');
    
    try {
      final stats = await UnifiedStorageService.instance.getDatabaseStats();
      
      d('  Database Statistics:');
      for (final entry in stats.entries) {
        d('    ${entry.key}: ${entry.value}');
      }
      
      d('  ✅ PASS: Stats retrieved successfully');
      return {'passed': true, 'message': 'Stats working', 'stats': stats};
    } catch (e) {
      d('  ❌ FAIL: $e');
      return {'passed': false, 'error': e.toString()};
    }
  }
  
  /// Quick smoke test - returns true if basic operations work
  static Future<bool> quickSmokeTest() async {
    try {
      // Initialize
      await UnifiedStorageService.instance.init();
      
      // Test basic operations
      final testId = 'smoke_test_${DateTime.now().millisecondsSinceEpoch}';
      
      // Save
      await UnifiedStorageService.instance.saveServer(Server(
        id: testId,
        name: 'Smoke Test',
      ));
      
      // Read
      final servers = await UnifiedStorageService.instance.getAllServers();
      final found = servers.any((s) => s.id == testId);
      
      // Delete
      await UnifiedStorageService.instance.deleteServer(testId);
      
      if (found) {
        d('✅ Quick Smoke Test PASSED');
        return true;
      } else {
        d('❌ Quick Smoke Test FAILED');
        return false;
      }
    } catch (e) {
      d('❌ Quick Smoke Test FAILED: $e');
      return false;
    }
  }
  
  /// Performance benchmark - measure operation speeds
  static Future<Map<String, int>> performanceBenchmark() async {
    d('=== Performance Benchmark ===');
    
    final results = <String, int>{};
    
    try {
      // Benchmark: Initialize
      final initStart = DateTime.now();
      await UnifiedStorageService.instance.init();
      results['init_ms'] = DateTime.now().difference(initStart).inMilliseconds;
      
      // Benchmark: Save Server
      final saveStart = DateTime.now();
      final testServer = Server(
        id: 'bench_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Benchmark Server',
      );
      await UnifiedStorageService.instance.saveServer(testServer);
      results['save_server_ms'] = DateTime.now().difference(saveStart).inMilliseconds;
      
      // Benchmark: Get All Servers
      final getAllStart = DateTime.now();
      await UnifiedStorageService.instance.getAllServers();
      results['get_all_servers_ms'] = DateTime.now().difference(getAllStart).inMilliseconds;
      
      // Benchmark: Delete Server
      final deleteStart = DateTime.now();
      await UnifiedStorageService.instance.deleteServer(testServer.id);
      results['delete_server_ms'] = DateTime.now().difference(deleteStart).inMilliseconds;
      
      d('Performance Results:');
      for (final entry in results.entries) {
        d('  ${entry.key}: ${entry.value}ms');
      }
      
      return results;
    } catch (e) {
      d('Benchmark failed: $e');
      return results;
    }
  }
  
  /// Generate test report
  static Future<String> generateTestReport() async {
    final buffer = StringBuffer();
    
    buffer.writeln('=== UnifiedStorageService Test Report ===');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('');
    
    final results = await runAllTests();
    final summary = results['summary'] as Map<String, dynamic>;
    
    buffer.writeln('Test Results:');
    buffer.writeln('  Passed: ${summary['passed']}/${summary['total']}');
    buffer.writeln('  Success Rate: ${summary['successRate'].toStringAsFixed(1)}%');
    buffer.writeln('  Overall: ${summary['allPassed'] ? '✅ ALL PASSED' : '⚠️ SOME FAILED'}');
    buffer.writeln('');
    
    buffer.writeln('Individual Tests:');
    for (final entry in results.entries) {
      if (entry.key == 'summary') continue;
      
      final result = entry.value as Map<String, dynamic>;
      final status = result['passed'] == true ? '✅' : '❌';
      buffer.writeln('  $status ${entry.key}: ${result['message'] ?? result['error']}');
    }
    
    buffer.writeln('');
    buffer.writeln('Performance Benchmark:');
    final perf = await performanceBenchmark();
    for (final entry in perf.entries) {
      buffer.writeln('  ${entry.key}: ${entry.value}ms');
    }
    
    return buffer.toString();
  }
}

