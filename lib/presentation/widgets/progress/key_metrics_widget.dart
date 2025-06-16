import 'package:flutter/material.dart';
import '../../../logic/blocs/dashboard/dashboard_state.dart';
import '../../../core/constants/app_fonts.dart';

class KeyMetricsWidget extends StatelessWidget {
  final DashboardLoaded state;

  const KeyMetricsWidget({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  Icons.analytics_rounded,
                  color: Color(0xFF10B981),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'المؤشرات الرئيسية',
                style: AppFonts.sectionTitle(isDark: isDark)
                    .copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCompactMetricCard(
            'البلاغات المتأخرة',
            '${state.overdueReports}',
            Icons.schedule_rounded,
            state.overdueReports > 0
                ? const Color(0xFFEF4444)
                : const Color(0xFF10B981),
            isDark,
          ),
          const SizedBox(height: 12),
          _buildCompactMetricCard(
            'البلاغات الطارئة',
            '${state.emergencyReports}',
            Icons.priority_high_rounded,
            state.emergencyReports > 0
                ? const Color(0xFFF59E0B)
                : const Color(0xFF10B981),
            isDark,
          ),
          const SizedBox(height: 12),
          _buildCompactMetricCard(
            'المشرفين النشطين',
            '${state.totalSupervisors}',
            Icons.groups_rounded,
            const Color(0xFF3B82F6),
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppFonts.bodyText(isDark: isDark).copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: AppFonts.statText(color: color, isDark: isDark).copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double rate) {
    if (rate >= 0.81) return const Color(0xFF10B981); // Green - Excellent
    if (rate >= 0.61) return const Color(0xFF3B82F6);  // Blue - Good
    if (rate >= 0.51) return const Color(0xFFF59E0B);  // Orange - Average
    return const Color(0xFFEF4444); // Red - Bad
  }
}
