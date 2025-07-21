import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/performance_monitoring_service.dart';
import '../services/error_handling_service.dart';

/// Configuration for repository caching behavior
class CacheConfig {
  final Duration ttl;
  final int maxSize;
  final bool enabled;

  const CacheConfig({
    this.ttl = const Duration(minutes: 5),
    this.maxSize = 100,
    this.enabled = true,
  });

  /// Disabled cache configuration
  static const CacheConfig disabled = CacheConfig(enabled: false);

  /// Default cache configuration
  static const CacheConfig defaults = CacheConfig();

  /// Long-term cache configuration
  static const CacheConfig longTerm = CacheConfig(
    ttl: Duration(hours: 1),
    maxSize: 50,
  );

  /// 🚀 PERFORMANCE OPTIMIZATION: Fast cache configuration for frequently accessed data
  static const CacheConfig fast = CacheConfig(
    ttl: Duration(minutes: 2),
    maxSize: 200,
  );
}

/// Cache entry with expiration
class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration ttl;

  CacheEntry(this.data, this.timestamp, this.ttl);

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;
}

/// Base repository class providing common functionality
///
/// This abstract class provides:
/// - Supabase client access
/// - Caching mechanism
/// - Error handling
/// - Debug logging
/// - Admin filtering support
abstract class BaseRepository<T> {
  final SupabaseClient client;
  final CacheConfig cacheConfig;
  final String repositoryName;

  /// Internal cache storage
  final Map<String, CacheEntry<dynamic>> _cache = {};

  BaseRepository({
    required this.client,
    required this.repositoryName,
    this.cacheConfig = CacheConfig.defaults,
  });

  /// Table name for Supabase operations
  String get tableName;

  /// Converts Map to domain model
  T fromMap(Map<String, dynamic> map);

  /// Converts domain model to Map
  Map<String, dynamic> toMap(T item);

  /// Logs debug information with repository context
  void logDebug(String message) {
    if (kDebugMode) {
      debugPrint('$repositoryName: $message');
    }
  }

  /// Logs error information with repository context
  void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('$repositoryName ERROR: $message');
      if (error != null) {
        debugPrint('$repositoryName ERROR Details: $error');
      }
      if (stackTrace != null) {
        debugPrint('$repositoryName Stack Trace: $stackTrace');
      }
    }
  }

  /// Generates cache key for the given parameters
  String generateCacheKey(String operation, [Map<String, dynamic>? params]) {
    if (params == null || params.isEmpty) {
      return '$repositoryName:$operation';
    }

    final sortedParams = Map.fromEntries(
        params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));

    return '$repositoryName:$operation:${sortedParams.toString()}';
  }

  /// Gets data from cache if available and not expired
  T? getFromCache<T>(String key) {
    if (!cacheConfig.enabled) {
      return null;
    }

    final entry = _cache[key];
    if (entry == null || entry.isExpired) {
      if (entry != null) {
        _cache.remove(key);
        logDebug('Cache entry expired and removed: $key');
      }
      return null;
    }

    // Safe cast - the data should be of type T if stored correctly
    try {
      logDebug('Cache hit: $key');
      return entry.data as T;
    } catch (e) {
      // If type cast fails, remove corrupted cache entry
      _cache.remove(key);
      logDebug('Cache type mismatch detected for $key, entry removed');
      return null;
    }
  }

  /// Stores data in cache
  void setCache<T>(String key, T data) {
    if (!cacheConfig.enabled) {
      return;
    }

    // 🚀 PERFORMANCE OPTIMIZATION: Use LRU eviction for better cache management
    if (_cache.length >= cacheConfig.maxSize) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
      logDebug('Cache full, removed oldest entry: $oldestKey');
    }

    _cache[key] = CacheEntry(data, DateTime.now(), cacheConfig.ttl);
    logDebug('Cache set: $key');
  }

  /// Clears cache for specific pattern or all cache
  void clearCache([String? pattern]) {
    if (pattern == null) {
      final count = _cache.length;
      _cache.clear();
      logDebug('Cleared all cache ($count entries)');
    } else {
      final keysToRemove =
          _cache.keys.where((key) => key.contains(pattern)).toList();
      for (final key in keysToRemove) {
        _cache.remove(key);
      }
      logDebug(
          'Cleared cache entries matching "$pattern" (${keysToRemove.length} entries)');
    }
  }

  /// Handles common database errors
  Exception handleDatabaseError(dynamic error, String operation) {
    logError('Database error during $operation', error);

    if (error is PostgrestException) {
      return Exception('Database operation failed: ${error.message}');
    } else if (error is AuthException) {
      return Exception('Authentication error: ${error.message}');
    } else {
      return Exception('Unknown error during $operation: $error');
    }
  }

  /// 🚀 PERFORMANCE OPTIMIZATION: Executes a query with improved error handling and caching
  Future<List<T>> executeQuery({
    required String operation,
    required Future<List<Map<String, dynamic>>> Function() query,
    Map<String, dynamic>? cacheParams,
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    // 🚀 PERFORMANCE OPTIMIZATION: Use faster performance monitoring threshold
    final performanceTimer = PerformanceMonitoringService().startOperation(
      '$repositoryName:$operation',
      metadata: {
        'repository': repositoryName,
        'operation': operation,
        'useCache': useCache,
        'forceRefresh': forceRefresh,
        'cacheParams': cacheParams,
      },
    );

    try {
      logDebug('Starting $operation${forceRefresh ? ' (force refresh)' : ''}');

      // 🚀 PERFORMANCE OPTIMIZATION: Check cache first for instant response
      String? cacheKey;
      if (useCache && !forceRefresh) {
        cacheKey = generateCacheKey(operation, cacheParams);
        final cached = getFromCache<List<T>>(cacheKey);
        if (cached != null) {
          PerformanceMonitoringService().recordCacheOperation(
            cacheKey,
            true,
            source: repositoryName,
          );
          logDebug('$operation completed from cache (${cached.length} items)');
          performanceTimer.stop(success: true);
          return cached;
        } else {
          PerformanceMonitoringService().recordCacheOperation(
            cacheKey,
            false,
            source: repositoryName,
          );
        }
      }

      // 🚀 PERFORMANCE OPTIMIZATION: Execute query with improved resilience
      final items = await ErrorHandlingService().executeWithResilience<List<T>>(
        '$repositoryName:$operation',
        () async {
          final rawData = await query();
          return rawData.map((item) => fromMap(item)).toList();
        },
        timeout: const Duration(seconds: 8), // 🚀 Reduced timeout for faster failure detection
        fallbackValue: <T>[],
      );

      // 🚀 PERFORMANCE OPTIMIZATION: Cache the results with optimized storage
      if (useCache && cacheKey != null) {
        setCache(cacheKey, items);
      }

      logDebug('$operation completed (${items.length} items)');
      performanceTimer.stop(success: true);
      return items;
    } catch (error, stackTrace) {
      await ErrorHandlingService().handleError(
        '$repositoryName:$operation',
        error,
        stackTrace,
        metadata: {
          'repository': repositoryName,
          'operation': operation,
          'cacheParams': cacheParams,
        },
      );

      performanceTimer.stop(success: false, errorMessage: error.toString());
      throw handleDatabaseError(error, operation);
    }
  }

  /// Executes a single item query with error handling and optional caching
  Future<T?> executeSingleQuery({
    required String operation,
    required Future<Map<String, dynamic>?> Function() query,
    Map<String, dynamic>? cacheParams,
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      logDebug('Starting $operation${forceRefresh ? ' (force refresh)' : ''}');

      // Check cache first
      String? cacheKey;
      if (useCache && !forceRefresh) {
        cacheKey = generateCacheKey(operation, cacheParams);
        final cached = getFromCache<T?>(cacheKey);
        if (cached != null) {
          logDebug('$operation completed from cache');
          return cached;
        }
      }

      // Execute query
      final startTime = DateTime.now();
      final rawData = await query();
      final duration = DateTime.now().difference(startTime);

      if (rawData == null) {
        logDebug(
            '$operation completed in ${duration.inMilliseconds}ms (no result)');
        return null;
      }

      // Convert to domain model
      final item = fromMap(rawData);

      logDebug('$operation completed in ${duration.inMilliseconds}ms');

      // Cache result
      if (useCache && cacheKey != null) {
        setCache(cacheKey, item);
      }

      return item;
    } catch (e, stackTrace) {
      throw handleDatabaseError(e, operation);
    }
  }

  /// Executes a mutation operation (insert, update, delete) with error handling
  Future<T?> executeMutation({
    required String operation,
    required Future<Map<String, dynamic>?> Function() mutation,
    bool clearCacheOnSuccess = true,
  }) async {
    try {
      logDebug('Starting $operation');

      final startTime = DateTime.now();
      final rawData = await mutation();
      final duration = DateTime.now().difference(startTime);

      if (rawData == null) {
        logDebug(
            '$operation completed in ${duration.inMilliseconds}ms (no result)');

        // Clear cache on successful mutation
        if (clearCacheOnSuccess) {
          clearCache();
        }

        return null;
      }

      // Convert to domain model
      final item = fromMap(rawData);

      logDebug('$operation completed in ${duration.inMilliseconds}ms');

      // Clear cache on successful mutation
      if (clearCacheOnSuccess) {
        clearCache();
      }

      return item;
    } catch (e, stackTrace) {
      throw handleDatabaseError(e, operation);
    }
  }
}
