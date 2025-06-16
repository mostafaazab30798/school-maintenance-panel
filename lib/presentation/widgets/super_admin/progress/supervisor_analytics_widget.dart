import 'package:flutter/material.dart';
import '../../../../logic/blocs/super_admin/super_admin_state.dart';
import '../../../../core/constants/app_fonts.dart';

class SupervisorAnalyticsWidget extends StatelessWidget {
  final SuperAdminLoaded state;

  const SupervisorAnalyticsWidget({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final supervisorInsights = _calculateSupervisorInsights();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.groups_outlined,
                  color: Color(0xFF10B981),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'تحليلات المشرفين',
                style: AppFonts.sectionTitle(isDark: isDark)
                    .copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Key metrics
          _buildMetricRow(
            'إجمالي المشرفين',
            state.allSupervisors.length.toString(),
            Icons.people_outline,
            const Color(0xFF10B981),
            isDark,
          ),
          const SizedBox(height: 8),
          _buildMetricRow(
            'المشرفين المعينين',
            supervisorInsights['assignedSupervisors'].toString(),
            Icons.assignment_ind_outlined,
            const Color(0xFF3B82F6),
            isDark,
          ),
          const SizedBox(height: 8),
          _buildMetricRow(
            'المشرفين غير المعينين',
            supervisorInsights['unassignedSupervisors'].toString(),
            Icons.person_off_outlined,
            const Color(0xFFF59E0B),
            isDark,
          ),

          const SizedBox(height: 16),

          // Assignment status chart
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حالة التعيين',
                  style: AppFonts.bodyText(isDark: isDark).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),

                // Assignment progress bar
                Row(
                  children: [
                    Expanded(
                      flex: supervisorInsights['assignedSupervisors'],
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(4),
                            bottomLeft: Radius.circular(4),
                            topRight:
                                supervisorInsights['unassignedSupervisors'] == 0
                                    ? Radius.circular(4)
                                    : Radius.zero,
                            bottomRight:
                                supervisorInsights['unassignedSupervisors'] == 0
                                    ? Radius.circular(4)
                                    : Radius.zero,
                          ),
                        ),
                      ),
                    ),
                    if (supervisorInsights['unassignedSupervisors'] > 0)
                      Expanded(
                        flex: supervisorInsights['unassignedSupervisors'],
                        child: Container(
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF59E0B),
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(4),
                              bottomRight: Radius.circular(4),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    _buildLegendItem(
                      'معين',
                      supervisorInsights['assignedSupervisors'],
                      const Color(0xFF10B981),
                      isDark,
                    ),
                    const SizedBox(width: 16),
                    _buildLegendItem(
                      'غير معين',
                      supervisorInsights['unassignedSupervisors'],
                      const Color(0xFFF59E0B),
                      isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Top performing supervisors
          if (supervisorInsights['topSupervisors'].isNotEmpty) ...[
            Text(
              'أفضل المشرفين أداءً',
              style: AppFonts.bodyText(isDark: isDark).copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            ...supervisorInsights['topSupervisors']
                .take(3)
                .map<Widget>((supervisor) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildSupervisorCard(supervisor, isDark),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricRow(
      String label, String value, IconData icon, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppFonts.bodyText(isDark: isDark).copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, int value, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label ($value)',
          style: AppFonts.bodyText(isDark: isDark).copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSupervisorCard(Map<String, dynamic> supervisor, bool isDark) {
    final completionRate = supervisor['completionRate'] as double;
    final color = _getPerformanceColor(completionRate);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person_outline,
              size: 12,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              supervisor['username'] as String,
              style: AppFonts.bodyText(isDark: isDark).copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${completionRate.toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateSupervisorInsights() {
    final assignedSupervisors =
        state.allSupervisors.where((s) => s['admin_id'] != null).length;
    final unassignedSupervisors =
        state.allSupervisors.length - assignedSupervisors;

    // Calculate supervisor performance from supervisorsWithStats
    final topSupervisors = <Map<String, dynamic>>[];

    for (final supervisor in state.supervisorsWithStats) {
      final totalReports = supervisor['total_reports'] as int? ?? 0;
      final completedReports = supervisor['completed_reports'] as int? ?? 0;
      final totalMaintenance = supervisor['total_maintenance'] as int? ?? 0;
      final completedMaintenance =
          supervisor['completed_maintenance'] as int? ?? 0;

      final totalWork = totalReports + totalMaintenance;
      final completedWork = completedReports + completedMaintenance;
      final completionRate =
          totalWork > 0 ? (completedWork / totalWork * 100) : 0.0;

      if (totalWork > 0) {
        topSupervisors.add({
          'username': supervisor['username'] ?? 'مشرف غير محدد',
          'completionRate': completionRate,
          'totalWork': totalWork,
          'completedWork': completedWork,
        });
      }
    }

    // Sort by completion rate
    topSupervisors.sort((a, b) => (b['completionRate'] as double)
        .compareTo(a['completionRate'] as double));

    return {
      'assignedSupervisors': assignedSupervisors,
      'unassignedSupervisors': unassignedSupervisors,
      'topSupervisors': topSupervisors,
    };
  }

  Color _getPerformanceColor(double rate) {
    if (rate >= 80) return const Color(0xFF10B981);
    if (rate >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}
