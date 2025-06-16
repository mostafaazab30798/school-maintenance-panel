import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../logic/blocs/super_admin/super_admin_bloc.dart';
import '../../../logic/blocs/super_admin/super_admin_state.dart';
import '../../../logic/blocs/super_admin/super_admin_event.dart';
import '../../../core/services/cache_service.dart';

Widget buildModernAdminPerformanceCard(
  BuildContext context,
  dynamic admin,
  Map<String, dynamic> stats,
  List<Map<String, dynamic>> allSupervisors,
  List<Map<String, dynamic>> supervisorsWithStats, {
  Function(BuildContext, dynamic, List<Map<String, dynamic>>)? onTeamManagement,
  Function(BuildContext, dynamic, List<Map<String, dynamic>>)? onShowReports,
  Function(BuildContext, dynamic, List<Map<String, dynamic>>)?
      onShowMaintenance,
}) {
  return _AdminCardWithHoverEffect(
    admin: admin,
    stats: stats,
    allSupervisors: allSupervisors,
    supervisorsWithStats: supervisorsWithStats,
    onTeamManagement: () =>
        onTeamManagement?.call(context, admin, allSupervisors),
    onShowReports: (adminSupervisorsWithStats) =>
        onShowReports?.call(context, admin, adminSupervisorsWithStats),
    onShowMaintenance: (adminSupervisorsWithStats) =>
        onShowMaintenance?.call(context, admin, adminSupervisorsWithStats),
  );
}

class _AdminCardWithHoverEffect extends StatefulWidget {
  final dynamic admin;
  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> allSupervisors;
  final List<Map<String, dynamic>> supervisorsWithStats;
  final VoidCallback onTeamManagement;
  final Function(List<Map<String, dynamic>>) onShowReports;
  final Function(List<Map<String, dynamic>>) onShowMaintenance;

  const _AdminCardWithHoverEffect({
    required this.admin,
    required this.stats,
    required this.allSupervisors,
    required this.supervisorsWithStats,
    required this.onTeamManagement,
    required this.onShowReports,
    required this.onShowMaintenance,
  });

  @override
  State<_AdminCardWithHoverEffect> createState() =>
      _AdminCardWithHoverEffectState();
}

class _AdminCardWithHoverEffectState extends State<_AdminCardWithHoverEffect>
    with TickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _scaleController;
  late AnimationController _shimmerController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _scaleController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _scaleController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  // Primary shadow
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.4)
                        : const Color(0xFF64748B).withOpacity(0.08),
                    offset: const Offset(0, 8),
                    blurRadius: 32,
                    spreadRadius: 0,
                  ),
                  // Accent shadow on hover
                  if (_isHovered)
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.15),
                      offset: const Offset(0, 4),
                      blurRadius: 24,
                      spreadRadius: 0,
                    ),
                  // Inner highlight
                  BoxShadow(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.white.withOpacity(0.8),
                    offset: const Offset(0, 1),
                    blurRadius: 0,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Main card content
                    _buildOriginalCard(context),

                    // Subtle pattern overlay - positioned behind interactive elements
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.transparent,
                                (isDark ? Colors.white : Colors.black)
                                    .withOpacity(0.01),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Animated shimmer effect on hover - positioned behind interactive elements
                    if (_isHovered)
                      AnimatedBuilder(
                        animation: _shimmerAnimation,
                        builder: (context, child) {
                          return Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin:
                                        Alignment(_shimmerAnimation.value, -1),
                                    end: Alignment(
                                        _shimmerAnimation.value + 0.5, 0),
                                    colors: [
                                      Colors.transparent,
                                      Colors.white
                                          .withOpacity(isDark ? 0.03 : 0.08),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOriginalCard(BuildContext context) {
    final supervisorCount = widget.stats['supervisors'] as int? ?? 0;
    final totalReports = widget.stats['reports'] as int? ?? 0;
    final totalMaintenance = widget.stats['maintenance'] as int? ?? 0;
    final completedReports = widget.stats['completed_reports'] as int? ?? 0;
    final completedMaintenance =
        widget.stats['completed_maintenance'] as int? ?? 0;
    final lateReports = widget.stats['late_reports'] as int? ?? 0;
    final lateCompletedReports =
        widget.stats['late_completed_reports'] as int? ?? 0;

    final totalWork = totalReports + totalMaintenance;
    final completedWork = completedReports + completedMaintenance;
    final completionRate = totalWork > 0 ? (completedWork / totalWork) : 0.0;

    // Get assigned supervisors for this admin
    final assignedSupervisors = widget.allSupervisors
        .where((s) => s['admin_id'] == widget.admin.id)
        .toList();

    // Get supervisor stats for this admin
    final adminSupervisorsWithStats = widget.supervisorsWithStats
        .where((supervisor) => supervisor['admin_id'] == widget.admin.id)
        .toList();

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(minWidth: 350, maxWidth: 400),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [
                    const Color(0xFF1E293B),
                    const Color(0xFF334155),
                  ]
                : [
                    Colors.white,
                    const Color(0xFFF8FAFC),
                  ],
          ),
          border: Border.all(
            color: const Color(0xFF3B82F6).withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF3B82F6),
                        const Color(0xFF1D4ED8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      (widget.admin.name ?? 'أ')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.admin.name ?? 'غير محدد',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'مسؤول',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Team Management Section
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  widget.onTeamManagement();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.people,
                          size: 16,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إدارة الفريق',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : const Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              supervisorCount > 0
                                  ? '$supervisorCount مشرف مُعيّن'
                                  : 'لا يوجد مشرفين مُعيّنين',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: supervisorCount > 0
                                    ? const Color(0xFF10B981)
                                    : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          if (supervisorCount > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$supervisorCount',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.settings,
                              size: 14,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Work Analytics
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        widget.onShowReports(adminSupervisorsWithStats);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFF3B82F6).withOpacity(0.1)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Icon(
                                  Icons.assignment_outlined,
                                  size: 16,
                                  color: Color(0xFF3B82F6),
                                ),
                                Text(
                                  '$totalReports',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF3B82F6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'البلاغات',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white.withOpacity(0.8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        widget.onShowMaintenance(adminSupervisorsWithStats);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFEF4444).withOpacity(0.1)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Icon(
                                  Icons.build_outlined,
                                  size: 16,
                                  color: Color(0xFFEF4444),
                                ),
                                Text(
                                  '$totalMaintenance',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'الصيانة',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white.withOpacity(0.8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Enhanced Performance Indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [
                          const Color(0xFF1E293B).withOpacity(0.8),
                          const Color(0xFF334155).withOpacity(0.6),
                        ]
                      : [
                          Colors.white.withOpacity(0.9),
                          const Color(0xFFF8FAFC).withOpacity(0.7),
                        ],
                ),
                border: Border.all(
                  color: _getCompletionRateColor(completionRate * 100)
                      .withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getCompletionRateColor(completionRate * 100)
                        .withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Circular Progress Indicator
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background circle
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF1E293B).withOpacity(0.5)
                                    : const Color(0xFFF1F5F9),
                          ),
                        ),
                        // Progress circle
                        SizedBox(
                          width: 70,
                          height: 70,
                          child: CircularProgressIndicator(
                            value: completionRate,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getCompletionRateColor(completionRate * 100),
                            ),
                            strokeWidth: 6.0,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        // Center text
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${(completionRate * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _getCompletionRateColor(
                                    completionRate * 100),
                                height: 1.0,
                              ),
                            ),
                            Text(
                              _getPerformanceLabel(completionRate * 100),
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: _getCompletionRateColor(
                                    completionRate * 100),
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Progress Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with status badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'معدل الإنجاز',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFFF1F5F9)
                                    : const Color(0xFF334155),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: [
                                    _getCompletionRateColor(
                                            completionRate * 100)
                                        .withOpacity(0.2),
                                    _getCompletionRateColor(
                                            completionRate * 100)
                                        .withOpacity(0.1),
                                  ],
                                ),
                                border: Border.all(
                                  color: _getCompletionRateColor(
                                          completionRate * 100)
                                      .withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getPerformanceIcon(completionRate * 100),
                                    size: 12,
                                    color: _getCompletionRateColor(
                                        completionRate * 100),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getPerformanceLabel(completionRate * 100),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: _getCompletionRateColor(
                                          completionRate * 100),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Completion breakdown
                        Row(
                          children: [
                            Expanded(
                              child: _buildCompletionStat(
                                'مكتمل',
                                completedWork,
                                const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildCompletionStat(
                                'متبقي',
                                totalWork - completedWork,
                                const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildCompletionStat(
                                'الإجمالي',
                                totalWork,
                                const Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCompletionRateColor(double rate) {
    if (rate >= 81) return const Color(0xFF10B981); // Green - Excellent
    if (rate >= 61) return const Color(0xFF3B82F6);  // Blue - Good
    if (rate >= 51) return const Color(0xFFF59E0B);  // Orange - Average
    return const Color(0xFFEF4444); // Red - Bad
  }

  String _getPerformanceLabel(double rate) {
    if (rate >= 81) return 'ممتاز';
    if (rate >= 61) return 'جيد';
    if (rate >= 51) return 'متوسط';
    return 'ضعيف';
  }

  IconData _getPerformanceIcon(double rate) {
    if (rate >= 81) return Icons.sentiment_very_satisfied;
    if (rate >= 61) return Icons.sentiment_satisfied;
    if (rate >= 51) return Icons.sentiment_neutral;
    return Icons.sentiment_dissatisfied;
  }

  Widget _buildCompletionStat(String label, int value, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
