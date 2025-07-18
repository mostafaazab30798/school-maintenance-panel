import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../../data/models/supervisor.dart';
import '../super_admin/dialogs/schools_list_dialog.dart';
import '../super_admin/dialogs/technician_management_dialog.dart';
import '../attendance/attendance_dialog.dart';
import '../common/esc_dismissible_dialog.dart';

class SupervisorCard extends StatefulWidget {
  final String name;
  final int routineCount;
  final int emergencyCount;
  final int overdueCount;
  final int lateCompletedCount;
  final int maintenanceCount;
  final int completedCount;
  final String supervisorId;
  final int completedMaintenanceCount;
  final int techniciansCount;
  final int schoolsCount;
  final Supervisor? supervisor; // Add supervisor object for badge functionality

  /// The completion rate for this supervisor's reports (0.0 to 1.0)
  final double completionRate;

  const SupervisorCard({
    super.key,
    required this.name,
    required this.routineCount,
    required this.emergencyCount,
    required this.overdueCount,
    required this.lateCompletedCount,
    required this.maintenanceCount,
    required this.completedCount,
    required this.supervisorId,
    required this.completionRate,
    required this.completedMaintenanceCount,
    this.techniciansCount = 0,
    this.schoolsCount = 0,
    this.supervisor,
  });

  @override
  State<SupervisorCard> createState() => _SupervisorCardState();
}

class _SupervisorCardState extends State<SupervisorCard>
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
      end: 1.005,
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
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  // Primary shadow
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.4)
                        : const Color(0xFF64748B).withOpacity(0.08),
                    offset: const Offset(0, 4),
                    blurRadius: 16,
                    spreadRadius: 0,
                  ),
                  // Accent shadow
                  if (_isHovered)
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.15),
                      offset: const Offset(0, 2),
                      blurRadius: 12,
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
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Main card background
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  const Color(0xFF1E293B),
                                  const Color(0xFF0F172A),
                                ]
                              : [
                                  Colors.white,
                                  const Color(0xFFFAFBFC),
                                ],
                        ),
                      ),
                    ),

                    // Subtle pattern overlay
                    Positioned.fill(
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

                    // Animated shimmer effect on hover
                    if (_isHovered)
                      AnimatedBuilder(
                        animation: _shimmerAnimation,
                        builder: (context, child) {
                          return Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment(_shimmerAnimation.value, -1),
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
                          );
                        },
                      ),

                    // Content - More aggressive padding reduction
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildModernHeader(isDark),
                          const SizedBox(height: 20),
                          _buildMetricsSection(isDark),
                          const SizedBox(height: 20),
                          _buildActionSection(isDark),
                        ],
                      ),
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

  Widget _buildModernHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Supervisor name with badges
        Row(
          children: [
            Expanded(
              child: Text(
                widget.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Technicians badge
            InkWell(
              onTap: widget.supervisor != null
                  ? () => _openTechnicianManagement(context)
                  : null,
              borderRadius: BorderRadius.circular(8),
              child: _buildInfoBadge(
                icon: Icons.build_circle,
                count: widget.techniciansCount,
                color: const Color(0xFF10B981),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 6),
            // Schools badge
            InkWell(
              onTap: () => _openSchoolsList(context),
              borderRadius: BorderRadius.circular(8),
              child: _buildInfoBadge(
                icon: Icons.school_rounded,
                count: widget.schoolsCount,
                color: const Color(0xFF3B82F6),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Progress indicators - More compact
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildReportsProgressIndicator(isDark),
            _buildMaintenanceProgressIndicator(isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildReportsProgressIndicator(bool isDark) {
    final clampedRate = widget.completionRate.clamp(0.0, 1.0);
    final color = _getProgressColor(clampedRate);
    final percentText = '${(clampedRate * 100).toStringAsFixed(0)}%';

    return SizedBox(
      height: 40,
      width: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? const Color(0xFF334155).withOpacity(0.3)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          // Progress circle
          SizedBox(
            height: 40,
            width: 40,
            child: CircularProgressIndicator(
              value: clampedRate,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeWidth: 4.0,
              strokeCap: StrokeCap.round,
            ),
          ),
          // Percentage text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                percentText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF334155),
                ),
              ),
              Text(
                'إنجاز',
                style: TextStyle(
                  fontSize: 7,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceProgressIndicator(bool isDark) {
    final completionRate = widget.maintenanceCount > 0
        ? widget.completedMaintenanceCount / widget.maintenanceCount
        : 0.0;
    final clampedRate = completionRate.clamp(0.0, 1.0);
    final color = _getProgressColor(clampedRate);
    final percentText = '${(clampedRate * 100).toStringAsFixed(0)}%';

    return SizedBox(
      height: 40,
      width: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? const Color(0xFF334155).withOpacity(0.3)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          // Progress circle
          SizedBox(
            height: 40,
            width: 40,
            child: CircularProgressIndicator(
              value: clampedRate,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeWidth: 4.0,
              strokeCap: StrokeCap.round,
            ),
          ),
          // Percentage text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                percentText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF334155),
                ),
              ),
              Text(
                'صيانة',
                style: TextStyle(
                  fontSize: 7,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection(bool isDark) {
    final stats = [
      {
        'label': 'روتيني',
        'count': widget.routineCount,
        'color': const Color(0xFF06B6D4),
        'icon': Icons.schedule_rounded,
        'route':
            '/reports?title=البلاغات الروتينية للمشرف ${widget.name}&priority=Routine&supervisorId=${widget.supervisorId}'
      },
      {
        'label': 'طارئ',
        'count': widget.emergencyCount,
        'color': const Color(0xFFEF4444),
        'icon': Icons.warning_rounded,
        'route':
            '/reports?title=البلاغات الطارئة للمشرف ${widget.name}&priority=Emergency&supervisorId=${widget.supervisorId}'
      },
      {
        'label': 'مكتمل',
        'count': widget.completedCount,
        'color': const Color(0xFF10B981),
        'icon': Icons.check_circle_rounded,
        'route':
            '/reports?title=البلاغات المكتملة للمشرف ${widget.name}&status=completed&supervisorId=${widget.supervisorId}'
      },
      {
        'label': 'متأخر',
        'count': widget.overdueCount,
        'color': const Color(0xFFF59E0B),
        'icon': Icons.access_time_rounded,
        'route':
            '/reports?title=البلاغات المتأخرة للمشرف ${widget.name}&status=late&supervisorId=${widget.supervisorId}'
      },
      {
        'label': 'مكتمل متأخر',
        'count': widget.lateCompletedCount,
        'color': const Color(0xFF8B5CF6),
        'icon': Icons.done_all_rounded,
        'route':
            '/reports?title=البلاغات المتأخرة المنجزة للمشرف ${widget.name}&status=late_completed&supervisorId=${widget.supervisorId}'
      },
      {
        'label': 'صيانة',
        'count': widget.maintenanceCount,
        'color': const Color(0xFF059669),
        'icon': Icons.build_circle_rounded,
        'route':
            '/maintenance-reports?title=بلاغات الصيانة للمشرف ${widget.name}&supervisorId=${widget.supervisorId}'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section header - Reduced
        Row(
          children: [
            Container(
              width: 2,
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                color: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'إحصائيات',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // Modern metrics grid - using LayoutBuilder to ensure proper constraints
        LayoutBuilder(
          builder: (context, constraints) {
            // Determine the best layout based on available width
            final availableWidth = constraints.maxWidth;

            // Dynamically adjust the grid layout based on available space
            int crossAxisCount;

            if (availableWidth < 300) {
              // Very narrow screens - 2 items per row
              crossAxisCount = 2;
            } else {
              // Normal screens - 3 items per row
              crossAxisCount = 3;
            }

            const crossAxisSpacing = 6.0;
            const mainAxisSpacing = 6.0;

            // Use Wrap instead of GridView for more flexible layout
            return Wrap(
              spacing: crossAxisSpacing,
              runSpacing: mainAxisSpacing,
              children: stats.map((stat) {
                return SizedBox(
                  width: (availableWidth -
                          (crossAxisSpacing * (crossAxisCount - 1))) /
                      crossAxisCount,
                  child: _buildModernMetricCard(
                    stat['label'] as String,
                    stat['count'] as int,
                    stat['color'] as Color,
                    stat['icon'] as IconData,
                    () => context.go(stat['route'] as String),
                    isDark,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildModernMetricCard(
    String label,
    int count,
    Color color,
    IconData icon,
    VoidCallback onTap,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isDark ? color.withOpacity(0.05) : color.withOpacity(0.03),
            border: Border.all(
              color: color.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 12,
                    color: color,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionSection(bool isDark) {
    // Use LayoutBuilder to make the action section responsive
    return LayoutBuilder(
      builder: (context, constraints) {
        // If width is less than 280px, stack buttons vertically
        final isNarrow = constraints.maxWidth < 280;

        if (isNarrow) {
          // Vertical layout for small screens
          return Column(
            children: [
              _buildModernActionButton(
                'إضافة بلاغ',
                Icons.add_circle_outline_rounded,
                const Color(0xFF3B82F6),
                () => context.push('/add-reports/${widget.supervisorId}'),
                isDark,
                isPrimary: true,
              ),
              const SizedBox(height: 8),
              _buildModernActionButton(
                'صيانة دورية',
                Icons.build_circle_outlined,
                const Color(0xFF059669),
                () => context.push('/add-maintenance/${widget.supervisorId}'),
                isDark,
                isPrimary: false,
              ),
              const SizedBox(height: 8),
              _buildModernActionButton(
                'سجل الحضور',
                Icons.calendar_today,
                const Color(0xFF8B5CF6),
                () => _showAttendanceDialog(context),
                isDark,
                isPrimary: false,
              ),
            ],
          );
        } else {
          // Horizontal layout for normal screens
          return Row(
            children: [
              Expanded(
                child: _buildModernActionButton(
                  'إضافة بلاغ',
                  Icons.add_circle_outline_rounded,
                  const Color(0xFF3B82F6),
                  () => context.push('/add-reports/${widget.supervisorId}'),
                  isDark,
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModernActionButton(
                  'صيانة دورية',
                  Icons.build_circle_outlined,
                  const Color(0xFF059669),
                  () => context.push('/add-maintenance/${widget.supervisorId}'),
                  isDark,
                  isPrimary: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModernActionButton(
                  'سجل الحضور',
                  Icons.calendar_today,
                  const Color(0xFF8B5CF6),
                  () => _showAttendanceDialog(context),
                  isDark,
                  isPrimary: false,
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildModernActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
    bool isDark, {
    bool isPrimary = false,
  }) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: isPrimary
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withOpacity(0.8),
                ],
              )
            : null,
        color: isPrimary ? null : color.withOpacity(0.08),
        border: isPrimary
            ? null
            : Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isPrimary ? Colors.white : color,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isPrimary ? Colors.white : color,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBadge({
    required IconData icon,
    required int count,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.1),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double percent) {
    if (percent >= 0.81) return const Color(0xFF10B981); // Green - Excellent
    if (percent >= 0.61) return const Color(0xFF3B82F6); // Blue - Good
    if (percent >= 0.51) return const Color(0xFFF59E0B); // Orange - Average
    return const Color(0xFFEF4444); // Red - Bad
  }

  void _openTechnicianManagement(BuildContext context) {
    if (widget.supervisor == null) return;

    context.showEscDismissibleDialog(
      barrierDismissible: true,
      builder: (dialogContext) => TechnicianManagementDialog(
        supervisor: widget.supervisor!,
        onSaveDetailed: (supervisorId, techniciansDetailed) {
          // Read-only mode for regular admins - no save functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('عرض فقط - لا يمكن تعديل بيانات الفنيين'),
              backgroundColor: Colors.orange,
            ),
          );
        },
        onTechniciansUpdated: () {
          // Read-only mode - no updates allowed
        },
        isReadOnly: true, // Enable read-only mode for regular admins
      ),
    );
  }

  void _openSchoolsList(BuildContext context) {
    // For regular admin dashboard, show read-only schools list
    // Super admins get the assignment dialog with Excel upload
    context.showEscDismissibleDialog(
      barrierDismissible: true,
      builder: (dialogContext) => SchoolsListDialog(
        supervisorId: widget.supervisorId,
        supervisorName: widget.name,
      ),
    );
  }

  void _showAttendanceDialog(BuildContext context) {
    AttendanceDialog.show(context, widget.supervisorId, widget.name);
  }
}
