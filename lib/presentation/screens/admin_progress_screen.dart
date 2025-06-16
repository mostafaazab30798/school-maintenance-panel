import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_fonts.dart';
import '../../logic/blocs/dashboard/dashboard_bloc.dart';
import '../../logic/blocs/dashboard/dashboard_state.dart';
import '../../logic/blocs/dashboard/dashboard_event.dart';
import '../../logic/cubits/theme_cubit.dart';
import '../widgets/progress/progress_widgets.dart';
import '../widgets/common/standard_refresh_button.dart';

class AdminProgressScreen extends StatefulWidget {
  const AdminProgressScreen({super.key});

  @override
  State<AdminProgressScreen> createState() => _AdminProgressScreenState();
}

class _AdminProgressScreenState extends State<AdminProgressScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _progressController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF8FAFC),
        appBar: _buildAppBar(context),
        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return _buildLoadingState(context);
            } else if (state is DashboardError) {
              return _buildErrorState(context, state.message);
            } else if (state is DashboardLoaded) {
              return _buildProgressContent(context, state);
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 70,
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      title: FadeTransition(
        opacity: _fadeAnimation,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.analytics_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'معدلات الانجاز الاجمالي',
              style: AppFonts.appBarTitle(isDark: isDark).copyWith(
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'جاري تحميل بيانات التقدم...',
              style: AppFonts.cardTitle(isDark: isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFEF4444),
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'حدث خطأ في تحميل البيانات',
              style: AppFonts.cardTitle(isDark: isDark),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.bodyText(isDark: isDark),
            ),
            const SizedBox(height: 24),
            StandardRefreshElevatedButton(
              onPressed: () {
                context.read<DashboardBloc>().add(
                      const LoadDashboardData(forceRefresh: true),
                    );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressContent(BuildContext context, DashboardLoaded state) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grid layout for main content
                if (isWide) ...[
                  // Wide screen: 3-column grid with stacked widgets
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Column 1: Progress Visualization + Performance Trends
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            ProgressVisualizationWidget(state: state),
                            const SizedBox(height: 16),
                            PerformanceTrendsWidget(state: state),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Column 2: Key Metrics (standalone)
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            KeyMetricsWidget(state: state),
                            const SizedBox(height: 16),
                            ProgressTimelineWidget(state: state),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Column 3: Actionable Insights + Progress Timeline
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            ActionableInsightsWidget(state: state),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Narrow screen: stacked layout
                  ProgressVisualizationWidget(state: state),
                  const SizedBox(height: 16),
                  KeyMetricsWidget(state: state),
                  const SizedBox(height: 16),
                  ActionableInsightsWidget(state: state),
                  const SizedBox(height: 16),
                  PerformanceTrendsWidget(state: state),
                  const SizedBox(height: 16),
                  ProgressTimelineWidget(state: state),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
