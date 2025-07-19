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
import 'package:flutter_dotenv/flutter_dotenv.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // try {
  //   await dotenv.load(fileName: ".env"); // Load environment variables
  // } catch (e) {
  //   throw Exception('Error loading .env file: $e'); // Print error if any
  //}
// final String baseUrl = dotenv.env['SUPBASE_URL'] ?? 'default_url';
//   final String apiKey = dotenv.env['SUPBASE_ANONKEY'] ?? 'default_key';
 // ✅ Load env vars injected during build
  const String baseUrl = String.fromEnvironment('SUPBASE_URL');
  const String apiKey = String.fromEnvironment('SUPBASE_ANONKEY');

  // ✅ Optional: debug log to verify values
  // print("Supabase URL: $baseUrl");
  // print("Anon Key (partial): ${apiKey.substring(0, 5)}...");

  
  await Supabase.initialize(
    url: baseUrl,
    anonKey: apiKey,
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
