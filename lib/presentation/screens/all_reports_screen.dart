import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/date_symbol_data_local.dart';
import 'dart:typed_data';
import '../../core/services/cache_service.dart';
import '../../core/services/admin_service.dart';
import '../widgets/common/standard_refresh_button.dart';

class AllReportsScreen extends StatefulWidget {
  final String? initialFilter;
  final String? supervisorId;
  final String? supervisorName;

  const AllReportsScreen({
    super.key,
    this.initialFilter,
    this.supervisorId,
    this.supervisorName,
  });

  @override
  State<AllReportsScreen> createState() => _AllReportsScreenState();
}

class _AllReportsScreenState extends State<AllReportsScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> reports = [];
  List<Map<String, dynamic>> filteredReports = [];
  bool isLoading = true;
  String? error;
  String selectedFilter = 'all';
  bool _isLoadingFromCache = false;

  final CacheService _cacheService = CacheService();
  final AdminService _adminService = AdminService(Supabase.instance.client);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, String>> filterOptions = [
    {'key': 'all', 'label': 'جميع البلاغات'},
    {'key': 'pending', 'label': 'جاري العمل'},
    {'key': 'completed', 'label': 'مكتملة'},
    {'key': 'late', 'label': 'متأخرة'},
    {'key': 'late_completed', 'label': 'منجزة متأخرة'},
  ];

  final Map<String, String> statusLabels = {
    'pending': 'في الانتظار',
    'in_progress': 'قيد التنفيذ',
    'completed': 'مكتمل',
    'late': 'متأخر',
    'late_completed': 'مكتمل متأخر',
  };

  final Map<String, Color> statusColors = {
    'pending': const Color(0xFF6B7280),
    'in_progress': const Color(0xFF3B82F6),
    'completed': const Color(0xFF10B981),
    'late': const Color(0xFFEF4444),
    'late_completed': const Color(0xFFFF9800),
  };

  final Map<String, IconData> statusIcons = {
    'pending': Icons.schedule_outlined,
    'in_progress': Icons.hourglass_empty_outlined,
    'completed': Icons.check_circle_outline,
    'late': Icons.warning_outlined,
    'late_completed': Icons.check_circle_outlined,
  };

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
    _loadReports();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadReports({bool forceRefresh = false}) async {
    try {
      // Always force refresh when filtering by supervisor ID to ensure accurate data
      if (widget.supervisorId != null && widget.supervisorId!.isNotEmpty) {
        forceRefresh = true;
      }

      // Check cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedReports = _cacheService
            .getCached<List<Map<String, dynamic>>>(CacheKeys.allReports);
        if (cachedReports != null) {
          setState(() {
            reports = cachedReports;
            _applyFilter();
            isLoading = false;
            _isLoadingFromCache = true;
          });
          _animationController.forward();

          // If cache is near expiry, refresh in background
          if (_cacheService.isNearExpiry(CacheKeys.allReports)) {
            _refreshReportsInBackground();
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
      List<Map<String, dynamic>> reportsData;

      if (isSuperAdmin) {
        // Super admin can see all reports or filter by specific supervisor
        var query = Supabase.instance.client
            .from('reports')
            .select('*, supervisors(username)');

        // If supervisorId is provided, filter by it
        if (widget.supervisorId != null && widget.supervisorId!.isNotEmpty) {
          // Use the supervisor_id directly as a string (UUID)
          query = query.eq('supervisor_id', widget.supervisorId!);
        }

        final response = await query.order('created_at', ascending: false);
        reportsData = List<Map<String, dynamic>>.from(response);
      } else {
        // Regular admin - filter by their assigned supervisors
        final adminSupervisorIds =
            await _adminService.getCurrentAdminSupervisorIds();
        if (adminSupervisorIds.isEmpty) {
          reportsData = [];
        } else {
          final response = await Supabase.instance.client
              .from('reports')
              .select('*, supervisors(username)')
              .inFilter('supervisor_id', adminSupervisorIds)
              .order('created_at', ascending: false);
          reportsData = List<Map<String, dynamic>>.from(response);
        }
      }

      // Cache the fresh data
      _cacheService.setCached(CacheKeys.allReports, reportsData);

      setState(() {
        reports = reportsData;
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

  Future<void> _refreshReportsInBackground() async {
    try {
      // Check if user is super admin
      final isSuperAdmin = await _adminService.isCurrentUserSuperAdmin();
      List<Map<String, dynamic>> reportsData;

      if (isSuperAdmin) {
        // Super admin can see all reports or filter by specific supervisor
        var query = Supabase.instance.client
            .from('reports')
            .select('*, supervisors(username)');

        // If supervisorId is provided, filter by it
        if (widget.supervisorId != null && widget.supervisorId!.isNotEmpty) {
          // Use the supervisor_id directly as a string (UUID)
          query = query.eq('supervisor_id', widget.supervisorId!);
        }

        final response = await query.order('created_at', ascending: false);
        reportsData = List<Map<String, dynamic>>.from(response);
      } else {
        // Regular admin - filter by their assigned supervisors
        final adminSupervisorIds =
            await _adminService.getCurrentAdminSupervisorIds();
        if (adminSupervisorIds.isEmpty) {
          reportsData = [];
        } else {
          final response = await Supabase.instance.client
              .from('reports')
              .select('*, supervisors(username)')
              .inFilter('supervisor_id', adminSupervisorIds)
              .order('created_at', ascending: false);
          reportsData = List<Map<String, dynamic>>.from(response);
        }
      }

      // Update cache
      _cacheService.setCached(CacheKeys.allReports, reportsData);

      // Update UI if the data has changed
      if (mounted && !_isDataEqual(reports, reportsData)) {
        setState(() {
          reports = reportsData;
          _applyFilter();
        });
      }
    } catch (e) {
      // Fail silently for background refresh
      debugPrint('Background refresh failed: $e');
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
    // Start with all reports
    List<Map<String, dynamic>> result = reports;

    // Filter by status if not 'all'
    if (selectedFilter != 'all') {
      result =
          result.where((report) => report['status'] == selectedFilter).toList();
    }

    // Filter by supervisor ID if provided
    if (widget.supervisorId != null && widget.supervisorId!.isNotEmpty) {
      result = result
          .where((report) => report['supervisor_id'] == widget.supervisorId)
          .toList();
    }

    filteredReports = result;
  }

  Future<void> _downloadReportsExcel() async {
    try {
      await initializeDateFormatting('ar');
      final excel = excel_lib.Excel.createExcel();
      final sheet = excel['البلاغات'];
      final dateFormat = intl.DateFormat('dd/MM/yyyy hh:mm a');

      // Header row - matching reports_screen format
      sheet.appendRow([
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
      ]);

      for (final report in filteredReports) {
        final supervisorData = report['supervisors'] as Map<String, dynamic>?;
        final createdAt = report['created_at'] != null
            ? DateTime.parse(report['created_at'])
            : DateTime.now();
        final scheduledDate = report['scheduled_date'] != null
            ? DateTime.parse(report['scheduled_date'])
            : createdAt;
        final closedAt = report['closed_at'] != null
            ? DateTime.parse(report['closed_at'])
            : null;

        sheet.appendRow([
          supervisorData?['username'] ?? 'غير محدد',
          report['school_name'] ?? report['title'] ?? 'غير محدد',
          report['description'] ?? '',
          _translatePriority(report['priority']),
          _translateStatus(report['status']),
          _translateType(report['type']),
          _translateReportSource(report['report_source']),
          dateFormat.format(createdAt),
          dateFormat.format(scheduledDate),
          closedAt != null ? dateFormat.format(closedAt) : '',
          report['completion_note'] ?? '',
        ]);
      }

      final excelBytes = excel.encode();
      if (excelBytes == null) return;

      await FileSaver.instance.saveFile(
        name: 'جميع_البلاغات',
        bytes: Uint8List.fromList(excelBytes),
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحميل ملف Excel بنجاح'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
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
      onPressed: _downloadReportsExcel,
      icon: const Icon(Icons.file_download_rounded),
      label: Text(
        selectedFilter == 'all'
            ? 'تحميل الكل (${filteredReports.length})'
            : 'تحميل المفلترة (${filteredReports.length})',
      ),
      backgroundColor: const Color(0xFF3B82F6),
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
        floatingActionButton: _buildFloatingActionButton(),
        body: CustomScrollView(
          slivers: [
            // Modern App Bar
            SliverAppBar.large(
              automaticallyImplyLeading: false,
              backgroundColor: colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              expandedHeight: 120,
              title: Text(
                'جميع البلاغات',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              actions: [
              
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: StandardRefreshButton(
                    onPressed: () => _loadReports(forceRefresh: true),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colorScheme.surface,
                        colorScheme.surface.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Filter Section
            if (!isLoading && error == null)
              SliverToBoxAdapter(
                child: _buildModernFilterSection(),
              ),

            // Content
            if (isLoading)
              SliverToBoxAdapter(child: _buildModernLoadingView())
            else if (error != null)
              SliverToBoxAdapter(child: _buildModernErrorView())
            else if (filteredReports.isEmpty)
              SliverToBoxAdapter(child: _buildModernEmptyView())
            else
              _buildModernReportsList(),
          ],
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
            'تصفية البلاغات',
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
                    'all', 'الجميع', reports.length, Icons.apps),
                _buildModernFilterChip(
                    'pending',
                    'قيد التنفيذ',
                    reports.where((r) => r['status'] == 'pending').length,
                    Icons.schedule),
                _buildModernFilterChip(
                    'completed',
                    'مكتملة',
                    reports.where((r) => r['status'] == 'completed').length,
                    Icons.check_circle),
                _buildModernFilterChip(
                    'late',
                    'متأخرة',
                    reports.where((r) => r['status'] == 'late').length,
                    Icons.warning_outlined),
                _buildModernFilterChip(
                    'late_completed',
                    'مكتملة متأخرة',
                    reports
                        .where((r) => r['status'] == 'late_completed')
                        .length,
                    Icons.check_circle_outlined),
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
              'جاري تحميل البلاغات...',
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
              onPressed: () => _loadReports(forceRefresh: true),
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
                    ? Icons.assignment_outlined
                    : statusIcons[selectedFilter],
                size: 64,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              selectedFilter == 'all'
                  ? 'لا توجد بلاغات'
                  : 'لا توجد بلاغات ${statusLabels[selectedFilter]}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'سيتم عرض البلاغات هنا عند إضافتها',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernReportsList() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final crossAxisCount = _getCrossAxisCount();

            // Build rows with elastic heights
            if (index % crossAxisCount == 0) {
              // Start of a new row
              final rowStartIndex = index;
              final rowEndIndex = (rowStartIndex + crossAxisCount - 1)
                  .clamp(0, filteredReports.length - 1);
              final reportsInRow =
                  filteredReports.sublist(rowStartIndex, rowEndIndex + 1);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: reportsInRow.asMap().entries.map((entry) {
                      final reportIndex = rowStartIndex + entry.key;
                      final report = entry.value;
                      final isLastInRow = entry.key == reportsInRow.length - 1;

                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(
                            left: isLastInRow ? 0 : 12,
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
                              child:
                                  _buildModernReportCard(report, reportIndex),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            } else {
              // Skip indices that are not row starts
              return const SizedBox.shrink();
            }
          },
          childCount: ((filteredReports.length / _getCrossAxisCount()).ceil() *
                  _getCrossAxisCount())
              .clamp(0, filteredReports.length),
        ),
      ),
    );
  }

  int _getCrossAxisCount() {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 3; // Large screens (desktop/tablet landscape)
    if (width > 600) return 2; // Medium screens (tablet portrait)
    return 1; // Small screens (mobile)
  }

  Widget _buildModernReportCard(Map<String, dynamic> report, int index) {
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
                          'بلاغ غير محدد',
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
                        _translatePriority(report['priority']),
                        Icons.priority_high_outlined,
                        report['priority'] == 'Emergency'
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF3B82F6),
                      ),
                      _buildCompactInfoChip(
                        _formatDate(report['created_at']),
                        Icons.calendar_today_outlined,
                        const Color(0xFF6B7280),
                      ),
                    ],
                  ),

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
}
