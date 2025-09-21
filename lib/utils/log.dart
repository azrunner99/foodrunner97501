import 'package:flutter/foundation.dart';

/// Debug logger; prints in debug and profile, silenced in release.
void d(Object? msg) {
  if (!kReleaseMode) {
    // Avoid string alloc when disabled
    // ignore: avoid_print
    print(msg);
  }
}
