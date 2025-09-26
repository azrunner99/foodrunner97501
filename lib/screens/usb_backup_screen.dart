import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../services/usb_backup_service.dart';
import '../utils/log.dart';
import '../widgets/wallpaper_background.dart';

/// USB Backup Management Screen
/// 
/// Provides easy access to USB-C flash drive backup functionality
/// with automatic detection and one-click backup/restore.
class USBBackupScreen extends StatefulWidget {
  const USBBackupScreen({super.key});

  @override
  State<USBBackupScreen> createState() => _USBBackupScreenState();
}

class _USBBackupScreenState extends State<USBBackupScreen> {
  final USBBackupService _usbService = USBBackupService.instance;
  bool _isMonitoring = false;
  bool _isBackingUp = false;
  bool _isRestoring = false;
  List<String> _connectedDrives = [];
  String _statusMessage = 'Checking for USB drives...';

  @override
  void initState() {
    super.initState();
    _checkUSBStatus();
  }

  @override
  void dispose() {
    _usbService.stopMonitoring();
    super.dispose();
  }

  Future<void> _checkUSBStatus() async {
    setState(() {
      _statusMessage = 'Checking for USB drives...';
    });

    try {
      final drives = await _usbService.getConnectedUSBDrives();
      setState(() {
        _connectedDrives = drives;
        if (drives.isNotEmpty) {
          _statusMessage = 'USB drive detected: ${drives.first}';
        } else {
          _statusMessage = 'No USB drives connected';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error checking USB drives: $e';
      });
    }
  }

  Future<void> _startMonitoring() async {
    await _usbService.startMonitoring();
    setState(() {
      _isMonitoring = true;
      _statusMessage = 'Monitoring for USB drives...';
    });
  }

  void _stopMonitoring() {
    _usbService.stopMonitoring();
    setState(() {
      _isMonitoring = false;
      _statusMessage = 'Monitoring stopped';
    });
  }

  Future<void> _performBackup() async {
    setState(() {
      _isBackingUp = true;
      _statusMessage = 'Creating backup...';
    });

    try {
      final success = await _usbService.manualBackupToUSB();
      setState(() {
        _isBackingUp = false;
        if (success) {
          _statusMessage = 'Backup completed successfully!';
        } else {
          _statusMessage = 'Backup failed - no USB drive detected';
        }
      });
    } catch (e) {
      setState(() {
        _isBackingUp = false;
        _statusMessage = 'Backup failed: $e';
      });
    }
  }

  Future<void> _performRestore() async {
    setState(() {
      _isRestoring = true;
      _statusMessage = 'Restoring from USB...';
    });

    try {
      final success = await _usbService.restoreFromUSB();
      setState(() {
        _isRestoring = false;
        if (success) {
          _statusMessage = 'Restore completed successfully!';
          // Refresh app state to show restored data
          if (mounted) {
            // Force rebuild of the screen to show restored data
            setState(() {});
          }
        } else {
          _statusMessage = 'Restore failed - no backup found on USB drive';
        }
      });
    } catch (e) {
      setState(() {
        _isRestoring = false;
        _statusMessage = 'Restore failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('USB-C Flash Drive Backup'),
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
                            _connectedDrives.isNotEmpty ? Icons.usb : Icons.usb_off,
                            color: _connectedDrives.isNotEmpty ? Colors.green : Colors.grey,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'USB Drive Status',
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
                      if (_connectedDrives.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Connected to: ${_connectedDrives.first}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Manual Backup Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isBackingUp ? null : _performBackup,
                  icon: _isBackingUp 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.backup),
                  label: Text(_isBackingUp ? 'Creating Backup...' : 'Backup to USB Drive'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Restore Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isRestoring ? null : _performRestore,
                  icon: _isRestoring 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.restore),
                  label: Text(_isRestoring ? 'Restoring...' : 'Restore from USB Drive'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Auto-Monitoring Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Automatic Monitoring',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enable automatic backup when USB drive is connected',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Switch(
                            value: _isMonitoring,
                            onChanged: (value) {
                              if (value) {
                                _startMonitoring();
                              } else {
                                _stopMonitoring();
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isMonitoring ? 'Monitoring Active' : 'Monitoring Inactive',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _isMonitoring ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

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
                        '1. Connect a USB-C flash drive to your tablet\n'
                        '2. Tap "Backup to USB Drive" to create a backup\n'
                        '3. Take the flash drive home with you\n'
                        '4. On your computer, copy the backup file to your emulator\n'
                        '5. Use "Restore from USB Drive" to load the data\n\n'
                        'The backup includes all your restaurant data:\n'
                        '• Server information and run counts\n'
                        '• Shift history and performance data\n'
                        '• NPS feedback and monthly reports\n'
                        '• Station assignments and analytics\n'
                        '• Gamification data and achievements',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Refresh Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _checkUSBStatus,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh USB Status'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
