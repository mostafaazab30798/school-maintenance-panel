import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../logic/blocs/super_admin/super_admin_bloc.dart';
import '../../../../logic/blocs/super_admin/super_admin_state.dart';
import '../../../../logic/blocs/super_admin/super_admin_event.dart';
import '../../../../data/models/supervisor.dart';
import '../../../../data/models/technician.dart';
import '../../../../core/services/cache_service.dart';

class TechnicianManagementDialog extends StatefulWidget {
  final Supervisor supervisor;
  final Function(String supervisorId, List<String> technicians)? onSave;
  final Function(String supervisorId, List<Technician> techniciansDetailed)?
      onSaveDetailed;
  final VoidCallback? onTechniciansUpdated;
  final bool isReadOnly;

  const TechnicianManagementDialog({
    super.key,
    required this.supervisor,
    this.onSave,
    this.onSaveDetailed,
    this.onTechniciansUpdated,
    this.isReadOnly = false,
  });

  @override
  State<TechnicianManagementDialog> createState() =>
      _TechnicianManagementDialogState();
}

class _TechnicianManagementDialogState
    extends State<TechnicianManagementDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _workIdController = TextEditingController();
  final TextEditingController _professionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late List<Technician> _technicians;
  late List<Technician> _originalTechnicians;
  bool _isSaving = false;
  int? _editingIndex;

  @override
  void initState() {
    super.initState();

    // Initialize with detailed technicians or convert from simple format
    _technicians = widget.supervisor.techniciansDetailed.isNotEmpty
        ? List.from(widget.supervisor.techniciansDetailed)
        : widget.supervisor.technicians
            .map((name) => Technician(name: name, workId: '', profession: ''))
            .toList();

    _originalTechnicians = List.from(_technicians);

    print('=== TECHNICIAN DIALOG INITIALIZED ===');
    print('Supervisor: ${widget.supervisor.username}');
    print('Supervisor ID: ${widget.supervisor.id}');
    print('TechniciansDetailed: ${widget.supervisor.techniciansDetailed}');
    print(
        'TechniciansDetailed count: ${widget.supervisor.techniciansDetailed.length}');
    print('Legacy technicians: ${widget.supervisor.technicians}');
    print('Legacy technicians count: ${widget.supervisor.technicians.length}');
    print('Final _technicians count: ${_technicians.length}');
    print('Final _technicians: ${_technicians.map((t) => t.toMap()).toList()}');
    print('Original _technicians count: ${_originalTechnicians.length}');
    print('Original _technicians: ${_originalTechnicians.map((t) => t.toMap()).toList()}');
    print('Initial hasChanges: ${hasChanges}');
    print('=====================================');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _workIdController.dispose();
    _professionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get hasChanges {
    print('🔍 Checking for changes...');
    print('Current technicians count: ${_technicians.length}');
    print('Original technicians count: ${_originalTechnicians.length}');
    
    if (_technicians.length != _originalTechnicians.length) {
      print('🔍 Length mismatch detected - has changes');
      return true;
    }

    for (int i = 0; i < _technicians.length; i++) {
      final current = _technicians[i];
      // Use index-based comparison instead of name-based to handle name changes
      final original = i < _originalTechnicians.length 
          ? _originalTechnicians[i] 
          : Technician(name: '', workId: '', profession: '');

      print('🔍 Comparing index $i:');
      print('  Current: ${current.name} | ${current.workId} | ${current.profession} | ${current.phoneNumber}');
      print('  Original: ${original.name} | ${original.workId} | ${original.profession} | ${original.phoneNumber}');

      if (current.name != original.name ||
          current.workId != original.workId ||
          current.profession != original.profession ||
          current.phoneNumber != original.phoneNumber) {
        print('🔍 Changes detected at index $i');
        return true;
      }
    }
    
    print('🔍 No changes detected');
    return false;
  }

  bool get _isEditing => _editingIndex != null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          border: Border.all(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.engineering,
                    color: isDark ? Colors.white : const Color(0xFF6B7280),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.isReadOnly ? 'عرض الفنيين' : 'إدارة الفنيين'} - ${widget.supervisor.username}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_technicians.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Add/Edit Form - Only show if not read-only
                  if (!widget.isReadOnly) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: _buildForm(isDark),
                    ),
                    // Divider
                    Divider(
                      height: 1,
                      color: isDark
                          ? const Color(0xFF374151)
                          : const Color(0xFFE5E7EB),
                    ),
                  ],

                  // Technicians List
                  Flexible(
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: widget.isReadOnly ? 400 : 300,
                        minHeight: 200,
                      ),
                      child: _technicians.isEmpty
                          ? _buildEmptyState(isDark)
                          : ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: _technicians.length,
                              itemBuilder: (context, index) {
                                final technician = _technicians[index];
                                final isEditing = !widget.isReadOnly &&
                                    _editingIndex == index;
                                return _buildTechnicianTile(
                                    technician, index, isEditing, isDark);
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
              ),
              child: widget.isReadOnly
                  ? Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'إغلاق',
                          style: TextStyle(
                            color:
                                isDark ? Colors.white : const Color(0xFF374151),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              'إلغاء',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white.withOpacity(0.7)
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: hasChanges && !_isSaving
                                ? _saveTechnicians
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hasChanges
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF9CA3AF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('حفظ'),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mode indicator
          if (_isEditing)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit, size: 14, color: Color(0xFF8B5CF6)),
                  const SizedBox(width: 4),
                  const Text(
                    'تعديل الفني',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8B5CF6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _cancelEdit,
                    child: const Icon(Icons.close,
                        size: 14, color: Color(0xFF8B5CF6)),
                  ),
                ],
              ),
            ),

          // Form fields - First row
          Row(
            children: [
              // Name field
              Expanded(
                flex: 3,
                child: _buildTextField(
                  controller: _nameController,
                  hint: 'اسم الفني',
                  isDark: isDark,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'مطلوب';
                    }
                    final existingNames = _technicians
                        .asMap()
                        .entries
                        .where((entry) =>
                            _editingIndex == null || entry.key != _editingIndex)
                        .map((entry) => entry.value.name)
                        .toList();
                    if (existingNames.contains(value.trim())) {
                      return 'موجود';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Work ID field
              Expanded(
                flex: 2,
                child: _buildTextField(
                  controller: _workIdController,
                  hint: 'رقم العمل',
                  isDark: isDark,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final existingWorkIds = _technicians
                          .asMap()
                          .entries
                          .where((entry) =>
                              _editingIndex == null ||
                              entry.key != _editingIndex)
                          .map((entry) => entry.value.workId)
                          .where((id) => id.isNotEmpty)
                          .toList();
                      if (existingWorkIds.contains(value.trim())) {
                        return 'مكرر';
                      }
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Form fields - Second row
          Row(
            children: [
              // Profession field
              Expanded(
                flex: 2,
                child: _buildTextField(
                  controller: _professionController,
                  hint: 'التخصص',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),

              // Phone field (optional)
              Expanded(
                flex: 2,
                child: _buildTextField(
                  controller: _phoneController,
                  hint: 'رقم الهاتف (اختياري)',
                  isDark: isDark,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      // Basic phone validation - Saudi format
                      final phoneRegex = RegExp(r'^[0-9+\-\s()]{10,15}$');
                      if (!phoneRegex.hasMatch(value.trim())) {
                        return 'رقم غير صحيح';
                      }
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Action button
              SizedBox(
                width: 40,
                height: 36,
                child: ElevatedButton(
                  onPressed: _isEditing ? _updateTechnician : _addTechnician,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEditing
                        ? const Color(0xFF8B5CF6)
                        : const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Icon(
                    _isEditing ? Icons.check : Icons.add,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF111827),
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color:
              isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF9CA3AF),
          fontSize: 14,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF374151) : const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        isDense: true,
      ),
    );
  }

  Widget _buildTechnicianTile(
      Technician technician, int index, bool isEditing, bool isDark) {
    final professionArabic =
        Technician.professionTranslations[technician.profession] ??
            (technician.profession.isNotEmpty ? technician.profession : 'عام');

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isEditing
            ? (isDark
                ? const Color(0xFF8B5CF6).withOpacity(0.1)
                : const Color(0xFF8B5CF6).withOpacity(0.05))
            : (isDark
                ? const Color(0xFF374151).withOpacity(0.5)
                : const Color(0xFFF9FAFB)),
        borderRadius: BorderRadius.circular(6),
        border: isEditing
            ? Border.all(color: const Color(0xFF8B5CF6), width: 1)
            : null,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color:
                  isEditing ? const Color(0xFF8B5CF6) : const Color(0xFF8B5CF6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                technician.name.isNotEmpty
                    ? technician.name[0].toUpperCase()
                    : 'ف',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        technician.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color:
                              isDark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                    ),
                    if (technician.workId.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          technician.workId,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF8B5CF6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        professionArabic,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white.withOpacity(0.6)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    if (technician.phoneNumber.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.phone,
                            size: 10,
                            color: isDark
                                ? Colors.white.withOpacity(0.5)
                                : const Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            technician.phoneNumber,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? Colors.white.withOpacity(0.5)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Actions - Only show if not read-only
          if (!widget.isReadOnly)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _startEdit(technician, index),
                  icon: Icon(
                    Icons.edit,
                    size: 16,
                    color: isEditing
                        ? const Color(0xFF8B5CF6)
                        : (isDark
                            ? Colors.white.withOpacity(0.6)
                            : const Color(0xFF6B7280)),
                  ),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
                IconButton(
                  onPressed: () => _removeTechnician(technician, index),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Color(0xFFEF4444),
                  ),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.engineering_outlined,
            size: 32,
            color: isDark
                ? Colors.white.withOpacity(0.4)
                : const Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isReadOnly ? 'لا يوجد فنيون مسجلون' : 'لا يوجد فنيون',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? Colors.white.withOpacity(0.6)
                  : const Color(0xFF6B7280),
            ),
          ),
          if (widget.isReadOnly) ...[
            const SizedBox(height: 4),
            Text(
              'لم يتم تعيين أي فنيين لهذا المشرف',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? Colors.white.withOpacity(0.4)
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _addTechnician() {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text.trim();
      final workId = _workIdController.text.trim();
      final profession = _professionController.text.trim();
      final phoneNumber = _phoneController.text.trim();

      final technician = Technician(
        name: name,
        workId: workId,
        profession: profession,
        phoneNumber: phoneNumber,
      );

      print('➕ Adding new technician: ${technician.name}');

      setState(() {
        _technicians.add(technician);
        _clearForm();
      });

      print('✅ Added technician: ${technician.name}. Total: ${_technicians.length}');
      print('🔍 Has changes after add: ${hasChanges}');
    }
  }

  void _startEdit(Technician technician, int index) {
    setState(() {
      _nameController.text = technician.name;
      _workIdController.text = technician.workId;
      _professionController.text = technician.profession;
      _phoneController.text = technician.phoneNumber;
      _editingIndex = index;
    });

    print('Started editing technician: ${technician.name} at index $index');
  }

  void _updateTechnician() {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text.trim();
      final workId = _workIdController.text.trim();
      final profession = _professionController.text.trim();
      final phoneNumber = _phoneController.text.trim();

      final updatedTechnician = Technician(
        name: name,
        workId: workId,
        profession: profession,
        phoneNumber: phoneNumber,
      );

      print('🔄 Updating technician at index $_editingIndex:');
      print('  Old: ${_technicians[_editingIndex!].name} | ${_technicians[_editingIndex!].workId} | ${_technicians[_editingIndex!].profession} | ${_technicians[_editingIndex!].phoneNumber}');
      print('  New: ${updatedTechnician.name} | ${updatedTechnician.workId} | ${updatedTechnician.profession} | ${updatedTechnician.phoneNumber}');

      setState(() {
        _technicians[_editingIndex!] = updatedTechnician;
        _cancelEdit();
      });

      print('✅ Updated technician at index $_editingIndex: ${updatedTechnician.name}');
      print('🔍 Has changes after update: ${hasChanges}');
    }
  }

  void _cancelEdit() {
    setState(() {
      _clearForm();
      _editingIndex = null;
    });
  }

  void _clearForm() {
    _nameController.clear();
    _workIdController.clear();
    _professionController.clear();
    _phoneController.clear();
  }

  void _removeTechnician(Technician technician, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف الفني "${technician.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              // 🚀 CRITICAL FIX: Use EXACT same pattern as team management
              // Remove from local list but don't save until user clicks Save button
              setState(() {
                _technicians.removeAt(index);
                if (_editingIndex == index) {
                  _cancelEdit();
                } else if (_editingIndex != null && _editingIndex! > index) {
                  _editingIndex = _editingIndex! - 1;
                }
              });
              Navigator.of(context).pop();

              print(
                  'Marked technician for removal: ${technician.name}. Total: ${_technicians.length}');
              print('Changes will be saved when user clicks Save button');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTechnicians() async {
    setState(() {
      _isSaving = true;
    });

    try {
      print('🔥 DIALOG: Saving ${_technicians.length} technicians...');
      print('🔥 DIALOG: Supervisor ID: ${widget.supervisor.id}');
      print(
          '🔥 DIALOG: Technician names: ${_technicians.map((t) => t.name).toList()}');

      // 🚀 Use the EXACT same pattern as team management dialog
      // Call the save callback (which triggers SuperAdminBloc event)
      if (widget.onSaveDetailed != null) {
        print('🔥 DIALOG: Calling onSaveDetailed callback...');
        widget.onSaveDetailed!(widget.supervisor.id, _technicians);
        print('🔥 DIALOG: onSaveDetailed callback completed');
      } else if (widget.onSave != null) {
        print('🔥 DIALOG: Calling onSave callback...');
        // Fallback to simple format
        final simpleNames = _technicians.map((t) => t.name).toList();
        widget.onSave!(widget.supervisor.id, simpleNames);
        print('🔥 DIALOG: onSave callback completed');
      } else {
        print('🔥 DIALOG: ERROR - No save callback available!');
      }

      // 🚀 Wait for bloc state update - EXACT same pattern as team management
      final bloc = context.read<SuperAdminBloc>();
      await bloc.stream.firstWhere((state) => state is SuperAdminLoaded);

      // 🚀 Close dialog immediately after state update - like team management
      if (mounted) {
        Navigator.of(context).pop();

        // Show success message after dialog closes
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'تم تحديث قائمة الفنيين بنجاح (${_technicians.length} فني)'),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );

            widget.onTechniciansUpdated?.call();
          }
        });
      }
    } catch (e) {
      print('Error saving technicians: $e');

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحفظ: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}
