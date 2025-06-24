import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_fonts.dart';
import '../../logic/blocs/super_admin/super_admin_bloc.dart';
import '../../logic/blocs/super_admin/super_admin_state.dart';
import '../../logic/blocs/super_admin/super_admin_event.dart';

import '../widgets/super_admin/progress/super_admin_progress_widgets.dart';

class SuperAdminProgressScreen extends StatefulWidget {
  const SuperAdminProgressScreen({super.key});

  @override
  State<SuperAdminProgressScreen> createState() =>
      _SuperAdminProgressScreenState();
}

class _SuperAdminProgressScreenState extends State<SuperAdminProgressScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  void _loadData() {
    context.read<SuperAdminBloc>().add(LoadSuperAdminData());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0A0A0B) : const Color(0xFFFAFBFC),
        appBar: _buildModernAppBar(context, isDark),
        body: BlocBuilder<SuperAdminBloc, SuperAdminState>(
          builder: (context, state) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildStateContent(state, isDark),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context, bool isDark) {
    return AppBar(
      automaticallyImplyLeading: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1A1A1B).withValues(alpha: 0.95),
                    const Color(0xFF2D2D30).withValues(alpha: 0.95),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.95),
                    const Color(0xFFF8F9FA).withValues(alpha: 0.95),
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مركز التحليلات المتقدم',
                style: AppFonts.appBarTitle(isDark: isDark).copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'نظرة شاملة على الأداء',
                style: AppFonts.bodyText(isDark: isDark).copyWith(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _loadData,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Icon(
                    Icons.refresh_rounded,
                    color: isDark ? Colors.white70 : Colors.black54,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStateContent(SuperAdminState state, bool isDark) {
    if (state is SuperAdminLoading) {
      return _buildModernLoadingState(isDark);
    } else if (state is SuperAdminError) {
      return _buildModernErrorState(state.message, isDark);
    } else if (state is SuperAdminLoaded) {
      return _buildMainContent(state, isDark);
    }
    return const SizedBox.shrink();
  }

  Widget _buildModernLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'جاري تحليل البيانات...',
            style: AppFonts.cardTitle(isDark: isDark).copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'يرجى الانتظار بينما نقوم بمعالجة المعلومات',
            style: AppFonts.bodyText(isDark: isDark).copyWith(
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernErrorState(String message, bool isDark) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFFF6B6B).withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
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
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Color(0xFFFF6B6B),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'حدث خطأ في النظام',
              style: AppFonts.cardTitle(isDark: isDark).copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppFonts.bodyText(isDark: isDark).copyWith(
                color: isDark
                    ? Colors.white70
                    : Colors.black.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(SuperAdminLoaded state, bool isDark) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Charts Section
              ChartsSectionWidget(state: state),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
