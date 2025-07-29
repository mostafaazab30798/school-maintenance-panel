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
      _clearDashboardCaches(); // Clear all dashboard caches
      add(const LoadDashboardData(forceRefresh: true));
    });
  }

  /// Clears cached dashboard data (useful when user logs out or changes)
  static void clearCache() {
    // Clear any static cache if needed
    PerformanceOptimizationService().clearCache();
  }

  /// Clear all dashboard-related caches to ensure fresh data
  void _clearDashboardCaches() {
    // Clear performance cache
    _performanceService.clearCache();
    
    // Clear repository caches - use available methods
    reportRepository.invalidateCache();
    
    // Clear admin service cache
    AdminService.clearCache();
    
    print('🧹 Dashboard caches cleared for fresh data');
  }

  /// Force refresh dashboard with all caches cleared
  void forceRefreshDashboard() {
    print('🔄 Force refreshing dashboard with all caches cleared...');
    
    // Clear all caches
    _clearDashboardCaches();
    
    // Clear admin service cache
    AdminService.clearCache();
    
    // Force refresh dashboard data
    add(const LoadDashboardData(forceRefresh: true));
  }

  /// Force refresh admin supervisor IDs and reload dashboard
  Future<void> forceRefreshAdminData() async {
    print('🔄 Force refreshing admin supervisor IDs...');
    
    // Force refresh supervisor IDs
    await adminService.forceRefreshSupervisorIds();
    
    // Clear all caches
    _clearDashboardCaches();
    
    // Force refresh dashboard data
    add(const LoadDashboardData(forceRefresh: true));
  }

  /// Debug method to verify dashboard counts
  Future<void> debugDashboardCounts() async {
    try {
      print('🔍 DEBUG: Starting comprehensive dashboard counts verification...');
      
      // Get current user info
      final user = Supabase.instance.client.auth.currentUser;
      print('🔍 DEBUG: Current auth user ID: ${user?.id}');
      
      // Get current admin's supervisor IDs
      final supervisorIds = await adminService.getCurrentAdminSupervisorIds();
      print('🔍 DEBUG: Admin supervisor IDs: $supervisorIds');
      
      // Check if admin exists in database
      final adminResponse = await Supabase.instance.client
          .from('admins')
          .select('*')
          .eq('auth_user_id', user?.id ?? '')
          .maybeSingle();
      
      print('🔍 DEBUG: Admin in database: ${adminResponse != null}');
      if (adminResponse != null) {
        print('🔍 DEBUG: Admin ID: ${adminResponse['id']}');
        print('🔍 DEBUG: Admin role: ${adminResponse['role']}');
        
        // Check if this is a super admin
        final isSuperAdmin = adminResponse['role'] == 'super_admin';
        print('🔍 DEBUG: Is super admin: $isSuperAdmin');
        
        if (isSuperAdmin) {
          print('🔍 DEBUG: Super admin detected - they should see all data without supervisor filtering');
        }
      }
      
      // Check supervisors table for this admin
      if (adminResponse != null) {
        final adminId = adminResponse['id'] as String;
        final supervisorsResponse = await Supabase.instance.client
            .from('supervisors')
            .select('id, username, admin_id')
            .eq('admin_id', adminId);
        
        print('🔍 DEBUG: Supervisors assigned to admin $adminId: ${supervisorsResponse.length}');
        for (final supervisor in supervisorsResponse) {
          print('  - Supervisor: ${supervisor['username']} (ID: ${supervisor['id']})');
        }
      }
      
      // Check if there are any reports at all in the database
      final allReportsResponse = await Supabase.instance.client
          .from('reports')
          .select('id, supervisor_id, status, priority')
          .limit(10);
      
      print('🔍 DEBUG: Total reports in database (sample): ${allReportsResponse.length}');
      if (allReportsResponse.isNotEmpty) {
        print('🔍 DEBUG: Sample report supervisor_id: ${allReportsResponse.first['supervisor_id']}');
      }
      
      // Check if there are any maintenance reports at all in the database
      final allMaintenanceResponse = await Supabase.instance.client
          .from('maintenance_reports')
          .select('id, supervisor_id, status')
          .limit(10);
      
      print('🔍 DEBUG: Total maintenance reports in database (sample): ${allMaintenanceResponse.length}');
      if (allMaintenanceResponse.isNotEmpty) {
        print('🔍 DEBUG: Sample maintenance report supervisor_id: ${allMaintenanceResponse.first['supervisor_id']}');
      }
      
      // Get reports for this admin's supervisors
      if (supervisorIds.isNotEmpty) {
        final adminReportsResponse = await Supabase.instance.client
            .from('reports')
            .select('id, supervisor_id, status, priority')
            .inFilter('supervisor_id', supervisorIds);
        
        print('🔍 DEBUG: Reports for this admin\'s supervisors: ${adminReportsResponse.length}');
        
        final adminMaintenanceResponse = await Supabase.instance.client
            .from('maintenance_reports')
            .select('id, supervisor_id, status')
            .inFilter('supervisor_id', supervisorIds);
        
        print('🔍 DEBUG: Maintenance reports for this admin\'s supervisors: ${adminMaintenanceResponse.length}');
        
        // Calculate statistics manually
        final totalReports = adminReportsResponse.length;
        final emergencyReports = adminReportsResponse
            .where((r) => r['priority']?.toString().toLowerCase() == 'emergency')
            .length;
        final completedReports = adminReportsResponse
            .where((r) => r['status']?.toString().toLowerCase() == 'completed')
            .length;
        final pendingReports = adminReportsResponse
            .where((r) => r['status']?.toString() == 'pending')
            .length;
        
        final totalMaintenanceReports = adminMaintenanceResponse.length;
        final completedMaintenanceReports = adminMaintenanceResponse
            .where((r) => r['status']?.toString().toLowerCase() == 'completed')
            .length;
        final pendingMaintenanceReports = adminMaintenanceResponse
            .where((r) => r['status']?.toString() == 'pending')
            .length;
        
        print('🔍 DEBUG: Manual calculation results:');
        print('  - Total reports: $totalReports');
        print('  - Emergency reports: $emergencyReports');
        print('  - Completed reports: $completedReports');
        print('  - Pending reports: $pendingReports');
        print('  - Total maintenance reports: $totalMaintenanceReports');
        print('  - Completed maintenance reports: $completedMaintenanceReports');
        print('  - Pending maintenance reports: $pendingMaintenanceReports');
      } else {
        print('🔍 DEBUG: No supervisor IDs found - checking if super admin...');
        
        // Check if this is a super admin
        final isSuperAdmin = await adminService.isCurrentUserSuperAdmin();
        if (isSuperAdmin) {
          print('🔍 DEBUG: Super admin detected - getting all data without supervisor filtering');
          
          // Get all reports for super admin
          final allReportsResponse = await Supabase.instance.client
              .from('reports')
              .select('id, supervisor_id, status, priority');
          
          print('🔍 DEBUG: All reports in database: ${allReportsResponse.length}');
          
          // Get all maintenance reports for super admin
          final allMaintenanceResponse = await Supabase.instance.client
              .from('maintenance_reports')
              .select('id, supervisor_id, status');
          
          print('🔍 DEBUG: All maintenance reports in database: ${allMaintenanceResponse.length}');
          
          // Calculate statistics for super admin
          final totalReports = allReportsResponse.length;
          final emergencyReports = allReportsResponse
              .where((r) => r['priority']?.toString().toLowerCase() == 'emergency')
              .length;
          final completedReports = allReportsResponse
              .where((r) => r['status']?.toString().toLowerCase() == 'completed')
              .length;
          final pendingReports = allReportsResponse
              .where((r) => r['status']?.toString() == 'pending')
              .length;
          
          final totalMaintenanceReports = allMaintenanceResponse.length;
          final completedMaintenanceReports = allMaintenanceResponse
              .where((r) => r['status']?.toString().toLowerCase() == 'completed')
              .length;
          final pendingMaintenanceReports = allMaintenanceResponse
              .where((r) => r['status']?.toString() == 'pending')
              .length;
          
          print('🔍 DEBUG: Super admin manual calculation results:');
          print('  - Total reports: $totalReports');
          print('  - Emergency reports: $emergencyReports');
          print('  - Completed reports: $completedReports');
          print('  - Pending reports: $pendingReports');
          print('  - Total maintenance reports: $totalMaintenanceReports');
          print('  - Completed maintenance reports: $completedMaintenanceReports');
          print('  - Pending maintenance reports: $pendingMaintenanceReports');
        } else {
          print('🔍 DEBUG: No supervisor IDs found and not super admin - this is why counts are zero!');
        }
      }
      
    } catch (e) {
      print('❌ ERROR: Failed to debug dashboard counts: $e');
    }
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

      // 🚀 DEBUG: Verify counts before loading dashboard
      await debugDashboardCounts();

      // Get current admin's supervisor IDs
      final supervisorIds = await adminService.getCurrentAdminSupervisorIds();
      print('🔍 Dashboard Debug: Admin has ${supervisorIds.length} assigned supervisors: $supervisorIds');

      // Check if current user is super admin
      final isSuperAdmin = await adminService.isCurrentUserSuperAdmin();
      print('🔍 Dashboard Debug: Is super admin: $isSuperAdmin');
      
      // For super admins, we don't filter by supervisor IDs (they can see all data)
      // Note: getCurrentAdminSupervisorIds() returns empty list for super admins
      final effectiveSupervisorIds = isSuperAdmin ? null : (supervisorIds.isNotEmpty ? supervisorIds : null);
      print('🔍 Dashboard Debug: Effective supervisor IDs for filtering: $effectiveSupervisorIds');
      print('🔍 Dashboard Debug: Is super admin: $isSuperAdmin, Supervisor IDs: $supervisorIds');

      // 🚀 DEBUG: Check all FCI assessments in database
      await fciAssessmentRepository.debugAllFciAssessments();

      // 🚀 PERFORMANCE OPTIMIZATION: Load all data in parallel to reduce total time
      print('🚀 Starting parallel data loading...');
      final results = await Future.wait<dynamic>([
        // Get all supervisors (we'll filter by admin later)
        supervisorRepository.fetchSupervisors(),
        // Get ALL reports for this admin's supervisors (no limit for accurate counting)
        reportRepository.fetchReportsForDashboard(
          supervisorIds: effectiveSupervisorIds,
          forceRefresh: event.forceRefresh,
          limit: 10000, // Large limit to get all reports for accurate counting
        ),
        // Get ALL maintenance reports for this admin's supervisors (no limit for accurate counting)
        maintenanceRepository.fetchMaintenanceReportsForDashboard(
          supervisorIds: effectiveSupervisorIds,
          limit: 10000, // Large limit to get all maintenance reports for accurate counting
        ),
        // Get maintenance count summary
        maintenanceCountRepository.getDashboardSummary(
          supervisorIds: effectiveSupervisorIds,
        ),
        // Get damage count summary
        damageCountRepository.getDashboardSummary(
          supervisorIds: effectiveSupervisorIds,
        ),
        // Get FCI assessment summary
        fciAssessmentRepository.getDashboardSummaryForceRefresh(
          supervisorIds: effectiveSupervisorIds,
        ),
      ]);

      final allSupervisors = results[0] as List<Supervisor>;
      final allReports = results[1] as List<Report>;
      final allMaintenanceReports = results[2] as List<MaintenanceReport>;
      final maintenanceCountSummary = results[3] as Map<String, int>;
      final damageCountSummary = results[4] as Map<String, int>;
      final fciAssessmentSummary = results[5] as Map<String, int>;

      // 🚀 DEBUG: Log actual counts for verification
      print('🔍 Dashboard Debug: Actual counts from database:');
      print('  - Total reports fetched: ${allReports.length}');
      print('  - Total maintenance reports fetched: ${allMaintenanceReports.length}');
      print('  - Reports by status: ${allReports.map((r) => r.status).toSet()}');
      print('  - Maintenance reports by status: ${allMaintenanceReports.map((r) => r.status).toSet()}');

      // 🚀 DEBUG: Log FCI assessment data
      print('🔍 FCI Assessment Debug: Raw summary data: $fciAssessmentSummary');
      print('🔍 FCI Assessment Debug: Total assessments: ${fciAssessmentSummary['total_assessments']}');
      print('🔍 FCI Assessment Debug: Submitted assessments: ${fciAssessmentSummary['submitted_assessments']}');
      print('🔍 FCI Assessment Debug: Draft assessments: ${fciAssessmentSummary['draft_assessments']}');
      print('🔍 FCI Assessment Debug: Schools with assessments: ${fciAssessmentSummary['schools_with_assessments']}');

      // Filter supervisors for current admin
      final rawSupervisors = allSupervisors
          .where((supervisor) => effectiveSupervisorIds == null || effectiveSupervisorIds.contains(supervisor.id))
          .toList();

      // 🚀 PERFORMANCE OPTIMIZATION: Get schools counts in parallel with supervisor enrichment
      final supervisors = <Supervisor>[];
      
      // 🚀 PERFORMANCE OPTIMIZATION: Use optimized service for schools count
      Map<String, int> schoolsCounts = {};
      try {
        if (isSuperAdmin) {
          // For super admins, get all supervisors' school counts
          schoolsCounts = await _performanceService.getSupervisorsSchoolsCountOptimized(
            rawSupervisors.map((s) => s.id).toList(),
          );
        } else {
          // For regular admins, only get their assigned supervisors' school counts
          schoolsCounts = await _performanceService.getSupervisorsSchoolsCountOptimized(
            effectiveSupervisorIds ?? [],
          );
        }
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

      // 🚀 PERFORMANCE OPTIMIZATION: Calculate statistics efficiently using ALL data
      final totalReports = allReports.length;
      final emergencyReports =
          allReports.where((r) => r.priority?.toLowerCase() == 'emergency').length;
      final completedReports =
          allReports.where((r) => r.status?.toLowerCase() == 'completed').length;
      final overdueReports =
          allReports.where((r) => r.status?.toLowerCase() == 'late').length;
      final lateCompletedReports = allReports
          .where((r) => r.status?.toLowerCase() == 'late_completed')
          .length;
      final routineReports =
          allReports.where((r) => r.priority?.toLowerCase() == 'routine').length;
      final pendingReports = allReports.where((r) => r.status == 'pending').length;
      final totalSupervisors = supervisors.length;
      final completionRate =
          totalReports == 0 ? 0.0 : completedReports / totalReports;

      // Maintenance statistics using ALL data
      final totalMaintenanceReports = allMaintenanceReports.length;
      final completedMaintenanceReports = allMaintenanceReports
          .where((r) => r.status?.toLowerCase() == 'completed')
          .length;
      final pendingMaintenanceReports = allMaintenanceReports
          .where((r) => r.status?.toLowerCase() == 'pending')
          .length;

      // 🚀 DEBUG: Log calculated statistics
      print('🔍 Dashboard Debug: Calculated statistics:');
      print('  - Total reports: $totalReports');
      print('  - Emergency reports: $emergencyReports');
      print('  - Completed reports: $completedReports');
      print('  - Overdue reports: $overdueReports');
      print('  - Routine reports: $routineReports');
      print('  - Pending reports: $pendingReports');
      print('  - Total maintenance reports: $totalMaintenanceReports');
      print('  - Completed maintenance reports: $completedMaintenanceReports');
      print('  - Pending maintenance reports: $pendingMaintenanceReports');

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
              .inFilter('supervisor_id', effectiveSupervisorIds ?? []);

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

      // 🚀 PERFORMANCE OPTIMIZATION: Limit display data for performance while keeping accurate counts
      final displayReports = allReports.take(50).toList(); // Limit for display
      final displayMaintenanceReports = allMaintenanceReports.take(20).toList(); // Limit for display

      final dashboardData = DashboardLoaded(
        pendingReports: pendingReports,
        routineReports: routineReports,
        totalReports: totalReports, // Use accurate count from all data
        emergencyReports: emergencyReports,
        completedReports: completedReports,
        overdueReports: overdueReports,
        lateCompletedReports: lateCompletedReports,
        totalSupervisors: totalSupervisors,
        completionRate: completionRate,
        reports: displayReports, // Use limited data for display
        supervisors: supervisors,
        totalMaintenanceReports: totalMaintenanceReports, // Use accurate count from all data
        completedMaintenanceReports: completedMaintenanceReports,
        pendingMaintenanceReports: pendingMaintenanceReports,
        maintenanceReports: displayMaintenanceReports, // Use limited data for display
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
