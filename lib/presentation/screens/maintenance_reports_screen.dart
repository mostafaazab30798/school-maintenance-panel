import 'package:admin_panel/presentation/widgets/dashboard/expandable_maintenance_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/blocs/maintenance_reports/maintenance_view_bloc.dart';
import '../../logic/blocs/maintenance_reports/maintenance_view_event.dart';
import '../../logic/blocs/maintenance_reports/maintenance_view_state.dart';
import '../../data/models/maintenance_report.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/date_symbol_data_local.dart';
import 'dart:typed_data';
// Web-specific imports - conditional
import 'dart:html' as html;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as syncfusion;
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
  // Pagination variables
  int currentPage = 1;
  int reportsPerPage = 20;
  int totalPages = 1;

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
          limit: reportsPerPage,
          page: currentPage,
        ));
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      setState(() {
        currentPage = page;
      });
      _loadMaintenanceReportsWithFilters();
    }
  }

  void _nextPage() {
    if (currentPage < totalPages) {
      _goToPage(currentPage + 1);
    }
  }

  void _previousPage() {
    if (currentPage > 1) {
      _goToPage(currentPage - 1);
    }
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
      
      // Use Syncfusion for web export
      final workbook = syncfusion.Workbook();
      
      // Rename the default sheet instead of removing it
      final sheet = workbook.worksheets[0];
      sheet.name = 'بلاغات الصيانة';
      final dateFormat = intl.DateFormat('dd/MM/yyyy hh:mm a');

      // Header row
      final headers = [
        'اسم المدرسة',
        'وصف الصيانة',
        'حالة الصيانة',
        'تاريخ انشاء الصيانة',
        'تاريخ الجدولة',
        'تاريخ اغلاق الصيانة',
        'ملاحظة الاغلاق',
      ];
      
      for (int i = 0; i < headers.length; i++) {
        sheet.getRangeByIndex(1, i + 1).setText(headers[i]);
      }

      for (int row = 0; row < reports.length; row++) {
        final report = reports[row];
        final rowData = [
          report.schoolId,
          report.description,
          _translateStatus(report.status),
          dateFormat.format(report.createdAt),
          report.closedAt != null ? dateFormat.format(report.closedAt!) : '',
          report.completionNote ?? '',
        ];
        
        for (int col = 0; col < rowData.length; col++) {
          sheet.getRangeByIndex(row + 2, col + 1).setText(rowData[col].toString());
        }
      }

      // Save and download
      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      final blob = html.Blob([Uint8List.fromList(bytes)]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'جميع_بلاغات_الصيانة.xlsx')
        ..click();
      html.Url.revokeObjectUrl(url);
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

  Widget _buildReportsInfo(List<MaintenanceReport> reports) {
    final totalReports = reports.length;
    final completedReports = reports.where((report) => report.status == 'completed').length;
    final lateReports = reports.where((report) => report.status == 'late').length;
    final lateCompletedReports = reports.where((report) => report.status == 'late_completed').length;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'عرض $totalReports بلاغات صيانة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          Row(
            children: [
              Text(
                'تم الانتهاء: $completedReports',
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xFF10B981), // Green color for success
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'متأخر: $lateReports',
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xFFFF9800), // Orange color for warning
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'منجز متأخر: $lateCompletedReports',
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xFFEF4444), // Red color for error
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: currentPage > 1 ? _previousPage : null,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            label: const Text('السابق'),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentPage > 1
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              foregroundColor: currentPage > 1
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$currentPage/$totalPages',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: currentPage < totalPages ? _nextPage : null,
            icon: const Icon(Icons.arrow_forward_ios_rounded),
            label: const Text('التالي'),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentPage < totalPages
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              foregroundColor: currentPage < totalPages
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
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
              
              // Calculate total pages based on loaded data
              totalPages = (state.maintenanceReports.length / reportsPerPage).ceil();
              if (totalPages == 0) totalPages = 1;
              
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
                child: Column(
                  children: [
                    // Reports info
                    _buildReportsInfo(state.maintenanceReports),
                    
                    // Reports list
                    Expanded(
                      child: ListView.builder(
                        itemCount: state.maintenanceReports.length,
                        itemBuilder: (context, index) {
                          final MaintenanceReport report =
                              state.maintenanceReports[index];
                          return ExpandableMaintenanceCard(
                              maintenanceReport: report.toMap());
                        },
                      ),
                    ),
                    
                    // Pagination controls
                    if (totalPages > 1) _buildPaginationControls(),
                  ],
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
