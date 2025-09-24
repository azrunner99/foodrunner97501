import 'storage_interface.dart';
import 'shared_prefs_storage.dart';
import 'hive_storage.dart';
import '../services/platform_service.dart';

/// Factory for creating platform-appropriate storage implementations
/// 
/// This factory automatically selects the best storage backend based on
/// the current platform, ensuring optimal performance and compatibility.
class StorageFactory {
  /// Create a storage instance appropriate for the current platform
  /// 
  /// Returns:
  /// - SharedPrefsStorage for Android/iOS and test environments
  /// - HiveStorage for Windows/Desktop (cross-platform compatibility)
  static StorageInterface create() {
    // Check if we're in a test environment (Dart VM test runner)
    if (_isTestEnvironment()) {
      return SharedPrefsStorage();
    }
    
    if (PlatformService.isWindows || PlatformService.isDesktop) {
      // Use Hive for Windows and other desktop platforms
      return HiveStorage();
    } else if (PlatformService.isMobile) {
      // Use existing SharedPreferences backend for mobile platforms
      return SharedPrefsStorage();
    } else {
      // Default fallback - use Hive for unknown platforms
      return HiveStorage();
    }
  }
  
  /// Detect if we're running in a test environment
  static bool _isTestEnvironment() {
    // In Dart VM tests, we can detect this through the current zone or stack trace
    try {
      // If we're in a test, there's typically no real application documents directory
      return (const bool.fromEnvironment('dart.vm.testing', defaultValue: false) ||
              _isStackTraceFromTest());
    } catch (e) {
      return false;
    }
  }
  
  /// Check if the current call stack indicates we're in a test
  static bool _isStackTraceFromTest() {
    try {
      final stackTrace = StackTrace.current.toString();
      return stackTrace.contains('test_') || 
             stackTrace.contains('_test.dart') ||
             stackTrace.contains('dart:io/main.dart');
    } catch (e) {
      return false;
    }
  }
  
  /// Create a storage instance for a specific platform (testing purposes)
  /// 
  /// Allows overriding platform detection for testing different backends.
  static StorageInterface createForPlatform(String platform) {
    switch (platform.toLowerCase()) {
      case 'android':
      case 'ios':
      case 'mobile':
      case 'test':
        return SharedPrefsStorage();
      case 'windows':
      case 'desktop':
        return HiveStorage();
      default:
        return HiveStorage();
    }
  }
  
  /// Get the backend type name for the current platform (debugging)
  static String getBackendType() {
    if (_isTestEnvironment()) {
      return 'SharedPrefsStorage (test)';
    } else if (PlatformService.isWindows || PlatformService.isDesktop) {
      return 'HiveStorage';
    } else if (PlatformService.isMobile) {
      return 'SharedPrefsStorage';
    } else {
      return 'HiveStorage (Fallback)';
    }
  }
  
  /// Check if the current platform supports data migration
  static bool supportsMigration() {
    return PlatformService.isWindows || PlatformService.isDesktop;
  }
}