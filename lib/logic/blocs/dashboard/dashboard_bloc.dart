import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/services/cache_service.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../data/repositories/supervisor_repository.dart';
import '../../../data/repositories/maintenance_repository.dart';
import '../../../data/repositories/maintenance_count_repository.dart';
import '../../../data/repositories/damage_count_repository.dart';
import '../../../data/models/supervisor.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final ReportRepository reportRepository;
  final SupervisorRepository supervisorRepository;
  final MaintenanceReportRepository maintenanceRepository;
  final MaintenanceCountRepository maintenanceCountRepository;
  final DamageCountRepository damageCountRepository;
  final AdminService adminService;
  final CacheService _cacheService = CacheService();

  DashboardBloc({
    required this.reportRepository,
    required this.supervisorRepository,
    required this.maintenanceRepository,
    required this.maintenanceCountRepository,
    required this.damageCountRepository,
    required this.adminService,
  }) : super(DashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
    on<RefreshDashboard>((event, emit) {
      // Clear cache and force refresh
      add(const LoadDashboardData(forceRefresh: true));
    });
  }

  /// Clears cached dashboard data (useful when user logs out or changes)
  static void clearCache() {
    // Clear any static cache if needed
  }

  Future<void> _onLoadDashboardData(
      LoadDashboardData event, Emitter<DashboardState> emit) async {
    try {
      emit(DashboardLoading());

      // Check if current user is admin
      final isAdmin = await adminService.isCurrentUserAdmin();
      if (!isAdmin) {
        emit(const DashboardError(
            'Unauthorized access. Admin privileges required.'));
        return;
      }

      // Get current admin's supervisor IDs
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
          schoolsWithCounts: 0,
          schoolsWithDamage: 0,
          totalSchools: 0,
          schoolsWithAchievements: 0,
        );
        emit(emptyData);
        return;
      }

      // Get supervisors
      final allSupervisors = await supervisorRepository.fetchSupervisors();
      final rawSupervisors = allSupervisors
          .where((supervisor) => supervisorIds.contains(supervisor.id))
          .toList();

      // Enrich supervisors with school counts
      final supervisors = <Supervisor>[];
      for (final supervisor in rawSupervisors) {
        // Get school count for this supervisor
        final schoolsResponse = await Supabase.instance.client
            .from('supervisor_schools')
            .select('school_id')
            .eq('supervisor_id', supervisor.id);

        final schoolCount = schoolsResponse.length;

        // Create enriched supervisor with school count
        final enrichedSupervisor = supervisor.copyWith(
          schoolsCount: schoolCount,
        );
        supervisors.add(enrichedSupervisor);
      }

      // Fetch reports and maintenance
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

      // Maintenance statistics
      final totalMaintenanceReports = maintenanceReports.length;
      final completedMaintenanceReports = maintenanceReports
          .where((r) => r.status.toLowerCase() == 'completed')
          .length;
      final pendingMaintenanceReports = maintenanceReports
          .where((r) => r.status.toLowerCase() == 'pending')
          .length;

      // Get inventory counts
      final maintenanceCountSummary =
          await maintenanceCountRepository.getDashboardSummary();
      final schoolsWithCounts =
          maintenanceCountSummary['schools_with_counts'] ?? 0;

      final damageCountSummary =
          await damageCountRepository.getDashboardSummary();
      final schoolsWithDamage = damageCountSummary['schools_with_damage'] ?? 0;

      // Get schools count and schools with achievements
      int totalSchools = 0;
      int schoolsWithAchievements = 0;

      // Get all school IDs for this admin's supervisors
      Set<String> adminSchoolIds = {};
      for (final supervisorId in supervisorIds) {
        final schoolsResponse = await Supabase.instance.client
            .from('supervisor_schools')
            .select('school_id')
            .eq('supervisor_id', supervisorId);

        for (final school in schoolsResponse) {
          if (school['school_id'] != null) {
            adminSchoolIds.add(school['school_id'].toString());
          }
        }
      }

      totalSchools = adminSchoolIds.length;

      // Calculate schools with achievements (schools that have achievement photos)
      if (adminSchoolIds.isNotEmpty) {
        try {
          final achievementsResponse = await Supabase.instance.client
              .from('achievement_photos')
              .select('school_id')
              .inFilter('school_id', adminSchoolIds.toList())
              .not('school_id', 'is', null);

          // Count unique schools with achievements
          Set<String> schoolsWithAchievementsSet = {};
          for (final achievement in achievementsResponse) {
            final schoolId = achievement['school_id']?.toString();
            if (schoolId != null && schoolId.isNotEmpty) {
              schoolsWithAchievementsSet.add(schoolId);
            }
          }

          schoolsWithAchievements = schoolsWithAchievementsSet.length;
        } catch (e) {
          print('Warning: Failed to fetch schools with achievements: $e');
          schoolsWithAchievements = 0;
        }
      }

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
        schoolsWithCounts: schoolsWithCounts,
        schoolsWithDamage: schoolsWithDamage,
        totalSchools: totalSchools,
        schoolsWithAchievements: schoolsWithAchievements,
      );

      emit(dashboardData);
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
