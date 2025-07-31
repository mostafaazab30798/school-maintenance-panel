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

      // 🚀 CRITICAL FIX: Determine admin permissions FIRST before any data loading
      print('🔍 Dashboard Debug: Determining admin permissions...');
      
      // Get admin supervisor IDs and check super admin status FIRST
      final supervisorIds = await adminService.getCurrentAdminSupervisorIds();
      final isSuperAdmin = await adminService.isCurrentUserSuperAdmin();
      
      print('🔍 Dashboard Debug: Admin has ${supervisorIds.length} assigned supervisors: $supervisorIds');
      print('🔍 Dashboard Debug: Is super admin: $isSuperAdmin');
      
      // 🚀 CRITICAL FIX: Determine effective supervisor IDs for filtering
      final effectiveSupervisorIds = isSuperAdmin ? null : (supervisorIds.isNotEmpty ? supervisorIds : null);
      print('🔍 Dashboard Debug: Effective supervisor IDs for filtering: $effectiveSupervisorIds');

      // 🚀 CRITICAL FIX: For regular admins with no supervisors, show empty state immediately
      if (!isSuperAdmin && (supervisorIds.isEmpty || effectiveSupervisorIds == null)) {
        print('🔍 Dashboard Debug: Regular admin has no supervisors - showing empty state');
        emit(DashboardLoaded(
          pendingReports: 0,
          routineReports: 0,
          totalReports: 0,
          emergencyReports: 0,
          completedReports: 0,
          overdueReports: 0,
          lateCompletedReports: 0,
          totalSupervisors: 0,
          completionRate: 0.0,
          reports: <Report>[],
          supervisors: <Supervisor>[],
          totalMaintenanceReports: 0,
          completedMaintenanceReports: 0,
          pendingMaintenanceReports: 0,
          maintenanceReports: <MaintenanceReport>[],
          schoolsWithCounts: 0,
          schoolsWithDamage: 0,
          totalSchools: 0,
          schoolsWithAchievements: 0,
          totalFciAssessments: 0,
          submittedFciAssessments: 0,
          draftFciAssessments: 0,
          schoolsWithFciAssessments: 0,
        ));
        return;
      }

      // 🚀 PERFORMANCE OPTIMIZATION: Load critical data with proper filtering from the start
      print('🚀 Starting progressive data loading with proper admin filtering...');
      
      // Step 1: Load supervisors and basic stats with proper filtering
      final supervisorsFuture = isSuperAdmin 
          ? supervisorRepository.fetchSupervisors()
          : supervisorRepository.fetchSupervisorsForCurrentAdmin();
      final basicStatsFuture = _loadBasicStats(effectiveSupervisorIds);
      
      final basicResults = await Future.wait([supervisorsFuture, basicStatsFuture]);
      final allSupervisors = basicResults[0] as List<Supervisor>;
      final basicStats = basicResults[1] as Map<String, dynamic>;
      
      // Step 2: Emit basic data immediately for faster UI response
      final basicDashboardData = DashboardLoaded(
        pendingReports: basicStats['pendingReports'] ?? 0,
        routineReports: basicStats['routineReports'] ?? 0,
        totalReports: basicStats['totalReports'] ?? 0,
        emergencyReports: basicStats['emergencyReports'] ?? 0,
        completedReports: basicStats['completedReports'] ?? 0,
        overdueReports: basicStats['overdueReports'] ?? 0,
        lateCompletedReports: basicStats['lateCompletedReports'] ?? 0,
        totalSupervisors: allSupervisors.length,
        completionRate: basicStats['completionRate'] ?? 0.0,
        reports: <Report>[], // Will be loaded in background
        supervisors: <Supervisor>[], // Will be loaded in background
        totalMaintenanceReports: basicStats['totalMaintenanceReports'] ?? 0,
        completedMaintenanceReports: basicStats['completedMaintenanceReports'] ?? 0,
        pendingMaintenanceReports: basicStats['pendingMaintenanceReports'] ?? 0,
        maintenanceReports: <MaintenanceReport>[], // Will be loaded in background
        schoolsWithCounts: basicStats['schoolsWithCounts'] ?? 0,
        schoolsWithDamage: basicStats['schoolsWithDamage'] ?? 0,
        totalSchools: basicStats['totalSchools'] ?? 0,
        schoolsWithAchievements: basicStats['schoolsWithAchievements'] ?? 0,
        totalFciAssessments: basicStats['totalFciAssessments'] ?? 0,
        submittedFciAssessments: basicStats['submittedFciAssessments'] ?? 0,
        draftFciAssessments: basicStats['draftFciAssessments'] ?? 0,
        schoolsWithFciAssessments: basicStats['schoolsWithFciAssessments'] ?? 0,
      );
      
      emit(basicDashboardData);
      
      // Step 3: Load detailed data in background with proper filtering
      final detailedResults = await Future.wait<dynamic>([
        // Get reports with proper filtering from the start
        reportRepository.fetchReportsForDashboard(
          supervisorIds: effectiveSupervisorIds,
          forceRefresh: event.forceRefresh,
          limit: 100, // Reduced from 10000 to 100 for faster loading
        ),
        // Get maintenance reports with proper filtering from the start
        maintenanceRepository.fetchMaintenanceReportsForDashboard(
          supervisorIds: effectiveSupervisorIds,
          limit: 100, // Reduced from 10000 to 100 for faster loading
        ),
        // Get maintenance count summary with proper filtering
        maintenanceCountRepository.getDashboardSummary(
          supervisorIds: effectiveSupervisorIds,
        ),
        // Get damage count summary with proper filtering
        damageCountRepository.getDashboardSummary(
          supervisorIds: effectiveSupervisorIds,
        ),
        // Get FCI assessment summary with proper filtering
        fciAssessmentRepository.getDashboardSummaryForceRefresh(
          supervisorIds: effectiveSupervisorIds,
        ),
        // Get schools count efficiently with proper filtering
        _getSchoolsCount(effectiveSupervisorIds),
        // Get schools with achievements efficiently with proper filtering
        _getSchoolsWithAchievements(effectiveSupervisorIds),
      ]);

      final allReports = detailedResults[0] as List<Report>;
      final allMaintenanceReports = detailedResults[1] as List<MaintenanceReport>;
      final maintenanceCountSummary = detailedResults[2] as Map<String, int>;
      final damageCountSummary = detailedResults[3] as Map<String, int>;
      final fciAssessmentSummary = detailedResults[4] as Map<String, int>;
      final totalSchools = detailedResults[5] as int;
      final schoolsWithAchievements = detailedResults[6] as int;

      // 🚀 VERIFICATION: Cross-check schools count
      await _verifySchoolsCount(effectiveSupervisorIds, totalSchools);

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

      // 🚀 CRITICAL FIX: Supervisors are already filtered by admin permissions
      final supervisors = allSupervisors;

      // 🚀 PERFORMANCE OPTIMIZATION: Get schools counts in parallel with supervisor enrichment
      final enrichedSupervisors = <Supervisor>[];
      
      // 🚀 PERFORMANCE OPTIMIZATION: Use optimized service for schools count
      Map<String, int> schoolsCounts = {};
      try {
        if (isSuperAdmin) {
          // For super admins, get all supervisors' school counts
          schoolsCounts = await _performanceService.getSupervisorsSchoolsCountOptimized(
            supervisors.map((s) => s.id).toList(),
          );
        } else {
          // For regular admins, only get their assigned supervisors' school counts
          schoolsCounts = await _performanceService.getSupervisorsSchoolsCountOptimized(
            effectiveSupervisorIds ?? [],
          );
        }
      } catch (e) {
        // Fallback: set all counts to 0
        schoolsCounts = {for (final s in supervisors) s.id: 0};
      }
      
      for (final supervisor in supervisors) {
        final schoolCount = schoolsCounts[supervisor.id] ?? 0;

        // Create enriched supervisor with school count
        final enrichedSupervisor = supervisor.copyWith(
          schoolsCount: schoolCount,
        );
        enrichedSupervisors.add(enrichedSupervisor);
      }

      // 🚀 PERFORMANCE OPTIMIZATION: Calculate statistics efficiently
      final totalReports = allReports.length;
      final emergencyReports = allReports
          .where((r) => r.priority?.toLowerCase() == 'emergency')
          .length;
      final completedReports = allReports
          .where((r) => r.status?.toLowerCase() == 'completed')
          .length;
      final overdueReports = allReports
          .where((r) => r.status?.toLowerCase() == 'overdue')
          .length;
      final routineReports = allReports
          .where((r) => r.type?.toLowerCase() == 'routine')
          .length;
      final pendingReports = allReports
          .where((r) => r.status?.toLowerCase() == 'pending')
          .length;
      final lateCompletedReports = allReports
          .where((r) => r.status?.toLowerCase() == 'late_completed')
          .length;

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

      // 🚀 PERFORMANCE OPTIMIZATION: Use schools data from detailed results (loaded in parallel)
      // totalSchools and schoolsWithAchievements are now loaded efficiently in the detailed phase

      // 🚀 PERFORMANCE OPTIMIZATION: Calculate final statistics
      final totalSupervisors = supervisors.length;
      final completionRate = totalReports > 0 
          ? (completedReports / totalReports) * 100 
          : 0.0;

      // 🚀 PERFORMANCE OPTIMIZATION: Limit display data for performance while keeping accurate counts
      final displayReports = allReports.take(50).toList(); // Limit for display
      final displayMaintenanceReports = allMaintenanceReports.take(20).toList(); // Limit for display

      // 🚀 DEBUG: Log final dashboard data for verification
      print('🔍 Dashboard Final Data Debug:');
      print('  - Total Schools: $totalSchools');
      print('  - Schools with Achievements: $schoolsWithAchievements');
      print('  - Total Supervisors: ${supervisors.length}');
      print('  - Total Reports: $totalReports');
      print('  - Total Maintenance Reports: $totalMaintenanceReports');

      final dashboardData = DashboardLoaded(
        pendingReports: pendingReports,
        routineReports: routineReports,
        totalReports: totalReports, // Use accurate count from all data
        emergencyReports: emergencyReports,
        completedReports: completedReports,
        overdueReports: overdueReports,
        lateCompletedReports: lateCompletedReports,
        totalSupervisors: supervisors.length, // Use filtered supervisors count
        completionRate: completionRate,
        reports: displayReports, // Use limited data for display
        supervisors: enrichedSupervisors, // Use filtered supervisors (admin's assigned supervisors only)
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

  /// 🚀 PERFORMANCE OPTIMIZATION: Load basic stats quickly for faster perceived performance
  Future<Map<String, dynamic>> _loadBasicStats(List<String>? effectiveSupervisorIds) async {
    try {
      // 🚀 CRITICAL FIX: Ensure admin filtering is applied from the start
      print('🔍 Basic Stats Debug: Loading with supervisor IDs: $effectiveSupervisorIds');
      
      // Load only essential data with proper filtering from the start
      final basicResults = await Future.wait<dynamic>([
        // Get basic report counts with proper filtering
        reportRepository.fetchReportsForDashboard(
          supervisorIds: effectiveSupervisorIds,
          limit: 20, // Very small limit for basic stats
        ),
        // Get basic maintenance counts with proper filtering
        maintenanceRepository.fetchMaintenanceReportsForDashboard(
          supervisorIds: effectiveSupervisorIds,
          limit: 20, // Very small limit for basic stats
        ),
        // Get basic FCI assessment counts with proper filtering
        fciAssessmentRepository.getDashboardSummaryForceRefresh(
          supervisorIds: effectiveSupervisorIds,
        ),
      ]);

      final basicReports = basicResults[0] as List<Report>;
      final basicMaintenanceReports = basicResults[1] as List<MaintenanceReport>;
      final fciAssessmentSummary = basicResults[2] as Map<String, int>;

      print('🔍 Basic Stats Debug: Loaded ${basicReports.length} reports, ${basicMaintenanceReports.length} maintenance reports');

      // Calculate basic stats
      final totalReports = basicReports.length;
      final emergencyReports = basicReports
          .where((r) => r.priority?.toLowerCase() == 'emergency')
          .length;
      final completedReports = basicReports
          .where((r) => r.status?.toLowerCase() == 'completed')
          .length;
      final pendingReports = basicReports
          .where((r) => r.status?.toLowerCase() == 'pending')
          .length;
      final routineReports = basicReports
          .where((r) => r.type?.toLowerCase() == 'routine')
          .length;
      final overdueReports = basicReports
          .where((r) => r.status?.toLowerCase() == 'overdue')
          .length;
      final lateCompletedReports = basicReports
          .where((r) => r.status?.toLowerCase() == 'late_completed')
          .length;

      final totalMaintenanceReports = basicMaintenanceReports.length;
      final completedMaintenanceReports = basicMaintenanceReports
          .where((r) => r.status?.toLowerCase() == 'completed')
          .length;
      final pendingMaintenanceReports = basicMaintenanceReports
          .where((r) => r.status?.toLowerCase() == 'pending')
          .length;

      // Calculate completion rate
      final completionRate = totalReports > 0 
          ? (completedReports / totalReports) * 100 
          : 0.0;

      print('🔍 Basic Stats Debug: Calculated stats - Total: $totalReports, Emergency: $emergencyReports, Completed: $completedReports');

      return {
        'totalReports': totalReports,
        'emergencyReports': emergencyReports,
        'completedReports': completedReports,
        'pendingReports': pendingReports,
        'routineReports': routineReports,
        'overdueReports': overdueReports,
        'lateCompletedReports': lateCompletedReports,
        'totalMaintenanceReports': totalMaintenanceReports,
        'completedMaintenanceReports': completedMaintenanceReports,
        'pendingMaintenanceReports': pendingMaintenanceReports,
        'completionRate': completionRate,
        'schoolsWithCounts': 0, // Will be loaded in detailed phase
        'schoolsWithDamage': 0, // Will be loaded in detailed phase
        'totalSchools': 0, // Will be loaded in detailed phase
        'schoolsWithAchievements': 0, // Will be loaded in detailed phase
        'totalFciAssessments': fciAssessmentSummary['total_assessments'] ?? 0,
        'submittedFciAssessments': fciAssessmentSummary['submitted_assessments'] ?? 0,
        'draftFciAssessments': fciAssessmentSummary['draft_assessments'] ?? 0,
        'schoolsWithFciAssessments': fciAssessmentSummary['schools_with_assessments'] ?? 0,
      };
    } catch (e) {
      print('❌ ERROR: Failed to load basic stats: $e');
      // Return default values if basic stats fail
      return {
        'totalReports': 0,
        'emergencyReports': 0,
        'completedReports': 0,
        'pendingReports': 0,
        'routineReports': 0,
        'overdueReports': 0,
        'lateCompletedReports': 0,
        'totalMaintenanceReports': 0,
        'completedMaintenanceReports': 0,
        'pendingMaintenanceReports': 0,
        'completionRate': 0.0,
        'schoolsWithCounts': 0,
        'schoolsWithDamage': 0,
        'totalSchools': 0,
        'schoolsWithAchievements': 0,
        'totalFciAssessments': 0,
        'submittedFciAssessments': 0,
        'draftFciAssessments': 0,
        'schoolsWithFciAssessments': 0,
      };
    }
  }

  /// 🚀 PERFORMANCE OPTIMIZATION: Get schools count efficiently
  Future<int> _getSchoolsCount(List<String>? effectiveSupervisorIds) async {
    if (effectiveSupervisorIds == null || effectiveSupervisorIds.isEmpty) return 0;
    
    try {
      // Clear cache to ensure fresh data
      _performanceService.clearCache();
      
      // Use a more robust query to ensure we get unique schools
      final response = await Supabase.instance.client
          .from('supervisor_schools')
          .select('school_id')
          .inFilter('supervisor_id', effectiveSupervisorIds);
      
      // Create a set to automatically remove duplicates
      final uniqueSchools = <String>{};
      
      for (final item in response) {
        final schoolId = item['school_id']?.toString();
        if (schoolId != null && schoolId.isNotEmpty) {
          uniqueSchools.add(schoolId);
        }
      }
      
      // 🚀 DEBUG: Log schools count for verification
      print('🔍 Schools Count Debug:');
      print('  - Supervisor IDs: $effectiveSupervisorIds');
      print('  - Total records from database: ${response.length}');
      print('  - Unique schools count: ${uniqueSchools.length}');
      print('  - Unique school IDs: ${uniqueSchools.toList()}');
      
      // Additional verification: Check if there are any duplicates in the raw data
      final allSchoolIds = response.map((item) => item['school_id']?.toString()).where((id) => id != null && id.isNotEmpty).toList();
      final rawCount = allSchoolIds.length;
      final uniqueCount = uniqueSchools.length;
      
      if (rawCount != uniqueCount) {
        print('⚠️ WARNING: Found ${rawCount - uniqueCount} duplicate school assignments');
        print('  - Raw count: $rawCount');
        print('  - Unique count: $uniqueCount');
      }
      
      return uniqueSchools.length;
    } catch (e) {
      print('❌ Error getting schools count: $e');
      return 0;
    }
  }

  /// 🚀 PERFORMANCE OPTIMIZATION: Get schools with achievements efficiently
  Future<int> _getSchoolsWithAchievements(List<String>? effectiveSupervisorIds) async {
    if (effectiveSupervisorIds == null || effectiveSupervisorIds.isEmpty) return 0;
    
    try {
      // First get school IDs for these supervisors
      final schoolIdsResponse = await Supabase.instance.client
          .from('supervisor_schools')
          .select('school_id')
          .inFilter('supervisor_id', effectiveSupervisorIds);

      final adminSchoolIds = schoolIdsResponse
          .map((school) => school['school_id']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .toSet();

      if (adminSchoolIds.isEmpty) return 0;

      // Then get schools with achievements
      final achievementsResponse = await Supabase.instance.client
          .from('achievement_photos')
          .select('school_id')
          .inFilter('school_id', adminSchoolIds.toList())
          .not('school_id', 'is', null);
      
      final schoolsWithAchievements = achievementsResponse
          .map((item) => item['school_id'])
          .toSet();
      
      return schoolsWithAchievements.length;
    } catch (e) {
      print('❌ Error getting schools with achievements: $e');
      return 0;
    }
  }

  /// 🚀 VERIFICATION: Cross-check schools count with actual schools table
  Future<void> _verifySchoolsCount(List<String>? effectiveSupervisorIds, int calculatedCount) async {
    if (effectiveSupervisorIds == null || effectiveSupervisorIds.isEmpty) return;
    
    try {
      // Get unique school IDs from supervisor_schools
      final supervisorSchoolsResponse = await Supabase.instance.client
          .from('supervisor_schools')
          .select('school_id')
          .inFilter('supervisor_id', effectiveSupervisorIds);
      
      final uniqueSchoolIds = supervisorSchoolsResponse
          .map((item) => item['school_id']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .toSet();
      
      // Verify these schools exist in the schools table
      if (uniqueSchoolIds.isNotEmpty) {
        final schoolsResponse = await Supabase.instance.client
            .from('schools')
            .select('id')
            .inFilter('id', uniqueSchoolIds.toList());
        
        final existingSchoolIds = schoolsResponse
            .map((item) => item['id']?.toString())
            .where((id) => id != null && id.isNotEmpty)
            .toSet();
        
        print('🔍 Schools Count Verification:');
        print('  - Calculated unique schools: $calculatedCount');
        print('  - Schools from supervisor_schools: ${uniqueSchoolIds.length}');
        print('  - Schools existing in schools table: ${existingSchoolIds.length}');
        print('  - Missing schools: ${uniqueSchoolIds.length - existingSchoolIds.length}');
        
        if (calculatedCount != existingSchoolIds.length) {
          print('⚠️ WARNING: Schools count mismatch!');
          print('  - Expected: ${existingSchoolIds.length}');
          print('  - Got: $calculatedCount');
        }
      }
    } catch (e) {
      print('❌ Error verifying schools count: $e');
    }
  }
}
