import 'package:flutter/material.dart';

import '../../../logic/blocs/super_admin/super_admin.dart';

class AdminManagementSection extends StatelessWidget {
  final SuperAdminLoaded state;
  final VoidCallback onCreateAdmin;

  const AdminManagementSection({
    super.key,
    required this.state,
    required this.onCreateAdmin,
  });

  @override
  Widget build(BuildContext context) {
    // Separate super admins from regular admins
    final superAdmins =
        state.admins.where((admin) => admin.role == 'super_admin').toList();
    final regularAdmins =
        state.admins.where((admin) => admin.role == 'admin').toList();

    return Column(
      children: [
        // Header with action buttons
        _buildAdminManagementHeader(context),
        const SizedBox(height: 20),

        // Responsive layout for admin sections
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 1200) {
              // Large screens: Side by side layout
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    flex: 3,
                    child: _buildSuperAdminsSection(context, superAdmins),
                  ),
                  const SizedBox(width: 20),
                  Flexible(
                    flex: 4,
                    child: _buildRegularAdminsSection(context, regularAdmins),
                  ),
                ],
              );
            } else {
              // Small/Medium screens: Stacked layout
              return Column(
                children: [
                  _buildSuperAdminsSection(context, superAdmins),
                  const SizedBox(height: 20),
                  _buildRegularAdminsSection(context, regularAdmins),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildAdminManagementHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6B46C1).withOpacity(0.1),
            const Color(0xFF8B5CF6).withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF6B46C1).withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6B46C1).withOpacity(0.2),
                  const Color(0xFF8B5CF6).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              size: 22,
              color: Color(0xFF6B46C1),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إدارة المسؤولين والمسؤولين',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF1E293B),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'إنشاء وتحرير وحذف حسابات المسؤولين والمسؤولين العامين',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildGradientButton(
            context,
            'إضافة مسؤول جديد',
            Icons.add_rounded,
            const Color(0xFF3B82F6),
            onCreateAdmin,
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.8),
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuperAdminsSection(
      BuildContext context, List<dynamic> superAdmins) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF8B5CF6).withOpacity(0.1),
            const Color(0xFF6B46C1).withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF8B5CF6).withOpacity(0.2),
                      const Color(0xFF6B46C1).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Color(0xFF8B5CF6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المسؤولين العامين',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: const Color(0xFF8B5CF6),
                          ),
                    ),
                    Text(
                      '${superAdmins.length} مدير عام',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (superAdmins.isEmpty)
            _buildEmptyStateCard(
              context,
              'لا يوجد مديرين عامين',
              'لم يتم إنشاء أي حساب مدير عام بعد',
              Icons.shield_outlined,
              const Color(0xFF8B5CF6),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900 ? 2 : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 1.4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: superAdmins.length,
                  itemBuilder: (context, index) {
                    final admin = superAdmins[index];
                    final stats = state.adminStats[admin.id] ?? {};
                    return _buildAdminPerformanceCard(
                        context, admin, stats, const Color(0xFF8B5CF6));
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRegularAdminsSection(
      BuildContext context, List<dynamic> regularAdmins) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3B82F6).withOpacity(0.1),
            const Color(0xFF1D4ED8).withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF3B82F6).withOpacity(0.2),
                      const Color(0xFF1D4ED8).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.people_rounded,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المسؤولين العاديين',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: const Color(0xFF3B82F6),
                          ),
                    ),
                    Text(
                      '${regularAdmins.length} مسؤول',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (regularAdmins.isEmpty)
            _buildEmptyStateCard(
              context,
              'لا يوجد مسؤولين',
              'ابدأ بإضافة مسؤولين لإدارة المشرفين',
              Icons.person_add_outlined,
              const Color(0xFF3B82F6),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900 ? 2 : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 1.4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: regularAdmins.length,
                  itemBuilder: (context, index) {
                    final admin = regularAdmins[index];
                    final stats =
                        state.adminStats[admin.id] ?? <String, dynamic>{};
                    return _buildAdminPerformanceCard(
                        context, admin, stats, const Color(0xFF3B82F6));
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateCard(BuildContext context, String title,
      String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withOpacity(0.05),
        border: Border.all(
          color: color.withOpacity(0.1),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 24,
              color: color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminPerformanceCard(BuildContext context, dynamic admin,
      Map<String, dynamic> stats, Color themeColor) {
    final assignedSupervisors =
        state.allSupervisors.where((s) => s['admin_id'] == admin.id).toList();
    final supervisorCount = stats['supervisors'] ?? 0;
    final totalReports = stats['reports'] ?? 0;
    final totalMaintenance = stats['maintenance'] ?? 0;
    final completedReports = stats['completed_reports'] ?? 0;
    final completedMaintenance = stats['completed_maintenance'] ?? 0;

    final totalWork = totalReports + totalMaintenance;
    final completedWork = completedReports + completedMaintenance;
    final completionRate = totalWork > 0 ? (completedWork / totalWork) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).brightness == Brightness.dark
              ? [
                  const Color(0xFF1E293B).withOpacity(0.9),
                  const Color(0xFF334155).withOpacity(0.7),
                ]
              : [
                  Colors.white.withOpacity(0.9),
                  const Color(0xFFF8FAFC).withOpacity(0.7),
                ],
        ),
        border: Border.all(
          color: themeColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with admin info
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [themeColor, themeColor.withOpacity(0.8)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  admin.role == 'super_admin'
                      ? Icons.shield_rounded
                      : Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 22,
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
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((admin.email ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        admin.email ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: _getCompletionRateColor(completionRate * 100)
                      .withOpacity(0.1),
                ),
                child: Text(
                  '${(completionRate * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _getCompletionRateColor(completionRate * 100),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: themeColor.withOpacity(0.1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  admin.role == 'super_admin'
                      ? Icons.verified_user
                      : Icons.admin_panel_settings,
                  size: 14,
                  color: themeColor,
                ),
                const SizedBox(width: 4),
                Text(
                  admin.role == 'super_admin' ? 'مدير عام' : 'مسؤول',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: themeColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Statistics cards
          Row(
            children: [
              Expanded(
                child: _buildMiniStatCard(context, 'مشرفين', supervisorCount,
                    const Color(0xFF10B981)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMiniStatCard(
                    context, 'بلاغات', totalReports, const Color(0xFF3B82F6)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMiniStatCard(context, 'صيانة', totalMaintenance,
                    const Color(0xFFEF4444)),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Completion stats
          Row(
            children: [
              Expanded(
                child: _buildMiniStatCard(
                    context, 'مكتمل', completedWork, const Color(0xFF10B981)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMiniStatCard(
                    context, 'المعين', assignedSupervisors.length, themeColor),
              ),
            ],
          ),

          const Spacer(),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  _showAdminDetails(admin, stats, assignedSupervisors),
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: const Text('عرض التفاصيل'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(
      BuildContext context, String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF374151)
            : Colors.white,
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getCompletionRateColor(double rate) {
    if (rate >= 80) return const Color(0xFF10B981);
    if (rate >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  void _showAdminDetails(dynamic admin, Map<String, dynamic> stats,
      List<Map<String, dynamic>> assignedSupervisors) {
    // Implementation for showing admin details dialog
    // This would show detailed information about the admin
  }
}
