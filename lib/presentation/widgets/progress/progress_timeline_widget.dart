import 'package:flutter/material.dart';
import '../../../logic/blocs/dashboard/dashboard_state.dart';
import '../../../core/constants/app_fonts.dart';

class ProgressTimelineWidget extends StatelessWidget {
  final DashboardLoaded state;

  const ProgressTimelineWidget({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timelineData = _calculateTimelineData();

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
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.timeline_rounded,
                  color: Color(0xFF3B82F6),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'الجدول الزمني للتقدم',
                style: AppFonts.sectionTitle(isDark: isDark)
                    .copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTimelineItem('اليوم', '${timelineData['today']}',
                    'مكتمل', const Color(0xFF10B981), isDark),
              ),
              Expanded(
                child: _buildTimelineItem(
                    'هذا الأسبوع',
                    '${timelineData['thisWeek']}',
                    'مكتمل',
                    const Color(0xFF3B82F6),
                    isDark),
              ),
              Expanded(
                child: _buildTimelineItem(
                    'هذا الشهر',
                    '${timelineData['thisMonth']}',
                    'مكتمل',
                    const Color(0xFF8B5CF6),
                    isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, int> _calculateTimelineData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    int todayCompleted = 0;
    int weekCompleted = 0;
    int monthCompleted = 0;

    // Count completed reports
    for (final report in state.reports) {
      if (report.status == 'completed' && report.closedAt != null) {
        final closedDate = DateTime(
          report.closedAt!.year,
          report.closedAt!.month,
          report.closedAt!.day,
        );

        // Today
        if (closedDate.isAtSameMomentAs(today)) {
          todayCompleted++;
        }

        // This week
        if (closedDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            closedDate.isBefore(now.add(const Duration(days: 1)))) {
          weekCompleted++;
        }

        // This month
        if (closedDate
                .isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
            closedDate.isBefore(now.add(const Duration(days: 1)))) {
          monthCompleted++;
        }
      }
    }

    // Count completed maintenance reports
    for (final maintenanceReport in state.maintenanceReports) {
      if (maintenanceReport.status == 'completed' &&
          maintenanceReport.closedAt != null) {
        final closedDate = DateTime(
          maintenanceReport.closedAt!.year,
          maintenanceReport.closedAt!.month,
          maintenanceReport.closedAt!.day,
        );

        // Today
        if (closedDate.isAtSameMomentAs(today)) {
          todayCompleted++;
        }

        // This week
        if (closedDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            closedDate.isBefore(now.add(const Duration(days: 1)))) {
          weekCompleted++;
        }

        // This month
        if (closedDate
                .isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
            closedDate.isBefore(now.add(const Duration(days: 1)))) {
          monthCompleted++;
        }
      }
    }

    return {
      'today': todayCompleted,
      'thisWeek': weekCompleted,
      'thisMonth': monthCompleted,
    };
  }

  Widget _buildTimelineItem(
      String period, String value, String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            period,
            style: AppFonts.bodyText(isDark: isDark).copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppFonts.statText(color: color, isDark: isDark).copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppFonts.bodyText(isDark: isDark).copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
