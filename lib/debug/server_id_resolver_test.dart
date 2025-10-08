import '../services/server_id_resolver.dart';
import '../app_state.dart';
import '../storage/database_factory.dart';
import '../storage/nps_database_adapter.dart';
import '../utils/log.dart';

/// Debug test for ServerIdResolver functionality
/// 
/// Call this from admin screen or debug console to verify
/// ServerIdResolver is working correctly after initialization.
class ServerIdResolverTest {
  static Future<void> runTests() async {
    d('=== ServerIdResolver Test Suite ===');
    d('');
    
    await _testInitialization();
    await _testCanonicalIdRetrieval();
    await _testIdResolution();
    await _testMappingReport();
    
    d('');
    d('=== Test Suite Complete ===');
  }
  
  static Future<void> _testInitialization() async {
    d('Test 1: Initialization Status');
    final stats = ServerIdResolver.getStatistics();
    
    d('  Initialized: ${stats['is_initialized']}');
    d('  Canonical Mappings: ${stats['canonical_mappings_count']}');
    d('  Reverse Mappings: ${stats['reverse_mappings_count']}');
    d('  Name Mappings: ${stats['name_mappings_count']}');
    
    if (stats['is_initialized'] == false) {
      d('  ⚠️ WARNING: ServerIdResolver not initialized!');
    } else {
      d('  ✅ PASS: ServerIdResolver is initialized');
    }
    d('');
  }
  
  static Future<void> _testCanonicalIdRetrieval() async {
    d('Test 2: Canonical ID Retrieval');
    
    try {
      final ids = ServerIdResolver.instance.getAllCanonicalIds();
      d('  Total Canonical IDs: ${ids.length}');
      
      if (ids.isEmpty) {
        d('  ⚠️ WARNING: No servers found in resolver');
      } else {
        d('  Server IDs:');
        for (final id in ids.take(10)) {
          d('    - $id');
        }
        if (ids.length > 10) {
          d('    ... and ${ids.length - 10} more');
        }
        d('  ✅ PASS: Retrieved ${ids.length} canonical IDs');
      }
    } catch (e) {
      d('  ❌ FAIL: Error retrieving canonical IDs: $e');
    }
    d('');
  }
  
  static Future<void> _testIdResolution() async {
    d('Test 3: ID Resolution');
    
    try {
      final ids = ServerIdResolver.instance.getAllCanonicalIds();
      
      if (ids.isEmpty) {
        d('  ⏭️ SKIP: No servers to test with');
        return;
      }
      
      // Test first 3 servers
      for (final id in ids.take(3)) {
        final canonical = ServerIdResolver.instance.getCanonicalId(id);
        final allKnown = ServerIdResolver.instance.getAllKnownIds(id);
        
        d('  Server ID "$id":');
        d('    → Canonical: "$canonical"');
        d('    → All known IDs: ${allKnown.join(", ")}');
        
        if (canonical == id) {
          d('    ✅ Resolves to itself (canonical)');
        } else {
          d('    ℹ️ Maps to different canonical ID');
        }
      }
      
      d('  ✅ PASS: ID resolution working');
    } catch (e) {
      d('  ❌ FAIL: Error testing ID resolution: $e');
    }
    d('');
  }
  
  static Future<void> _testMappingReport() async {
    d('Test 4: Generate Mapping Report');
    
    try {
      final report = await ServerIdResolver.generateMappingReport();
      d(report);
      d('  ✅ PASS: Mapping report generated');
    } catch (e) {
      d('  ❌ FAIL: Error generating mapping report: $e');
    }
    d('');
  }
  
  /// Test server lookup by name
  static Future<void> testServerLookupByName(String serverName) async {
    d('=== Server Name Lookup Test ===');
    d('Looking up: "$serverName"');
    
    try {
      final canonicalId = ServerIdResolver.instance.getCanonicalIdByName(serverName);
      
      if (canonicalId != null) {
        d('  ✅ Found canonical ID: "$canonicalId"');
        
        final allKnown = ServerIdResolver.instance.getAllKnownIds(canonicalId);
        d('  All known IDs for this server: ${allKnown.join(", ")}');
      } else {
        d('  ❌ Server not found by name');
      }
    } catch (e) {
      d('  ❌ Error: $e');
    }
    d('');
  }
  
  /// Test if two server IDs refer to the same server
  static Future<void> testServerComparison(String id1, String id2) async {
    d('=== Server Comparison Test ===');
    d('Comparing "$id1" with "$id2"');
    
    try {
      final areSame = ServerIdResolver.instance.areSameServer(id1, id2);
      
      if (areSame) {
        d('  ✅ These IDs refer to the SAME server');
      } else {
        d('  ℹ️ These IDs refer to DIFFERENT servers');
      }
      
      d('  ID 1 resolves to: "${ServerIdResolver.instance.getCanonicalId(id1)}"');
      d('  ID 2 resolves to: "${ServerIdResolver.instance.getCanonicalId(id2)}"');
    } catch (e) {
      d('  ❌ Error: $e');
    }
    d('');
  }
  
  /// Re-initialize resolver (useful for testing after server changes)
  static Future<void> reinitialize() async {
    d('=== Re-initializing ServerIdResolver ===');
    
    try {
      ServerIdResolver.instance.reset();
      d('  Resolver reset');
      
      final appState = AppState();
      final npsAdapter = NPSDatabaseAdapter(DatabaseFactory.instance);
      
      await ServerIdResolver.instance.initialize(appState, npsAdapter);
      final serverCount = ServerIdResolver.instance.getAllCanonicalIds().length;
      
      d('  ✅ Re-initialized with $serverCount servers');
    } catch (e) {
      d('  ❌ Re-initialization failed: $e');
    }
    d('');
  }
  
  /// Quick validation - returns true if everything looks good
  static Future<bool> quickValidation() async {
    final stats = ServerIdResolver.getStatistics();
    
    if (stats['is_initialized'] == false) {
      d('❌ Quick Validation FAILED: Not initialized');
      return false;
    }
    
    final serverCount = stats['canonical_mappings_count'] as int;
    if (serverCount == 0) {
      d('⚠️ Quick Validation WARNING: No servers found');
      return false;
    }
    
    d('✅ Quick Validation PASSED: $serverCount servers mapped');
    return true;
  }
}

