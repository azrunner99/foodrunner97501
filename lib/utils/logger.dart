class Logger {
  static bool debugLoggingEnabled = false;

  static void log(String message) {
    if (debugLoggingEnabled) {
      print('[DEBUG] $message');
    }
  }
}