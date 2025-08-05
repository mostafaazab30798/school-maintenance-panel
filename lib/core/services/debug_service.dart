import 'package:flutter/foundation.dart';

class DebugService {
  static void initialize() {
    if (kDebugMode) {
      // Enable debug logging for platform channels
      debugPrint('🔧 Debug mode enabled - monitoring platform channels');
    }
  }
  
  static void logChannelMessage(String channel, String message) {
    if (kDebugMode) {
      debugPrint('📡 Channel message on $channel: $message');
    }
  }
  
  static void logError(String error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('❌ Error: $error');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }
  
  static void logWarning(String warning) {
    if (kDebugMode) {
      debugPrint('⚠️ Warning: $warning');
    }
  }
} 