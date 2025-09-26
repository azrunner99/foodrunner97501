import 'package:flutter/material.dart';
import '../services/backup_test_service.dart';
import '../utils/log.dart';
import '../widgets/wallpaper_background.dart';

/// Backup Debug Screen
/// 
/// Provides debugging tools to test backup/restore functionality
class BackupDebugScreen extends StatefulWidget {
  const BackupDebugScreen({super.key});

  @override
  State<BackupDebugScreen> createState() => _BackupDebugScreenState();
}

class _BackupDebugScreenState extends State<BackupDebugScreen> {
  final BackupTestService _testService = BackupTestService.instance;
  bool _isRunningTest = false;
  Map<String, dynamic>? _testResults;
  Map<String, dynamic>? _currentDataSummary;

  @override
  void initState() {
    super.initState();
    _loadCurrentDataSummary();
  }

  Future<void> _loadCurrentDataSummary() async {
    try {
      final summary = await _testService.getCurrentDataSummary();
      setState(() {
        _currentDataSummary = summary;
      });
    } catch (e) {
      d('[BackupDebug] Error loading current data summary: $e');
    }
  }

  Future<void> _runBackupRestoreTest() async {
    setState(() {
      _isRunningTest = true;
      _testResults = null;
    });

    try {
      final results = await _testService.testBackupRestoreCycle();
      setState(() {
        _testResults = results;
      });
    } catch (e) {
      setState(() {
        _testResults = {'error': 'Test failed: $e'};
      });
    } finally {
      setState(() {
        _isRunningTest = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup Debug Tools'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: WallpaperBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Data Summary
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current App Data',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_currentDataSummary != null) ...[
                        Text('Servers: ${_currentDataSummary!['servers_count'] ?? 0}'),
                        Text('Shifts: ${_currentDataSummary!['shifts_count'] ?? 0}'),
                        Text('Profiles: ${_currentDataSummary!['profiles_count'] ?? 0}'),
                        Text('Totals: ${_currentDataSummary!['totals_count'] ?? 0}'),
                        if (_currentDataSummary!['server_names'] != null) ...[
                          const SizedBox(height: 8),
                          Text('Server Names: ${(_currentDataSummary!['server_names'] as List).join(', ')}'),
                        ],
                      ] else
                        const Text('Loading current data...'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Test Controls
              Text(
                'Backup/Restore Test',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isRunningTest ? null : _runBackupRestoreTest,
                  icon: _isRunningTest 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                  label: Text(_isRunningTest ? 'Running Test...' : 'Run Backup/Restore Test'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Test Results
              if (_testResults != null) ...[
                Text(
                  'Test Results',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_testResults!['success'] == true) ...[
                          Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green),
                              const SizedBox(width: 8),
                              const Text('Test Passed', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ] else if (_testResults!['error'] != null) ...[
                          Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red),
                              const SizedBox(width: 8),
                              const Text('Test Failed', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                        
                        const SizedBox(height: 12),
                        
                        // Display all test results
                        ..._testResults!.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text('${entry.key}: ${entry.value}'),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Instructions
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Debug Instructions',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This screen helps debug backup/restore issues:\n\n'
                        '1. Check "Current App Data" to see what data exists\n'
                        '2. Run "Backup/Restore Test" to test the complete cycle\n'
                        '3. Review test results to identify any issues\n\n'
                        'The test will:\n'
                        '• Create a backup\n'
                        '• Verify backup file structure\n'
                        '• Restore the backup\n'
                        '• Verify data was restored\n'
                        '• Clean up test files',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
