import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../logic/blocs/super_admin/super_admin_state.dart';
import '../admins_section.dart';
import '../../common/ui_components/chips_and_badges.dart';
import '../../common/ui_components/ranking_utils.dart';

class AdminAnalyticsSection extends StatelessWidget {
  final SuperAdminLoaded state;
  final Function(BuildContext, dynamic, List<Map<String, dynamic>>)
      onTeamManagement;
  final Function(BuildContext, dynamic, List<Map<String, dynamic>>)
      onShowReports;
  final Function(BuildContext, dynamic, List<Map<String, dynamic>>)
      onShowMaintenance;

  const AdminAnalyticsSection({
    super.key,
    required this.state,
    required this.onTeamManagement,
    required this.onShowReports,
    required this.onShowMaintenance,
  });

  @override
  Widget build(BuildContext context) {
    final regularAdmins = state.admins.where((a) => a.role == 'admin').toList();
    final totalAdmins = regularAdmins.length;

    if (regularAdmins.isEmpty) {
      return _buildEmptyAdminsState();
    }

    final topAdmins =
        RankingUtils.getTopPerformingAdmins(regularAdmins, state.adminStats, 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, totalAdmins),
        const SizedBox(height: 16),
        _buildAdminCards(topAdmins, context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, int totalAdmins) {
    return Row(
      children: [
        Icon(
          Icons.admin_panel_settings_rounded,
          color: const Color(0xFF3B82F6),
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'أفضل المسؤولين أداءً',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF334155),
              ),
        ),
        const SizedBox(width: 8),
        _buildCountBadge(totalAdmins),
        const Spacer(),
        _buildSeeAllButton(context),
      ],
    );
  }

  Widget _buildCountBadge(int count) {
    return ChipsAndBadges.buildCountBadge(
      count: count,
      color: const Color(0xFF3B82F6),
    );
  }

  Widget _buildSeeAllButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/admins-list'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF3B82F6).withOpacity(0.2),
              width: 1,
            ),
            color: const Color(0xFF3B82F6).withOpacity(0.05),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'عرض الكل',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: const Color(0xFF3B82F6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminCards(List<dynamic> topAdmins, BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: topAdmins.asMap().entries.map((entry) {
        final index = entry.key;
        final admin = entry.value;
        final stats = state.adminStats[admin.id] ?? <String, dynamic>{};

        return _buildAdminCardWithBadge(context, admin, stats, index);
      }).toList(),
    );
  }

  Widget _buildAdminCardWithBadge(BuildContext context, dynamic admin,
      Map<String, dynamic> stats, int index) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        buildModernAdminPerformanceCard(
          context,
          admin,
          stats,
          state.allSupervisors,
          state.supervisorsWithStats,
          onTeamManagement: onTeamManagement,
          onShowReports: onShowReports,
          onShowMaintenance: onShowMaintenance,
        ),
        // Performance rank badge
        RankingUtils.buildPerformanceBadgeForAdmin(index),
      ],
    );
  }

  Widget _buildEmptyAdminsState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF3B82F6).withOpacity(0.05),
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.1),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.admin_panel_settings_outlined,
              size: 48,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'لا يوجد مسؤولين',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ابدأ بإضافة مسؤولين لمراقبة أدائهم وإدارة المشرفين',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
