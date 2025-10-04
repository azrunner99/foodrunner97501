import 'package:flutter/material.dart';
import '../database/phase5_nps_migration_service.dart';
import '../database/phase5_diagnostic_service.dart';
import '../database/nps_initialization_service.dart';
import '../utils/log.dart';

class Phase5Runner extends StatefulWidget {
  const Phase5Runner({super.key});

  @override
  State<Phase5Runner> createState() => _Phase5RunnerState();
}

class _Phase5RunnerState extends State<Phase5Runner> {
  bool _isRunning = false;
  Phase5MigrationReport? _report;
  final List<String> _logs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: const Text('Phase 5: NPS Database Migration'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Migration Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(
                      _report?.success == true 
                          ? Icons.check_circle 
                          : _report?.success == false 
                              ? Icons.error 
                              : Icons.data_usage,
                      size: 64,
                      color: _report?.success == true 
                          ? Colors.green 
                          : _report?.success == false 
                              ? Colors.red 
                              : Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'NPS Database Migration',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _report?.status ?? 'Ready to migrate integer IDs to string IDs',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    if (_report != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Execution Time: ${_report!.executionTimeMs}ms',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Metrics Grid
            if (_report != null) ...[
              _buildMetricsGrid(),
              const SizedBox(height: 16),
            ],
            
            // Action Buttons
            Column(
              children: [
                // First row: Diagnostic and Initialize
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isRunning ? null : _runDiagnostic,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Run Diagnostic'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isRunning ? null : _initializeDatabase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Initialize DB'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Second row: Migration button (full width)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isRunning ? null : _runMigration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: _isRunning
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Processing...'),
                            ],
                          )
                        : const Text('Run Migration'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Results Summary
            if (_report != null) _buildResultsSummary(),
            
            const SizedBox(height: 16),
            
            // Live Logs
            Expanded(
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.terminal, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Migration Log',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          if (_logs.isNotEmpty)
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _logs.clear();
                                });
                              },
                              icon: const Icon(Icons.clear, size: 16),
                              label: const Text('Clear'),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _logs.isEmpty
                          ? const Center(
                              child: Text(
                                'Click "Run NPS Database Migration" to start',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _logs.length,
                              itemBuilder: (context, index) {
                                final log = _logs[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    log,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetricsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        _buildMetricCard(
          'Records Found',
          _report!.totalRecords.toString(),
          Icons.data_usage,
          Colors.blue,
        ),
        _buildMetricCard(
          'Successful',
          _report!.successfulMigrations.toString(),
          Icons.check_circle,
          Colors.green,
        ),
        _buildMetricCard(
          'Failed',
          _report!.failedMigrations.toString(),
          Icons.error,
          Colors.red,
        ),
        _buildMetricCard(
          'Success Rate',
          '${_report!.successRate.toStringAsFixed(1)}%',
          Icons.trending_up,
          Colors.orange,
        ),
      ],
    );
  }
  
  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildResultsSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.assessment, size: 20),
                SizedBox(width: 8),
                Text(
                  'Migration Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Migration Status', _report!.status),
            _buildSummaryRow('Records Processed', '${_report!.totalRecords}'),
            _buildSummaryRow('Successful Migrations', '${_report!.successfulMigrations}'),
            _buildSummaryRow('Failed Migrations', '${_report!.failedMigrations}'),
            _buildSummaryRow('Remaining Integer IDs', '${_report!.remainingIntegerIds}'),
            _buildSummaryRow('Success Rate', '${_report!.successRate.toStringAsFixed(1)}%'),
            if (_report!.unmappedIds.isNotEmpty)
              _buildSummaryRow('Unmapped IDs', _report!.unmappedIds.join(', ')),
            if (_report!.errors.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Errors:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              ..._report!.errors.map((error) => Text(
                '• $error',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              )),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _runMigration() async {
    setState(() {
      _isRunning = true;
      _logs.clear();
    });
    
    _addLog('Starting Phase 5: NPS Database Migration...');
    _addLog('Converting integer server IDs to string format...');
    
    try {
      final migrationService = Phase5NPSMigrationService();
      final report = await migrationService.migrateNPSDatabase();
      
      setState(() {
        _report = report;
        _isRunning = false;
      });
      
      if (report.success) {
        _addLog('✅ Migration completed successfully!');
        _addLog('📊 Migrated ${report.successfulMigrations} records');
        if (report.isComplete) {
          _addLog('🎉 All integer IDs have been converted to string format');
        }
      } else {
        _addLog('❌ Migration encountered errors');
        for (final error in report.errors) {
          _addLog('   • $error');
        }
      }
      
    } catch (e) {
      _addLog('❌ Migration failed: $e');
      setState(() {
        _isRunning = false;
      });
    }
  }
  
  Future<void> _initializeDatabase() async {
    setState(() {
      _isRunning = true;
      _logs.clear();
    });
    
    _addLog('🚀 Initializing NPS Database...');
    _addLog('Creating nps_entries table and indexes...');
    
    try {
      final initService = NPSInitializationService();
      final report = await initService.initializeNPSDatabase();
      
      setState(() {
        _isRunning = false;
      });
      
      if (report.success) {
        _addLog('✅ Database initialization successful!');
        _addLog('📊 Status: ${report.status}');
        _addLog('📋 Created ${report.columnCount} columns');
        
        if (report.tablesCreated) {
          _addLog('🎉 NPS tracking table created successfully');
        }
        
        if (report.indexesCreated) {
          _addLog('⚡ Performance indexes created');
        }
        
        if (report.operationTestPassed) {
          _addLog('✅ Database operations test passed');
        }
        
        _addLog('');
        _addLog('📝 Table structure:');
        for (final column in report.columns) {
          _addLog('   • $column');
        }
        
        _addLog('');
        _addLog('🎯 Ready for NPS data! You can now:');
        _addLog('   1. Add NPS entries through the app');
        _addLog('   2. Run diagnostic to verify structure');
        _addLog('   3. Use migration tools if needed');
        
      } else {
        _addLog('❌ Database initialization failed');
        for (final error in report.errors) {
          _addLog('   • $error');
        }
      }
      
    } catch (e) {
      _addLog('❌ Initialization failed: $e');
      setState(() {
        _isRunning = false;
      });
    }
  }

  Future<void> _runDiagnostic() async {
    setState(() {
      _isRunning = true;
      _logs.clear();
    });
    
    _addLog('🔍 Running Phase 5 Diagnostic...');
    _addLog('Checking NPS database and server storage...');
    
    try {
      final diagnostic = Phase5DiagnosticService();
      final result = await diagnostic.runDiagnostic();
      
      setState(() {
        _isRunning = false;
      });
      
      _addLog('📊 Diagnostic Results:');
      _addLog('   • NPS Records: ${result['npsRecordCount']}');
      _addLog('   • Integer IDs found: ${result['integerIdCount']}');
      _addLog('   • Server count: ${result['serverCount']}');
      
      if (result['sampleIntegerIds'].isNotEmpty) {
        _addLog('   • Sample integer IDs:');
        for (final id in result['sampleIntegerIds']) {
          _addLog('     - $id');
        }
      }
      
      if (result['sampleServers'].isNotEmpty) {
        _addLog('   • Sample servers:');
        for (final server in result['sampleServers'].take(3)) {
          _addLog('     - $server');
        }
      }
      
      if (result['errors'].isNotEmpty) {
        _addLog('❌ Errors found:');
        for (final error in result['errors']) {
          _addLog('   • $error');
        }
      } else {
        _addLog('✅ All systems accessible - ready for migration!');
      }
      
    } catch (e) {
      _addLog('❌ Diagnostic failed: $e');
      setState(() {
        _isRunning = false;
      });
    }
  }
  
  void _addLog(String message) {
    setState(() {
      final timestamp = DateTime.now().toString().substring(11, 23);
      _logs.add('[$timestamp] $message');
    });
  }
}