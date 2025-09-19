import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import '../storage.dart';
import '../models.dart'; // For WeeklyHours

class BackupManager {
  /// Creates a comprehensive backup of all app data
  static Future<BackupResult> createBackup({String? customName}) async {
    try {
      final timestamp = DateTime.now();
      final fileName = customName ??
          'food_runs_backup_${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}-${timestamp.minute.toString().padLeft(2, '0')}-${timestamp.second.toString().padLeft(2, '0')}.json';

      // Collect all data from all storage boxes
      final backupData = <String, dynamic>{
        'metadata': {
          'version': '1.0',
          'timestamp': timestamp.toIso8601String(),
          'app_version': 'food_runs_counter',
          'backup_type': 'full',
        },
        'servers': await _getServersData(),
        'totals': await _getTotalsData(),
        'shifts': await _getShiftsData(),
        'profiles': await _getProfilesData(),
        'settings': await _getSettingsData(),
        'dayPlans': await _getDayPlansData(),
        'tapLogs': await _getTapLogsData(),
        'avatarPhotos': await _getAvatarPhotosData(),
        'sharedPreferences': await _getSharedPreferencesData(),
      };

      // Convert to JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      // Save to file
      final file = await _getBackupFile(fileName);
      print('[BackupManager] Attempting to write backup to: ${file.path}');
      await file.writeAsString(jsonString);

      // Verify the file was written
      final exists = await file.exists();
      final size = exists ? await file.length() : 0;
      print(
          '[BackupManager] File written successfully: exists=$exists, size=$size bytes');

      if (!exists) {
        throw Exception('File was not created after write operation');
      }

      return BackupResult(
        success: true,
        filePath: file.path,
        fileName: fileName,
        fileSize: size,
        message: 'Backup created successfully',
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: 'Failed to create backup: $e',
      );
    } finally {
      // Clean up old backups to maintain rolling 30-day retention
      try {
        await _cleanupOldAutomaticBackups();
      } catch (e) {
        print(
            '[BackupManager] Warning: Cleanup failed after backup creation: $e');
      }
    }
  }

  /// Creates a comprehensive backup package as a ZIP file including all data and photos
  static Future<BackupResult> createComprehensiveBackup(
      {String? customName}) async {
    try {
      final timestamp = DateTime.now();
      final baseName = customName
              ?.replaceAll('.zip', '')
              .replaceAll('.json', '') ??
          'food_runs_backup_${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}-${timestamp.minute.toString().padLeft(2, '0')}-${timestamp.second.toString().padLeft(2, '0')}';
      final zipFileName = '$baseName.zip';

      // Create the archive
      final archive = Archive();

      // 1. Create JSON data (without base64 encoded photos for efficiency)
      final backupData = <String, dynamic>{
        'metadata': {
          'version': '2.0', // Updated version to indicate comprehensive backup
          'timestamp': timestamp.toIso8601String(),
          'app_version': 'food_runs_counter',
          'backup_type': 'comprehensive',
          'includes_photos': true,
        },
        'servers': await _getServersData(),
        'totals': await _getTotalsData(),
        'shifts': await _getShiftsData(),
        'profiles': await _getProfilesData(),
        'settings': await _getSettingsData(),
        'dayPlans': await _getDayPlansData(),
        'tapLogs': await _getTapLogsData(),
        'avatarPhotos':
            await _getAvatarPhotosPaths(), // Just paths, not base64 data
        'sharedPreferences': await _getSharedPreferencesData(),
      };

      // Add JSON data to archive
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final jsonBytes = utf8.encode(jsonString);
      archive.addFile(
          ArchiveFile('backup_data.json', jsonBytes.length, jsonBytes));

      // 2. Add all avatar photo files to the archive
      final appDir = await getApplicationDocumentsDirectory();
      final directory = Directory(appDir.path);

      final photoFiles = await directory
          .list()
          .where((entity) => entity is File && entity.path.contains('avatar_'))
          .cast<File>()
          .toList();

      int photoCount = 0;
      for (final photoFile in photoFiles) {
        if (await photoFile.exists()) {
          final fileName = photoFile.path.split('/').last.split('\\').last;
          final photoBytes = await photoFile.readAsBytes();
          archive.addFile(
              ArchiveFile('photos/$fileName', photoBytes.length, photoBytes));
          photoCount++;
        }
      }

      // 3. Create the ZIP file
      final zipData = ZipEncoder().encode(archive);

      final zipFile = await _getBackupFile(zipFileName);
      await zipFile.writeAsBytes(zipData);

      // Verify the file was written
      final exists = await zipFile.exists();
      final size = exists ? await zipFile.length() : 0;

      if (!exists) {
        throw Exception('ZIP file was not created after write operation');
      }

      print('[BackupManager] Comprehensive backup created: $zipFileName');
      print('[BackupManager] JSON data size: ${jsonBytes.length} bytes');
      print('[BackupManager] Photos included: $photoCount');
      print('[BackupManager] Total ZIP size: $size bytes');

      return BackupResult(
        success: true,
        filePath: zipFile.path,
        fileName: zipFileName,
        fileSize: size,
        message:
            'Comprehensive backup created successfully (includes $photoCount photos)',
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: 'Failed to create comprehensive backup: $e',
      );
    } finally {
      // Clean up old backups to maintain rolling 30-day retention
      try {
        await _cleanupOldAutomaticBackups();
      } catch (e) {
        print(
            '[BackupManager] Warning: Cleanup failed after comprehensive backup creation: $e');
      }
    }
  }

  /// Restores all app data from a backup file
  static Future<RestoreResult> restoreFromBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return RestoreResult(
          success: false,
          message: 'Backup file not found',
        );
      }

      // Read and parse backup data
      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate backup format
      final validationResult = _validateBackupData(backupData);
      if (!validationResult.isValid) {
        return RestoreResult(
          success: false,
          message: 'Invalid backup file: ${validationResult.error}',
        );
      }

      // Create current backup before restore
      final currentBackup = await createBackup(
          customName:
              'pre_restore_backup_${DateTime.now().millisecondsSinceEpoch}');

      // Restore each data section
      await _restoreServersData(backupData['servers']);
      await _restoreTotalsData(backupData['totals']);
      await _restoreShiftsData(backupData['shifts']);
      await _restoreProfilesData(backupData['profiles']);
      await _restoreSettingsData(backupData['settings']);
      await _restoreDayPlansData(backupData['dayPlans']);
      await _restoreTapLogsData(backupData['tapLogs']);
      await _restoreAvatarPhotosData(backupData['avatarPhotos']);
      await _restoreSharedPreferencesData(backupData['sharedPreferences']);

      return RestoreResult(
        success: true,
        message:
            'Data restored successfully. Previous data backed up to: ${currentBackup.fileName}',
        restoredSections: [
          'servers',
          'totals',
          'shifts',
          'profiles',
          'settings',
          'dayPlans',
          'tapLogs',
          'avatarPhotos',
          'sharedPreferences'
        ],
      );
    } catch (e) {
      return RestoreResult(
        success: false,
        message: 'Failed to restore backup: $e',
      );
    }
  }

  /// Gets list of available backup files
  static Future<List<BackupInfo>> getAvailableBackups() async {
    try {
      final backups = <BackupInfo>[];

      // Check both external and internal storage locations
      final directories = await _getAllBackupDirectories();

      print(
          '[BackupManager] Checking ${directories.length} directories for backups');

      for (final directory in directories) {
        print('[BackupManager] Checking directory: ${directory.path}');

        if (await directory.exists()) {
          print('[BackupManager] Directory exists: ${directory.path}');

          // List all files first for debugging
          final allFiles = directory.listSync();
          print(
              '[BackupManager] All files in directory: ${allFiles.map((f) => f.path.split(Platform.pathSeparator).last).toList()}');

          final files = allFiles
              .where(
                  (entity) => entity is File && entity.path.endsWith('.json'))
              .cast<File>()
              .toList();

          print(
              '[BackupManager] Found ${files.length} JSON files in ${directory.path}');
          if (files.isNotEmpty) {
            print(
                '[BackupManager] JSON files: ${files.map((f) => f.path.split(Platform.pathSeparator).last).toList()}');
          }

          for (final file in files) {
            try {
              final stat = await file.stat();
              final content = await file.readAsString();
              final data = jsonDecode(content) as Map<String, dynamic>;

              final backup = BackupInfo(
                fileName: file.path.split(Platform.pathSeparator).last,
                filePath: file.path,
                fileSize: stat.size,
                created: stat.modified,
                metadata: data['metadata'] as Map<String, dynamic>?,
              );

              backups.add(backup);
              print('[BackupManager] Added backup: ${backup.fileName}');
            } catch (e) {
              print(
                  '[BackupManager] Skipping invalid backup file ${file.path}: $e');
              // Skip invalid backup files
              continue;
            }
          }
        } else {
          print('[BackupManager] Directory does not exist: ${directory.path}');
        }
      }

      print(
          '[BackupManager] Total backups found before deduplication: ${backups.length}');

      // Remove duplicates (same filename) - prefer external storage
      final uniqueBackups = <String, BackupInfo>{};
      for (final backup in backups) {
        final isExternal = backup.filePath.contains('FoodRunsBackups');
        if (!uniqueBackups.containsKey(backup.fileName) || isExternal) {
          uniqueBackups[backup.fileName] = backup;
        }
      }

      final resultList = uniqueBackups.values.toList();
      // Sort by creation date (newest first)
      resultList.sort((a, b) => b.created.compareTo(a.created));

      print('[BackupManager] Final unique backup count: ${resultList.length}');
      for (final backup in resultList) {
        print(
            '[BackupManager] Available backup: ${backup.fileName} (${backup.fileSize} bytes)');
      }

      return resultList;
    } catch (e) {
      print('[BackupManager] Error getting available backups: $e');
      return [];
    }
  }

  /// Gets all possible backup directories (external and internal)
  static Future<List<Directory>> _getAllBackupDirectories() async {
    final directories = <Directory>[];

    try {
      // First try: Downloads directory (survives app data clearing)
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        // Navigate to Downloads directory which persists across app data clearing
        final pathParts = externalDir.path.split('/');
        final rootIndex = pathParts.indexOf('0');
        if (rootIndex != -1) {
          final downloadsPath =
              '${pathParts.sublist(0, rootIndex + 1).join('/')}/Download/FoodRunsBackups';
          directories.add(Directory(downloadsPath));
        }

        // Second try: App-specific external storage
        directories.add(Directory('${externalDir.path}/FoodRunsBackups'));
      }
    } catch (e) {
      // External storage not available
    }

    // Fallback: Internal app documents directory
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      directories.add(Directory('${documentsDir.path}/backups'));
    } catch (e) {
      // App documents not available
    }

    return directories;
  }

  /// Migrates backups from internal to external storage
  static Future<void> migrateBackupsToExternal() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final oldBackupsDir = Directory('${documentsDir.path}/backups');

      if (!await oldBackupsDir.exists()) return;

      final externalDir = await getExternalStorageDirectory();
      if (externalDir == null) return;

      final newBackupsDir = Directory('${externalDir.path}/FoodRunsBackups');
      if (!await newBackupsDir.exists()) {
        await newBackupsDir.create(recursive: true);
      }

      final oldFiles = oldBackupsDir
          .listSync()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();

      for (final oldFile in oldFiles) {
        final fileName = oldFile.path.split(Platform.pathSeparator).last;
        final newFile = File('${newBackupsDir.path}/$fileName');

        if (!await newFile.exists()) {
          await oldFile.copy(newFile.path);
          print('Migrated backup: $fileName');
        }
      }
    } catch (e) {
      print('Migration failed: $e');
    }
  }

  /// Deletes a backup file
  static Future<bool> deleteBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Exports a backup file to an external location using the system share dialog
  static Future<ExportResult> exportBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ExportResult(
          success: false,
          message: 'Backup file not found',
        );
      }

      // Get file info
      final fileName = file.path.split('/').last.split('\\').last;
      final fileSize = await file.length();

      // Create XFile for sharing
      final xFile = XFile(
        file.path,
        name: fileName,
        mimeType: 'application/json',
      );

      // Share the file
      final result = await Share.shareXFiles(
        [xFile],
        subject: 'Food Runs Backup - $fileName',
        text:
            'BJ\'s Food Runs Counter backup file. Import this file to restore your data on another device.',
      );

      if (result.status == ShareResultStatus.success) {
        return ExportResult(
          success: true,
          message: 'Backup exported successfully',
          fileName: fileName,
          fileSize: fileSize,
        );
      } else {
        return ExportResult(
          success: false,
          message: 'Export was cancelled or failed',
        );
      }
    } catch (e) {
      return ExportResult(
        success: false,
        message: 'Failed to export backup: $e',
      );
    }
  }

  /// Saves a backup file to a user-selected location on the device
  static Future<ExportResult> saveBackupToDevice(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ExportResult(
          success: false,
          message: 'Backup file not found',
        );
      }

      // Get file info
      final fileName = file.path.split('/').last.split('\\').last;
      final fileSize = await file.length();

      // Read the file content
      final fileContent = await file.readAsBytes();

      // Use file picker to save the file
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup File',
        fileName: fileName,
        bytes: fileContent,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        return ExportResult(
          success: true,
          message: 'Backup saved to: $result',
          fileName: fileName,
          fileSize: fileSize,
        );
      } else {
        return ExportResult(
          success: false,
          message: 'Save operation was cancelled',
        );
      }
    } catch (e) {
      return ExportResult(
        success: false,
        message: 'Failed to save backup: $e',
      );
    }
  }

  /// Gets backup directory size
  static Future<int> getBackupDirectorySize() async {
    try {
      final directories = await _getAllBackupDirectories();
      int totalSize = 0;

      for (final directory in directories) {
        if (await directory.exists()) {
          await for (final entity in directory.list(recursive: true)) {
            if (entity is File) {
              final stat = await entity.stat();
              totalSize += stat.size;
            }
          }
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Gets information about backup storage location
  static Future<Map<String, dynamic>> getBackupLocationInfo() async {
    try {
      final externalDir = await getExternalStorageDirectory();
      final documentsDir = await getApplicationDocumentsDirectory();

      String primaryLocation = 'Internal App Storage';
      String primaryPath = '${documentsDir.path}/backups';
      bool externalAvailable = false;

      if (externalDir != null) {
        primaryLocation = 'External Storage';
        primaryPath = '${externalDir.path}/FoodRunsBackups';
        externalAvailable = true;
      }

      return {
        'primaryLocation': primaryLocation,
        'primaryPath': primaryPath,
        'externalAvailable': externalAvailable,
        'survivesClearData': externalAvailable,
      };
    } catch (e) {
      return {
        'primaryLocation': 'Internal App Storage',
        'primaryPath': 'Unknown',
        'externalAvailable': false,
        'survivesClearData': false,
      };
    }
  }

  // Private helper methods for data collection
  static Future<dynamic> _getServersData() async {
    return await Storage.serversBox.get('list');
  }

  static Future<dynamic> _getTotalsData() async {
    return await Storage.totalsBox.get('totals');
  }

  static Future<dynamic> _getShiftsData() async {
    return await Storage.shiftsBox.get('list');
  }

  static Future<Map<String, dynamic>> _getProfilesData() async {
    // Profiles are stored individually by server ID
    final servers = await Storage.serversBox.get('list') as List?;
    if (servers == null) return {};

    final profiles = <String, dynamic>{};
    for (final serverData in servers) {
      final serverId = serverData['id'] as String;
      final profileData = await Storage.profilesBox.get(serverId);
      if (profileData != null) {
        profiles[serverId] = profileData;
      }
    }
    return profiles;
  }

  static Future<Map<String, dynamic>> _getSettingsData() async {
    final settings = <String, dynamic>{};

    // Collect all known setting keys
    final keys = [
      'gamification',
      'lastEndedSnapshot',
      'weekly_hours',
      'selectedWallpaper',
      'autoRotateWallpaper',
      'activeShiftState',
    ];

    for (final key in keys) {
      final value = await Storage.settingsBox.get(key);
      if (value != null) {
        settings[key] = value;
      }
    }
    return settings;
  }

  static Future<Map<String, dynamic>> _getDayPlansData() async {
    // Day plans are stored by date keys, we need to collect them
    // This is a simplified approach - in a real scenario you might want
    // to track all used date keys or implement a getAllKeys method
    final dayPlans = <String, dynamic>{};

    // For now, get recent day plans (last 30 days)
    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final planData = await Storage.dayPlanBox.get(dateKey);
      if (planData != null) {
        dayPlans[dateKey] = planData;
      }
    }
    return dayPlans;
  }

  static Future<dynamic> _getTapLogsData() async {
    return await Storage.tapBox.get('per_minute');
  }

  static Future<Map<String, dynamic>> _getAvatarPhotosData() async {
    final avatarPhotos = <String, dynamic>{};

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final directory = Directory(appDir.path);

      // Find all avatar photo files (avatar_serverId_uuid.ext pattern)
      final files = await directory
          .list()
          .where((entity) => entity is File && entity.path.contains('avatar_'))
          .cast<File>()
          .toList();

      for (final file in files) {
        if (await file.exists()) {
          final fileName = file.path.split('/').last.split('\\').last;
          final bytes = await file.readAsBytes();
          // Store as base64 to include in JSON backup
          avatarPhotos[fileName] = {
            'data': base64Encode(bytes),
            'originalPath': file.path,
            'size': bytes.length,
          };
        }
      }

      print('[Backup] Found ${avatarPhotos.length} avatar photos to backup');
      return avatarPhotos;
    } catch (e) {
      print('[Backup] Error collecting avatar photos: $e');
      return {};
    }
  }

  /// Gets avatar photo file paths for comprehensive backup (without base64 data)
  static Future<Map<String, dynamic>> _getAvatarPhotosPaths() async {
    final avatarPhotos = <String, dynamic>{};

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final directory = Directory(appDir.path);

      // Find all avatar photo files (avatar_serverId_uuid.ext pattern)
      final files = await directory
          .list()
          .where((entity) => entity is File && entity.path.contains('avatar_'))
          .cast<File>()
          .toList();

      for (final file in files) {
        if (await file.exists()) {
          final fileName = file.path.split('/').last.split('\\').last;
          final stat = await file.stat();
          // Store only metadata, actual files will be in ZIP
          avatarPhotos[fileName] = {
            'originalPath': file.path,
            'size': stat.size,
            'modified': stat.modified.toIso8601String(),
          };
        }
      }

      print(
          '[Backup] Found ${avatarPhotos.length} avatar photos paths for comprehensive backup');
      return avatarPhotos;
    } catch (e) {
      print('[Backup] Error collecting avatar photo paths: $e');
      return {};
    }
  }

  static Future<Map<String, dynamic>> _getSharedPreferencesData() async {
    final sharedPrefsData = <String, dynamic>{};

    try {
      final prefs = await SharedPreferences.getInstance();

      // Get all keys and filter for app-specific data
      final keys = prefs
          .getKeys()
          .where((key) =>
              key.startsWith('avatar_') ||
              key == 'lunchStationType' ||
              key == 'dinnerStationType' ||
              key == 'lunchStationSection' ||
              key == 'dinnerStationSection' ||
              key == 'station_types' ||
              key.startsWith('last_automatic_backup_'))
          .toList();

      for (final key in keys) {
        final value = prefs.get(key);
        if (value != null) {
          sharedPrefsData[key] = value;
        }
      }

      print(
          '[Backup] Found ${sharedPrefsData.length} SharedPreferences entries to backup');
      return sharedPrefsData;
    } catch (e) {
      print('[Backup] Error collecting SharedPreferences data: $e');
      return {};
    }
  }

  // Private helper methods for data restoration
  static Future<void> _restoreServersData(dynamic data) async {
    if (data != null) {
      await Storage.serversBox.put('list', data);
    }
  }

  static Future<void> _restoreTotalsData(dynamic data) async {
    if (data != null) {
      await Storage.totalsBox.put('totals', data);
    }
  }

  static Future<void> _restoreShiftsData(dynamic data) async {
    if (data != null) {
      await Storage.shiftsBox.put('list', data);
    }
  }

  static Future<void> _restoreProfilesData(Map<String, dynamic>? data) async {
    if (data != null) {
      for (final entry in data.entries) {
        await Storage.profilesBox.put(entry.key, entry.value);
      }
    }
  }

  static Future<void> _restoreSettingsData(Map<String, dynamic>? data) async {
    if (data != null) {
      for (final entry in data.entries) {
        await Storage.settingsBox.put(entry.key, entry.value);
      }
    }
  }

  static Future<void> _restoreDayPlansData(Map<String, dynamic>? data) async {
    if (data != null) {
      for (final entry in data.entries) {
        await Storage.dayPlanBox.put(entry.key, entry.value);
      }
    }
  }

  static Future<void> _restoreTapLogsData(dynamic data) async {
    if (data != null) {
      await Storage.tapBox.put('per_minute', data);
    }
  }

  static Future<void> _restoreAvatarPhotosData(dynamic data) async {
    if (data == null) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final avatarPhotos = data as Map<String, dynamic>;

      int restoredCount = 0;
      for (final entry in avatarPhotos.entries) {
        try {
          final fileName = entry.key;
          final photoData = entry.value as Map<String, dynamic>;
          final base64Data = photoData['data'] as String;

          // Decode base64 and restore file
          final bytes = base64Decode(base64Data);
          final filePath = '${appDir.path}/$fileName';
          final file = File(filePath);

          await file.writeAsBytes(bytes);
          restoredCount++;

          print(
              '[Restore] Restored avatar photo: $fileName (${bytes.length} bytes)');
        } catch (e) {
          print('[Restore] Failed to restore avatar photo ${entry.key}: $e');
        }
      }

      print(
          '[Restore] Successfully restored $restoredCount/${avatarPhotos.length} avatar photos');
    } catch (e) {
      print('[Restore] Error restoring avatar photos: $e');
    }
  }

  static Future<void> _restoreSharedPreferencesData(dynamic data) async {
    if (data == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final sharedPrefsData = data as Map<String, dynamic>;

      int restoredCount = 0;
      for (final entry in sharedPrefsData.entries) {
        final key = entry.key;
        final value = entry.value;

        try {
          if (value is String) {
            await prefs.setString(key, value);
            restoredCount++;
          } else if (value is int) {
            await prefs.setInt(key, value);
            restoredCount++;
          } else if (value is double) {
            await prefs.setDouble(key, value);
            restoredCount++;
          } else if (value is bool) {
            await prefs.setBool(key, value);
            restoredCount++;
          } else if (value is List<String>) {
            await prefs.setStringList(key, value);
            restoredCount++;
          }

          print('[Restore] Restored SharedPreferences: $key');
        } catch (e) {
          print('[Restore] Failed to restore SharedPreferences entry $key: $e');
        }
      }

      print(
          '[Restore] Successfully restored $restoredCount/${sharedPrefsData.length} SharedPreferences entries');
    } catch (e) {
      print('[Restore] Error restoring SharedPreferences data: $e');
    }
  }

  // File system helpers
  static Future<Directory> _getBackupsDirectory() async {
    try {
      // First try: Downloads directory (survives app data clearing)
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        // Navigate to Downloads directory which persists across app data clearing
        // /storage/emulated/0/Android/data/app -> /storage/emulated/0/Download
        final pathParts = externalDir.path.split('/');
        final rootIndex = pathParts.indexOf('0');
        if (rootIndex != -1) {
          final downloadsPath =
              '${pathParts.sublist(0, rootIndex + 1).join('/')}/Download/FoodRunsBackups';
          final downloadsDir = Directory(downloadsPath);
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
          print(
              '[BackupManager] Using persistent Downloads directory: ${downloadsDir.path}');
          return downloadsDir;
        }

        // Second try: Use getExternalStorageDirectory for app-specific location
        final appExternalDir = Directory('${externalDir.path}/FoodRunsBackups');
        if (!await appExternalDir.exists()) {
          await appExternalDir.create(recursive: true);
        }
        print(
            '[BackupManager] Using app external directory: ${appExternalDir.path}');
        return appExternalDir;
      }
    } catch (e) {
      // If external storage fails, fall back to app documents directory
      print('External storage not available, using app documents: $e');
    }

    // Fallback to app documents directory
    final documentsDir = await getApplicationDocumentsDirectory();
    final backupsDir = Directory('${documentsDir.path}/backups');
    if (!await backupsDir.exists()) {
      await backupsDir.create(recursive: true);
    }
    print('[BackupManager] Using app documents directory: ${backupsDir.path}');
    return backupsDir;
  }

  static Future<File> _getBackupFile(String fileName) async {
    final directory = await _getBackupsDirectory();
    return File('${directory.path}/$fileName');
  }

  // Validation helpers
  static BackupValidation _validateBackupData(Map<String, dynamic> data) {
    try {
      // Check required sections
      final requiredSections = [
        'metadata',
        'servers',
        'totals',
        'shifts',
        'profiles'
      ];
      for (final section in requiredSections) {
        if (!data.containsKey(section)) {
          return BackupValidation(false, 'Missing required section: $section');
        }
      }

      // Validate metadata
      final metadata = data['metadata'] as Map<String, dynamic>?;
      if (metadata == null ||
          !metadata.containsKey('version') ||
          !metadata.containsKey('timestamp')) {
        return BackupValidation(false, 'Invalid metadata section');
      }

      return BackupValidation(true, '');
    } catch (e) {
      return BackupValidation(false, 'Validation error: $e');
    }
  }

  // ============ AUTOMATIC BACKUP SYSTEM ============

  static Timer? _automaticBackupTimer;
  static const String _lastBackupDateKey = 'last_automatic_backup_date';
  static const String _lastDeviceBackupDateKey = 'last_device_backup_date';
  static const int _maxBackupDays = 30;

  /// Starts the automatic backup system
  static void startAutomaticBackupSystem() {
    _stopAutomaticBackupTimer();

    // Perform cleanup on startup to ensure rolling retention
    _cleanupOldAutomaticBackups().catchError((e) {
      print('[BackupManager] Warning: Initial cleanup failed on startup: $e');
    });

    // Check every hour for backup opportunities
    _automaticBackupTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _checkAndPerformAutomaticBackup();
    });

    // Also check immediately when starting
    _checkAndPerformAutomaticBackup();
  }

  /// Stops the automatic backup system
  static void stopAutomaticBackupSystem() {
    _stopAutomaticBackupTimer();
  }

  static void _stopAutomaticBackupTimer() {
    _automaticBackupTimer?.cancel();
    _automaticBackupTimer = null;
  }

  /// Checks if an automatic backup should be performed
  static Future<void> _checkAndPerformAutomaticBackup() async {
    try {
      final now = DateTime.now();

      // Check if we're in the closing time window based on user settings
      final isClosingTime = await _isClosingTime(now);

      if (!isClosingTime) return;

      // Check if we already backed up today
      final today = DateTime(now.year, now.month, now.day);
      final lastBackupDate = await _getLastAutomaticBackupDate();
      final lastDeviceBackupDate = await _getLastDeviceBackupDate();

      bool needsRegularBackup = false;
      bool needsDeviceBackup = false;

      // Check if we need regular backup
      if (lastBackupDate == null ||
          lastBackupDate.year != today.year ||
          lastBackupDate.month != today.month ||
          lastBackupDate.day != today.day) {
        needsRegularBackup = true;
      }

      // Check if we need device backup
      if (lastDeviceBackupDate == null ||
          lastDeviceBackupDate.year != today.year ||
          lastDeviceBackupDate.month != today.month ||
          lastDeviceBackupDate.day != today.day) {
        needsDeviceBackup = true;
      }

      if (!needsRegularBackup && !needsDeviceBackup) {
        return; // Already backed up everything today
      }

      print('[AutoBackup] Performing automatic end-of-day backups...');

      // Create automatic server backup if needed
      if (needsRegularBackup) {
        final result = await _createAutomaticBackup();
        if (result.success) {
          await _setLastAutomaticBackupDate(today);
          print(
              '[AutoBackup] Automatic server backup created: ${result.fileName}');
        } else {
          print(
              '[AutoBackup] Failed to create automatic backup: ${result.message}');
        }
      }

      // Create automatic device backup if needed
      if (needsDeviceBackup) {
        final deviceResult = await _createAutomaticDeviceBackup();
        if (deviceResult.success) {
          await _setLastDeviceBackupDate(today);
          print(
              '[AutoBackup] Automatic device backup created: ${deviceResult.fileName}');
        } else {
          print(
              '[AutoBackup] Failed to create device backup: ${deviceResult.message}');
        }
      }

      // Clean up old backups (keep only last 30 days)
      await _cleanupOldAutomaticBackups();
    } catch (e) {
      print('[AutoBackup] Error during automatic backup: $e');
    }
  }

  /// Determines if current time is during closing hours based on user settings
  static Future<bool> _isClosingTime(DateTime now) async {
    try {
      // Get user's weekly hours settings
      final hoursMap = await Storage.settingsBox.get('weekly_hours') as Map?;
      if (hoursMap == null) {
        // Fallback to default dinner closing time if no settings
        return _isDefaultDinnerClosingTime(now);
      }

      final hours = WeeklyHours.fromMap(Map<String, dynamic>.from(hoursMap));
      final weekday = now.weekday; // 1=Monday, 7=Sunday
      final closeMinutes =
          hours.closeMinutes[weekday] ?? 23 * 60; // Default to 11 PM

      final nowMinutes = now.hour * 60 + now.minute;

      // Handle overnight closing times properly
      if (closeMinutes >= 1440) {
        // Overnight shift - check if we're in the closing window before next-day close
        final closeNextDay = closeMinutes - 1440;
        // Consider it closing time in the hour before close time (next day)
        final closingWindowStart = closeNextDay >= 60 ? closeNextDay - 60 : 0;

        // We're in closing time if we're in early morning before close OR late evening before midnight
        final inEarlyMorningClosing =
            nowMinutes < closeNextDay && nowMinutes >= closingWindowStart;
        final inLateEveningClosing =
            nowMinutes >= (1440 - 60); // Last hour of current day

        return inEarlyMorningClosing || inLateEveningClosing;
      } else {
        // Same-day closing
        final closingWindowStart = (closeMinutes - 60).clamp(0, 1439);
        return nowMinutes >= closingWindowStart && nowMinutes < closeMinutes;
      }
    } catch (e) {
      print('[AutoBackup] Error reading close time settings: $e');
      // Fallback to default
      return _isDefaultDinnerClosingTime(now);
    }
  }

  /// Fallback method for default dinner closing time
  static bool _isDefaultDinnerClosingTime(DateTime now) {
    final hour = now.hour;
    final minute = now.minute;
    final totalMinutes = hour * 60 + minute;

    // Default dinner closing time: 9:00 PM (21:00) to 11:00 PM (23:00)
    return totalMinutes >= 21 * 60 && totalMinutes < 23 * 60;
  }

  /// Creates an automatic backup with special naming
  static Future<BackupResult> _createAutomaticBackup() async {
    try {
      final timestamp = DateTime.now();
      final fileName =
          'auto_backup_${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}-${timestamp.minute.toString().padLeft(2, '0')}.json';

      // Collect all data from all storage boxes
      final backupData = <String, dynamic>{
        'metadata': {
          'version': '1.0',
          'timestamp': timestamp.toIso8601String(),
          'app_version': 'food_runs_counter',
          'backup_type': 'automatic',
          'created_during': 'dinner_closing',
        },
        'servers': await _getServersData(),
        'totals': await _getTotalsData(),
        'shifts': await _getShiftsData(),
        'profiles': await _getProfilesData(),
        'settings': await _getSettingsData(),
        'dayPlans': await _getDayPlansData(),
        'tapLogs': await _getTapLogsData(),
        'avatarPhotos': await _getAvatarPhotosData(),
        'sharedPreferences': await _getSharedPreferencesData(),
      };

      // Convert to JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      // Save to file
      final file = await _getBackupFile(fileName);
      await file.writeAsString(jsonString);

      return BackupResult(
        success: true,
        filePath: file.path,
        fileName: fileName,
        fileSize: await file.length(),
        message: 'Automatic backup created successfully',
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: 'Failed to create automatic backup: $e',
      );
    }
  }

  /// Gets the date of the last automatic backup
  static Future<DateTime?> _getLastAutomaticBackupDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateString = prefs.getString(_lastBackupDateKey);
      if (dateString != null) {
        return DateTime.parse(dateString);
      }
    } catch (e) {
      print('[AutoBackup] Error getting last backup date: $e');
    }
    return null;
  }

  /// Sets the date of the last automatic backup
  static Future<void> _setLastAutomaticBackupDate(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastBackupDateKey, date.toIso8601String());
    } catch (e) {
      print('[AutoBackup] Error setting last backup date: $e');
    }
  }

  /// Gets the date of the last device backup
  static Future<DateTime?> _getLastDeviceBackupDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateString = prefs.getString(_lastDeviceBackupDateKey);
      if (dateString != null) {
        return DateTime.parse(dateString);
      }
    } catch (e) {
      print('[AutoBackup] Error getting last device backup date: $e');
    }
    return null;
  }

  /// Sets the date of the last device backup
  static Future<void> _setLastDeviceBackupDate(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastDeviceBackupDateKey, date.toIso8601String());
    } catch (e) {
      print('[AutoBackup] Error setting last device backup date: $e');
    }
  }

  /// Creates an automatic device backup that overwrites the previous one
  static Future<BackupResult> _createAutomaticDeviceBackup() async {
    try {
      // Use a consistent filename that will be overwritten each day
      const fileName = 'daily_device_backup.zip';

      // Create comprehensive backup (includes photos)
      final result =
          await createComprehensiveBackup(customName: 'daily_device_backup');

      if (!result.success) {
        return result;
      }

      // Now save it to device storage using file picker save
      final sourceFile = File(result.filePath!);
      if (!await sourceFile.exists()) {
        return BackupResult(
          success: false,
          message: 'Backup file not found after creation',
        );
      }

      try {
        // Get Documents directory or Downloads as fallback for automatic saves
        Directory? targetDirectory;
        try {
          targetDirectory = await getApplicationDocumentsDirectory();
        } catch (e) {
          // Fallback to external storage if available
          targetDirectory = await getExternalStorageDirectory();
        }

        if (targetDirectory == null) {
          return BackupResult(
            success: false,
            message: 'No suitable directory found for device backup',
          );
        }

        // Create backup subdirectory
        final backupDir = Directory('${targetDirectory.path}/AutoBackups');
        if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
        }

        // Copy to device location with consistent filename
        final targetFile = File('${backupDir.path}/$fileName');
        await sourceFile.copy(targetFile.path);

        final size = await targetFile.length();

        return BackupResult(
          success: true,
          filePath: targetFile.path,
          fileName: fileName,
          fileSize: size,
          message: 'Device backup saved to ${targetFile.path}',
        );
      } catch (e) {
        return BackupResult(
          success: false,
          message: 'Failed to save device backup: $e',
        );
      }
    } catch (e) {
      return BackupResult(
        success: false,
        message: 'Failed to create automatic device backup: $e',
      );
    }
  }

  /// Removes automatic backups older than 30 days
  /// Cleans up old backups to maintain 30-day rolling retention
  /// This applies to ALL backup types: automatic, comprehensive, and manual backups
  static Future<void> _cleanupOldAutomaticBackups() async {
    try {
      final directories = await _getAllBackupDirectories();
      final cutoffDate =
          DateTime.now().subtract(Duration(days: _maxBackupDays));
      int deletedCount = 0;

      print(
          '[BackupCleanup] Starting cleanup - removing backups older than ${cutoffDate.toIso8601String()}');

      for (final directory in directories) {
        if (await directory.exists()) {
          final files = await directory
              .list()
              .where((entity) =>
                  entity is File &&
                  (
                      // Automatic JSON backups
                      (entity.path.endsWith('.json') &&
                              entity.path.contains('auto_backup_')) ||
                          // Comprehensive ZIP backups
                          (entity.path.endsWith('.zip') &&
                              entity.path.contains('food_runs_backup_')) ||
                          // Manual JSON backups
                          (entity.path.endsWith('.json') &&
                              entity.path.contains('food_runs_backup_')) ||
                          // Daily device backups (keep only the most recent one)
                          (entity.path.endsWith('.zip') &&
                              entity.path.contains('daily_device_backup'))))
              .cast<File>()
              .toList();

          // Sort files by modification date (oldest first)
          files.sort((a, b) {
            try {
              final aStat = a.statSync();
              final bStat = b.statSync();
              return aStat.modified.compareTo(bStat.modified);
            } catch (e) {
              return 0;
            }
          });

          // For daily device backups, keep only the most recent one
          final dailyDeviceBackups = files
              .where((file) => file.path.contains('daily_device_backup'))
              .toList();

          if (dailyDeviceBackups.length > 1) {
            // Keep the newest, delete the rest
            for (int i = 0; i < dailyDeviceBackups.length - 1; i++) {
              try {
                await dailyDeviceBackups[i].delete();
                deletedCount++;
                print(
                    '[BackupCleanup] Deleted old daily device backup: ${dailyDeviceBackups[i].path}');
              } catch (e) {
                print(
                    '[BackupCleanup] Error deleting daily device backup ${dailyDeviceBackups[i].path}: $e');
              }
            }
          }

          // For all other backups, delete those older than 30 days
          for (final file in files) {
            if (!file.path.contains('daily_device_backup')) {
              try {
                final stat = await file.stat();
                if (stat.modified.isBefore(cutoffDate)) {
                  await file.delete();
                  deletedCount++;
                  print('[BackupCleanup] Deleted old backup: ${file.path}');
                }
              } catch (e) {
                print(
                    '[BackupCleanup] Error deleting old backup ${file.path}: $e');
              }
            }
          }
        }
      }

      print(
          '[BackupCleanup] Cleanup completed - deleted $deletedCount old backup files');
    } catch (e) {
      print('[BackupCleanup] Error during cleanup: $e');
    }
  }

  /// Manual trigger for automatic backup (for testing)
  static Future<BackupResult> triggerAutomaticBackup() async {
    print('[AutoBackup] Manual trigger for automatic backup');
    final result = await _createAutomaticBackup();

    if (result.success) {
      final today = DateTime.now();
      await _setLastAutomaticBackupDate(
          DateTime(today.year, today.month, today.day));
      await _cleanupOldAutomaticBackups();
    }

    return result;
  }

  /// Gets status of automatic backup system
  static Map<String, dynamic> getAutomaticBackupStatus() {
    return {
      'isRunning': _automaticBackupTimer?.isActive ?? false,
      'nextCheckIn': 'Every hour during dinner closing (9-11 PM)',
      'retentionDays': _maxBackupDays,
      'lastBackupDate': null, // Will be filled by caller if needed
    };
  }
}

class BackupResult {
  final bool success;
  final String? filePath;
  final String? fileName;
  final int? fileSize;
  final String message;

  BackupResult({
    required this.success,
    this.filePath,
    this.fileName,
    this.fileSize,
    required this.message,
  });
}

class RestoreResult {
  final bool success;
  final String message;
  final List<String>? restoredSections;

  RestoreResult({
    required this.success,
    required this.message,
    this.restoredSections,
  });
}

class BackupInfo {
  final String fileName;
  final String filePath;
  final int fileSize;
  final DateTime created;
  final Map<String, dynamic>? metadata;

  BackupInfo({
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.created,
    this.metadata,
  });

  bool get isAutomatic => fileName.startsWith('auto_backup_');

  String get formattedSize {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024)
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String get formattedDate {
    return '${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')} ${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}';
  }

  String get displayName {
    if (isAutomatic) {
      return 'Auto Backup - $formattedDate';
    }
    return fileName.replaceAll('.json', '').replaceAll('_', ' ');
  }
}

class BackupValidation {
  final bool isValid;
  final String error;

  BackupValidation(this.isValid, this.error);
}

class ExportResult {
  final bool success;
  final String message;
  final String? fileName;
  final int? fileSize;

  ExportResult({
    required this.success,
    required this.message,
    this.fileName,
    this.fileSize,
  });
}
