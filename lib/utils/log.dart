import 'package:flutter/foundation.dart';

/// Global verbose flag (can be toggled early in app startup / tests)
/// Default set to false to reduce runtime noise and improve performance.
bool kVerboseLogging = false;

/// Enable/disable verbose logging at runtime (e.g. from a debug menu).
void setVerboseLogging(bool enabled) {
  kVerboseLogging = enabled;
  if (!kReleaseMode) {
    // ignore: avoid_print
    print('[Log] Verbose logging set to: $enabled');
  }
}

/// Debug logger; prints in debug/profile when verbosity is enabled (never in release).
void d(Object? msg) {
  if (!kReleaseMode && kVerboseLogging) {
    // ignore: avoid_print
    print(msg);
  }
}
