import 'package:flutter/material.dart';
import 'dart:ui';

class ModernSupervisorCard extends StatefulWidget {
  final Map<String, dynamic> supervisor;
  final VoidCallback? onInfoTap;
  final Function(String supervisorId, String username)? onReportsTap;
  final Function(String supervisorId, String username)? onMaintenanceTap;
  final Function(String supervisorId, String username)? onCompletedTap;
  final Function(String supervisorId, String username)? onLateReportsTap;
  final Function(String supervisorId, String username)? onLateCompletedTap;

  const ModernSupervisorCard({
    super.key,
    required this.supervisor,
    this.onInfoTap,
    this.onReportsTap,
    this.onMaintenanceTap,
    this.onCompletedTap,
    this.onLateReportsTap,
    this.onLateCompletedTap,
  });

  @override
  State<ModernSupervisorCard> createState() => _ModernSupervisorCardState();
}

class _ModernSupervisorCardState extends State<ModernSupervisorCard>
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
    final stats = widget.supervisor['stats'] as Map<String, dynamic>;
    final username = widget.supervisor['username'] as String? ?? 'غير محدد';
    final email = widget.supervisor['email'] as String? ?? '';
    final adminId = widget.supervisor['admin_id'] as String?;
    final supervisorId = widget.supervisor['id'] as String? ?? '';

    final totalReports = stats['reports'] as int? ?? 0;
    final totalMaintenance = stats['maintenance'] as int? ?? 0;
    final completedReports = stats['completed_reports'] as int? ?? 0;
    final completedMaintenance = stats['completed_maintenance'] as int? ?? 0;
    final lateReports = stats['late_reports'] as int? ?? 0;
    final lateCompletedReports = stats['late_completed_reports'] as int? ?? 0;
    final completionRate = stats['completion_rate'] as double? ?? 0.0;

    final totalWork = totalReports + totalMaintenance;
    final completedWork = completedReports + completedMaintenance;

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
              constraints: const BoxConstraints(
                minWidth: 350,
                maxWidth: 400,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF1E293B).withOpacity(0.95),
                          const Color(0xFF334155).withOpacity(0.8),
                        ]
                      : [
                          Colors.white.withOpacity(0.95),
                          const Color(0xFFF8FAFC).withOpacity(0.9),
                        ],
                ),
                border: Border.all(
                  color: _isHovered
                      ? const Color(0xFF10B981).withOpacity(0.4)
                      : (isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0))
                          .withOpacity(0.6),
                  width: 1.5,
                ),
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
                      color: const Color(0xFF10B981).withOpacity(0.15),
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
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  const Color(0xFF1E293B),
                                  const Color(0xFF334155),
                                ]
                              : [
                                  Colors.white,
                                  const Color(0xFFF8FAFC),
                                ],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModernHeader(
                              context, username, email, adminId, isDark),
                          const SizedBox(height: 16),
                          _buildCircularProgress(context, completionRate, isDark),
                          const SizedBox(height: 16),
                          _buildStatsGrid(context, totalReports, totalMaintenance,
                              completedWork, supervisorId, username, isDark),
                          const SizedBox(height: 16),
                          _buildLateReportsSection(
                              context,
                              lateReports,
                              lateCompletedReports,
                              supervisorId,
                              username,
                              isDark),
                        ],
                      ),
                    ),

                    // Subtle pattern overlay
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

                    // Animated shimmer effect on hover
                    if (_isHovered)
                      AnimatedBuilder(
                        animation: _shimmerAnimation,
                        builder: (context, child) {
                          return Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment(_shimmerAnimation.value, -1),
                                    end: Alignment(_shimmerAnimation.value + 0.5, 0),
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

  Widget _buildModernHeader(BuildContext context, String username, String email,
      String? adminId, bool isDark) {
    return Row(
      children: [
        // Modern Avatar with Status Ring
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF10B981),
                Color(0xFF059669),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),

        const SizedBox(width: 16),
        // User Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      username,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Info Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onInfoTap,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 6),
              // Assignment Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: adminId != null
                        ? [
                            const Color(0xFF10B981).withOpacity(0.2),
                            const Color(0xFF10B981).withOpacity(0.1),
                          ]
                        : [
                            const Color(0xFFF59E0B).withOpacity(0.2),
                            const Color(0xFFF59E0B).withOpacity(0.1),
                          ],
                  ),
                  border: Border.all(
                    color: adminId != null
                        ? const Color(0xFF10B981).withOpacity(0.3)
                        : const Color(0xFFF59E0B).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      adminId != null
                          ? Icons.check_circle
                          : Icons.warning_rounded,
                      size: 12,
                      color: adminId != null
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      adminId != null ? 'مُعيّن' : 'غير مُعيّن',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: adminId != null
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCircularProgress(
      BuildContext context, double completionRate, bool isDark) {
    final color = _getCompletionRateColor(completionRate * 100);
    final label = _getPerformanceLabel(completionRate * 100);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1E293B).withOpacity(0.6),
                  const Color(0xFF334155).withOpacity(0.4),
                ]
              : [
                  Colors.white.withOpacity(0.8),
                  const Color(0xFFF8FAFC).withOpacity(0.6),
                ],
        ),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Circular Progress
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? const Color(0xFF1E293B).withOpacity(0.5)
                        : const Color(0xFFF1F5F9),
                  ),
                ),
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: completionRate,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeWidth: 5.0,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(completionRate * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: color,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w600,
                        color: color,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'معدل الإنجاز',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF334155),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: color.withOpacity(0.15),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getPerformanceIcon(completionRate * 100),
                            size: 10,
                            color: color,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Mini progress bar
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: const Color(0xFFE2E8F0),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: completionRate,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: LinearGradient(
                          colors: [
                            color,
                            color.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
      BuildContext context,
      int totalReports,
      int totalMaintenance,
      int completedWork,
      String supervisorId,
      String username,
      bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildModernStatCard(
            'البلاغات',
            totalReports,
            Icons.description_outlined,
            const Color(0xFF3B82F6),
            () => widget.onReportsTap?.call(supervisorId, username),
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildModernStatCard(
            'الصيانة',
            totalMaintenance,
            Icons.build_outlined,
            const Color(0xFFEF4444),
            () => widget.onMaintenanceTap?.call(supervisorId, username),
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildModernStatCard(
            'مكتمل',
            completedWork,
            Icons.check_circle_outlined,
            const Color(0xFF10B981),
            () => widget.onCompletedTap?.call(supervisorId, username),
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildModernStatCard(String label, int value, IconData icon,
      Color color, VoidCallback? onTap, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: 18,
              ),
              const SizedBox(height: 6),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLateReportsSection(
      BuildContext context,
      int lateReports,
      int lateCompletedReports,
      String supervisorId,
      String username,
      bool isDark) {
    final hasLateReports = lateReports > 0 || lateCompletedReports > 0;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: hasLateReports 
            ? Colors.orange.withOpacity(0.05)
            : (isDark ? const Color(0xFF1E293B).withOpacity(0.3) : Colors.grey.withOpacity(0.05)),
        border: Border.all(
          color: hasLateReports 
              ? Colors.orange.withOpacity(0.2)
              : (isDark ? const Color(0xFF334155).withOpacity(0.3) : Colors.grey.withOpacity(0.2)),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 14,
                color: hasLateReports 
                    ? Colors.orange[600]
                    : (isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF)),
              ),
              const SizedBox(width: 6),
              Text(
                'البلاغات المتأخرة',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: hasLateReports 
                      ? Colors.orange[700]
                      : (isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasLateReports)
            Row(
              children: [
                if (lateReports > 0)
                  Expanded(
                    child: _buildLateChip(
                      'متأخرة',
                      lateReports,
                      Colors.orange,
                      () => widget.onLateReportsTap?.call(supervisorId, username),
                    ),
                  ),
                if (lateReports > 0 && lateCompletedReports > 0)
                  const SizedBox(width: 8),
                if (lateCompletedReports > 0)
                  Expanded(
                    child: _buildLateChip(
                      'مكتملة متأخرة',
                      lateCompletedReports,
                      Colors.amber,
                      () =>
                          widget.onLateCompletedTap?.call(supervisorId, username),
                    ),
                  ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isDark 
                    ? const Color(0xFF1E293B).withOpacity(0.2)
                    : const Color(0xFFF8FAFC),
              ),
              child: Text(
                'لا توجد بلاغات متأخرة',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark 
                      ? const Color(0xFF64748B)
                      : const Color(0xFF9CA3AF),
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLateChip(
      String label, int count, Color color, VoidCallback? onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: color.withOpacity(0.1),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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
}
