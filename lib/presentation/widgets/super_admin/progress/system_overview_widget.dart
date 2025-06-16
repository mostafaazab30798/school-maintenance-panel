import 'package:flutter/material.dart';
import '../../../../logic/blocs/super_admin/super_admin_state.dart';
import '../../../../core/constants/app_fonts.dart';

class SystemOverviewWidget extends StatelessWidget {
  final SuperAdminLoaded state;

  const SystemOverviewWidget({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate system-wide statistics
    final totalAdmins = state.admins.length;
    final totalSupervisors = state.allSupervisors.length;
    final assignedSupervisors =
        state.allSupervisors.where((s) => s['admin_id'] != null).length;

    int totalReports = 0;
    int totalMaintenance = 0;
    int completedReports = 0;
    int completedMaintenance = 0;

    for (final admin in state.admins) {
      final stats = state.adminStats[admin.id];
      if (stats != null) {
        totalReports += (stats['reports'] as int? ?? 0);
        totalMaintenance += (stats['maintenance'] as int? ?? 0);
        completedReports += (stats['completed_reports'] as int? ?? 0);
        completedMaintenance += (stats['completed_maintenance'] as int? ?? 0);
      }
    }

    final totalWork = totalReports + totalMaintenance;
    final completedWork = completedReports + completedMaintenance;
    final systemCompletionRate =
        totalWork > 0 ? (completedWork / totalWork * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF334155)]
              : [Colors.white, const Color(0xFFF8FAFC)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6B46C1), Color(0xFF553C9A)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.dashboard_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'نظرة عامة على النظام',
                style: AppFonts.sectionTitle(isDark: isDark).copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getPerformanceColor(systemCompletionRate)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getPerformanceColor(systemCompletionRate)
                        .withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '${systemCompletionRate.toStringAsFixed(1)}% إنجاز',
                  style: TextStyle(
                    color: _getPerformanceColor(systemCompletionRate),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Main metrics grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;

              if (isWide) {
                return Row(
                  children: [
                    Expanded(
                        child: _buildMetricCard(
                            'المسؤولين',
                            totalAdmins,
                            Icons.admin_panel_settings,
                            const Color(0xFF3B82F6),
                            isDark)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildMetricCard('المشرفين', totalSupervisors,
                            Icons.groups, const Color(0xFF10B981), isDark)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildMetricCard('البلاغات', totalReports,
                            Icons.report, const Color(0xFFF59E0B), isDark)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildMetricCard('الصيانة', totalMaintenance,
                            Icons.build, const Color(0xFFEF4444), isDark)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: _buildMetricCard(
                                'المسؤولين',
                                totalAdmins,
                                Icons.admin_panel_settings,
                                const Color(0xFF3B82F6),
                                isDark)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _buildMetricCard(
                                'المشرفين',
                                totalSupervisors,
                                Icons.groups,
                                const Color(0xFF10B981),
                                isDark)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _buildMetricCard('البلاغات', totalReports,
                                Icons.report, const Color(0xFFF59E0B), isDark)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _buildMetricCard('الصيانة', totalMaintenance,
                                Icons.build, const Color(0xFFEF4444), isDark)),
                      ],
                    ),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 16),

          // Progress bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'معدل الإنجاز الإجمالي',
                      style: AppFonts.bodyText(isDark: isDark).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${completedWork} من ${totalWork}',
                      style: AppFonts.bodyText(isDark: isDark).copyWith(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: totalWork > 0 ? completedWork / totalWork : 0,
                    backgroundColor: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _getPerformanceColor(systemCompletionRate)),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String title, int value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppFonts.bodyText(isDark: isDark).copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getPerformanceColor(double rate) {
    if (rate >= 80) return const Color(0xFF10B981);
    if (rate >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}
