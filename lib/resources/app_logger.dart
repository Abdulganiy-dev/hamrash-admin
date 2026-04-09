import 'package:flutter/foundation.dart';

class AppLogger {
  static void debug(String message) {
    if (!kReleaseMode) debugPrint('[DEBUG] $message');
  }

  static void info(String message) {
    if (!kReleaseMode) debugPrint('[INFO] $message');
  }

  static void warn(String message) {
    if (!kReleaseMode) debugPrint('[WARN] $message');
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (!kReleaseMode) {
      final suffix = error != null ? ' | error=$error' : '';
      debugPrint('[ERROR] $message$suffix');
      if (stackTrace != null) debugPrint(stackTrace.toString());
    }
  }
}


