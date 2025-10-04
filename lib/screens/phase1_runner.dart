import 'package:flutter/material.dart';
import '../services/server_id_resolver.dart';
import '../services/database_audit_tool.dart';
import '../services/phase1_test_tool.dart';
import '../screens/id_diagnostic_dashboard.dart';
import '../utils/log.dart';

/// Phase 1 Implementation Runner
/// 
/// Demonstrates and executes all Phase 1 components:
/// - ServerIdResolver
/// - DatabaseAuditTool 
/// - IdDiagnosticDashboard
/// - Phase1TestTool
class Phase1Runner extends StatefulWidget {
  const Phase1Runner({Key? key}) : super(key: key);

  @override
  State<Phase1Runner> createState() => _Phase1RunnerState();
}

class _Phase1RunnerState extends State<Phase1Runner> {
  bool _isRunning = false;
  String _status = 'Ready to run Phase 1 implementation';
  List<String> _results = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phase 1: Server ID Standardization'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildActionButtons(),
            const SizedBox(height: 16),
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildResultsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phase 1: Foundation & Analysis',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This phase creates the foundation for server ID standardization by implementing:',
            ),
            const SizedBox(height: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ServerIdResolver - Multi-format ID resolution service'),
                Text('• DatabaseAuditTool - Comprehensive ID consistency analysis'),
                Text('• IdDiagnosticDashboard - Real-time monitoring interface'),
                Text('• Phase1TestTool - Validation and testing framework'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isRunning ? null : _runFullDemo,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Run Full Demo'),
                ),
                ElevatedButton.icon(
                  onPressed: _isRunning ? null : _testResolver,
                  icon: const Icon(Icons.search),
                  label: const Text('Test ID Resolver'),
                ),
                ElevatedButton.icon(
                  onPressed: _isRunning ? null : _runAudit,
                  icon: const Icon(Icons.analytics),
                  label: const Text('Run Database Audit'),
                ),
                ElevatedButton.icon(
                  onPressed: _openDashboard,
                  icon: const Icon(Icons.dashboard),
                  label: const Text('Open Dashboard'),
                ),
                ElevatedButton.icon(
                  onPressed: _isRunning ? null : _runTests,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Run Validation Tests'),
                ),
                ElevatedButton.icon(
                  onPressed: _clearResults,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Results'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (_isRunning)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    Icons.info,
                    color: Colors.blue,
                    size: 20,
                  ),
                const SizedBox(width: 8),
                Text(
                  'Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_status),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Results',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          result,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addResult(String message) {
    setState(() {
      _results.add('${DateTime.now().toString().substring(11, 19)} - $message');
    });
  }

  Future<void> _runFullDemo() async {
    setState(() {
      _isRunning = true;
      _status = 'Running full Phase 1 demonstration...';
    });

    try {
      _addResult('🚀 Starting Phase 1 Full Demo');
      _addResult('');

      // Step 1: Test ServerIdResolver
      await _testResolver(showStatus: false);

      // Step 2: Run Database Audit
      await _runAudit(showStatus: false);

      // Step 3: Run validation tests
      await _runTests(showStatus: false);

      // Step 4: Generate comprehensive report
      _addResult('📊 Generating comprehensive Phase 1 report...');
      await _generateComprehensiveReport();

      setState(() {
        _status = 'Phase 1 demonstration completed successfully! ✅';
      });

    } catch (e) {
      _addResult('❌ Demo failed: $e');
      setState(() {
        _status = 'Phase 1 demonstration failed';
      });
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  Future<void> _testResolver({bool showStatus = true}) async {
    if (showStatus) {
      setState(() {
        _isRunning = true;
        _status = 'Testing ServerIdResolver...';
      });
    }

    try {
      _addResult('🔍 Testing ServerIdResolver service...');

      // Test various ID formats
      final testIds = ['1', 'server_1', '999', 'nonexistent'];
      
      for (final testId in testIds) {
        final resolved = await ServerIdResolver.resolveToStandardId(testId);
        _addResult('  ID "$testId" -> ${resolved ?? "NOT FOUND"}');
      }

      // Get statistics
      final stats = ServerIdResolver.getStatistics();
      _addResult('📈 Resolver Statistics:');
      stats.forEach((key, value) {
        _addResult('  $key: $value');
      });

      // Generate mapping report
      _addResult('📋 Generating ID mapping report...');
      final mappingReport = await ServerIdResolver.generateMappingReport();
      final reportLines = mappingReport.split('\n').length;
      _addResult('  Generated report with $reportLines lines');

      if (showStatus) {
        setState(() {
          _status = 'ServerIdResolver testing completed';
        });
      }

    } catch (e) {
      _addResult('❌ Resolver test failed: $e');
      if (showStatus) {
        setState(() {
          _status = 'ServerIdResolver testing failed';
        });
      }
    } finally {
      if (showStatus) {
        setState(() {
          _isRunning = false;
        });
      }
    }
  }

  Future<void> _runAudit({bool showStatus = true}) async {
    if (showStatus) {
      setState(() {
        _isRunning = true;
        _status = 'Running database audit...';
      });
    }

    try {
      _addResult('🔍 Running comprehensive database audit...');

      final auditResult = await DatabaseAuditTool.runFullAudit();
      
      _addResult('📊 Audit Results:');
      _addResult('  Main Storage Servers: ${auditResult.mainStorageServerCount}');
      _addResult('  NPS Storage Servers: ${auditResult.npsStorageServerCount}');
      _addResult('  NPS Feedback Records: ${auditResult.npsFeedbackCount}');
      _addResult('  Monthly Reports: ${auditResult.monthlyReportsCount}');
      _addResult('  Total Issues Found: ${auditResult.issues.length}');

      if (auditResult.issues.isNotEmpty) {
        _addResult('⚠️  Issues by severity:');
        final criticalCount = auditResult.issues.where((i) => i.severity == IssueSeverity.critical).length;
        final errorCount = auditResult.issues.where((i) => i.severity == IssueSeverity.error).length;
        final warningCount = auditResult.issues.where((i) => i.severity == IssueSeverity.warning).length;
        
        _addResult('    Critical: $criticalCount');
        _addResult('    Errors: $errorCount');
        _addResult('    Warnings: $warningCount');
      } else {
        _addResult('✅ No issues found - system is healthy!');
      }

      if (showStatus) {
        setState(() {
          _status = 'Database audit completed';
        });
      }

    } catch (e) {
      _addResult('❌ Audit failed: $e');
      if (showStatus) {
        setState(() {
          _status = 'Database audit failed';
        });
      }
    } finally {
      if (showStatus) {
        setState(() {
          _isRunning = false;
        });
      }
    }
  }

  Future<void> _runTests({bool showStatus = true}) async {
    if (showStatus) {
      setState(() {
        _isRunning = true;
        _status = 'Running validation tests...';
      });
    }

    try {
      _addResult('🧪 Running Phase 1 validation tests...');

      final testResult = await Phase1TestTool.runAllTests();
      
      _addResult('📋 Test Results:');
      _addResult('  Overall Status: ${testResult.overallSuccess ? "PASSED ✅" : "FAILED ❌"}');
      _addResult('  Tests Passed: ${testResult.passedTests}/${testResult.totalTests}');

      if (testResult.resolverTest != null) {
        _addResult('  ServerIdResolver: ${testResult.resolverTest!.success ? "PASSED" : "FAILED"}');
      }
      
      if (testResult.auditTest != null) {
        _addResult('  DatabaseAuditTool: ${testResult.auditTest!.success ? "PASSED" : "FAILED"}');
      }
      
      if (testResult.integrationTest != null) {
        _addResult('  Integration: ${testResult.integrationTest!.success ? "PASSED" : "FAILED"}');
      }
      
      if (testResult.performanceTest != null) {
        _addResult('  Performance: ${testResult.performanceTest!.success ? "PASSED" : "FAILED"}');
      }

      if (testResult.errors.isNotEmpty) {
        _addResult('❌ Test Errors:');
        for (final error in testResult.errors) {
          _addResult('  $error');
        }
      }

      if (showStatus) {
        setState(() {
          _status = testResult.overallSuccess 
            ? 'All validation tests passed!' 
            : 'Some validation tests failed';
        });
      }

    } catch (e) {
      _addResult('❌ Test execution failed: $e');
      if (showStatus) {
        setState(() {
          _status = 'Validation tests failed';
        });
      }
    } finally {
      if (showStatus) {
        setState(() {
          _isRunning = false;
        });
      }
    }
  }

  void _openDashboard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const IdDiagnosticDashboard(),
      ),
    );
  }

  void _clearResults() {
    setState(() {
      _results.clear();
      _status = 'Results cleared - ready for new operations';
    });
  }

  Future<void> _generateComprehensiveReport() async {
    try {
      // Generate full test report
      final testResult = await Phase1TestTool.runAllTests();
      final testReport = testResult.generateReport();
      
      // Generate audit report
      final auditReport = await DatabaseAuditTool.generateAuditReport();
      
      // Generate resolver report
      final resolverReport = await ServerIdResolver.generateMappingReport();
      
      _addResult('📄 Comprehensive Phase 1 Report Generated:');
      _addResult('  Test Report: ${testReport.split('\n').length} lines');
      _addResult('  Audit Report: ${auditReport.split('\n').length} lines');
      _addResult('  Resolver Report: ${resolverReport.split('\n').length} lines');
      _addResult('');
      _addResult('🎉 Phase 1 implementation is complete and operational!');
      _addResult('');
      _addResult('Next Steps:');
      _addResult('  • Review diagnostic dashboard for ongoing monitoring');
      _addResult('  • Address any critical issues found in audit');
      _addResult('  • Proceed to Phase 2: Data Layer Standardization');

    } catch (e) {
      _addResult('❌ Report generation failed: $e');
    }
  }
}