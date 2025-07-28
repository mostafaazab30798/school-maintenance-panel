import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import 'indicator_card.dart';
import 'supervisor_card.dart';

import 'completion_progress_card.dart';

class DashboardGrid extends StatefulWidget {
  const DashboardGrid({
    super.key,
    required this.totalReports,
    required this.routineReports,
    required this.emergencyReports,
    required this.completedReports,
    required this.overdueReports,
    required this.lateCompletedReports,
    required this.totalSupervisors,
    required this.completionRate,
    required this.supervisorCards,
    required this.onTapTotalReports,
    required this.onTapRoutineReports,
    required this.onTapEmergencyReports,
    required this.onTapCompletedReports,
    required this.onTapOverdueReports,
    required this.onTapLateCompletedReports,
    required this.onTapTotalSupervisors,
    // Maintenance reports parameters
    required this.totalMaintenanceReports,
    required this.completedMaintenanceReports,
    required this.pendingMaintenanceReports,
    required this.onTapTotalMaintenanceReports,
    required this.onTapCompletedMaintenanceReports,
    required this.onTapPendingMaintenanceReports,
    // Inventory count parameters
    required this.schoolsWithCounts,
    required this.schoolsWithDamage,
    // Schools parameters
    required this.totalSchools,
    required this.schoolsWithAchievements,
    // FCI Assessment parameters
    required this.totalFciAssessments,
    required this.submittedFciAssessments,
    required this.draftFciAssessments,
    required this.schoolsWithFciAssessments,
  });

  final int totalReports;
  final int routineReports;
  final int emergencyReports;
  final int completedReports;
  final int overdueReports;
  final int lateCompletedReports;
  final int totalSupervisors;
  final double completionRate;
  final List<Widget> supervisorCards;

  // Maintenance reports
  final int totalMaintenanceReports;
  final int completedMaintenanceReports;
  final int pendingMaintenanceReports;

  // Inventory counts
  final int schoolsWithCounts;
  final int schoolsWithDamage;

  // Schools data
  final int totalSchools;
  final int schoolsWithAchievements;

  // FCI Assessment data
  final int totalFciAssessments;
  final int submittedFciAssessments;
  final int draftFciAssessments;
  final int schoolsWithFciAssessments;

  final VoidCallback onTapTotalReports;
  final VoidCallback onTapRoutineReports;
  final VoidCallback onTapEmergencyReports;
  final VoidCallback onTapCompletedReports;
  final VoidCallback onTapOverdueReports;
  final VoidCallback onTapLateCompletedReports;
  final VoidCallback onTapTotalSupervisors;

  // Maintenance callbacks
  final VoidCallback onTapTotalMaintenanceReports;
  final VoidCallback onTapCompletedMaintenanceReports;
  final VoidCallback onTapPendingMaintenanceReports;

  @override
  State<DashboardGrid> createState() => _DashboardGridState();

  /// Clear the scroll position (useful for logout or reset)
  static void clearScrollPosition() {
    _DashboardGridState.clearScrollPosition();
  }
}

class _DashboardGridState extends State<DashboardGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;

  // Static scroll controller to persist across widget rebuilds
  static ScrollController? _staticScrollController;
  static double _lastScrollPosition = 0.0;

  ScrollController get _scrollController {
    _staticScrollController ??= ScrollController();
    return _staticScrollController!;
  }

  /// Clear the scroll position (useful for logout or reset)
  static void clearScrollPosition() {
    _lastScrollPosition = 0.0;
    _staticScrollController?.dispose();
    _staticScrollController = null;
  }

  @override
  void initState() {
    super.initState();
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.completionRate,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeOutCubic,
    ));

    // Start animation after a brief delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _progressAnimationController.forward();
      }
    });

    // Restore scroll position after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreScrollPosition();
    });

    // Listen to scroll changes to save position
    _scrollController.addListener(_saveScrollPosition);
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    // Don't dispose the static scroll controller as it should persist
    super.dispose();
  }

  void _saveScrollPosition() {
    if (_scrollController.hasClients) {
      _lastScrollPosition = _scrollController.offset;
    }
  }

  void _restoreScrollPosition() {
    if (_scrollController.hasClients && _lastScrollPosition > 0) {
      _scrollController.animateTo(
        _lastScrollPosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: Theme.of(context).brightness == Brightness.dark
              ? const [
                  Color(0xFF0F172A),
                  Color(0xFF1E293B),
                ]
              : const [
                  Color(0xFFF8FAFC),
                  Color(0xFFF1F5F9),
                ],
        ),
      ),
      child: SingleChildScrollView(
        key: const PageStorageKey<String>('dashboard_scroll'),
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        // 🚀 PERFORMANCE OPTIMIZATION: Use ClampingScrollPhysics for better performance
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🚀 PERFORMANCE OPTIMIZATION: Remove heavy animations for better performance
            _buildOverviewSection(context),
            const SizedBox(height: 32),

            // Maintenance Reports Section
            _buildMaintenanceSection(context),
            const SizedBox(height: 32),

            // Inventories Section
            _buildInventoriesSection(context),
            const SizedBox(height: 32),

            // Supervisors Section
            _buildSupervisorsSection(context),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;

    // Determine greeting based on time of day
    String greeting;
    if (hour < 12) {
      greeting = 'صباح الخير'; // Good morning
    } else if (hour < 17) {
      greeting = 'مساء الخير'; // Good afternoon
    } else {
      greeting = 'مساء الخير'; // Good evening
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: Theme.of(context).brightness == Brightness.dark
              ? [
                  const Color(0xFF1E293B),
                  const Color(0xFF0F172A),
                ]
              : [
                  const Color(0xFFE0F2FE),
                  const Color(0xFFBAE6FD),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF0F172A)
                            : Colors.white,
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
                      'نظرة عامة',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '$greeting, مرحباً بك في لوحة التحكم الخاصة بالمشرفين',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.8)
                        : const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'يمكنك متابعة جميع البلاغات والصيانة والمشرفين من هنا',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.6)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF0F172A).withOpacity(0.5)
                  : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.insights_rounded,
              size: 60,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFF0284C7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress and Supervisors row
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 600) {
              // Desktop/Tablet layout - side by side
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Progress Chip with super admin sizing
                    Expanded(
                      flex: 2,
                      child: Container(
                        constraints: const BoxConstraints(
                          minHeight: 200,
                          maxHeight: 200,
                        ),
                        child: ClipRect(
                          child: _buildProgressChip(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // All Supervisors Chip
                    Expanded(
                      flex: 1,
                      child: Container(
                        constraints: const BoxConstraints(
                          minHeight: 200,
                          maxHeight: 200,
                        ),
                        child: _buildSupervisorsChip(context),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              // Mobile layout - stacked
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    constraints: const BoxConstraints(
                      minHeight: 200,
                      maxHeight: 200,
                    ),
                    child: ClipRect(
                      child: _buildProgressChip(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    constraints: const BoxConstraints(
                      minHeight: 200,
                      maxHeight: 200,
                    ),
                    child: _buildSupervisorsChip(context),
                  ),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 16),

        // Schools Section
        _buildSchoolsSection(context),
        const SizedBox(height: 16),

        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E293B)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'إحصائيات البلاغات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF334155),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.assignment_outlined,
                      color: Color(0xFF3B82F6),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.totalReports} بلاغ',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildFixedHeightGrid(context),
      ],
    );
  }

  Widget _buildMaintenanceSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E293B)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.build_outlined,
                  color: Color(0xFF059669),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'إحصائيات الصيانة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF334155),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.build_outlined,
                      color: Color(0xFF059669),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.totalMaintenanceReports} صيانة',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildMaintenanceFixedHeightGrid(context),
      ],
    );
  }

  Widget _buildProgressChip(BuildContext context) {
    final double progressValue = widget.totalReports > 0
        ? (widget.completedReports / widget.totalReports).clamp(0.0, 1.0)
        : 0.0;

    return CompletionProgressCard(
      percentage: progressValue,
      onTap: () => context.push('/progress'),
    );
  }

  Widget _buildSupervisorsChip(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0EA5E9).withOpacity(0.1),
            const Color(0xFF0284C7).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF0EA5E9).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTapTotalSupervisors,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with background
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF0EA5E9),
                        const Color(0xFF0284C7),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0EA5E9).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.people_alt_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                // Count
                Text(
                  '${widget.totalSupervisors}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                // Label
                Text(
                  'مشرف',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.8)
                        : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 2),
                // Subtitle
                Text(
                  'عرض الكل',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0EA5E9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFixedHeightGrid(BuildContext context) {
    final cards = [
      IndicatorCard(
        label: 'إجمالي البلاغات',
        count: widget.totalReports,
        color: const Color(0xFF3B82F6),
        icon: Icons.assignment_outlined,
        onTap: widget.onTapTotalReports,
      ),
      IndicatorCard(
        label: 'بلاغات روتينية',
        count: widget.routineReports,
        color: const Color(0xFF8B5CF6),
        icon: Icons.calendar_today_outlined,
        onTap: widget.onTapRoutineReports,
      ),
      IndicatorCard(
        label: 'بلاغات طارئة',
        count: widget.emergencyReports,
        color: const Color(0xFFEF4444),
        icon: Icons.warning_amber_outlined,
        onTap: widget.onTapEmergencyReports,
      ),
      IndicatorCard(
        label: 'بلاغات مكتملة',
        count: widget.completedReports,
        color: const Color(0xFF10B981),
        icon: Icons.check_circle_outline,
        onTap: widget.onTapCompletedReports,
      ),
      IndicatorCard(
        label: 'بلاغات متأخرة',
        count: widget.overdueReports,
        color: const Color(0xFFF59E0B),
        icon: Icons.schedule,
        onTap: widget.onTapOverdueReports,
      ),
      IndicatorCard(
        label: 'بلاغات متأخرة منجزة',
        count: widget.lateCompletedReports,
        color: const Color(0xFF6366F1),
        icon: Icons.assignment_late_outlined,
        onTap: widget.onTapLateCompletedReports,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use same breakpoints as super admin
        if (constraints.maxWidth >= 1200) {
          // 3 columns for very wide screens (6 cards total)
          return _buildFixedRowsLayout(cards, 3);
        } else if (constraints.maxWidth >= 900) {
          // 3 columns for medium-wide screens
          return _buildFixedRowsLayout(cards, 3);
        } else if (constraints.maxWidth >= 600) {
          // 2 columns for medium screens
          return _buildFixedRowsLayout(cards, 2);
        } else {
          // 1 column for small screens
          return _buildFixedRowsLayout(cards, 1);
        }
      },
    );
  }

  Widget _buildFixedRowsLayout(List<Widget> cards, int columns) {
    final rows = <Widget>[];
    const cardHeight = 180.0; // Same height as super admin dashboard

    for (int i = 0; i < cards.length; i += columns) {
      final rowCards = <Widget>[];

      for (int j = 0; j < columns && (i + j) < cards.length; j++) {
        rowCards.add(Expanded(child: cards[i + j]));

        // Add spacing between cards (except for the last one)
        if (j < columns - 1 && (i + j + 1) < cards.length) {
          rowCards.add(const SizedBox(width: 16));
        }
      }

      // Fill remaining slots with empty expanded widgets for consistent spacing
      while (rowCards.length < (columns * 2 - 1)) {
        rowCards.add(const Expanded(child: SizedBox()));
      }

      rows.add(
        SizedBox(
          height: cardHeight,
          child: Row(children: rowCards),
        ),
      );

      // Add vertical spacing between rows (except for the last one)
      if (i + columns < cards.length) {
        rows.add(const SizedBox(height: 16));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }

  Widget _buildMaintenanceFixedHeightGrid(BuildContext context) {
    final maintenanceCards = [
      IndicatorCard(
        label: 'إجمالي الصيانة',
        count: widget.totalMaintenanceReports,
        color: const Color(0xFF059669),
        icon: Icons.build_outlined,
        onTap: widget.onTapTotalMaintenanceReports,
      ),
      IndicatorCard(
        label: 'صيانة مكتملة',
        count: widget.completedMaintenanceReports,
        color: const Color(0xFF10B981),
        icon: Icons.check_circle_outline,
        onTap: widget.onTapCompletedMaintenanceReports,
      ),
      IndicatorCard(
        label: 'صيانة جارية',
        count: widget.pendingMaintenanceReports,
        color: const Color(0xFF3B82F6),
        icon: Icons.pending_outlined,
        onTap: widget.onTapPendingMaintenanceReports,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use same breakpoints as super admin for maintenance cards
        if (constraints.maxWidth >= 900) {
          // 3 columns for medium-wide screens and above
          return _buildFixedRowsLayout(maintenanceCards, 3);
        } else if (constraints.maxWidth >= 600) {
          // 2 columns for medium screens
          return _buildFixedRowsLayout(maintenanceCards, 2);
        } else {
          // 1 column for small screens
          return _buildFixedRowsLayout(maintenanceCards, 1);
        }
      },
    );
  }



  Widget _buildSchoolsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E293B)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Color(0xFF0EA5E9),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'المدارس',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF334155),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.school_rounded,
                      color: Color(0xFF0EA5E9),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.totalSchools} مدرسة',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0EA5E9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildSchoolsFixedHeightGrid(context),
      ],
    );
  }

  Widget _buildSchoolsFixedHeightGrid(BuildContext context) {
    final schoolsCards = [
      IndicatorCard(
        label: 'جميع المدارس',
        count: widget.totalSchools,
        color: const Color(0xFF3B82F6),
        icon: Icons.school_rounded,
        onTap: () {
          context.push('/schools');
        },
      ),
      IndicatorCard(
        label: 'المشاهد والفحوصات',
        count: widget.schoolsWithAchievements,
        color: const Color(0xFF10B981),
        icon: Icons.emoji_events,
        onTap: () {
          context.push('/schools-with-achievements');
        },
      ),
      IndicatorCard(
        label: 'تقييمات FCI',
        count: widget.totalFciAssessments,
        color: const Color(0xFF8B5CF6),
        icon: Icons.assessment_outlined,
        onTap: () {
          context.push('/fci-assessments');
        },
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use responsive layout for schools cards
        if (constraints.maxWidth >= 600) {
          // 3 columns for medium screens and above
          return _buildFixedRowsLayout(schoolsCards, 3);
        } else {
          // 1 column for small screens
          return _buildFixedRowsLayout(schoolsCards, 1);
        }
      },
    );
  }

  Widget _buildInventoriesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E293B)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFF8B5CF6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'الحصورات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF334155),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      color: Color(0xFF8B5CF6),
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'حصر الصيانة',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildInventoriesFixedHeightGrid(context),
      ],
    );
  }

  Widget _buildInventoriesFixedHeightGrid(BuildContext context) {
    final inventoryCards = [
      IndicatorCard(
        label: 'حصر الاعداد',
        count: widget.schoolsWithCounts,
        color: const Color(0xFF10B981),
        icon: Icons.inventory_outlined,
        onTap: () {
          context.push('/count-inventory');
        },
      ),
      IndicatorCard(
        label: 'حصر التوالف',
        count: widget.schoolsWithDamage,
        color: const Color(0xFFEF4444),
        icon: Icons.warning_amber_outlined,
        onTap: () {
          context.push('/damage-inventory');
        },
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use same breakpoints for inventory cards
        if (constraints.maxWidth >= 600) {
          // 2 columns for medium screens and above
          return _buildFixedRowsLayout(inventoryCards, 2);
        } else {
          // 1 column for small screens
          return _buildFixedRowsLayout(inventoryCards, 1);
        }
      },
    );
  }

  Widget _buildSupervisorsSection(BuildContext context) {
    // Show all supervisor cards instead of limiting to 3
    final allSupervisorCards = widget.supervisorCards;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Modern header with enhanced visual appeal
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [
                      const Color(0xFF1E293B).withOpacity(0.9),
                      const Color(0xFF0F172A).withOpacity(0.95),
                    ]
                  : [
                      Colors.white.withOpacity(0.9),
                      const Color(0xFFF8FAFC).withOpacity(0.95),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF334155).withOpacity(0.3)
                  : const Color(0xFFE2E8F0).withOpacity(0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.06),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                blurRadius: 40,
                spreadRadius: 0,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Row(
            children: [
              // Modern icon with gradient background
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF3B82F6),
                      Color(0xFF1D4ED8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.people_alt_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 20),
              
              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'جميع المشرفين',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            'تفصيلي',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'عرض جميع المشرفين المعينين لك مع تفاصيل الأداء والإحصائيات',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Performance indicator
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${widget.totalSupervisors}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF3B82F6),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'إجمالي',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Show all supervisor cards with responsive grid
        if (allSupervisorCards.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1400
                  ? 3
                  : constraints.maxWidth > 900
                      ? 2
                      : 1;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: crossAxisCount == 1
                      ? 1.4
                      : 1.2,
                ),
                itemCount: allSupervisorCards.length,
                itemBuilder: (context, index) {
                  return RepaintBoundary(
                    child: allSupervisorCards[index],
                  );
                },
              );
            },
          )
        else
          _buildEmptySupervisorsState(context),
      ],
    );
  }

  Widget _buildEmptySupervisorsState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark
            ? const Color(0xFF1E293B).withOpacity(0.5)
            : const Color(0xFFF8FAFC),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155).withOpacity(0.3)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF64748B).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline_rounded,
              size: 48,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد مشرفين متاحين حالياً',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'سيتم عرض المشرفين المعينين لك هنا',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

class WaterTankPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  WaterTankPainter({
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Calculate water level
    final waterHeight = size.height * progress;
    final waterTop = size.height - waterHeight;

    // Define 3 color levels
    Color waterColor;
    if (progress >= 0.8) {
      // Excellent - Green water
      waterColor = const Color(0xFF10B981);
    } else if (progress >= 0.6) {
      // Good - Amber water
      waterColor = const Color(0xFFF59E0B);
    } else {
      // Needs improvement - Red water
      waterColor = const Color(0xFFEF4444);
    }

    if (waterHeight > 0) {
      // Create water effect with gradient
      final waterGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          waterColor.withOpacity(0.7),
          waterColor.withOpacity(0.9),
          waterColor,
        ],
        stops: const [0.0, 0.5, 1.0],
      );

      // Draw water with wave effect
      final waterPath = Path();

      // Create wave pattern
      final waveHeight = 4.0;
      final waveLength = size.width / 2;

      // Start from left edge
      waterPath.moveTo(0, waterTop);

      // Create wave pattern across the top
      for (double x = 0; x <= size.width; x += 2) {
        final waveY = waterTop +
            math.sin((x / waveLength) * 2 * math.pi +
                    DateTime.now().millisecondsSinceEpoch * 0.005) *
                waveHeight;
        waterPath.lineTo(x, waveY);
      }

      // Complete the water shape
      waterPath.lineTo(size.width, size.height);
      waterPath.lineTo(0, size.height);
      waterPath.close();

      // Draw water
      final waterPaint = Paint()
        ..shader = waterGradient.createShader(rect)
        ..style = PaintingStyle.fill;

      canvas.drawPath(waterPath, waterPaint);

      // Add shimmer effect
      final shimmerPaint = Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..style = PaintingStyle.fill;

      final shimmerPath = Path();
      final shimmerY = waterTop + waterHeight * 0.3;
      shimmerPath.moveTo(0, shimmerY);

      for (double x = 0; x <= size.width; x += 1) {
        final shimmerWaveY = shimmerY +
            math.sin((x / (waveLength * 0.7)) * 2 * math.pi +
                    DateTime.now().millisecondsSinceEpoch * 0.008) *
                2;
        shimmerPath.lineTo(x, shimmerWaveY);
      }

      shimmerPath.lineTo(size.width, shimmerY + 8);
      shimmerPath.lineTo(0, shimmerY + 8);
      shimmerPath.close();

      canvas.drawPath(shimmerPath, shimmerPaint);
    }

    // Draw level indicators (3 horizontal lines)
    final levelPaint = Paint()
      ..color = isDark ? Colors.white24 : Colors.black12
      ..strokeWidth = 1;

    // Draw 3 level lines
    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(
        Offset(size.width * 0.1, y),
        Offset(size.width * 0.9, y),
        levelPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
