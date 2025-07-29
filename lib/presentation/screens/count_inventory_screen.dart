import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../logic/blocs/maintenance_counts/maintenance_counts_bloc.dart';
import '../../data/repositories/maintenance_count_repository.dart';
import '../../data/repositories/supervisor_repository.dart';
import '../../data/repositories/damage_count_repository.dart';
import '../../core/services/admin_service.dart';
import '../../core/services/excel_export_service.dart';
import '../../data/models/maintenance_count.dart';
import '../../data/models/damage_count.dart';
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
      )..add(const LoadMaintenanceCountRecords()),
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
            if (state is MaintenanceCountRecordsLoaded && state.records.isNotEmpty) {
              return FloatingActionButton.extended(
                onPressed: () => _exportToExcel(context, state.records),
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
                      .add(const LoadMaintenanceCountRecords()),
                ),
              );
            }

            if (state is MaintenanceCountRecordsLoaded) {
              final records = state.records;
              final supervisorNames = state.supervisorNames;

              if (records.isEmpty) {
                return _buildEmptyState(context);
              }

              return _buildMaintenanceCountsList(context, records, supervisorNames);
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
            'جاري تحميل سجلات حصر الاعداد...',
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
              'لا توجد سجلات حصر صيانة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'لم يتم العثور على أي سجلات حصر صيانة حتى الآن',
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

  Widget _buildMaintenanceCountsList(
      BuildContext context, List<MaintenanceCount> records, Map<String, String> supervisorNames) {
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
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final record = records[index];
                  return _buildMaintenanceCountChip(context, record, supervisorNames);
                },
                childCount: records.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceCountChip(BuildContext context, MaintenanceCount record, Map<String, String> supervisorNames) {
    final schoolName = record.schoolName;
    final status = record.status;
    final createdAt = record.createdAt;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = status == 'submitted' ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.all(6.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showMaintenanceCountDetails(context, record),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark 
                    ? Colors.black.withOpacity(0.3)
                    : const Color(0xFF64748B).withOpacity(0.08),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.8),
                  offset: const Offset(0, 1),
                  blurRadius: 0,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon and status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            statusColor.withOpacity(0.15),
                            statusColor.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: statusColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.inventory_2_rounded,
                        color: statusColor,
                        size: 18,
                      ),
                    ),
                    const Spacer(),
                    // Container(
                    //   padding: const EdgeInsets.symmetric(
                    //     horizontal: 8,
                    //     vertical: 4,
                    //   ),
                    //   decoration: BoxDecoration(
                    //     color: statusColor,
                    //     borderRadius: BorderRadius.circular(16),
                    //   ),
                    //   child: Text(
                    //     status == 'submitted' ? 'تم الإرسال' : 'مسودة',
                    //     style: const TextStyle(
                    //       fontSize: 10,
                    //       fontWeight: FontWeight.w600,
                    //       color: Colors.white,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // School name
                Text(
                  schoolName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 10),
                
                // Details section - more compact
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155).withOpacity(0.3) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Creation date
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'تاريخ الإنشاء: ${_formatDate(createdAt)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 6),
                      
                      // Supervisor
                      Row(
                        children: [
                          Icon(
                            Icons.person_rounded,
                            size: 12,
                            color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _getSupervisorDisplayText(record.supervisorId, supervisorNames),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Action indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'عرض التفاصيل',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: statusColor,
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

  void _showMaintenanceCountDetails(
      BuildContext context, MaintenanceCount record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaintenanceCountDetailScreen(
          schoolId: record.schoolId,
          schoolName: record.schoolName,
        ),
      ),
    );
  }

  Future<void> _exportToExcel(
      BuildContext context, List<MaintenanceCount> records) async {
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
      final supervisorRepository = SupervisorRepository(Supabase.instance.client);
      final excelService = ExcelExportService(
        repository,
        supervisorRepository: supervisorRepository,
      );

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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getSupervisorDisplayText(String supervisorId, Map<String, String> supervisorNames) {
    // Check if this is a merged record (contains multiple supervisor IDs)
    if (supervisorId.contains(', ')) {
      final supervisorIdList = supervisorId.split(', ');
      final supervisorNameList = <String>[];
      
      for (final id in supervisorIdList) {
        final name = supervisorNames[id.trim()];
        if (name != null && name.isNotEmpty) {
          supervisorNameList.add(name);
        }
      }
      
      if (supervisorNameList.isNotEmpty) {
        if (supervisorNameList.length == 1) {
          return 'المشرف: ${supervisorNameList.first}';
        } else {
          return 'المشرفون: ${supervisorNameList.join('، ')}';
        }
      } else {
        return 'المشرفون: غير محدد';
      }
    } else {
      // Single supervisor
      final supervisorName = supervisorNames[supervisorId];
      return 'المشرف: ${supervisorName ?? 'غير محدد'}';
    }
  }
}
