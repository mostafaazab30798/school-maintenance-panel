import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../super_admin/modern_supervisor_card.dart';
import '../../../data/models/admin.dart';
import '../super_admin/dialogs/supervisor_detail_dialog.dart';
import '../super_admin/dialogs/technician_management_dialog.dart';
import '../super_admin/dialogs/schools_list_dialog.dart';
import '../super_admin/dialogs/school_assignment_dialog.dart';
import '../../../data/models/supervisor.dart';
import '../../../logic/blocs/super_admin/super_admin_bloc.dart';
import '../../../logic/blocs/super_admin/super_admin_event.dart';
import '../../../core/services/bloc_manager.dart';
import '../common/esc_dismissible_dialog.dart';
import '../attendance/attendance_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'export_attendance_excel.dart';
import '../../../data/repositories/supervisor_attendance_repository.dart';
import '../../../data/models/supervisor_attendance.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupervisorsListContent extends StatefulWidget {
  final List<Map<String, dynamic>> supervisorsWithStats;
  final List<Admin> admins;

  const SupervisorsListContent({
    super.key,
    required this.supervisorsWithStats,
    required this.admins,
  });

  @override
  State<SupervisorsListContent> createState() => _SupervisorsListContentState();
}

class _SupervisorsListContentState extends State<SupervisorsListContent> {
  String _searchQuery = '';
  String _sortBy = 'name'; // name, completion_rate, reports, maintenance, admin
  bool _sortAscending = true;
  String _filterBy =
      'all'; // all, assigned, unassigned, high_performance, low_performance
  String _selectedAdminId = 'all'; // all, specific admin id, unassigned
  bool _isGridView = true; // true for grid, false for list
  int _currentPage = 0;
  final int _itemsPerPage = 12;

  List<Map<String, dynamic>> get _filteredAndSortedSupervisors {
    var supervisors =
        List<Map<String, dynamic>>.from(widget.supervisorsWithStats);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      supervisors = supervisors.where((supervisor) {
        final username =
            (supervisor['username'] as String? ?? '').toLowerCase();
        final email = (supervisor['email'] as String? ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return username.contains(query) || email.contains(query);
      }).toList();
    }

    // Apply admin filter
    if (_selectedAdminId != 'all') {
      if (_selectedAdminId == 'unassigned') {
        supervisors = supervisors.where((s) => s['admin_id'] == null).toList();
      } else {
        supervisors = supervisors
            .where((s) => s['admin_id'] == _selectedAdminId)
            .toList();
      }
    }

    // Apply performance filter
    switch (_filterBy) {
      case 'assigned':
        supervisors = supervisors.where((s) => s['admin_id'] != null).toList();
        break;
      case 'unassigned':
        supervisors = supervisors.where((s) => s['admin_id'] == null).toList();
        break;
      case 'high_performance':
        supervisors = supervisors.where((s) {
          final stats = s['stats'] as Map<String, dynamic>;
          final completionRate = stats['completion_rate'] as double? ?? 0.0;
          return completionRate >= 0.8;
        }).toList();
        break;
      case 'low_performance':
        supervisors = supervisors.where((s) {
          final stats = s['stats'] as Map<String, dynamic>;
          final completionRate = stats['completion_rate'] as double? ?? 0.0;
          return completionRate < 0.5;
        }).toList();
        break;
    }

    // Apply sorting
    supervisors.sort((a, b) {
      dynamic aValue, bValue;

      switch (_sortBy) {
        case 'name':
          aValue = (a['username'] as String? ?? '').toLowerCase();
          bValue = (b['username'] as String? ?? '').toLowerCase();
          break;
        case 'completion_rate':
          final aStats = a['stats'] as Map<String, dynamic>;
          final bStats = b['stats'] as Map<String, dynamic>;
          aValue = aStats['completion_rate'] as double? ?? 0.0;
          bValue = bStats['completion_rate'] as double? ?? 0.0;
          break;
        case 'reports':
          final aStats = a['stats'] as Map<String, dynamic>;
          final bStats = b['stats'] as Map<String, dynamic>;
          aValue = aStats['reports'] as int? ?? 0;
          bValue = bStats['reports'] as int? ?? 0;
          break;
        case 'maintenance':
          final aStats = a['stats'] as Map<String, dynamic>;
          final bStats = b['stats'] as Map<String, dynamic>;
          aValue = aStats['maintenance'] as int? ?? 0;
          bValue = bStats['maintenance'] as int? ?? 0;
          break;
        case 'admin':
          aValue = _getAdminName(a['admin_id']).toLowerCase();
          bValue = _getAdminName(b['admin_id']).toLowerCase();
          break;
        default:
          aValue = (a['username'] as String? ?? '').toLowerCase();
          bValue = (b['username'] as String? ?? '').toLowerCase();
      }

      final comparison = aValue.compareTo(bValue);
      return _sortAscending ? comparison : -comparison;
    });

    return supervisors;
  }

  List<Map<String, dynamic>> get _paginatedSupervisors {
    final filtered = _filteredAndSortedSupervisors;
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, filtered.length);
    if (filtered.isEmpty || startIndex >= filtered.length) return [];
    // Ensure startIndex is never negative or > filtered.length
    return filtered.sublist(startIndex.clamp(0, filtered.length), endIndex);
  }

  int get _totalPages {
    final filtered = _filteredAndSortedSupervisors;
    // Always return at least 1 to avoid ArgumentError in pagination
    return ((filtered.length / _itemsPerPage).ceil()).clamp(1, 9999);
  }

  Map<String, List<Map<String, dynamic>>> get _groupedSupervisors {
    final filtered = _filteredAndSortedSupervisors;
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final supervisor in filtered) {
      final adminId = supervisor['admin_id'] as String?;
      final key = adminId ?? 'unassigned';

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(supervisor);
    }

    return grouped;
  }

  String _getAdminName(String? adminId) {
    if (adminId == null) return 'غير مُعيّن';
    final admin = widget.admins.firstWhere(
      (a) => a.id == adminId,
      orElse: () => Admin(
        id: '',
        name: 'غير معروف',
        email: '',
        role: '',
        createdAt: DateTime.now(),
      ),
    );
    return admin.name;
  }

  @override
  Widget build(BuildContext context) {
    final filteredCount = _filteredAndSortedSupervisors.length;

    if (widget.supervisorsWithStats.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildControlsSection(context, filteredCount),
          _buildEmptyState(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Controls Section
        _buildControlsSection(context, filteredCount),

        // Content based on view type
        if (_isGridView) _buildGridView() else _buildListView(),

        // Pagination Controls
        if (_totalPages > 1)
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildPaginationControls(),
          ),

        // Bottom padding
        const SizedBox(height: 24),
      ],
    );
  }

  // Helper methods to replace sliver widgets with normal widgets
  Widget _buildGridView() {
    final paginatedSupervisors = _paginatedSupervisors;

    if (paginatedSupervisors.isEmpty) {
      return _buildNoResultsState();
    }

    // Responsive crossAxisCount
    int crossAxisCount = 1;
    final width = MediaQuery.of(context).size.width;
    if (width > 1400) {
      crossAxisCount = 4;
    } else if (width > 1000) {
      crossAxisCount = 3;
    } else if (width > 600) {
      crossAxisCount = 2;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Add vertical padding
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 24, // Increased spacing between rows
          crossAxisSpacing: 24, // Increased spacing between columns
          childAspectRatio: 0.7, // Make cards taller to prevent overflow
        ),
        itemCount: paginatedSupervisors.length,
        itemBuilder: (context, index) {
          final supervisor = paginatedSupervisors[index];
          return ModernSupervisorCard(
            supervisor: supervisor,
            onInfoTap: () => _showSupervisorDetails(context, supervisor),
            onReportsTap: (supervisorId, username) =>
                _navigateToSupervisorReports(context, supervisorId, username),
            onMaintenanceTap: (supervisorId, username) =>
                _navigateToSupervisorMaintenance(context, supervisorId, username),
            onCompletedTap: (supervisorId, username) =>
                _navigateToSupervisorCompleted(context, supervisorId, username),
            onLateReportsTap: (supervisorId, username) =>
                _navigateToSupervisorLateReports(context, supervisorId, username),
            onLateCompletedTap: (supervisorId, username) =>
                _navigateToSupervisorLateCompleted(context, supervisorId, username),
            onAttendanceTap: (supervisorId, username) =>
                _showAttendanceDialog(context, supervisorId, username),
          );
        },
      ),
    );
  }

  Widget _buildListView() {
    final paginatedSupervisors = _paginatedSupervisors;

    if (paginatedSupervisors.isEmpty) {
      return _buildNoResultsState();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Add vertical padding
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: paginatedSupervisors.length,
        itemBuilder: (context, index) {
          final supervisor = paginatedSupervisors[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16), // Add space between cards
            child: _buildSupervisorListItem(supervisor),
          );
        },
      ),
    );
  }

  Widget _buildControlsSection(BuildContext context, int filteredCount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar and View Toggle + Export Button
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _currentPage = 0;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'البحث بالاسم أو البريد الإلكتروني...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF10B981), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFF8FAFC),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 16),

              const SizedBox(width: 16),
              // View Toggle
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    _buildViewToggleButton(
                      icon: Icons.grid_view,
                      isSelected: _isGridView,
                      onTap: () => setState(() => _isGridView = true),
                    ),
                    _buildViewToggleButton(
                      icon: Icons.view_list,
                      isSelected: !_isGridView,
                      onTap: () => setState(() => _isGridView = false),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Results count
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.people,
                      color: Color(0xFF10B981),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$filteredCount نتيجة',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Filter Controls
          Row(
            children: [
              // Admin Filter
              Expanded(
                child: _buildDropdown(
                  'تصفية حسب المسؤول:',
                  _selectedAdminId,
                  _buildAdminFilterOptions(),
                  (value) {
                    setState(() {
                      _selectedAdminId = value!;
                      _currentPage = 0;
                    });
                  },
                ),
              ),

              const SizedBox(width: 16),

              // Performance Filter
              Expanded(
                child: _buildDropdown(
                  'تصفية حسب الأداء:',
                  _filterBy,
                  {
                    'all': 'الكل',
                    'assigned': 'المُعيّنين',
                    'unassigned': 'غير المُعيّنين',
                    'high_performance': 'أداء عالي (80%+)',
                    'low_performance': 'أداء منخفض (<50%)',
                  },
                  (value) {
                    setState(() {
                      _filterBy = value!;
                      _currentPage = 0;
                    });
                  },
                ),
              ),

              const SizedBox(width: 16),

              // Sort Dropdown
              Expanded(
                child: _buildDropdown(
                  'ترتيب حسب:',
                  _sortBy,
                  {
                    'name': 'الاسم',
                    'completion_rate': 'معدل الإنجاز',
                    'reports': 'عدد البلاغات',
                    'maintenance': 'عدد الصيانة',
                    'admin': 'المسؤول',
                  },
                  (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                  },
                ),
              ),

              const SizedBox(width: 12),

              // Sort Direction Toggle
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                      color: isDark ? const Color(0xFF334155) : Colors.white,
                    ),
                    child: Icon(
                      _sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 20,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Map<String, String> _buildAdminFilterOptions() {
    final Map<String, String> options = {
      'all': 'الكل',
      'unassigned': 'غير مُعيّنين'
    };

    for (final admin in widget.admins) {
      if (admin.role == 'admin') {
        options[admin.id] = admin.name;
      }
    }

    return options;
  }

  Widget _buildDropdown(
    String label,
    String value,
    Map<String, String> items,
    Function(String?) onChanged,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor:
                isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
          ),
          items: items.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(
                entry.value,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey[50],
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            const Text(
              'لا يوجد مشرفين في النظام',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ابدأ بإضافة مشرفين لإدارة النظام',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverGridView() {
    final paginatedSupervisors = _paginatedSupervisors;

    if (paginatedSupervisors.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildNoResultsState(),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.crossAxisExtent > 1400
              ? 4
              : constraints.crossAxisExtent > 1000
                  ? 3
                  : constraints.crossAxisExtent > 600
                      ? 2
                      : 1;

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final supervisor = paginatedSupervisors[index];
                return ModernSupervisorCard(
                  supervisor: supervisor,
                  onInfoTap: () => _showSupervisorDetails(context, supervisor),
                  onReportsTap: (supervisorId, username) =>
                      _navigateToSupervisorReports(
                          context, supervisorId, username),
                  onMaintenanceTap: (supervisorId, username) =>
                      _navigateToSupervisorMaintenance(
                          context, supervisorId, username),
                  onCompletedTap: (supervisorId, username) =>
                      _navigateToSupervisorCompleted(
                          context, supervisorId, username),
                  onLateReportsTap: (supervisorId, username) =>
                      _navigateToSupervisorLateReports(
                          context, supervisorId, username),
                  onLateCompletedTap: (supervisorId, username) =>
                      _navigateToSupervisorLateCompleted(
                          context, supervisorId, username),
                  onAttendanceTap: (supervisorId, username) =>
                      _showAttendanceDialog(context, supervisorId, username),
                );
              },
              childCount: paginatedSupervisors.length,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverListView() {
    final paginatedSupervisors = _paginatedSupervisors;

    if (paginatedSupervisors.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildNoResultsState(),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final supervisor = paginatedSupervisors[index];
            return _buildSupervisorListItem(supervisor);
          },
          childCount: paginatedSupervisors.length,
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey[50],
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            const Text(
              'لا توجد نتائج مطابقة للبحث',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'جرب تغيير معايير البحث أو التصفية',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'صفحة ${_currentPage + 1} من $_totalPages',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              _buildPaginationButton(
                icon: Icons.chevron_right,
                onPressed: _currentPage > 0
                    ? () => setState(() => _currentPage--)
                    : null,
              ),
              const SizedBox(width: 8),
              ..._buildPageNumbers(),
              const SizedBox(width: 8),
              _buildPaginationButton(
                icon: Icons.chevron_left,
                onPressed: _currentPage < _totalPages - 1
                    ? () => setState(() => _currentPage++)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    final List<Widget> pageButtons = [];
    final int totalPages = _totalPages;
    final int startPage = (_currentPage - 2).clamp(0, totalPages - 1);
    final int endPage = (startPage + 4).clamp(0, totalPages - 1);

    for (int i = startPage; i <= endPage; i++) {
      pageButtons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: _buildPaginationButton(
            text: '${i + 1}',
            isSelected: i == _currentPage,
            onPressed: () => setState(() => _currentPage = i),
          ),
        ),
      );
    }

    return pageButtons;
  }

  Widget _buildPaginationButton({
    IconData? icon,
    String? text,
    bool isSelected = false,
    VoidCallback? onPressed,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF10B981)
                : onPressed == null
                    ? Colors.transparent
                    : (isDark ? const Color(0xFF334155) : Colors.white),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF10B981)
                  : (isDark
                      ? const Color(0xFF475569)
                      : const Color(0xFFE2E8F0)),
            ),
          ),
          child: Center(
            child: icon != null
                ? Icon(
                    icon,
                    size: 16,
                    color: onPressed == null
                        ? Colors.grey[400]
                        : isSelected
                            ? Colors.white
                            : (isDark
                                ? Colors.white70
                                : const Color(0xFF64748B)),
                  )
                : Text(
                    text!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: onPressed == null
                          ? Colors.grey[400]
                          : isSelected
                              ? Colors.white
                              : (isDark
                                  ? Colors.white70
                                  : const Color(0xFF64748B)),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSupervisorListItem(Map<String, dynamic> supervisor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = supervisor['stats'] as Map<String, dynamic>;
    final username = supervisor['username'] as String? ?? 'غير محدد';
    final email = supervisor['email'] as String? ?? '';
    final supervisorId = supervisor['id'] as String? ?? '';
    final adminId = supervisor['admin_id'] as String?;

    final totalReports = stats['reports'] as int? ?? 0;
    final totalMaintenance = stats['maintenance'] as int? ?? 0;
    final completedReports = stats['completed_reports'] as int? ?? 0;
    final completedMaintenance = stats['completed_maintenance'] as int? ?? 0;
    final completionRate = stats['completion_rate'] as double? ?? 0.0;
    final lateReports = stats['late_reports'] as int? ?? 0;
    final lateCompletedReports = stats['late_completed_reports'] as int? ?? 0;
    final totalWork = totalReports + totalMaintenance;
    final completedWork = completedReports + completedMaintenance;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSupervisorDetails(context, supervisor),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Left side - Avatar and Info
                Expanded(
                  child: Row(
                    children: [
                      // Compact Avatar with Status Indicator
                      Stack(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                username.isNotEmpty
                                    ? username[0].toUpperCase()
                                    : 'س',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          // Assignment Status Dot
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: adminId != null
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF59E0B),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 16),

                      // Name and Email Section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              username,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (email.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                email,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 4),
                            // Admin Assignment
                            Text(
                              adminId != null
                                  ? _getAdminName(adminId)
                                  : 'غير مُعيّن',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: adminId != null
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF59E0B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Right side - Stats, Progress, and Actions (all aligned)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Compact Stats Grid
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCompactStat(totalReports, 'بلاغات',
                            const Color(0xFF3B82F6), Icons.report_outlined),
                        const SizedBox(width: 12),
                        _buildCompactStat(totalMaintenance, 'صيانة',
                            const Color(0xFFEF4444), Icons.build_outlined),
                        const SizedBox(width: 12),
                        _buildCompactStat(
                            completedWork,
                            'مكتمل',
                            const Color(0xFF10B981),
                            Icons.check_circle_outlined),
                        if (lateReports > 0 || lateCompletedReports > 0) ...[
                          const SizedBox(width: 12),
                          _buildCompactStat(
                              lateReports + lateCompletedReports,
                              'متأخر',
                              const Color(0xFFF59E0B),
                              Icons.schedule_outlined),
                        ],
                      ],
                    ),

                    const SizedBox(width: 12),

                    // School Assignment Button
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        border: Border.all(
                          color: const Color(0xFF3B82F6).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () =>
                              _openSchoolAssignment(context, supervisor),
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.school_rounded,
                                  size: 14,
                                  color: Color(0xFF3B82F6),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'مدارس',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3B82F6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Schools Small Badge
                    GestureDetector(
                      onTap: () => _showSchoolsList(context, supervisor),
                      child: Stack(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              size: 16,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              constraints: const BoxConstraints(minWidth: 18),
                              height: 18,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(9),
                                border:
                                    Border.all(color: Colors.white, width: 1),
                              ),
                              child: Center(
                                child: Text(
                                  '${_getSchoolCount(supervisor)}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Technician Management Button
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () =>
                              _openTechnicianManagement(context, supervisor),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.build_circle,
                                  size: 14,
                                  color: Color(0xFF10B981),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_getTechnicianCount(supervisor)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 20),

                    // Completion Rate Circle
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getCompletionRateColor(completionRate * 100)
                            .withOpacity(0.1),
                        border: Border.all(
                          color: _getCompletionRateColor(completionRate * 100)
                              .withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Progress Circle
                          Positioned.fill(
                            child: CircularProgressIndicator(
                              value: completionRate,
                              strokeWidth: 3,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getCompletionRateColor(completionRate * 100),
                              ),
                            ),
                          ),
                          // Percentage Text
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${(completionRate * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: _getCompletionRateColor(
                                        completionRate * 100),
                                    height: 1,
                                  ),
                                ),
                                Text(
                                  'إنجاز',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    color: _getCompletionRateColor(
                                        completionRate * 100),
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStat(
      int value, String label, Color color, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: color.withOpacity(0.8),
            height: 1,
          ),
        ),
      ],
    );
  }

  Color _getCompletionRateColor(double rate) {
    if (rate >= 81) return const Color(0xFF10B981); // Green - Excellent
    if (rate >= 61) return const Color(0xFF3B82F6); // Blue - Good
    if (rate >= 51) return const Color(0xFFF59E0B); // Orange - Average
    return const Color(0xFFEF4444); // Red - Bad
  }

  // Navigation methods (placeholder implementations)
  void _showSupervisorDetails(
      BuildContext context, Map<String, dynamic> supervisor) {
    SupervisorDetailDialog.show(context, supervisor);
  }

  void _navigateToSupervisorReports(
      BuildContext context, String supervisorId, String username) {
    context.go(
        '/all-reports?supervisor_id=$supervisorId&supervisor_name=$username');
  }

  void _navigateToSupervisorMaintenance(
      BuildContext context, String supervisorId, String username) {
    context.go(
        '/all-maintenance?supervisor_id=$supervisorId&supervisor_name=$username');
  }

  void _navigateToSupervisorCompleted(
      BuildContext context, String supervisorId, String username) {
    context.go(
        '/all-reports?supervisor_id=$supervisorId&supervisor_name=$username&filter=completed');
  }

  void _navigateToSupervisorLateReports(
      BuildContext context, String supervisorId, String username) {
    context.go(
        '/all-reports?supervisor_id=$supervisorId&supervisor_name=$username&filter=late');
  }

  void _navigateToSupervisorLateCompleted(
      BuildContext context, String supervisorId, String username) {
    context.go(
        '/all-reports?supervisor_id=$supervisorId&supervisor_name=$username&filter=late_completed');
  }

  void _showAttendanceDialog(
      BuildContext context, String supervisorId, String username) {
    AttendanceDialog.show(context, supervisorId, username);
  }

  void _openTechnicianManagement(
      BuildContext context, Map<String, dynamic> supervisorData) {
    try {
      // Ensure we have the minimum required data
      if (supervisorData['id'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطأ: لا يمكن العثور على معرف المشرف'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final supervisor = Supervisor.fromMap(supervisorData);
      context.showEscDismissibleDialog(
        barrierDismissible: false,
        builder: (dialogContext) => BlocProvider.value(
          value: context.read<SuperAdminBloc>(),
          child: TechnicianManagementDialog(
            supervisor: supervisor,
            onSaveDetailed: (supervisorId, techniciansDetailed) {
              // Handle technician update like team management dialog using detailed format
              context
                  .read<SuperAdminBloc>()
                  .add(SupervisorTechniciansUpdatedEvent(
                    supervisorId: supervisorId,
                    techniciansDetailed:
                        techniciansDetailed.map((t) => t.toMap()).toList(),
                  ));
            },
            onTechniciansUpdated: () {
              // Force a hard page refresh by triggering the SuperAdminBloc
              try {
                final superAdminBloc = BlocManager().getSuperAdminBloc();
                superAdminBloc.add(LoadSuperAdminData(forceRefresh: true));
                print('Triggered SuperAdminBloc refresh from supervisors list');
              } catch (e) {
                print(
                    'Failed to refresh SuperAdminBloc from supervisors list: $e');
              }
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحميل بيانات المشرف: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openSchoolAssignment(
      BuildContext context, Map<String, dynamic> supervisor) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<SuperAdminBloc>(),
        child: SchoolAssignmentDialog(supervisor: supervisor),
      ),
    );
  }

  int _getTechnicianCount(Map<String, dynamic> supervisor) {
    final techniciansDetailed = supervisor['technicians_detailed'];
    if (techniciansDetailed is List) {
      try {
        // Parse the JSONB list to count valid technician objects
        return techniciansDetailed
            .where((item) =>
                item is Map<String, dynamic> &&
                (item['name']?.toString().trim().isNotEmpty ?? false))
            .length;
      } catch (e) {
        print('Error parsing technicians_detailed: $e');
        return 0;
      }
    }
    return 0;
  }

  int _getSchoolCount(Map<String, dynamic> supervisor) {
    try {
      final schoolsCount = supervisor['schools_count'] as int?;
      if (schoolsCount != null && schoolsCount > 0) {
        return schoolsCount;
      }
      final schools = supervisor['schools'] as List?;
      if (schools != null && schools.isNotEmpty) {
        return schools.length;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  void _showSchoolsList(BuildContext context, Map<String, dynamic> supervisor) {
    // Open read-only schools list with search functionality
    final supervisorId = supervisor['id'] as String? ?? '';
    final username = supervisor['username'] as String? ?? 'غير محدد';

    showDialog(
      context: context,
      builder: (dialogContext) => SchoolsListDialog(
        supervisorId: supervisorId,
        supervisorName: username,
      ),
    );
  }


}
