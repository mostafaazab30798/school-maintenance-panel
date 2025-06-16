import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../logic/blocs/super_admin/super_admin_state.dart';
import '../../dashboard/indicator_card.dart';
import '../../dashboard/completion_progress_card.dart';

class StatisticsSection extends StatelessWidget {
  final SuperAdminLoaded state;
  final VoidCallback onNavigateToAllReports;
  final VoidCallback onNavigateToCompletedReports;
  final VoidCallback onNavigateToAllMaintenance;

  const StatisticsSection({
    super.key,
    required this.state,
    required this.onNavigateToAllReports,
    required this.onNavigateToCompletedReports,
    required this.onNavigateToAllMaintenance,
  });

  @override
  Widget build(BuildContext context) {
    final statistics = _calculateStatistics();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'إحصائيات النظام العامة',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF334155),
                letterSpacing: -0.1,
              ),
        ),
        const SizedBox(height: 12),
        _buildStatisticsCards(context, statistics),
      ],
    );
  }

  Map<String, dynamic> _calculateStatistics() {
    int totalReports = 0;
    int totalMaintenance = 0;
    int completedReports = 0;
    int completedMaintenance = 0;

    for (final admin in state.admins) {
      final stats = state.adminStats[admin.id];
      if (stats != null) {
        totalReports += (stats['reports'] as int? ?? 0);
        totalMaintenance += (stats['maintenance'] as int? ?? 0);
        completedReports += (stats['completed_reports'] as int? ?? 0);
        completedMaintenance += (stats['completed_maintenance'] as int? ?? 0);
      }
    }

    final totalWork = totalReports + totalMaintenance;
    final completedWork = completedReports + completedMaintenance;
    final systemCompletionRate =
        totalWork > 0 ? (completedWork / totalWork * 100) : 0.0;

    return {
      'totalReports': totalReports,
      'totalMaintenance': totalMaintenance,
      'completedReports': completedReports,
      'completedMaintenance': completedMaintenance,
      'systemCompletionRate': systemCompletionRate,
    };
  }

  Widget _buildStatisticsCards(BuildContext context, Map<String, dynamic> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 800;

        final cards = [
          IndicatorCard(
            label: 'إجمالي البلاغات',
            count: stats['totalReports'],
            icon: Icons.report_outlined,
            color: const Color(0xFFF59E0B),
            onTap: onNavigateToAllReports,
          ),
          IndicatorCard(
            label: 'البلاغات المكتملة',
            count: stats['completedReports'],
            icon: Icons.check_circle_outlined,
            color: const Color(0xFF10B981),
            onTap: onNavigateToCompletedReports,
          ),
          IndicatorCard(
            label: 'إجمالي الصيانة',
            count: stats['totalMaintenance'],
            icon: Icons.build_outlined,
            color: const Color(0xFFEF4444),
            onTap: onNavigateToAllMaintenance,
          ),
          CompletionProgressCard(
            percentage: stats['systemCompletionRate'] / 100,
            onTap: () => context.go('/super-admin-progress'),
          ),
        ];

        if (isSmallScreen) {
          return _buildGridLayout(cards);
        } else {
          return _buildRowLayout(cards);
        }
      },
    );
  }

  Widget _buildGridLayout(List<Widget> cards) {
    return SizedBox(
      height: 380,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 16),
                Expanded(child: cards[1]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(child: cards[2]),
                const SizedBox(width: 16),
                Expanded(child: cards[3]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowLayout(List<Widget> cards) {
    return SizedBox(
      height: 180,
      child: Row(
        children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 16),
          Expanded(child: cards[1]),
          const SizedBox(width: 16),
          Expanded(child: cards[2]),
          const SizedBox(width: 16),
          Expanded(child: cards[3]),
        ],
      ),
    );
  }
} 