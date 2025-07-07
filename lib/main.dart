import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/repositories/report_repository.dart';
import 'data/repositories/supervisor_repository.dart';
import 'data/repositories/maintenance_repository.dart';
import 'data/repositories/maintenance_count_repository.dart';
import 'data/repositories/damage_count_repository.dart';
import 'logic/blocs/reports/report_bloc.dart';
import 'logic/blocs/reports/report_event.dart';
import 'logic/blocs/dashboard/dashboard_bloc.dart';
import 'logic/blocs/dashboard/dashboard_event.dart';
import 'logic/blocs/supervisors/supervisor_bloc.dart';
import 'logic/blocs/supervisors/supervisor_event.dart';
import 'logic/blocs/super_admin/super_admin_bloc.dart';
import 'logic/blocs/super_admin/super_admin_event.dart';
import 'logic/cubits/theme_cubit.dart';
import 'core/constants/app_themes.dart';
import 'core/routes/app_router.dart';
import 'core/services/admin_service.dart';
import 'core/services/admin_management_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://cftjaukrygtzguqcafon.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNmdGphdWtyeWd0emd1cWNhZm9uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgzMjU1NzYsImV4cCI6MjA2MzkwMTU3Nn0.28pIhi_qCDK3SIjCiJa0VuieFx0byoMK-wdmhb4G75c',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final reportRepo = ReportRepository(supabase);
    final supervisorRepo = SupervisorRepository(supabase);
    final maintenanceRepo = MaintenanceReportRepository(supabase);
    final maintenanceCountRepo = MaintenanceCountRepository(supabase);
    final damageCountRepo = DamageCountRepository(supabase);
    final adminService = AdminService(supabase);
    final adminManagementService = AdminManagementService(supabase);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ReportRepository>.value(value: reportRepo),
        RepositoryProvider<SupervisorRepository>.value(value: supervisorRepo),
        RepositoryProvider<MaintenanceReportRepository>.value(
            value: maintenanceRepo),
        RepositoryProvider<MaintenanceCountRepository>.value(
            value: maintenanceCountRepo),
        RepositoryProvider<DamageCountRepository>.value(value: damageCountRepo),
        RepositoryProvider<AdminService>.value(value: adminService),
        RepositoryProvider<AdminManagementService>.value(
            value: adminManagementService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>(
            create: (_) => ThemeCubit(),
          ),
          BlocProvider<ReportBloc>(
            create: (_) =>
                ReportBloc(reportRepo, adminService)..add(const FetchReports()),
          ),
          BlocProvider<DashboardBloc>(
            create: (_) => DashboardBloc(
              reportRepository: reportRepo,
              supervisorRepository: supervisorRepo,
              maintenanceRepository: maintenanceRepo,
              maintenanceCountRepository: maintenanceCountRepo,
              damageCountRepository: damageCountRepo,
              adminService: adminService,
            )..add(LoadDashboardData()),
          ),
          BlocProvider<SupervisorBloc>(
            create: (_) => SupervisorBloc(supervisorRepo, adminService)
              ..add(const SupervisorsStarted()),
          ),
          BlocProvider<SuperAdminBloc>(
            create: (_) => SuperAdminBloc(
              adminManagementService,
              supervisorRepo,
              reportRepo,
              maintenanceRepo,
            )..add(LoadSuperAdminData()),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              routerConfig: appRouter,
              title: 'لوحة تحكم البلاغات',
              theme: AppThemes.lightTheme,
              darkTheme: AppThemes.darkTheme,
              themeMode: themeMode,
            );
          },
        ),
      ),
    );
  }
}
