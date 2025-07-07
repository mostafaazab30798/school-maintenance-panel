import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../logic/blocs/maintenance_counts/maintenance_counts_bloc.dart';
import '../../data/repositories/maintenance_count_repository.dart';
import '../../data/repositories/damage_count_repository.dart';
import '../../core/services/admin_service.dart';
import '../../core/services/excel_export_service.dart';
import '../widgets/common/shared_app_bar.dart';
import '../widgets/common/error_widget.dart';
import '../widgets/common/school_chip.dart';
import 'maintenance_count_detail_screen.dart';

class CountInventoryScreen extends StatelessWidget {
  const CountInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MaintenanceCountsBloc(
        repository: MaintenanceCountRepository(Supabase.instance.client),
        damageRepository: DamageCountRepository(Supabase.instance.client),
        adminService: AdminService(Supabase.instance.client),
      )..add(const LoadSchoolsWithCounts()),
      child: const CountInventoryView(),
    );
  }
}

class CountInventoryView extends StatelessWidget {
  const CountInventoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: const SharedAppBar(
          title: 'حصر الاعداد',
        ),
        floatingActionButton:
            BlocBuilder<MaintenanceCountsBloc, MaintenanceCountsState>(
          builder: (context, state) {
            if (state is SchoolsWithCountsLoaded && state.schools.isNotEmpty) {
              return FloatingActionButton.extended(
                onPressed: () => _exportToExcel(context, state.schools),
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 4,
                icon: const Icon(Icons.file_download_rounded, size: 20),
                label: const Text(
                  'تصدير Excel',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        body: BlocBuilder<MaintenanceCountsBloc, MaintenanceCountsState>(
          builder: (context, state) {
            if (state is MaintenanceCountsLoading) {
              return _buildLoadingState(context);
            }

            if (state is MaintenanceCountsError) {
              return Center(
                child: AppErrorWidget(
                  message: state.message,
                  onRetry: () => context
                      .read<MaintenanceCountsBloc>()
                      .add(const LoadSchoolsWithCounts()),
                ),
              );
            }

            if (state is SchoolsWithCountsLoaded) {
              final schools = state.schools;

              if (schools.isEmpty) {
                return _buildEmptyState(context);
              }

              return _buildSchoolsList(context, schools);
            }

            return _buildEmptyState(context);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF3B82F6).withOpacity(0.1),
                  const Color(0xFF1D4ED8).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF3B82F6).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'جاري تحميل حصر الاعداد...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[300] : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1E293B).withOpacity(0.8),
                    const Color(0xFF334155).withOpacity(0.6),
                  ]
                : [
                    Colors.white.withOpacity(0.9),
                    const Color(0xFFF8FAFC).withOpacity(0.7),
                  ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? const Color(0xFF334155).withOpacity(0.5)
                : const Color(0xFFE2E8F0).withOpacity(0.8),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : const Color(0xFF64748B).withOpacity(0.06),
              offset: const Offset(0, 8),
              blurRadius: 32,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF3B82F6).withOpacity(0.15),
                    const Color(0xFF1D4ED8).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                size: 48,
                color: Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'لا توجد مدارس بحصر صيانة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'لم يتم العثور على أي مدارس تحتوي على حصر صيانة حتى الآن',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolsList(
      BuildContext context, List<Map<String, dynamic>> schools) {
    return RefreshIndicator(
      onRefresh: () async {
        context
            .read<MaintenanceCountsBloc>()
            .add(const RefreshMaintenanceCounts());
      },
      color: const Color(0xFF10B981),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final school = schools[index];
                  return _buildSchoolChip(context, school);
                },
                childCount: schools.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolChip(BuildContext context, Map<String, dynamic> school) {
    final schoolName = school['school_name'] as String;
    final address = school['address'] as String? ?? '';
    final maintenanceCount = school['maintenance_count'] as int;

    return SchoolChip(
      schoolName: schoolName,
      address: address,
      count: maintenanceCount,
      primaryColor: const Color(0xFF10B981),
      icon: Icons.inventory_outlined,
      countLabel: 'عدد',
      onTap: () => _showMaintenanceCountDetails(context, school),
    );
  }

  void _showMaintenanceCountDetails(
      BuildContext context, Map<String, dynamic> school) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaintenanceCountDetailScreen(
          schoolId: school['school_id'] as String,
          schoolName: school['school_name'] as String,
        ),
      ),
    );
  }

  Future<void> _exportToExcel(
      BuildContext context, List<Map<String, dynamic>> schools) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(color: Color(0xFF10B981)),
              const SizedBox(width: 20),
              Text(
                'جاري تصدير البيانات...',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      );

      // Create Excel export service
      final repository = MaintenanceCountRepository(Supabase.instance.client);
      final excelService = ExcelExportService(repository);

      // Export to Excel
      await excelService.exportAllMaintenanceCounts();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم تصدير البيانات بنجاح - تحقق من التحميلات'),
            backgroundColor: const Color(0xFF10B981),
            action: SnackBarAction(
              label: 'موافق',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء التصدير: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'موافق',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }
}
