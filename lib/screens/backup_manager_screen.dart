import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
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

  Widget _buildInfoRow(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue[600], size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800],
                  fontSize: 12,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
            const Text(
                'This will restore all app data from the selected backup.'),
            const SizedBox(height: 16),
            const Text(
                '⚠️ WARNING: This will replace ALL current data including:'),
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
          _showSnackBar(
              '${result.message}\n\nPlease restart the app for all changes to take effect.');
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

  Future<void> _shareBackup(BackupInfo backup) async {
    try {
      final result = await BackupManager.exportBackup(backup.filePath);
      if (result.success) {
        _showSnackBar(result.message);
      } else {
        _showSnackBar(result.message, isError: true);
      }
    } catch (e) {
      _showSnackBar('Failed to share backup: $e', isError: true);
    }
  }

  Future<void> _saveBackupToDevice(BackupInfo backup) async {
    try {
      final result = await BackupManager.saveBackupToDevice(backup.filePath);
      if (result.success) {
        _showSnackBar(result.message);
      } else {
        _showSnackBar(result.message, isError: true);
      }
    } catch (e) {
      _showSnackBar('Failed to save backup: $e', isError: true);
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

  Future<void> _showRestoreOptions() async {
    // Automatically search for backup files on device
    await _searchAndShowBackupFiles();
  }

  Future<void> _searchAndShowBackupFiles() async {
    setState(() => _isCreatingBackup = true); // Use this as loading state

    try {
      // Search for backup files in common locations
      final foundBackups = await _findBackupFilesOnDevice();

      setState(() => _isCreatingBackup = false);

      if (foundBackups.isEmpty) {
        _showSnackBar(
            'No backup files found on device. Use file picker to manually select a backup file.',
            isError: true);
        // Fallback to manual file picker
        await _openManualFilePicker();
        return;
      }

      // Show found backup files for selection
      final selectedFile = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Found Backup Files'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: Column(
              children: [
                Text(
                  'Found ${foundBackups.length} backup file(s) on your device:',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: foundBackups.length,
                    itemBuilder: (context, index) {
                      final backup = foundBackups[index];
                      final fileName = backup['name'] as String;
                      final filePath = backup['path'] as String;
                      final fileSize = backup['size'] as String;
                      final isZip = fileName.endsWith('.zip');

                      return ListTile(
                        leading: Icon(
                          isZip ? Icons.archive : Icons.description,
                          color: isZip ? Colors.purple : Colors.blue,
                        ),
                        title: Text(fileName),
                        subtitle: Text('$fileSize • ${backup['location']}'),
                        onTap: () => Navigator.pop(context, filePath),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _openManualFilePicker();
              },
              child: const Text('Browse Manually'),
            ),
          ],
        ),
      );

      if (selectedFile != null) {
        await _confirmAndRestore(selectedFile);
      }
    } catch (e) {
      setState(() => _isCreatingBackup = false);
      _showSnackBar('Error searching for backup files: $e', isError: true);
      // Fallback to manual file picker
      await _openManualFilePicker();
    }
  }

  Future<List<Map<String, dynamic>>> _findBackupFilesOnDevice() async {
    final foundFiles = <Map<String, dynamic>>[];

    try {
      // Get common directories to search
      final directories = await _getSearchDirectories();

      for (final directory in directories) {
        if (await directory.exists()) {
          await for (final entity
              in directory.list(recursive: true, followLinks: false)) {
            if (entity is File) {
              final fileName = entity.path.split('/').last.split('\\').last;

              // Check if it's a backup file
              if (_isBackupFile(fileName)) {
                try {
                  final stat = await entity.stat();
                  final sizeStr = _formatFileSize(stat.size);

                  foundFiles.add({
                    'name': fileName,
                    'path': entity.path,
                    'size': sizeStr,
                    'location': _getLocationName(directory.path),
                    'modified': stat.modified,
                  });
                } catch (e) {
                  // Skip files that can't be accessed
                  continue;
                }
              }
            }
          }
        }
      }

      // Sort by modification date (newest first)
      foundFiles.sort((a, b) =>
          (b['modified'] as DateTime).compareTo(a['modified'] as DateTime));

      return foundFiles;
    } catch (e) {
      print('[BackupSearch] Error searching for backup files: $e');
      return foundFiles;
    }
  }

  Future<List<Directory>> _getSearchDirectories() async {
    final directories = <Directory>[];

    try {
      // Documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      directories.add(documentsDir);

      // Download folder (common location for exported files)
      final downloadPaths = [
        '/storage/emulated/0/Download',
        '/sdcard/Download',
        Platform.isAndroid ? '/storage/emulated/0/Downloads' : null,
      ].where((path) => path != null).cast<String>();

      for (final path in downloadPaths) {
        final dir = Directory(path);
        if (await dir.exists()) {
          directories.add(dir);
        }
      }

      // External storage (if available)
      try {
        if (Platform.isAndroid) {
          final externalDir = Directory('/storage/emulated/0/');
          if (await externalDir.exists()) {
            directories.add(externalDir);
          }
        }
      } catch (e) {
        // External storage not accessible
      }
    } catch (e) {
      print('[BackupSearch] Error getting search directories: $e');
    }

    return directories;
  }

  bool _isBackupFile(String fileName) {
    final lowerName = fileName.toLowerCase();
    return (lowerName.endsWith('.json') || lowerName.endsWith('.zip')) &&
        (lowerName.contains('backup') ||
            lowerName.contains('food_runs') ||
            lowerName.contains('auto_backup') ||
            lowerName.startsWith('food_runs_backup_') ||
            lowerName.startsWith('auto_backup_'));
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String _getLocationName(String path) {
    if (path.contains('Download')) return 'Downloads';
    if (path.contains('Documents')) return 'Documents';
    if (path.contains('/storage/emulated/0/')) return 'Device Storage';
    return 'Device';
  }

  Future<void> _openManualFilePicker() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'zip'],
        dialogTitle: 'Select Backup File to Restore',
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        await _confirmAndRestore(filePath);
      }
    } catch (e) {
      _showSnackBar('Failed to select backup file: $e', isError: true);
    }
  }

  Future<void> _confirmAndRestore(String filePath) async {
    final fileName = filePath.split('/').last.split('\\').last;

    // Show confirmation dialog with file info
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Restore'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selected file: $fileName'),
            const SizedBox(height: 16),
            const Text(
                '⚠️ WARNING: This will replace ALL current data including:'),
            const SizedBox(height: 8),
            const Text('• All servers and their data'),
            const Text('• All shifts and history'),
            const Text('• All achievements and profiles'),
            const Text('• All settings and preferences'),
            const Text('• All custom avatar photos'),
            const SizedBox(height: 16),
            const Text('This action cannot be undone. Are you sure?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Restore Data'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _performRestore(filePath);
    }
  }

  Future<void> _performRestore(String filePath) async {
    setState(() => _isRestoring = true);
    try {
      final result = await BackupManager.restoreFromBackup(filePath);
      if (result.success) {
        _showSnackBar('Data restored successfully! Please restart the app.');
        await _loadBackups();
      } else {
        _showSnackBar(result.message, isError: true);
      }
    } catch (e) {
      _showSnackBar('Failed to restore backup: $e', isError: true);
    } finally {
      setState(() => _isRestoring = false);
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
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Storage location info
                  if (_locationInfo != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 6),
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
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
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
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        // Backup System Description
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: Colors.blue[700], size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'How Backup System Works',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(Icons.schedule, 'Automatic Timing',
                                  'Every night during closing hours'),
                              const SizedBox(height: 4),
                              _buildInfoRow(
                                  Icons.cloud_upload,
                                  'Server Backups',
                                  'JSON files - 30-day rolling retention'),
                              const SizedBox(height: 4),
                              _buildInfoRow(
                                  Icons.phone_android,
                                  'Device Backups',
                                  'ZIP files with photos - daily to device'),
                              const SizedBox(height: 4),
                              _buildInfoRow(
                                  Icons.photo_library,
                                  'Complete Protection',
                                  'All data, settings, and photos included'),
                              const SizedBox(height: 4),
                              _buildInfoRow(
                                  Icons.auto_delete,
                                  'Rolling Retention',
                                  'Old backups auto-deleted after 30 days'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
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
                                  Icon(Icons.schedule,
                                      color: Colors.green[600], size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Automatic Daily Backups',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[800],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Auto-backup during closing hours with 30-day rolling retention.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isCreatingBackup
                                      ? null
                                      : _triggerAutoBackup,
                                  icon: const Icon(Icons.play_arrow, size: 16),
                                  label: const Text('Trigger Auto Backup Now'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[600],
                                    foregroundColor: Colors.white,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
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
                                    Icon(Icons.backup_outlined,
                                        size: 64, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text(
                                      'No backups found',
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.grey),
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
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final backup = _backups[index];
                                  return Card(
                                    elevation: 2,
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: backup.isAutomatic
                                            ? Colors.green[100]
                                            : Colors.blue[100],
                                        child: Icon(
                                          backup.isAutomatic
                                              ? Icons.schedule
                                              : Icons.backup,
                                          color: backup.isAutomatic
                                              ? Colors.green
                                              : Colors.blue,
                                        ),
                                      ),
                                      title: Text(
                                        backup.displayName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              'Created: ${backup.formattedDate}'),
                                          Text('Size: ${backup.formattedSize}'),
                                          if (backup.metadata != null)
                                            Text(
                                                'Version: ${backup.metadata!['version'] ?? 'Unknown'}'),
                                        ],
                                      ),
                                      isThreeLine: true,
                                      trailing: PopupMenuButton<String>(
                                        onSelected: (value) {
                                          switch (value) {
                                            case 'restore':
                                              _restoreBackup(backup);
                                              break;
                                            case 'share':
                                              _shareBackup(backup);
                                              break;
                                            case 'save':
                                              _saveBackupToDevice(backup);
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
                                                Icon(Icons.restore,
                                                    color: Colors.orange),
                                                SizedBox(width: 8),
                                                Text('Restore'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'share',
                                            child: Row(
                                              children: [
                                                Icon(Icons.share,
                                                    color: Colors.blue),
                                                SizedBox(width: 8),
                                                Text('Share'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'save',
                                            child: Row(
                                              children: [
                                                Icon(Icons.download,
                                                    color: Colors.green),
                                                SizedBox(width: 8),
                                                Text('Save to Device'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete,
                                                    color: Colors.red),
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
                  // Restore button section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Column(
                      children: [
                        const Divider(),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isCreatingBackup || _isRestoring
                                ? null
                                : _showRestoreOptions,
                            icon: const Icon(Icons.search, size: 16),
                            label: Text(_isCreatingBackup
                                ? 'Searching...'
                                : 'Find & Restore Backups'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Automatically searches device for backup files',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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
