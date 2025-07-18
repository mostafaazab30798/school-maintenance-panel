import 'package:flutter/foundation.dart';
import 'performance_monitoring_service.dart';
import 'cache_service.dart';

/// Performance optimization service for improving application performance
class PerformanceOptimizationService {
  static final PerformanceOptimizationService _instance =
      PerformanceOptimizationService._internal();
  factory PerformanceOptimizationService() => _instance;
  PerformanceOptimizationService._internal();

  final PerformanceMonitoringService _performanceService = PerformanceMonitoringService();
  final CacheService _cacheService = CacheService();

  /// Optimize repository queries based on performance metrics
  Map<String, dynamic> getQueryOptimizationSuggestions() {
    final metrics = _performanceService.getAllMetrics();
    final suggestions = <String, List<String>>{};

    for (final entry in metrics.entries) {
      final operationName = entry.key;
      final metric = entry.value;
      final suggestionsForOperation = <String>[];

      // Check for slow operations
      if (metric.averageDuration.inMilliseconds > 500) {
        suggestionsForOperation.add('Consider implementing pagination');
        suggestionsForOperation.add('Review database indexes');
        suggestionsForOperation.add('Optimize query filters');
      }

      // Check for low success rates
      if (metric.successRate < 0.95) {
        suggestionsForOperation.add('Review error handling');
        suggestionsForOperation.add('Check network connectivity');
        suggestionsForOperation.add('Validate query parameters');
      }

      // Check for high execution counts (potential over-fetching)
      if (metric.executionCount > 100) {
        suggestionsForOperation.add('Implement better caching strategy');
        suggestionsForOperation.add('Consider background refresh');
        suggestionsForOperation.add('Review cache invalidation logic');
      }

      if (suggestionsForOperation.isNotEmpty) {
        suggestions[operationName] = suggestionsForOperation;
      }
    }

    return suggestions;
  }

  /// Get cache performance recommendations
  Map<String, dynamic> getCacheOptimizationSuggestions() {
    final cacheMetrics = _performanceService.getCacheMetrics();
    final suggestions = <String, List<String>>{};

    for (final entry in cacheMetrics.entries) {
      final source = entry.key;
      final metrics = entry.value;
      final suggestionsForSource = <String>[];

      // Check for low hit rates
      if (metrics.hitRate < 0.5) {
        suggestionsForSource.add('Increase cache TTL');
        suggestionsForSource.add('Review cache key generation');
        suggestionsForSource.add('Consider pre-warming cache');
      }

      // Check for high miss rates
      if (metrics.misses > metrics.hits * 2) {
        suggestionsForSource.add('Optimize cache invalidation');
        suggestionsForSource.add('Review cache size limits');
        suggestionsForSource.add('Consider cache warming strategies');
      }

      if (suggestionsForSource.isNotEmpty) {
        suggestions[source] = suggestionsForSource;
      }
    }

    return suggestions;
  }

  /// Generate performance report with optimization recommendations
  Map<String, dynamic> generatePerformanceReport() {
    final querySuggestions = getQueryOptimizationSuggestions();
    final cacheSuggestions = getCacheOptimizationSuggestions();
    final metrics = _performanceService.getAllMetrics();
    final cacheMetrics = _performanceService.getCacheMetrics();

    // Calculate overall performance score
    double overallScore = 0.0;
    int totalOperations = 0;

    for (final metric in metrics.values) {
      final operationScore = _calculateOperationScore(metric);
      overallScore += operationScore;
      totalOperations++;
    }

    final averageScore = totalOperations > 0 ? overallScore / totalOperations : 0.0;

    return {
      'timestamp': DateTime.now().toIso8601String(),
      'overallScore': averageScore,
      'totalOperations': totalOperations,
      'metrics': metrics.map((key, value) => MapEntry(key, value.toJson())),
      'cacheMetrics': cacheMetrics.map((key, value) => MapEntry(key, value.toJson())),
      'queryOptimizations': querySuggestions,
      'cacheOptimizations': cacheSuggestions,
      'recommendations': _generateOverallRecommendations(metrics, cacheMetrics),
    };
  }

  /// Calculate performance score for an operation
  double _calculateOperationScore(PerformanceMetric metric) {
    double score = 1.0;

    // Deduct points for slow operations
    if (metric.averageDuration.inMilliseconds > 1000) {
      score -= 0.3;
    } else if (metric.averageDuration.inMilliseconds > 500) {
      score -= 0.2;
    } else if (metric.averageDuration.inMilliseconds > 300) {
      score -= 0.1;
    }

    // Deduct points for low success rates
    if (metric.successRate < 0.9) {
      score -= 0.3;
    } else if (metric.successRate < 0.95) {
      score -= 0.1;
    }

    // Bonus for high success rates and fast operations
    if (metric.successRate > 0.98 && metric.averageDuration.inMilliseconds < 200) {
      score += 0.1;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Generate overall performance recommendations
  List<String> _generateOverallRecommendations(
    Map<String, PerformanceMetric> metrics,
    Map<String, CacheMetrics> cacheMetrics,
  ) {
    final recommendations = <String>[];

    // Check for overall slow operations
    final slowOperations = metrics.values
        .where((metric) => metric.averageDuration.inMilliseconds > 500)
        .length;
    if (slowOperations > 0) {
      recommendations.add('Found $slowOperations slow operations - consider database optimization');
    }

    // Check for low cache hit rates
    final lowHitRateSources = cacheMetrics.values
        .where((metric) => metric.hitRate < 0.5)
        .length;
    if (lowHitRateSources > 0) {
      recommendations.add('Found $lowHitRateSources cache sources with low hit rates - review caching strategy');
    }

    // Check for high error rates
    final highErrorOperations = metrics.values
        .where((metric) => metric.successRate < 0.9)
        .length;
    if (highErrorOperations > 0) {
      recommendations.add('Found $highErrorOperations operations with high error rates - review error handling');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Performance is within acceptable ranges');
    }

    return recommendations;
  }

  /// Optimize cache settings based on usage patterns
  void optimizeCacheSettings() {
    final cacheMetrics = _performanceService.getCacheMetrics();
    
    for (final entry in cacheMetrics.entries) {
      final source = entry.key;
      final metrics = entry.value;

      if (metrics.hitRate < 0.3) {
        // Low hit rate - clear cache to force fresh data
        _cacheService.invalidatePattern(source);
        if (kDebugMode) {
          debugPrint('PerformanceOptimization: Cleared cache for $source due to low hit rate');
        }
      } else if (metrics.hitRate > 0.8) {
        // High hit rate - could optimize cache invalidation
        if (kDebugMode) {
          debugPrint('PerformanceOptimization: High hit rate for $source - consider optimizing cache strategy');
        }
      }
    }
  }

  /// Clear performance data and reset metrics
  void resetPerformanceData() {
    // This would need to be implemented in PerformanceMonitoringService
    if (kDebugMode) {
      debugPrint('PerformanceOptimization: Performance data reset requested');
    }
  }

  /// Log performance summary for debugging
  void logPerformanceSummary() {
    if (!kDebugMode) return;

    final report = generatePerformanceReport();
    
    debugPrint('=== PERFORMANCE OPTIMIZATION SUMMARY ===');
    debugPrint('Overall Score: ${(report['overallScore'] as double).toStringAsFixed(2)}');
    debugPrint('Total Operations: ${report['totalOperations']}');
    
    final recommendations = report['recommendations'] as List<String>;
    if (recommendations.isNotEmpty) {
      debugPrint('Recommendations:');
      for (final recommendation in recommendations) {
        debugPrint('  - $recommendation');
      }
    }
    
    debugPrint('=== END SUMMARY ===');
  }
} 