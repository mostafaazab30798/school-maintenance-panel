import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/admin.dart';
import '../super_admin/admins_section.dart';
import '../../../logic/blocs/super_admin/super_admin_bloc.dart';
import '../../../logic/blocs/super_admin/super_admin_event.dart';
import '../common/esc_dismissible_dialog.dart';
import '../super_admin/admins_section/team_management_dialog.dart';
import '../super_admin/admins_section/admin_reports_dialog.dart';
import '../super_admin/admins_section/admin_maintenance_dialog.dart';

class AdminsListContent extends StatefulWidget {
  final List<dynamic> admins;
  final Map<String, Map<String, dynamic>> adminStats;
  final List<Map<String, dynamic>> allSupervisors;
  final List<Map<String, dynamic>> supervisorsWithStats;

  const AdminsListContent({
    super.key,
    required this.admins,
    required this.adminStats,
    required this.allSupervisors,
    required this.supervisorsWithStats,
  });

  @override
  State<AdminsListContent> createState() => _AdminsListContentState();
}

class _AdminsListContentState extends State<AdminsListContent> {
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _sortAscending = true;
  String _performanceFilter = 'all';
  String _assignmentFilter = 'all';

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> get _filteredAndSortedAdmins {
    var filtered = widget.admins.where((admin) {
      if (_searchQuery.isNotEmpty) {
        final name = admin.name?.toLowerCase() ?? '';
        final email = admin.email?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        if (!name.contains(query) && !email.contains(query)) {
          return false;
        }
      }

      final stats = widget.adminStats[admin.id] ?? <String, dynamic>{};
      final totalWork = (stats['reports'] as int? ?? 0) + (stats['maintenance'] as int? ?? 0);
      final completedWork = (stats['completed_reports'] as int? ?? 0) + (stats['completed_maintenance'] as int? ?? 0);
      final completionRate = totalWork > 0 ? (completedWork / totalWork) : 0.0;
      final supervisorCount = stats['supervisors'] as int? ?? 0;

      if (_performanceFilter == 'high' && completionRate < 0.8) return false;
      if (_performanceFilter == 'low' && completionRate >= 0.5) return false;

      if (_assignmentFilter == 'assigned' && supervisorCount == 0) return false;
      if (_assignmentFilter == 'unassigned' && supervisorCount > 0) return false;

      return true;
    }).toList();

    filtered.sort((a, b) {
      final aStats = widget.adminStats[a.id] ?? <String, dynamic>{};
      final bStats = widget.adminStats[b.id] ?? <String, dynamic>{};

      int comparison = 0;

      switch (_sortBy) {
        case 'name':
          comparison = (a.name ?? '').compareTo(b.name ?? '');
          break;
        case 'completion_rate':
          final aTotalWork = (aStats['reports'] as int? ?? 0) + (aStats['maintenance'] as int? ?? 0);
          final aCompletedWork = (aStats['completed_reports'] as int? ?? 0) + (aStats['completed_maintenance'] as int? ?? 0);
          final aCompletionRate = aTotalWork > 0 ? (aCompletedWork / aTotalWork) : 0.0;
          
          final bTotalWork = (bStats['reports'] as int? ?? 0) + (bStats['maintenance'] as int? ?? 0);
          final bCompletedWork = (bStats['completed_reports'] as int? ?? 0) + (bStats['completed_maintenance'] as int? ?? 0);
          final bCompletionRate = bTotalWork > 0 ? (bCompletedWork / bTotalWork) : 0.0;
          
          comparison = aCompletionRate.compareTo(bCompletionRate);
          break;
        case 'reports':
          comparison = (aStats['reports'] as int? ?? 0).compareTo(bStats['reports'] as int? ?? 0);
          break;
        case 'maintenance':
          comparison = (aStats['maintenance'] as int? ?? 0).compareTo(bStats['maintenance'] as int? ?? 0);
          break;
        case 'supervisors':
          comparison = (aStats['supervisors'] as int? ?? 0).compareTo(bStats['supervisors'] as int? ?? 0);
          break;
      }

      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredAdmins = _filteredAndSortedAdmins;

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E293B)
                  : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF475569)
                          : const Color(0xFFE2E8F0),
                    ),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF334155)
                        : const Color(0xFFF8FAFC),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'البحث بالاسم أو البريد الإلكتروني...',
                      prefixIcon: Icon(Icons.search_rounded),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        'الأداء',
                        _performanceFilter,
                        {
                          'all': 'الكل',
                          'high': 'عالي (80%+)',
                          'low': 'منخفض (<50%)',
                        },
                        (value) => setState(() => _performanceFilter = value),
                        const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 12),
                      
                      _buildFilterChip(
                        'التعيين',
                        _assignmentFilter,
                        {
                          'all': 'الكل',
                          'assigned': 'لديه مشرفين',
                          'unassigned': 'بدون مشرفين',
                        },
                        (value) => setState(() => _assignmentFilter = value),
                        const Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 12),
                      
                      _buildSortChip(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  'عرض ${filteredAdmins.length} من ${widget.admins.length} مسؤول',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (_searchQuery.isNotEmpty || _performanceFilter != 'all' || _assignmentFilter != 'all')
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _performanceFilter = 'all';
                        _assignmentFilter = 'all';
                        _searchController.clear();
                      });
                    },
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('مسح الفلاتر'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),

          filteredAdmins.isEmpty
              ? _buildEmptyState()
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: filteredAdmins.map((admin) {
                      final stats = widget.adminStats[admin.id] ?? <String, dynamic>{};
                      return buildModernAdminPerformanceCard(
                        context,
                        admin,
                        stats,
                        widget.allSupervisors,
                        widget.supervisorsWithStats,
                        onTeamManagement: _showTeamManagementDialog,
                        onShowReports: _showAdminReports,
                        onShowMaintenance: _showAdminMaintenance,
                      );
                    }).toList(),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String currentValue,
    Map<String, String> options,
    Function(String) onChanged,
    Color color,
  ) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      itemBuilder: (context) => options.entries
          .map((entry) => PopupMenuItem<String>(
                value: entry.key,
                child: Row(
                  children: [
                    Icon(
                      currentValue == entry.key ? Icons.check : null,
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Text(entry.value),
                  ],
                ),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: currentValue != 'all' ? color.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: currentValue != 'all' ? color : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list,
              size: 16,
              color: currentValue != 'all' ? color : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Text(
              '$label: ${options[currentValue]}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: currentValue != 'all' ? color : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: currentValue != 'all' ? color : const Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip() {
    final sortOptions = {
      'name': 'الاسم',
      'completion_rate': 'معدل الإنجاز',
      'reports': 'البلاغات',
      'maintenance': 'الصيانة',
      'supervisors': 'المشرفين',
    };

    return PopupMenuButton<String>(
      onSelected: (value) {
        setState(() {
          if (_sortBy == value) {
            _sortAscending = !_sortAscending;
          } else {
            _sortBy = value;
            _sortAscending = true;
          }
        });
      },
      itemBuilder: (context) => sortOptions.entries
          .map((entry) => PopupMenuItem<String>(
                value: entry.key,
                child: Row(
                  children: [
                    Icon(
                      _sortBy == entry.key
                          ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                          : Icons.sort,
                      size: 16,
                      color: const Color(0xFF8B5CF6),
                    ),
                    const SizedBox(width: 8),
                    Text(entry.value),
                  ],
                ),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF8B5CF6).withOpacity(0.1),
          border: Border.all(color: const Color(0xFF8B5CF6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
              color: const Color(0xFF8B5CF6),
            ),
            const SizedBox(width: 4),
            Text(
              'ترتيب: ${sortOptions[_sortBy]}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: Color(0xFF8B5CF6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilters = _searchQuery.isNotEmpty || _performanceFilter != 'all' || _assignmentFilter != 'all';

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E293B)
              : const Color(0xFFF8FAFC),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF475569)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                hasFilters ? Icons.search_off : Icons.admin_panel_settings_outlined,
                size: 48,
                color: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'لا توجد نتائج' : 'لا يوجد مسؤولين',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'جرب تغيير معايير البحث أو الفلترة'
                  : 'لا يوجد مسؤولين في النظام حالياً',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            if (hasFilters) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _performanceFilter = 'all';
                    _assignmentFilter = 'all';
                    _searchController.clear();
                  });
                },
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('مسح جميع الفلاتر'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showTeamManagementDialog(
    BuildContext context,
    dynamic admin,
    List<Map<String, dynamic>> allSupervisors,
  ) {
    context.showEscDismissibleDialog(
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<SuperAdminBloc>(),
        child: TeamManagementDialog(
          admin: admin,
          allSupervisors: allSupervisors,
          onSave: (selectedSupervisorIds) {
            context.read<SuperAdminBloc>().add(AssignSupervisorsToAdmin(
                  adminId: admin.id,
                  supervisorIds: selectedSupervisorIds,
                ));
          },
        ),
      ),
    );
  }

  void _showAdminReports(
    BuildContext context,
    dynamic admin,
    List<Map<String, dynamic>> adminSupervisorsWithStats,
  ) {
    context.showEscDismissibleDialog(
      barrierDismissible: true,
      builder: (dialogContext) => AdminReportsDialog(
        admin: admin,
        adminSupervisorsWithStats: adminSupervisorsWithStats,
      ),
    );
  }

  void _showAdminMaintenance(
    BuildContext context,
    dynamic admin,
    List<Map<String, dynamic>> adminSupervisorsWithStats,
  ) {
    context.showEscDismissibleDialog(
      barrierDismissible: true,
      builder: (dialogContext) => AdminMaintenanceDialog(
        admin: admin,
        adminSupervisorsWithStats: adminSupervisorsWithStats,
      ),
    );
  }
} 