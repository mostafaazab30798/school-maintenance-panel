import 'package:flutter/material.dart';

/// A modern, professional admin performance card widget
class AdminPerformanceCard extends StatelessWidget {
  final dynamic admin;
  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> allSupervisors;
  final List<Map<String, dynamic>> supervisorsWithStats;
  final VoidCallback? onTeamManagement;

  const AdminPerformanceCard({
    super.key,
    required this.admin,
    required this.stats,
    required this.allSupervisors,
    required this.supervisorsWithStats,
    this.onTeamManagement,
  });

  @override
  Widget build(BuildContext context) {
    final supervisorCount = stats['supervisors'] as int? ?? 0;
    final totalReports = stats['reports'] as int? ?? 0;
    final totalMaintenance = stats['maintenance'] as int? ?? 0;
    final completedReports = stats['completed_reports'] as int? ?? 0;
    final completedMaintenance = stats['completed_maintenance'] as int? ?? 0;

    final totalWork = totalReports + totalMaintenance;
    final completedWork = completedReports + completedMaintenance;
    final completionRate = totalWork > 0 ? (completedWork / totalWork) : 0.0;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(minWidth: 350, maxWidth: 400),
        decoration: _buildCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildTeamManagementSection(context, supervisorCount),
            const SizedBox(height: 16),
            _buildStatsGrid(context, totalReports, completedReports,
                totalMaintenance, completedMaintenance),
            const SizedBox(height: 16),
            _buildCompletionProgress(context, completionRate),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildCardDecoration(BuildContext context) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: Theme.of(context).brightness == Brightness.dark
            ? [const Color(0xFF1E293B), const Color(0xFF334155)]
            : [Colors.white, const Color(0xFFF8FAFC)],
      ),
      border: Border.all(
        color: const Color(0xFF3B82F6).withOpacity(0.2),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF3B82F6).withOpacity(0.15),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              (admin.name ?? 'أ')[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                admin.name ?? 'غير محدد',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'مسؤول',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamManagementSection(
      BuildContext context, int supervisorCount) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTeamManagement,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.people,
                  size: 16,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إدارة الفريق',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      supervisorCount > 0
                          ? '$supervisorCount مشرف مُعيّن'
                          : 'لا يوجد مشرفين مُعيّنين',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Color(0xFF10B981),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, int totalReports,
      int completedReports, int totalMaintenance, int completedMaintenance) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'البلاغات',
            '$completedReports/$totalReports',
            const Color(0xFF3B82F6),
            Icons.description,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'الصيانة',
            '$completedMaintenance/$totalMaintenance',
            const Color(0xFF10B981),
            Icons.build,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionProgress(BuildContext context, double completionRate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'معدل الإنجاز',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF374151),
              ),
            ),
            Text(
              '${(completionRate * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _getCompletionColor(completionRate),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: completionRate,
          backgroundColor: const Color(0xFFE5E7EB),
          valueColor: AlwaysStoppedAnimation<Color>(
              _getCompletionColor(completionRate)),
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Color _getCompletionColor(double rate) {
    if (rate >= 0.81) return const Color(0xFF10B981); // Green - Excellent
    if (rate >= 0.61) return const Color(0xFF3B82F6);  // Blue - Good
    if (rate >= 0.51) return const Color(0xFFF59E0B);  // Orange - Average
    return const Color(0xFFEF4444); // Red - Bad
  }
}
