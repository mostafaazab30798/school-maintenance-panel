import 'package:flutter/material.dart';
import '../../../logic/blocs/dashboard/dashboard_state.dart';
import '../../../core/constants/app_fonts.dart';

class PerformanceTrendsWidget extends StatelessWidget {
  final DashboardLoaded state;

  const PerformanceTrendsWidget({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final performanceData = _calculatePerformanceData();

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
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Color(0xFF8B5CF6),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'اتجاهات الأداء',
                style: AppFonts.sectionTitle(isDark: isDark)
                    .copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTrendItem(
              'معدل الإنجاز الإجمالي',
              '${(state.completionRate * 100).toStringAsFixed(1)}%',
              state.completionRate >= 0.8
                  ? Icons.trending_up
                  : Icons.trending_down,
              state.completionRate >= 0.8
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              isDark),
          const SizedBox(height: 12),
          _buildTrendItem(
              'متوسط وقت الاستجابة',
              performanceData['averageResponseTime'],
              Icons.schedule,
              const Color(0xFF3B82F6),
              isDark),
          const SizedBox(height: 12),
          _buildTrendItem(
              'معدل حل البلاغات',
              '${performanceData['resolutionRate']}%',
              Icons.check_circle,
              const Color(0xFF06B6D4),
              isDark),
          const SizedBox(height: 12),
          _buildTrendItem(
              'معدل البلاغات المتأخرة',
              '${performanceData['overdueRate']}%',
              performanceData['overdueRate'] > 20
                  ? Icons.trending_up
                  : Icons.trending_down,
              performanceData['overdueRate'] > 20
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
              isDark),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculatePerformanceData() {
    // Calculate average response time
    double totalResponseHours = 0;
    int completedReportsWithDates = 0;

    for (final report in state.reports) {
      if (report.status == 'completed' && report.closedAt != null) {
        final responseTime = report.closedAt!.difference(report.createdAt);
        totalResponseHours += responseTime.inHours;
        completedReportsWithDates++;
      }
    }

    for (final maintenanceReport in state.maintenanceReports) {
      if (maintenanceReport.status == 'completed' &&
          maintenanceReport.closedAt != null) {
        final responseTime =
            maintenanceReport.closedAt!.difference(maintenanceReport.createdAt);
        totalResponseHours += responseTime.inHours;
        completedReportsWithDates++;
      }
    }

    final averageResponseHours = completedReportsWithDates > 0
        ? totalResponseHours / completedReportsWithDates
        : 0.0;

    String averageResponseTime;
    if (averageResponseHours < 1) {
      averageResponseTime = '${(averageResponseHours * 60).round()} دقيقة';
    } else if (averageResponseHours < 24) {
      averageResponseTime = '${averageResponseHours.toStringAsFixed(1)} ساعة';
    } else {
      averageResponseTime =
          '${(averageResponseHours / 24).toStringAsFixed(1)} يوم';
    }

    // Calculate resolution rate (completed vs total)
    final totalTasks = state.totalReports + state.totalMaintenanceReports;
    final completedTasks =
        state.completedReports + state.completedMaintenanceReports;
    final resolutionRate =
        totalTasks > 0 ? ((completedTasks / totalTasks) * 100).round() : 0;

    // Calculate overdue rate
    final overdueRate = state.totalReports > 0
        ? ((state.overdueReports / state.totalReports) * 100).round()
        : 0;

    return {
      'averageResponseTime': averageResponseTime,
      'resolutionRate': resolutionRate,
      'overdueRate': overdueRate,
    };
  }

  Widget _buildTrendItem(
      String title, String value, IconData icon, Color color, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: AppFonts.bodyText(isDark: isDark).copyWith(fontSize: 12),
          ),
        ),
        Text(
          value,
          style: AppFonts.statText(color: color, isDark: isDark)
              .copyWith(fontSize: 12),
        ),
      ],
    );
  }
}
