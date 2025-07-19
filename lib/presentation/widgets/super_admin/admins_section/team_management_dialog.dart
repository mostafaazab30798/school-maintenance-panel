import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../logic/blocs/super_admin/super_admin_bloc.dart';
import '../../../../logic/blocs/super_admin/super_admin_event.dart';
import '../../../../logic/blocs/super_admin/super_admin_state.dart';

/// A modern, professional team management dialog for admin-supervisor assignment
class TeamManagementDialog extends StatefulWidget {
  final dynamic admin;
  final List<Map<String, dynamic>> allSupervisors;
  final Function(List<String>)? onSave;

  const TeamManagementDialog({
    super.key,
    required this.admin,
    required this.allSupervisors,
    this.onSave,
  });

  @override
  State<TeamManagementDialog> createState() => _TeamManagementDialogState();
}

class _TeamManagementDialogState extends State<TeamManagementDialog>
    with TickerProviderStateMixin {
  String searchQuery = '';
  Set<String> selectedSupervisors = {};
  Set<String> originallyAssigned = {};
  bool _isLoading = false;
  bool _isUpdatingUI = false;

  late AnimationController _dialogController;
  late AnimationController _loadingController;
  late Animation<double> _dialogAnimation;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _dialogController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _dialogAnimation = CurvedAnimation(
      parent: _dialogController,
      curve: Curves.easeOutBack,
    );
    _loadingAnimation = CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOut,
    );

    // Pre-select currently assigned supervisors
    selectedSupervisors = widget.allSupervisors
        .where((s) => s['admin_id'] == widget.admin.id)
        .map((s) => s['id'].toString())
        .toSet();
    originallyAssigned = Set.from(selectedSupervisors);

    // Start dialog animation
    _dialogController.forward();
  }

  @override
  void dispose() {
    _dialogController.dispose();
    _loadingController.dispose();
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
                  ? 550
                  : (isMediumScreen ? 500 : screenSize.width * 0.9),
              height: isLargeScreen
                  ? 650
                  : (isMediumScreen ? 600 : screenSize.height * 0.85),
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
              child: Stack(
                children: [
                  // Main content
                  Column(
                    children: [
                      _buildModernHeader(context, isDark),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: Column(
                            children: [
                              const SizedBox(height: 8),
                              _buildModernSearchBar(context, isDark),
                              const SizedBox(height: 16),
                              Expanded(
                                  child: _buildModernSupervisorsList(
                                      context, isDark)),
                              const SizedBox(height: 16),
                              _buildModernActionButtons(context, isDark),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Loading overlay with modern design
                  if (_isLoading || _isUpdatingUI)
                    AnimatedBuilder(
                      animation: _loadingAnimation,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.black : Colors.white)
                                .withOpacity(0.8),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF10B981),
                                          Color(0xFF059669)
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _isUpdatingUI
                                        ? 'جاري تحديث البيانات...'
                                        : 'جاري الحفظ...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _isUpdatingUI
                                        ? 'يرجى الانتظار حتى اكتمال التحديث'
                                        : 'يتم حفظ التغييرات الآن',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF6B7280),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
            Color(0xFF10B981),
            Color(0xFF059669),
            Color(0xFF047857),
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
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.people_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إدارة فريق العمل',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
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

  Widget _buildStatsCards(BuildContext context, bool isDark) {
    // Calculate available supervisors (excluding those assigned to other admins)
    final availableSupervisors = widget.allSupervisors.where((supervisor) {
      final adminId = supervisor['admin_id'];
      return adminId == null || adminId == widget.admin.id;
    }).toList();
    
    final totalSupervisors = availableSupervisors.length;
    final currentlyAssigned = originallyAssigned.length;
    final selectedCount = selectedSupervisors.length;
    final changes = (selectedSupervisors.difference(originallyAssigned).length +
        originallyAssigned.difference(selectedSupervisors).length);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'إجمالي المشرفين',
            totalSupervisors.toString(),
            Icons.people_outline,
            const Color(0xFF3B82F6),
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'المُعيّنين حالياً',
            currentlyAssigned.toString(),
            Icons.person_add,
            const Color(0xFF10B981),
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'المحددين',
            selectedCount.toString(),
            Icons.check_circle_outline,
            const Color(0xFF8B5CF6),
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'التغييرات',
            changes.toString(),
            Icons.sync_alt,
            changes > 0 ? const Color(0xFFF59E0B) : const Color(0xFF6B7280),
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModernSearchBar(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
        ),
      ),
      child: TextField(
        onChanged: (value) => setState(() => searchQuery = value),
        decoration: InputDecoration(
          hintText: 'البحث عن مشرف بالاسم أو اسم المستخدم...',
          hintStyle: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
            fontSize: 16,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.search_rounded,
              color: Color(0xFF10B981),
              size: 20,
            ),
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () => setState(() => searchQuery = ''),
                  icon: Icon(
                    Icons.clear_rounded,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF6B7280),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF1F2937),
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildModernSupervisorsList(BuildContext context, bool isDark) {
    final filteredSupervisors = widget.allSupervisors.where((supervisor) {
      // First, filter out supervisors assigned to other admins
      final adminId = supervisor['admin_id'];
      if (adminId != null && adminId != widget.admin.id) {
        return false; // Exclude supervisors assigned to other admins
      }
      
      // Then apply search filter
      final username = supervisor['username']?.toString().toLowerCase() ?? '';
      final fullName = supervisor['full_name']?.toString().toLowerCase() ?? '';
      final workId = supervisor['work_id']?.toString().toLowerCase() ?? '';
      final query = searchQuery.toLowerCase();
      return username.contains(query) || 
             fullName.contains(query) || 
             workId.contains(query);
    }).toList();

    if (filteredSupervisors.isEmpty) {
      return _buildEmptyState(context, isDark);
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
          return _buildModernSupervisorTile(context, supervisor, isDark);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF6B7280).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 40,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              searchQuery.isEmpty ? 'لا يوجد مشرفين متاحين' : 'لا توجد نتائج للبحث',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searchQuery.isEmpty
                  ? 'جميع المشرفين مُعيّنين لمسؤولين آخرين أو لا يوجد مشرفين في النظام'
                  : 'جرب البحث بكلمات مختلفة',
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSupervisorTile(
      BuildContext context, Map<String, dynamic> supervisor, bool isDark) {
    final supervisorId = supervisor['id'].toString();
    final isSelected = selectedSupervisors.contains(supervisorId);
    final isCurrentlyAssigned = originallyAssigned.contains(supervisorId);
    final username = supervisor['username'] ?? 'غير محدد';
    final fullName = supervisor['full_name'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF10B981).withOpacity(0.1)
            : isDark
                ? const Color(0xFF475569)
                : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF10B981)
              : isDark
                  ? const Color(0xFF64748B)
                  : const Color(0xFFE5E7EB),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedSupervisors.remove(supervisorId);
              } else {
                selectedSupervisors.add(supervisorId);
              }
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isSelected
                          ? [const Color(0xFF10B981), const Color(0xFF059669)]
                          : [const Color(0xFF6B7280), const Color(0xFF4B5563)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      username[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

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
                      if (fullName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          fullName,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                      if (isCurrentlyAssigned) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'مُعيّن حالياً',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Checkbox
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF10B981)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF10B981)
                          : isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFFD1D5DB),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernActionButtons(BuildContext context, bool isDark) {
    final hasChanges =
        !selectedSupervisors.difference(originallyAssigned).isEmpty ||
            !originallyAssigned.difference(selectedSupervisors).isEmpty;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF475569) : const Color(0xFFE5E7EB),
              ),
            ),
            child: TextButton(
              onPressed: () => _closeDialog(),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'إلغاء',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF6B7280),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: hasChanges
                  ? const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    )
                  : null,
              color: hasChanges
                  ? null
                  : (isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFF3F4F6)),
              borderRadius: BorderRadius.circular(16),
              boxShadow: hasChanges
                  ? [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: ElevatedButton(
              onPressed: hasChanges && !_isLoading ? _saveAssignments : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                hasChanges ? 'حفظ التغييرات' : 'لا توجد تغييرات',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: hasChanges
                      ? Colors.white
                      : (isDark
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF9CA3AF)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveAssignments() async {
    setState(() {
      _isLoading = true;
    });
    _loadingController.forward();

    try {
      // Call the save callback
      widget.onSave?.call(selectedSupervisors.toList());

      // Listen for bloc state changes to know when the update is complete
      final bloc = context.read<SuperAdminBloc>();

      // Wait for the next state emission (which should be the updated state)
      await bloc.stream.firstWhere((state) => state is SuperAdminLoaded);

      // Close dialog immediately after state update
      if (mounted) {
        _closeDialog();

        // Show success message after dialog closes
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'تم تحديث تعيين المشرفين بنجاح',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUpdatingUI = false;
        });
        _loadingController.reverse();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'خطأ في الحفظ: $e',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _closeDialog() {
    _dialogController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }
}
