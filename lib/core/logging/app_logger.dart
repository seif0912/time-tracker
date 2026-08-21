import 'dart:developer' as developer;

abstract final class AppLogger {
  static void debug(String message, {String name = 'TimeTracker'}) {
    developer.log(message, name: name, level: 500);
  }

  static void info(String message, {String name = 'TimeTracker'}) {
    developer.log(message, name: name, level: 800);
  }

  static void warning(String message, {String name = 'TimeTracker'}) {
    developer.log(message, name: name, level: 900);
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String name = 'TimeTracker',
  }) {
    developer.log(
      message,
      name: name,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
