import 'package:food_runs_counter/utils/log.dart';

/// Deprecated: use d(message) from utils/log.dart instead.
@Deprecated('Use d(message) from utils/log.dart')
class Logger {
  static void log(Object? message) {
    // Delegate to central debug logger (debug/profile only)
    d(message);
  }
}
