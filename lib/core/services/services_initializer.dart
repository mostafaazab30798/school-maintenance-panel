import 'package:flutter/foundation.dart';
import 'cache_service.dart';
import 'data_sync_service.dart';
import 'notification_service.dart';

class ServicesInitializer {
  static bool _isInitialized = false;

  /// Initialize all core services
  static void initialize() {
    if (_isInitialized) return;

    try {
      // Initialize cache service
      final cacheService = CacheService();

      // Initialize data sync service for realtime updates
      final dataSyncService = DataSyncService();
      dataSyncService.initialize();

      // Initialize notification service
      NotificationService.instance.initialize();

      _isInitialized = true;

      if (kDebugMode) {
        print('ServicesInitializer: All services initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ServicesInitializer: Failed to initialize services: $e');
      }
    }
  }

  /// Clean up all services
  static void dispose() {
    if (!_isInitialized) return;

    try {
      final cacheService = CacheService();
      cacheService.dispose();

      final dataSyncService = DataSyncService();
      dataSyncService.dispose();

      // Dispose notification service
      NotificationService.instance.dispose();

      _isInitialized = false;

      if (kDebugMode) {
        print('ServicesInitializer: All services disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ServicesInitializer: Error disposing services: $e');
      }
    }
  }

  /// Check if services are initialized
  static bool get isInitialized => _isInitialized;

  /// Force reinitialize all services
  static void reinitialize() {
    dispose();
    initialize();
  }
}
