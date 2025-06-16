import 'package:flutter/material.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../logic/blocs/super_admin/super_admin_bloc.dart';
import '../../../../logic/blocs/super_admin/super_admin_state.dart';

class AdminProgressSectionWidget extends StatelessWidget {
  final SuperAdminLoaded state;

  const AdminProgressSectionWidget({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final regularAdmins =
        state.admins.where((admin) => admin.role == 'admin').toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تقدم المسؤولين الفردي',
                      style: AppFonts.sectionTitle(isDark: isDark).copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'معدل الإنجاز والأداء لكل مدير',
                      style: AppFonts.bodyText(isDark: isDark).copyWith(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (regularAdmins.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 48,
                    color: isDark ? Colors.white30 : Colors.black26,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'لا يوجد مديرين',
                    style: AppFonts.bodyText(isDark: isDark).copyWith(
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: regularAdmins.length,
                itemBuilder: (context, index) {
                  final admin = regularAdmins[index];
                  return _buildAdminCard(admin, isDark, index);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(dynamic admin, bool isDark, int index) {
    final stats = state.adminStats[admin.id] ?? {};
    final totalReports = (stats['reports'] as int? ?? 0);
    final completedReports = (stats['completed_reports'] as int? ?? 0);
    final lateReports = (stats['late_reports'] as int? ?? 0);
    final totalMaintenance = (stats['maintenance'] as int? ?? 0);
    final completedMaintenance = (stats['completed_maintenance'] as int? ?? 0);

    final totalWork = totalReports + totalMaintenance;
    final completedWork = completedReports + completedMaintenance;
    final completionRate = totalWork > 0 ? (completedWork / totalWork) : 0.0;

    final colors = [
      const Color(0xFF667EEA),
      const Color(0xFF4ECDC4),
      const Color(0xFF96CEB4),
      const Color(0xFFFECEA8),
    ];
    final cardColor = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      admin.name ?? 'مدير غير محدد',
                      style: AppFonts.cardTitle(isDark: isDark).copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$totalWork مهمة إجمالية',
                      style: AppFonts.bodyText(isDark: isDark).copyWith(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getCompletionColor(completionRate)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getCompletionColor(completionRate)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${(completionRate * 100).toInt()}%',
                  style: TextStyle(
                    color: _getCompletionColor(completionRate),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'معدل الإنجاز',
                style: AppFonts.bodyText(isDark: isDark).copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$completedWork من $totalWork',
                style: AppFonts.bodyText(isDark: isDark).copyWith(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: completionRate,
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          if (lateReports > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_rounded,
                    color: Color(0xFFFF6B6B),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$lateReports تقرير متأخر',
                    style: AppFonts.bodyText(isDark: isDark).copyWith(
                      fontSize: 12,
                      color: const Color(0xFFFF6B6B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getCompletionColor(double rate) {
    if (rate >= 0.81) return const Color(0xFF10B981); // Green - Excellent  
    if (rate >= 0.61) return const Color(0xFF3B82F6);  // Blue - Good
    if (rate >= 0.51) return const Color(0xFFF59E0B);  // Orange - Average
    return const Color(0xFFEF4444); // Red - Bad
  }
}
