import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/supervisor.dart';
import '../../../../logic/blocs/supervisors/supervisor_bloc.dart';
import '../../../../logic/blocs/supervisors/supervisor_event.dart';
import '../../../../logic/blocs/supervisors/supervisor_state.dart';
import '../../common/esc_dismissible_dialog.dart';
import '../../saudi_plate.dart';

class EditSupervisorDialog extends StatefulWidget {
  final Supervisor supervisor;

  const EditSupervisorDialog({
    super.key,
    required this.supervisor,
  });

  @override
  State<EditSupervisorDialog> createState() => _EditSupervisorDialogState();
}

class _EditSupervisorDialogState extends State<EditSupervisorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _iqamaIdController = TextEditingController();
  final _plateNumbersController = TextEditingController();
  final _plateEnglishLettersController = TextEditingController();
  final _plateArabicLettersController = TextEditingController();
  final _workIdController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _usernameController.text = widget.supervisor.username;
    _emailController.text = widget.supervisor.email;
    _phoneController.text = widget.supervisor.phone;
    _iqamaIdController.text = widget.supervisor.iqamaId;
    _plateNumbersController.text = widget.supervisor.plateNumbers;
    _plateEnglishLettersController.text = widget.supervisor.plateEnglishLetters;
    _plateArabicLettersController.text = widget.supervisor.plateArabicLetters;
    _workIdController.text = widget.supervisor.workId;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _iqamaIdController.dispose();
    _plateNumbersController.dispose();
    _plateEnglishLettersController.dispose();
    _plateArabicLettersController.dispose();
    _workIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<SupervisorBloc, SupervisorState>(
      listener: (context, state) {
        if (state is SupervisorError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is SupervisorLoaded) {
          // Success - close dialog
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تحديث بيانات المشرف بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 700),
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
              _buildHeader(context, isDark),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPersonalInfoSection(isDark),
                        const SizedBox(height: 20),
                        _buildLicensePlateSection(isDark),
                        const SizedBox(height: 20),
                        _buildWorkInfoSection(isDark),
                      ],
                    ),
                  ),
                ),
              ),
              _buildActionButtons(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3B82F6),
            const Color(0xFF1E40AF),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.edit_outlined,
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
                  'تعديل بيانات المشرف',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.supervisor.username,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('المعلومات الشخصية', Icons.person_outline, isDark),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'اسم المشرف',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) => value?.trim().isEmpty == true ? 'مطلوب' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
                validator: (value) => value?.trim().isEmpty == true ? 'مطلوب' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _iqamaIdController,
                decoration: InputDecoration(
                  labelText: 'رقم الهوية/الإقامة',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.credit_card),
                ),
                validator: (value) => value?.trim().isEmpty == true ? 'مطلوب' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? Colors.white24 : Colors.grey[300]!,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.email,
                      color: isDark ? Colors.white54 : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'البريد الإلكتروني',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _emailController.text,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'غير قابل للتعديل',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLicensePlateSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('رقم اللوحة', Icons.directions_car, isDark),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _plateNumbersController,
                decoration: InputDecoration(
                  labelText: 'الأرقام',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.numbers),
                ),
                validator: (value) => value?.trim().isEmpty == true ? 'مطلوب' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _plateEnglishLettersController,
                decoration: InputDecoration(
                  labelText: 'الحروف الإنجليزية',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.text_fields),
                ),
                validator: (value) => value?.trim().isEmpty == true ? 'مطلوب' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _plateArabicLettersController,
                decoration: InputDecoration(
                  labelText: 'الحروف العربية',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.text_fields),
                ),
                validator: (value) => value?.trim().isEmpty == true ? 'مطلوب' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Preview the license plate
        if (_plateNumbersController.text.isNotEmpty ||
            _plateEnglishLettersController.text.isNotEmpty ||
            _plateArabicLettersController.text.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'معاينة اللوحة:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    height: 60,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SaudiLicensePlate(
                        englishNumbers: _plateNumbersController.text.isEmpty
                            ? '0000'
                            : _plateNumbersController.text,
                        arabicLetters: _plateArabicLettersController.text.isEmpty
                            ? 'غ غ غ'
                            : _plateArabicLettersController.text,
                        englishLetters: _plateEnglishLettersController.text.isEmpty
                            ? 'AAA'
                            : _plateEnglishLettersController.text,
                        isHorizontal: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildWorkInfoSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('معلومات العمل', Icons.work_outline, isDark),
        const SizedBox(height: 12),
        TextFormField(
          controller: _workIdController,
          decoration: InputDecoration(
            labelText: 'رقم العمل',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.badge),
          ),
          validator: (value) => value?.trim().isEmpty == true ? 'مطلوب' : null,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF8B5CF6),
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(
                  color: isDark ? Colors.white30 : Colors.grey[400]!,
                ),
              ),
              child: const Text('إلغاء'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: BlocBuilder<SupervisorBloc, SupervisorState>(
              builder: (context, state) {
                final isLoading = state is SupervisorUpdating && 
                    state.supervisorId == widget.supervisor.id;
                
                return ElevatedButton(
                  onPressed: isLoading ? null : _saveSupervisor,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('حفظ التغييرات'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _saveSupervisor() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<SupervisorBloc>().add(SupervisorUpdated(
        id: widget.supervisor.id,
        username: _usernameController.text.trim(),
        email: widget.supervisor.email, // Keep original email unchanged
        phone: _phoneController.text.trim(),
        iqamaId: _iqamaIdController.text.trim(),
        plateNumbers: _plateNumbersController.text.trim(),
        plateEnglishLetters: _plateEnglishLettersController.text.trim(),
        plateArabicLetters: _plateArabicLettersController.text.trim(),
        workId: _workIdController.text.trim(),
      ));
    }
  }

  static void show(BuildContext context, Supervisor supervisor) {
    context.showEscDismissibleDialog(
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<SupervisorBloc>(),
        child: EditSupervisorDialog(supervisor: supervisor),
      ),
    );
  }
} 