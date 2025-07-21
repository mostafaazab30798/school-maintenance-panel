import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/services/performance_optimization_service.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../data/repositories/supervisor_repository.dart';
import '../../../data/repositories/maintenance_repository.dart';
import '../../../data/repositories/maintenance_count_repository.dart';
import '../../../data/repositories/damage_count_repository.dart';
import '../../../data/models/supervisor.dart';
import '../../../data/models/report.dart';
import '../../../data/models/maintenance_report.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final ReportRepository reportRepository;
  final SupervisorRepository supervisorRepository;
  final MaintenanceReportRepository maintenanceRepository;
  final MaintenanceCountRepository maintenanceCountRepository;
  final DamageCountRepository damageCountRepository;
  final AdminService adminService;
  final CacheService _cacheService = CacheService();
  // 🚀 PERFORMANCE OPTIMIZATION: Add performance optimization service
  final PerformanceOptimizationService _performanceService = PerformanceOptimizationService();

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
      _performanceService.clearCache(); // Clear performance cache too
      add(const LoadDashboardData(forceRefresh: true));
    });
  }

  /// Clears cached dashboard data (useful when user logs out or changes)
  static void clearCache() {
    // Clear any static cache if needed
    PerformanceOptimizationService().clearCache();
  }

  Future<void> _onLoadDashboardData(
      LoadDashboardData event, Emitter<DashboardState> emit) async {
    try {
      print('🚀 Starting optimized dashboard data fetch...');
      emit(DashboardLoading());

      // Check if current user is admin
      final isAdmin = await adminService.isCurrentUserAdmin();
      if (!isAdmin) {
        emit(const DashboardError(
            'Unauthorized access. Admin privileges required.'));
        return;
      }

      // Get current admin's supervisor IDs
      print('🔍 Getting supervisor IDs...');
      final supervisorIds = await adminService.getCurrentAdminSupervisorIds();
      print('📊 Found ${supervisorIds.length} supervisor IDs: $supervisorIds');

      // If no supervisors assigned to this admin, return empty data
      if (supervisorIds.isEmpty) {
        print('⚠️ No supervisors found, returning empty data');
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

      // 🚀 PERFORMANCE OPTIMIZATION: Load all data in parallel for faster dashboard loading
      print('🚀 Loading dashboard data in parallel...');
      
      final results = await Future.wait([
        // Get supervisors
        supervisorRepository.fetchSupervisors(),
        // Get reports using dashboard-optimized method
        reportRepository.fetchReportsForDashboard(
          supervisorIds: supervisorIds,
          forceRefresh: event.forceRefresh,
          limit: 50, // Limit for dashboard
        ),
        // Get maintenance reports using dashboard-optimized method
        maintenanceRepository.fetchMaintenanceReportsForDashboard(
          supervisorIds: supervisorIds,
          limit: 20, // Smaller limit for dashboard
        ),
        // Get maintenance count summary
        maintenanceCountRepository.getDashboardSummary(
          supervisorIds: supervisorIds,
        ),
        // Get damage count summary
        damageCountRepository.getDashboardSummary(
          supervisorIds: supervisorIds,
        ),
      ]);

      final allSupervisors = results[0] as List<Supervisor>;
      final reports = results[1] as List<Report>;
      final maintenanceReports = results[2] as List<MaintenanceReport>;
      final maintenanceCountSummary = results[3] as Map<String, int>;
      final damageCountSummary = results[4] as Map<String, int>;

      print('📊 Parallel loading completed:');
      print('  - Supervisors: ${allSupervisors.length}');
      print('  - Reports: ${reports.length}');
      print('  - Maintenance: ${maintenanceReports.length}');

      // Filter supervisors for current admin
      final rawSupervisors = allSupervisors
          .where((supervisor) => supervisorIds.contains(supervisor.id))
          .toList();
      print('📊 Filtered to ${rawSupervisors.length} supervisors for current admin');

      // 🚀 PERFORMANCE OPTIMIZATION: Get schools counts in parallel with supervisor enrichment
      final supervisors = <Supervisor>[];
      
      // 🚀 PERFORMANCE OPTIMIZATION: Use optimized service for schools count
      print('🔍 Getting schools counts...');
      Map<String, int> schoolsCounts = {};
      try {
        schoolsCounts = await _performanceService.getSupervisorsSchoolsCountOptimized(
          rawSupervisors.map((s) => s.id).toList(),
        );
        print('📊 Schools counts: $schoolsCounts');
      } catch (e) {
        print('❌ Error getting schools counts: $e');
        // Fallback: set all counts to 0
        schoolsCounts = {for (final s in rawSupervisors) s.id: 0};
      }
      
      for (final supervisor in rawSupervisors) {
        final schoolCount = schoolsCounts[supervisor.id] ?? 0;
        print('📊 Supervisor ${supervisor.id} has $schoolCount schools');

        // Create enriched supervisor with school count
        final enrichedSupervisor = supervisor.copyWith(
          schoolsCount: schoolCount,
        );
        supervisors.add(enrichedSupervisor);
      }

      // 🚀 PERFORMANCE OPTIMIZATION: Calculate statistics efficiently
      final totalReports = reports.length;
      final emergencyReports =
          reports.where((r) => r.priority?.toLowerCase() == 'emergency').length;
      final completedReports =
          reports.where((r) => r.status?.toLowerCase() == 'completed').length;
      final overdueReports =
          reports.where((r) => r.status?.toLowerCase() == 'late').length;
      final lateCompletedReports = reports
          .where((r) => r.status?.toLowerCase() == 'late_completed')
          .length;
      final routineReports =
          reports.where((r) => r.priority?.toLowerCase() == 'routine').length;
      final pendingReports = reports.where((r) => r.status == 'pending').length;
      final totalSupervisors = supervisors.length;
      final completionRate =
          totalReports == 0 ? 0.0 : completedReports / totalReports;

      // Maintenance statistics
      final totalMaintenanceReports = maintenanceReports.length;
      final completedMaintenanceReports = maintenanceReports
          .where((r) => r.status?.toLowerCase() == 'completed')
          .length;
      final pendingMaintenanceReports = maintenanceReports
          .where((r) => r.status?.toLowerCase() == 'pending')
          .length;

      // Get inventory counts from parallel results
      final schoolsWithCounts =
          maintenanceCountSummary['schools_with_counts'] ?? 0;
      final schoolsWithDamage = damageCountSummary['schools_with_damage'] ?? 0;

      // 🚀 PERFORMANCE OPTIMIZATION: Get schools data efficiently
      int totalSchools = 0;
      int schoolsWithAchievements = 0;

      // Get total schools count from existing schoolsCounts
      totalSchools = schoolsCounts.values.fold(0, (sum, count) => sum + count);

      // 🚀 PERFORMANCE OPTIMIZATION: Get schools with achievements using optimized service
      if (totalSchools > 0) {
        try {
          // Get all school IDs for this admin's supervisors
          final schoolIdsResponse = await Supabase.instance.client
              .from('supervisor_schools')
              .select('school_id')
              .inFilter('supervisor_id', supervisorIds);

          final adminSchoolIds = schoolIdsResponse
              .map((school) => school['school_id']?.toString())
              .where((id) => id != null && id.isNotEmpty)
              .map((id) => id!) // Convert nullable String to non-nullable String
              .toSet();

          // 🚀 PERFORMANCE OPTIMIZATION: Use optimized service for schools achievements
          if (adminSchoolIds.isNotEmpty) {
            schoolsWithAchievements = await _performanceService.getSchoolsWithAchievementsOptimized(adminSchoolIds);
          }
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

      print('✅ Dashboard data loaded successfully in parallel');
      emit(dashboardData);
    } catch (e) {
      print('❌ Dashboard loading error: $e');
      emit(DashboardError(e.toString()));
    }
  }
}
