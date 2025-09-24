import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../services/platform_service.dart';
import '../utils/log.dart';

/// Universal File Service for cross-platform file operations
/// 
/// This service abstracts file system operations to provide consistent
/// behavior across Android and Windows platforms. It handles platform-specific
/// directory structures and path resolution automatically.
class FileService {
  static FileService? _instance;
  
  /// Singleton instance
  static FileService get instance {
    _instance ??= FileService._();
    return _instance!;
  }

  FileService._();

  /// Get the appropriate documents directory for the current platform
  /// 
  /// - Android: Uses getApplicationDocumentsDirectory()
  /// - Windows: Uses getApplicationDocumentsDirectory() 
  /// - Fallback: Uses getApplicationDocumentsDirectory()
  Future<Directory> getDocumentsDirectory() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      d('[FileService] Documents directory: ${documentsDir.path}');
      return documentsDir;
    } catch (e) {
      d('[FileService] Error getting documents directory: $e');
      rethrow;
    }
  }

  /// Get the appropriate external storage directory for the current platform
  /// 
  /// - Android: Uses getExternalStorageDirectory() for Downloads access
  /// - Windows: Uses getDownloadsDirectory() if available, falls back to Documents
  /// - Other: Falls back to Documents directory
  Future<Directory?> getExternalDirectory() async {
    try {
      if (PlatformService.isAndroid) {
        // Android: Use external storage directory
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          d('[FileService] External directory (Android): ${externalDir.path}');
          return externalDir;
        }
      } else if (PlatformService.isWindows) {
        // Windows: Try to get Downloads directory
        try {
          final downloadsDir = await getDownloadsDirectory();
          if (downloadsDir != null) {
            d('[FileService] External directory (Windows Downloads): ${downloadsDir.path}');
            return downloadsDir;
          }
        } catch (e) {
          d('[FileService] Downloads directory not available on Windows: $e');
        }
      }
      
      // Fallback to documents directory
      final documentsDir = await getDocumentsDirectory();
      d('[FileService] External directory (fallback to Documents): ${documentsDir.path}');
      return documentsDir;
    } catch (e) {
      d('[FileService] Error getting external directory: $e');
      return null;
    }
  }

  /// Get app-specific data directory for backups and exports
  /// 
  /// Creates a subdirectory within the platform's appropriate location
  /// for storing app-specific files like backups and exports.
  Future<Directory> getAppDataDirectory({String? subdirectory}) async {
    try {
      final baseDir = await getDocumentsDirectory();
      final appDirPath = path.join(baseDir.path, 'FoodRunsCounter');
      
      String finalPath = appDirPath;
      if (subdirectory != null) {
        finalPath = path.join(appDirPath, subdirectory);
      }
      
      final appDir = Directory(finalPath);
      
      // Create directory if it doesn't exist
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
        d('[FileService] Created app data directory: $finalPath');
      }
      
      return appDir;
    } catch (e) {
      d('[FileService] Error getting app data directory: $e');
      rethrow;
    }
  }

  /// Get backup directories for the current platform
  /// 
  /// Returns a list of directories where backups can be stored/found,
  /// ordered by preference (most preferred first).
  Future<List<Directory>> getBackupDirectories() async {
    final directories = <Directory>[];
    
    try {
      if (PlatformService.isAndroid) {
        // Android: Prefer external storage, fallback to app documents
        final externalDir = await getExternalDirectory();
        if (externalDir != null) {
          final backupDir = Directory(path.join(externalDir.path, 'FoodRunsCounter', 'Backups'));
          directories.add(backupDir);
        }
        
        // Also check app documents directory
        final appBackupDir = await getAppDataDirectory(subdirectory: 'Backups');
        directories.add(appBackupDir);
        
      } else if (PlatformService.isWindows) {
        // Windows: Use Documents/FoodRunsCounter/Backups
        final appBackupDir = await getAppDataDirectory(subdirectory: 'Backups');
        directories.add(appBackupDir);
        
        // Also try Downloads if available
        final externalDir = await getExternalDirectory();
        if (externalDir != null && externalDir.path != (await getDocumentsDirectory()).path) {
          final backupDir = Directory(path.join(externalDir.path, 'FoodRunsCounter', 'Backups'));
          directories.add(backupDir);
        }
        
      } else {
        // Other platforms: Use app data directory
        final appBackupDir = await getAppDataDirectory(subdirectory: 'Backups');
        directories.add(appBackupDir);
      }
      
      d('[FileService] Backup directories: ${directories.map((d) => d.path).toList()}');
      return directories;
      
    } catch (e) {
      d('[FileService] Error getting backup directories: $e');
      // Return at least the app data directory as fallback
      try {
        final fallbackDir = await getAppDataDirectory(subdirectory: 'Backups');
        return [fallbackDir];
      } catch (fallbackError) {
        d('[FileService] Fallback directory also failed: $fallbackError');
        rethrow;
      }
    }
  }

  /// Get export directory for CSV and other data exports
  Future<Directory> getExportDirectory() async {
    try {
      if (PlatformService.isWindows) {
        // Windows: Prefer Downloads directory for exports
        final externalDir = await getExternalDirectory();
        if (externalDir != null) {
          final exportDir = Directory(path.join(externalDir.path, 'FoodRunsCounter', 'Exports'));
          if (!await exportDir.exists()) {
            await exportDir.create(recursive: true);
          }
          d('[FileService] Export directory (Windows): ${exportDir.path}');
          return exportDir;
        }
      }
      
      // Fallback: Use app data directory
      final exportDir = await getAppDataDirectory(subdirectory: 'Exports');
      d('[FileService] Export directory (fallback): ${exportDir.path}');
      return exportDir;
      
    } catch (e) {
      d('[FileService] Error getting export directory: $e');
      rethrow;
    }
  }

  /// Create a file with the given name in the specified directory
  /// 
  /// Ensures the directory exists before creating the file.
  Future<File> createFile(Directory directory, String fileName) async {
    try {
      // Ensure directory exists
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      final filePath = path.join(directory.path, fileName);
      final file = File(filePath);
      
      d('[FileService] Created file path: $filePath');
      return file;
      
    } catch (e) {
      d('[FileService] Error creating file: $e');
      rethrow;
    }
  }

  /// Get all files in a directory with optional file extension filter
  Future<List<File>> getFilesInDirectory(
    Directory directory, {
    String? extension,
    bool recursive = false,
  }) async {
    try {
      if (!await directory.exists()) {
        d('[FileService] Directory does not exist: ${directory.path}');
        return [];
      }
      
      final files = <File>[];
      final entities = directory.listSync(recursive: recursive);
      
      for (final entity in entities) {
        if (entity is File) {
          if (extension == null || entity.path.toLowerCase().endsWith(extension.toLowerCase())) {
            files.add(entity);
          }
        }
      }
      
      d('[FileService] Found ${files.length} files in ${directory.path}${extension != null ? ' with extension $extension' : ''}');
      return files;
      
    } catch (e) {
      d('[FileService] Error getting files in directory: $e');
      return [];
    }
  }

  /// Copy a file to a new location
  Future<File> copyFile(File source, Directory targetDirectory, {String? newFileName}) async {
    try {
      // Ensure target directory exists
      if (!await targetDirectory.exists()) {
        await targetDirectory.create(recursive: true);
      }
      
      final fileName = newFileName ?? path.basename(source.path);
      final targetPath = path.join(targetDirectory.path, fileName);
      
      final targetFile = await source.copy(targetPath);
      d('[FileService] Copied file from ${source.path} to ${targetFile.path}');
      
      return targetFile;
      
    } catch (e) {
      d('[FileService] Error copying file: $e');
      rethrow;
    }
  }

  /// Delete a file or directory safely
  Future<bool> delete(FileSystemEntity entity, {bool recursive = false}) async {
    try {
      if (await entity.exists()) {
        await entity.delete(recursive: recursive);
        d('[FileService] Deleted: ${entity.path}');
        return true;
      } else {
        d('[FileService] Entity does not exist: ${entity.path}');
        return false;
      }
    } catch (e) {
      d('[FileService] Error deleting entity: $e');
      return false;
    }
  }

  /// Check if a file or directory exists
  Future<bool> exists(String path) async {
    try {
      final entity = FileSystemEntity.typeSync(path);
      return entity != FileSystemEntityType.notFound;
    } catch (e) {
      d('[FileService] Error checking existence: $e');
      return false;
    }
  }

  /// Get platform-appropriate path separator
  String get pathSeparator => Platform.pathSeparator;

  /// Join path components using the platform-appropriate separator
  String joinPath(List<String> components) {
    return path.joinAll(components);
  }

  /// Get file name from a path
  String getFileName(String filePath) {
    return path.basename(filePath);
  }

  /// Get directory path from a file path
  String getDirectoryPath(String filePath) {
    return path.dirname(filePath);
  }

  /// Get file extension from a path
  String getFileExtension(String filePath) {
    return path.extension(filePath);
  }

  /// Generate a timestamp-based filename
  String generateTimestampedFileName(String baseName, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${baseName}_$timestamp.$extension';
  }

  /// Get human-readable platform info for debugging
  String get platformInfo {
    return 'Platform: ${PlatformService.platformName}, '
           'Separator: $pathSeparator';
  }
}