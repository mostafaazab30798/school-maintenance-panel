import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../cache_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for handling supervisor-related navigation and data preloading
class SupervisorNavigationService {
  static final CacheService _cacheService = CacheService();

  /// Navigate to all reports with optional preloading
  static void navigateToAllReports(BuildContext context,
      {bool preload = true}) {
    if (preload) _preloadAllReportsData();
    context.push('/all-reports');
  }

  /// Navigate to completed reports with preloading
  static void navigateToCompletedReports(BuildContext context) {
    _preloadAllReportsData();
    context.push('/all-reports?filter=completed');
  }

  /// Navigate to all maintenance with preloading
  static void navigateToAllMaintenance(BuildContext context) {
    _preloadMaintenanceData();
    context.push('/all-maintenance');
  }

  /// Navigate to supervisor-specific reports
  static void navigateToSupervisorReports(
    BuildContext context,
    String supervisorId,
    String supervisorName,
  ) {
    _preloadReportsData();
    context.push(
        '/all-reports?supervisor_id=$supervisorId&supervisor_name=$supervisorName');
  }

  /// Navigate to supervisor-specific maintenance
  static void navigateToSupervisorMaintenance(
    BuildContext context,
    String supervisorId,
    String supervisorName,
  ) {
    _preloadMaintenanceData();
    context.push(
        '/all-maintenance?supervisor_id=$supervisorId&supervisor_name=$supervisorName');
  }

  /// Navigate to supervisor completed work (both reports and maintenance)
  static void navigateToSupervisorCompleted(
    BuildContext context,
    String supervisorId,
    String supervisorName,
  ) {
    _preloadReportsData();
    _preloadMaintenanceData();
    context.push(
        '/all-reports?supervisor_id=$supervisorId&supervisor_name=$supervisorName&filter=completed');
  }

  /// Navigate to supervisor late reports
  static void navigateToSupervisorLateReports(
    BuildContext context,
    String supervisorId,
    String supervisorName,
  ) {
    _preloadReportsData();
    context.push(
        '/all-reports?supervisor_id=$supervisorId&supervisor_name=$supervisorName&filter=late');
  }

  /// Navigate to supervisor late completed reports
  static void navigateToSupervisorLateCompleted(
    BuildContext context,
    String supervisorId,
    String supervisorName,
  ) {
    _preloadReportsData();
    context.push(
        '/all-reports?supervisor_id=$supervisorId&supervisor_name=$supervisorName&filter=late_completed');
  }

  /// Navigate to supervisors list
  static void navigateToSupervisorsList(BuildContext context) {
    context.push('/supervisors-list');
  }

  /// Navigate to admins list
  static void navigateToAdminsList(BuildContext context) {
    context.push('/admins-list');
  }

  /// Preload reports data for faster navigation
  static Future<void> _preloadReportsData() async {
    // Only preload if cache is empty or expired
    if (!_cacheService.isCached(CacheKeys.allReports)) {
      try {
        final response = await Supabase.instance.client
            .from('reports')
            .select('*, supervisors(username)')
            .order('created_at', ascending: false);

        final reportsData = List<Map<String, dynamic>>.from(response);
        _cacheService.setCached(CacheKeys.allReports, reportsData);

        debugPrint(
            'NavigationService: Preloaded ${reportsData.length} reports');
      } catch (e) {
        debugPrint('NavigationService: Failed to preload reports: $e');
      }
    }
  }

  /// Preload all reports data specifically for "all reports" navigation
  static Future<void> _preloadAllReportsData() async {
    // Force refresh to ensure we get all reports, not supervisor-specific cached data
    try {
      final response = await Supabase.instance.client
          .from('reports')
          .select('*, supervisors(username)')
          .order('created_at', ascending: false);

      final reportsData = List<Map<String, dynamic>>.from(response);
      _cacheService.setCached(CacheKeys.allReports, reportsData);

      debugPrint(
          'NavigationService: Preloaded ${reportsData.length} all reports');
    } catch (e) {
      debugPrint('NavigationService: Failed to preload all reports: $e');
    }
  }

  /// Preload maintenance data for faster navigation
  static Future<void> _preloadMaintenanceData() async {
    // Only preload if cache is empty or expired
    if (!_cacheService.isCached(CacheKeys.allMaintenance)) {
      try {
        final response = await Supabase.instance.client
            .from('maintenance_reports')
            .select('*, supervisors(username)')
            .order('created_at', ascending: false);

        final maintenanceData = List<Map<String, dynamic>>.from(response);
        _cacheService.setCached(CacheKeys.allMaintenance, maintenanceData);

        debugPrint(
            'NavigationService: Preloaded ${maintenanceData.length} maintenance reports');
      } catch (e) {
        debugPrint('NavigationService: Failed to preload maintenance: $e');
      }
    }
  }

  /// Preload all frequently accessed data in the background
  static Future<void> preloadAllData() async {
    try {
      // Preload reports data
      if (!_cacheService.isCached(CacheKeys.allReports)) {
        final reportsResponse = await Supabase.instance.client
            .from('reports')
            .select('*, supervisors(username)')
            .order('created_at', ascending: false);

        final reportsData = List<Map<String, dynamic>>.from(reportsResponse);
        _cacheService.setCached(CacheKeys.allReports, reportsData);
        debugPrint(
            'NavigationService: Background preloaded ${reportsData.length} reports');
      }

      // Preload maintenance data
      if (!_cacheService.isCached(CacheKeys.allMaintenance)) {
        final maintenanceResponse = await Supabase.instance.client
            .from('maintenance_reports')
            .select('*, supervisors(username)')
            .order('created_at', ascending: false);

        final maintenanceData =
            List<Map<String, dynamic>>.from(maintenanceResponse);
        _cacheService.setCached(CacheKeys.allMaintenance, maintenanceData);
        debugPrint(
            'NavigationService: Background preloaded ${maintenanceData.length} maintenance reports');
      }

      debugPrint('NavigationService: Background preloading completed');
    } catch (e) {
      debugPrint('NavigationService: Background preloading failed: $e');
    }
  }

  /// Check if data is loaded from cache
  static bool isDataLoadedFromCache() {
    return _cacheService.isCached(CacheKeys.dashboardStats);
  }

  /// Clear all navigation-related cache
  static void clearCache() {
    _cacheService.invalidate(CacheKeys.allReports);
    _cacheService.invalidate(CacheKeys.allMaintenance);

    // Clear supervisor-specific cache keys
    _cacheService.invalidatePattern('${CacheKeys.allReports}_supervisor_');
    _cacheService.invalidatePattern('${CacheKeys.allMaintenance}_supervisor_');

    debugPrint('NavigationService: Cache cleared');
  }
}
