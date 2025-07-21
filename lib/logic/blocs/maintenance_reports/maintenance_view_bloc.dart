import 'package:flutter_bloc/flutter_bloc.dart';
import 'maintenance_view_event.dart';
import 'maintenance_view_state.dart';
import '../../../data/repositories/maintenance_repository.dart';
import '../../../data/models/maintenance_report.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/mixins/admin_filter_mixin.dart';
import 'package:flutter/foundation.dart';

class MaintenanceViewBloc
    extends Bloc<MaintenanceViewEvent, MaintenanceViewState>
    with AdminFilterMixin {
  final MaintenanceReportRepository maintenanceRepository;
  final CacheService _cacheService = CacheService();

  @override
  final AdminService adminService;

  MaintenanceViewBloc(this.maintenanceRepository, this.adminService)
      : super(MaintenanceViewInitial()) {
    on<FetchMaintenanceReports>(_onFetchMaintenanceReports);
  }

  /// Invalidates all cached maintenance reports in the repository
  void invalidateCache() {
    maintenanceRepository.clearCache();
    _cacheService.invalidatePattern('maintenance');
  }

  Future<void> _onFetchMaintenanceReports(
      FetchMaintenanceReports event, Emitter<MaintenanceViewState> emit) async {
    
    // 🚀 PERFORMANCE OPTIMIZATION: Create cache key based on filters
    final cacheKey = _generateCacheKey(event);
    
    // 🚀 PERFORMANCE OPTIMIZATION: Check cache first if not forcing refresh (instant loading like dashboard) 
    if (!event.forceRefresh) {
      final cachedReports = _cacheService.getCached<List<MaintenanceReport>>(cacheKey);
      if (cachedReports != null) {
        // ⚡ Emit cached data first for instant loading
        emit(MaintenanceViewLoaded(cachedReports));
        
        // If cache is near expiry, refresh in background
        if (_cacheService.isNearExpiry(cacheKey)) {
          _refreshMaintenanceInBackground(event, emit);
        }
        return;
      }
    }

    // Show loading only if no cached data
    if (state is! MaintenanceViewLoaded) {
      emit(MaintenanceViewLoading());
    }

    logAdminFilterDebug(
        'Starting maintenance fetch with filters: supervisorId=${event.supervisorId}, status=${event.status}, forceRefresh=${event.forceRefresh}',
        context: 'MaintenanceViewBloc');

    try {
      List<MaintenanceReport> reports;

      // 🚀 PERFORMANCE OPTIMIZATION: Use dashboard method for small limits (dashboard scenarios)
      final isDashboardQuery = event.limit != null && event.limit! <= 20 && event.page == null;
      
      if (isDashboardQuery) {
        logAdminFilterDebug('Using dashboard-optimized query', context: 'MaintenanceViewBloc');
        
        if (event.supervisorId == null) {
          final filterResult = await applyAdminFilter<MaintenanceReport>(
            fetchAllData: () => maintenanceRepository.fetchMaintenanceReportsForDashboard(
              status: event.status,
              limit: event.limit ?? 10,
            ),
            fetchFilteredData: (supervisorIds) =>
                maintenanceRepository.fetchMaintenanceReportsForDashboard(
              supervisorIds: supervisorIds,
              status: event.status,
              limit: event.limit ?? 10,
            ),
            debugContext: 'Maintenance',
          );
          reports = filterResult.data;
        } else {
          final hasAccess = await hasAccessToSupervisor(
            supervisorId: event.supervisorId!,
            debugContext: 'Maintenance',
          );

          if (!hasAccess) {
            logAdminFilterDebug(
                'Access denied to supervisor ${event.supervisorId}',
                context: 'MaintenanceViewBloc');
            emit(MaintenanceViewError('Access denied to supervisor data'));
            return;
          }

          reports = await maintenanceRepository.fetchMaintenanceReportsForDashboard(
            supervisorId: event.supervisorId,
            status: event.status,
            limit: event.limit ?? 10,
          );
        }
      } else {
        // Use full query for larger datasets or pagination
        if (event.supervisorId == null) {
          logAdminFilterDebug(
              'No specific supervisorId - applying admin filtering',
              context: 'MaintenanceViewBloc');

          // Use AdminFilterMixin to apply admin-based filtering
          final filterResult = await applyAdminFilter<MaintenanceReport>(
            fetchAllData: () => maintenanceRepository.fetchMaintenanceReports(
              status: event.status,
              limit: event.limit,
              page: event.page,
            ),
            fetchFilteredData: (supervisorIds) =>
                maintenanceRepository.fetchMaintenanceReports(
              supervisorIds: supervisorIds,
              status: event.status,
              limit: event.limit,
              page: event.page,
            ),
            debugContext: 'Maintenance',
          );

          reports = filterResult.data;

          logAdminFilterDebug(
              'Admin filtering completed: ${reports.length} maintenance reports, isSuperAdmin=${filterResult.isSuperAdmin}, hasAccess=${filterResult.hasAccess}',
              context: 'MaintenanceViewBloc');
        } else {
          // Specific supervisor requested - validate access first
          final hasAccess = await hasAccessToSupervisor(
            supervisorId: event.supervisorId!,
            debugContext: 'Maintenance',
          );

          if (!hasAccess) {
            logAdminFilterDebug(
                'Access denied to supervisor ${event.supervisorId}',
                context: 'MaintenanceViewBloc');
            emit(MaintenanceViewError('Access denied to supervisor data'));
            return;
          }

          logAdminFilterDebug(
              'Fetching maintenance for specific supervisor: ${event.supervisorId}',
              context: 'MaintenanceViewBloc');
          reports = await maintenanceRepository.fetchMaintenanceReports(
            supervisorId: event.supervisorId,
            status: event.status,
            limit: event.limit,
            page: event.page,
          );
        }
      }

      // 🚀 PERFORMANCE OPTIMIZATION: Cache the fresh data with appropriate maxAge
      _cacheService.setCached(cacheKey, reports, maxAge: isDashboardQuery ? Duration(minutes: 2) : Duration(minutes: 5));
      print('💾 Maintenance reports cached for ${isDashboardQuery ? "2" : "5"} minutes: ${reports.length} reports');

      logAdminFilterDebug(
          'Maintenance fetch completed: ${reports.length} reports',
          context: 'MaintenanceViewBloc');

      emit(MaintenanceViewLoaded(reports));
    } catch (e) {
      logAdminFilterDebug('Maintenance fetch error: $e',
          context: 'MaintenanceViewBloc');
      emit(MaintenanceViewError(e.toString()));
    }
  }

  /// Generate cache key based on filters
  String _generateCacheKey(FetchMaintenanceReports event) {
    final parts = <String>['maintenance'];
    if (event.supervisorId != null) parts.add('sup_${event.supervisorId}');
    if (event.status != null) parts.add('status_${event.status}');
    if (event.page != null) parts.add('page_${event.page}');
    if (event.limit != null) parts.add('limit_${event.limit}');
    return parts.join('_');
  }

  /// Refresh maintenance reports in background (like dashboard)
  Future<void> _refreshMaintenanceInBackground(
      FetchMaintenanceReports event, Emitter<MaintenanceViewState> emit) async {
    try {
      print('🔄 Background refresh started for maintenance reports...');
      
      List<MaintenanceReport> reports;

      if (event.supervisorId == null) {
        final filterResult = await applyAdminFilter<MaintenanceReport>(
          fetchAllData: () => maintenanceRepository.fetchMaintenanceReports(
            status: event.status,
            limit: event.limit,
            page: event.page,
          ),
          fetchFilteredData: (supervisorIds) =>
              maintenanceRepository.fetchMaintenanceReports(
            supervisorIds: supervisorIds,
            status: event.status,
            limit: event.limit,
            page: event.page,
          ),
          debugContext: 'Maintenance',
        );
        reports = filterResult.data;
      } else {
        reports = await maintenanceRepository.fetchMaintenanceReports(
          supervisorId: event.supervisorId,
          status: event.status,
          limit: event.limit,
          page: event.page,
        );
      }

      final cacheKey = _generateCacheKey(event);
      _cacheService.setCached(cacheKey, reports);

      // Only emit if data has actually changed
      if (state is MaintenanceViewLoaded) {
        final currentReports = (state as MaintenanceViewLoaded).maintenanceReports;
        if (_isMaintenanceDataDifferent(currentReports, reports)) {
          emit(MaintenanceViewLoaded(reports));
          print('✅ Background refresh completed with new maintenance data');
        } else {
          print('✅ Background refresh completed - no changes');
        }
      }
    } catch (e) {
      // Fail silently for background refresh
      print('Background maintenance refresh failed: $e');
    }
  }

  /// Check if maintenance data has changed
  bool _isMaintenanceDataDifferent(List<MaintenanceReport> current, List<MaintenanceReport> fresh) {
    if (current.length != fresh.length) return true;
    // Could add more sophisticated comparison if needed
    return false;
  }
}
