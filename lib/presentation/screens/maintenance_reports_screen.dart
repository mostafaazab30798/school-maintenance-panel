import 'package:admin_panel/presentation/widgets/dashboard/expandable_maintenance_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/blocs/maintenance_reports/maintenance_view_bloc.dart';
import '../../logic/blocs/maintenance_reports/maintenance_view_event.dart';
import '../../logic/blocs/maintenance_reports/maintenance_view_state.dart';
import '../../data/models/maintenance_report.dart';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/date_symbol_data_local.dart';
import 'dart:typed_data';
import '../widgets/dashboard/expandable_maintenance_card.dart';
import '../widgets/common/standard_refresh_button.dart';

class MaintenanceReportsScreen extends StatefulWidget {
  const MaintenanceReportsScreen({
    super.key,
    required this.title,
    this.supervisorId,
    this.status,
  });

  final String title;
  final String? supervisorId;
  final String? status;

  @override
  State<MaintenanceReportsScreen> createState() =>
      _MaintenanceReportsScreenState();
}

class _MaintenanceReportsScreenState extends State<MaintenanceReportsScreen> {
  @override
  void initState() {
    super.initState();
    // Initial load with filters
    _loadMaintenanceReportsWithFilters();
  }

  void _loadMaintenanceReportsWithFilters({bool forceRefresh = false}) {
    context.read<MaintenanceViewBloc>().add(FetchMaintenanceReports(
          supervisorId: widget.supervisorId,
          status: widget.status,
          forceRefresh: forceRefresh,
        ));
  }

  String _translateStatus(String? value) {
    switch (value) {
      case 'pending':
        return 'جاري العمل';
      case 'completed':
        return 'تم الانتهاء';
      case 'late':
        return 'متأخر';
      case 'late_completed':
        return 'منجز متأخر';
      default:
        return value ?? '';
    }
  }

  Future<void> _downloadMaintenanceExcel(
      List<MaintenanceReport> reports) async {
    try {
      await initializeDateFormatting('ar');
      final excel = Excel.createExcel();
      final sheet = excel['بلاغات الصيانة'];
      final dateFormat = intl.DateFormat('dd/MM/yyyy hh:mm a');

      // Header row
      sheet.appendRow([
        'اسم المدرسة',
        'وصف الصيانة',
        'حالة الصيانة',
        'تاريخ انشاء الصيانة',
        'تاريخ الجدولة',
        'تاريخ اغلاق الصيانة',
        'ملاحظة الاغلاق',
      ]);

      for (final report in reports) {
        sheet.appendRow([
          report.schoolId,
          report.description,
          _translateStatus(report.status),
          dateFormat.format(report.createdAt),
          report.closedAt != null ? dateFormat.format(report.closedAt!) : '',
          report.completionNote ?? '',
        ]);
      }

      final excelBytes = excel.encode();
      if (excelBytes == null) return;

      await FileSaver.instance.saveFile(
        name: 'جميع_بلاغات_الصيانة',
        bytes: Uint8List.fromList(excelBytes),
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
    } catch (e, stack) {
      print('Excel export error: $e');
      print(stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تصدير بلاغات الصيانة: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : null,
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: Text(
            widget.title,
            style: Theme.of(context).appBarTheme.titleTextStyle,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
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
        ),
        body: BlocBuilder<MaintenanceViewBloc, MaintenanceViewState>(
          builder: (context, state) {
            if (state is MaintenanceViewLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is MaintenanceViewLoaded) {
              if (state.maintenanceReports.isEmpty) {
                return Center(
                  child: Text(
                    'لا يوجد بلاغات صيانة.',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                );
              }
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            const Color(0xFF0F172A),
                            const Color(0xFF1E293B),
                          ]
                        : [
                            const Color(0xFFF8FAFC),
                            const Color(0xFFF1F5F9),
                          ],
                  ),
                ),
                child: ListView.builder(
                  itemCount: state.maintenanceReports.length,
                  itemBuilder: (context, index) {
                    final MaintenanceReport report =
                        state.maintenanceReports[index];
                    return ExpandableMaintenanceCard(
                        maintenanceReport: report.toMap());
                  },
                ),
              );
            } else if (state is MaintenanceViewError) {
              return Center(
                child: Text(
                  'خطأ: ${state.message}',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFEF4444),
                  ),
                ),
              );
            } else {
              return Center(
                child: Text(
                  'تحميل البيانات...',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              );
            }
          },
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'refresh_maintenance_btn',
              onPressed: () =>
                  _loadMaintenanceReportsWithFilters(forceRefresh: true),
              tooltip: 'تحديث مع الحفاظ على الفلاتر',
              backgroundColor: const Color(0xFF3B82F6),
              child: const Icon(Icons.refresh_rounded, color: Colors.white),
            ),
            if (widget.title == 'جميع بلاغات الصيانة') ...[
              const SizedBox(width: 16),
              BlocBuilder<MaintenanceViewBloc, MaintenanceViewState>(
                builder: (context, state) {
                  if (state is MaintenanceViewLoaded &&
                      state.maintenanceReports.isNotEmpty) {
                    return FloatingActionButton(
                      heroTag: 'download_maintenance_excel_btn',
                      onPressed: () =>
                          _downloadMaintenanceExcel(state.maintenanceReports),
                      tooltip: 'تحميل كل بلاغات الصيانة (Excel)',
                      child: const Icon(Icons.download_rounded),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
