import 'dart:io';
import 'dart:convert';
import '../utils/backup_manager.dart';
import '../utils/log.dart';
import '../app_state.dart';

/// Backup Test Service
/// 
/// Provides testing functionality to verify backup/restore process
class BackupTestService {
  static BackupTestService? _instance;
  static BackupTestService get instance => _instance ??= BackupTestService._();
  
  BackupTestService._();

  /// Test the complete backup/restore cycle
  Future<Map<String, dynamic>> testBackupRestoreCycle() async {
    final results = <String, dynamic>{};
    
    try {
      d('[BackupTest] Starting backup/restore test cycle...');
      
      // Step 1: Create a test backup
      d('[BackupTest] Step 1: Creating test backup...');
      final backupResult = await BackupManager.createBackup(customName: 'test_backup_${DateTime.now().millisecondsSinceEpoch}');
      
      if (!backupResult.success) {
        results['error'] = 'Backup creation failed: ${backupResult.message}';
        return results;
      }
      
      results['backup_created'] = true;
      results['backup_path'] = backupResult.filePath;
      results['backup_size'] = backupResult.fileSize;
      
      d('[BackupTest] Backup created successfully: ${backupResult.filePath}');
      
      // Step 2: Verify backup file exists and is readable
      d('[BackupTest] Step 2: Verifying backup file...');
      final backupFile = File(backupResult.filePath!);
      if (!await backupFile.exists()) {
        results['error'] = 'Backup file does not exist';
        return results;
      }
      
      final fileSize = await backupFile.length();
      if (fileSize == 0) {
        results['error'] = 'Backup file is empty';
        return results;
      }
      
      results['backup_file_verified'] = true;
      results['backup_file_size'] = fileSize;
      
      // Step 3: Parse backup content to verify structure
      d('[BackupTest] Step 3: Parsing backup content...');
      final jsonString = await backupFile.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Check for required sections
      final requiredSections = ['metadata', 'servers', 'totals', 'shifts', 'profiles', 'settings', 'avatarPhotos', 'sharedPreferences'];
      final missingSections = <String>[];
      
      for (final section in requiredSections) {
        if (!backupData.containsKey(section)) {
          missingSections.add(section);
        }
      }
      
      if (missingSections.isNotEmpty) {
        results['error'] = 'Missing backup sections: ${missingSections.join(', ')}';
        return results;
      }
      
      results['backup_content_verified'] = true;
      results['backup_sections'] = backupData.keys.toList();
      results['servers_count'] = (backupData['servers'] as List?)?.length ?? 0;
      results['shifts_count'] = (backupData['shifts'] as List?)?.length ?? 0;
      results['profiles_count'] = (backupData['profiles'] as Map?)?.length ?? 0;
      results['avatar_photos_count'] = (backupData['avatarPhotos'] as Map?)?.length ?? 0;
      
      d('[BackupTest] Backup content verified successfully');
      d('[BackupTest] Servers: ${results['servers_count']}, Shifts: ${results['shifts_count']}, Profiles: ${results['profiles_count']}, Avatar Photos: ${results['avatar_photos_count']}');
      
      // Step 4: Test restore process
      d('[BackupTest] Step 4: Testing restore process...');
      final restoreResult = await BackupManager.restoreFromBackup(backupResult.filePath!);
      
      if (!restoreResult.success) {
        results['error'] = 'Restore failed: ${restoreResult.message}';
        return results;
      }
      
      results['restore_successful'] = true;
      results['restored_sections'] = restoreResult.restoredSections;
      
      d('[BackupTest] Restore completed successfully');
        d('[BackupTest] Restored sections: ${restoreResult.restoredSections?.join(', ') ?? 'none'}');
      
      // Step 5: Verify data was actually restored
      d('[BackupTest] Step 5: Verifying restored data...');
      final appState = AppState();
      await appState.load();
      
      results['restored_servers_count'] = appState.servers.length;
      results['restored_shifts_count'] = appState.history.length;
      results['restored_profiles_count'] = appState.profiles.length;
      
      d('[BackupTest] Restored data verification:');
      d('[BackupTest] - Servers: ${appState.servers.length}');
      d('[BackupTest] - Shifts: ${appState.history.length}');
      d('[BackupTest] - Profiles: ${appState.profiles.length}');
      
      // Step 6: Clean up test backup
      d('[BackupTest] Step 6: Cleaning up test backup...');
      try {
        await backupFile.delete();
        results['cleanup_successful'] = true;
      } catch (e) {
        results['cleanup_error'] = e.toString();
      }
      
      results['test_completed'] = true;
      results['success'] = true;
      
      d('[BackupTest] Backup/restore test cycle completed successfully!');
      
    } catch (e) {
      d('[BackupTest] Error during test cycle: $e');
      results['error'] = 'Test cycle failed: $e';
      results['success'] = false;
    }
    
    return results;
  }

  /// Test backup file validation
  Future<Map<String, dynamic>> testBackupValidation(String filePath) async {
    final results = <String, dynamic>{};
    
    try {
      d('[BackupTest] Testing backup validation for: $filePath');
      
      final file = File(filePath);
      if (!await file.exists()) {
        results['error'] = 'File does not exist';
        return results;
      }
      
      final fileSize = await file.length();
      if (fileSize == 0) {
        results['error'] = 'File is empty';
        return results;
      }
      
      results['file_exists'] = true;
      results['file_size'] = fileSize;
      
      // Parse JSON
      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Check metadata
      final metadata = backupData['metadata'] as Map<String, dynamic>?;
      if (metadata == null) {
        results['error'] = 'Missing metadata section';
        return results;
      }
      
      results['metadata'] = metadata;
      results['backup_type'] = metadata['backup_type'] as String?;
      results['version'] = metadata['version'] as String?;
      results['timestamp'] = metadata['timestamp'] as String?;
      results['includes_sqlite'] = metadata['includes_sqlite'] as bool? ?? false;
      
      // Check data sections
      final sections = backupData.keys.toList();
      results['sections'] = sections;
      
      // Count data
      results['servers_count'] = (backupData['servers'] as List?)?.length ?? 0;
      results['shifts_count'] = (backupData['shifts'] as List?)?.length ?? 0;
      results['profiles_count'] = (backupData['profiles'] as Map?)?.length ?? 0;
      results['avatar_photos_count'] = (backupData['avatarPhotos'] as Map?)?.length ?? 0;
      results['shared_prefs_count'] = (backupData['sharedPreferences'] as Map?)?.length ?? 0;
      
      if (backupData.containsKey('sqlite_data')) {
        final sqliteData = backupData['sqlite_data'] as Map<String, dynamic>;
        results['sqlite_tables'] = sqliteData.keys.toList();
        results['sqlite_servers_count'] = (sqliteData['servers'] as List?)?.length ?? 0;
        results['sqlite_nps_feedback_count'] = (sqliteData['nps_feedback'] as List?)?.length ?? 0;
        results['sqlite_monthly_reports_count'] = (sqliteData['nps_monthly_reports'] as List?)?.length ?? 0;
      }
      
      results['validation_successful'] = true;
      
      d('[BackupTest] Backup validation completed successfully');
      d('[BackupTest] - Servers: ${results['servers_count']}');
      d('[BackupTest] - Shifts: ${results['shifts_count']}');
      d('[BackupTest] - Profiles: ${results['profiles_count']}');
      d('[BackupTest] - Avatar Photos: ${results['avatar_photos_count']}');
      d('[BackupTest] - Shared Preferences: ${results['shared_prefs_count']}');
      if (results['includes_sqlite']) {
        d('[BackupTest] - SQLite Tables: ${results['sqlite_tables']}');
      }
      
    } catch (e) {
      d('[BackupTest] Error validating backup: $e');
      results['error'] = 'Validation failed: $e';
    }
    
    return results;
  }

  /// Get current app data summary
  Future<Map<String, dynamic>> getCurrentDataSummary() async {
    final results = <String, dynamic>{};
    
    try {
      d('[BackupTest] Getting current app data summary...');
      
      final appState = AppState();
      await appState.load();
      
      results['servers_count'] = appState.servers.length;
      results['shifts_count'] = appState.history.length;
      results['profiles_count'] = appState.profiles.length;
      results['totals_count'] = appState.totals.length;
      
      // Get server names
      results['server_names'] = appState.servers.map((s) => s.name).toList();
      
      // Get recent shifts
      final recentShifts = appState.history.take(5).map((s) => {
        'date': s.start.toString(),
        'shift_type': s.shiftType,
        'total_runs': s.counts.values.fold(0, (sum, runs) => sum + runs),
      }).toList();
      results['recent_shifts'] = recentShifts;
      
      d('[BackupTest] Current data summary:');
      d('[BackupTest] - Servers: ${results['servers_count']}');
      d('[BackupTest] - Shifts: ${results['shifts_count']}');
      d('[BackupTest] - Profiles: ${results['profiles_count']}');
      d('[BackupTest] - Totals: ${results['totals_count']}');
      
    } catch (e) {
      d('[BackupTest] Error getting data summary: $e');
      results['error'] = 'Failed to get data summary: $e';
    }
    
    return results;
  }
}
