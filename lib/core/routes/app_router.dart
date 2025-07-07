import 'package:admin_panel/data/repositories/multi_reports_repository.dart';
import 'package:admin_panel/presentation/screens/report_screen.dart';
import 'package:admin_panel/presentation/screens/all_reports_screen.dart';
import 'package:admin_panel/presentation/screens/all_maintenance_screen.dart';
import 'package:admin_panel/presentation/screens/count_inventory_screen.dart';
import 'package:admin_panel/presentation/screens/damage_inventory_screen.dart';
import 'package:admin_panel/presentation/screens/damage_count_detail_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/report_repository.dart';
import '../../data/repositories/maintenance_repository.dart';
import '../../data/repositories/maintenance_count_repository.dart';
import '../../data/repositories/damage_count_repository.dart';
import '../../data/repositories/supervisor_repository.dart';
import '../../logic/blocs/maintenance_reports/maintenance_bloc.dart';
import '../../logic/blocs/maintenance_reports/maintenance_view_bloc.dart';
import '../../logic/blocs/maintenance_reports/maintenance_view_event.dart';
import '../../logic/blocs/maintenance_counts/maintenance_counts_bloc.dart';
import '../../logic/blocs/multi_reports/multi_reports_bloc.dart';
import '../../logic/blocs/reports/report_bloc.dart';
import '../../logic/blocs/reports/report_event.dart';
import '../../logic/blocs/dashboard/dashboard_bloc.dart';
import '../../logic/blocs/dashboard/dashboard_event.dart';
import '../../logic/blocs/super_admin/super_admin_bloc.dart';
import '../../logic/blocs/super_admin/super_admin_event.dart';
import '../../logic/cubits/add_multiple_reports_cubit.dart';
import '../../presentation/screens/add_multiple_maintenance_screen.dart';
import '../../presentation/screens/auth_screen.dart';
import '../../presentation/screens/regular_admin_dashboard_screen.dart';
import '../../presentation/screens/add_multiple_reports_screen.dart';
import '../../presentation/screens/maintenance_reports_screen.dart';
import '../../presentation/screens/supervisor_list_screen.dart';
import '../../presentation/screens/admin_managment_screen.dart';
import '../../presentation/screens/test_connection_screen.dart';
import '../../presentation/screens/debug_auth_screen.dart';
import '../../presentation/screens/super_admin_dashboard_screen.dart';
import '../../presentation/screens/super_admin_progress_screen.dart';
import '../../presentation/screens/admins_list_screen.dart';
import '../../presentation/screens/admin_progress_screen.dart';
import '../../presentation/screens/supervisors_list_screen.dart';
import '../../presentation/screens/admins_list_screen.dart';
import '../../presentation/screens/schools_list_screen.dart';
import '../../presentation/screens/school_details_screen.dart';
import '../../presentation/screens/schools_with_achievements_screen.dart';

import '../../core/services/admin_service.dart';
import '../../core/services/admin_management_service.dart';
// Commented out for now
// import '../../presentation/screens/supervisor_auth_link_screen.dart';

// Simple router with no redirects - authentication is handled in the auth screen
final GoRouter appRouter = GoRouter(
  initialLocation: '/auth',
  // Disable redirects completely - we'll handle navigation in the auth screen
  redirect: null,
  routes: [
    GoRoute(
      path: '/auth',
      name: 'auth',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/',
      name: 'dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/super-admin',
      name: 'super-admin',
      builder: (context, state) => const SuperAdminDashboardScreen(),
    ),
    GoRoute(
      path: '/super-admin-progress',
      name: 'super-admin-progress',
      builder: (context, state) => BlocProvider(
        create: (context) => SuperAdminBloc(
          AdminManagementService(Supabase.instance.client),
          SupervisorRepository(Supabase.instance.client),
          ReportRepository(Supabase.instance.client),
          MaintenanceReportRepository(Supabase.instance.client),
        )..add(LoadSuperAdminData()),
        child: const SuperAdminProgressScreen(),
      ),
    ),
    GoRoute(
      path: '/admins',
      name: 'admins',
      builder: (context, state) => const AdminsListScreen(),
    ),
    GoRoute(
      path: '/supervisors-list',
      name: 'supervisors-list',
      builder: (context, state) => const SupervisorsListScreen(),
    ),
    GoRoute(
      path: '/admins-list',
      name: 'admins-list',
      builder: (context, state) => const AdminsListScreen(),
    ),
    GoRoute(
      path: '/progress',
      name: 'progress',
      builder: (context, state) => BlocProvider(
        create: (context) => DashboardBloc(
          reportRepository: ReportRepository(Supabase.instance.client),
          maintenanceRepository:
              MaintenanceReportRepository(Supabase.instance.client),
          maintenanceCountRepository:
              MaintenanceCountRepository(Supabase.instance.client),
          damageCountRepository:
              DamageCountRepository(Supabase.instance.client),
          supervisorRepository: SupervisorRepository(Supabase.instance.client),
          adminService: AdminService(Supabase.instance.client),
        )..add(const LoadDashboardData()),
        child: const AdminProgressScreen(),
      ),
    ),
    GoRoute(
      path: '/reports',
      name: 'reports',
      builder: (context, state) {
        final title = state.uri.queryParameters['title'] ?? 'جميع البلاغات';
        final status = state.uri.queryParameters['status'];
        final priority = state.uri.queryParameters['priority'];
        final supervisorId = state.uri.queryParameters['supervisorId'];
        final type = state.uri.queryParameters['type'];
        final schoolName = state.uri.queryParameters['schoolName'];

        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => ReportBloc(
                ReportRepository(Supabase.instance.client),
                AdminService(Supabase.instance.client),
              )..add(FetchReports(
                  supervisorId: supervisorId,
                  status: status,
                  priority: priority,
                  type: type,
                  schoolName: schoolName)),
            ),
          ],
          child: ReportScreen(
            title: title,
            supervisorId: supervisorId,
            status: status,
            priority: priority,
            type: type,
            schoolName: schoolName,
          ),
        );
      },
    ),
    GoRoute(
      path: '/maintenance-reports',
      name: 'maintenance-reports',
      builder: (context, state) {
        final title =
            state.uri.queryParameters['title'] ?? 'جميع بلاغات الصيانة';
        final status = state.uri.queryParameters['status'];
        final supervisorId = state.uri.queryParameters['supervisorId'];

        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => MaintenanceViewBloc(
                MaintenanceReportRepository(Supabase.instance.client),
                AdminService(Supabase.instance.client),
              )..add(FetchMaintenanceReports(
                  supervisorId: supervisorId, status: status)),
            ),
          ],
          child: MaintenanceReportsScreen(
            title: title,
            supervisorId: supervisorId,
            status: status,
          ),
        );
      },
    ),
    GoRoute(
      path: '/add-reports/:supervisorId',
      name: 'add-reports',
      builder: (context, state) {
        final supervisorId = state.pathParameters['supervisorId'] ?? '';
        final reportRepo = ReportRepository(Supabase.instance.client);

        return MultiBlocProvider(
          providers: [
            BlocProvider<MultipleReportBloc>(
              create: (context) => MultipleReportBloc(
                MultiReportRepository(
                  client: Supabase.instance.client,
                  reportRepository: reportRepo,
                ),
              ),
            ),
            BlocProvider<AddMultipleReportsCubit>(
              create: (_) => AddMultipleReportsCubit(supervisorId),
            ),
          ],
          child: AddMultipleReportsScreen(supervisorId: supervisorId),
        );
      },
    ),
    GoRoute(
      path: '/add-maintenance/:supervisorId',
      name: 'add-maintenance',
      builder: (context, state) {
        final supervisorId = state.pathParameters['supervisorId'] ?? '';
        return BlocProvider(
          create: (_) => MaintenanceReportBloc(Supabase.instance.client),
          child: AddMultipleMaintenanceScreen(supervisorId: supervisorId),
        );
      },
    ),
    GoRoute(
      path: '/maintenance-list/:supervisorId',
      name: 'maintenance-list',
      builder: (context, state) {
        final supervisorId = state.pathParameters['supervisorId'] ?? '';

        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => MaintenanceViewBloc(
                MaintenanceReportRepository(Supabase.instance.client),
                AdminService(Supabase.instance.client),
              )..add(FetchMaintenanceReports(supervisorId: supervisorId)),
            ),
          ],
          child: MaintenanceReportsScreen(
            title: 'بلاغات الصيانة',
            supervisorId: supervisorId,
          ),
        );
      },
    ),
    GoRoute(
      path: '/count-inventory',
      name: 'count-inventory',
      builder: (context, state) => BlocProvider(
        create: (_) => MaintenanceCountsBloc(
          repository: MaintenanceCountRepository(Supabase.instance.client),
          damageRepository: DamageCountRepository(Supabase.instance.client),
          adminService: AdminService(Supabase.instance.client),
        ),
        child: const CountInventoryScreen(),
      ),
    ),
    GoRoute(
      path: '/damage-inventory',
      name: 'damage-inventory',
      builder: (context, state) {
        final schoolId = state.uri.queryParameters['schoolId'];
        final schoolName = state.uri.queryParameters['schoolName'];

        // If schoolId is provided, go directly to damage count detail screen
        if (schoolId != null && schoolName != null) {
          return BlocProvider(
            create: (_) => MaintenanceCountsBloc(
              repository: MaintenanceCountRepository(Supabase.instance.client),
              damageRepository: DamageCountRepository(Supabase.instance.client),
              adminService: AdminService(Supabase.instance.client),
            ),
            child: DamageCountDetailScreen(
              schoolId: schoolId,
              schoolName: schoolName,
            ),
          );
        }

        // Otherwise, show the general damage inventory screen
        return BlocProvider(
          create: (_) => MaintenanceCountsBloc(
            repository: MaintenanceCountRepository(Supabase.instance.client),
            damageRepository: DamageCountRepository(Supabase.instance.client),
            adminService: AdminService(Supabase.instance.client),
          ),
          child: const DamageInventoryScreen(),
        );
      },
    ),
    GoRoute(
      path: '/supervisors',
      name: 'supervisors',
      builder: (context, state) => const SupervisorListScreen(),
    ),
    GoRoute(
      path: '/admin-management',
      name: 'admin-management',
      builder: (context, state) => const AdminManagementScreen(),
    ),
    GoRoute(
      path: '/test-connection',
      name: 'test-connection',
      builder: (context, state) => const TestConnectionScreen(),
    ),
    GoRoute(
      path: '/debug-auth',
      name: 'debug-auth',
      builder: (context, state) => const DebugAuthScreen(),
    ),
    GoRoute(
      path: '/all-reports',
      name: 'all-reports',
      builder: (context, state) {
        final initialFilter = state.uri.queryParameters['filter'];
        final supervisorId = state.uri.queryParameters['supervisor_id'];
        final supervisorName = state.uri.queryParameters['supervisor_name'];
        return AllReportsScreen(
          initialFilter: initialFilter,
          supervisorId: supervisorId,
          supervisorName: supervisorName,
        );
      },
    ),
    GoRoute(
      path: '/all-maintenance',
      name: 'all-maintenance',
      builder: (context, state) {
        final supervisorId = state.uri.queryParameters['supervisor_id'];
        final supervisorName = state.uri.queryParameters['supervisor_name'];
        return AllMaintenanceScreen(
          supervisorId: supervisorId,
          supervisorName: supervisorName,
        );
      },
    ),
    GoRoute(
      path: '/schools',
      name: 'schools',
      builder: (context, state) => const SchoolsListScreen(),
    ),
    GoRoute(
      path: '/schools-with-achievements',
      name: 'schools-with-achievements',
      builder: (context, state) => const SchoolsWithAchievementsScreen(),
    ),
    GoRoute(
      path: '/school-details/:schoolId',
      name: 'school-details',
      builder: (context, state) {
        final schoolId = state.pathParameters['schoolId'] ?? '';
        return SchoolDetailsScreen(schoolId: schoolId);
      },
    ),
  ],
);
