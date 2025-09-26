import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import '../utils/log.dart';
import '../utils/backup_manager.dart';
import '../services/sqlite_backup_service.dart';

/// Local Backup Service
/// 
/// Provides manual save/restore functionality for local device storage.
/// Allows users to save backups to selected folders and restore from selected files.
class LocalBackupService {
  static LocalBackupService? _instance;
  static LocalBackupService get instance => _instance ??= LocalBackupService._();
  
  LocalBackupService._();

  /// Save backup to a user-selected folder
  Future<BackupResult> saveToLocalFolder({String? customName}) async {
    try {
      d('[LocalBackupService] Starting local folder save...');
      
      // Let user select a directory
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) {
        return BackupResult(
          success: false,
          message: 'No folder selected',
        );
      }
      
      // Create comprehensive backup
      final timestamp = DateTime.now();
      final fileName = customName ?? 
          'restaurant_backup_${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}-${timestamp.minute.toString().padLeft(2, '0')}.json';
      
      // Create backup using existing BackupManager
      final backupResult = await BackupManager.createBackup(customName: fileName);
      
      if (!backupResult.success) {
        return backupResult;
      }
      
      // Copy backup file to selected directory
      final sourceFile = File(backupResult.filePath!);
      final targetPath = path.join(selectedDirectory, fileName);
      final targetFile = File(targetPath);
      
      await sourceFile.copy(targetFile.path);
      
      // Create README file in the folder
      await _createLocalBackupReadme(selectedDirectory, fileName);
      
      d('[LocalBackupService] Local backup saved to: $targetPath');
      
      return BackupResult(
        success: true,
        filePath: targetPath,
        fileName: fileName,
        fileSize: await targetFile.length(),
        message: 'Backup saved to: $selectedDirectory',
      );
      
    } catch (e) {
      d('[LocalBackupService] Error saving to local folder: $e');
      return BackupResult(
        success: false,
        message: 'Failed to save backup: $e',
      );
    }
  }

  /// Restore backup from a user-selected file
  Future<RestoreResult> restoreFromLocalFile() async {
    try {
      d('[LocalBackupService] Starting local file restore...');
      
      // Let user select a backup file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );
      
      if (result == null || result.files.isEmpty) {
        return RestoreResult(
          success: false,
          message: 'File selection cancelled by user',
        );
      }
      
      final selectedFile = result.files.first;
      final filePath = selectedFile.path;
      
      if (filePath == null) {
        return RestoreResult(
          success: false,
          message: 'Invalid file path',
        );
      }
      
      d('[LocalBackupService] Restoring from: $filePath');
      
      // Use existing restore functionality
      final restoreResult = await BackupManager.restoreFromBackup(filePath);
      
      if (restoreResult.success) {
        d('[LocalBackupService] Local restore completed successfully');
      } else {
        d('[LocalBackupService] Local restore failed: ${restoreResult.message}');
      }
      
      return restoreResult;
      
    } catch (e) {
      d('[LocalBackupService] Error restoring from local file: $e');
      return RestoreResult(
        success: false,
        message: 'Failed to restore backup: $e',
      );
    }
  }

  /// Save backup to Downloads folder (automatic location)
  Future<BackupResult> saveToDownloadsFolder({String? customName}) async {
    try {
      d('[LocalBackupService] Starting Downloads folder save...');
      
      // Get Downloads directory
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) {
        return BackupResult(
          success: false,
          message: 'Downloads directory not available',
        );
      }
      
      // Create FoodRunsCounter subfolder
      final backupDir = Directory(path.join(downloadsDir.path, 'FoodRunsCounter', 'Backups'));
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      
      // Create comprehensive backup
      final timestamp = DateTime.now();
      final fileName = customName ?? 
          'restaurant_backup_${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}-${timestamp.minute.toString().padLeft(2, '0')}.json';
      
      // Create backup using existing BackupManager
      final backupResult = await BackupManager.createBackup(customName: fileName);
      
      if (!backupResult.success) {
        return backupResult;
      }
      
      // Copy backup file to Downloads folder
      final sourceFile = File(backupResult.filePath!);
      final targetPath = path.join(backupDir.path, fileName);
      final targetFile = File(targetPath);
      
      await sourceFile.copy(targetFile.path);
      
      // Create README file
      await _createLocalBackupReadme(backupDir.path, fileName);
      
      d('[LocalBackupService] Downloads backup saved to: $targetPath');
      
      return BackupResult(
        success: true,
        filePath: targetPath,
        fileName: fileName,
        fileSize: await targetFile.length(),
        message: 'Backup saved to Downloads folder',
      );
      
    } catch (e) {
      d('[LocalBackupService] Error saving to Downloads folder: $e');
      return BackupResult(
        success: false,
        message: 'Failed to save backup: $e',
      );
    }
  }

  /// Get list of available backup files in Downloads folder
  Future<List<BackupFileInfo>> getAvailableBackups() async {
    try {
      d('[LocalBackupService] Getting available backups...');
      
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) {
        return [];
      }
      
      final backupDir = Directory(path.join(downloadsDir.path, 'FoodRunsCounter', 'Backups'));
      if (!await backupDir.exists()) {
        return [];
      }
      
      final files = await backupDir.list().toList();
      final backupFiles = <BackupFileInfo>[];
      
      for (final file in files) {
        if (file is File && file.path.endsWith('.json')) {
          final stat = await file.stat();
          backupFiles.add(BackupFileInfo(
            fileName: path.basename(file.path),
            filePath: file.path,
            fileSize: stat.size,
            modifiedDate: stat.modified,
          ));
        }
      }
      
      // Sort by modification date (newest first)
      backupFiles.sort((a, b) => b.modifiedDate.compareTo(a.modifiedDate));
      
      d('[LocalBackupService] Found ${backupFiles.length} backup files');
      return backupFiles;
      
    } catch (e) {
      d('[LocalBackupService] Error getting available backups: $e');
      return [];
    }
  }

  /// Create README file for local backup
  Future<void> _createLocalBackupReadme(String directory, String backupFileName) async {
    try {
      final readmeContent = '''
# Food Runs Counter - Restaurant Data Backup

## Backup Information
- **File**: $backupFileName
- **Created**: ${DateTime.now().toString()}
- **App Version**: 3.6.0+360
- **Backup Type**: Comprehensive Restaurant Data

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

## How to Restore

### On Your Development Computer (Emulator)
1. Copy this backup file to your computer
2. Open the Food Runs Counter app in the emulator
3. Go to Settings → Admin → Data Backup & Restore
4. Use "Import Backup" to select this file
5. Confirm restoration

### On Your Restaurant Tablet
1. Copy this backup file to your tablet
2. Open the Food Runs Counter app
3. Go to Settings → Admin → Data Backup & Restore
4. Use "Import Backup" to select this file
5. Confirm restoration

## File Structure
- `$backupFileName` - Main backup file (JSON format)
- `README.txt` - This instruction file

## Support
If you need help restoring this data, contact your system administrator.

---
Generated by Food Runs Counter v3.6.0+360
''';

      final readmeFile = File(path.join(directory, 'README.txt'));
      await readmeFile.writeAsString(readmeContent);
      
      d('[LocalBackupService] Created README file: ${readmeFile.path}');
      
    } catch (e) {
      d('[LocalBackupService] Error creating README file: $e');
    }
  }

  /// Validate backup file before restore
  Future<BackupValidationResult> validateBackupFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return BackupValidationResult(
          isValid: false,
          error: 'File does not exist',
        );
      }
      
      final fileSize = await file.length();
      if (fileSize == 0) {
        return BackupValidationResult(
          isValid: false,
          error: 'File is empty',
        );
      }
      
      // Try to parse JSON
      try {
        final jsonString = await file.readAsString();
        final backupData = jsonDecode(jsonString) as Map<String, dynamic>;
        
        // Check for required fields
        if (!backupData.containsKey('metadata')) {
          return BackupValidationResult(
            isValid: false,
            error: 'Invalid backup format: missing metadata',
          );
        }
        
        final metadata = backupData['metadata'] as Map<String, dynamic>;
        final backupType = metadata['backup_type'] as String?;
        
        if (backupType == null) {
          return BackupValidationResult(
            isValid: false,
            error: 'Invalid backup format: missing backup_type',
          );
        }
        
        return BackupValidationResult(
          isValid: true,
          backupType: backupType,
          version: metadata['version'] as String?,
          timestamp: metadata['timestamp'] as String?,
          includesSQLite: metadata['includes_sqlite'] as bool? ?? false,
        );
        
      } catch (e) {
        return BackupValidationResult(
          isValid: false,
          error: 'Invalid JSON format: $e',
        );
      }
      
    } catch (e) {
      return BackupValidationResult(
        isValid: false,
        error: 'Error validating file: $e',
      );
    }
  }
}

/// Information about a backup file
class BackupFileInfo {
  final String fileName;
  final String filePath;
  final int fileSize;
  final DateTime modifiedDate;

  BackupFileInfo({
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.modifiedDate,
  });
}

/// Result of backup file validation
class BackupValidationResult {
  final bool isValid;
  final String? error;
  final String? backupType;
  final String? version;
  final String? timestamp;
  final bool includesSQLite;

  BackupValidationResult({
    required this.isValid,
    this.error,
    this.backupType,
    this.version,
    this.timestamp,
    this.includesSQLite = false,
  });
}
