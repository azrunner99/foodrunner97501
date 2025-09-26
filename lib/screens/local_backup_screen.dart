import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../services/local_backup_service.dart';
import '../utils/backup_manager.dart';
import '../utils/log.dart';
import '../widgets/wallpaper_background.dart';

/// Local Backup Management Screen
/// 
/// Provides manual save/restore functionality for local device storage.
/// Allows users to save backups to selected folders and restore from selected files.
class LocalBackupScreen extends StatefulWidget {
  const LocalBackupScreen({super.key});

  @override
  State<LocalBackupScreen> createState() => _LocalBackupScreenState();
}

class _LocalBackupScreenState extends State<LocalBackupScreen> {
  final LocalBackupService _localBackupService = LocalBackupService.instance;
  bool _isSaving = false;
  bool _isRestoring = false;
  bool _isLoadingBackups = false;
  List<BackupFileInfo> _availableBackups = [];
  String _statusMessage = 'Ready to backup or restore';

  @override
  void initState() {
    super.initState();
    _loadAvailableBackups();
  }

  Future<void> _loadAvailableBackups() async {
    setState(() {
      _isLoadingBackups = true;
      _statusMessage = 'Loading available backups...';
    });

    try {
      final backups = await _localBackupService.getAvailableBackups();
      setState(() {
        _availableBackups = backups;
        _isLoadingBackups = false;
        _statusMessage = 'Found ${backups.length} backup files';
      });
    } catch (e) {
      setState(() {
        _isLoadingBackups = false;
        _statusMessage = 'Error loading backups: $e';
      });
    }
  }

  Future<void> _saveToSelectedFolder() async {
    setState(() {
      _isSaving = true;
      _statusMessage = 'Selecting folder and creating backup...';
    });

    try {
      final result = await _localBackupService.saveToLocalFolder();
      setState(() {
        _isSaving = false;
        if (result.success) {
          _statusMessage = 'Backup saved successfully to: ${result.filePath}';
        } else {
          _statusMessage = 'Backup failed: ${result.message}';
        }
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
        _statusMessage = 'Error saving backup: $e';
      });
    }
  }

  Future<void> _saveToDownloadsFolder() async {
    setState(() {
      _isSaving = true;
      _statusMessage = 'Saving backup to Downloads folder...';
    });

    try {
      final result = await _localBackupService.saveToDownloadsFolder();
      setState(() {
        _isSaving = false;
        if (result.success) {
          _statusMessage = 'Backup saved to Downloads folder';
          _loadAvailableBackups(); // Refresh the list
        } else {
          _statusMessage = 'Backup failed: ${result.message}';
        }
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
        _statusMessage = 'Error saving backup: $e';
      });
    }
  }

  Future<void> _restoreFromSelectedFile() async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Backup File'),
        content: const Text(
          'This will open the file picker to select a backup file. '
          'You can cancel at any time using the back button or cancel option.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Select File'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      setState(() {
        _statusMessage = 'File selection cancelled';
      });
      return;
    }

    setState(() {
      _isRestoring = true;
      _statusMessage = 'Selecting file and restoring backup...';
    });

    try {
      final result = await _localBackupService.restoreFromLocalFile();
      
      if (result.success) {
        // Refresh app state to show restored data
        if (mounted) {
          final app = Provider.of<AppState>(context, listen: false);
          // Reload data from storage
          await app.load();
        }
        
        setState(() {
          _isRestoring = false;
          _statusMessage = 'Backup restored successfully!';
        });
      } else {
        setState(() {
          _isRestoring = false;
          // Check if it was a cancellation
          if (result.message == 'File selection cancelled by user') {
            _statusMessage = 'File selection cancelled';
          } else {
            _statusMessage = 'Restore failed: ${result.message}';
          }
        });
      }
    } catch (e) {
      setState(() {
        _isRestoring = false;
        _statusMessage = 'Error restoring backup: $e';
      });
    }
  }

  Future<void> _restoreFromBackup(BackupFileInfo backup) async {
    setState(() {
      _isRestoring = true;
      _statusMessage = 'Restoring from ${backup.fileName}...';
    });

    try {
      // Use BackupManager directly for file restore
      final result = await BackupManager.restoreFromBackup(backup.filePath);
      
      if (result.success) {
        // Refresh app state to show restored data
        if (mounted) {
          final app = Provider.of<AppState>(context, listen: false);
          // Reload data from storage
          await app.load();
        }
        
        setState(() {
          _isRestoring = false;
          _statusMessage = 'Backup restored successfully from ${backup.fileName}!';
        });
      } else {
        setState(() {
          _isRestoring = false;
          _statusMessage = 'Restore failed: ${result.message}';
        });
      }
    } catch (e) {
      setState(() {
        _isRestoring = false;
        _statusMessage = 'Error restoring backup: $e';
      });
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Backup & Restore'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: WallpaperBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isSaving || _isRestoring ? Icons.sync : Icons.info,
                            color: _isSaving || _isRestoring ? Colors.orange : Colors.blue,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Status',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _statusMessage,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Save Backup Section
              Text(
                'Save Backup',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Save to Selected Folder
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveToSelectedFolder,
                  icon: _isSaving 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.folder_open),
                  label: Text(_isSaving ? 'Saving...' : 'Save to Selected Folder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Save to Downloads Folder
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveToDownloadsFolder,
                  icon: _isSaving 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                  label: Text(_isSaving ? 'Saving...' : 'Save to Downloads Folder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Restore Backup Section
              Text(
                'Restore Backup',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Restore from Selected File
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isRestoring ? null : _restoreFromSelectedFile,
                  icon: _isRestoring 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.file_open),
                  label: Text(_isRestoring ? 'Restoring...' : 'Restore from Selected File'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Available Backups Section
              Row(
                children: [
                  Text(
                    'Available Backups',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _loadAvailableBackups,
                    icon: _isLoadingBackups 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                    tooltip: 'Refresh backup list',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_availableBackups.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _isLoadingBackups 
                        ? 'Loading backups...'
                        : 'No backup files found in Downloads folder',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                )
              else
                ..._availableBackups.map((backup) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.backup),
                    title: Text(backup.fileName),
                    subtitle: Text(
                      '${_formatFileSize(backup.fileSize)} • ${_formatDate(backup.modifiedDate)}',
                    ),
                    trailing: ElevatedButton(
                      onPressed: _isRestoring ? null : () => _restoreFromBackup(backup),
                      child: _isRestoring 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Restore'),
                    ),
                  ),
                )),

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
                        'How to Use',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Save Backup:\n'
                        '• "Save to Selected Folder" - Choose any folder on your device\n'
                        '• "Save to Downloads Folder" - Automatically saves to Downloads/FoodRunsCounter/Backups\n\n'
                        'Restore Backup:\n'
                        '• "Restore from Selected File" - Choose any backup file from your device\n'
                        '• Click "Restore" on any file in the Available Backups list\n\n'
                        'The backup includes all your restaurant data:\n'
                        '• Server information and run counts\n'
                        '• Shift history and performance data\n'
                        '• NPS feedback and monthly reports\n'
                        '• Station assignments and analytics\n'
                        '• Gamification data and achievements\n'
                        '• Complete SQLite database',
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
