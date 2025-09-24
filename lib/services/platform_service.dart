import 'dart:io' if (dart.library.html) 'dart:html';
import 'package:flutter/foundation.dart';

/// Platform detection service for cross-platform compatibility
/// 
/// Provides static methods to detect the current platform and determine
/// the appropriate storage backends and UI adaptations needed.
class PlatformService {
  /// Returns true if running on Windows desktop
  static bool get isWindows => !kIsWeb && Platform.isWindows;
  
  /// Returns true if running on Android mobile
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  
  /// Returns true if running on iOS mobile  
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  
  /// Returns true if running on any mobile platform (Android or iOS)
  static bool get isMobile => isAndroid || isIOS;
  
  /// Returns true if running on any desktop platform (Windows, macOS, Linux)
  static bool get isDesktop => isWindows || (!kIsWeb && (Platform.isLinux || Platform.isMacOS));
  
  /// Returns true if running on macOS desktop
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;
  
  /// Returns true if running on Linux desktop
  static bool get isLinux => !kIsWeb && Platform.isLinux;
  
  /// Returns true if running in a web browser
  static bool get isWeb => kIsWeb;
  
  /// Returns a human-readable platform name for debugging
  static String get platformName {
    if (isWeb) return 'Web';
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    if (isWindows) return 'Windows';
    if (isMacOS) return 'macOS';
    if (isLinux) return 'Linux';
    return 'Unknown';
  }
  
  /// Returns true if the current platform supports file system operations
  static bool get supportsFileSystem => !isWeb;
  
  /// Returns true if the current platform supports SQLite operations
  static bool get supportsSQLite => !isWeb;
  
  /// Returns true if the current platform should use mobile-optimized storage
  static bool get usesMobileStorage => isMobile;
  
  /// Returns true if the current platform should use desktop-optimized storage  
  static bool get usesDesktopStorage => isDesktop;
}