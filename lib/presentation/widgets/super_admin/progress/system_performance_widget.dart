import 'package:flutter/material.dart';
import '../../../../logic/blocs/super_admin/super_admin_state.dart';
import '../../../../core/constants/app_fonts.dart';

class SystemPerformanceWidget extends StatelessWidget {
  final SuperAdminLoaded state;

  const SystemPerformanceWidget({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate performance metrics
    final performanceMetrics = _calculatePerformanceMetrics();

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
                  Icons.speed_rounded,
                  color: Color(0xFF8B5CF6),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'أداء النظام',
                style: AppFonts.sectionTitle(isDark: isDark)
                    .copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Performance indicators
          _buildPerformanceIndicator(
            'كفاءة الإنجاز',
            performanceMetrics['completionEfficiency']!,
            Icons.check_circle_outline,
            isDark,
          ),
          const SizedBox(height: 12),
          _buildPerformanceIndicator(
            'سرعة الاستجابة',
            performanceMetrics['responseSpeed']!,
            Icons.flash_on_outlined,
            isDark,
          ),
          const SizedBox(height: 12),
          _buildPerformanceIndicator(
            'جودة العمل',
            performanceMetrics['workQuality']!,
            Icons.star_outline,
            isDark,
          ),
          const SizedBox(height: 12),
          _buildPerformanceIndicator(
            'توزيع الأعباء',
            performanceMetrics['workloadDistribution']!,
            Icons.balance_outlined,
            isDark,
          ),

          const SizedBox(height: 16),

          // Overall performance score
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getPerformanceColor(performanceMetrics['overallScore']!)
                      .withOpacity(0.1),
                  _getPerformanceColor(performanceMetrics['overallScore']!)
                      .withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getPerformanceColor(performanceMetrics['overallScore']!)
                    .withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color:
                      _getPerformanceColor(performanceMetrics['overallScore']!),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'النتيجة الإجمالية',
                  style: AppFonts.bodyText(isDark: isDark).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${performanceMetrics['overallScore']!.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: _getPerformanceColor(
                        performanceMetrics['overallScore']!),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceIndicator(
      String title, double value, IconData icon, bool isDark) {
    final color = _getPerformanceColor(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppFonts.bodyText(isDark: isDark).copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              '${value.toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / 100,
            backgroundColor:
                isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Map<String, double> _calculatePerformanceMetrics() {
    int totalReports = 0;
    int totalMaintenance = 0;
    int completedReports = 0;
    int completedMaintenance = 0;
    int lateReports = 0;
    int emergencyReports = 0;

    for (final admin in state.admins) {
      final stats = state.adminStats[admin.id];
      if (stats != null) {
        totalReports += (stats['reports'] as int? ?? 0);
        totalMaintenance += (stats['maintenance'] as int? ?? 0);
        completedReports += (stats['completed_reports'] as int? ?? 0);
        completedMaintenance += (stats['completed_maintenance'] as int? ?? 0);
        lateReports += (stats['late_reports'] as int? ?? 0);
        emergencyReports += (stats['emergency_reports'] as int? ?? 0);
      }
    }

    final totalWork = totalReports + totalMaintenance;
    final completedWork = completedReports + completedMaintenance;

    // Calculate metrics
    final completionEfficiency =
        totalWork > 0 ? (completedWork / totalWork * 100) : 0.0;
    final responseSpeed = totalReports > 0
        ? ((totalReports - lateReports) / totalReports * 100)
        : 100.0;
    final workQuality = totalReports > 0
        ? ((totalReports - emergencyReports) / totalReports * 100)
        : 100.0;

    // Calculate workload distribution (how evenly work is distributed among admins)
    final adminWorkloads = state.admins.map((admin) {
      final stats = state.adminStats[admin.id];
      return (stats?['reports'] as int? ?? 0) +
          (stats?['maintenance'] as int? ?? 0);
    }).toList();

    double workloadDistribution = 100.0;
    if (adminWorkloads.isNotEmpty && adminWorkloads.any((w) => w > 0)) {
      final avgWorkload =
          adminWorkloads.reduce((a, b) => a + b) / adminWorkloads.length;
      final variance = adminWorkloads
              .map((w) => (w - avgWorkload) * (w - avgWorkload))
              .reduce((a, b) => a + b) /
          adminWorkloads.length;
      final standardDeviation =
          variance > 0 ? (variance * 0.5) : 0; // Simplified sqrt approximation
      workloadDistribution = avgWorkload > 0
          ? (100 - (standardDeviation / avgWorkload * 100)).clamp(0, 100)
          : 100.0;
    }

    final overallScore = (completionEfficiency +
            responseSpeed +
            workQuality +
            workloadDistribution) /
        4;

    return {
      'completionEfficiency': completionEfficiency,
      'responseSpeed': responseSpeed,
      'workQuality': workQuality,
      'workloadDistribution': workloadDistribution,
      'overallScore': overallScore,
    };
  }

  Color _getPerformanceColor(double value) {
    if (value >= 80) return const Color(0xFF10B981);
    if (value >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}
