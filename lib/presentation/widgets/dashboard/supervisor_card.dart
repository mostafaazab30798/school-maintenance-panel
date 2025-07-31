import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';
import '../../../data/models/supervisor.dart';
import '../../../data/repositories/supervisor_repository.dart';
import '../../../core/services/admin_service.dart';
import '../../../logic/blocs/supervisors/supervisor_bloc.dart';
import '../super_admin/dialogs/schools_list_dialog.dart';
import '../super_admin/dialogs/technician_management_dialog.dart';
import '../super_admin/dialogs/change_supervisor_password_dialog.dart';
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
  final Supervisor? supervisor;

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
  bool _isPressed = false;
  late AnimationController _scaleController;
  // 🚀 PERFORMANCE OPTIMIZATION: Remove heavy animations for better performance
  // late AnimationController _glowController;
  // late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  // late Animation<double> _glowAnimation;
  // late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    // 🚀 PERFORMANCE OPTIMIZATION: Remove heavy animations
    // _glowController = AnimationController(
    //   duration: const Duration(milliseconds: 2000),
    //   vsync: this,
    // )..repeat(reverse: true);
    // _pulseController = AnimationController(
    //   duration: const Duration(milliseconds: 1000),
    //   vsync: this,
    // );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutCubic,
    ));

    // 🚀 PERFORMANCE OPTIMIZATION: Remove heavy animations
    // _glowAnimation = Tween<double>(
    //   begin: 0.3,
    //   end: 0.7,
    // ).animate(CurvedAnimation(
    //   parent: _glowController,
    //   curve: Curves.easeInOut,
    // ));

    // _pulseAnimation = Tween<double>(
    //   begin: 1.0,
    //   end: 1.05,
    // ).animate(CurvedAnimation(
    //   parent: _pulseController,
    //   curve: Curves.easeInOut,
    // ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    // 🚀 PERFORMANCE OPTIMIZATION: Remove heavy animations
    // _glowController.dispose();
    // _pulseController.dispose();
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
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedBuilder(
          animation: Listenable.merge([_scaleAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _isPressed ? 0.98 : _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    // Primary shadow
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.4)
                          : const Color(0xFF64748B).withOpacity(0.12),
                      offset: const Offset(0, 12),
                      blurRadius: 32,
                      spreadRadius: 0,
                    ),
                    // Secondary shadow for depth
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.2)
                          : const Color(0xFF64748B).withOpacity(0.06),
                      offset: const Offset(0, 6),
                      blurRadius: 16,
                      spreadRadius: 0,
                    ),
                    // Glow effect on hover
                    if (_isHovered)
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.25),
                        offset: const Offset(0, 8),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  const Color(0xFF1E293B).withOpacity(0.95),
                                  const Color(0xFF0F172A).withOpacity(0.98),
                                ]
                              : [
                                  Colors.white.withOpacity(0.95),
                                  const Color(0xFFFAFBFC).withOpacity(0.98),
                                ],
                        ),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.12)
                              : Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min, // Remove unnecessary flex
                          children: [
                            _buildModernHeader(isDark),
                            const SizedBox(height: 16),
                            _buildProgressDashboard(isDark),
                            const SizedBox(height: 16),
                            _buildCompactMetrics(isDark), // Changed to non-expanded version
                            const SizedBox(height: 50),
                            _buildModernActionBar(isDark),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModernHeader(bool isDark) {
    return Row(
      children: [
        // Modern avatar with gradient and status
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF3B82F6),
                const Color(0xFF1D4ED8),
                const Color(0xFF1E40AF),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.4),
                offset: const Offset(0, 6),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 28,
              ),
              // Active status indicator
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        
        // Name and role info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'مشرف ميداني',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3B82F6),
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 8),
              
              // Enhanced badges row
              Row(
                children: [
                  _buildEnhancedBadge(
                    Icons.engineering_rounded,
                    widget.techniciansCount,
                    'فنيين',
                    const Color(0xFF10B981),
                    isDark,
                    onTap: widget.supervisor != null
                        ? () => _openTechnicianManagement(context)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  _buildEnhancedBadge(
                    Icons.school_rounded,
                    widget.schoolsCount,
                    'مدارس',
                    const Color(0xFF8B5CF6),
                    isDark,
                    onTap: () => _openSchoolsList(context),
                  ),
                  const SizedBox(width: 8),
                  _buildEnhancedBadge(
                    Icons.key_rounded,
                    1,
                    'كلمة المرور',
                    const Color(0xFFF59E0B),
                    isDark,
                    onTap: widget.supervisor != null
                        ? () => _openPasswordChangeDialog(context)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Performance score
        _buildPerformanceScore(isDark),
      ],
    );
  }

  Widget _buildEnhancedBadge(
    IconData icon,
    int count,
    String label,
    Color color,
    bool isDark, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.withOpacity(0.1),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceScore(bool isDark) {
    final overallScore = ((widget.completionRate * 0.6) + 
                         ((widget.maintenanceCount > 0 ? 
                           widget.completedMaintenanceCount / widget.maintenanceCount : 0) * 0.4))
                        .clamp(0.0, 1.0);
    
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: overallScore >= 0.8
              ? [const Color(0xFF10B981), const Color(0xFF059669)]
              : overallScore >= 0.6
                  ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                  : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
        ),
        boxShadow: [
          BoxShadow(
            color: (overallScore >= 0.8
                ? const Color(0xFF10B981)
                : overallScore >= 0.6
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFFEF4444)).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: overallScore,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 4,
            strokeCap: StrokeCap.round,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(overallScore * 100).toInt()}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              Text(
                '%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDashboard(bool isDark) {
    final reportsProgress = widget.completionRate.clamp(0.0, 1.0);
    final maintenanceProgress = widget.maintenanceCount > 0
        ? (widget.completedMaintenanceCount / widget.maintenanceCount).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? const Color(0xFF334155).withOpacity(0.3)
            : const Color(0xFFF8FAFC),
        border: Border.all(
          color: isDark
              ? const Color(0xFF475569).withOpacity(0.3)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                size: 16,
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 8),
              Text(
                'مؤشرات الأداء',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildProgressIndicator(
                  'البلاغات',
                  reportsProgress,
                  const Color(0xFF3B82F6),
                  widget.completedCount,
                  widget.completedCount + widget.routineCount + widget.emergencyCount + widget.overdueCount,
                  isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProgressIndicator(
                  'الصيانة',
                  maintenanceProgress,
                  const Color(0xFF10B981),
                  widget.completedMaintenanceCount,
                  widget.maintenanceCount,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(
    String label,
    double progress,
    Color color,
    int completed,
    int total,
    bool isDark,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            Text(
              '$completed/$total',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: color.withOpacity(0.1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(progress * 100).toInt()}%',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactMetrics(bool isDark) {
    final metrics = [
      {
        'label': 'روتيني',
        'count': widget.routineCount,
        'color': const Color(0xFF06B6D4),
        'icon': Icons.schedule_rounded,
        'route': '/reports?title=البلاغات الروتينية للمشرف ${widget.name}&priority=Routine&supervisorId=${widget.supervisorId}'
      },
      {
        'label': 'طارئ',
        'count': widget.emergencyCount,
        'color': const Color(0xFFEF4444),
        'icon': Icons.warning_rounded,
        'route': '/reports?title=البلاغات الطارئة للمشرف ${widget.name}&priority=Emergency&supervisorId=${widget.supervisorId}'
      },
      {
        'label': 'مكتمل',
        'count': widget.completedCount,
        'color': const Color(0xFF10B981),
        'icon': Icons.check_circle_rounded,
        'route': '/reports?title=البلاغات المكتملة للمشرف ${widget.name}&status=completed&supervisorId=${widget.supervisorId}'
      },
      {
        'label': 'متأخر',
        'count': widget.overdueCount,
        'color': const Color(0xFFF59E0B),
        'icon': Icons.access_time_rounded,
        'route': '/reports?title=البلاغات المتأخرة للمشرف ${widget.name}&status=late&supervisorId=${widget.supervisorId}'
      },
      {
        'label': 'متأخر مكتمل',
        'count': widget.lateCompletedCount,
        'color': const Color(0xFF8B5CF6),
        'icon': Icons.done_all_rounded,
        'route': '/reports?title=البلاغات المتأخرة المنجزة للمشرف ${widget.name}&status=late_completed&supervisorId=${widget.supervisorId}'
      },
      {
        'label': 'صيانة',
        'count': widget.maintenanceCount,
        'color': const Color(0xFF059669),
        'icon': Icons.build_circle_rounded,
        'route': '/maintenance-reports?title=بلاغات الصيانة للمشرف ${widget.name}&supervisorId=${widget.supervisorId}'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'تفاصيل البلاغات',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Compact metrics as small badges
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: metrics.map((metric) {
            return _buildSmallBadge(
              metric['label'] as String,
              metric['count'] as int,
              metric['color'] as Color,
              metric['icon'] as IconData,
              () => context.go(metric['route'] as String),
              isDark,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSmallBadge(
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.withOpacity(0.1),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernActionBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? const Color(0xFF334155).withOpacity(0.2)
            : const Color(0xFFF1F5F9),
        border: Border.all(
          color: isDark
              ? const Color(0xFF475569).withOpacity(0.3)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModernActionButton(
              'إضافة بلاغ',
              Icons.add_circle_rounded,
              const Color(0xFF3B82F6),
              () => context.push('/add-reports/${widget.supervisorId}'),
              isDark,
              isPrimary: true,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildModernActionButton(
              'صيانة',
              Icons.build_circle_rounded,
              const Color(0xFF10B981),
              () => context.push('/add-maintenance/${widget.supervisorId}'),
              isDark,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildModernActionButton(
              'حضور',
              Icons.event_available_rounded,
              const Color(0xFF8B5CF6),
              () => _showAttendanceDialog(context),
              isDark,
            ),
          ),
        ],
      ),
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
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: isPrimary
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.8)],
              )
            : null,
        color: isPrimary ? null : color.withOpacity(0.1),
        border: isPrimary
            ? null
            : Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isPrimary ? Colors.white : color,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isPrimary ? Colors.white : color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openTechnicianManagement(BuildContext context) {
    if (widget.supervisor == null) return;

    context.showEscDismissibleDialog(
      barrierDismissible: true,
      builder: (dialogContext) => TechnicianManagementDialog(
        supervisor: widget.supervisor!,
        onSaveDetailed: (supervisorId, techniciansDetailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('عرض فقط - لا يمكن تعديل بيانات الفنيين'),
              backgroundColor: Colors.orange,
            ),
          );
        },
        onTechniciansUpdated: () {},
        isReadOnly: true,
      ),
    );
  }

  void _openSchoolsList(BuildContext context) {
    context.showEscDismissibleDialog(
      barrierDismissible: true,
      builder: (dialogContext) => BlocProvider(
        create: (context) => SupervisorBloc(
          SupervisorRepository(Supabase.instance.client),
          AdminService(Supabase.instance.client),
        ),
        child: SchoolsListDialog(
          supervisorId: widget.supervisorId,
          supervisorName: widget.name,
        ),
      ),
    );
  }

  void _showAttendanceDialog(BuildContext context) {
    AttendanceDialog.show(context, widget.supervisorId, widget.name);
  }

  void _openPasswordChangeDialog(BuildContext context) {
    if (widget.supervisor == null) return;

    // Debug logging
    print('🔍 DEBUG: Regular supervisor card - Opening password change dialog');
    print('🔍 DEBUG: Supervisor ID: ${widget.supervisor!.id}');
    print('🔍 DEBUG: Supervisor username: ${widget.supervisor!.username}');

    ChangeSupervisorPasswordDialog.show(
      context,
      widget.supervisor!,
      onPasswordChanged: () {
        // Optionally refresh data or show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم تحديث كلمة المرور بنجاح'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }
}
