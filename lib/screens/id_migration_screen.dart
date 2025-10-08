import 'package:flutter/material.dart';
import '../services/id_migration_service.dart';
import '../utils/log.dart';

/// Admin screen for managing ID migration from int to String format
class IDMigrationScreen extends StatefulWidget {
  const IDMigrationScreen({super.key});

  @override
  State<IDMigrationScreen> createState() => _IDMigrationScreenState();
}

class _IDMigrationScreenState extends State<IDMigrationScreen> {
  bool _isLoading = false;
  String _statusMessage = 'Ready to check migration status';
  String _migrationStatus = '';
  bool _migrationCompleted = false;
  List<String> _migrationLog = [];

  @override
  void initState() {
    super.initState();
    _checkMigrationStatus();
  }

  Future<void> _checkMigrationStatus() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking migration status...';
    });

    try {
      final migrationService = IDMigrationService.instance;
      final status = await migrationService.getMigrationStatus();
      
      setState(() {
        _migrationStatus = status;
        _migrationCompleted = status.contains('No migration needed');
        _statusMessage = _migrationCompleted 
          ? 'All IDs are already in String format ✅'
          : 'Migration is needed';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error checking status: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _executeMigration() async {
    if (_migrationCompleted) {
      _showDialog('Migration Not Needed', 'All IDs are already in String format.');
      return;
    }

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Executing migration...';
      _migrationLog.clear();
    });

    _addToLog('🚀 Starting ID migration...');

    try {
      final migrationService = IDMigrationService.instance;
      
      _addToLog('📋 Checking migration requirements...');
      final status = await migrationService.getMigrationStatus();
      _addToLog('Status: $status');
      
      if (status.contains('No migration needed')) {
        _addToLog('✅ No migration needed!');
        setState(() {
          _migrationCompleted = true;
          _statusMessage = 'Migration check completed - no action needed';
          _isLoading = false;
        });
        return;
      }

      _addToLog('🔄 Executing database migration...');
      final success = await migrationService.executeFullMigration();
      
      if (success) {
        _addToLog('✅ Migration completed successfully!');
        _addToLog('🔍 Verifying migration results...');
        
        // Re-check status to confirm migration
        final newStatus = await migrationService.getMigrationStatus();
        _addToLog('New status: $newStatus');
        
        setState(() {
          _migrationCompleted = true;
          _migrationStatus = newStatus;
          _statusMessage = 'Migration completed successfully! ✅';
          _isLoading = false;
        });
        
        _showDialog('Migration Successful', 'All server IDs have been migrated to String format successfully.');
      } else {
        _addToLog('❌ Migration failed!');
        setState(() {
          _statusMessage = 'Migration failed - check logs';
          _isLoading = false;
        });
        
        _showDialog('Migration Failed', 'The migration process encountered an error. Please check the logs for details.');
      }
    } catch (e) {
      _addToLog('❌ Migration error: $e');
      setState(() {
        _statusMessage = 'Migration error: $e';
        _isLoading = false;
      });
      
      _showDialog('Migration Error', 'An error occurred during migration: $e');
    }
  }

  void _addToLog(String message) {
    setState(() {
      _migrationLog.add('${DateTime.now().toLocal().toString().substring(11, 19)} $message');
    });
    d('[IDMigrationScreen] $message');
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm ID Migration'),
        content: const Text(
          'This will migrate all server IDs from integer format to string format.\n\n'
          'This is a permanent change that affects:\n'
          '• Server records\n'
          '• NPS feedback data\n'
          '• Monthly reports\n'
          '• Calculation logs\n\n'
          'A backup will be created automatically.\n\n'
          'Do you want to proceed?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Proceed'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ID Migration'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _migrationCompleted ? Icons.check_circle : Icons.info,
                          color: _migrationCompleted ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Migration Status',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_statusMessage),
                    if (_migrationStatus.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _migrationStatus,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Actions
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _checkMigrationStatus,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Check Status'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _isLoading || _migrationCompleted ? null : _executeMigration,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Execute Migration'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ],
            ),
            
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],
            
            // Migration Log
            if (_migrationLog.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Migration Log',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListView.builder(
                      itemCount: _migrationLog.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            _migrationLog[index],
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
              ),
            ],
            
            // Information
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About ID Migration',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This migration converts all server IDs from integer format '
                      'to string format for improved consistency and compatibility. '
                      'The process is safe and includes automatic backup creation.',
                      style: TextStyle(fontSize: 12),
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
}





