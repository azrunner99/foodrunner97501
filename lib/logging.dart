import 'package:flutter/foundation.dart';

/// Lightweight debug-only logger.
///
/// Routes through [debugPrint] and is compiled out of release builds via
/// [kDebugMode], so diagnostic logging never reaches production output.
/// Replaces the ad-hoc `print()` calls that previously shipped in release.
void logDebug(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}
