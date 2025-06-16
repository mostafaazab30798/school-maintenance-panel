import 'package:flutter/material.dart';
import '../../../logic/blocs/dashboard/dashboard_state.dart';
import '../../../core/constants/app_fonts.dart';

class ActionableInsightsWidget extends StatelessWidget {
  final DashboardLoaded state;

  const ActionableInsightsWidget({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final insights = _getActionableInsights(state);

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
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  color: Color(0xFFF59E0B),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'رؤى قابلة للتنفيذ',
                style: AppFonts.sectionTitle(isDark: isDark)
                    .copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (insights.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الوضع مستقر',
                          style: AppFonts.cardTitle(
                            color: const Color(0xFF10B981),
                            isDark: isDark,
                          ).copyWith(fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'لا توجد مشاكل تحتاج إلى اهتمام فوري',
                          style: AppFonts.bodyText(isDark: isDark)
                              .copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            for (final insight in insights)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: insight['color'].withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: insight['color'].withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: insight['color'].withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        insight['icon'],
                        color: insight['color'],
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            insight['title'],
                            style: AppFonts.cardTitle(
                              color: insight['color'],
                              isDark: isDark,
                            ).copyWith(fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            insight['description'],
                            style: AppFonts.bodyText(isDark: isDark)
                                .copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getActionableInsights(DashboardLoaded state) {
    final insights = <Map<String, dynamic>>[];

    // Priority 1: Critical issues
    if (state.overdueReports > 0) {
      insights.add({
        'icon': Icons.schedule_rounded,
        'title': 'البلاغات المتأخرة',
        'description':
            'يوجد ${state.overdueReports} بلاغ متأخر يحتاج متابعة فورية',
        'color': const Color(0xFFEF4444),
      });
    }

    if (state.emergencyReports > 0) {
      insights.add({
        'icon': Icons.priority_high_rounded,
        'title': 'البلاغات الطارئة',
        'description':
            'يوجد ${state.emergencyReports} بلاغ طارئ يحتاج أولوية قصوى',
        'color': const Color(0xFFF59E0B),
      });
    }

    // Priority 2: Performance insights
    if (state.completionRate >= 0.9) {
      insights.add({
        'icon': Icons.star_rounded,
        'title': 'أداء استثنائي',
        'description':
            'معدل الإنجاز ${(state.completionRate * 100).toStringAsFixed(1)}% - أداء ممتاز!',
        'color': const Color(0xFF10B981),
      });
    } else if (state.completionRate >= 0.8) {
      insights.add({
        'icon': Icons.check_circle_rounded,
        'title': 'أداء جيد',
        'description':
            'معدل الإنجاز ${(state.completionRate * 100).toStringAsFixed(1)}% - استمر في الحفاظ على هذا المستوى',
        'color': const Color(0xFF10B981),
      });
    } else if (state.completionRate < 0.6) {
      insights.add({
        'icon': Icons.trending_up_rounded,
        'title': 'تحسين الأداء مطلوب',
        'description':
            'معدل الإنجاز ${(state.completionRate * 100).toStringAsFixed(1)}% - ركز على إنجاز المهام المعلقة',
        'color': const Color(0xFFEF4444),
      });
    }

    // Priority 3: Workload insights
    final totalTasks = state.totalReports + state.totalMaintenanceReports;
    final pendingTasks = state.pendingReports + state.pendingMaintenanceReports;

    if (pendingTasks > totalTasks * 0.7) {
      insights.add({
        'icon': Icons.work_rounded,
        'title': 'حمولة عمل عالية',
        'description':
            'يوجد ${pendingTasks} مهمة معلقة - قد تحتاج لتوزيع المهام',
        'color': const Color(0xFFF59E0B),
      });
    }

    // Priority 4: Supervisor insights
    if (state.totalSupervisors > 0 && totalTasks > 0) {
      final tasksPerSupervisor = totalTasks / state.totalSupervisors;
      if (tasksPerSupervisor > 20) {
        insights.add({
          'icon': Icons.groups_rounded,
          'title': 'توزيع المهام',
          'description':
              'متوسط ${tasksPerSupervisor.toStringAsFixed(1)} مهمة لكل مشرف - قد تحتاج لمزيد من المشرفين',
          'color': const Color(0xFF3B82F6),
        });
      }
    }

    // Priority 5: Maintenance insights
    if (state.totalMaintenanceReports > 0) {
      final maintenanceCompletionRate =
          (state.completedMaintenanceReports / state.totalMaintenanceReports) *
              100;

      if (maintenanceCompletionRate < 50) {
        insights.add({
          'icon': Icons.build_rounded,
          'title': 'تأخير في الصيانة',
          'description':
              'معدل إنجاز الصيانة ${maintenanceCompletionRate.toStringAsFixed(1)}% - يحتاج متابعة',
          'color': const Color(0xFFF59E0B),
        });
      }
    }

    return insights;
  }
}
