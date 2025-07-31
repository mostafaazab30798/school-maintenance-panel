import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/admin_management_service.dart';
import '../../../../data/models/supervisor.dart';
import '../../common/esc_dismissible_dialog.dart';

class ChangeSupervisorPasswordDialog extends StatefulWidget {
  final Supervisor supervisor;
  final VoidCallback? onPasswordChanged;

  const ChangeSupervisorPasswordDialog({
    super.key,
    required this.supervisor,
    this.onPasswordChanged,
  });

  static Future<void> show(
    BuildContext context,
    Supervisor supervisor, {
    VoidCallback? onPasswordChanged,
  }) {
    return context.showEscDismissibleDialog(
      barrierDismissible: true,
      builder: (dialogContext) => ChangeSupervisorPasswordDialog(
        supervisor: supervisor,
        onPasswordChanged: onPasswordChanged,
      ),
    );
  }

  @override
  State<ChangeSupervisorPasswordDialog> createState() => _ChangeSupervisorPasswordDialogState();
}

class _ChangeSupervisorPasswordDialogState extends State<ChangeSupervisorPasswordDialog>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  late AnimationController _animationController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.decelerate));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.decelerate));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.decelerate));

    _animationController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _slideController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: Listenable.merge([_animationController, _slideController]),
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: SlideTransition(
            position: _slideAnimation,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                width: screenSize.width > 600 ? 480 : screenSize.width * 0.9,
                constraints: BoxConstraints(
                  maxHeight: screenSize.height * 0.85,
                  minHeight: 400,
                ),
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
                              _buildSupervisorInfo(isDark),
                              const SizedBox(height: 24),
                              _buildPasswordSection(isDark),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 16),
                                _buildErrorMessage(isDark),
                              ],
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
          colors: isDark
              ? [
                  const Color(0xFF334155).withOpacity(0.3),
                  const Color(0xFF1E293B).withOpacity(0.5),
                ]
              : [
                  const Color(0xFFF8FAFC),
                  const Color(0xFFF1F5F9),
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
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.lock_rounded,
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
                  'تغيير كلمة المرور',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'قم بتحديث كلمة مرور المشرف',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupervisorInfo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? const Color(0xFF334155).withOpacity(0.3)
            : const Color(0xFFF8FAFC),
        border: Border.all(
          color: isDark
              ? const Color(0xFF475569).withOpacity(0.3)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
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
                  widget.supervisor.username,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                if (widget.supervisor.email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.supervisor.email,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'كلمة المرور الجديدة',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        _buildPasswordField(
          controller: _newPasswordController,
          label: 'كلمة المرور الجديدة',
          obscureText: _obscureNewPassword,
          onToggleObscure: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'يرجى إدخال كلمة المرور الجديدة';
            }
            if (value.length < 6) {
              return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
            }
            return null;
          },
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _buildPasswordField(
          controller: _confirmPasswordController,
          label: 'تأكيد كلمة المرور',
          obscureText: _obscureConfirmPassword,
          onToggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'يرجى تأكيد كلمة المرور';
            }
            if (value != _newPasswordController.text) {
              return 'كلمة المرور غير متطابقة';
            }
            return null;
          },
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            border: Border.all(
              color: const Color(0xFF3B82F6).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    required String? Function(String?) validator,
    required bool isDark,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : const Color(0xFF1E293B),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
        filled: true,
        fillColor: isDark
            ? const Color(0xFF334155).withOpacity(0.3)
            : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0xFF475569).withOpacity(0.3)
                : const Color(0xFFE2E8F0),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0xFF475569).withOpacity(0.3)
                : const Color(0xFFE2E8F0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF3B82F6),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 2,
          ),
        ),
        suffixIcon: IconButton(
          onPressed: onToggleObscure,
          icon: Icon(
            obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildErrorMessage(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFEF4444).withOpacity(0.1),
        border: Border.all(
          color: const Color(0xFFEF4444).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: const Color(0xFFEF4444),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF334155).withOpacity(0.3),
                  const Color(0xFF1E293B).withOpacity(0.5),
                ]
              : [
                  const Color(0xFFF8FAFC),
                  const Color(0xFFF1F5F9),
                ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildButton(
              'إلغاء',
              Icons.close_rounded,
              const Color(0xFF64748B),
              () => Navigator.of(context).pop(),
              isDark,
              isOutlined: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildButton(
              _isLoading ? 'جاري التحديث...' : 'تحديث كلمة المرور',
              _isLoading ? Icons.hourglass_empty_rounded : Icons.lock_reset_rounded,
              const Color(0xFF3B82F6),
              _isLoading ? null : _handlePasswordChange,
              isDark,
              isPrimary: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback? onPressed,
    bool isDark, {
    bool isPrimary = false,
    bool isOutlined = false,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: isPrimary
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.8)],
              )
            : null,
        color: isPrimary ? null : (isOutlined ? Colors.transparent : color.withOpacity(0.1)),
        border: isOutlined
            ? Border.all(color: color.withOpacity(0.3), width: 1.5)
            : null,
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isPrimary ? Colors.white : color,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isPrimary ? Colors.white : color,
                    fontWeight: FontWeight.w700,
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

  Future<void> _handlePasswordChange() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Debug logging
      print('🔍 DEBUG: Password change dialog - Supervisor ID: ${widget.supervisor.id}');
      print('🔍 DEBUG: Supervisor username: ${widget.supervisor.username}');
      print('🔍 DEBUG: Supervisor email: ${widget.supervisor.email}');
      
      final adminService = AdminManagementService(Supabase.instance.client);
      
      final result = await adminService.changeSupervisorPassword(
        supervisorId: widget.supervisor.id,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'تم تحديث كلمة المرور بنجاح'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        widget.onPasswordChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 