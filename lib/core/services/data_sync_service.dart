import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cache_service.dart';

class DataSyncService {
  static final DataSyncService _instance = DataSyncService._internal();
  factory DataSyncService() => _instance;
  DataSyncService._internal();

  final CacheService _cacheService = CacheService();
  late final SupabaseClient _supabase;
  bool _isListening = false;

  void initialize() {
    _supabase = Supabase.instance.client;
    _startRealtimeListening();
  }

  void _startRealtimeListening() {
    if (_isListening) return;

    // Listen for changes in reports table
    _supabase
        .channel('reports_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'reports',
          callback: (payload) {
            _handleReportsChange(payload);
          },
        )
        .subscribe();

    // Listen for changes in maintenance_reports table
    _supabase
        .channel('maintenance_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'maintenance_reports',
          callback: (payload) {
            _handleMaintenanceChange(payload);
          },
        )
        .subscribe();

    _isListening = true;

    if (kDebugMode) {
      print('DataSyncService: Started realtime listening');
    }
  }

  void _handleReportsChange(PostgresChangePayload payload) {
    if (kDebugMode) {
      print('DataSyncService: Reports change detected - ${payload.eventType}');
    }

    // Invalidate reports cache when data changes
    _cacheService.invalidatePattern('reports');

    // Optionally, fetch fresh data in background for immediate update
    _refreshReportsCache();
  }

  void _handleMaintenanceChange(PostgresChangePayload payload) {
    if (kDebugMode) {
      print(
          'DataSyncService: Maintenance change detected - ${payload.eventType}');
    }

    // Invalidate maintenance cache when data changes
    _cacheService.invalidatePattern('maintenance');

    // Optionally, fetch fresh data in background for immediate update
    _refreshMaintenanceCache();
  }

  Future<void> _refreshReportsCache() async {
    try {
      final response = await _supabase
          .from('reports')
          .select('*, supervisors(username)')
          .order('created_at', ascending: false);

      final reportsData = List<Map<String, dynamic>>.from(response);
      _cacheService.setCached(CacheKeys.allReports, reportsData);

      if (kDebugMode) {
        print(
            'DataSyncService: Refreshed reports cache with ${reportsData.length} items');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DataSyncService: Failed to refresh reports cache: $e');
      }
    }
  }

  Future<void> _refreshMaintenanceCache() async {
    try {
      final response = await _supabase
          .from('maintenance_reports')
          .select('*, supervisors(username)')
          .order('created_at', ascending: false);

      final maintenanceData = List<Map<String, dynamic>>.from(response);
      _cacheService.setCached(CacheKeys.allMaintenance, maintenanceData);

      if (kDebugMode) {
        print(
            'DataSyncService: Refreshed maintenance cache with ${maintenanceData.length} items');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DataSyncService: Failed to refresh maintenance cache: $e');
      }
    }
  }

  // Manual invalidation methods for when data is modified locally
  void invalidateReportsCache() {
    _cacheService.invalidatePattern('reports');
    _refreshReportsCache();
  }

  void invalidateMaintenanceCache() {
    _cacheService.invalidatePattern('maintenance');
    _refreshMaintenanceCache();
  }

  void invalidateAllCache() {
    _cacheService.clearAll();
    _refreshReportsCache();
    _refreshMaintenanceCache();
  }

  // Force refresh without invalidation (for pull-to-refresh scenarios)
  Future<void> forceRefreshReports() async {
    await _refreshReportsCache();
  }

  Future<void> forceRefreshMaintenance() async {
    await _refreshMaintenanceCache();
  }

  void dispose() {
    if (_isListening) {
      _supabase.removeAllChannels();
      _isListening = false;
    }
  }
}
