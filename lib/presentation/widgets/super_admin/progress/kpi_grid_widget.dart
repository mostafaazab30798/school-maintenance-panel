import 'package:flutter/material.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../logic/blocs/super_admin/super_admin_bloc.dart';
import '../../../../logic/blocs/super_admin/super_admin_state.dart';

class KPIGridWidget extends StatelessWidget {
  final SuperAdminLoaded state;

  const KPIGridWidget({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final analytics = _calculateAnalytics(state);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

        if (isWide) {
          return Row(
            children: [
              Expanded(
                  child: _buildKPICard(
                      'إجمالي البلاغات',
                      '${analytics['totalReports']}',
                      Icons.description_rounded,
                      const Color(0xFF4ECDC4),
                      context)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildKPICard(
                      'البلاغات المكتملة',
                      '${analytics['completedReports']}',
                      Icons.check_circle_rounded,
                      const Color(0xFF45B7D1),
                      context)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildKPICard(
                      'معدل الإنجاز',
                      '${(analytics['completionRate'] * 100).toStringAsFixed(1)}%',
                      Icons.trending_up_rounded,
                      const Color(0xFF96CEB4),
                      context)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildKPICard(
                      'البلاغات المتأخرة',
                      '${analytics['lateReports']}',
                      Icons.warning_rounded,
                      const Color(0xFFFF6B6B),
                      context)),
            ],
          );
        } else {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: _buildKPICard(
                          'إجمالي البلاغات',
                          '${analytics['totalReports']}',
                          Icons.description_rounded,
                          const Color(0xFF4ECDC4),
                          context)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildKPICard(
                          'البلاغات المكتملة',
                          '${analytics['completedReports']}',
                          Icons.check_circle_rounded,
                          const Color(0xFF45B7D1),
                          context)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _buildKPICard(
                          'معدل الإنجاز',
                          '${(analytics['completionRate'] * 100).toStringAsFixed(1)}%',
                          Icons.trending_up_rounded,
                          const Color(0xFF96CEB4),
                          context)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildKPICard(
                          'البلاغات المتأخرة',
                          '${analytics['lateReports']}',
                          Icons.warning_rounded,
                          const Color(0xFFFF6B6B),
                          context)),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color,
      BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Icon(
                Icons.more_horiz_rounded,
                color: isDark ? Colors.white30 : Colors.black26,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppFonts.bodyText(isDark: isDark).copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color:
                  isDark ? Colors.white70 : Colors.black.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateAnalytics(SuperAdminLoaded state) {
    int totalReports = 0;
    int completedReports = 0;
    int lateReports = 0;

    for (final stats in state.adminStats.values) {
      totalReports += (stats['reports'] as int? ?? 0);
      completedReports += (stats['completed_reports'] as int? ?? 0);
      lateReports += (stats['late_reports'] as int? ?? 0);
    }

    final completionRate =
        totalReports > 0 ? completedReports / totalReports : 0.0;

    return {
      'totalReports': totalReports,
      'completedReports': completedReports,
      'lateReports': lateReports,
      'completionRate': completionRate,
    };
  }
}
