import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/admin_management_service.dart';
import '../../core/services/cache_service.dart';
import '../../data/repositories/supervisor_repository.dart';
import '../../data/repositories/report_repository.dart';
import '../../data/repositories/maintenance_repository.dart';
import '../../logic/blocs/super_admin/super_admin_bloc.dart';
import '../../logic/blocs/super_admin/super_admin_state.dart';
import '../../logic/blocs/super_admin/super_admin_event.dart';
import '../widgets/super_admin/super_admin_app_bar.dart';
import '../widgets/super_admin/admins_section.dart';
import '../widgets/super_admin/modern_supervisor_card.dart';
import '../widgets/dashboard/indicator_card.dart';
import '../widgets/dashboard/completion_progress_card.dart';
import '../widgets/super_admin/create_admin_dialog.dart';
import '../widgets/super_admin/admins_section/team_management_dialog.dart';
import '../widgets/super_admin/admins_section/admin_reports_dialog.dart';
import '../widgets/super_admin/admins_section/admin_maintenance_dialog.dart';
import '../widgets/super_admin/dashboard/statistics_section.dart';
import '../widgets/super_admin/dashboard/admin_analytics_section.dart';
import '../widgets/super_admin/dashboard/supervisor_analytics_section.dart';
import '../widgets/super_admin/dialogs/supervisor_detail_dialog.dart';
import '../widgets/super_admin/dialogs/admin_detail_dialogs.dart';
import '../../data/models/supervisor.dart';
import '../widgets/saudi_plate.dart';
import '../widgets/common/standard_refresh_button.dart';
import '../widgets/common/esc_dismissible_dialog.dart';

import '../widgets/common/ui_components/chips_and_badges.dart';
import '../widgets/common/ui_components/stat_cards.dart';
import '../widgets/common/ui_components/ranking_utils.dart';
import '../widgets/common/ui_components/format_utils.dart';
import '../../core/services/navigation/supervisor_navigation_service.dart';
import '../../core/services/navigation/dashboard_state_service.dart';
import '../../core/services/dialog_service.dart';
import 'package:go_router/go_router.dart';

class SuperAdminDashboardScreen extends StatelessWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return BlocProvider(
      create: (context) => SuperAdminBloc(
        AdminManagementService(supabase),
        SupervisorRepository(supabase),
        ReportRepository(supabase),
        MaintenanceReportRepository(supabase),
      )..add(LoadSuperAdminData()),
      child: const _SuperAdminDashboardView(),
    );
  }
}

class _SuperAdminDashboardView extends StatefulWidget {
  const _SuperAdminDashboardView();

  @override
  State<_SuperAdminDashboardView> createState() =>
      _SuperAdminDashboardViewState();
}

class _SuperAdminDashboardViewState extends State<_SuperAdminDashboardView> {
  @override
  void initState() {
    super.initState();
    // Initialize dashboard state using the service
    DashboardStateService.initializeDashboard();
  }

  @override
  void dispose() {
    DashboardStateService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: SuperAdminAppBar(
          onCreateAdmin: () => _showCreateAdminDialog(context),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                  : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
            ),
          ),
          child: BlocListener<SuperAdminBloc, SuperAdminState>(
            listener: (context, state) {
              if (state is SuperAdminLoaded) {
                // Update cache indicator when data is loaded
                DashboardStateService.updateCacheStatus();
              }
            },
            child: BlocBuilder<SuperAdminBloc, SuperAdminState>(
              builder: (context, state) {
                if (state is SuperAdminLoading) {
                  return _buildLoadingView();
                } else if (state is SuperAdminPartiallyLoaded) {
                  return _buildPartialLoadingView(context, state);
                } else if (state is SuperAdminError) {
                  return _buildErrorView(context, state.message);
                } else if (state is SuperAdminLoaded) {
                  return _buildDashboardContent(context, state);
                }
                return _buildWelcomeView();
              },
            ),
          ),
        ),

      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B46C1)),
          ),
          SizedBox(height: 16),
          Text(
            'جاري تحميل البيانات...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartialLoadingView(BuildContext context, SuperAdminPartiallyLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show basic admin/supervisor info immediately
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'نظرة عامة سريعة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickStatCard(
                        'إجمالي المدراء',
                        '${state.admins.length}',
                        Icons.people,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickStatCard(
                        'إجمالي المشرفين',
                        '${state.allSupervisors.length}',
                        Icons.supervisor_account,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Loading indicator for detailed stats
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Column(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B46C1)),
                ),
                SizedBox(height: 16),
                Text(
                  'جاري تحميل الإحصائيات التفصيلية...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.admin_panel_settings_rounded,
            size: 80,
            color: Color(0xFF6B46C1),
          ),
          SizedBox(height: 16),
          Text(
            'مرحباً بك في لوحة المدير العام',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'إدارة شاملة للمسؤولين والمشرفين',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            StandardRefreshElevatedButton(
              onPressed: () => context
                  .read<SuperAdminBloc>()
                  .add(LoadSuperAdminData(forceRefresh: true)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, SuperAdminLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Statistics - keeping only the system statistics with progress indicator and reports grid
          StatisticsSection(
            state: state,
            onNavigateToAllReports: () => SupervisorNavigationService.navigateToAllReports(context),
            onNavigateToCompletedReports: () => SupervisorNavigationService.navigateToCompletedReports(context),
            onNavigateToAllMaintenance: () => SupervisorNavigationService.navigateToAllMaintenance(context),
          ),
          const SizedBox(height: 24),

          // Admin Performance Analytics
          AdminAnalyticsSection(
            state: state,
            onTeamManagement: _showTeamManagementDialog,
            onShowReports: _showAdminReports,
            onShowMaintenance: _showAdminMaintenance,
          ),
          const SizedBox(height: 24),

          // Supervisor Performance Analytics
          SupervisorAnalyticsSection(
            state: state,
            onShowSupervisorDetails: (supervisor) => SupervisorDetailDialog.show(context, supervisor),
            onNavigateToSupervisorReports: (supervisorId, username) =>
                SupervisorNavigationService.navigateToSupervisorReports(context, supervisorId, username),
            onNavigateToSupervisorMaintenance: (supervisorId, username) =>
                SupervisorNavigationService.navigateToSupervisorMaintenance(context, supervisorId, username),
            onNavigateToSupervisorCompleted: (supervisorId, username) =>
                SupervisorNavigationService.navigateToSupervisorCompleted(context, supervisorId, username),
            onNavigateToSupervisorLateReports: (supervisorId, username) =>
                SupervisorNavigationService.navigateToSupervisorLateReports(context, supervisorId, username),
            onNavigateToSupervisorLateCompleted: (supervisorId, username) =>
                SupervisorNavigationService.navigateToSupervisorLateCompleted(context, supervisorId, username),
          ),
        ],
      ),
    );
  }













  void _showTeamManagementDialog(
    BuildContext context,
    dynamic admin,
    List<Map<String, dynamic>> allSupervisors,
  ) {
    context.showEscDismissibleDialog(
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<SuperAdminBloc>(),
        child: TeamManagementDialog(
          admin: admin,
          allSupervisors: allSupervisors,
          onSave: (selectedSupervisorIds) {
            // Handle supervisor assignment
            context.read<SuperAdminBloc>().add(AssignSupervisorsToAdmin(
                  adminId: admin.id,
                  supervisorIds: selectedSupervisorIds,
                ));
          },
        ),
      ),
    );
  }

  void _showAdminReports(
    BuildContext context,
    dynamic admin,
    List<Map<String, dynamic>> adminSupervisorsWithStats,
  ) {
    context.showEscDismissibleDialog(
      barrierDismissible: true,
      builder: (dialogContext) => AdminReportsDialog(
        admin: admin,
        adminSupervisorsWithStats: adminSupervisorsWithStats,
      ),
    );
  }

  void _showAdminMaintenance(
    BuildContext context,
    dynamic admin,
    List<Map<String, dynamic>> adminSupervisorsWithStats,
  ) {
    context.showEscDismissibleDialog(
      barrierDismissible: true,
      builder: (dialogContext) => AdminMaintenanceDialog(
        admin: admin,
        adminSupervisorsWithStats: adminSupervisorsWithStats,
      ),
    );
  }











  void _showCreateAdminDialog(BuildContext context) {
    context.showEscDismissibleDialog(
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<SuperAdminBloc>(),
        child: const CreateAdminDialog(),
      ),
    );
  }



  // Helper Widgets
  Widget _buildEnhancedDetailItem(BuildContext context, String label,
      String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  void _showSystemProgressDetails(BuildContext context, int totalWork,
      int completedWork, double completionRate) {
    DialogService.showProgressDetails(
      context,
      title: 'تفاصيل معدل الإنجاز العام',
      totalWork: totalWork,
      completedWork: completedWork,
      completionRate: completionRate,
    );
  }
}
