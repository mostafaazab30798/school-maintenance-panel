import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/admin_management_service.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/services/cache_invalidation_service.dart';
import '../../../data/repositories/supervisor_repository.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../data/repositories/maintenance_repository.dart';
import '../../../data/models/technician.dart';
import 'super_admin_event.dart';
import 'super_admin_state.dart';

class SuperAdminBloc extends Bloc<SuperAdminEvent, SuperAdminState> {
  final AdminManagementService _adminService;
  final SupervisorRepository _supervisorRepo;
  final ReportRepository _reportRepo;
  final MaintenanceReportRepository _maintenanceRepo;
  final CacheService _cacheService = CacheService();

  SuperAdminBloc(
    this._adminService,
    this._supervisorRepo,
    this._reportRepo,
    this._maintenanceRepo,
  ) : super(SuperAdminInitial()) {
    on<LoadSuperAdminData>(_onLoadData);
    on<CreateNewAdmin>(_onCreateAdmin);
    on<DeleteAdminEvent>(_onDeleteAdmin);
    on<AssignSupervisorsToAdmin>(_onAssignSupervisors);
    on<CreateNewAdminComplete>(_onCreateAdminComplete);
    on<CreateNewAdminManual>(_onCreateAdminManual);
    on<SupervisorTechniciansUpdatedEvent>(_onSupervisorTechniciansUpdated);
  }

  Future<void> _onLoadData(
      LoadSuperAdminData event, Emitter<SuperAdminState> emit) async {
    try {
      // Check cache first if not forcing refresh
      if (!event.forceRefresh) {
        final cachedData = _cacheService
            .getCached<Map<String, dynamic>>(CacheKeys.dashboardStats);
        if (cachedData != null) {
          try {
            // Emit cached data first for instant loading
            emit(SuperAdminLoaded(
              admins: (cachedData['admins'] as List).cast(),
              allSupervisors: (cachedData['allSupervisors'] as List)
                  .cast<Map<String, dynamic>>(),
              adminStats: (cachedData['adminStats'] as Map)
                  .cast<String, Map<String, dynamic>>(),
              supervisorsWithStats: (cachedData['supervisorsWithStats'] as List)
                  .cast<Map<String, dynamic>>(),
              reportTypesStats:
                  (cachedData['reportTypesStats'] as Map<String, dynamic>?)
                          ?.cast<String, int>() ??
                      <String, int>{},
              reportSourcesStats:
                  (cachedData['reportSourcesStats'] as Map<String, dynamic>?)
                          ?.cast<String, int>() ??
                      <String, int>{},
              maintenanceStatusStats: (cachedData['maintenanceStatusStats']
                          as Map<String, dynamic>?)
                      ?.cast<String, int>() ??
                  <String, int>{},
              adminReportsDistribution: (cachedData['adminReportsDistribution']
                          as Map<String, dynamic>?)
                      ?.cast<String, int>() ??
                  <String, int>{},
              adminMaintenanceDistribution:
                  (cachedData['adminMaintenanceDistribution']
                              as Map<String, dynamic>?)
                          ?.cast<String, int>() ??
                      <String, int>{},
              reportTypesCompletionRates:
                  (cachedData['reportTypesCompletionRates']
                              as Map<String, dynamic>?)
                          ?.cast<String, Map<String, dynamic>>() ??
                      <String, Map<String, dynamic>>{},
              reportSourcesCompletionRates:
                  (cachedData['reportSourcesCompletionRates']
                              as Map<String, dynamic>?)
                          ?.cast<String, Map<String, dynamic>>() ??
                      <String, Map<String, dynamic>>{},
              reportPriorityStats:
                  (cachedData['reportPriorityStats'] as Map<String, dynamic>?)
                          ?.cast<String, int>() ??
                      <String, int>{},
              reportPriorityCompletionRates:
                  (cachedData['reportPriorityCompletionRates']
                              as Map<String, dynamic>?)
                          ?.cast<String, Map<String, dynamic>>() ??
                      <String, Map<String, dynamic>>{},
            ));

            // If cache is near expiry, refresh in background
            if (_cacheService.isNearExpiry(CacheKeys.dashboardStats)) {
              _refreshDashboardDataInBackground(emit);
            }
            return;
          } catch (e) {
            // Cache data format issue, invalidate and continue with fresh load
            _cacheService.invalidate(CacheKeys.dashboardStats);
            print('Cache data format issue, loading fresh data: $e');
          }
        }
      }

      // Show loading only if no cached data
      if (state is! SuperAdminLoaded) {
        emit(SuperAdminLoading());
      }

      // Load fresh data
      final dashboardData = await _loadFreshDashboardData();

      // Cache the fresh data
      _cacheService.setCached(CacheKeys.dashboardStats, dashboardData);

      emit(SuperAdminLoaded(
        admins: dashboardData['admins'],
        allSupervisors: dashboardData['allSupervisors'],
        adminStats: dashboardData['adminStats'],
        supervisorsWithStats: dashboardData['supervisorsWithStats'],
        reportTypesStats: dashboardData['reportTypesStats'],
        reportSourcesStats: dashboardData['reportSourcesStats'],
        maintenanceStatusStats: dashboardData['maintenanceStatusStats'],
        adminReportsDistribution: dashboardData['adminReportsDistribution'],
        adminMaintenanceDistribution:
            dashboardData['adminMaintenanceDistribution'],
        reportTypesCompletionRates: dashboardData['reportTypesCompletionRates'],
        reportSourcesCompletionRates:
            dashboardData['reportSourcesCompletionRates'],
        reportPriorityStats: dashboardData['reportPriorityStats'],
        reportPriorityCompletionRates:
            dashboardData['reportPriorityCompletionRates'],
      ));
    } catch (e) {
      emit(SuperAdminError(e.toString()));
    }
  }

  Future<Map<String, dynamic>> _loadFreshDashboardData() async {
    // 🚀 Use the new optimized method that eliminates N+1 queries and runs everything in parallel
    print('🚀 Using optimized dashboard data loading...');
    final stopwatch = Stopwatch()..start();

    final dashboardData = await _adminService.getAllDashboardDataOptimized();

    stopwatch.stop();
    print(
        '✅ Dashboard data loaded in ${stopwatch.elapsedMilliseconds}ms (was taking 5000-10000ms before optimization)');

    return dashboardData;
  }

  Future<void> _refreshDashboardDataInBackground(
      Emitter<SuperAdminState> emit) async {
    try {
      final dashboardData = await _loadFreshDashboardData();

      // Update cache
      _cacheService.setCached(CacheKeys.dashboardStats, dashboardData);

      // Only emit if data has actually changed
      if (state is SuperAdminLoaded) {
        final currentState = state as SuperAdminLoaded;
        if (_isDashboardDataDifferent(currentState, dashboardData)) {
          emit(SuperAdminLoaded(
            admins: dashboardData['admins'],
            allSupervisors: dashboardData['allSupervisors'],
            adminStats: dashboardData['adminStats'],
            supervisorsWithStats: dashboardData['supervisorsWithStats'],
            reportTypesStats: dashboardData['reportTypesStats'],
            reportSourcesStats: dashboardData['reportSourcesStats'],
            maintenanceStatusStats: dashboardData['maintenanceStatusStats'],
            adminReportsDistribution: dashboardData['adminReportsDistribution'],
            adminMaintenanceDistribution:
                dashboardData['adminMaintenanceDistribution'],
            reportTypesCompletionRates:
                dashboardData['reportTypesCompletionRates'],
            reportSourcesCompletionRates:
                dashboardData['reportSourcesCompletionRates'],
            reportPriorityStats: dashboardData['reportPriorityStats'],
            reportPriorityCompletionRates:
                dashboardData['reportPriorityCompletionRates'],
          ));
        }
      }
    } catch (e) {
      // Fail silently for background refresh
      print('Background dashboard refresh failed: $e');
    }
  }

  bool _isDashboardDataDifferent(
      SuperAdminLoaded currentState, Map<String, dynamic> newData) {
    // Simple comparison - check if admin count or stats have changed
    return currentState.admins.length != (newData['admins'] as List).length ||
        currentState.allSupervisors.length !=
            (newData['allSupervisors'] as List).length;
  }

  Future<void> _onCreateAdmin(
      CreateNewAdmin event, Emitter<SuperAdminState> emit) async {
    try {
      await _adminService.createAdmin(
        name: event.name,
        email: event.email,
        authUserId: event.authUserId,
      );
      add(LoadSuperAdminData(forceRefresh: true));
    } catch (e) {
      emit(SuperAdminError(e.toString()));
    }
  }

  Future<void> _onDeleteAdmin(
      DeleteAdminEvent event, Emitter<SuperAdminState> emit) async {
    try {
      await _adminService.deleteAdmin(event.adminId);
      add(LoadSuperAdminData(forceRefresh: true));
    } catch (e) {
      emit(SuperAdminError(e.toString()));
    }
  }

  Future<void> _onAssignSupervisors(
      AssignSupervisorsToAdmin event, Emitter<SuperAdminState> emit) async {
    try {
      // Perform the assignment
      await _adminService.assignSupervisorsToAdmin(
        adminId: event.adminId,
        supervisorIds: event.supervisorIds,
      );

      // 🚀 Critical Fix: Clear all supervisor-related caches
      // This ensures that when the assigned admin logs in, they'll see the newly assigned supervisors
      CacheInvalidationService.invalidateSupervisorCaches();

      // Instead of reloading everything, just update the specific admin's data
      if (state is SuperAdminLoaded) {
        final currentState = state as SuperAdminLoaded;

        // Update the allSupervisors list with new admin_id assignments
        final updatedAllSupervisors =
            currentState.allSupervisors.map((supervisor) {
          final supervisorId = supervisor['id'].toString();
          if (event.supervisorIds.contains(supervisorId)) {
            // Assign this supervisor to the admin
            return {...supervisor, 'admin_id': event.adminId};
          } else if (supervisor['admin_id'] == event.adminId &&
              !event.supervisorIds.contains(supervisorId)) {
            // Unassign this supervisor from the admin
            return {...supervisor, 'admin_id': null};
          }
          return supervisor;
        }).toList();

        // Recalculate only the affected admin's stats
        final updatedAdminStats =
            Map<String, Map<String, dynamic>>.from(currentState.adminStats);
        final newStats = await _adminService.getAdminStats(event.adminId);
        updatedAdminStats[event.adminId] = newStats;

        // Emit the updated state immediately
        emit(SuperAdminLoaded(
          admins: currentState.admins,
          allSupervisors: updatedAllSupervisors,
          adminStats: updatedAdminStats,
          supervisorsWithStats: currentState.supervisorsWithStats,
          reportTypesStats: currentState.reportTypesStats,
          reportSourcesStats: currentState.reportSourcesStats,
          maintenanceStatusStats: currentState.maintenanceStatusStats,
          adminReportsDistribution: currentState.adminReportsDistribution,
          adminMaintenanceDistribution:
              currentState.adminMaintenanceDistribution,
          reportTypesCompletionRates: currentState.reportTypesCompletionRates,
          reportSourcesCompletionRates:
              currentState.reportSourcesCompletionRates,
          reportPriorityStats: currentState.reportPriorityStats,
          reportPriorityCompletionRates:
              currentState.reportPriorityCompletionRates,
        ));

        // Update cache with new data
        final updatedData = {
          'admins': currentState.admins,
          'allSupervisors': updatedAllSupervisors,
          'adminStats': updatedAdminStats,
          'supervisorsWithStats': currentState.supervisorsWithStats,
          'reportTypesStats': currentState.reportTypesStats,
          'reportSourcesStats': currentState.reportSourcesStats,
          'maintenanceStatusStats': currentState.maintenanceStatusStats,
          'adminReportsDistribution': currentState.adminReportsDistribution,
          'adminMaintenanceDistribution':
              currentState.adminMaintenanceDistribution,
          'reportTypesCompletionRates': currentState.reportTypesCompletionRates,
          'reportSourcesCompletionRates':
              currentState.reportSourcesCompletionRates,
          'reportPriorityStats': currentState.reportPriorityStats,
          'reportPriorityCompletionRates':
              currentState.reportPriorityCompletionRates,
        };
        _cacheService.setCached(CacheKeys.dashboardStats, updatedData);
      } else {
        // Fallback to full reload if state is not loaded
        add(LoadSuperAdminData(forceRefresh: true));
      }
    } catch (e) {
      emit(SuperAdminError(e.toString()));
    }
  }

  Future<void> _onCreateAdminComplete(
      CreateNewAdminComplete event, Emitter<SuperAdminState> emit) async {
    try {
      await _adminService.createAdminWithAuth(
        name: event.name,
        email: event.email,
        password: event.password,
        role: event.role,
      );
      add(LoadSuperAdminData(forceRefresh: true));
    } catch (e) {
      emit(SuperAdminError(e.toString()));
    }
  }

  Future<void> _onCreateAdminManual(
      CreateNewAdminManual event, Emitter<SuperAdminState> emit) async {
    try {
      await _adminService.createAdmin(
        name: event.name,
        email: event.email,
        authUserId: event.authUserId,
        role: event.role,
      );
      add(LoadSuperAdminData(forceRefresh: true));
    } catch (e) {
      emit(SuperAdminError(e.toString()));
    }
  }

  Future<void> _onSupervisorTechniciansUpdated(
      SupervisorTechniciansUpdatedEvent event,
      Emitter<SuperAdminState> emit) async {
    try {
      print(
          '🔥 SuperAdminBloc: Processing technician update for supervisor ${event.supervisorId}');
      print(
          '🔥 Technicians detailed count: ${event.techniciansDetailed.length}');

      // Perform the technician update - prioritize detailed format if available
      if (event.techniciansDetailed.isNotEmpty) {
        // Use detailed technician update
        final technicians = event.techniciansDetailed
            .map((data) => Technician.fromMap(data as Map<String, dynamic>))
            .toList();
        await _supervisorRepo.updateSupervisorTechniciansDetailed(
          event.supervisorId,
          technicians,
        );
      } else {
        // Fallback to simple technician update
        await _supervisorRepo.updateSupervisorTechnicians(
          event.supervisorId,
          event.technicians,
        );
      }

      // 🚀 Critical Fix: Clear all supervisor-related caches
      CacheInvalidationService.invalidateSupervisorCaches();

      // Instead of reloading everything, just update the specific supervisor's data
      if (state is SuperAdminLoaded) {
        final currentState = state as SuperAdminLoaded;

        // Update the supervisorsWithStats list with new technicians
        final updatedSupervisorsWithStats =
            currentState.supervisorsWithStats.map((supervisor) {
          if (supervisor['id'] == event.supervisorId) {
            // Update this supervisor's technicians_detailed only
            return {
              ...supervisor,
              'technicians_detailed': event.techniciansDetailed,
            };
          }
          return supervisor;
        }).toList();

        // Also update allSupervisors if it contains technician data
        final updatedAllSupervisors =
            currentState.allSupervisors.map((supervisor) {
          if (supervisor['id'] == event.supervisorId) {
            // Update this supervisor's technicians_detailed only
            return {
              ...supervisor,
              'technicians_detailed': event.techniciansDetailed,
            };
          }
          return supervisor;
        }).toList();

        // Emit the updated state immediately
        emit(SuperAdminLoaded(
          admins: currentState.admins,
          allSupervisors: updatedAllSupervisors,
          adminStats: currentState.adminStats,
          supervisorsWithStats: updatedSupervisorsWithStats,
          reportTypesStats: currentState.reportTypesStats,
          reportSourcesStats: currentState.reportSourcesStats,
          maintenanceStatusStats: currentState.maintenanceStatusStats,
          adminReportsDistribution: currentState.adminReportsDistribution,
          adminMaintenanceDistribution:
              currentState.adminMaintenanceDistribution,
          reportTypesCompletionRates: currentState.reportTypesCompletionRates,
          reportSourcesCompletionRates:
              currentState.reportSourcesCompletionRates,
          reportPriorityStats: currentState.reportPriorityStats,
          reportPriorityCompletionRates:
              currentState.reportPriorityCompletionRates,
        ));

        // Update cache with new data
        final updatedData = {
          'admins': currentState.admins,
          'allSupervisors': updatedAllSupervisors,
          'adminStats': currentState.adminStats,
          'supervisorsWithStats': updatedSupervisorsWithStats,
          'reportTypesStats': currentState.reportTypesStats,
          'reportSourcesStats': currentState.reportSourcesStats,
          'maintenanceStatusStats': currentState.maintenanceStatusStats,
          'adminReportsDistribution': currentState.adminReportsDistribution,
          'adminMaintenanceDistribution':
              currentState.adminMaintenanceDistribution,
          'reportTypesCompletionRates': currentState.reportTypesCompletionRates,
          'reportSourcesCompletionRates':
              currentState.reportSourcesCompletionRates,
          'reportPriorityStats': currentState.reportPriorityStats,
          'reportPriorityCompletionRates':
              currentState.reportPriorityCompletionRates,
        };
        _cacheService.setCached(CacheKeys.dashboardStats, updatedData);
      } else {
        // Fallback to full reload if state is not loaded
        add(LoadSuperAdminData(forceRefresh: true));
      }
    } catch (e) {
      emit(SuperAdminError(e.toString()));
    }
  }
}
