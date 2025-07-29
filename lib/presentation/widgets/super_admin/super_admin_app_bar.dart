import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../logic/cubits/theme_cubit.dart';
import '../../../logic/blocs/super_admin/super_admin_bloc.dart';
import '../../../logic/blocs/super_admin/super_admin_event.dart';
import '../../../core/services/excel_export_service.dart';
import '../../../data/repositories/maintenance_count_repository.dart';
import '../../../data/repositories/damage_count_repository.dart';
import '../../../data/repositories/supervisor_repository.dart';
import '../common/weekly_report_dialog.dart';
import '../common/user_info_widget.dart';
import '../common/shared_back_button.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/utils/maintenance_counts_test.dart';

class SuperAdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onCreateAdmin;
  final bool showBackButton;

  const SuperAdminAppBar({
    super.key,
    this.onCreateAdmin,
    this.showBackButton = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? SharedBackButton(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF1E293B),
              forceShow: true,
            )
          : null,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [
                    const Color(0xFF0F172A).withOpacity(0.95),
                    const Color(0xFF0F172A).withOpacity(0.8),
                  ]
                : [
                    Colors.white.withOpacity(0.95),
                    Colors.white.withOpacity(0.8),
                  ],
          ),
        ),
      ),
      title: Row(
        children: [
          Text(
            'لوحة تحكم المدير العام',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
          ),
          const SizedBox(width: 16),
          const UserInfoWidget(),
        ],
      ),
      actions: [
        // Download Maintenance Counts button
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFFF59E0B).withOpacity(0.1),
            border: Border.all(
              color: const Color(0xFFF59E0B).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.build_outlined,
              color: Color(0xFFF59E0B),
            ),
            tooltip: 'تحميل حصر الصيانة',
            onPressed: () => _downloadMaintenanceCounts(context),
          ),
        ),
        // Download Damage Counts button
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFFEF4444).withOpacity(0.1),
            border: Border.all(
              color: const Color(0xFFEF4444).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.warning_outlined,
              color: Color(0xFFEF4444),
            ),
            tooltip: 'تحميل حصر التوالف',
            onPressed: () => _downloadDamageCounts(context),
          ),
        ),
        // Weekly Report button
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFF10B981).withOpacity(0.1),
            border: Border.all(
              color: const Color(0xFF10B981).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.assessment_outlined,
              color: Color(0xFF10B981),
            ),
            tooltip: 'تقرير أسبوعي/شهري',
            onPressed: () => _showWeeklyReportDialog(context),
          ),
        ),
        // Theme toggle button
        BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            final isDark = themeMode == ThemeMode.dark;
            return Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF6B46C1).withOpacity(0.1),
                border: Border.all(
                  color: const Color(0xFF6B46C1).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: const Color(0xFF6B46C1),
                ),
                tooltip: isDark ? 'الوضع المضيء' : 'الوضع المظلم',
                onPressed: () {
                  context.read<ThemeCubit>().toggleTheme();
                },
              ),
            );
          },
        ),
        // Refresh button
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            border: Border.all(
              color: const Color(0xFF3B82F6).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF3B82F6),
            ),
            tooltip: 'تحديث البيانات',
            onPressed: () => _refreshData(context),
          ),
        ),
        if (onCreateAdmin != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: _buildAddAdminButton(context),
          ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444).withOpacity(0.1),
              foregroundColor: const Color(0xFFEF4444),
            ),
            tooltip: 'تسجيل الخروج',
          ),
        ),
      ],
    );
  }

  Widget _buildAddAdminButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3B82F6),
            const Color(0xFF3B82F6),
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onCreateAdmin,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_add_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'إضافة مسؤول',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _refreshData(BuildContext context) {
    // Trigger refresh of super admin data
    context.read<SuperAdminBloc>().add(LoadSuperAdminData(forceRefresh: true));

    // Show a brief feedback message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جاري تحديث البيانات...'),
        backgroundColor: Color(0xFF3B82F6),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => RawKeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        autofocus: true,
        onKey: (RawKeyEvent event) {
          if (event is RawKeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(ctx).pop();
          }
        },
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [
                        const Color(0xFF1E293B).withOpacity(0.95),
                        const Color(0xFF0F172A).withOpacity(0.95),
                      ]
                    : [
                        Colors.white.withOpacity(0.95),
                        const Color(0xFFF8FAFC).withOpacity(0.95),
                      ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
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
                // Modern logout icon with enhanced styling
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFEF4444).withOpacity(0.15),
                        const Color(0xFFDC2626).withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFEF4444).withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFEF4444).withOpacity(0.1),
                          const Color(0xFFDC2626).withOpacity(0.05),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFEF4444),
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Modern title with better typography
                Text(
                  'تسجيل الخروج',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Description text
                Text(
                  'هل أنت متأكد من تسجيل الخروج من حسابك؟\nسيتم إعادة توجيهك إلى صفحة تسجيل الدخول',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    height: 1.5,
                    letterSpacing: 0.1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Modern action buttons with enhanced styling
                Row(
                  children: [
                    // Cancel button with modern subtle styling
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF334155).withOpacity(0.5)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF475569)
                                    : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: EdgeInsets.zero,
                            overlayColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.black.withOpacity(0.03),
                          ),
                          child: Text(
                            'إلغاء',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF475569),
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Logout button with gradient and modern styling
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFEF4444),
                              Color(0xFFDC2626),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: () async {
                            await Supabase.instance.client.auth.signOut();
                            if (ctx.mounted) {
                              Navigator.of(ctx).pop();
                            }
                            if (context.mounted) {
                              context.go('/auth');
                            }
                          },
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: EdgeInsets.zero,
                            overlayColor: Colors.white.withOpacity(0.1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.logout_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'تسجيل الخروج',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
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

  void _showWeeklyReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => WeeklyReportDialog(
        adminService: AdminService(Supabase.instance.client),
      ),
    );
  }

  Future<void> _downloadMaintenanceCounts(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(color: Color(0xFFF59E0B)),
              const SizedBox(width: 20),
              Text(
                'جاري تحضير ملف حصر الصيانة...',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      );

      // Add a small delay to ensure UI updates
      await Future.delayed(const Duration(milliseconds: 100));

      final repository = MaintenanceCountRepository(Supabase.instance.client);
      final supervisorRepository = SupervisorRepository(Supabase.instance.client);
      final excelService = ExcelExportService(
        repository,
        supervisorRepository: supervisorRepository,
      );
      
      // Export with retry mechanism and better error handling
      int retryCount = 0;
      const maxRetries = 3;
      Exception? lastError;
      
      while (retryCount < maxRetries) {
        try {
          await excelService.exportAllMaintenanceCounts();
          break; // Success, exit retry loop
        } catch (e) {
          lastError = e is Exception ? e : Exception(e.toString());
          retryCount++;
          print('Maintenance counts export attempt $retryCount failed: $e');
          
          if (retryCount >= maxRetries) {
            break; // Exit retry loop
          }
          
          // Update loading dialog with retry information
          if (context.mounted) {
            Navigator.of(context).pop();
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFFF59E0B)),
                    const SizedBox(height: 16),
                    Text(
                      'إعادة المحاولة... ($retryCount/$maxRetries)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          
          // Wait before retry with exponential backoff
          await Future.delayed(Duration(milliseconds: 1000 * retryCount));
        }
      }
      
      // Close loading dialog
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      if (lastError != null) {
        // All retries failed
        throw lastError;
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text('تم تحميل حصر الصيانة بنجاح!'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Provide more specific error messages
      String errorMessage = 'حدث خطأ أثناء التحميل';
      if (e.toString().contains('No maintenance counts found')) {
        errorMessage = 'لا توجد بيانات حصر صيانة للتحميل';
      } else if (e.toString().contains('Storage permission denied')) {
        errorMessage = 'تم رفض إذن التخزين. يرجى السماح بالوصول للملفات';
      } else if (e.toString().contains('Download already in progress')) {
        errorMessage = 'تحميل قيد التنفيذ بالفعل. يرجى الانتظار';
      } else if (e.toString().contains('Export timeout')) {
        errorMessage = 'استغرق التصدير وقتاً طويلاً. يرجى المحاولة مرة أخرى';
      } else if (e.toString().contains('Failed to export Excel')) {
        errorMessage = 'فشل في إنشاء ملف Excel. يرجى المحاولة مرة أخرى';
      } else {
        errorMessage = 'حدث خطأ أثناء التحميل: ${e.toString().split(':').last.trim()}';
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'إعادة المحاولة',
              textColor: Colors.white,
              onPressed: () => _downloadMaintenanceCounts(context),
            ),
          ),
        );
      }
    }
  }

  Future<void> _downloadDamageCounts(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(color: Color(0xFFEF4444)),
              const SizedBox(width: 20),
              Text(
                'جاري تحضير ملف حصر التوالف...',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      );

      // Add a small delay to ensure UI updates
      await Future.delayed(const Duration(milliseconds: 100));

      final maintenanceRepo = MaintenanceCountRepository(Supabase.instance.client);
      final damageRepo = DamageCountRepository(Supabase.instance.client);
      final supervisorRepo = SupervisorRepository(Supabase.instance.client);
      final excelService = ExcelExportService(
        maintenanceRepo, 
        damageRepository: damageRepo,
        supervisorRepository: supervisorRepo,
      );
      
      // Export with retry mechanism
      int retryCount = 0;
      const maxRetries = 3;
      
      while (retryCount < maxRetries) {
        try {
          await excelService.exportAllDamageCounts();
          break; // Success, exit retry loop
        } catch (e) {
          retryCount++;
          if (retryCount >= maxRetries) {
            rethrow; // Re-throw if all retries failed
          }
          // Wait before retry
          await Future.delayed(Duration(milliseconds: 500 * retryCount));
        }
      }
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text('تم تحميل حصر التوالف بنجاح!'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('حدث خطأ أثناء التحميل: $e')),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

}
