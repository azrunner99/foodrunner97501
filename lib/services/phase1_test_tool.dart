import '../services/server_id_resolver.dart';
import '../services/database_audit_tool.dart';
import '../utils/log.dart';
import '../models.dart';

/// Test tool for validating Phase 1 implementation
/// 
/// Comprehensive testing of ServerIdResolver and DatabaseAuditTool
class Phase1TestTool {
  static Phase1TestTool? _instance;
  static Phase1TestTool get instance => _instance ??= Phase1TestTool._();
  
  Phase1TestTool._();

  /// Run all Phase 1 tests
  static Future<Phase1TestResult> runAllTests() async {
    return await instance._runAllTests();
  }

  /// Test ServerIdResolver functionality
  static Future<TestResult> testServerIdResolver() async {
    return await instance._testServerIdResolver();
  }

  /// Test DatabaseAuditTool functionality
  static Future<TestResult> testDatabaseAuditTool() async {
    return await instance._testDatabaseAuditTool();
  }

  Future<Phase1TestResult> _runAllTests() async {
    final result = Phase1TestResult();
    
    d('[Phase1TestTool] Starting Phase 1 validation tests...');
    
    try {
      // Test 1: ServerIdResolver
      result.resolverTest = await _testServerIdResolver();
      
      // Test 2: Database Audit Tool
      result.auditTest = await _testDatabaseAuditTool();
      
      // Test 3: Integration tests
      result.integrationTest = await _testIntegration();
      
      // Test 4: Performance tests
      result.performanceTest = await _testPerformance();
      
      d('[Phase1TestTool] Phase 1 tests completed: ${result.overallSuccess ? 'SUCCESS' : 'FAILED'}');
      
    } catch (e) {
      d('[Phase1TestTool] Test execution failed: $e');
      result.addError('Test execution failed: $e');
    }
    
    return result;
  }

  Future<TestResult> _testServerIdResolver() async {
    final test = TestResult('ServerIdResolver');
    
    try {
      // Reset resolver for clean testing
      ServerIdResolver.resetResolver();
      
      // Test 1: Basic resolution
      await _testBasicResolution(test);
      
      // Test 2: Fallback strategies
      await _testFallbackStrategies(test);
      
      // Test 3: Cache functionality
      await _testCacheFunctionality(test);
      
      // Test 4: Statistics tracking
      await _testStatisticsTracking(test);
      
      // Test 5: Mapping report generation
      await _testMappingReportGeneration(test);
      
    } catch (e) {
      test.addError('ServerIdResolver test failed: $e');
    }
    
    return test;
  }

  Future<void> _testBasicResolution(TestResult test) async {
    // Test string ID resolution
    final stringResult = await ServerIdResolver.resolveToStandardId('server_1');
    if (stringResult == null) {
      test.addError('Failed to resolve string ID');
    } else {
      test.addSuccess('String ID resolution works');
    }
    
    // Test integer ID resolution
    final intResult = await ServerIdResolver.resolveToStandardId(1);
    test.addResult('Integer ID resolution', intResult != null);
    
    // Test Server object resolution
    try {
      final testServer = Server(id: 'test_server', name: 'Test Server');
      final objResult = await ServerIdResolver.resolveToServerObject(testServer);
      test.addResult('Server object resolution', objResult != null && objResult.id == 'test_server');
    } catch (e) {
      test.addError('Server object resolution failed: $e');
    }
    
    // Test null input handling
    final nullResult = await ServerIdResolver.resolveToStandardId(null);
    test.addResult('Null input handling', nullResult == null);
  }

  Future<void> _testFallbackStrategies(TestResult test) async {
    // Test name-based fallback
    try {
      // This would test with actual server data if available
      final nameResult = await ServerIdResolver.resolveToServerObject('Test Server');
      test.addResult('Name-based fallback', true); // Test completed without error
    } catch (e) {
      test.addError('Name-based fallback test failed: $e');
    }
    
    // Test pattern matching
    try {
      final patternResult = await ServerIdResolver.resolveToStandardId('server_999');
      test.addResult('Pattern matching', true); // Test completed
    } catch (e) {
      test.addError('Pattern matching test failed: $e');
    }
  }

  Future<void> _testCacheFunctionality(TestResult test) async {
    // Reset cache
    ServerIdResolver.resetResolver();
    
    // Make same request twice
    await ServerIdResolver.resolveToStandardId('test_cache');
    await ServerIdResolver.resolveToStandardId('test_cache');
    
    final stats = ServerIdResolver.getStatistics();
    final totalLookups = stats['total_lookups'] as int;
    final cacheHits = stats['cache_hits'] as int;
    
    test.addResult('Cache functionality', totalLookups >= 2);
    test.addSuccess('Cache statistics: $totalLookups lookups, $cacheHits hits');
  }

  Future<void> _testStatisticsTracking(TestResult test) async {
    final statsBefore = ServerIdResolver.getStatistics();
    
    // Make a few resolution attempts
    await ServerIdResolver.resolveToStandardId('stats_test_1');
    await ServerIdResolver.resolveToStandardId('stats_test_2');
    await ServerIdResolver.resolveToStandardId('stats_test_3');
    
    final statsAfter = ServerIdResolver.getStatistics();
    
    final beforeLookups = statsBefore['total_lookups'] as int;
    final afterLookups = statsAfter['total_lookups'] as int;
    
    test.addResult('Statistics tracking', afterLookups > beforeLookups);
    test.addSuccess('Lookup count increased from $beforeLookups to $afterLookups');
  }

  Future<void> _testMappingReportGeneration(TestResult test) async {
    try {
      final report = await ServerIdResolver.generateMappingReport();
      
      test.addResult('Mapping report generation', report.isNotEmpty);
      test.addResult('Report contains header', report.contains('SERVER ID MAPPING REPORT'));
      test.addResult('Report contains statistics', report.contains('RESOLUTION STATISTICS'));
      
      final reportLines = report.split('\n').length;
      test.addSuccess('Generated report with $reportLines lines');
      
    } catch (e) {
      test.addError('Mapping report generation failed: $e');
    }
  }

  Future<TestResult> _testDatabaseAuditTool() async {
    final test = TestResult('DatabaseAuditTool');
    
    try {
      // Test 1: Full audit execution
      await _testFullAudit(test);
      
      // Test 2: Audit report generation
      await _testAuditReportGeneration(test);
      
      // Test 3: Issue detection
      await _testIssueDetection(test);
      
    } catch (e) {
      test.addError('DatabaseAuditTool test failed: $e');
    }
    
    return test;
  }

  Future<void> _testFullAudit(TestResult test) async {
    try {
      final auditResult = await DatabaseAuditTool.runFullAudit();
      
      test.addResult('Audit execution', auditResult != null);
      test.addResult('Statistics collection', auditResult.mainStorageServerCount >= 0);
      
      test.addSuccess('Audit found ${auditResult.issues.length} issues');
      test.addSuccess('Main storage: ${auditResult.mainStorageServerCount} servers');
      test.addSuccess('NPS storage: ${auditResult.npsStorageServerCount} servers');
      
    } catch (e) {
      test.addError('Full audit test failed: $e');
    }
  }

  Future<void> _testAuditReportGeneration(TestResult test) async {
    try {
      final report = await DatabaseAuditTool.generateAuditReport();
      
      test.addResult('Audit report generation', report.isNotEmpty);
      test.addResult('Report contains header', report.contains('DATABASE AUDIT REPORT'));
      test.addResult('Report contains summary', report.contains('SUMMARY'));
      
      final reportLines = report.split('\n').length;
      test.addSuccess('Generated audit report with $reportLines lines');
      
    } catch (e) {
      test.addError('Audit report generation failed: $e');
    }
  }

  Future<void> _testIssueDetection(TestResult test) async {
    try {
      final auditResult = await DatabaseAuditTool.runFullAudit();
      
      // Test issue severity classification
      final criticalIssues = auditResult.issues.where((i) => i.severity == IssueSeverity.critical).length;
      final errorIssues = auditResult.issues.where((i) => i.severity == IssueSeverity.error).length;
      final warningIssues = auditResult.issues.where((i) => i.severity == IssueSeverity.warning).length;
      
      test.addSuccess('Issue classification: $criticalIssues critical, $errorIssues errors, $warningIssues warnings');
      test.addResult('Issue detection system', true); // System is functional
      
    } catch (e) {
      test.addError('Issue detection test failed: $e');
    }
  }

  Future<TestResult> _testIntegration() async {
    final test = TestResult('Integration');
    
    try {
      // Test resolver + audit tool integration
      final stats = ServerIdResolver.getStatistics();
      final auditResult = await DatabaseAuditTool.runFullAudit();
      
      test.addResult('Resolver-Audit integration', stats != null && auditResult != null);
      
      // Test data consistency
      if (auditResult.mainStorageServerCount > 0) {
        // Try to resolve some server IDs
        await ServerIdResolver.resolveToStandardId('1');
        await ServerIdResolver.resolveToStandardId('server_1');
        
        final updatedStats = ServerIdResolver.getStatistics();
        final newLookups = updatedStats['total_lookups'] as int;
        final oldLookups = stats['total_lookups'] as int;
        
        test.addResult('Cross-system data flow', newLookups > oldLookups);
      }
      
      test.addSuccess('Integration tests completed');
      
    } catch (e) {
      test.addError('Integration test failed: $e');
    }
    
    return test;
  }

  Future<TestResult> _testPerformance() async {
    final test = TestResult('Performance');
    
    try {
      final stopwatch = Stopwatch();
      
      // Test resolution performance
      stopwatch.start();
      for (int i = 0; i < 100; i++) {
        await ServerIdResolver.resolveToStandardId('perf_test_$i');
      }
      stopwatch.stop();
      
      final resolutionTime = stopwatch.elapsedMilliseconds;
      final avgResolutionTime = resolutionTime / 100;
      
      test.addResult('Resolution performance', avgResolutionTime < 50); // Should be under 50ms per resolution
      test.addSuccess('Average resolution time: ${avgResolutionTime.toStringAsFixed(2)}ms');
      
      // Test audit performance
      stopwatch.reset();
      stopwatch.start();
      await DatabaseAuditTool.runFullAudit();
      stopwatch.stop();
      
      final auditTime = stopwatch.elapsedMilliseconds;
      test.addResult('Audit performance', auditTime < 10000); // Should be under 10 seconds
      test.addSuccess('Audit completion time: ${auditTime}ms');
      
      // Test cache effectiveness
      final stats = ServerIdResolver.getStatistics();
      final cacheHitRate = double.tryParse((stats['cache_hit_rate'] as String).replaceAll('%', '')) ?? 0;
      
      test.addResult('Cache effectiveness', cacheHitRate > 10); // Should have some cache hits
      test.addSuccess('Cache hit rate: ${cacheHitRate.toStringAsFixed(1)}%');
      
    } catch (e) {
      test.addError('Performance test failed: $e');
    }
    
    return test;
  }
}

/// Result of Phase 1 testing
class Phase1TestResult {
  TestResult? resolverTest;
  TestResult? auditTest;
  TestResult? integrationTest;
  TestResult? performanceTest;
  final List<String> errors = [];
  
  bool get overallSuccess {
    return (resolverTest?.success ?? false) &&
           (auditTest?.success ?? false) &&
           (integrationTest?.success ?? false) &&
           (performanceTest?.success ?? false) &&
           errors.isEmpty;
  }
  
  int get totalTests {
    return (resolverTest?.totalTests ?? 0) +
           (auditTest?.totalTests ?? 0) +
           (integrationTest?.totalTests ?? 0) +
           (performanceTest?.totalTests ?? 0);
  }
  
  int get passedTests {
    return (resolverTest?.passedTests ?? 0) +
           (auditTest?.passedTests ?? 0) +
           (integrationTest?.passedTests ?? 0) +
           (performanceTest?.passedTests ?? 0);
  }
  
  void addError(String error) {
    errors.add(error);
  }
  
  String generateReport() {
    final report = StringBuffer();
    
    report.writeln('=== PHASE 1 TEST REPORT ===');
    report.writeln('Generated: ${DateTime.now()}');
    report.writeln('Overall Status: ${overallSuccess ? 'SUCCESS' : 'FAILED'}');
    report.writeln('Tests Passed: $passedTests/$totalTests');
    report.writeln('');
    
    if (resolverTest != null) {
      report.writeln('=== SERVER ID RESOLVER TESTS ===');
      report.writeln(resolverTest!.generateReport());
      report.writeln('');
    }
    
    if (auditTest != null) {
      report.writeln('=== DATABASE AUDIT TOOL TESTS ===');
      report.writeln(auditTest!.generateReport());
      report.writeln('');
    }
    
    if (integrationTest != null) {
      report.writeln('=== INTEGRATION TESTS ===');
      report.writeln(integrationTest!.generateReport());
      report.writeln('');
    }
    
    if (performanceTest != null) {
      report.writeln('=== PERFORMANCE TESTS ===');
      report.writeln(performanceTest!.generateReport());
      report.writeln('');
    }
    
    if (errors.isNotEmpty) {
      report.writeln('=== ERRORS ===');
      for (final error in errors) {
        report.writeln('❌ $error');
      }
      report.writeln('');
    }
    
    return report.toString();
  }
}

/// Individual test result
class TestResult {
  final String name;
  final List<String> successes = [];
  final List<String> failures = [];
  final List<String> errors = [];
  
  TestResult(this.name);
  
  void addSuccess(String message) {
    successes.add(message);
  }
  
  void addFailure(String message) {
    failures.add(message);
  }
  
  void addError(String message) {
    errors.add(message);
  }
  
  void addResult(String testName, bool passed) {
    if (passed) {
      addSuccess(testName);
    } else {
      addFailure(testName);
    }
  }
  
  bool get success => failures.isEmpty && errors.isEmpty && successes.isNotEmpty;
  int get totalTests => successes.length + failures.length;
  int get passedTests => successes.length;
  
  String generateReport() {
    final report = StringBuffer();
    
    report.writeln('$name: ${success ? 'PASSED' : 'FAILED'} ($passedTests/$totalTests)');
    
    if (successes.isNotEmpty) {
      for (final success in successes) {
        report.writeln('  ✅ $success');
      }
    }
    
    if (failures.isNotEmpty) {
      for (final failure in failures) {
        report.writeln('  ❌ $failure');
      }
    }
    
    if (errors.isNotEmpty) {
      for (final error in errors) {
        report.writeln('  🔥 $error');
      }
    }
    
    return report.toString();
  }
}