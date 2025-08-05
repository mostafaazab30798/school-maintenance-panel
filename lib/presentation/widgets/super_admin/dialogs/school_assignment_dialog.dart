import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/school_assignment_service.dart';
import '../../../../logic/blocs/super_admin/super_admin_bloc.dart';
import '../../../../logic/blocs/super_admin/super_admin_event.dart';
import '../../common/esc_dismissible_dialog.dart';

class SchoolAssignmentDialog extends StatefulWidget {
  final Map<String, dynamic> supervisor;

  const SchoolAssignmentDialog({
    super.key,
    required this.supervisor,
  });

  @override
  State<SchoolAssignmentDialog> createState() => _SchoolAssignmentDialogState();
}

class _SchoolAssignmentDialogState extends State<SchoolAssignmentDialog>
    with SingleTickerProviderStateMixin {
  final SchoolAssignmentService _schoolService =
      SchoolAssignmentService(Supabase.instance.client);
  late TabController _tabController;

  // Excel tab variables
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _selectedFileName;
  PlatformFile? _selectedFile;
  String? _errorMessage;
  String _progressMessage = '';
  double _progressValue = 0.0;

  // Manual tab variables
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _nameControllers = [];
  final List<FocusNode> _nameFocusNodes = [];
  bool _isManualLoading = false;
  String? _manualErrorMessage;
  String _manualProgressMessage = '';
  double _manualProgressValue = 0.0;

  // Tab state
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    // Start with one empty school entry for manual tab
    _addSchoolEntry();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    for (final controller in _nameControllers) {
      controller.dispose();
    }
    for (final focusNode in _nameFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    }
  }

  void _addSchoolEntry() {
    setState(() {
      _nameControllers.add(TextEditingController());
      _nameFocusNodes.add(FocusNode());
    });
  }

  void _removeSchoolEntry(int index) {
    if (_nameControllers.length > 1) {
      setState(() {
        _nameControllers[index].dispose();
        _nameFocusNodes[index].dispose();
        _nameControllers.removeAt(index);
        _nameFocusNodes.removeAt(index);
      });
    }
  }

  List<Map<String, String>> _getSchoolsData() {
    final schools = <Map<String, String>>[];
    for (int i = 0; i < _nameControllers.length; i++) {
      final name = _nameControllers[i].text.trim();
      
      if (name.isNotEmpty) {
        schools.add({
          'name': name,
          'address': '', // Empty address as requested
        });
      }
    }
    return schools;
  }

  bool _canAddSchools() {
    final schools = _getSchoolsData();
    return schools.isNotEmpty && !_isManualLoading;
  }

  Future<void> _addSchoolsManually() async {
    if (!_canAddSchools()) return;

    final schools = _getSchoolsData();
    if (schools.isEmpty) {
      setState(() {
        _manualErrorMessage = 'يرجى إدخال اسم مدرسة واحد على الأقل';
      });
      return;
    }

    setState(() {
      _isManualLoading = true;
      _manualErrorMessage = null;
      _manualProgressMessage = 'بدء العملية...';
      _manualProgressValue = 0.1;
    });

    try {
      final supervisorId = widget.supervisor['id'] as String;

      final result = await _schoolService.manuallyAddSchools(
        schools: schools,
        supervisorId: supervisorId,
        onProgress: (message) {
          if (mounted) {
            setState(() {
              _manualProgressMessage = message;
              // Update progress based on message content
              if (message.contains('إنشاء')) {
                _manualProgressValue = 0.7;
              } else if (message.contains('ربط')) {
                _manualProgressValue = 0.9;
              } else if (message.contains('إكمال')) {
                _manualProgressValue = 1.0;
              }
            });
          }
        },
      );

      if (mounted) {
        // Refresh super admin data
        context
            .read<SuperAdminBloc>()
            .add(LoadSuperAdminData(forceRefresh: true));

        // Small delay to show completion
        await Future.delayed(const Duration(milliseconds: 500));

        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم إضافة ${result['total_schools']} مدرسة للمشرف ${widget.supervisor['username']} (${result['new_schools_created']} جديدة، ${result['existing_schools_used']} موجودة)',
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _manualErrorMessage = e.toString();
        _isManualLoading = false;
        _manualProgressMessage = '';
        _manualProgressValue = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final username = widget.supervisor['username'] ?? 'غير محدد';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 800),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, username, isDark),
            _buildTabBar(isDark),
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildExcelTab(isDark),
                  _buildManualTab(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String username, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تعيين المدارس',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'للمشرف: $username',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: _buildTabCard(
              isDark: isDark,
              isSelected: _currentTabIndex == 0,
              icon: Icons.upload_file_rounded,
              title: 'رفع ملف Excel',
              subtitle: 'استيراد المدارس من ملف Excel',
              color: const Color(0xFF10B981),
              onTap: () => _tabController.animateTo(0),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildTabCard(
              isDark: isDark,
              isSelected: _currentTabIndex == 1,
              icon: Icons.add_business_rounded,
              title: 'إضافة يدوية',
              subtitle: 'إضافة المدارس يدوياً',
              color: const Color(0xFF8B5CF6),
              onTap: () => _tabController.animateTo(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabCard({
    required bool isDark,
    required bool isSelected,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.1)
              : isDark
                  ? const Color(0xFF374151)
                  : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.2)
                    : isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? color : const Color(0xFF64748B),
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? color
                    : isDark
                        ? Colors.white
                        : const Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? color.withOpacity(0.8)
                    : const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExcelTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExcelInstructionCard(isDark),
          const SizedBox(height: 20),
          _buildFileUploadSection(isDark),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildErrorMessage(_errorMessage!, isDark),
          ],
          const SizedBox(height: 20),
          _buildExcelActionButtons(context, isDark),
        ],
      ),
    );
  }

  Widget _buildManualTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildManualInstructionCard(isDark),
            const SizedBox(height: 24),
            _buildManualSchoolsList(isDark),
            if (_manualErrorMessage != null) ...[
              const SizedBox(height: 16),
              _buildManualErrorMessage(_manualErrorMessage!, isDark),
            ],
            const SizedBox(height: 24),
            _buildManualActionButtons(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildManualInstructionCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF8B5CF6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'تعليمات الإضافة اليدوية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '• أدخل اسم المدرسة في الحقل المخصص\n'
            '• يمكنك إضافة مدارس متعددة باستخدام زر "إضافة مدرسة"\n'
            '• سيتم إضافة المدارس الجديدة إلى المدارس الموجودة\n'
            '• المدارس الموجودة مسبقاً سيتم ربطها، والجديدة سيتم إنشاؤها',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualSchoolsList(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'قائمة المدارس',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _isManualLoading ? null : _addSchoolEntry,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('إضافة مدرسة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(_nameControllers.length, (index) {
          return _buildManualSchoolEntry(index, isDark);
        }),
      ],
    );
  }

  Widget _buildManualSchoolEntry(int index, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF374151) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.school,
              color: Color(0xFF8B5CF6),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: _nameControllers[index],
              focusNode: _nameFocusNodes[index],
              enabled: !_isManualLoading,
              decoration: InputDecoration(
                labelText: 'اسم المدرسة *',
                hintText: 'أدخل اسم المدرسة',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.school),
                suffixIcon: _nameControllers.length > 1
                    ? IconButton(
                        onPressed: _isManualLoading ? null : () => _removeSchoolEntry(index),
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        iconSize: 20,
                      )
                    : null,
              ),
              validator: (value) {
                if (value?.trim().isEmpty == true) {
                  return 'اسم المدرسة مطلوب';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualErrorMessage(String message, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExcelInstructionCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFF10B981),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'تعليمات رفع ملف Excel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '• يجب أن تكون أسماء المدارس في العمود الأول\n'
            '• الصف الأول يمكن أن يحتوي على عنوان (سيتم تجاهله)\n'
            '• كل صف يحتوي على اسم مدرسة واحدة\n'
            '• الخلايا الفارغة سيتم تجاهلها\n'
            '• سيتم استبدال جميع المدارس المعينة سابقاً',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileUploadSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختيار ملف Excel',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _isProcessing ? null : _pickExcelFile,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF374151) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedFile != null
                    ? const Color(0xFF10B981)
                    : isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFFD1D5DB),
                width: 2,
              ),
            ),
            child: _isProcessing
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'جاري معالجة الملف...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedFile != null
                            ? Icons.check_circle_outline
                            : Icons.upload_file_rounded,
                        size: 32,
                        color: _selectedFile != null
                            ? const Color(0xFF10B981)
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFile != null
                            ? 'تم اختيار الملف: $_selectedFileName'
                            : 'اضغط لاختيار ملف Excel',
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedFile != null
                              ? const Color(0xFF10B981)
                              : const Color(0xFF64748B),
                          fontWeight: _selectedFile != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_selectedFile == null) ...[
                        const SizedBox(height: 4),
                        const Text(
                          'xlsx, xls',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(String message, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExcelActionButtons(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text(
            'إلغاء',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _canAssignSchools() ? _assignSchools : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _progressMessage.isNotEmpty
                          ? _progressMessage
                          : 'جاري المعالجة...',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                )
              : const Text(
                  'تعيين المدارس',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildManualActionButtons(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isManualLoading ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'إلغاء',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _canAddSchools() ? _addSchoolsManually : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
          child: _isManualLoading
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _manualProgressMessage.isNotEmpty
                          ? _manualProgressMessage
                          : 'جاري المعالجة...',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                )
              : const Text(
                  'إضافة المدارس',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _pickExcelFile() async {
    try {
      setState(() {
        _errorMessage = null;
        _isProcessing = true;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        final file = result.files.single;
        setState(() {
          _selectedFile = file;
          _selectedFileName = file.name;
          _isProcessing = false;
        });
      } else {
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ في اختيار الملف: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }

  bool _canAssignSchools() {
    return _selectedFile != null && !_isLoading && !_isProcessing;
  }

  Future<void> _assignSchools() async {
    if (!_canAssignSchools() || _selectedFile?.bytes == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _progressMessage = 'بدء العملية...';
      _progressValue = 0.1;
    });

    try {
      final supervisorId = widget.supervisor['id'] as String;

      // Use the new simplified method
      final result = await _schoolService.processExcelAndAssignSchools(
        fileBytes: _selectedFile!.bytes!,
        supervisorId: supervisorId,
        onProgress: (message) {
          if (mounted) {
            setState(() {
              _progressMessage = message;
              // Update progress based on message content
              if (message.contains('إنشاء')) {
                _progressValue = 0.7;
              } else if (message.contains('ربط')) {
                _progressValue = 0.9;
              } else if (message.contains('إكمال')) {
                _progressValue = 1.0;
              }
            });
          }
        },
      );

      if (mounted) {
        // Refresh super admin data
        context
            .read<SuperAdminBloc>()
            .add(LoadSuperAdminData(forceRefresh: true));

        // Small delay to show completion
        await Future.delayed(const Duration(milliseconds: 500));

        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تعيين ${result['total_schools']} مدرسة للمشرف ${widget.supervisor['username']} (${result['new_schools_created']} جديدة، ${result['existing_schools_used']} موجودة)',
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _progressMessage = '';
        _progressValue = 0.0;
      });
    }
  }

  static void show(BuildContext context, Map<String, dynamic> supervisor) {
    context.showEscDismissibleDialog(
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<SuperAdminBloc>(),
        child: SchoolAssignmentDialog(supervisor: supervisor),
      ),
    );
  }
}
