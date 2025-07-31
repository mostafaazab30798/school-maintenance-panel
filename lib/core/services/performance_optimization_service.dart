import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 🚀 Performance optimization service for dashboard and other heavy operations
class PerformanceOptimizationService {
  static final PerformanceOptimizationService _instance = PerformanceOptimizationService._internal();
  factory PerformanceOptimizationService() => _instance;
  PerformanceOptimizationService._internal();

  // Cache for expensive operations
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// 🚀 PERFORMANCE OPTIMIZATION: Get schools count for supervisors with optimized caching
  Future<Map<String, int>> getSupervisorsSchoolsCountOptimized(List<String> supervisorIds) async {
    if (supervisorIds.isEmpty) return {};
    
    final cacheKey = 'supervisors_schools_count_${supervisorIds.join('_')}';
    
    // Check cache first
    if (_isCacheValid(cacheKey)) {
      if (kDebugMode) {
        print('⚡ PerformanceOptimizationService: Cached schools count for ${supervisorIds.length} supervisors');
      }
      return _cache[cacheKey] as Map<String, int>;
    }
    
    try {
      // 🚀 PERFORMANCE OPTIMIZATION: Use single query for all supervisors
      final response = await Supabase.instance.client
          .from('supervisor_schools')
          .select('supervisor_id')
          .inFilter('supervisor_id', supervisorIds);
      
      // Count schools per supervisor
      final Map<String, int> schoolsCount = {};
      for (final supervisorId in supervisorIds) {
        schoolsCount[supervisorId] = response
            .where((item) => item['supervisor_id'] == supervisorId)
            .length;
      }
      
      // Cache the result
      _cache[cacheKey] = schoolsCount;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      if (kDebugMode) {
        print('⚡ PerformanceOptimizationService: Cached schools count for ${supervisorIds.length} supervisors');
      }
      
      return schoolsCount;
    } catch (e) {
      if (kDebugMode) {
        print('❌ PerformanceOptimizationService: Error getting schools count: $e');
      }
      // Return empty map on error
      return {for (final id in supervisorIds) id: 0};
    }
  }

  /// 🚀 PERFORMANCE OPTIMIZATION: Get schools with achievements using optimized query
  Future<int> getSchoolsWithAchievementsOptimized(Set<String> schoolIds) async {
    if (schoolIds.isEmpty) return 0;
    
    final cacheKey = 'schools_achievements_${schoolIds.length}';
    
    // Check cache first
    if (_isCacheValid(cacheKey)) {
      if (kDebugMode) {
        print('⚡ PerformanceOptimizationService: Cached schools achievements count: ${_cache[cacheKey]}');
      }
      return _cache[cacheKey] as int;
    }
    
    try {
      // 🚀 PERFORMANCE OPTIMIZATION: Use optimized query for achievements
      final response = await Supabase.instance.client
          .from('achievement_photos')
          .select('school_id')
          .inFilter('school_id', schoolIds.toList())
          .not('school_id', 'is', null);
      
      final schoolsWithAchievements = response.map((item) => item['school_id']).toSet().length;
      
      // Cache the result
      _cache[cacheKey] = schoolsWithAchievements;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      if (kDebugMode) {
        print('⚡ PerformanceOptimizationService: Cached schools achievements count: $schoolsWithAchievements');
      }
      
      return schoolsWithAchievements;
    } catch (e) {
      if (kDebugMode) {
        print('❌ PerformanceOptimizationService: Error getting schools achievements: $e');
      }
      return 0;
    }
  }

  /// 🚀 Clear all cached data
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    if (kDebugMode) {
      debugPrint('🧹 PerformanceOptimizationService: Cache cleared');
    }
  }

  /// 🚀 Clear specific cache entry
  void clearCacheEntry(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
    if (kDebugMode) {
      debugPrint('🧹 PerformanceOptimizationService: Cleared cache entry: $key');
    }
  }

  /// Check if cache is still valid
  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    
    final isExpired = DateTime.now().difference(timestamp) > _cacheExpiry;
    if (isExpired) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
    
    return !isExpired;
  }

  /// 🚀 Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'totalEntries': _cache.length,
      'cacheKeys': _cache.keys.toList(),
      'timestamps': _cacheTimestamps.map((key, value) => MapEntry(key, value.toIso8601String())),
    };
  }

  /// 🚀 Get database optimization suggestions (for performance monitor widget)
  List<String> getDatabaseOptimizationSuggestions() {
    return [
      '🚀 Database Index Recommendations:',
      '  - CREATE INDEX idx_reports_supervisor_id ON reports(supervisor_id);',
      '  - CREATE INDEX idx_reports_status ON reports(status);',
      '  - CREATE INDEX idx_reports_created_at ON reports(created_at DESC);',
      '  - CREATE INDEX idx_supervisor_schools_supervisor_id ON supervisor_schools(supervisor_id);',
      '  - CREATE INDEX idx_maintenance_reports_supervisor_id ON maintenance_reports(supervisor_id);',
      '',
      '🚀 Query Optimization Tips:',
      '  - Use selective column fetching instead of SELECT *',
      '  - Implement proper pagination with LIMIT and OFFSET',
      '  - Consider materialized views for complex aggregations',
      '  - Use database connection pooling',
      '  - Monitor query execution plans',
    ];
  }
} 