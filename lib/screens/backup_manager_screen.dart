import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../utils/backup_manager.dart';
import '../widgets/wallpaper_background.dart';

class BackupManagerScreen extends StatefulWidget {
  const BackupManagerScreen({super.key});

  @override
  State<BackupManagerScreen> createState() => _BackupManagerScreenState();
}

class _BackupManagerScreenState extends State<BackupManagerScreen> {
  List<BackupInfo> _backups = [];
  bool _isLoading = true;
  bool _isCreatingBackup = false;
  bool _isRestoring = false;
  Map<String, dynamic>? _locationInfo;
  bool _migrationInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadBackups();
    _loadLocationInfo();
    _checkAndMigrate();
  }

  Future<void> _loadLocationInfo() async {
    final info = await BackupManager.getBackupLocationInfo();
    setState(() {
      _locationInfo = info;
    });
  }

  Future<void> _checkAndMigrate() async {
    setState(() {
      _migrationInProgress = true;
    });
    
    try {
      await BackupManager.migrateBackupsToExternal();
      await _loadBackups(); // Refresh backup list after migration
    } catch (e) {
      // Migration failed or not needed, continue normally
    }
    
    setState(() {
      _migrationInProgress = false;
    });
  }

  Future<void> _loadBackups() async {
    print('[BackupManagerScreen] _loadBackups() called');
    setState(() => _isLoading = true);
    try {
      final backups = await BackupManager.getAvailableBackups();
      print('[BackupManagerScreen] Loaded ${backups.length} backups');
      setState(() {
        _backups = backups;
        _isLoading = false;
      });
    } catch (e) {
      print('[BackupManagerScreen] Error loading backups: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnackBar('Failed to load backups: $e', isError: true);
      }
    }
  }

  Future<void> _createBackup() async {
    setState(() => _isCreatingBackup = true);
    try {
      final result = await BackupManager.createBackup();
      if (result.success) {
        _showSnackBar('Backup created successfully: ${result.fileName}');
        await _loadBackups(); // Refresh the list
      } else {
        _showSnackBar(result.message, isError: true);
      }
    } catch (e) {
      _showSnackBar('Failed to create backup: $e', isError: true);
    } finally {
      setState(() => _isCreatingBackup = false);
    }
  }

  Future<void> _createNamedBackup() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Named Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter a custom name for this backup:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Backup Name',
                hintText: 'e.g. before_update_v2',
                border: OutlineInputBorder(),
              ),
              maxLength: 50,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _isCreatingBackup = true);
      try {
        final customName = '${result.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.json';
        final backupResult = await BackupManager.createBackup(customName: customName);
        if (backupResult.success) {
          _showSnackBar('Named backup created: $customName');
          await _loadBackups();
        } else {
          _showSnackBar(backupResult.message, isError: true);
        }
      } catch (e) {
        _showSnackBar('Failed to create named backup: $e', isError: true);
      } finally {
        setState(() => _isCreatingBackup = false);
      }
    }
  }

  Future<void> _restoreBackup(BackupInfo backup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This will restore all app data from the selected backup.'),
            const SizedBox(height: 16),
            const Text('⚠️ WARNING: This will replace ALL current data including:'),
            const SizedBox(height: 8),
            const Text('• All servers and their settings'),
            const Text('• Complete shift history'),
            const Text('• All achievements and profiles'),
            const Text('• App settings and preferences'),
            const SizedBox(height: 16),
            const Text('Your current data will be backed up before restoring.'),
            const SizedBox(height: 16),
            Text('Backup: ${backup.fileName}'),
            Text('Created: ${backup.formattedDate}'),
            Text('Size: ${backup.formattedSize}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isRestoring = true);
      try {
        final result = await BackupManager.restoreFromBackup(backup.filePath);
        if (result.success) {
          _showSnackBar('${result.message}\n\nPlease restart the app for all changes to take effect.');
          // Reload app state after restoration
          if (mounted) {
            final appState = Provider.of<AppState>(context, listen: false);
            await appState.load();
          }
        } else {
          _showSnackBar(result.message, isError: true);
        }
      } catch (e) {
        _showSnackBar('Failed to restore backup: $e', isError: true);
      } finally {
        setState(() => _isRestoring = false);
      }
    }
  }

  Future<void> _deleteBackup(BackupInfo backup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Backup'),
        content: Text('Are you sure you want to delete "${backup.fileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await BackupManager.deleteBackup(backup.filePath);
      if (success) {
        _showSnackBar('Backup deleted successfully');
        await _loadBackups();
      } else {
        _showSnackBar('Failed to delete backup', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red[700] : Colors.green[700],
          duration: Duration(seconds: isError ? 4 : 3),
        ),
      );
    }
  }

  Future<void> _triggerAutoBackup() async {
    setState(() => _isCreatingBackup = true);
    try {
      final result = await BackupManager.triggerAutomaticBackup();
      if (result.success) {
        _showSnackBar('Automatic backup created successfully');
        await _loadBackups();
      } else {
        _showSnackBar(result.message, isError: true);
      }
    } catch (e) {
      _showSnackBar('Failed to create automatic backup: $e', isError: true);
    } finally {
      setState(() => _isCreatingBackup = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Data Backup & Restore',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.shade600.withValues(alpha: 0.8),
                Colors.blue.shade400.withValues(alpha: 0.6),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          WallpaperBackground(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Storage location info
                  if (_locationInfo != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: _locationInfo!['survivesClearData'] 
                            ? Colors.green[50] 
                            : Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _locationInfo!['survivesClearData'] 
                              ? Colors.green[200]! 
                              : Colors.orange[200]!,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _locationInfo!['survivesClearData'] 
                                    ? Icons.security 
                                    : Icons.warning_outlined,
                                color: _locationInfo!['survivesClearData'] 
                                    ? Colors.green[700] 
                                    : Colors.orange[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Storage: ${_locationInfo!['primaryLocation']}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _locationInfo!['survivesClearData'] 
                                        ? Colors.green[800] 
                                        : Colors.orange[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _locationInfo!['survivesClearData'] 
                                ? 'Backups will survive app data clearing'
                                : 'Backups will be lost if app data is cleared',
                            style: TextStyle(
                              fontSize: 12,
                              color: _locationInfo!['survivesClearData'] 
                                  ? Colors.green[600] 
                                  : Colors.orange[600],
                            ),
                          ),
                          if (_migrationInProgress)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Migrating backups to external storage...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  // Action buttons
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isCreatingBackup ? null : _createBackup,
                                icon: _isCreatingBackup 
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.backup),
                                label: Text(_isCreatingBackup ? 'Creating...' : 'Quick Backup'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isCreatingBackup ? null : _createNamedBackup,
                                icon: const Icon(Icons.drive_file_rename_outline),
                                label: const Text('Named Backup'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Backups include all your data: servers, shift history, achievements, settings, preferences, custom avatar photos, station assignments, and section configurations.',
                                  style: TextStyle(fontSize: 12, color: Colors.blue),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Automatic backup section
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.schedule, color: Colors.green[600], size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Automatic Daily Backups',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Backups occur automatically every night during dinner closing hours (9-11 PM). Last 30 days are kept.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[600],
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isCreatingBackup ? null : _triggerAutoBackup,
                                  icon: const Icon(Icons.play_arrow, size: 16),
                                  label: const Text('Trigger Auto Backup Now'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[600],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Backup list
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _backups.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.backup_outlined, size: 64, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text(
                                      'No backups found',
                                      style: TextStyle(fontSize: 18, color: Colors.grey),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Create your first backup to protect your data',
                                      style: TextStyle(color: Colors.grey),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _backups.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final backup = _backups[index];
                                  return Card(
                                    elevation: 2,
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: backup.isAutomatic ? Colors.green[100] : Colors.blue[100],
                                        child: Icon(
                                          backup.isAutomatic ? Icons.schedule : Icons.backup, 
                                          color: backup.isAutomatic ? Colors.green : Colors.blue,
                                        ),
                                      ),
                                      title: Text(
                                        backup.displayName,
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Created: ${backup.formattedDate}'),
                                          Text('Size: ${backup.formattedSize}'),
                                          if (backup.metadata != null)
                                            Text('Version: ${backup.metadata!['version'] ?? 'Unknown'}'),
                                        ],
                                      ),
                                      isThreeLine: true,
                                      trailing: PopupMenuButton<String>(
                                        onSelected: (value) {
                                          switch (value) {
                                            case 'restore':
                                              _restoreBackup(backup);
                                              break;
                                            case 'delete':
                                              _deleteBackup(backup);
                                              break;
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'restore',
                                            child: Row(
                                              children: [
                                                Icon(Icons.restore, color: Colors.orange),
                                                SizedBox(width: 8),
                                                Text('Restore'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete, color: Colors.red),
                                                SizedBox(width: 8),
                                                Text('Delete'),
                                              ],
                                            ),
                                          ),
                                        ],
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
          // Loading overlay for restore operations
          if (_isRestoring)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Restoring data...'),
                        SizedBox(height: 8),
                        Text(
                          'Please wait while your data is being restored',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
