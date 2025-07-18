// Performance Monitoring Service

import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';

/// Advanced performance monitoring service for tracking application metrics
class PerformanceMonitoringService {
  static final PerformanceMonitoringService _instance =
      PerformanceMonitoringService._internal();
  factory PerformanceMonitoringService() => _instance;
  PerformanceMonitoringService._internal();

  final Map<String, PerformanceMetric> _metrics = {};
  final Queue<PerformanceEvent> _events = Queue();
  final Map<String, CacheMetrics> _cacheMetrics = {};

  static const int _maxEvents = 1000;
  // 🚀 PERFORMANCE OPTIMIZATION: Reduced slow operation threshold for better detection
  static const Duration _slowOperationThreshold = Duration(milliseconds: 300);

  void initialize() {
    _logDebug('Performance monitoring service initialized');
  }

  PerformanceTimer startOperation(String operationName,
      {Map<String, dynamic>? metadata}) {
    return PerformanceTimer._(operationName, metadata);
  }

  void recordOperation(
    String operationName,
    Duration duration, {
    bool success = true,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    final metric = _metrics.putIfAbsent(
        operationName, () => PerformanceMetric(operationName));
    metric.addExecution(duration, success);

    final event = PerformanceEvent(
      operationName: operationName,
      duration: duration,
      success: success,
      errorMessage: errorMessage,
      metadata: metadata,
      timestamp: DateTime.now(),
    );

    _addEvent(event);
    _checkPerformanceAlerts(operationName, duration, success);
  }

  void recordCacheOperation(String cacheKey, bool hit, {String? source}) {
    final metrics = _cacheMetrics.putIfAbsent(
        source ?? 'default', () => CacheMetrics(source ?? 'default'));
    metrics.recordOperation(hit);
  }

  Map<String, PerformanceMetric> getAllMetrics() {
    return Map.unmodifiable(_metrics);
  }

  Map<String, CacheMetrics> getCacheMetrics() {
    return Map.unmodifiable(_cacheMetrics);
  }

  List<PerformanceEvent> getRecentEvents({int limit = 100}) {
    final events = _events.toList();
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return events.take(limit).toList();
  }

  Map<String, dynamic> exportPerformanceData() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'metrics': _metrics.map((key, value) => MapEntry(key, value.toJson())),
      'cacheMetrics':
          _cacheMetrics.map((key, value) => MapEntry(key, value.toJson())),
      'recentEvents':
          getRecentEvents(limit: 50).map((e) => e.toJson()).toList(),
    };
  }

  void _addEvent(PerformanceEvent event) {
    _events.add(event);
    while (_events.length > _maxEvents) {
      _events.removeFirst();
    }
  }

  void _checkPerformanceAlerts(
      String operationName, Duration duration, bool success) {
    if (!success) {
      _logWarning('Operation failed: $operationName');
    } else if (duration > _slowOperationThreshold) {
      _logWarning(
          'Slow operation detected: $operationName (${duration.inMilliseconds}ms)');
      
      // 🚀 PERFORMANCE OPTIMIZATION: Provide actionable suggestions for slow operations
      _suggestOptimizations(operationName, duration);
    }
  }

  /// 🚀 PERFORMANCE OPTIMIZATION: Provide optimization suggestions for slow operations
  void _suggestOptimizations(String operationName, Duration duration) {
    if (operationName.contains('fetchReports') || operationName.contains('fetchMaintenanceReports')) {
      _logDebug('💡 Performance suggestion: Consider implementing pagination or reducing query scope for $operationName');
    } else if (operationName.contains('Cache')) {
      _logDebug('💡 Performance suggestion: Review cache hit rates and TTL settings for $operationName');
    } else if (duration.inMilliseconds > 1000) {
      _logDebug('💡 Performance suggestion: Consider optimizing database queries or implementing background processing for $operationName');
    }
  }

  void _logDebug(String message) {
    if (kDebugMode) {
      debugPrint('PerformanceMonitoring: $message');
    }
  }

  void _logWarning(String message) {
    if (kDebugMode) {
      debugPrint('PerformanceMonitoring WARNING: $message');
    }
  }
}

class PerformanceTimer {
  final String operationName;
  final Map<String, dynamic>? metadata;
  final DateTime startTime;

  PerformanceTimer._(this.operationName, this.metadata)
      : startTime = DateTime.now();

  void stop({bool success = true, String? errorMessage}) {
    final duration = DateTime.now().difference(startTime);
    PerformanceMonitoringService().recordOperation(
      operationName,
      duration,
      success: success,
      errorMessage: errorMessage,
      metadata: metadata,
    );
  }
}

class PerformanceMetric {
  final String operationName;
  int executionCount = 0;
  int successCount = 0;
  Duration totalDuration = Duration.zero;
  Duration minDuration = Duration(days: 1);
  Duration maxDuration = Duration.zero;

  PerformanceMetric(this.operationName);

  void addExecution(Duration duration, bool success) {
    executionCount++;
    if (success) successCount++;

    totalDuration += duration;
    if (duration < minDuration) minDuration = duration;
    if (duration > maxDuration) maxDuration = duration;
  }

  Duration get averageDuration => executionCount > 0
      ? Duration(microseconds: totalDuration.inMicroseconds ~/ executionCount)
      : Duration.zero;

  double get successRate =>
      executionCount > 0 ? successCount / executionCount : 0.0;

  Map<String, dynamic> toJson() => {
        'operationName': operationName,
        'executionCount': executionCount,
        'successCount': successCount,
        'averageDuration': averageDuration.inMilliseconds,
        'successRate': successRate,
      };
}

class CacheMetrics {
  final String source;
  int hits = 0;
  int misses = 0;

  CacheMetrics(this.source);

  void recordOperation(bool hit) {
    if (hit) {
      hits++;
    } else {
      misses++;
    }
  }

  double get hitRate => (hits + misses) > 0 ? hits / (hits + misses) : 0.0;

  Map<String, dynamic> toJson() => {
        'source': source,
        'hits': hits,
        'misses': misses,
        'hitRate': hitRate,
      };
}

class PerformanceEvent {
  final String operationName;
  final Duration duration;
  final bool success;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  PerformanceEvent({
    required this.operationName,
    required this.duration,
    required this.success,
    this.errorMessage,
    this.metadata,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'operationName': operationName,
        'duration': duration.inMilliseconds,
        'success': success,
        'errorMessage': errorMessage,
        'metadata': metadata,
        'timestamp': timestamp.toIso8601String(),
      };
}
