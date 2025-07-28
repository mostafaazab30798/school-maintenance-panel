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
import '../../../data/repositories/fci_assessment_repository.dart';
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
  final FciAssessmentRepository fciAssessmentRepository;
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
    required this.fciAssessmentRepository,
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
      print('🔍 Dashboard Debug: Admin has ${supervisorIds.length} assigned supervisors: $supervisorIds');

      // 🚀 DEBUG: Check all FCI assessments in database
      await fciAssessmentRepository.debugAllFciAssessments();

      // 🚀 PERFORMANCE OPTIMIZATION: Load all data in parallel to reduce total time
      print('🚀 Starting parallel data loading...');
      final results = await Future.wait<dynamic>([
        // Get all supervisors (we'll filter by admin later)
        supervisorRepository.fetchSupervisors(),
        // Get all reports for this admin's supervisors
        reportRepository.fetchReportsForDashboard(
          supervisorIds: supervisorIds,
          forceRefresh: event.forceRefresh,
          limit: 50,
        ),
        // Get all maintenance reports for this admin's supervisors
        maintenanceRepository.fetchMaintenanceReportsForDashboard(
          supervisorIds: supervisorIds,
          limit: 20,
        ),
        // Get maintenance count summary
        maintenanceCountRepository.getDashboardSummary(
          supervisorIds: supervisorIds,
        ),
        // Get damage count summary
        damageCountRepository.getDashboardSummary(
          supervisorIds: supervisorIds,
        ),
        // Get FCI assessment summary
        fciAssessmentRepository.getDashboardSummaryForceRefresh(
          supervisorIds: supervisorIds,
        ),
      ]);

      final allSupervisors = results[0] as List<Supervisor>;
      final reports = results[1] as List<Report>;
      final maintenanceReports = results[2] as List<MaintenanceReport>;
      final maintenanceCountSummary = results[3] as Map<String, int>;
      final damageCountSummary = results[4] as Map<String, int>;
      final fciAssessmentSummary = results[5] as Map<String, int>;

      // 🚀 DEBUG: Log FCI assessment data
      print('🔍 FCI Assessment Debug: Raw summary data: $fciAssessmentSummary');
      print('🔍 FCI Assessment Debug: Total assessments: ${fciAssessmentSummary['total_assessments']}');
      print('🔍 FCI Assessment Debug: Submitted assessments: ${fciAssessmentSummary['submitted_assessments']}');
      print('🔍 FCI Assessment Debug: Draft assessments: ${fciAssessmentSummary['draft_assessments']}');
      print('🔍 FCI Assessment Debug: Schools with assessments: ${fciAssessmentSummary['schools_with_assessments']}');

      // Filter supervisors for current admin
      final rawSupervisors = allSupervisors
          .where((supervisor) => supervisorIds.contains(supervisor.id))
          .toList();

      // 🚀 PERFORMANCE OPTIMIZATION: Get schools counts in parallel with supervisor enrichment
      final supervisors = <Supervisor>[];
      
      // 🚀 PERFORMANCE OPTIMIZATION: Use optimized service for schools count
      Map<String, int> schoolsCounts = {};
      try {
        schoolsCounts = await _performanceService.getSupervisorsSchoolsCountOptimized(
          rawSupervisors.map((s) => s.id).toList(),
        );
      } catch (e) {
        // Fallback: set all counts to 0
        schoolsCounts = {for (final s in rawSupervisors) s.id: 0};
      }
      
      for (final supervisor in rawSupervisors) {
        final schoolCount = schoolsCounts[supervisor.id] ?? 0;

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

      // Get FCI assessment counts from parallel results
      final totalFciAssessments = fciAssessmentSummary['total_assessments'] ?? 0;
      final submittedFciAssessments = fciAssessmentSummary['submitted_assessments'] ?? 0;
      final draftFciAssessments = fciAssessmentSummary['draft_assessments'] ?? 0;
      final schoolsWithFciAssessments = fciAssessmentSummary['schools_with_assessments'] ?? 0;

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
          // Fallback: set all counts to 0
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
        totalFciAssessments: totalFciAssessments,
        submittedFciAssessments: submittedFciAssessments,
        draftFciAssessments: draftFciAssessments,
        schoolsWithFciAssessments: schoolsWithFciAssessments,
      );

      emit(dashboardData);
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
