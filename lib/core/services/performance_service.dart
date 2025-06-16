import 'package:flutter/foundation.dart';

/// Performance monitoring service for tracking app performance metrics
///
/// This service provides tools for measuring and monitoring various
/// performance aspects of the application including:
/// - Operation execution times
/// - Memory usage patterns
/// - Cache hit rates
/// - Network request performance
class PerformanceService {
  static const String _logPrefix = 'PerformanceService';

  // Singleton pattern
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  // Performance metrics storage
  final Map<String, List<Duration>> _operationTimes = {};
  final Map<String, int> _operationCounts = {};
  final Map<String, DateTime> _activeOperations = {};

  // Cache performance metrics
  final Map<String, int> _cacheHits = {};
  final Map<String, int> _cacheMisses = {};

  // Memory usage tracking
  final List<MemorySnapshot> _memorySnapshots = [];

  /// Starts timing an operation
  ///
  /// Returns an operation ID that should be used with [endOperation]
  String startOperation(String operationName,
      {Map<String, dynamic>? metadata}) {
    final operationId =
        '${operationName}_${DateTime.now().millisecondsSinceEpoch}';
    _activeOperations[operationId] = DateTime.now();

    if (kDebugMode) {
      debugPrint(
          '$_logPrefix: Started operation "$operationName" (ID: $operationId)');
      if (metadata != null) {
        debugPrint('$_logPrefix: Metadata: $metadata');
      }
    }

    return operationId;
  }

  /// Ends timing an operation and records the duration
  Duration? endOperation(String operationId, {bool logResult = true}) {
    final startTime = _activeOperations.remove(operationId);
    if (startTime == null) {
      if (kDebugMode) {
        debugPrint(
            '$_logPrefix: Warning - Operation ID not found: $operationId');
      }
      return null;
    }

    final duration = DateTime.now().difference(startTime);
    final operationName = operationId.split('_').first;

    // Record the timing
    _operationTimes.putIfAbsent(operationName, () => []).add(duration);
    _operationCounts[operationName] =
        (_operationCounts[operationName] ?? 0) + 1;

    if (kDebugMode && logResult) {
      debugPrint(
          '$_logPrefix: Completed operation "$operationName" in ${duration.inMilliseconds}ms');
    }

    return duration;
  }

  /// Records a cache hit for performance tracking
  void recordCacheHit(String cacheType) {
    _cacheHits[cacheType] = (_cacheHits[cacheType] ?? 0) + 1;

    if (kDebugMode) {
      debugPrint('$_logPrefix: Cache hit for $cacheType');
    }
  }

  /// Records a cache miss for performance tracking
  void recordCacheMiss(String cacheType) {
    _cacheMisses[cacheType] = (_cacheMisses[cacheType] ?? 0) + 1;

    if (kDebugMode) {
      debugPrint('$_logPrefix: Cache miss for $cacheType');
    }
  }

  /// Takes a memory snapshot for tracking memory usage
  void takeMemorySnapshot(String label) {
    // Note: In a real implementation, you would use platform-specific
    // memory monitoring APIs. This is a simplified version.
    final snapshot = MemorySnapshot(
      label: label,
      timestamp: DateTime.now(),
      // In a real implementation, get actual memory usage
      estimatedMemoryUsage: _estimateMemoryUsage(),
    );

    _memorySnapshots.add(snapshot);

    // Keep only the last 100 snapshots
    if (_memorySnapshots.length > 100) {
      _memorySnapshots.removeAt(0);
    }

    if (kDebugMode) {
      debugPrint(
          '$_logPrefix: Memory snapshot "$label": ${snapshot.estimatedMemoryUsage}MB');
    }
  }

  /// Gets performance statistics for a specific operation
  OperationStats? getOperationStats(String operationName) {
    final times = _operationTimes[operationName];
    final count = _operationCounts[operationName];

    if (times == null || times.isEmpty || count == null) {
      return null;
    }

    final totalMs =
        times.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds);
    final avgMs = totalMs / times.length;
    final minMs =
        times.map((d) => d.inMilliseconds).reduce((a, b) => a < b ? a : b);
    final maxMs =
        times.map((d) => d.inMilliseconds).reduce((a, b) => a > b ? a : b);

    return OperationStats(
      operationName: operationName,
      totalExecutions: count,
      averageTimeMs: avgMs,
      minTimeMs: minMs,
      maxTimeMs: maxMs,
      totalTimeMs: totalMs,
    );
  }

  /// Gets cache performance statistics
  CacheStats getCacheStats(String cacheType) {
    final hits = _cacheHits[cacheType] ?? 0;
    final misses = _cacheMisses[cacheType] ?? 0;
    final total = hits + misses;
    final hitRate = total > 0 ? (hits / total) * 100 : 0.0;

    return CacheStats(
      cacheType: cacheType,
      hits: hits,
      misses: misses,
      hitRate: hitRate,
    );
  }

  /// Gets all performance statistics
  PerformanceReport getPerformanceReport() {
    final operationStats = <OperationStats>[];
    for (final operationName in _operationTimes.keys) {
      final stats = getOperationStats(operationName);
      if (stats != null) {
        operationStats.add(stats);
      }
    }

    final cacheStats = <CacheStats>[];
    final allCacheTypes = {..._cacheHits.keys, ..._cacheMisses.keys};
    for (final cacheType in allCacheTypes) {
      cacheStats.add(getCacheStats(cacheType));
    }

    return PerformanceReport(
      operationStats: operationStats,
      cacheStats: cacheStats,
      memorySnapshots: List.from(_memorySnapshots),
      reportGeneratedAt: DateTime.now(),
    );
  }

  /// Clears all performance data
  void clearData() {
    _operationTimes.clear();
    _operationCounts.clear();
    _activeOperations.clear();
    _cacheHits.clear();
    _cacheMisses.clear();
    _memorySnapshots.clear();

    if (kDebugMode) {
      debugPrint('$_logPrefix: Performance data cleared');
    }
  }

  /// Logs a performance summary to debug console
  void logPerformanceSummary() {
    if (!kDebugMode) return;

    debugPrint('$_logPrefix: === PERFORMANCE SUMMARY ===');

    // Operation performance
    debugPrint('$_logPrefix: Operation Performance:');
    for (final operationName in _operationTimes.keys) {
      final stats = getOperationStats(operationName);
      if (stats != null) {
        debugPrint(
            '$_logPrefix:   $operationName: ${stats.totalExecutions} executions, avg ${stats.averageTimeMs.toStringAsFixed(1)}ms');
      }
    }

    // Cache performance
    debugPrint('$_logPrefix: Cache Performance:');
    final allCacheTypes = {..._cacheHits.keys, ..._cacheMisses.keys};
    for (final cacheType in allCacheTypes) {
      final stats = getCacheStats(cacheType);
      debugPrint(
          '$_logPrefix:   $cacheType: ${stats.hitRate.toStringAsFixed(1)}% hit rate (${stats.hits} hits, ${stats.misses} misses)');
    }

    // Memory usage
    if (_memorySnapshots.isNotEmpty) {
      final latest = _memorySnapshots.last;
      debugPrint(
          '$_logPrefix: Latest Memory Usage: ${latest.estimatedMemoryUsage}MB (${latest.label})');
    }

    debugPrint('$_logPrefix: === END SUMMARY ===');
  }

  // Private helper methods
  double _estimateMemoryUsage() {
    // Simplified memory estimation
    // In a real implementation, use platform-specific APIs
    return 50.0 +
        (_operationTimes.length * 0.1) +
        (_memorySnapshots.length * 0.05);
  }
}

/// Statistics for a specific operation
class OperationStats {
  final String operationName;
  final int totalExecutions;
  final double averageTimeMs;
  final int minTimeMs;
  final int maxTimeMs;
  final int totalTimeMs;

  const OperationStats({
    required this.operationName,
    required this.totalExecutions,
    required this.averageTimeMs,
    required this.minTimeMs,
    required this.maxTimeMs,
    required this.totalTimeMs,
  });

  @override
  String toString() {
    return 'OperationStats(name: $operationName, executions: $totalExecutions, avg: ${averageTimeMs.toStringAsFixed(1)}ms)';
  }
}

/// Cache performance statistics
class CacheStats {
  final String cacheType;
  final int hits;
  final int misses;
  final double hitRate;

  const CacheStats({
    required this.cacheType,
    required this.hits,
    required this.misses,
    required this.hitRate,
  });

  @override
  String toString() {
    return 'CacheStats(type: $cacheType, hitRate: ${hitRate.toStringAsFixed(1)}%, hits: $hits, misses: $misses)';
  }
}

/// Memory usage snapshot
class MemorySnapshot {
  final String label;
  final DateTime timestamp;
  final double estimatedMemoryUsage; // in MB

  const MemorySnapshot({
    required this.label,
    required this.timestamp,
    required this.estimatedMemoryUsage,
  });

  @override
  String toString() {
    return 'MemorySnapshot(label: $label, usage: ${estimatedMemoryUsage}MB, time: $timestamp)';
  }
}

/// Complete performance report
class PerformanceReport {
  final List<OperationStats> operationStats;
  final List<CacheStats> cacheStats;
  final List<MemorySnapshot> memorySnapshots;
  final DateTime reportGeneratedAt;

  const PerformanceReport({
    required this.operationStats,
    required this.cacheStats,
    required this.memorySnapshots,
    required this.reportGeneratedAt,
  });

  @override
  String toString() {
    return 'PerformanceReport(operations: ${operationStats.length}, caches: ${cacheStats.length}, snapshots: ${memorySnapshots.length})';
  }
}
