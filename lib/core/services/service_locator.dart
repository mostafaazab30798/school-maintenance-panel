// Service Locator

import 'package:flutter/foundation.dart';
import 'performance_monitoring_service.dart';
import 'error_handling_service.dart';
import 'code_quality_service.dart';
import 'developer_tools_service.dart';

/// Service locator for managing application services
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  bool _initialized = false;

  /// Initialize all services
  Future<void> initialize() async {
    if (_initialized) {
      _logDebug('Services already initialized');
      return;
    }

    try {
      _logDebug('Initializing application services...');

      // Initialize services in dependency order
      PerformanceMonitoringService().initialize();
      ErrorHandlingService().initialize();
      CodeQualityService().initialize();
      DeveloperToolsService().initialize();

      // Configure service integrations
      _configureServiceIntegrations();

      _initialized = true;
      _logDebug('All services initialized successfully');
    } catch (error) {
      _logError('Failed to initialize services: $error');
      rethrow;
    }
  }

  /// Check if services are initialized
  bool get isInitialized => _initialized;

  /// Get performance monitoring service
  PerformanceMonitoringService get performance =>
      PerformanceMonitoringService();

  /// Get error handling service
  ErrorHandlingService get errorHandling => ErrorHandlingService();

  /// Get code quality service
  CodeQualityService get codeQuality => CodeQualityService();

  /// Get developer tools service
  DeveloperToolsService get developerTools => DeveloperToolsService();

  /// Get comprehensive system status
  Map<String, dynamic> getSystemStatus() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'initialized': _initialized,
      'services': {
        'performance': 'active',
        'errorHandling': 'active',
        'codeQuality': 'active',
        'developerTools': 'active',
      },
      'health': developerTools.generateHealthCheck(),
    };
  }

  /// Configure integrations between services
  void _configureServiceIntegrations() {
    // Configure error handling policies for different operations
    errorHandling.configureRetryPolicy(
        'database_query', RetryPolicy.networkPolicy());
    errorHandling.configureRetryPolicy('api_call', RetryPolicy.networkPolicy());

    // Configure circuit breakers
    errorHandling.configureCircuitBreaker(
      'supabase_query',
      failureThreshold: 5,
      timeout: const Duration(seconds: 30),
      resetTimeout: const Duration(minutes: 2),
    );

    _logDebug('Service integrations configured');
  }

  void _logDebug(String message) {
    if (kDebugMode) {
      debugPrint('ServiceLocator: $message');
    }
  }

  void _logError(String message) {
    if (kDebugMode) {
      debugPrint('ServiceLocator ERROR: $message');
    }
  }
}
