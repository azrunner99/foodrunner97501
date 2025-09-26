import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../utils/log.dart';
import '../utils/backup_manager.dart';
import 'file_service.dart';
import 'platform_service.dart';

/// USB-C Flash Drive Backup Service
/// 
/// Provides automatic backup functionality when a USB-C flash drive is connected.
/// Leverages existing backup infrastructure for seamless data transfer.
class USBBackupService {
  static USBBackupService? _instance;
  static USBBackupService get instance => _instance ??= USBBackupService._();
  
  USBBackupService._();

  Timer? _monitoringTimer;
  bool _isMonitoring = false;
  String? _lastDetectedUSBPath;
  final List<String> _usbPaths = [];

  /// Start monitoring for USB-C flash drives
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    
    d('[USBBackupService] Starting USB drive monitoring...');
    _isMonitoring = true;
    
    // Check every 2 seconds for USB drives
    _monitoringTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkForUSBDrives();
    });
    
    // Initial check
    await _checkForUSBDrives();
  }

  /// Stop monitoring for USB drives
  void stopMonitoring() {
    d('[USBBackupService] Stopping USB drive monitoring...');
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _isMonitoring = false;
  }

  /// Check for connected USB drives and trigger backup if new drive detected
  Future<void> _checkForUSBDrives() async {
    try {
      final usbPaths = await _detectUSBDrives();
      
      // Check if we have a new USB drive
      if (usbPaths.isNotEmpty && !_usbPaths.contains(usbPaths.first)) {
        d('[USBBackupService] New USB drive detected: ${usbPaths.first}');
        _usbPaths.clear();
        _usbPaths.addAll(usbPaths);
        
        // Trigger automatic backup
        await _performAutomaticBackup(usbPaths.first);
      } else if (usbPaths.isEmpty && _usbPaths.isNotEmpty) {
        d('[USBBackupService] USB drive disconnected');
        _usbPaths.clear();
      }
    } catch (e) {
      d('[USBBackupService] Error checking for USB drives: $e');
    }
  }

  /// Detect USB drives on the current platform
  Future<List<String>> _detectUSBDrives() async {
    final usbPaths = <String>[];
    
    try {
      if (PlatformService.isAndroid) {
        // Android: Check common USB mount points
        final commonPaths = [
          '/storage/usbotg',
          '/storage/usbotg1',
          '/storage/usbotg2',
          '/mnt/usb',
          '/mnt/usbotg',
          '/media/usb',
          '/media/usbotg',
        ];
        
        for (final usbPath in commonPaths) {
          final dir = Directory(usbPath);
          if (await dir.exists()) {
            // Check if it's actually a USB drive (has files or is writable)
            try {
              final testFile = File('${dir.path}/.test_write');
              await testFile.writeAsString('test');
              await testFile.delete();
              usbPaths.add(usbPath);
              d('[USBBackupService] Found USB drive at: $usbPath');
            } catch (e) {
              // Not writable, skip
            }
          }
        }
        
        // Also check external storage directories for USB drives
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final parentDir = Directory(path.dirname(externalDir.path));
          final subdirs = await parentDir.list().toList();
          
          for (final subdir in subdirs) {
            if (subdir is Directory) {
              final dirName = path.basename(subdir.path).toLowerCase();
              if (dirName.contains('usb') || dirName.contains('otg') || dirName.contains('flash')) {
                try {
                  final testFile = File('${subdir.path}/.test_write');
                  await testFile.writeAsString('test');
                  await testFile.delete();
                  usbPaths.add(subdir.path);
                  d('[USBBackupService] Found USB drive at: ${subdir.path}');
                } catch (e) {
                  // Not writable, skip
                }
              }
            }
          }
        }
        
      } else if (PlatformService.isWindows) {
        // Windows: Check for removable drives
        final drives = await _getWindowsRemovableDrives();
        usbPaths.addAll(drives);
      }
      
    } catch (e) {
      d('[USBBackupService] Error detecting USB drives: $e');
    }
    
    return usbPaths;
  }

  /// Get removable drives on Windows
  Future<List<String>> _getWindowsRemovableDrives() async {
    final drives = <String>[];
    
    try {
      // Check common drive letters for removable media
      for (int i = 65; i <= 90; i++) { // A-Z
        final driveLetter = String.fromCharCode(i);
        final drivePath = '$driveLetter:\\';
        final drive = Directory(drivePath);
        
        if (await drive.exists()) {
          try {
            // Try to write a test file to see if it's writable
            final testFile = File('$drivePath.test_write');
            await testFile.writeAsString('test');
            await testFile.delete();
            
            // Check if it's removable (not system drive)
            if (driveLetter != 'C' && driveLetter != 'D') {
              drives.add(drivePath);
              d('[USBBackupService] Found removable drive: $drivePath');
            }
          } catch (e) {
            // Not writable or not removable, skip
          }
        }
      }
    } catch (e) {
      d('[USBBackupService] Error checking Windows drives: $e');
    }
    
    return drives;
  }

  /// Perform automatic backup to USB drive
  Future<void> _performAutomaticBackup(String usbPath) async {
    try {
      d('[USBBackupService] Starting automatic backup to USB drive: $usbPath');
      
      // Create backup directory on USB drive
      final usbBackupDir = Directory(path.join(usbPath, 'FoodRunsCounter', 'Backups'));
      if (!await usbBackupDir.exists()) {
        await usbBackupDir.create(recursive: true);
      }
      
      // Create timestamped backup
      final timestamp = DateTime.now();
      final backupName = 'restaurant_data_${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}-${timestamp.minute.toString().padLeft(2, '0')}';
      
      // Create backup using existing BackupManager (includes Hive data)
      final backupResult = await BackupManager.createBackup(customName: backupName);
      
      if (backupResult.success) {
        // Copy backup file to USB drive
        final sourceFile = File(backupResult.filePath!);
        final usbBackupFile = File(path.join(usbBackupDir.path, '${backupName}.json'));
        
        await sourceFile.copy(usbBackupFile.path);
        
        d('[USBBackupService] Backup completed successfully to USB drive');
        d('[USBBackupService] Backup file: ${usbBackupFile.path}');
        
        // Create a README file with instructions
        await _createUSBReadme(usbBackupDir.path);
        
      } else {
        d('[USBBackupService] Backup creation failed: ${backupResult.message}');
      }
      
    } catch (e) {
      d('[USBBackupService] Error performing automatic backup: $e');
    }
  }

  /// Create a README file with instructions for using the backup
  Future<void> _createUSBReadme(String usbBackupDir) async {
    try {
      final readmeContent = '''
# Food Runs Counter - Restaurant Data Backup

## Backup Information
- **Created**: ${DateTime.now().toString()}
- **App Version**: 3.6.0+360
- **Backup Type**: Full Restaurant Data

## What's Included
- **Complete Server Data**: Names, IDs, team colors, hire dates, active status
- **All Food Run Counts**: Totals, shift records, performance metrics
- **NPS System Data**: Feedback records, monthly reports, calculation logs (SQLite)
- **Station/Section Data**: Assignments, performance analytics
- **Gamification Data**: XP, badges, achievements, leaderboards
- **App Settings**: Preferences, wallpapers, admin settings
- **User Preferences**: All customizations and configurations
- **Admin Preferences**: Station types, section assignments, PIN settings
- **Reporting Data**: All generated reports and analytics
- **Avatar Photos**: Server profile pictures (base64 encoded)
- **SQLite Database**: Complete NPS database with all tables and relationships

## How to Restore on Your Computer

### Option 1: Using the Emulator
1. Copy the backup file to your computer
2. Open the Food Runs Counter app in the emulator
3. Go to Settings → Admin → Data Backup & Restore
4. Use "Import Backup" to select the file
5. Confirm restoration

### Option 2: Manual Data Entry
1. Open the backup file in a text editor
2. Copy the data you need
3. Manually enter it into the app

## File Structure
- `restaurant_data_YYYY-MM-DD_HH-MM.json` - Main backup file
- `README.txt` - This instruction file

## Support
If you need help restoring this data, contact your system administrator.

---
Generated by Food Runs Counter v3.6.0+360
''';

      final readmeFile = File(path.join(usbBackupDir, 'README.txt'));
      await readmeFile.writeAsString(readmeContent);
      
      d('[USBBackupService] Created README file: ${readmeFile.path}');
      
    } catch (e) {
      d('[USBBackupService] Error creating README file: $e');
    }
  }

  /// Manually trigger backup to USB drive
  Future<bool> manualBackupToUSB() async {
    try {
      final usbPaths = await _detectUSBDrives();
      
      if (usbPaths.isEmpty) {
        d('[USBBackupService] No USB drives detected for manual backup');
        return false;
      }
      
      await _performAutomaticBackup(usbPaths.first);
      return true;
      
    } catch (e) {
      d('[USBBackupService] Error in manual backup: $e');
      return false;
    }
  }

  /// Check if USB drives are currently connected
  Future<bool> hasUSBDrive() async {
    final usbPaths = await _detectUSBDrives();
    return usbPaths.isNotEmpty;
  }

  /// Get list of connected USB drives
  Future<List<String>> getConnectedUSBDrives() async {
    return await _detectUSBDrives();
  }

  /// Restore data from USB drive
  Future<bool> restoreFromUSB() async {
    try {
      final usbPaths = await _detectUSBDrives();
      
      if (usbPaths.isEmpty) {
        d('[USBBackupService] No USB drives found for restore');
        return false;
      }
      
      final usbBackupDir = Directory(path.join(usbPaths.first, 'FoodRunsCounter', 'Backups'));
      if (!await usbBackupDir.exists()) {
        d('[USBBackupService] No backup directory found on USB drive');
        return false;
      }
      
      // Find the most recent backup file
      final backupFiles = await usbBackupDir.list()
          .where((file) => file is File && file.path.endsWith('.json'))
          .cast<File>()
          .toList();
      
      if (backupFiles.isEmpty) {
        d('[USBBackupService] No backup files found on USB drive');
        return false;
      }
      
      // Sort by modification time (newest first)
      backupFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      final latestBackup = backupFiles.first;
      
      d('[USBBackupService] Restoring from USB backup: ${latestBackup.path}');
      
      // Use existing restore functionality
      final restoreResult = await BackupManager.restoreFromBackup(latestBackup.path);
      
      return restoreResult.success;
      
    } catch (e) {
      d('[USBBackupService] Error restoring from USB: $e');
      return false;
    }
  }
}
