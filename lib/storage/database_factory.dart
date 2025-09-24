import '../services/platform_service.dart';
import '../utils/log.dart';
import 'database_interface.dart';
import 'drift_database.dart';
import 'sqflite_database.dart';

/// Factory class that provides the appropriate database implementation
/// based on the current platform
/// 
/// - Android: Uses sqflite for optimal performance
/// - Windows/Desktop: Uses Drift for cross-platform compatibility
class DatabaseFactory {
  static DatabaseInterface? _instance;
  
  /// Get singleton database instance
  static DatabaseInterface get instance {
    if (_instance == null) {
      throw Exception('Database not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  /// Initialize the database with platform-appropriate implementation
  static Future<void> initialize() async {
    if (_instance != null) {
      d('[DatabaseFactory] Database already initialized');
      return;
    }

    try {
      if (PlatformService.isAndroid) {
        d('[DatabaseFactory] Initializing sqflite database for Android');
        _instance = SqfliteNPSDatabase();
      } else if (PlatformService.isWindows || PlatformService.isDesktop) {
        d('[DatabaseFactory] Initializing Drift database for Windows/Desktop');
        _instance = DriftNPSDatabase();
      } else {
        // Fallback to Drift for other platforms
        d('[DatabaseFactory] Initializing Drift database as fallback for platform: ${PlatformService.platformName}');
        _instance = DriftNPSDatabase();
      }

      // Initialize the database
      await _instance!.init();
      d('[DatabaseFactory] Database initialized successfully');

    } catch (e) {
      d('[DatabaseFactory] Error initializing database: $e');
      _instance = null;
      rethrow;
    }
  }

  /// Reset the database instance (useful for testing)
  static Future<void> reset() async {
    if (_instance != null) {
      try {
        await _instance!.close();
      } catch (e) {
        d('[DatabaseFactory] Error closing database during reset: $e');
      }
      _instance = null;
    }
  }

  /// Check if database is initialized
  static bool get isInitialized => _instance != null;

  /// Get the current implementation type name for debugging
  static String get implementationType {
    if (_instance == null) return 'None';
    if (_instance is SqfliteNPSDatabase) return 'Sqflite (Android)';
    if (_instance is DriftNPSDatabase) return 'Drift (Cross-platform)';
    return 'Unknown';
  }
}