import 'package:admin_panel/logic/blocs/auth/auth_state.dart' as my_auth;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/admin_service.dart';
import '../../core/constants/app_fonts.dart';
import '../../logic/blocs/auth/auth_bloc.dart';
import '../../logic/blocs/auth/auth_event.dart';
import '../../logic/blocs/dashboard/dashboard_bloc.dart';
import '../../logic/blocs/dashboard/dashboard_event.dart';
import '../../logic/blocs/dashboard/dashboard_state.dart';
import '../../logic/cubits/theme_cubit.dart';
import '../../data/repositories/report_repository.dart';
import '../../data/repositories/supervisor_repository.dart';
import '../../data/repositories/maintenance_repository.dart';
import '../../data/repositories/maintenance_count_repository.dart';
import '../../data/repositories/damage_count_repository.dart';
import '../../data/repositories/fci_assessment_repository.dart';
import '../widgets/dashboard/dashboard_grid.dart';
import '../widgets/dashboard/supervisor_card.dart';
import '../widgets/common/esc_dismissible_dialog.dart';
import '../widgets/common/user_info_widget.dart';
import '../widgets/common/weekly_report_dialog.dart';
import '../../core/services/navigation/dashboard_state_service.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // 🚀 Initialize dashboard state service for instant loading optimization
    DashboardStateService.initializeDashboard();
  }

  @override
  void dispose() {
    DashboardStateService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Create DashboardBloc and AuthBloc instances (like super admin pattern)
    final supabase = Supabase.instance.client;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc(
            AuthService(supabase),
          ),
        ),
        BlocProvider(
          create: (context) => DashboardBloc(
            reportRepository: ReportRepository(supabase),
            supervisorRepository: SupervisorRepository(supabase),
            maintenanceRepository: MaintenanceReportRepository(supabase),
            maintenanceCountRepository: MaintenanceCountRepository(supabase),
            damageCountRepository: DamageCountRepository(supabase),
            fciAssessmentRepository: FciAssessmentRepository(supabase),
            adminService: AdminService(supabase),
          )..add(const LoadDashboardData()), // 🚀 Trigger loading immediately
        ),
      ],
      child: BlocListener<AuthBloc, my_auth.AuthState>(
        listener: (context, state) {
          if (state is my_auth.Unauthenticated) {
            context.go('/auth');
          }
        },
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              toolbarHeight: 70,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.dashboard_rounded,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF38BDF8)
                          : const Color(0xFF0284C7),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'لوحة التحكم',
                    style: AppFonts.appBarTitle(
                      isDark: Theme.of(context).brightness == Brightness.dark,
                    ).copyWith(
                      fontSize: 22,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const UserInfoWidget(isCompact: true),
                ],
              ),
              centerTitle: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: Theme.of(context).brightness == Brightness.dark
                        ? [
                            const Color(0xFF0F172A).withOpacity(0.95),
                            const Color(0xFF0F172A).withOpacity(0.8),
                          ]
                        : [
                            Colors.white.withOpacity(0.95),
                            Colors.white.withOpacity(0.8),
                          ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black.withOpacity(0.2)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              actions: [
                // Weekly Report button
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: const Color.fromARGB(255, 89, 16, 185).withOpacity(0.1),
                    border: Border.all(
                      color: const Color.fromARGB(255, 75, 16, 185).withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(255, 75, 16, 185).withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.assessment_outlined,
                      color: Color.fromARGB(255, 75, 16, 185),
                    ),
                    tooltip: 'تقرير أسبوعي/شهري',
                    onPressed: () => _showWeeklyReportDialog(context),
                  ),
                ),
                // Theme toggle button
                BlocBuilder<ThemeCubit, ThemeMode>(
                  builder: (context, themeMode) {
                    final isDark = themeMode == ThemeMode.dark;
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          color: const Color(0xFF10B981),
                        ),
                        tooltip: isDark ? 'الوضع المضيء' : 'الوضع المظلم',
                        onPressed: () {
                          context.read<ThemeCubit>().toggleTheme();
                        },
                      ),
                    );
                  },
                ),
                
                // Refresh button
                Builder(builder: (context) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: BlocBuilder<DashboardBloc, DashboardState>(
                      builder: (context, state) {
                        final isLoading = state is DashboardLoading;
                        return IconButton(
                          icon: isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      Color(0xFF3B82F6),
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.refresh_rounded,
                                  color: Color(0xFF3B82F6),
                                ),
                          tooltip:
                              isLoading ? 'جاري التحديث...' : 'تحديث البيانات',
                                                onPressed: isLoading
                          ? null
                          : () async {
                              // Force refresh admin data first
                              await context.read<DashboardBloc>().forceRefreshAdminData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                  Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'جاري تحديث جميع البيانات والإحصائيات...',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF3B82F6),
                                  duration: const Duration(seconds: 3),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                            },
                        );
                      },
                    ),
                  );
                }),
                // Logout button
                Builder(builder: (context) {
                  return Container(
                    margin: const EdgeInsets.only(right: 16, left: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFEF4444),
                      ),
                      tooltip: 'تسجيل الخروج',
                      onPressed: () {
                        context.showEscDismissibleDialog(
                          barrierDismissible: false,
                          barrierColor: Colors.black.withOpacity(0.6),
                          builder: (ctx) => Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 0,
                            backgroundColor: Colors.transparent,
                            child: Container(
                              width: 320,
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? [
                                          const Color(0xFF1E293B)
                                              .withOpacity(0.95),
                                          const Color(0xFF0F172A)
                                              .withOpacity(0.95),
                                        ]
                                      : [
                                          Colors.white.withOpacity(0.95),
                                          const Color(0xFFF8FAFC)
                                              .withOpacity(0.95),
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.05),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.black.withOpacity(0.4)
                                        : Colors.black.withOpacity(0.15),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                    spreadRadius: 0,
                                  ),
                                  BoxShadow(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.black.withOpacity(0.2)
                                        : Colors.black.withOpacity(0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Modern icon with gradient background
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          const Color(0xFFEF4444)
                                              .withOpacity(0.15),
                                          const Color(0xFFDC2626)
                                              .withOpacity(0.1),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFEF4444)
                                            .withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Container(
                                      margin: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            const Color(0xFFEF4444)
                                                .withOpacity(0.1),
                                            const Color(0xFFDC2626)
                                                .withOpacity(0.05),
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.logout_rounded,
                                        color: Color(0xFFEF4444),
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Modern title with better typography
                                  Text(
                                    'تسجيل الخروج',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                      letterSpacing: -0.5,
                                      height: 1.2,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),

                                  // Subtle description with ESC hint
                                  Column(
                                    children: [
                                      Text(
                                        'هل أنت متأكد من تسجيل الخروج من حسابك؟\nسيتم إعادة توجيهك إلى صفحة تسجيل الدخول',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B),
                                          height: 1.5,
                                          letterSpacing: 0.1,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'اضغط ESC للإلغاء',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? const Color(0xFF64748B)
                                              : const Color(0xFF94A3B8),
                                          letterSpacing: 0.2,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 32),

                                  // Modern action buttons with better styling
                                  Row(
                                    children: [
                                      // Cancel button with subtle styling
                                      Expanded(
                                        child: Container(
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? const Color(0xFF334155)
                                                        .withOpacity(0.3)
                                                    : const Color(0xFFF1F5F9),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? const Color(0xFF475569)
                                                      .withOpacity(0.3)
                                                  : const Color(0xFFE2E8F0),
                                              width: 1,
                                            ),
                                          ),
                                          child: TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(),
                                            style: TextButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              padding: EdgeInsets.zero,
                                              overlayColor: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                      .withOpacity(0.05)
                                                  : Colors.black
                                                      .withOpacity(0.03),
                                            ),
                                            child: Text(
                                              'إلغاء',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? const Color(0xFFCBD5E1)
                                                    : const Color(0xFF475569),
                                                letterSpacing: 0.1,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),

                                      // Logout button with gradient and modern styling
                                      Expanded(
                                        child: Container(
                                          height: 48,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color(0xFFEF4444),
                                                Color(0xFFDC2626),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFEF4444)
                                                    .withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: TextButton(
                                            onPressed: () {
                                              // Clear dashboard cache on logout
                                              DashboardBloc.clearCache();
                                              // Clear scroll position on logout
                                              DashboardGrid
                                                  .clearScrollPosition();
                                              context.read<AuthBloc>().add(
                                                  const SignOutRequested());
                                              Navigator.of(ctx).pop();
                                              // BlocListener will handle redirect
                                            },
                                            style: TextButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              padding: EdgeInsets.zero,
                                              overlayColor:
                                                  Colors.white.withOpacity(0.1),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.logout_rounded,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'تسجيل الخروج',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                    letterSpacing: 0.1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
            body: PageStorage(
              bucket: PageStorageBucket(),
              child: BlocBuilder<DashboardBloc, DashboardState>(
                builder: (context, state) {
                  if (state is DashboardLoading) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(0xFF38BDF8)
                                          : const Color(0xFF0284C7),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'جاري تحميل البيانات...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : const Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (state is DashboardError) {
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        width: 400,
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.error_outline,
                                color: Color(0xFFEF4444),
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'حدث خطأ أثناء تحميل البيانات',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white.withOpacity(0.7)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                context.read<DashboardBloc>().add(
                                    const LoadDashboardData(
                                        forceRefresh: true));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.refresh, size: 18),
                                  SizedBox(width: 8),
                                  Text('إعادة المحاولة',
                                      style: TextStyle(fontSize: 16)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (state is DashboardLoaded) {
                    final supervisorCards = state.supervisors.map((supervisor) {
                      final supervisorReports = state.reports
                          .where((r) => r.supervisorId == supervisor.id)
                          .toList();
                      final routine = supervisorReports
                          .where((r) => r.priority.toLowerCase() == 'routine')
                          .length;
                      final emergency = supervisorReports
                          .where((r) => r.priority.toLowerCase() == 'emergency')
                          .length;
                      final overdue = supervisorReports
                          .where((r) => r.status.toLowerCase() == 'late')
                          .length;
                      final lateDone = supervisorReports
                          .where(
                              (r) => r.status.toLowerCase() == 'late_completed')
                          .length;

                      // Calculate maintenance reports for this supervisor
                      final supervisorMaintenanceReports = state
                          .maintenanceReports
                          .where((r) => r.supervisorId == supervisor.id)
                          .toList();
                      final maintenance = supervisorMaintenanceReports.length;
                      final completedMaintenance = supervisorMaintenanceReports
                          .where((r) => r.status.toLowerCase() == 'completed')
                          .length;

                      // Calculate completion rate for this supervisor
                      final completedCount = supervisorReports
                          .where((r) => r.status.toLowerCase() == 'completed')
                          .length;
                      final completionRate = supervisorReports.isEmpty
                          ? 0.0
                          : completedCount / supervisorReports.length;

                      // Calculate technicians count
                      final techniciansCount =
                          supervisor.techniciansDetailed.isNotEmpty
                              ? supervisor.techniciansDetailed.length
                              : supervisor.technicians.length;

                      // Get schools count from enriched supervisor data
                      final schoolsCount = supervisor.schoolsCount ?? 0;

                      return SupervisorCard(
                        supervisorId: supervisor.id,
                        name: supervisor.username,
                        routineCount: routine,
                        emergencyCount: emergency,
                        overdueCount: overdue,
                        lateCompletedCount: lateDone,
                        maintenanceCount: maintenance,
                        completedCount: completedCount,
                        completionRate: completionRate,
                        completedMaintenanceCount: completedMaintenance,
                        techniciansCount: techniciansCount,
                        schoolsCount: schoolsCount,
                        supervisor:
                            supervisor, // Pass the supervisor object for badge functionality
                      );
                    }).toList();

                    return DashboardGrid(
                      totalReports: state.totalReports,
                      routineReports: state.routineReports,
                      emergencyReports: state.emergencyReports,
                      completedReports: state.completedReports,
                      overdueReports: state.overdueReports,
                      lateCompletedReports: state.lateCompletedReports,
                      totalSupervisors: state.totalSupervisors,
                      completionRate: state.completionRate,
                      supervisorCards: supervisorCards,
                      // Maintenance reports data
                      totalMaintenanceReports: state.totalMaintenanceReports,
                      completedMaintenanceReports:
                          state.completedMaintenanceReports,
                      pendingMaintenanceReports:
                          state.pendingMaintenanceReports,
                      // Inventory count data
                      schoolsWithCounts: state.schoolsWithCounts,
                      schoolsWithDamage: state.schoolsWithDamage,
                      // Schools data
                      totalSchools: state.totalSchools,
                      schoolsWithAchievements: state.schoolsWithAchievements,
                      // FCI Assessment data
                      totalFciAssessments: state.totalFciAssessments,
                      submittedFciAssessments: state.submittedFciAssessments,
                      draftFciAssessments: state.draftFciAssessments,
                      schoolsWithFciAssessments: state.schoolsWithFciAssessments,
                      onTapTotalReports: () => context.push('/reports'),
                      onTapEmergencyReports: () => context.push(
                          '/reports?title=البلاغات الطارئة&priority=Emergency'),
                      onTapCompletedReports: () => context.push(
                          '/reports?title=البلاغات المكتملة&status=completed'),
                      onTapOverdueReports: () => context
                          .push('/reports?title=البلاغات المتأخرة&status=late'),
                      onTapLateCompletedReports: () => context.push(
                          '/reports?title=البلاغات المتأخرة المنجزة&status=late_completed'),
                      onTapTotalSupervisors: () => context.push('/supervisors'),
                      onTapRoutineReports: () => context.push(
                          '/reports?title=البلاغات الروتينية&priority=Routine'),
                      // Maintenance callbacks
                      onTapTotalMaintenanceReports: () =>
                          context.push('/maintenance-reports'),
                      onTapCompletedMaintenanceReports: () => context.push(
                          '/maintenance-reports?title=بلاغات الصيانة المكتملة&status=completed'),
                      onTapPendingMaintenanceReports: () => context.push(
                          '/maintenance-reports?title=بلاغات الصيانة الجارية&status=pending'),
                      // Schools callback
                    );
                  }

                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showWeeklyReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => WeeklyReportDialog(
        adminService: AdminService(Supabase.instance.client),
      ),
    );
  }
}
