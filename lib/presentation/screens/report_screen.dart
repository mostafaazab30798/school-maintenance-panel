import 'package:admin_panel/presentation/widgets/dashboard/expandable_report_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/blocs/reports/report_bloc.dart';
import '../../../logic/blocs/reports/report_event.dart';
import '../../../logic/blocs/reports/report_state.dart';
import '../../../data/models/report.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/date_symbol_data_local.dart';
import 'dart:typed_data';
// Web-specific imports - conditional
import 'dart:html' as html;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as syncfusion;

class ReportScreen extends StatefulWidget {
  const ReportScreen({
    super.key,
    required this.title,
    this.supervisorId,
    this.type,
    this.status,
    this.priority,
    this.schoolName,
  });

  final String title;
  final String? supervisorId;
  final String? type;
  final String? status;
  final String? priority;
  final String? schoolName;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Report> _filteredReports = [];
  bool _isSearching = false;
  String _selectedStatusFilter = 'all';

  // Status filter options
  final List<Map<String, dynamic>> _statusFilterOptions = [
    {'key': 'all', 'label': 'جميع البلاغات', 'icon': Icons.list_alt},
    {'key': 'pending', 'label': 'قيد التنفيذ', 'icon': Icons.schedule_outlined},
    {'key': 'completed', 'label': 'مكتملة', 'icon': Icons.check_circle_outline},
    {'key': 'late', 'label': 'متأخرة', 'icon': Icons.warning_outlined},
    {'key': 'late_completed', 'label': 'منجزة متأخرة', 'icon': Icons.check_circle_outlined},
  ];

  // Status colors and labels
  final Map<String, Color> _statusColors = {
    'pending': const Color(0xFF6B7280),
    'completed': const Color(0xFF10B981),
    'late': const Color(0xFFEF4444),
    'late_completed': const Color(0xFFFF9800),
  };

  final Map<String, String> _statusLabels = {
    'pending': 'قيد التنفيذ',
    'completed': 'مكتمل',
    'late': 'متأخر',
    'late_completed': 'منجز متأخر',
  };

  @override
  void initState() {
    super.initState();
    // Set initial status filter based on widget status parameter
    if (widget.status != null) {
      _selectedStatusFilter = widget.status!;
    }
    // Initial load with filters
    _loadReportsWithFilters();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // This will trigger the filtering when user types
  }

  void _filterReports(List<Report> allReports) {
    final query = _searchController.text.toLowerCase().trim();
    List<Report> filteredBySearch = allReports;
    
    // Apply search filter
    if (query.isNotEmpty) {
      filteredBySearch = allReports.where((report) {
        return report.schoolName.toLowerCase().contains(query);
      }).toList();
    }
    
    // Apply status filter
    if (_selectedStatusFilter != 'all') {
      filteredBySearch = filteredBySearch.where((report) {
        return report.status == _selectedStatusFilter;
      }).toList();
    }
    
    _filteredReports = filteredBySearch;
  }

  void _loadReportsWithFilters({bool forceRefresh = false}) {
    context.read<ReportBloc>().add(FetchReports(
          supervisorId: widget.supervisorId,
          type: widget.type,
          status: widget.status,
          priority: widget.priority,
          schoolName: widget.schoolName,
          forceRefresh: forceRefresh,
        ));
  }

  String _translatePriority(String? value) {
    switch (value) {
      case 'Routine':
        return 'روتيني';
      case 'Emergency':
        return 'طارئ';
      default:
        return value ?? '';
    }
  }

  String _translateType(String? value) {
    switch (value) {
      case 'Civil':
        return 'مدني';
      case 'Plumbing':
        return 'سباكة';
      case 'Electricity':
        return 'كهرباء';
      case 'AC':
        return 'تكييف';
      case 'Fire':
        return 'حريق';
      default:
        return value ?? '';
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

  String _translateReportSource(String? value) {
    switch (value) {
      case 'unifier':
        return 'يونيفاير';
      case 'check_list':
        return 'تشيك ليست';
      case 'consultant':
        return 'استشاري';
      default:
        return value ?? 'يونيفاير'; // Default to unifier
    }
  }

  Widget _buildStatusFilterChips() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _statusFilterOptions.length,
        itemBuilder: (context, index) {
          final option = _statusFilterOptions[index];
          final isSelected = _selectedStatusFilter == option['key'];
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    option['icon'],
                    size: 16,
                    color: isSelected ? Colors.white : _getStatusColor(option['key']),
                  ),
                  const SizedBox(width: 4),
                  Text(option['label']),
                ],
              ),
              selectedColor: _getStatusColor(option['key']),
              checkmarkColor: Colors.white,
              onSelected: (selected) {
                setState(() {
                  _selectedStatusFilter = option['key'];
                });
                // Re-filter the reports
                if (context.read<ReportBloc>().state is ReportLoaded) {
                  final state = context.read<ReportBloc>().state as ReportLoaded;
                  _filterReports(state.reports);
                }
              },
              backgroundColor: Colors.grey[200],
              side: BorderSide(
                color: isSelected ? _getStatusColor(option['key']) : Colors.grey[300]!,
                width: 1,
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFF6B7280);
      case 'completed':
        return const Color(0xFF10B981);
      case 'late':
        return const Color(0xFFEF4444);
      case 'late_completed':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  

  

  Widget _buildEmptyState() {
    if (_searchController.text.isNotEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'لا توجد نتائج للبحث',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'جرب البحث بكلمة أخرى',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    } else if (_selectedStatusFilter != 'all') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _statusFilterOptions.firstWhere((opt) => opt['key'] == _selectedStatusFilter)['icon'],
              size: 64,
              color: _getStatusColor(_selectedStatusFilter),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد بلاغات ${_statusLabels[_selectedStatusFilter] ?? _selectedStatusFilter}',
              style: TextStyle(
                fontSize: 18,
                color: _getStatusColor(_selectedStatusFilter),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'جرب تغيير الفلتر أو البحث بكلمة أخرى',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    } else {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'لا يوجد بلاغات',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'لم يتم العثور على أي بلاغات في النظام',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _downloadReportsExcel(List<Report> reports) async {
    try {
      await initializeDateFormatting('ar');
      
      // Use Syncfusion for web export
      final workbook = syncfusion.Workbook();
      
      // Rename the default sheet instead of removing it
      final sheet = workbook.worksheets[0];
      sheet.name = 'البلاغات';
      final dateFormat = intl.DateFormat('dd/MM/yyyy hh:mm a');
      
      // Header row
      final headers = [
        'اسم المشرف',
        'اسم المدرسة',
        'وصف البلاغ',
        'اولولية البلاغ',
        'حالة البلاغ',
        'نوع البلاغ',
        'مصدر البلاغ',
        'تاريخ انشاء البلاغ',
        'تاريخ الجدولة',
        'تاريخ اغلاق البلاغ',
        'ملاحظة الاغلاق',
      ];
      
      for (int i = 0; i < headers.length; i++) {
        sheet.getRangeByIndex(1, i + 1).setText(headers[i]);
      }
      
      for (int row = 0; row < reports.length; row++) {
        final report = reports[row];
        final rowData = [
          report.supervisorName,
          report.schoolName,
          report.description,
          _translatePriority(report.priority),
          _translateStatus(report.status),
          _translateType(report.type),
          _translateReportSource(report.reportSource),
          dateFormat.format(report.createdAt),
          dateFormat.format(report.scheduledDate),
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
        ..setAttribute('download', 'جميع_البلاغات.xlsx')
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e, stack) {
      // Print error and stack trace for debugging
      print('Excel export error: $e');
      print(stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تصدير البلاغات: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'البحث عن مدرسة...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.black),
                  ),
                  style: const TextStyle(color: Colors.black),
                  onChanged: (value) {
                    setState(() {
                      // Trigger rebuild to update filtered results
                    });
                  },
                )
              : Text(widget.title),
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                  }
                });
              },
            ),
          ],
        ),
        body: BlocBuilder<ReportBloc, ReportState>(
          builder: (context, state) {
            if (state is ReportLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ReportLoaded) {
              // Filter reports based on search query and status
              _filterReports(state.reports);

              return Column(
                children: [
               
                  
                  
                  // Status filter chips
                  _buildStatusFilterChips(),
                  
                  // Search results count
                  if (_searchController.text.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Colors.blue.withOpacity(0.1),
                      child: Text(
                        'تم العثور على ${_filteredReports.length} نتيجة للبحث عن "${_searchController.text}"',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  
                  // Filtered results count
                  if (_selectedStatusFilter != 'all' && _searchController.text.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: _getStatusColor(_selectedStatusFilter).withOpacity(0.1),
                      child: Text(
                        'عرض ${_filteredReports.length} بلاغ ${_statusLabels[_selectedStatusFilter] ?? _selectedStatusFilter}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _getStatusColor(_selectedStatusFilter),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  
                  // Results list
                  Expanded(
                    child: _filteredReports.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: _filteredReports.length,
                            itemBuilder: (context, index) {
                              final Report report = _filteredReports[index];
                              return ExpandableReportCard(report: report.toMap());
                            },
                          ),
                  ),
                ],
              );
            } else if (state is ReportError) {
              return Center(child: Text('خطأ: ${state.message}'));
            } else {
              return const Center(child: Text('تحميل البيانات...'));
            }
          },
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'refresh_btn',
              onPressed: () => _loadReportsWithFilters(forceRefresh: true),
              tooltip: 'تحديث مع الحفاظ على الفلاتر',
              backgroundColor: const Color(0xFF3B82F6),
              child: const Icon(Icons.refresh_rounded, color: Colors.white),
            ),
            if (widget.title == 'جميع البلاغات') ...[
              const SizedBox(width: 16),
              BlocBuilder<ReportBloc, ReportState>(
                builder: (context, state) {
                  if (state is ReportLoaded) {
                    // Use filtered reports for download
                    _filterReports(state.reports);
                    if (_filteredReports.isNotEmpty) {
                      return FloatingActionButton(
                        heroTag: 'download_excel_btn',
                        onPressed: () =>
                            _downloadReportsExcel(_filteredReports),
                        tooltip: _searchController.text.isNotEmpty
                            ? 'تحميل نتائج البحث (Excel)'
                            : 'تحميل كل البلاغات (Excel)',
                        child: Stack(
                          children: [
                            const Icon(Icons.download_rounded),
                            if (_searchController.text.isNotEmpty)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }
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
