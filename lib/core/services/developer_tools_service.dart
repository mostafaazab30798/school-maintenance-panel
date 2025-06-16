// Developer Tools Service

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'performance_monitoring_service.dart';
import 'error_handling_service.dart';
import 'code_quality_service.dart';

/// Developer tools service for debugging and monitoring
class DeveloperToolsService {
  static final DeveloperToolsService _instance =
      DeveloperToolsService._internal();
  factory DeveloperToolsService() => _instance;
  DeveloperToolsService._internal();

  final List<DebugLog> _debugLogs = [];
  final Map<String, dynamic> _debugFlags = {};
  Timer? _monitoringTimer;

  static const int _maxLogs = 500;

  void initialize() {
    _setupDefaultDebugFlags();
    _startPeriodicMonitoring();
    _logDebug('Developer tools service initialized');
  }

  /// Log debug information with categorization
  void logDebug(
    String message, {
    String category = 'General',
    Map<String, dynamic>? metadata,
    DebugLevel level = DebugLevel.info,
  }) {
    final log = DebugLog(
      message: message,
      category: category,
      level: level,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    _debugLogs.add(log);

    // Limit log size
    while (_debugLogs.length > _maxLogs) {
      _debugLogs.removeAt(0);
    }

    // Print to console in debug mode
    if (kDebugMode) {
      final prefix = _getLevelPrefix(level);
      debugPrint('$prefix[$category] $message');
    }
  }

  /// Get performance dashboard data
  Map<String, dynamic> getPerformanceDashboard() {
    final performanceService = PerformanceMonitoringService();

    return {
      'timestamp': DateTime.now().toIso8601String(),
      'performance': {
        'metrics': performanceService.getAllMetrics(),
        'cacheMetrics': performanceService.getCacheMetrics(),
        'recentEvents': performanceService.getRecentEvents(limit: 20),
      },
      'system': {
        'debugFlags': _debugFlags,
        'logCount': _debugLogs.length,
      },
    };
  }

  /// Generate health check report
  Map<String, dynamic> generateHealthCheck() {
    final performanceService = PerformanceMonitoringService();

    final health = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'overall': 'healthy',
      'issues': <String>[],
      'warnings': <String>[],
    };

    // Check performance metrics
    final metrics = performanceService.getAllMetrics();
    for (final entry in metrics.entries) {
      final metric = entry.value;

      if (metric.successRate < 0.95) {
        health['issues'].add('Low success rate for ${entry.key}');
        health['overall'] = 'degraded';
      }
    }

    return health;
  }

  void _setupDefaultDebugFlags() {
    _debugFlags.addAll({
      'enablePerformanceLogging': kDebugMode,
      'enableErrorTracking': true,
      'enableCacheDebugging': kDebugMode,
    });
  }

  void _startPeriodicMonitoring() {
    _monitoringTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _performPeriodicChecks();
    });
  }

  void _performPeriodicChecks() {
    final healthCheck = generateHealthCheck();

    if (healthCheck['overall'] != 'healthy') {
      logDebug(
        'Health check alert: ${healthCheck['overall']}',
        category: 'HealthCheck',
        level: DebugLevel.warning,
      );
    }
  }

  String _getLevelPrefix(DebugLevel level) {
    switch (level) {
      case DebugLevel.debug:
        return 'DEBUG';
      case DebugLevel.info:
        return 'INFO';
      case DebugLevel.warning:
        return 'WARN';
      case DebugLevel.error:
        return 'ERROR';
    }
  }

  void _logDebug(String message) {
    if (kDebugMode) {
      debugPrint('DeveloperTools: $message');
    }
  }
}

/// Debug log entry
class DebugLog {
  final String message;
  final String category;
  final DebugLevel level;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  DebugLog({
    required this.message,
    required this.category,
    required this.level,
    required this.timestamp,
    this.metadata,
  });
}

/// Debug levels
enum DebugLevel { debug, info, warning, error }
