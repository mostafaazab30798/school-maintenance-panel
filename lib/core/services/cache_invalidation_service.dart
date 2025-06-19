import 'package:flutter/foundation.dart';
import 'admin_service.dart';
import 'cache_service.dart';
import 'navigation/supervisor_navigation_service.dart';

/// Service to handle cache invalidation across different components
/// 
/// This service ensures that when critical data changes (like supervisor assignments),
/// all relevant caches are properly cleared to prevent stale data issues.
class CacheInvalidationService {
  static final CacheService _cacheService = CacheService();

  /// Invalidate all caches related to supervisor assignments
  /// 
  /// This should be called whenever:
  /// - A supervisor is assigned/unassigned to/from an admin
  /// - Supervisor data is modified
  /// - Admin data is modified
  static void invalidateSupervisorCaches() {
    if (kDebugMode) {
      debugPrint('CacheInvalidationService: Invalidating all supervisor-related caches');
    }

    // Clear AdminService supervisor cache (affects regular admin dashboard)
    AdminService.clearCache();
    
    // Clear navigation cache
    SupervisorNavigationService.clearCache();
    
    // Clear main dashboard caches
    _cacheService.invalidate(CacheKeys.dashboardStats); // Super admin
    _cacheService.invalidate(CacheKeys.regularDashboardStats); // Regular admin
    
    // Clear all report and maintenance caches since supervisor assignments affect data access
    _cacheService.invalidatePattern('reports');
    _cacheService.invalidatePattern('maintenance');
    _cacheService.invalidatePattern('supervisor');
    
    if (kDebugMode) {
      debugPrint('CacheInvalidationService: All supervisor-related caches cleared');
    }
  }

  /// Invalidate caches when report data changes
  static void invalidateReportCaches() {
    if (kDebugMode) {
      debugPrint('CacheInvalidationService: Invalidating report-related caches');
    }

    _cacheService.invalidatePattern('reports');
    _cacheService.invalidate(CacheKeys.dashboardStats);
    _cacheService.invalidate(CacheKeys.regularDashboardStats);
    SupervisorNavigationService.clearCache();
  }

  /// Invalidate caches when maintenance data changes
  static void invalidateMaintenanceCaches() {
    if (kDebugMode) {
      debugPrint('CacheInvalidationService: Invalidating maintenance-related caches');
    }

    _cacheService.invalidatePattern('maintenance');
    _cacheService.invalidate(CacheKeys.dashboardStats);
    _cacheService.invalidate(CacheKeys.regularDashboardStats);
    SupervisorNavigationService.clearCache();
  }

  /// Complete cache clear (for logout or major data changes)
  static void clearAllCaches() {
    if (kDebugMode) {
      debugPrint('CacheInvalidationService: Clearing all application caches');
    }

    AdminService.clearCache();
    SupervisorNavigationService.clearCache();
    _cacheService.clearAll();
  }
} 