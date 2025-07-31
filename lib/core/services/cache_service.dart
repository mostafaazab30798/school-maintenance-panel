import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration maxAge;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.maxAge,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > maxAge;

  bool get isNearExpiry {
    final elapsed = DateTime.now().difference(timestamp);
    return elapsed >
        Duration(milliseconds: (maxAge.inMilliseconds * 0.8).round());
  }
}

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Map<String, CacheEntry> _cache = {};
  final Map<String, Timer> _refreshTimers = {};
  final Map<String, List<VoidCallback>> _listeners = {};

  // Cache durations for different data types
  static const Duration _defaultCacheDuration = Duration(minutes: 3);
  static const Duration _reportsCacheDuration = Duration(minutes: 2);
  static const Duration _maintenanceCacheDuration = Duration(minutes: 2);
  static const Duration _dashboardCacheDuration = Duration(minutes: 1); // Reduced for faster refresh
  static const Duration _supervisorCacheDuration = Duration(minutes: 5); // Longer for stable data

  /// Get cached data if available and not expired
  T? getCached<T>(String key) {
    final entry = _cache[key] as CacheEntry<T>?;
    if (entry == null || entry.isExpired) {
      return null;
    }
    return entry.data;
  }

  /// Check if cached data exists and is valid
  bool isCached(String key) {
    final entry = _cache[key];
    return entry != null && !entry.isExpired;
  }

  /// Check if cached data is near expiry (80% of max age)
  bool isNearExpiry(String key) {
    final entry = _cache[key];
    return entry != null && entry.isNearExpiry;
  }

  /// Set cached data with automatic expiry
  void setCached<T>(String key, T data, {Duration? maxAge}) {
    final duration = maxAge ?? _getCacheDurationForKey(key);

    _cache[key] = CacheEntry<T>(
      data: data,
      timestamp: DateTime.now(),
      maxAge: duration,
    );

    // Cancel existing refresh timer
    _refreshTimers[key]?.cancel();

    // Set up auto-refresh timer at 90% of cache duration
    final refreshDelay =
        Duration(milliseconds: (duration.inMilliseconds * 0.9).round());
    _refreshTimers[key] = Timer(refreshDelay, () {
      _notifyNearExpiry(key);
    });

    // Notify listeners of data update
    _notifyListeners(key);

    if (kDebugMode) {
      print('CacheService: Cached $key for ${duration.inMinutes} minutes');
    }
  }

  /// Get cache duration based on key pattern
  Duration _getCacheDurationForKey(String key) {
    if (key.contains('reports')) return _reportsCacheDuration;
    if (key.contains('maintenance')) return _maintenanceCacheDuration;
    if (key.contains('dashboard')) return _dashboardCacheDuration;
    if (key.contains('supervisor')) return _supervisorCacheDuration;
    return _defaultCacheDuration;
  }

  /// Add listener for cache updates
  void addListener(String key, VoidCallback listener) {
    _listeners[key] ??= [];
    _listeners[key]!.add(listener);
  }

  /// Remove listener
  void removeListener(String key, VoidCallback listener) {
    _listeners[key]?.remove(listener);
    if (_listeners[key]?.isEmpty == true) {
      _listeners.remove(key);
    }
  }

  /// Notify listeners of cache updates
  void _notifyListeners(String key) {
    _listeners[key]?.forEach((listener) => listener());
  }

  /// Notify that cache is near expiry (for background refresh)
  void _notifyNearExpiry(String key) {
    if (kDebugMode) {
      print('CacheService: Cache near expiry for $key');
    }
    // This could trigger background refresh in the future
  }

  /// Invalidate specific cache entry
  void invalidate(String key) {
    _cache.remove(key);
    _refreshTimers[key]?.cancel();
    _refreshTimers.remove(key);

    if (kDebugMode) {
      print('CacheService: Invalidated cache for $key');
    }
  }

  /// Invalidate all cache entries matching pattern
  void invalidatePattern(String pattern) {
    final keysToRemove =
        _cache.keys.where((key) => key.contains(pattern)).toList();
    for (final key in keysToRemove) {
      invalidate(key);
    }
  }

  /// Clear all cache
  void clearAll() {
    _cache.clear();
    _refreshTimers.values.forEach((timer) => timer.cancel());
    _refreshTimers.clear();

    if (kDebugMode) {
      print('CacheService: Cleared all cache');
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    final now = DateTime.now();
    final stats = <String, dynamic>{};

    for (final entry in _cache.entries) {
      final cacheEntry = entry.value;
      final age = now.difference(cacheEntry.timestamp);
      stats[entry.key] = {
        'age_minutes': age.inMinutes,
        'max_age_minutes': cacheEntry.maxAge.inMinutes,
        'is_expired': cacheEntry.isExpired,
        'is_near_expiry': cacheEntry.isNearExpiry,
      };
    }

    return stats;
  }

  /// Preload cache with initial data
  void preload<T>(String key, T data, {Duration? maxAge}) {
    if (!isCached(key)) {
      setCached(key, data, maxAge: maxAge);
    }
  }

  void dispose() {
    _refreshTimers.values.forEach((timer) => timer.cancel());
    _refreshTimers.clear();
    _listeners.clear();
  }
}

// Cache keys constants for consistency
class CacheKeys {
  static const String allReports = 'all_reports';
  static const String allMaintenance = 'all_maintenance';
  static const String dashboardStats = 'dashboard_stats';
  static const String regularDashboardStats = 'regular_dashboard_stats';
  static const String supervisors = 'supervisors';
  static const String pendingReports = 'pending_reports';
  static const String completedReports = 'completed_reports';
  static const String pendingMaintenance = 'pending_maintenance';
  static const String completedMaintenance = 'completed_maintenance';

  // Dynamic keys
  static String reportsFiltered(String filter) => 'reports_filtered_$filter';
  static String maintenanceFiltered(String filter) =>
      'maintenance_filtered_$filter';
}
