import 'package:flutter/foundation.dart';
import 'lib/core/services/performance_monitoring_service.dart';

/// Simple performance test to measure dashboard loading improvements
class PerformanceTest {
  static final PerformanceMonitoringService _performanceService = PerformanceMonitoringService();

  /// Test dashboard loading performance
  static Future<void> testDashboardLoading() async {
    print('🚀 Starting Dashboard Performance Test...');
    
    final stopwatch = Stopwatch()..start();
    
    // Simulate dashboard loading operations
    await _testMaintenanceReportsLoading();
    await _testReportsLoading();
    await _testSupervisorsLoading();
    
    stopwatch.stop();
    
    print('✅ Dashboard loading test completed in ${stopwatch.elapsedMilliseconds}ms');
    
    // Get performance metrics
    final metrics = _performanceService.getAllMetrics();
    final cacheMetrics = _performanceService.getCacheMetrics();
    
    print('\n📊 Performance Metrics:');
    for (final entry in metrics.entries) {
      final metric = entry.value;
      final isSlow = metric.averageDuration.inMilliseconds > 300;
      final status = isSlow ? '⚠️ SLOW' : '✅ GOOD';
      
      print('  $status ${entry.key}:');
      print('    - Average: ${metric.averageDuration.inMilliseconds}ms');
      print('    - Success Rate: ${(metric.successRate * 100).toStringAsFixed(1)}%');
      print('    - Executions: ${metric.executionCount}');
    }
    
    print('\n💾 Cache Performance:');
    for (final entry in cacheMetrics.entries) {
      final metrics = entry.value;
      final hitRate = metrics.hitRate;
      final status = hitRate > 0.7 ? '✅ GOOD' : '⚠️ LOW';
      
      print('  $status ${entry.key}:');
      print('    - Hit Rate: ${(hitRate * 100).toStringAsFixed(1)}%');
      print('    - Hits: ${metrics.hits}');
      print('    - Misses: ${metrics.misses}');
    }
  }

  static Future<void> _testMaintenanceReportsLoading() async {
    final timer = _performanceService.startOperation('test_maintenance_reports');
    
    // Simulate maintenance reports loading
    await Future.delayed(const Duration(milliseconds: 100));
    
    timer.stop(success: true);
  }

  static Future<void> _testReportsLoading() async {
    final timer = _performanceService.startOperation('test_reports_loading');
    
    // Simulate reports loading
    await Future.delayed(const Duration(milliseconds: 150));
    
    timer.stop(success: true);
  }

  static Future<void> _testSupervisorsLoading() async {
    final timer = _performanceService.startOperation('test_supervisors_loading');
    
    // Simulate supervisors loading
    await Future.delayed(const Duration(milliseconds: 80));
    
    timer.stop(success: true);
  }

  /// Compare performance before and after optimizations
  static void comparePerformance({
    required int beforeTime,
    required int afterTime,
  }) {
    final improvement = beforeTime - afterTime;
    final percentage = (improvement / beforeTime * 100);
    
    print('\n📈 Performance Comparison:');
    print('  Before: ${beforeTime}ms');
    print('  After:  ${afterTime}ms');
    print('  Improvement: ${improvement}ms (${percentage.toStringAsFixed(1)}%)');
    
    if (percentage >= 50) {
      print('  🎉 Excellent improvement!');
    } else if (percentage >= 30) {
      print('  ✅ Good improvement!');
    } else if (percentage >= 10) {
      print('  ⚠️ Moderate improvement');
    } else {
      print('  ❌ Minimal improvement - consider additional optimizations');
    }
  }

  /// Generate optimization recommendations
  static void generateRecommendations() {
    print('\n🔧 Optimization Recommendations:');
    
    final metrics = _performanceService.getAllMetrics();
    
    for (final entry in metrics.entries) {
      final metric = entry.value;
      
      if (metric.averageDuration.inMilliseconds > 500) {
        print('  ⚠️ ${entry.key}:');
        print('    - Consider implementing pagination');
        print('    - Review database indexes');
        print('    - Optimize query filters');
        print('    - Use selective column fetching');
      } else if (metric.averageDuration.inMilliseconds > 300) {
        print('  📝 ${entry.key}:');
        print('    - Monitor for degradation');
        print('    - Consider caching strategies');
      }
    }
    
    final cacheMetrics = _performanceService.getCacheMetrics();
    for (final entry in cacheMetrics.entries) {
      final metrics = entry.value;
      
      if (metrics.hitRate < 0.5) {
        print('  💾 ${entry.key}:');
        print('    - Increase cache TTL');
        print('    - Review cache invalidation strategy');
        print('    - Consider cache warming');
      }
    }
  }
}

/// Usage example:
/// 
/// ```dart
/// // Run performance test
/// await PerformanceTest.testDashboardLoading();
/// 
/// // Compare before/after
/// PerformanceTest.comparePerformance(
///   beforeTime: 631,
///   afterTime: 250,
/// );
/// 
/// // Get recommendations
/// PerformanceTest.generateRecommendations();
/// ``` 