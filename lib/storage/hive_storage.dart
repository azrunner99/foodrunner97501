import 'dart:convert';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'storage_interface.dart';
import '../services/platform_service.dart';

/// Hive-based implementation of StorageInterface
/// 
/// This implementation provides cross-platform key-value storage using Hive,
/// compatible with Windows, Android, iOS, and other platforms. It maintains
/// the same API as SharedPreferences while offering better performance.
class HiveStorage implements StorageInterface {
  static const String _boxName = 'food_runs_storage';
  Box<dynamic>? _box;
  bool _isInitialized = false;
  
  @override
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      // Initialize Hive with platform-appropriate directory
      if (PlatformService.isDesktop) {
        // For Windows/Desktop: Try Documents directory, fallback to temp
        String hiveDir;
        try {
          final documentsDir = await getApplicationDocumentsDirectory();
          hiveDir = '${documentsDir.path}/FoodRunsCounter';
        } catch (e) {
          // Fallback for test environments where path_provider might not work
          final tempDir = Directory.systemTemp;
          hiveDir = '${tempDir.path}/FoodRunsCounter_test';
          print('[HiveStorage] Using test directory: $hiveDir');
        }
        await Hive.initFlutter(hiveDir);
      } else {
        // For mobile: Use default app directory
        await Hive.initFlutter();
      }
      
      // Open the main storage box
      _box = await Hive.openBox(_boxName);
      _isInitialized = true;
      
      // Log successful initialization with platform info
      print('[HiveStorage] Initialized successfully on ${PlatformService.platformName}');
      
    } catch (e) {
      print('[HiveStorage] Initialization failed: $e');
      rethrow;
    }
  }
  
  /// Ensure box is initialized before operations
  Future<Box<dynamic>> _ensureInitialized() async {
    if (!_isInitialized || _box == null) {
      await init();
    }
    return _box!;
  }
  
  @override
  Future<dynamic> get(String key) async {
    try {
      final box = await _ensureInitialized();
      final value = box.get(key);
      
      // If value is a string that looks like JSON, try to decode it
      // This maintains compatibility with SharedPreferences JSON encoding
      if (value is String) {
        try {
          return jsonDecode(value);
        } catch (_) {
          // Return raw string if JSON decode fails
          return value;
        }
      }
      
      return value;
    } catch (e) {
      print('[HiveStorage] Error getting key "$key": $e');
      return null;
    }
  }
  
  @override
  Future<void> put(String key, dynamic value) async {
    try {
      final box = await _ensureInitialized();
      
      // JSON encode values to maintain compatibility with SharedPreferences
      final encodedValue = jsonEncode(value);
      await box.put(key, encodedValue);
      
    } catch (e) {
      print('[HiveStorage] Error putting key "$key": $e');
      rethrow;
    }
  }
  
  @override
  Future<void> delete(String key) async {
    try {
      final box = await _ensureInitialized();
      await box.delete(key);
    } catch (e) {
      print('[HiveStorage] Error deleting key "$key": $e');
      rethrow;
    }
  }
  
  @override
  Future<Set<String>> getKeys() async {
    try {
      final box = await _ensureInitialized();
      return box.keys.cast<String>().toSet();
    } catch (e) {
      print('[HiveStorage] Error getting keys: $e');
      return <String>{};
    }
  }
  
  @override
  Future<void> clear() async {
    try {
      final box = await _ensureInitialized();
      await box.clear();
    } catch (e) {
      print('[HiveStorage] Error clearing storage: $e');
      rethrow;
    }
  }
  
  @override
  Future<bool> containsKey(String key) async {
    try {
      final box = await _ensureInitialized();
      return box.containsKey(key);
    } catch (e) {
      print('[HiveStorage] Error checking key "$key": $e');
      return false;
    }
  }
  
  @override
  Future<int> get length async {
    try {
      final box = await _ensureInitialized();
      return box.length;
    } catch (e) {
      print('[HiveStorage] Error getting length: $e');
      return 0;
    }
  }
  
  @override
  Future<void> close() async {
    try {
      if (_box != null && _box!.isOpen) {
        await _box!.close();
      }
      _isInitialized = false;
      _box = null;
    } catch (e) {
      print('[HiveStorage] Error closing storage: $e');
    }
  }
  
  /// Migration helper: Import data from SharedPreferences format
  /// 
  /// This method helps migrate existing data from SharedPreferences
  /// to Hive storage while maintaining data integrity.
  Future<void> migrateFromMap(Map<String, String> sharedPrefsData) async {
    try {
      final box = await _ensureInitialized();
      
      print('[HiveStorage] Starting migration of ${sharedPrefsData.length} keys...');
      
      for (final entry in sharedPrefsData.entries) {
        final key = entry.key;
        final value = entry.value;
        
        // Store the value directly as it's already JSON-encoded from SharedPreferences
        await box.put(key, value);
      }
      
      print('[HiveStorage] Migration completed successfully');
      
    } catch (e) {
      print('[HiveStorage] Migration failed: $e');
      rethrow;
    }
  }
  
  /// Get storage statistics for debugging
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final box = await _ensureInitialized();
      final keys = await getKeys();
      
      return {
        'platform': PlatformService.platformName,
        'totalKeys': keys.length,
        'boxName': _boxName,
        'isInitialized': _isInitialized,
        'isOpen': _box?.isOpen ?? false,
        'sampleKeys': keys.take(5).toList(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'platform': PlatformService.platformName,
      };
    }
  }
}