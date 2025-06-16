import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../logic/blocs/dashboard/dashboard_bloc.dart';
import '../../../logic/blocs/dashboard/dashboard_state.dart';
import '../../../core/constants/app_fonts.dart';

class ProgressVisualizationWidget extends StatelessWidget {
  final DashboardLoaded state;

  const ProgressVisualizationWidget({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chartSections = _buildChartSections();

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
                  Icons.donut_large_rounded,
                  color: Color(0xFF3B82F6),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'توزيع المهام',
                style: AppFonts.sectionTitle(isDark: isDark)
                    .copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: chartSections.isEmpty
                ? _buildEmptyState(isDark)
                : Row(
                    children: [
                      // Pie Chart - Narrower
                      SizedBox(
                        width: 120,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 25,
                            sections: chartSections,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Expanded Legend
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (state.completedReports > 0)
                              _buildCompactLegendItem(
                                  'البلاغات المكتملة',
                                  const Color(0xFF10B981),
                                  state.completedReports,
                                  context),
                            if (state.pendingReports > 0)
                              _buildCompactLegendItem(
                                  'البلاغات المعلقة',
                                  const Color(0xFF3B82F6),
                                  state.pendingReports,
                                  context),
                            if (state.overdueReports > 0)
                              _buildCompactLegendItem(
                                  'البلاغات المتأخرة',
                                  const Color(0xFFEF4444),
                                  state.overdueReports,
                                  context),
                            if (state.completedMaintenanceReports > 0)
                              _buildCompactLegendItem(
                                  'الصيانة المكتملة',
                                  const Color(0xFF06B6D4),
                                  state.completedMaintenanceReports,
                                  context),
                            if (state.pendingMaintenanceReports > 0)
                              _buildCompactLegendItem(
                                  'الصيانة المعلقة',
                                  const Color(0xFF8B5CF6),
                                  state.pendingMaintenanceReports,
                                  context),
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

  List<PieChartSectionData> _buildChartSections() {
    final sections = <PieChartSectionData>[];

    // Only add sections with values > 0
    if (state.completedReports > 0) {
      sections.add(PieChartSectionData(
        value: state.completedReports.toDouble(),
        title: '',
        color: const Color(0xFF10B981),
        radius: 30,
      ));
    }

    if (state.pendingReports > 0) {
      sections.add(PieChartSectionData(
        value: state.pendingReports.toDouble(),
        title: '',
        color: const Color(0xFF3B82F6),
        radius: 30,
      ));
    }

    if (state.overdueReports > 0) {
      sections.add(PieChartSectionData(
        value: state.overdueReports.toDouble(),
        title: '',
        color: const Color(0xFFEF4444),
        radius: 30,
      ));
    }

    if (state.completedMaintenanceReports > 0) {
      sections.add(PieChartSectionData(
        value: state.completedMaintenanceReports.toDouble(),
        title: '',
        color: const Color(0xFF06B6D4),
        radius: 30,
      ));
    }

    if (state.pendingMaintenanceReports > 0) {
      sections.add(PieChartSectionData(
        value: state.pendingMaintenanceReports.toDouble(),
        title: '',
        color: const Color(0xFF8B5CF6),
        radius: 30,
      ));
    }

    return sections;
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 48,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'لا توجد مهام حالياً',
            style: AppFonts.bodyText(isDark: isDark).copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLegendItem(
      String label, Color color, int value, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppFonts.bodyText(isDark: isDark).copyWith(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value.toString(),
            style: AppFonts.statText(color: color, isDark: isDark)
                .copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
