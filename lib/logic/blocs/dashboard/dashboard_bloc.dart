import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/services/cache_service.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../data/repositories/supervisor_repository.dart';
import '../../../data/repositories/maintenance_repository.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final ReportRepository reportRepository;
  final SupervisorRepository supervisorRepository;
  final MaintenanceReportRepository maintenanceRepository;
  final AdminService adminService;
  final CacheService _cacheService = CacheService();

  // 🚀 Smart caching to prevent unnecessary reloads (kept for backward compatibility)
  static DashboardLoaded? _cachedData;
  static DateTime? _lastFetchTime;
  static const Duration _cacheExpiry = Duration(minutes: 2);

  DashboardBloc({
    required this.reportRepository,
    required this.supervisorRepository,
    required this.maintenanceRepository,
    required this.adminService,
  }) : super(DashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
    on<RefreshDashboard>((event, emit) {
      // Clear cache and force refresh
      clearCache();
      add(const LoadDashboardData(forceRefresh: true));
    });
  }

  /// Clears cached dashboard data (useful when user logs out or changes)
  static void clearCache() {
    _cachedData = null;
    _lastFetchTime = null;
  }

  /// Clear all dashboard caches (including CacheService cache)
  void clearAllCaches() {
    clearCache();
    _cacheService.invalidate(CacheKeys.regularDashboardStats);
  }

  /// Handles explicit refresh requests by clearing cache and reloading
  Future<void> _onRefreshDashboard(
      RefreshDashboard event, Emitter<DashboardState> emit) async {
    // Clear cache and force refresh
    clearCache();
    add(const LoadDashboardData(forceRefresh: true));
  }

  Future<void> _onLoadDashboardData(
      LoadDashboardData event, Emitter<DashboardState> emit) async {
    try {
      // 🚀 Check cache first if not forcing refresh (instant loading like super admin)
      if (!event.forceRefresh) {
        final cachedData = _cacheService
            .getCached<Map<String, dynamic>>(CacheKeys.regularDashboardStats);
        if (cachedData != null) {
          try {
            // ⚡ Emit cached data first for instant loading
            final dashboardState = _mapCachedDataToDashboardState(cachedData);
            emit(dashboardState);

            // If cache is near expiry, refresh in background
            if (_cacheService.isNearExpiry(CacheKeys.regularDashboardStats)) {
              _refreshDashboardDataInBackground(emit);
            }
            return;
          } catch (e) {
            // Cache data format issue, invalidate and continue with fresh load
            _cacheService.invalidate(CacheKeys.regularDashboardStats);
            print('Cache data format issue, loading fresh data: $e');
          }
        }
      }

      // Show loading only if no cached data
      if (state is! DashboardLoaded) {
        emit(DashboardLoading());
      }

      print('🚀 Fetching fresh dashboard data${event.forceRefresh ? ' (force refresh)' : ''}');

      // Check if current user is admin
      final isAdmin = await adminService.isCurrentUserAdmin();
      if (!isAdmin) {
        emit(const DashboardError(
            'Unauthorized access. Admin privileges required.'));
        return;
      }

      // Get current admin's supervisor IDs (correctly using admin_supervisors table)
      final supervisorIds = await adminService.getCurrentAdminSupervisorIds();

      // If no supervisors assigned to this admin, return empty data
      if (supervisorIds.isEmpty) {
        final emptyData = DashboardLoaded(
          pendingReports: 0,
          routineReports: 0,
          totalReports: 0,
          emergencyReports: 0,
          completedReports: 0,
          overdueReports: 0,
          lateCompletedReports: 0,
          totalSupervisors: 0,
          completionRate: 0.0,
          reports: [],
          supervisors: [],
          totalMaintenanceReports: 0,
          completedMaintenanceReports: 0,
          pendingMaintenanceReports: 0,
          maintenanceReports: [],
        );

        // Cache the empty data
        _cachedData = emptyData;
        _lastFetchTime = DateTime.now();

        emit(emptyData);
        return;
      }

      // Get supervisor objects for the assigned supervisor IDs
      final allSupervisors = await supervisorRepository.fetchSupervisors();
      final supervisors = allSupervisors
          .where((supervisor) => supervisorIds.contains(supervisor.id))
          .toList();

      // Fetch reports and maintenance only for admin's supervisors  
      final reports = await reportRepository.fetchReports(
        supervisorIds: supervisorIds,
        forceRefresh: event.forceRefresh,
      );
      final maintenanceReports =
          await maintenanceRepository.fetchMaintenanceReports(
        supervisorIds: supervisorIds,
      );

      // Calculate statistics
      final totalReports = reports.length;
      final emergencyReports =
          reports.where((r) => r.priority.toLowerCase() == 'emergency').length;
      final completedReports =
          reports.where((r) => r.status.toLowerCase() == 'completed').length;
      final overdueReports =
          reports.where((r) => r.status.toLowerCase() == 'late').length;
      final lateCompletedReports = reports
          .where((r) => r.status.toLowerCase() == 'late_completed')
          .length;
      final routineReports =
          reports.where((r) => r.priority.toLowerCase() == 'routine').length;
      final pendingReports = reports.where((r) => r.status == 'pending').length;
      final totalSupervisors = supervisors.length;

      final completionRate =
          totalReports == 0 ? 0.0 : completedReports / totalReports;

      // Maintenance reports statistics
      final totalMaintenanceReports = maintenanceReports.length;
      final completedMaintenanceReports = maintenanceReports
          .where((r) => r.status.toLowerCase() == 'completed')
          .length;
      final pendingMaintenanceReports = maintenanceReports
          .where((r) => r.status.toLowerCase() == 'pending')
          .length;

      final dashboardData = DashboardLoaded(
        pendingReports: pendingReports,
        routineReports: routineReports,
        totalReports: totalReports,
        emergencyReports: emergencyReports,
        completedReports: completedReports,
        overdueReports: overdueReports,
        lateCompletedReports: lateCompletedReports,
        totalSupervisors: totalSupervisors,
        completionRate: completionRate,
        reports: reports,
        supervisors: supervisors,
        totalMaintenanceReports: totalMaintenanceReports,
        completedMaintenanceReports: completedMaintenanceReports,
        pendingMaintenanceReports: pendingMaintenanceReports,
        maintenanceReports: maintenanceReports,
      );

      // 🚀 Cache the fresh data with new CacheService
      final dataMap = _mapDashboardStateToCache(dashboardData);
      _cacheService.setCached(CacheKeys.regularDashboardStats, dataMap);

      // Keep old cache for backward compatibility
      _cachedData = dashboardData;
      _lastFetchTime = DateTime.now();

      print('💾 Dashboard data cached for 2 minutes');
      emit(dashboardData);
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  /// Map cached data back to DashboardState
  DashboardLoaded _mapCachedDataToDashboardState(Map<String, dynamic> cachedData) {
    return DashboardLoaded(
      pendingReports: cachedData['pendingReports'] ?? 0,
      routineReports: cachedData['routineReports'] ?? 0,
      totalReports: cachedData['totalReports'] ?? 0,
      emergencyReports: cachedData['emergencyReports'] ?? 0,
      completedReports: cachedData['completedReports'] ?? 0,
      overdueReports: cachedData['overdueReports'] ?? 0,
      lateCompletedReports: cachedData['lateCompletedReports'] ?? 0,
      totalSupervisors: cachedData['totalSupervisors'] ?? 0,
      completionRate: (cachedData['completionRate'] as num?)?.toDouble() ?? 0.0,
      reports: (cachedData['reports'] as List<dynamic>?)?.cast() ?? [],
      supervisors: (cachedData['supervisors'] as List<dynamic>?)?.cast() ?? [],
      totalMaintenanceReports: cachedData['totalMaintenanceReports'] ?? 0,
      completedMaintenanceReports: cachedData['completedMaintenanceReports'] ?? 0,
      pendingMaintenanceReports: cachedData['pendingMaintenanceReports'] ?? 0,
      maintenanceReports: (cachedData['maintenanceReports'] as List<dynamic>?)?.cast() ?? [],
    );
  }

  /// Map DashboardState to cacheable format
  Map<String, dynamic> _mapDashboardStateToCache(DashboardLoaded dashboardData) {
    return {
      'pendingReports': dashboardData.pendingReports,
      'routineReports': dashboardData.routineReports,
      'totalReports': dashboardData.totalReports,
      'emergencyReports': dashboardData.emergencyReports,
      'completedReports': dashboardData.completedReports,
      'overdueReports': dashboardData.overdueReports,
      'lateCompletedReports': dashboardData.lateCompletedReports,
      'totalSupervisors': dashboardData.totalSupervisors,
      'completionRate': dashboardData.completionRate,
      'reports': dashboardData.reports,
      'supervisors': dashboardData.supervisors,
      'totalMaintenanceReports': dashboardData.totalMaintenanceReports,
      'completedMaintenanceReports': dashboardData.completedMaintenanceReports,
      'pendingMaintenanceReports': dashboardData.pendingMaintenanceReports,
      'maintenanceReports': dashboardData.maintenanceReports,
    };
  }

  /// Refresh dashboard data in background (like super admin)
  Future<void> _refreshDashboardDataInBackground(Emitter<DashboardState> emit) async {
    try {
      print('🔄 Background refresh started for regular dashboard...');
      
      // Check if current user is admin
      final isAdmin = await adminService.isCurrentUserAdmin();
      if (!isAdmin) return;

      // Get current admin's supervisor IDs
      final supervisorIds = await adminService.getCurrentAdminSupervisorIds();
      if (supervisorIds.isEmpty) return;

      // Get supervisor objects for the assigned supervisor IDs
      final allSupervisors = await supervisorRepository.fetchSupervisors();
      final supervisors = allSupervisors
          .where((supervisor) => supervisorIds.contains(supervisor.id))
          .toList();

      // Fetch fresh data
      final reports = await reportRepository.fetchReports(
        supervisorIds: supervisorIds,
        forceRefresh: true,
      );
      final maintenanceReports = await maintenanceRepository.fetchMaintenanceReports(
        supervisorIds: supervisorIds,
      );

      // Calculate statistics
      final totalReports = reports.length;
      final emergencyReports = reports.where((r) => r.priority.toLowerCase() == 'emergency').length;
      final completedReports = reports.where((r) => r.status.toLowerCase() == 'completed').length;
      final overdueReports = reports.where((r) => r.status.toLowerCase() == 'late').length;
      final lateCompletedReports = reports.where((r) => r.status.toLowerCase() == 'late_completed').length;
      final routineReports = reports.where((r) => r.priority.toLowerCase() == 'routine').length;
      final pendingReports = reports.where((r) => r.status == 'pending').length;
      final totalSupervisors = supervisors.length;
      final completionRate = totalReports == 0 ? 0.0 : completedReports / totalReports;

      // Maintenance reports statistics
      final totalMaintenanceReports = maintenanceReports.length;
      final completedMaintenanceReports = maintenanceReports.where((r) => r.status.toLowerCase() == 'completed').length;
      final pendingMaintenanceReports = maintenanceReports.where((r) => r.status.toLowerCase() == 'pending').length;

      final dashboardData = DashboardLoaded(
        pendingReports: pendingReports,
        routineReports: routineReports,
        totalReports: totalReports,
        emergencyReports: emergencyReports,
        completedReports: completedReports,
        overdueReports: overdueReports,
        lateCompletedReports: lateCompletedReports,
        totalSupervisors: totalSupervisors,
        completionRate: completionRate,
        reports: reports,
        supervisors: supervisors,
        totalMaintenanceReports: totalMaintenanceReports,
        completedMaintenanceReports: completedMaintenanceReports,
        pendingMaintenanceReports: pendingMaintenanceReports,
        maintenanceReports: maintenanceReports,
      );

      // Update cache
      final dataMap = _mapDashboardStateToCache(dashboardData);
      _cacheService.setCached(CacheKeys.regularDashboardStats, dataMap);

      // Only emit if data has actually changed
      if (state is DashboardLoaded) {
        final currentState = state as DashboardLoaded;
        if (_isDashboardDataDifferent(currentState, dashboardData)) {
          emit(dashboardData);
          print('✅ Background refresh completed with new data');
        } else {
          print('✅ Background refresh completed - no changes');
        }
      }
    } catch (e) {
      // Fail silently for background refresh
      print('Background dashboard refresh failed: $e');
    }
  }

  /// Check if dashboard data has changed
  bool _isDashboardDataDifferent(DashboardLoaded current, DashboardLoaded fresh) {
    return current.totalReports != fresh.totalReports ||
           current.completedReports != fresh.completedReports ||
           current.totalMaintenanceReports != fresh.totalMaintenanceReports ||
           current.completedMaintenanceReports != fresh.completedMaintenanceReports;
  }
}
