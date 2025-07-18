import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../logic/blocs/maintenance_reports/maintenance_bloc.dart';
import '../../logic/blocs/maintenance_reports/maintenance_event.dart';
import '../../logic/blocs/maintenance_reports/maintenance_state.dart';
import '../../data/repositories/maintenance_repository.dart';
import '../../core/services/admin_service.dart';
import '../widgets/dashboard/expandable_maintenance_card.dart';
import '../widgets/common/standard_refresh_button.dart';
import '../widgets/common/shared_app_bar.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/date_symbol_data_local.dart';
import 'dart:typed_data';
import '../../core/services/cache_service.dart';
// Web-specific imports - conditional
import 'dart:html' as html;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as syncfusion;

class AllMaintenanceScreen extends StatefulWidget {
  final String? initialFilter;
  final String? supervisorId;
  final String? supervisorName;

  const AllMaintenanceScreen({
    super.key,
    this.initialFilter,
    this.supervisorId,
    this.supervisorName,
  });

  @override
  State<AllMaintenanceScreen> createState() => _AllMaintenanceScreenState();
}

class _AllMaintenanceScreenState extends State<AllMaintenanceScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> maintenanceReports = [];
  List<Map<String, dynamic>> filteredReports = [];
  List<Map<String, dynamic>> paginatedReports = [];
  bool isLoading = true;
  String? error;
  String selectedFilter = 'all';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final CacheService _cacheService = CacheService();
  bool _isLoadingFromCache = false;

  // Pagination variables
  int currentPage = 1;
  int reportsPerPage = 20;
  int totalPages = 1;

  final AdminService _adminService = AdminService(Supabase.instance.client);

  final Map<String, String> statusLabels = {
    'pending': 'في الانتظار',
    'in_progress': 'قيد التنفيذ',
    'completed': 'مكتمل',
  };

  final Map<String, Color> statusColors = {
    'pending': const Color(0xFF6B7280),
    'in_progress': const Color(0xFF3B82F6),
    'completed': const Color(0xFF10B981),
  };

  final Map<String, IconData> statusIcons = {
    'pending': Icons.schedule_outlined,
    'in_progress': Icons.hourglass_empty_outlined,
    'completed': Icons.check_circle_outline,
  };

  final List<Map<String, String>> filterOptions = [
    {'key': 'all', 'label': 'جميع البلاغات'},
    {'key': 'pending', 'label': 'جاري العمل'},
    {'key': 'completed', 'label': 'مكتملة'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.initialFilter != null) {
      selectedFilter = widget.initialFilter!;
    }
    _loadMaintenanceReports();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadMaintenanceReports({bool forceRefresh = false}) async {
    try {
      // Check cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedMaintenance = _cacheService
            .getCached<List<Map<String, dynamic>>>(CacheKeys.allMaintenance);
        if (cachedMaintenance != null) {
          setState(() {
            maintenanceReports = cachedMaintenance;
            _applyFilter();
            isLoading = false;
            _isLoadingFromCache = true;
          });
          _animationController.forward();

          // If cache is near expiry, refresh in background
          if (_cacheService.isNearExpiry(CacheKeys.allMaintenance)) {
            _refreshMaintenanceInBackground();
          }
          return;
        }
      }

      setState(() {
        isLoading = true;
        error = null;
        _isLoadingFromCache = false;
      });

      // Check if user is super admin
      final isSuperAdmin = await _adminService.isCurrentUserSuperAdmin();
      List<Map<String, dynamic>> maintenanceData;

      if (isSuperAdmin) {
        // Super admin can see all maintenance reports or filter by specific supervisor
        var query = Supabase.instance.client
            .from('maintenance_reports')
            .select('*, supervisors(username)');

        // If supervisorId is provided, filter by it
        if (widget.supervisorId != null) {
          // Convert string to int since supervisor_id in database is likely an integer
          final supervisorIdInt = int.tryParse(widget.supervisorId!);
          if (supervisorIdInt != null) {
            query = query.eq('supervisor_id', supervisorIdInt);
          }
        }

        final response = await query.order('created_at', ascending: false);
        maintenanceData = List<Map<String, dynamic>>.from(response);
      } else {
        // Regular admin - filter by their assigned supervisors
        final adminSupervisorIds =
            await _adminService.getCurrentAdminSupervisorIds();
        if (adminSupervisorIds.isEmpty) {
          maintenanceData = [];
        } else {
          final response = await Supabase.instance.client
              .from('maintenance_reports')
              .select('*, supervisors(username)')
              .inFilter('supervisor_id', adminSupervisorIds)
              .order('created_at', ascending: false);
          maintenanceData = List<Map<String, dynamic>>.from(response);
        }
      }

      // Cache the fresh data
      _cacheService.setCached(CacheKeys.allMaintenance, maintenanceData);

      setState(() {
        maintenanceReports = maintenanceData;
        _applyFilter();
        isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _refreshMaintenanceInBackground() async {
    try {
      // Check if user is super admin
      final isSuperAdmin = await _adminService.isCurrentUserSuperAdmin();
      List<Map<String, dynamic>> maintenanceData;

      if (isSuperAdmin) {
        // Super admin can see all maintenance reports or filter by specific supervisor
        var query = Supabase.instance.client
            .from('maintenance_reports')
            .select('*, supervisors(username)');

        // If supervisorId is provided, filter by it
        if (widget.supervisorId != null) {
          // Convert string to int since supervisor_id in database is likely an integer
          final supervisorIdInt = int.tryParse(widget.supervisorId!);
          if (supervisorIdInt != null) {
            query = query.eq('supervisor_id', supervisorIdInt);
          }
        }

        final response = await query.order('created_at', ascending: false);
        maintenanceData = List<Map<String, dynamic>>.from(response);
      } else {
        // Regular admin - filter by their assigned supervisors
        final adminSupervisorIds =
            await _adminService.getCurrentAdminSupervisorIds();
        if (adminSupervisorIds.isEmpty) {
          maintenanceData = [];
        } else {
          final response = await Supabase.instance.client
              .from('maintenance_reports')
              .select('*, supervisors(username)')
              .inFilter('supervisor_id', adminSupervisorIds)
              .order('created_at', ascending: false);
          maintenanceData = List<Map<String, dynamic>>.from(response);
        }
      }

      // Update cache
      _cacheService.setCached(CacheKeys.allMaintenance, maintenanceData);

      // Update UI if the data has changed
      if (mounted && !_isDataEqual(maintenanceReports, maintenanceData)) {
        setState(() {
          maintenanceReports = maintenanceData;
          _applyFilter();
        });
      }
    } catch (e) {
      // Fail silently for background refresh
      debugPrint('Background maintenance refresh failed: $e');
    }
  }

  bool _isDataEqual(
      List<Map<String, dynamic>> list1, List<Map<String, dynamic>> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i]['id'] != list2[i]['id'] ||
          list1[i]['status'] != list2[i]['status'] ||
          list1[i]['updated_at'] != list2[i]['updated_at']) {
        return false;
      }
    }
    return true;
  }

  void _applyFilter() {
    if (selectedFilter == 'all') {
      filteredReports = maintenanceReports;
    } else {
      filteredReports = maintenanceReports
          .where((report) => report['status'] == selectedFilter)
          .toList();
    }
    _updatePagination();
  }

  void _updatePagination() {
    totalPages = (filteredReports.length / reportsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;

    // Ensure current page is valid
    if (currentPage > totalPages) {
      currentPage = totalPages;
    }

    // Calculate start and end indices for current page
    final startIndex = (currentPage - 1) * reportsPerPage;
    final endIndex =
        (startIndex + reportsPerPage).clamp(0, filteredReports.length);

    paginatedReports = filteredReports.sublist(startIndex, endIndex);
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      setState(() {
        currentPage = page;
        _updatePagination();
      });
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

  Future<void> _downloadMaintenanceExcel() async {
    try {
      await initializeDateFormatting('ar');
      
      // Use Syncfusion for web export
      final workbook = syncfusion.Workbook();
      
      // Rename the default sheet instead of removing it
      final sheet = workbook.worksheets[0];
      sheet.name = 'بلاغات_الصيانة';
      final dateFormat = intl.DateFormat('dd-MM-yyyy hh:mm a');

      // Header row
      final headers = [
        'اسم المشرف',
        'اسم المدرسة',
        'وصف التقرير',
        'حالة التقرير',
        'نوع المعدة',
        'الموقع',
        'الأولوية',
        'تاريخ انشاء التقرير',
        'تاريخ اغلاق التقرير',
      ];
      
      for (int i = 0; i < headers.length; i++) {
        sheet.getRangeByIndex(1, i + 1).setText(headers[i]);
      }

      for (int row = 0; row < filteredReports.length; row++) {
        final report = filteredReports[row];
        final supervisorData = report['supervisors'] as Map<String, dynamic>?;
        final createdAt = report['created_at'] != null
            ? DateTime.parse(report['created_at'])
            : DateTime.now();
        final closedAt = report['closed_at'] != null
            ? DateTime.parse(report['closed_at'])
            : null;

        final rowData = [
          supervisorData?['username'] ?? 'غير محدد',
          report['school_name'] ?? report['title'] ?? 'غير محدد',
          report['description'] ?? '',
          _translateStatus(report['status']),
          report['equipment_type'] ?? 'غير محدد',
          report['location'] ?? 'غير محدد',
          _translatePriority(report['priority']),
          dateFormat.format(createdAt),
          closedAt != null ? dateFormat.format(closedAt) : '',
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحميل ملف Excel بنجاح'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
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

  String _translatePriority(String? value) {
    switch (value?.toLowerCase()) {
      case 'high':
        return 'عالي';
      case 'medium':
        return 'متوسط';
      case 'low':
        return 'منخفض';
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

      default:
        return value ?? '';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'غير محدد';
    try {
      final date = DateTime.parse(dateStr);
      return intl.DateFormat('dd-MM-yyyy hh:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Widget? _buildFloatingActionButton() {
    if (isLoading || filteredReports.isEmpty) return null;

    return FloatingActionButton.extended(
      onPressed: _downloadMaintenanceExcel,
      icon: const Icon(Icons.file_download_rounded),
      label: Text(
        selectedFilter == 'all'
            ? 'تحميل الكل (${filteredReports.length})'
            : 'تحميل المفلترة (${filteredReports.length})',
      ),
      backgroundColor: const Color(0xFFEF4444),
      foregroundColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: SharedAppBar(
          title: 'جميع بلاغات الصيانة',
          actions: [
            StandardRefreshButton(
              onPressed: () => _loadMaintenanceReports(forceRefresh: true),
            ),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(),
        body: isLoading
            ? _buildModernLoadingView()
            : error != null
                ? _buildModernErrorView()
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        // Filter Section
                        if (!isLoading && error == null)
                          _buildModernFilterSection(),

                        // Content
                        filteredReports.isEmpty
                            ? _buildModernEmptyView()
                            : Column(
                                children: [
                                  // Reports info
                                  if (filteredReports.isNotEmpty) _buildReportsInfo(),
                                  
                                  // Maintenance list
                                  _buildModernMaintenanceList(),
                                  
                                  // Pagination controls
                                  if (totalPages > 1) _buildPaginationControls(),
                                ],
                              ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildModernFilterSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تصفية بلاغات الصيانة',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildModernFilterChip(
                    'all', 'الجميع', maintenanceReports.length, Icons.apps),
                _buildModernFilterChip(
                    'pending',
                    'قيد التنفيذ',
                    maintenanceReports
                        .where((r) => r['status'] == 'pending')
                        .length,
                    Icons.schedule),
                _buildModernFilterChip(
                    'completed',
                    'مكتملة',
                    maintenanceReports
                        .where((r) => r['status'] == 'completed')
                        .length,
                    Icons.check_circle),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildModernFilterChip(
      String value, String label, int count, IconData icon) {
    final isSelected = selectedFilter == value;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = value == 'all'
        ? colorScheme.primary
        : statusColors[value] ?? colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: FilterChip(
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            selectedFilter = value;
            _applyFilter();
          });
        },
        avatar: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : color,
        ),
        label: Text('$label ($count)'),
        backgroundColor: color.withOpacity(0.05),
        selectedColor: color,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side: BorderSide(
            color: isSelected ? color : color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        elevation: isSelected ? 4 : 0,
        shadowColor: color.withOpacity(0.3),
      ),
    );
  }

  Widget _buildModernLoadingView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'جاري تحميل بلاغات الصيانة...',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernErrorView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      margin: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'حدث خطأ في تحميل البيانات',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            StandardRefreshElevatedButton(
              onPressed: () => _loadMaintenanceReports(forceRefresh: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernEmptyView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                selectedFilter == 'all'
                    ? Icons.build_outlined
                    : statusIcons[selectedFilter],
                size: 64,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              selectedFilter == 'all'
                  ? 'لا توجد بلاغات صيانة'
                  : 'لا توجد بلاغات صيانة ${statusLabels[selectedFilter]}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'سيتم عرض بلاغات الصيانة هنا عند إضافتها',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsInfo() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalReports = filteredReports.length;
    final pendingReports = filteredReports.where((r) => r['status'] == 'pending').length;
    final inProgressReports = filteredReports.where((r) => r['status'] == 'in_progress').length;
    final completedReports = filteredReports.where((r) => r['status'] == 'completed').length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معلومات البلاغات',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoCard(
                'البلاغات الكلية',
                totalReports,
                Icons.list_alt_outlined,
                const Color(0xFF6B7280),
              ),
              _buildInfoCard(
                'البلاغات المعلقة',
                pendingReports,
                Icons.schedule_outlined,
                const Color(0xFF6B7280),
              ),
              _buildInfoCard(
                'البلاغات قيد التنفيذ',
                inProgressReports,
                Icons.hourglass_empty_outlined,
                const Color(0xFF6B7280),
              ),
              _buildInfoCard(
                'البلاغات مكتملة',
                completedReports,
                Icons.check_circle_outline,
                const Color(0xFF10B981),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, int count, IconData icon, Color color) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 36, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ElevatedButton.icon(
            onPressed: currentPage > 1 ? _previousPage : null,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            label: const Text('السابق'),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentPage > 1
                  ? colorScheme.primary
                  : colorScheme.surfaceVariant.withOpacity(0.3),
              foregroundColor: currentPage > 1
                  ? Colors.white
                  : colorScheme.onSurfaceVariant.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Text(
            '$currentPage/$totalPages',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          ElevatedButton.icon(
            onPressed: currentPage < totalPages ? _nextPage : null,
            icon: const Icon(Icons.arrow_forward_ios_rounded),
            label: const Text('التالي'),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentPage < totalPages
                  ? colorScheme.primary
                  : colorScheme.surfaceVariant.withOpacity(0.3),
              foregroundColor: currentPage < totalPages
                  ? Colors.white
                  : colorScheme.onSurfaceVariant.withOpacity(0.5),
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

  Widget _buildModernMaintenanceList() {
    final crossAxisCount = _getCrossAxisCount();
    final rows = <Widget>[];

    for (int i = 0; i < paginatedReports.length; i += crossAxisCount) {
      final rowStartIndex = i;
      final rowEndIndex =
          (i + crossAxisCount - 1).clamp(0, paginatedReports.length - 1);
      final reportsInRow =
          paginatedReports.sublist(rowStartIndex, rowEndIndex + 1);

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: reportsInRow.asMap().entries.map((entry) {
                final reportIndex = rowStartIndex + entry.key;
                final report = entry.value;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: entry.key < reportsInRow.length - 1 ? 12 : 0,
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            (reportIndex * 0.1).clamp(0.0, 1.0),
                            ((reportIndex + 1) * 0.1).clamp(0.0, 1.0),
                            curve: Curves.easeOutCubic,
                          ),
                        )),
                        child: _buildModernMaintenanceCard(report, reportIndex),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: rows,
      ),
    );
  }

  int _getCrossAxisCount() {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 3; // Large screens (desktop/tablet landscape)
    if (width > 600) return 2; // Medium screens (tablet portrait)
    return 1; // Small screens (mobile)
  }

  Widget _buildModernMaintenanceCard(Map<String, dynamic> report, int index) {
    final status = report['status'] as String;
    final statusColor = statusColors[status] ?? const Color(0xFF6B7280);
    final supervisorData = report['supervisors'] as Map<String, dynamic>?;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor.withOpacity(0.1),
                    statusColor.withOpacity(0.05)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      report['school_name'] ??
                          report['title'] ??
                          'تقرير صيانة غير محدد',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      statusLabels[status] ?? status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Info chips in single row
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildCompactInfoChip(
                        supervisorData?['username'] ?? 'غير محدد',
                        Icons.person_outline,
                        const Color(0xFF10B981),
                      ),
                      _buildCompactInfoChip(
                        _formatDate(report['created_at']),
                        Icons.calendar_today_outlined,
                        const Color(0xFF6B7280),
                      ),
                    ],
                  ),

                  if (report['equipment_type'] != null ||
                      report['location'] != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (report['equipment_type'] != null)
                          _buildCompactInfoChip(
                            report['equipment_type'],
                            Icons.precision_manufacturing,
                            const Color(0xFF8B5CF6),
                          ),
                        if (report['location'] != null)
                          _buildCompactInfoChip(
                            report['location'],
                            Icons.location_on,
                            const Color(0xFF06B6D4),
                          ),
                      ],
                    ),
                  ],

                  if (report['description'] != null &&
                      report['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الوصف:',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            report['description'],
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.8),
                              height: 1.3,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Show completion date for completed reports
                  if (report['status'] == 'completed' ||
                      report['status'] == 'late_completed') ...[
                    if (report['closed_at'] != null) ...[
                      const SizedBox(height: 8),
                      _buildCompletionDateChip(
                        _formatDate(report['closed_at']),
                        Icons.check_circle_outline,
                        const Color(0xFF10B981),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInfoChip(String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionDateChip(String date, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            'اكتمل في: ',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              date,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
      case 'عالي':
        return const Color(0xFFEF4444);
      case 'medium':
      case 'متوسط':
        return const Color(0xFFF59E0B);
      case 'low':
      case 'منخفض':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
