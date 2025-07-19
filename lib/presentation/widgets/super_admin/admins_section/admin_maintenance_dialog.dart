import 'package:flutter/material.dart';

/// A modern, professional admin maintenance dialog showing supervisor-wise maintenance statistics
class AdminMaintenanceDialog extends StatefulWidget {
  final dynamic admin;
  final List<Map<String, dynamic>> adminSupervisorsWithStats;

  const AdminMaintenanceDialog({
    super.key,
    required this.admin,
    required this.adminSupervisorsWithStats,
  });

  @override
  State<AdminMaintenanceDialog> createState() => _AdminMaintenanceDialogState();
}

class _AdminMaintenanceDialogState extends State<AdminMaintenanceDialog>
    with TickerProviderStateMixin {
  String searchQuery = '';
  String sortBy = 'name'; // name, maintenance, completion
  bool sortAscending = true;

  late AnimationController _dialogController;
  late Animation<double> _dialogAnimation;

  @override
  void initState() {
    super.initState();

    _dialogController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _dialogAnimation = CurvedAnimation(
      parent: _dialogController,
      curve: Curves.easeOutBack,
    );

    _dialogController.forward();
  }

  @override
  void dispose() {
    _dialogController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final isLargeScreen = screenSize.width > 1200;
    final isMediumScreen = screenSize.width > 800;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _dialogAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _dialogAnimation.value,
            child: Container(
              width: isLargeScreen
                  ? 700
                  : (isMediumScreen ? 600 : screenSize.width * 0.9),
              height: isLargeScreen
                  ? 750
                  : (isMediumScreen ? 700 : screenSize.height * 0.85),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 80,
                    offset: const Offset(0, 40),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildModernHeader(context, isDark),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        children: [
                          if (widget.adminSupervisorsWithStats.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildSearchAndSort(context, isDark),
                            const SizedBox(height: 16),
                            Expanded(
                                child: _buildSupervisorsList(context, isDark)),
                          ] else
                            Expanded(child: _buildEmptyState(context, isDark)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEF4444),
            Color(0xFFDC2626),
            Color(0xFFB91C1C),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.build_circle_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'بلاغات الصيانة',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'المسؤول: ${widget.admin.name ?? 'غير محدد'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              onPressed: () => _closeDialog(),
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 24,
              ),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndSort(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
              ),
            ),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: 'البحث عن مشرف...',
                hintStyle: TextStyle(
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF6B7280),
                  fontSize: 14,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFFEF4444),
                    size: 18,
                  ),
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1F2937),
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: sortBy,
              onChanged: (value) => setState(() => sortBy = value!),
              items: const [
                DropdownMenuItem(value: 'name', child: Text('الاسم')),
                DropdownMenuItem(value: 'maintenance', child: Text('الصيانة')),
                DropdownMenuItem(value: 'completion', child: Text('الإنجاز')),
              ],
              icon: const Icon(Icons.sort_rounded, size: 18),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1F2937),
                fontSize: 14,
              ),
              dropdownColor: isDark ? const Color(0xFF334155) : Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
            ),
          ),
          child: IconButton(
            onPressed: () => setState(() => sortAscending = !sortAscending),
            icon: Icon(
              sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 18,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
            ),
            padding: const EdgeInsets.all(8),
          ),
        ),
      ],
    );
  }

  Widget _buildSupervisorsList(BuildContext context, bool isDark) {
    var filteredSupervisors =
        widget.adminSupervisorsWithStats.where((supervisor) {
      final username = supervisor['username']?.toString().toLowerCase() ?? '';
      final workId = supervisor['work_id']?.toString().toLowerCase() ?? '';
      final query = searchQuery.toLowerCase();
      return username.contains(query) || workId.contains(query);
    }).toList();

    // Sort supervisors
    filteredSupervisors.sort((a, b) {
      final aStats = a['stats'] as Map<String, dynamic>? ?? {};
      final bStats = b['stats'] as Map<String, dynamic>? ?? {};

      int comparison = 0;
      switch (sortBy) {
        case 'name':
          comparison = (a['username'] ?? '').compareTo(b['username'] ?? '');
          break;
        case 'maintenance':
          final aMaintenance = (aStats['maintenance'] as int? ?? 0);
          final bMaintenance = (bStats['maintenance'] as int? ?? 0);
          comparison = aMaintenance.compareTo(bMaintenance);
          break;
        case 'completion':
          final aTotal = (aStats['maintenance'] as int? ?? 0);
          final aCompleted = (aStats['completed_maintenance'] as int? ?? 0);
          final aRate = aTotal > 0 ? (aCompleted / aTotal) : 0.0;

          final bTotal = (bStats['maintenance'] as int? ?? 0);
          final bCompleted = (bStats['completed_maintenance'] as int? ?? 0);
          final bRate = bTotal > 0 ? (bCompleted / bTotal) : 0.0;

          comparison = aRate.compareTo(bRate);
          break;
      }

      return sortAscending ? comparison : -comparison;
    });

    if (filteredSupervisors.isEmpty) {
      return _buildEmptySearchState(context, isDark);
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: filteredSupervisors.length,
        itemBuilder: (context, index) {
          final supervisor = filteredSupervisors[index];
          return _buildSupervisorTile(context, supervisor, isDark);
        },
      ),
    );
  }

  Widget _buildSupervisorTile(
      BuildContext context, Map<String, dynamic> supervisor, bool isDark) {
    final stats = supervisor['stats'] as Map<String, dynamic>? ?? {};
    final username = supervisor['username'] ?? 'غير معروف';
    final totalMaintenance = stats['maintenance'] as int? ?? 0;
    final completedMaintenance = stats['completed_maintenance'] as int? ?? 0;
    final lateMaintenance = stats['late_maintenance'] as int? ?? 0;
    final lateCompletedMaintenance =
        stats['late_completed_maintenance'] as int? ?? 0;
    final urgentMaintenance = stats['urgent_maintenance'] as int? ?? 0;
    final pendingMaintenance = stats['pending_maintenance'] as int? ?? 0;

    final completionRate = totalMaintenance > 0
        ? (completedMaintenance / totalMaintenance * 100)
        : 0.0;

    final completionColor = completionRate >= 80
        ? const Color(0xFF10B981)
        : completionRate >= 60
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF475569) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF64748B) : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFEF4444),
                        Color(0xFFDC2626),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      username[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildMiniStat('الصيانة', totalMaintenance.toString(),
                              const Color(0xFFEF4444)),
                          const SizedBox(width: 16),
                          _buildMiniStat(
                              'مكتملة',
                              completedMaintenance.toString(),
                              const Color(0xFF10B981)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Completion Rate
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: completionColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: completionColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: completionColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${completionRate.toInt()}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: completionColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Status Dots Section
            if (totalMaintenance > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'تفاصيل الحالة',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                        Text(
                          'المجموع: ${totalMaintenance}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        // Completed Maintenance
                        if (completedMaintenance > 0)
                          _buildStatusDot(
                            'صيانة مكتملة',
                            completedMaintenance,
                            const Color(0xFF10B981),
                            Icons.check_circle,
                          ),

                        // Urgent Maintenance
                        if (urgentMaintenance > 0)
                          _buildStatusDot(
                            'صيانة عاجلة',
                            urgentMaintenance,
                            const Color(0xFFDC2626),
                            Icons.priority_high,
                          ),

                        // Late Maintenance
                        if (lateMaintenance > 0)
                          _buildStatusDot(
                            'صيانة متأخرة',
                            lateMaintenance,
                            const Color(0xFFEF4444),
                            Icons.schedule,
                          ),

                        // Late Completed Maintenance
                        if (lateCompletedMaintenance > 0)
                          _buildStatusDot(
                            'صيانة متأخرة مكتملة',
                            lateCompletedMaintenance,
                            const Color(0xFFF59E0B),
                            Icons.warning,
                          ),

                        // Pending Maintenance
                        if (pendingMaintenance > 0)
                          _buildStatusDot(
                            'صيانة معلقة',
                            pendingMaintenance,
                            const Color(0xFF6B7280),
                            Icons.pending,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $value',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDot(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.build_circle_outlined,
              size: 40,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'لا يوجد مشرفين مُعيّنين',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'قم بتعيين مشرفين لهذا المسؤول لعرض بلاغات الصيانة',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF6B7280).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 30,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد نتائج للبحث',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جرب البحث بكلمات مختلفة',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  void _closeDialog() {
    _dialogController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }
}
