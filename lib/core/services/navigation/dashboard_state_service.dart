import 'package:flutter/material.dart';
import '../cache_service.dart';
import 'supervisor_navigation_service.dart';

/// Service for managing dashboard state and cache lifecycle
class DashboardStateService {
  static final CacheService _cacheService = CacheService();
  
  // State tracking
  static bool _hasPreloadedData = false;
  static bool _isLoadedFromCache = false;

  /// Initialize dashboard state and start background preloading
  static void initializeDashboard() {
    // Check if dashboard data is loaded from cache
    _checkIfLoadedFromCache();
    
    // Start preloading data in the background after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _preloadAllData();
    });
  }

  /// Check if data is loaded from cache
  static void _checkIfLoadedFromCache() {
    _isLoadedFromCache = _cacheService.isCached(CacheKeys.dashboardStats);
  }

  /// Get cache loading status
  static bool get isLoadedFromCache => _isLoadedFromCache;

  /// Get preload completion status
  static bool get hasPreloadedData => _hasPreloadedData;

  /// Preload all frequently accessed data in the background
  static Future<void> _preloadAllData() async {
    if (_hasPreloadedData) return;

    try {
      // Use the navigation service's preload method
      await SupervisorNavigationService.preloadAllData();
      _hasPreloadedData = true;
    } catch (e) {
      debugPrint('DashboardStateService: Background preloading failed: $e');
    }
  }

  /// Force refresh all cached data
  static Future<void> forceRefreshData() async {
    SupervisorNavigationService.clearCache();
    _hasPreloadedData = false;
    _isLoadedFromCache = false;
    await _preloadAllData();
  }

  /// Update cache loading status when state changes
  static void updateCacheStatus() {
    _checkIfLoadedFromCache();
  }

  /// Reset dashboard state
  static void resetState() {
    _hasPreloadedData = false;
    _isLoadedFromCache = false;
  }

  /// Get dashboard cache statistics
  static Map<String, dynamic> getCacheStats() {
    return _cacheService.getStats();
  }

  /// Check if any critical cache is near expiry
  static bool isCacheNearExpiry() {
    return _cacheService.isNearExpiry(CacheKeys.allReports) ||
           _cacheService.isNearExpiry(CacheKeys.allMaintenance) ||
           _cacheService.isNearExpiry(CacheKeys.dashboardStats);
  }

  /// Dispose resources when dashboard is destroyed
  static void dispose() {
    resetState();
  }
} 