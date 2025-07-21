import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'admin_service.dart';

class WeeklyReportService {
  final SupabaseClient _client = Supabase.instance.client;
  
  /// Get all weeks in a given month (fixed 4 weeks structure)
  static List<Map<String, dynamic>> getWeeksInMonth(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    
    List<Map<String, dynamic>> weeks = [];
    
    // Fixed 4-week structure:
    // Week 1: 1-7
    // Week 2: 8-14  
    // Week 3: 15-21
    // Week 4: 22-end of month (28/29/30/31)
    
    final weekRanges = [
      [1, 7],   // Week 1
      [8, 14],  // Week 2
      [15, 21], // Week 3
      [22, lastDay.day], // Week 4 - until end of month
    ];
    
    for (int i = 0; i < weekRanges.length; i++) {
      final startDay = weekRanges[i][0];
      final endDay = weekRanges[i][1];
      
      final weekStart = DateTime(year, month, startDay);
      final weekEnd = DateTime(year, month, endDay);
      
      weeks.add({
        'weekNumber': i + 1,
        'startDate': weekStart,
        'endDate': weekEnd,
        'label': 'الأسبوع ${i + 1} (${DateFormat('dd/MM').format(weekStart)} - ${DateFormat('dd/MM').format(weekEnd)})',
      });
    }
    
    return weeks;
  }

  /// Get month data for monthly reports
  static Map<String, dynamic> getMonthData(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    
    return {
      'startDate': firstDay,
      'endDate': lastDay,
      'label': '${_getMonthName(month)} $year',
    };
  }

  /// Get month name in Arabic
  static String _getMonthName(int month) {
    const monthNames = [
      'يناير', 'فبراير', 'مارس', 'أبريل',
      'مايو', 'يونيو', 'يوليو', 'أغسطس',
      'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return monthNames[month - 1];
  }
  
  /// Generate weekly report data
  Future<Map<String, dynamic>> generateWeeklyReportData({
    required DateTime startDate,
    required DateTime endDate,
    AdminService? adminService,
  }) async {
    try {
      List<Map<String, dynamic>> reports;
      List<Map<String, dynamic>> maintenance;
      
      // Check if admin filtering is needed
      if (adminService != null) {
        final isSuperAdmin = await adminService.isCurrentUserSuperAdmin();
        
        if (isSuperAdmin) {
          // Super admin gets all data
          final reportsResponse = await _client
              .from('reports')
              .select('*, supervisors(username)')
              .gte('created_at', startDate.toIso8601String())
              .lte('created_at', endDate.toIso8601String())
              .order('created_at', ascending: false);

          reports = List<Map<String, dynamic>>.from(reportsResponse);
          
          final maintenanceResponse = await _client
              .from('maintenance_reports')
              .select('*, supervisors(username)')
              .gte('created_at', startDate.toIso8601String())
              .lte('created_at', endDate.toIso8601String())
              .order('created_at', ascending: false);

          maintenance = List<Map<String, dynamic>>.from(maintenanceResponse);
        } else {
          // Regular admin - filter by assigned supervisors
          final adminSupervisorIds = await adminService.getCurrentAdminSupervisorIds();
          
          if (adminSupervisorIds.isEmpty) {
            // No supervisors assigned, return empty data
            reports = [];
            maintenance = [];
          } else {
            // Filter reports by assigned supervisors
            final reportsResponse = await _client
                .from('reports')
                .select('*, supervisors(username)')
                .gte('created_at', startDate.toIso8601String())
                .lte('created_at', endDate.toIso8601String())
                .inFilter('supervisor_id', adminSupervisorIds)
                .order('created_at', ascending: false);

            reports = List<Map<String, dynamic>>.from(reportsResponse);
            
            // Filter maintenance by assigned supervisors
            final maintenanceResponse = await _client
                .from('maintenance_reports')
                .select('*, supervisors(username)')
                .gte('created_at', startDate.toIso8601String())
                .lte('created_at', endDate.toIso8601String())
                .inFilter('supervisor_id', adminSupervisorIds)
                .order('created_at', ascending: false);

            maintenance = List<Map<String, dynamic>>.from(maintenanceResponse);
          }
        }
      } else {
        // No admin service provided, get all data (backward compatibility)
        final reportsResponse = await _client
            .from('reports')
            .select('*, supervisors(username)')
            .gte('created_at', startDate.toIso8601String())
            .lte('created_at', endDate.toIso8601String())
            .order('created_at', ascending: false);

        reports = List<Map<String, dynamic>>.from(reportsResponse);
        
        final maintenanceResponse = await _client
            .from('maintenance_reports')
            .select('*, supervisors(username)')
            .gte('created_at', startDate.toIso8601String())
            .lte('created_at', endDate.toIso8601String())
            .order('created_at', ascending: false);

        maintenance = List<Map<String, dynamic>>.from(maintenanceResponse);
      }
      
      // Calculate statistics
      final statistics = _calculateWeeklyStatistics(reports, maintenance);
      
      return {
        'reports': reports,
        'maintenance': maintenance,
        'statistics': statistics,
        'startDate': startDate,
        'endDate': endDate,
      };
    } catch (e) {
      debugPrint('Error generating weekly report data: $e');
      rethrow;
    }
  }
  
  /// Calculate weekly statistics
  Map<String, dynamic> _calculateWeeklyStatistics(
    List<Map<String, dynamic>> reports,
    List<Map<String, dynamic>> maintenance,
  ) {
    // Reports statistics
    final totalReports = reports.length;
    final completedReports = reports.where((r) => r['status'] == 'completed').length;
    final pendingReports = reports.where((r) => r['status'] == 'pending').length;
    final inProgressReports = reports.where((r) => r['status'] == 'in_progress').length;
    final lateReports = reports.where((r) => r['status'] == 'late').length;
    final lateCompletedReports = reports.where((r) => r['status'] == 'late_completed').length;
    
    // Reports by type
    final civilReports = reports.where((r) => r['type'] == 'Civil').length;
    final plumbingReports = reports.where((r) => r['type'] == 'Plumbing').length;
    final electricityReports = reports.where((r) => r['type'] == 'Electricity').length;
    final acReports = reports.where((r) => r['type'] == 'AC').length;
    final fireReports = reports.where((r) => r['type'] == 'Fire').length;
    
    // Reports by priority (flexible matching)
    final emergencyReports = reports.where((r) {
      final priority = r['priority']?.toString()?.toLowerCase()?.trim() ?? '';
      return priority == 'emergency' || priority == 'urgent' || priority.contains('طارئ');
    }).length;
    final routineReports = reports.where((r) {
      final priority = r['priority']?.toString()?.toLowerCase()?.trim() ?? '';
      return priority == 'routine' || priority == 'normal' || priority.contains('روتيني');
    }).length;
    
    // Reports by source
    final unifierReports = reports.where((r) => r['report_source'] == 'unifier').length;
    final checklistReports = reports.where((r) => r['report_source'] == 'checklist').length;
    final consultantReports = reports.where((r) => r['report_source'] == 'consultant').length;
    
    // Maintenance statistics
    final totalMaintenance = maintenance.length;
    final completedMaintenance = maintenance.where((m) => m['status'] == 'completed').length;
    final pendingMaintenance = maintenance.where((m) => m['status'] == 'pending').length;
    final inProgressMaintenance = maintenance.where((m) => m['status'] == 'in_progress').length;
    
    // Overall completion rate
    final totalWork = totalReports + totalMaintenance;
    final completedWork = completedReports + completedMaintenance;
    final completionRate = totalWork > 0 ? (completedWork / totalWork * 100) : 0.0;
    
    // Get unique supervisors
    final supervisorNames = <String>{};
    for (final report in reports) {
      final supervisor = report['supervisors'];
      if (supervisor != null && supervisor['username'] != null) {
        supervisorNames.add(supervisor['username']);
      }
    }
    for (final main in maintenance) {
      final supervisor = main['supervisors'];
      if (supervisor != null && supervisor['username'] != null) {
        supervisorNames.add(supervisor['username']);
      }
    }
    
    return {
      // Overall statistics
      'totalReports': totalReports,
      'totalMaintenance': totalMaintenance,
      'totalWork': totalWork,
      'completionRate': completionRate,
      'activeSupervisors': supervisorNames.length,
      
      // Reports by status
      'completedReports': completedReports,
      'pendingReports': pendingReports,
      'inProgressReports': inProgressReports,
      'lateReports': lateReports,
      'lateCompletedReports': lateCompletedReports,
      
      // Reports by type
      'civilReports': civilReports,
      'plumbingReports': plumbingReports,
      'electricityReports': electricityReports,
      'acReports': acReports,
      'fireReports': fireReports,
      
      // Reports by priority
      'emergencyReports': emergencyReports,
      'routineReports': routineReports,
      
      // Reports by source
      'unifierReports': unifierReports,
      'checklistReports': checklistReports,
      'consultantReports': consultantReports,
      
      // Maintenance by status
      'completedMaintenance': completedMaintenance,
      'pendingMaintenance': pendingMaintenance,
      'inProgressMaintenance': inProgressMaintenance,
    };
  }
  
  /// Generate Excel report
  Future<Uint8List> generateWeeklyExcelReport({
    required Map<String, dynamic> reportData,
    required String weekLabel,
  }) async {
    // Create a fresh Excel workbook
    final excel = excel_lib.Excel.createExcel();
    excel.delete('Sheet1');
    
    // Create our 3 main sheets FIRST - this ensures they appear at the beginning
    await _createSummarySheet(excel, reportData, weekLabel);
    await _createDetailedReportsSheet(excel, reportData);
    await _createDetailedMaintenanceSheet(excel, reportData);
    
    // Now check if default sheet exists and move it to the end by creating a dummy sheet
    // This pushes any default sheet to the last position
    try {
      final allSheets = excel.sheets.keys.toList();
      debugPrint('All sheets after creating our content: $allSheets');
      
      // If Sheet1 exists and it's not one of our sheets, it will be at the end naturally
      // But let's ensure our sheets are properly ordered by creating them in the right sequence
      
      // Check if there's an unwanted default sheet
      final defaultSheetNames = ['Sheet1', 'Sheet 1', 'Worksheet'];
      bool hasDefaultSheet = false;
      
      for (final defaultName in defaultSheetNames) {
        if (excel.sheets.containsKey(defaultName)) {
          hasDefaultSheet = true;
          debugPrint('Found default sheet: $defaultName - it will appear last');
          break;
        }
      }
      
      if (hasDefaultSheet) {
        // Create a temporary sheet to push default to the end, then delete temp
        final tempSheet = excel['_temp_'];
        excel.delete('_temp_');
      }
      
    } catch (e) {
      debugPrint('Sheet ordering attempt: $e');
    }
    
    // Verify final sheet order
    final finalSheets = excel.sheets.keys.toList();
    debugPrint('Final sheets in order: $finalSheets (count: ${finalSheets.length})');
    
    // Encode and return
    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Failed to generate Excel file');
    }
    
    return Uint8List.fromList(bytes);
  }
  
  /// Create professionally formatted summary sheet with RTL support by overriding default Sheet1
  Future<void> _createSummarySheetOverride(
    excel_lib.Excel excel,
    Map<String, dynamic> reportData,
    String weekLabel,
  ) async {
    // Create the Arabic summary sheet directly
    final sheet = excel['ملخص_الأسبوع'];
    
    final statistics = reportData['statistics'] as Map<String, dynamic>;
    final startDate = reportData['startDate'] as DateTime;
    final endDate = reportData['endDate'] as DateTime;
    
    // Configure sheet for RTL with proper settings
    _configureSheetRTL(sheet);
    
    int row = 0;
    
    // Create title section
    _createTitleSection(sheet, weekLabel, startDate, endDate, row);
    row += 5;
    
    // Create key metrics section with progress indicators
    _createKeyMetricsSection(sheet, statistics, row);
    row += 10;
    
    // Create breakdown sections
    _createBreakdownSections(sheet, statistics, row);
    
    // Set optimal column widths
    _setColumnWidths(sheet);
  }

  /// Create professionally formatted summary sheet with RTL support
  Future<void> _createSummarySheet(
    excel_lib.Excel excel,
    Map<String, dynamic> reportData,
    String weekLabel,
  ) async {
    final sheet = excel['ملخص_الأسبوع'];
    final statistics = reportData['statistics'] as Map<String, dynamic>;
    final startDate = reportData['startDate'] as DateTime;
    final endDate = reportData['endDate'] as DateTime;
    
    // Configure sheet for RTL
    sheet.isRTL = true;
    
    int row = 0;
    
    // Create title section
    _createTitleSection(sheet, weekLabel, startDate, endDate, row);
    row += 5;
    
    // Create key metrics section with progress indicators
    _createKeyMetricsSection(sheet, statistics, row);
    row += 10;
    
    // Create breakdown sections
    _createBreakdownSections(sheet, statistics, row);
    
    // Set optimal column widths
    _setColumnWidths(sheet);
  }
  
  void _createTitleSection(excel_lib.Sheet sheet, String weekLabel, DateTime startDate, DateTime endDate, int startRow) {
    // Main title
    final titleCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow));
    titleCell.value = 'تقرير أسبوعي - نظام صيانة المدارس';
    titleCell.cellStyle = excel_lib.CellStyle(
      bold: true,
      fontSize: 18,
      horizontalAlign: excel_lib.HorizontalAlign.Center,
      verticalAlign: excel_lib.VerticalAlign.Center,
      backgroundColorHex: 'FF1E40AF',
      fontColorHex: 'FFFFFFFF',
    );
    sheet.merge(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow), 
               excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: startRow));
    
    // Week label
    final weekCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow + 2));
    weekCell.value = weekLabel;
    weekCell.cellStyle = excel_lib.CellStyle(
      bold: true,
      fontSize: 14,
      horizontalAlign: excel_lib.HorizontalAlign.Center,
      backgroundColorHex: 'FFF3F4F6',
    );
    sheet.merge(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow + 2), 
               excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: startRow + 2));
    
    // Date range
    final dateCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow + 3));
    dateCell.value = 'من ${DateFormat('dd/MM/yyyy').format(startDate)} إلى ${DateFormat('dd/MM/yyyy').format(endDate)}';
    dateCell.cellStyle = excel_lib.CellStyle(
      fontSize: 12,
      horizontalAlign: excel_lib.HorizontalAlign.Center,
      backgroundColorHex: 'FFF9FAFB',
    );
    sheet.merge(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow + 3), 
               excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: startRow + 3));
  }
  
  void _createKeyMetricsSection(excel_lib.Sheet sheet, Map<String, dynamic> statistics, int startRow) {
    // Section header
    final headerCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow));
    headerCell.value = '📊 المؤشرات الرئيسية';
    headerCell.cellStyle = excel_lib.CellStyle(
      bold: true,
      fontSize: 16,
      horizontalAlign: excel_lib.HorizontalAlign.Center,
      backgroundColorHex: 'FF374151',
      fontColorHex: 'FFFFFFFF',
    );
    sheet.merge(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow), 
               excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: startRow));
    
    int row = startRow + 2;
    
    // Key metrics with colored backgrounds
    final completionRate = statistics['completionRate'] as double;
    final metrics = [
      {
        'label': 'إجمالي البلاغات',
        'value': '${statistics['totalReports']}',
        'color': 'FF3B82F6',
        'textColor': 'FFFFFFFF',
      },
      {
        'label': 'إجمالي أعمال الصيانة',
        'value': '${statistics['totalMaintenance']}',
        'color': 'FF10B981',
        'textColor': 'FFFFFFFF',
      },
      {
        'label': 'معدل الإنجاز',
        'value': '${completionRate.toStringAsFixed(1)}%',
        'color': completionRate >= 80 ? 'FF059669' : completionRate >= 60 ? 'FFF59E0B' : 'FFDC2626',
        'textColor': 'FFFFFFFF',
      },
    ];
    
    for (int i = 0; i < metrics.length; i++) {
      final metric = metrics[i];
      
      // Label
      final labelCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
      labelCell.value = metric['label'];
      labelCell.cellStyle = excel_lib.CellStyle(
        bold: true,
        fontSize: 14,
        horizontalAlign: excel_lib.HorizontalAlign.Right,
        backgroundColorHex: 'FFEBEBEB',
      );
      sheet.merge(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row), 
                 excel_lib.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row));
      
      // Value with color coding
      final valueCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row));
      valueCell.value = metric['value'];
      valueCell.cellStyle = excel_lib.CellStyle(
        bold: true,
        fontSize: 14,
        horizontalAlign: excel_lib.HorizontalAlign.Center,
        backgroundColorHex: metric['color'] as String,
        fontColorHex: metric['textColor'] as String,
      );
      sheet.merge(excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row), 
                 excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row));
      
      row += 2;
    }
  }
  
  void _createBreakdownSections(excel_lib.Sheet sheet, Map<String, dynamic> statistics, int startRow) {
    int row = startRow;
    
    // Status breakdown
    _createStatusBreakdown(sheet, statistics, row);
    row += 12;
    
    // Type breakdown
    _createTypeBreakdown(sheet, statistics, row);
    row += 10;
    
    // Priority breakdown
    _createPriorityBreakdown(sheet, statistics, row);
  }
  
  void _createStatusBreakdown(excel_lib.Sheet sheet, Map<String, dynamic> statistics, int startRow) {
    // Header
    final headerCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow));
    headerCell.value = '📈 البلاغات حسب الحالة';
    headerCell.cellStyle = excel_lib.CellStyle(
      bold: true,
      fontSize: 14,
      horizontalAlign: excel_lib.HorizontalAlign.Center,
      backgroundColorHex: 'FF1F2937',
      fontColorHex: 'FFFFFFFF',
    );
    sheet.merge(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow), 
               excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: startRow));
    
    int row = startRow + 2;
    final statusData = [
      ['✅ مكتملة', statistics['completedReports'], 'FF10B981'],
      ['⏳ قيد التنفيذ', statistics['pendingReports'] + statistics['inProgressReports'], 'FFF59E0B'],
      ['⚠️ متأخرة', statistics['lateReports'], 'ff8c00'],
      ['🔄 مكتملة متأخرة', statistics['lateCompletedReports'], 'ff8c00'],
    ];
    
    for (final status in statusData) {
      _createDataRow(sheet, status[0] as String, status[1] as int, status[2] as String, row);
      row += 2;
    }
  }
  
  void _createTypeBreakdown(excel_lib.Sheet sheet, Map<String, dynamic> statistics, int startRow) {
    // Header
    final headerCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow));
    headerCell.value = '🔧 البلاغات حسب النوع';
    headerCell.cellStyle = excel_lib.CellStyle(
      bold: true,
      fontSize: 14,
      horizontalAlign: excel_lib.HorizontalAlign.Center,
      backgroundColorHex: 'FF7C3AED',
      fontColorHex: 'FFFFFFFF',
    );
    sheet.merge(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow), 
               excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: startRow));
    
    int row = startRow + 2;
    final typeData = [
      ['🏗️ مدني', statistics['civilReports'], 'FF6B7280'],
      ['🚰 سباكة', statistics['plumbingReports'], 'FF2563EB'],
      ['⚡ كهرباء', statistics['electricityReports'], 'FFFBBF24'],
      ['❄️ تكييف', statistics['acReports'], 'FF06B6D4'],
      ['🔥 حريق', statistics['fireReports'], 'FFEF4444'],
    ];
    
    for (final type in typeData) {
      _createDataRow(sheet, type[0] as String, type[1] as int, type[2] as String, row);
      row += 2;
    }
  }
  
  void _createPriorityBreakdown(excel_lib.Sheet sheet, Map<String, dynamic> statistics, int startRow) {
    // Header
    final headerCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow));
    headerCell.value = '🚨 البلاغات حسب الأولوية';
    headerCell.cellStyle = excel_lib.CellStyle(
      bold: true,
      fontSize: 14,
      horizontalAlign: excel_lib.HorizontalAlign.Center,
      backgroundColorHex: 'FFDC2626',
      fontColorHex: 'FFFFFFFF',
    );
    sheet.merge(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow), 
               excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: startRow));
    
    int row = startRow + 2;
    final priorityData = [
      ['🔴 طارئ', statistics['emergencyReports'], 'FFDC2626'],
      ['🟡 روتيني', statistics['routineReports'], 'FF10B981'],
    ];
    
    for (final priority in priorityData) {
      _createDataRow(sheet, priority[0] as String, priority[1] as int, priority[2] as String, row);
      row += 2;
    }
  }
  
  void _createDataRow(excel_lib.Sheet sheet, String label, int value, String colorHex, int row) {
    // Label
    final labelCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    labelCell.value = label;
    labelCell.cellStyle = excel_lib.CellStyle(
      bold: true,
      fontSize: 12,
      horizontalAlign: excel_lib.HorizontalAlign.Right,
      backgroundColorHex: 'FFF9FAFB',
    );
    sheet.merge(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row), 
               excel_lib.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row));
    
    // Value
    final valueCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row));
    valueCell.value = value;
    valueCell.cellStyle = excel_lib.CellStyle(
      bold: true,
      fontSize: 12,
      horizontalAlign: excel_lib.HorizontalAlign.Center,
      backgroundColorHex: colorHex,
      fontColorHex: 'FFFFFFFF',
    );
    sheet.merge(excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row), 
               excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row));
  }
  
  void _setColumnWidths(excel_lib.Sheet sheet) {
    sheet.setColWidth(0, 15);
    sheet.setColWidth(1, 15);
    sheet.setColWidth(2, 15);
    sheet.setColWidth(3, 15);
    sheet.setColWidth(4, 12);
    sheet.setColWidth(5, 12);
  }
  
  /// Configure consistent RTL settings for all sheets
  void _configureSheetRTL(excel_lib.Sheet sheet) {
    sheet.isRTL = true;
    // Additional RTL configurations can be added here if needed
  }
  
  /// Check if a sheet is empty (has no meaningful content)
  bool _isSheetEmpty(excel_lib.Sheet sheet) {
    try {
      // Check if sheet has any cells with actual content
      for (int row = 0; row < sheet.maxRows; row++) {
        for (int col = 0; col < sheet.maxCols; col++) {
          final cell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
          if (cell.value != null && cell.value.toString().trim().isNotEmpty) {
            return false; // Found content, not empty
          }
        }
      }
      return true; // No content found, sheet is empty
    } catch (e) {
      // If we can't check, assume it's not empty to be safe
      return false;
    }
  }
  

  
  /// Create professionally formatted detailed reports sheet with RTL support
  Future<void> _createDetailedReportsSheet(
    excel_lib.Excel excel,
    Map<String, dynamic> reportData,
  ) async {
    final sheet = excel['تفاصيل_البلاغات'];
    final reports = reportData['reports'] as List<Map<String, dynamic>>;
    
    // Configure for RTL
    sheet.isRTL = true;
    
    // Headers in Arabic with icons
    final headers = [
      '👤 اسم المشرف',
      '🏫 اسم المدرسة',
      '📝 وصف البلاغ',
      '⚡ الأولوية',
      '📊 الحالة',
      '🔧 النوع',
      '👥 المصدر',
      '📅 تاريخ الإنشاء',
      '⏰ تاريخ الجدولة',
      '✅ تاريخ الإغلاق',
      '💬 ملاحظة الإغلاق',
    ];
    
    // Create title row
    final titleCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = '📋 تفاصيل البلاغات الأسبوعية';
    titleCell.cellStyle = excel_lib.CellStyle(
      bold: true,
      fontSize: 16,
      horizontalAlign: excel_lib.HorizontalAlign.Center,
      backgroundColorHex: 'FF1F2937',
      fontColorHex: 'FFFFFFFF',
    );
    sheet.merge(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0), 
               excel_lib.CellIndex.indexByColumnRow(columnIndex: headers.length - 1, rowIndex: 0));
    
    // Create header row with professional styling
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2));
      cell.value = headers[i];
      cell.cellStyle = excel_lib.CellStyle(
        bold: true,
        fontSize: 11,
        backgroundColorHex: 'FF374151',
        fontColorHex: 'FFFFFFFF',
        horizontalAlign: excel_lib.HorizontalAlign.Center,
        verticalAlign: excel_lib.VerticalAlign.Center,
      );
    }
    
    // Data rows with status-based coloring
    for (int i = 0; i < reports.length; i++) {
      final report = reports[i];
      final supervisorData = report['supervisors'] as Map<String, dynamic>?;
      
      final rowData = [
        supervisorData?['username'] ?? 'غير محدد',
        report['school_name'] ?? '',
        report['description'] ?? '',
        _getPriorityLabel(report['priority']),
        _getStatusLabel(report['status']),
        _getTypeLabel(report['type']),
        _getSourceLabel(report['report_source'] ?? 'يونيفاير'),
        report['created_at'] != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(report['created_at'])) : '',
        report['scheduled_date'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(report['scheduled_date'])) : '',
        report['closed_at'] != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(report['closed_at'])) : '',
        report['completion_note'] ?? '',
      ];
      
      // Color coding based on status and priority
      String backgroundColor;
      final status = report['status']?.toString() ?? '';
      final priority = report['priority']?.toString()?.toLowerCase() ?? '';
      
      if (status == 'completed') {
        backgroundColor = 'FFF0FDF4'; // Light green
      } else if (status == 'late' || status == 'late_completed') {
        backgroundColor = 'FFFEF2F2'; // Light red
      } else if (priority.contains('emergency') || priority.contains('urgent') || priority.contains('طارئ')) {
        backgroundColor = 'FFFFF1F2'; // Light pink for emergency
      } else {
        backgroundColor = i % 2 == 0 ? 'FFF9FAFB' : 'FFFFFFFF'; // Alternating
      }
      
      for (int j = 0; j < rowData.length; j++) {
        final cell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 3));
        cell.value = rowData[j];
        cell.cellStyle = excel_lib.CellStyle(
          fontSize: 10,
          backgroundColorHex: backgroundColor,
          horizontalAlign: excel_lib.HorizontalAlign.Right,
          verticalAlign: excel_lib.VerticalAlign.Top,
        );
      }
    }
    
    // Set optimal column widths for RTL
    sheet.setColWidth(0, 18); // Supervisor
    sheet.setColWidth(1, 25); // School
    sheet.setColWidth(2, 35); // Description
    sheet.setColWidth(3, 15); // Priority
    sheet.setColWidth(4, 15); // Status
    sheet.setColWidth(5, 15); // Type
    sheet.setColWidth(6, 15); // Source
    sheet.setColWidth(7, 20); // Created
    sheet.setColWidth(8, 18); // Scheduled
    sheet.setColWidth(9, 20); // Closed
    sheet.setColWidth(10, 30); // Note
  }
  
  /// Create professionally formatted detailed maintenance sheet with RTL support
  Future<void> _createDetailedMaintenanceSheet(
    excel_lib.Excel excel,
    Map<String, dynamic> reportData,
  ) async {
    final sheet = excel['تفاصيل_الصيانة'];
    final maintenance = reportData['maintenance'] as List<Map<String, dynamic>>;
    
    // Configure for RTL
    sheet.isRTL = true;
    
    // Headers with icons
    final headers = [
      '👤 اسم المشرف',
      '🏫 اسم المدرسة',
      '🔧 وصف الصيانة',
      '📊 الحالة',
      '📅 تاريخ الإنشاء',
      '⏰ تاريخ الجدولة',
      '✅ تاريخ الإغلاق',
      '💬 الملاحظات',
    ];
    
    // Create title row
    final titleCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = '🔧 تفاصيل أعمال الصيانة الأسبوعية';
    titleCell.cellStyle = excel_lib.CellStyle(
      bold: true,
      fontSize: 16,
      horizontalAlign: excel_lib.HorizontalAlign.Center,
      backgroundColorHex: 'FF059669',
      fontColorHex: 'FFFFFFFF',
    );
    sheet.merge(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0), 
               excel_lib.CellIndex.indexByColumnRow(columnIndex: headers.length - 1, rowIndex: 0));
    
    // Create header row with professional styling
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2));
      cell.value = headers[i];
      cell.cellStyle = excel_lib.CellStyle(
        bold: true,
        fontSize: 11,
        backgroundColorHex: 'FF047857',
        fontColorHex: 'FFFFFFFF',
        horizontalAlign: excel_lib.HorizontalAlign.Center,
        verticalAlign: excel_lib.VerticalAlign.Center,
      );
    }
    
    // Data rows with status-based coloring
    for (int i = 0; i < maintenance.length; i++) {
      final main = maintenance[i];
      final supervisorData = main['supervisors'] as Map<String, dynamic>?;
      
      final rowData = [
        supervisorData?['username'] ?? 'غير محدد',
        main['school_name'] ?? '',
        main['description'] ?? '',
        _getStatusLabel(main['status']),
        main['created_at'] != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(main['created_at'])) : '',
        main['scheduled_date'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(main['scheduled_date'])) : '',
        main['closed_at'] != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(main['closed_at'])) : '',
        main['closure_note'] ?? '',
      ];
      
      // Color coding based on status
      String backgroundColor;
      final status = main['status']?.toString() ?? '';
      
      if (status == 'completed') {
        backgroundColor = 'FFF0FDF4'; // Light green
      } else if (status == 'late' || status == 'late_completed') {
        backgroundColor = 'FFB22C'; // Light orange
      } else if (status == 'in_progress') {
        backgroundColor = 'FFFEF3C7'; // Light yellow
      } else {
        backgroundColor = i % 2 == 0 ? 'FFF0FDF4' : 'FFFFFFFF'; // Alternating green theme
      }
      
      for (int j = 0; j < rowData.length; j++) {
        final cell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 3));
        cell.value = rowData[j];
        cell.cellStyle = excel_lib.CellStyle(
          fontSize: 10,
          backgroundColorHex: backgroundColor,
          horizontalAlign: excel_lib.HorizontalAlign.Right,
          verticalAlign: excel_lib.VerticalAlign.Top,
        );
      }
    }
    
    // Set optimal column widths for RTL
    sheet.setColWidth(0, 18); // Supervisor
    sheet.setColWidth(1, 25); // School
    sheet.setColWidth(2, 35); // Description
    sheet.setColWidth(3, 18); // Status
    sheet.setColWidth(4, 20); // Created
    sheet.setColWidth(5, 18); // Scheduled
    sheet.setColWidth(6, 20); // Closed
    sheet.setColWidth(7, 35); // Notes
  }
  

  
  /// Helper methods for labels
  String _getPriorityLabel(String? priority) {
    if (priority == null) return '';
    
    final priorityLower = priority.toLowerCase().trim();
    switch (priorityLower) {
      case 'emergency':
      
      case 'طارئ':
        return 'طارئ';
      case 'routine':
      
      
        return 'روتيني';
      default:
        // If it's already in Arabic, keep it, otherwise translate
        if (priorityLower.contains(RegExp(r'[طارئروتيني]'))) {
          return priority;
        }
        return priority.isNotEmpty ? priority : 'غير محدد';
    }
  }
  
  String _getStatusLabel(String? status) {
    switch (status) {
      case 'pending':
      case 'in_progress':
        return 'قيد التنفيذ';
      case 'completed':
        return 'مكتمل';
      case 'late':
        return 'متأخر';
      case 'late_completed':
        return 'مكتمل متأخر';
      default:
        return status ?? '';
    }
  }
  
  String _getTypeLabel(String? type) {
    switch (type) {
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
        return type ?? '';
    }
  }
  
  String _getSourceLabel(String? source) {
    switch (source) {
      case 'unifier':
        return 'يونيفاير';
      case 'check_list':
        return 'تشيك ليست';
      case 'consultant':
        return 'استشاري';
      default:
        return source ?? '';
    }
  }
  
  /// Generate and download weekly report
  Future<void> generateAndDownloadWeeklyReport({
    required DateTime startDate,
    required DateTime endDate,
    required String weekLabel,
    AdminService? adminService,
  }) async {
    // Generate report data
    final reportData = await generateWeeklyReportData(
      startDate: startDate,
      endDate: endDate,
      adminService: adminService,
    );
    
    // Generate Excel file
    final excelBytes = await generateWeeklyExcelReport(
      reportData: reportData,
      weekLabel: weekLabel,
    );
    
    // Download file
    final fileName = 'تقرير_أسبوعي_${DateFormat('yyyy_MM_dd').format(startDate)}_${DateFormat('yyyy_MM_dd').format(endDate)}.xlsx';
    
    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: excelBytes,
      ext: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }

  Future<void> generateAndDownloadMonthlyReport({
    required DateTime startDate,
    required DateTime endDate,
    required String monthLabel,
    AdminService? adminService,
  }) async {
    // Generate report data
    final reportData = await generateWeeklyReportData(
      startDate: startDate,
      endDate: endDate,
      adminService: adminService,
    );
    
    // Generate Excel file
    final excelBytes = await generateWeeklyExcelReport(
      reportData: reportData,
      weekLabel: monthLabel,
    );
    
    // Download file
    final fileName = 'تقرير_شهري_${DateFormat('yyyy_MM').format(startDate)}.xlsx';
    
    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: excelBytes,
      ext: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }
} 