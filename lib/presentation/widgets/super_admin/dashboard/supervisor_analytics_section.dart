import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../logic/blocs/super_admin/super_admin_state.dart';
import '../modern_supervisor_card.dart';
import '../../attendance/attendance_dialog.dart';

class SupervisorAnalyticsSection extends StatelessWidget {
  final SuperAdminLoaded state;
  final Function(Map<String, dynamic>) onShowSupervisorDetails;
  final Function(String, String) onNavigateToSupervisorReports;
  final Function(String, String) onNavigateToSupervisorMaintenance;
  final Function(String, String) onNavigateToSupervisorCompleted;
  final Function(String, String) onNavigateToSupervisorLateReports;
  final Function(String, String) onNavigateToSupervisorLateCompleted;

  const SupervisorAnalyticsSection({
    super.key,
    required this.state,
    required this.onShowSupervisorDetails,
    required this.onNavigateToSupervisorReports,
    required this.onNavigateToSupervisorMaintenance,
    required this.onNavigateToSupervisorCompleted,
    required this.onNavigateToSupervisorLateReports,
    required this.onNavigateToSupervisorLateCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final totalSupervisors = state.allSupervisors.length;
    final topSupervisors =
        _getTopPerformingSupervisors(state.supervisorsWithStats, 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, totalSupervisors),
        const SizedBox(height: 16),
        _buildSupervisorCards(context, topSupervisors),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, int totalSupervisors) {
    return Row(
      children: [
        Icon(
          Icons.people_rounded,
          color: const Color(0xFF10B981),
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'أفضل المشرفين أداءً',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF334155),
              ),
        ),
        const SizedBox(width: 8),
        _buildCountBadge(totalSupervisors),
        const Spacer(),
        _buildSeeAllButton(context),
      ],
    );
  }

  Widget _buildCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF10B981),
        ),
      ),
    );
  }

  Widget _buildSeeAllButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/supervisors-list'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF10B981).withOpacity(0.2),
              width: 1,
            ),
            color: const Color(0xFF10B981).withOpacity(0.05),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'عرض الكل',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: const Color(0xFF10B981),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupervisorCards(
      BuildContext context, List<Map<String, dynamic>> topSupervisors) {
    if (state.supervisorsWithStats.isEmpty) {
      return _buildEmptyState();
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: topSupervisors.asMap().entries.map((entry) {
        final index = entry.key;
        final supervisor = entry.value;

        return _buildSupervisorCardWithBadge(context, supervisor, index);
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[100],
      ),
      child: const Center(
        child: Text(
          'لا يوجد مشرفين في النظام',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildSupervisorCardWithBadge(
      BuildContext context, Map<String, dynamic> supervisor, int index) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ModernSupervisorCard(
          supervisor: supervisor,
          onInfoTap: () => onShowSupervisorDetails(supervisor),
          onReportsTap: (supervisorId, username) =>
              onNavigateToSupervisorReports(supervisorId, username),
          onMaintenanceTap: (supervisorId, username) =>
              onNavigateToSupervisorMaintenance(supervisorId, username),
          onCompletedTap: (supervisorId, username) =>
              onNavigateToSupervisorCompleted(supervisorId, username),
          onLateReportsTap: (supervisorId, username) =>
              onNavigateToSupervisorLateReports(supervisorId, username),
          onLateCompletedTap: (supervisorId, username) =>
              onNavigateToSupervisorLateCompleted(supervisorId, username),
          onAttendanceTap: (supervisorId, username) =>
              AttendanceDialog.show(context, supervisorId, username),
        ),
        _buildRankBadge(index),
      ],
    );
  }

  Widget _buildRankBadge(int index) {
    final colors = _getRankColors(index);
    final icon = _getRankIcon(index);

    return Positioned(
      top: -8,
      right: -8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: colors[0].withOpacity(0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 10),
            const SizedBox(width: 3),
            Text(
              '#${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  List<Map<String, dynamic>> _getTopPerformingSupervisors(
      List<Map<String, dynamic>> supervisors, int count) {
    final sortedSupervisors = List<Map<String, dynamic>>.from(supervisors);

    sortedSupervisors.sort((a, b) {
      final aStats = a['stats'] as Map<String, dynamic>;
      final bStats = b['stats'] as Map<String, dynamic>;
      final aCompletionRate = aStats['completion_rate'] as double? ?? 0.0;
      final bCompletionRate = bStats['completion_rate'] as double? ?? 0.0;

      return bCompletionRate.compareTo(aCompletionRate);
    });

    return sortedSupervisors.take(count).toList();
  }

  List<Color> _getRankColors(int index) {
    switch (index) {
      case 0:
        return [const Color(0xFFFFD700), const Color(0xFFFFA500)]; // Gold
      case 1:
        return [const Color(0xFFC0C0C0), const Color(0xFF808080)]; // Silver
      case 2:
        return [const Color(0xFFCD7F32), const Color(0xFF8B4513)]; // Bronze
      default:
        return [const Color(0xFF10B981), const Color(0xFF059669)];
    }
  }

  IconData _getRankIcon(int index) {
    switch (index) {
      case 0:
        return Icons.emoji_events; // Trophy
      case 1:
        return Icons.military_tech; // Medal
      case 2:
        return Icons.star; // Star
      default:
        return Icons.trending_up;
    }
  }
}
