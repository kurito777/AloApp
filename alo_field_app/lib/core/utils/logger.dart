import 'dart:developer' as dev;

class Logger {
  static void info(String message) {
    dev.log('ℹ️ INFO: $message');
  }

  static void warning(String message) {
    dev.log('⚠️ WARNING: $message');
  }

  static void error(String message, [Object? error]) {
    dev.log('❌ ERROR: $message${error != null ? '\n$error' : ''}');
  }

  static void debug(String message) {
    dev.log('🐛 DEBUG: $message');
  }

  static void success(String message) {
    dev.log('✅ SUCCESS: $message');
  }
}