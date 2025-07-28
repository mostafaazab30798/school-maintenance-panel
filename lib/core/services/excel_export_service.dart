import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/maintenance_count.dart';
import '../../data/models/damage_count.dart';
import '../../data/repositories/maintenance_count_repository.dart';
import '../../data/repositories/damage_count_repository.dart';
// Web-specific imports - conditional
import 'dart:html' as html;
// Conditional import for Syncfusion - only import if available
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as syncfusion;

class ExcelExportService {
  final MaintenanceCountRepository _repository;
  final DamageCountRepository? _damageRepository;
  
  // Global state to prevent multiple simultaneous downloads
  static bool _isDownloading = false;

  ExcelExportService(this._repository,
      {DamageCountRepository? damageRepository})
      : _damageRepository = damageRepository;

  Future<void> exportAllMaintenanceCounts() async {
    // Prevent multiple simultaneous downloads
    if (_isDownloading) {
      throw Exception('Download already in progress. Please wait.');
    }
    
    _isDownloading = true;
    
    // Performance monitoring
    final stopwatch = Stopwatch()..start();
    print('⏱️ Starting maintenance counts export at ${DateTime.now()}');
    
    try {
      // Request storage permission for Android (not needed on web)
      if (!kIsWeb) {
        try {
          if (Platform.isAndroid) {
            final permission = await Permission.storage.request();
            if (!permission.isGranted) {
              throw Exception('Storage permission denied');
            }
          }
        } catch (e) {
          // Platform check failed, likely on web - continue without permission check
          print('Platform check failed: $e');
        }
      }

      // Get all maintenance counts and school names with timeout
      final allCounts = await _getAllMaintenanceCounts()
          .timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Database query timeout - taking too long to fetch data');
      });
      
      final schoolNames = await _getSchoolNamesMap()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('School names query timeout');
      });

      print('Total maintenance counts: ${allCounts.length}'); // Debug
      for (final count in allCounts) {
        print('Count ID: ${count.id}, Heater entries: ${count.heaterEntries}'); // Debug
      }

      if (allCounts.isEmpty) {
        throw Exception('No maintenance counts found');
      }

      // Check if dataset is too large and suggest simplified export
      if (allCounts.length > 100) {
        print('⚠️ Large dataset detected: ${allCounts.length} records');
        print('💡 Consider using simplified export for better performance');
      }

      // Check if Syncfusion is available and try it first
      bool syncfusionAvailable = false;
      try {
        // Test if Syncfusion is available by creating a workbook
        final testWorkbook = syncfusion.Workbook();
        testWorkbook.dispose();
        syncfusionAvailable = true;
        print('✅ Syncfusion is available and working');
      } catch (e) {
        print('❌ Syncfusion not available: $e');
        print('📋 This could be due to:');
        print('   - Library not properly installed');
        print('   - Version compatibility issues');
        print('   - Platform-specific problems');
        syncfusionAvailable = false;
      }

      if (syncfusionAvailable) {
        try {
          // Add timeout to prevent hanging
          await _exportMaintenanceCountsSyncfusion(allCounts, schoolNames)
              .timeout(const Duration(minutes: 2), onTimeout: () {
            throw Exception('Export timeout - taking too long to generate file');
          });
        } catch (syncfusionError) {
          print('Syncfusion export failed: $syncfusionError');
          print('Falling back to excel package...');
          await _exportMaintenanceCountsExcelPackage(allCounts, schoolNames)
              .timeout(const Duration(minutes: 1), onTimeout: () {
            throw Exception('Export timeout - taking too long to generate file');
          });
        }
      } else {
        // Use excel package directly if Syncfusion is not available
        print('Using excel package fallback...');
        await _exportMaintenanceCountsExcelPackage(allCounts, schoolNames)
            .timeout(const Duration(minutes: 1), onTimeout: () {
          throw Exception('Export timeout - taking too long to generate file');
        });
      }
    } catch (e) {
      print('❌ Export error: $e');
      throw Exception('Failed to export Excel: ${e.toString()}');
    } finally {
      stopwatch.stop();
      print('⏱️ Export completed in ${stopwatch.elapsed.inSeconds} seconds');
      // Always reset the downloading state, even on error
      _isDownloading = false;
    }
  }

  Future<void> _exportMaintenanceCountsSyncfusion(List<MaintenanceCount> allCounts, Map<String, String> schoolNames) async {
    try {
      print('🚀 Starting Syncfusion export...');
      print('📊 Data to export:');
      print('   - Total counts: ${allCounts.length}');
      print('   - Schools: ${schoolNames.length}');
      print('   - Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
      
      // Use Syncfusion for all platforms
      final workbook = syncfusion.Workbook();
      print('✅ Workbook created successfully');

      // Safety Sheet
      print('📋 Creating Safety Sheet...');
      final safetySheet = workbook.worksheets[0];
      safetySheet.name = 'أمن وسلامة';
      print('✅ Safety Sheet created');
      
      // Title
      final titleRange = safetySheet.getRangeByIndex(1, 1, 1, 23);
      titleRange.setText('حصر الأمن والسلامة');
      titleRange.cellStyle.fontSize = 16;
      titleRange.cellStyle.bold = true;
      safetySheet.getRangeByIndex(1, 1, 1, 23).merge();

      final safetyHeaders = [
        'اسم المدرسة',
        'تاريخ الحصر',
        'خرطوم الحريق',
        'صناديق الحريق',
        'حالة صناديق الحريق',
        'طفايات الحريق',
        'تاريخ انتهاء طفايات الحريق',
        'مضخة الديزل',
        'حالة مضخة الديزل',
        'المضخة الكهربائية',
        'حالة المضخة الكهربائية',
        'المضخة المساعدة',
        'حالة المضخة المساعدة',
        'نوع لوحة الإنذار',
        'عدد لوحات الإنذار',
        'حالة لوحة الإنذار',
        'حالة نظام إنذار الحريق',
        'حالة نظام إطفاء الحريق',
        'حالة مخارج الطوارئ',
        'حالة أضواء الطوارئ',
        'حالة أجهزة استشعار الدخان',
        'حالة أجهزة استشعار الحرارة',
        'كاسر',
      ];
      
      // Apply header styling
      final headerRange = safetySheet.getRangeByIndex(3, 1, 3, safetyHeaders.length);
      headerRange.cellStyle.fontSize = 12;
      headerRange.cellStyle.bold = true;
      
      for (int i = 0; i < safetyHeaders.length; i++) {
        safetySheet.getRangeByIndex(3, i + 1).setText(safetyHeaders[i]);
      }
      
      // Data rows
      print('📝 Adding Safety Sheet data rows (${allCounts.length} rows)...');
      for (int row = 0; row < allCounts.length; row++) {
        final count = allCounts[row];
        
        // Progress logging every 10 rows
        if (row % 10 == 0) {
          print('   📊 Processing Safety row ${row + 1}/${allCounts.length}');
        }
        
        final rowData = [
          schoolNames[count.schoolId] ?? 'مدرسة ${count.schoolId}',
          _formatDate(count.createdAt),
          int.tryParse(count.itemCounts['fire_hose']?.toString() ?? '0') ?? 0,
          int.tryParse(count.itemCounts['fire_boxes']?.toString() ?? '0') ?? 0,
          count.surveyAnswers['fire_boxes_condition'] ?? '',
          int.tryParse(count.itemCounts['fire_extinguishers']?.toString() ?? '0') ?? 0,
          _getFireExtinguisherExpiryDate(count),
          int.tryParse(count.itemCounts['diesel_pump']?.toString() ?? '0') ?? 0,
          count.surveyAnswers['diesel_pump_condition'] ?? '',
          int.tryParse(count.itemCounts['electric_pump']?.toString() ?? '0') ?? 0,
          count.surveyAnswers['electric_pump_condition'] ?? '',
          int.tryParse(count.itemCounts['auxiliary_pump']?.toString() ?? '0') ?? 0,
          count.surveyAnswers['auxiliary_pump_condition'] ?? '',
          count.fireSafetyAlarmPanelData['alarm_panel_type'] ?? '',
          int.tryParse(count.fireSafetyAlarmPanelData['alarm_panel_count']?.toString() ?? '0') ?? 0,
          count.surveyAnswers['alarm_panel_condition'] ?? '',
          count.surveyAnswers['fire_alarm_system_condition'] ?? '',
          count.surveyAnswers['fire_suppression_system_condition'] ?? '',
          count.surveyAnswers['emergency_exits_condition'] ?? '',
          count.surveyAnswers['emergency_lights_condition'] ?? '',
          count.surveyAnswers['smoke_detectors_condition'] ?? '',
          count.surveyAnswers['heat_detectors_condition'] ?? '',
          count.surveyAnswers['break_glasses_bells_condition'] ?? '',
        ];
        
        safetySheet.getRangeByIndex(row + 4, 1).setText(rowData[0].toString());
        safetySheet.getRangeByIndex(row + 4, 2).setText(rowData[1].toString());
        safetySheet.getRangeByIndex(row + 4, 3).setNumber(double.tryParse(rowData[2].toString()) ?? 0);
        safetySheet.getRangeByIndex(row + 4, 4).setNumber(double.tryParse(rowData[3].toString()) ?? 0);
        safetySheet.getRangeByIndex(row + 4, 5).setText(rowData[4].toString());
        safetySheet.getRangeByIndex(row + 4, 6).setNumber(double.tryParse(rowData[5].toString()) ?? 0);
        safetySheet.getRangeByIndex(row + 4, 7).setText(rowData[6].toString());
        safetySheet.getRangeByIndex(row + 4, 8).setNumber(double.tryParse(rowData[7].toString()) ?? 0);
        safetySheet.getRangeByIndex(row + 4, 9).setText(rowData[8].toString());
        safetySheet.getRangeByIndex(row + 4, 10).setNumber(double.tryParse(rowData[9].toString()) ?? 0);
        safetySheet.getRangeByIndex(row + 4, 11).setText(rowData[10].toString());
        safetySheet.getRangeByIndex(row + 4, 12).setNumber(double.tryParse(rowData[11].toString()) ?? 0);
        safetySheet.getRangeByIndex(row + 4, 13).setText(rowData[12].toString());
        safetySheet.getRangeByIndex(row + 4, 14).setText(rowData[13].toString());
        safetySheet.getRangeByIndex(row + 4, 15).setNumber(double.tryParse(rowData[14].toString()) ?? 0);
        safetySheet.getRangeByIndex(row + 4, 16).setText(rowData[15].toString());
        safetySheet.getRangeByIndex(row + 4, 17).setText(rowData[16].toString());
        safetySheet.getRangeByIndex(row + 4, 18).setText(rowData[17].toString());
        safetySheet.getRangeByIndex(row + 4, 19).setText(rowData[18].toString());
        safetySheet.getRangeByIndex(row + 4, 20).setText(rowData[19].toString());
        safetySheet.getRangeByIndex(row + 4, 21).setText(rowData[20].toString());
        safetySheet.getRangeByIndex(row + 4, 22).setText(rowData[21].toString());
        safetySheet.getRangeByIndex(row + 4, 23).setText(rowData[22].toString());
      }

      // Electrical Sheet
      final electricalSheet = workbook.worksheets.addWithName('كهرباء');
      
      // Title
      final electricalTitleRange = electricalSheet.getRangeByIndex(1, 1, 1, 22);
      electricalTitleRange.setText('حصر الكهرباء');
      electricalTitleRange.cellStyle.fontSize = 16;
      electricalTitleRange.cellStyle.bold = true;
      electricalSheet.getRangeByIndex(1, 1, 1, 22).merge();
      
      final electricalHeaders = [
        'اسم المدرسة',
        'تاريخ الحصر',
        'لوحة انارة',
        'امبير لوحة الانارة',
        'لوحة باور(أفياش)',
        'امبير لوحة الباور',
        'لوحة تكييف',
        'امبير لوحة التكييف',
        'لوحة توزيع رئيسية',
        'امبير لوحة التوزيع الرئيسية',
        'القاطع الرئيسي',
        'امبير القاطع الرئيسي',
        'قاطع تكييف (كونسيلد)',
        'امبير قاطع التكييف (كونسيلد)',
        'قاطع تكييف (باكدج)',
        'امبير قاطع التكييف (باكدج)',
        'لمبات',
        'بروجيكتور',
        'جرس الفصول',
        'السماعات',
        'نظام الميكوفون',
        'رقم عداد الكهرباء',
      ];
      
      // Apply header styling
      final electricalHeaderRange = electricalSheet.getRangeByIndex(3, 1, 3, electricalHeaders.length);
      electricalHeaderRange.cellStyle.fontSize = 12;
      electricalHeaderRange.cellStyle.bold = true;
      
      for (int i = 0; i < electricalHeaders.length; i++) {
        electricalSheet.getRangeByIndex(3, i + 1).setText(electricalHeaders[i]);
      }
      
      for (int row = 0; row < allCounts.length; row++) {
        final count = allCounts[row];
        final rowData = [
          schoolNames[count.schoolId] ?? 'مدرسة ${count.schoolId}',
          _formatDate(count.createdAt), // Text
          int.tryParse(count.itemCounts['lighting_panel']?.toString() ?? '0') ?? 0, // Number
          int.tryParse(count.textAnswers['lighting_panel_amperage']?.toString() ?? '0') ?? 0, // Number
          int.tryParse(count.itemCounts['power_panel']?.toString() ?? '0') ?? 0, // Number
          int.tryParse(count.textAnswers['power_panel_amperage']?.toString() ?? '0') ?? 0, // Number
          int.tryParse(count.itemCounts['ac_panel']?.toString() ?? '0') ?? 0, // Number
          int.tryParse(count.textAnswers['ac_panel_amperage']?.toString() ?? '0') ?? 0, // Number
          int.tryParse(count.itemCounts['main_distribution_panel']?.toString() ?? '0') ?? 0, // Number
          int.tryParse(count.textAnswers['main_distribution_panel_amperage']?.toString() ?? '0') ?? 0, // Number
          int.tryParse(count.itemCounts['main_breaker']?.toString() ?? '0') ?? 0, // Number
          int.tryParse(count.textAnswers['main_breaker_amperage']?.toString() ?? '0') ?? 0, // Number
          int.tryParse(count.itemCounts['concealed_ac_breaker']?.toString() ?? '0') ?? 0, // Number
          int.tryParse(count.textAnswers['concealed_ac_breaker_amperage']?.toString() ?? '0') ?? 0, // Number
          int.tryParse(count.itemCounts['package_ac_breaker']?.toString() ?? '0') ?? 0, // Number
          int.tryParse(count.textAnswers['package_ac_breaker_amperage']?.toString() ?? '0') ?? 0, // Number
          int.tryParse(count.itemCounts['lamps']?.toString() ?? '0') ?? 0, // Number
          int.tryParse(count.itemCounts['projector']?.toString() ?? '0') ?? 0, // Number
          int.tryParse(count.itemCounts['class_bell']?.toString() ?? '0') ?? 0, // Number
          int.tryParse(count.itemCounts['speakers']?.toString() ?? '0') ?? 0, // Number
          int.tryParse(count.itemCounts['microphone_system']?.toString() ?? '0') ?? 0, // Number
          count.textAnswers['electricity_meter_number'] ?? '', // Text
        ];
        
        electricalSheet.getRangeByIndex(row + 4, 1).setText(rowData[0].toString());
        electricalSheet.getRangeByIndex(row + 4, 2).setText(rowData[1].toString());
        electricalSheet.getRangeByIndex(row + 4, 3).setNumber(double.tryParse(rowData[2].toString()) ?? 0);
        electricalSheet.getRangeByIndex(row + 4, 4).setNumber(double.tryParse(rowData[3].toString()) ?? 0);
        electricalSheet.getRangeByIndex(row + 4, 5).setNumber(double.tryParse(rowData[4].toString()) ?? 0);
        electricalSheet.getRangeByIndex(row + 4, 6).setNumber(double.tryParse(rowData[5].toString()) ?? 0);
        electricalSheet.getRangeByIndex(row + 4, 7).setNumber(double.tryParse(rowData[6].toString()) ?? 0);
        electricalSheet.getRangeByIndex(row + 4, 8).setNumber(double.tryParse(rowData[7].toString()) ?? 0);
        electricalSheet.getRangeByIndex(row + 4, 9).setNumber(double.tryParse(rowData[8].toString()) ?? 0);
        electricalSheet.getRangeByIndex(row + 4, 10).setNumber(double.tryParse(rowData[9].toString()) ?? 0);
        electricalSheet.getRangeByIndex(row + 4, 11).setNumber(double.tryParse(rowData[10].toString()) ?? 0);
        electricalSheet.getRangeByIndex(row + 4, 12).setNumber(double.tryParse(rowData[11].toString()) ?? 0);
        electricalSheet.getRangeByIndex(row + 4, 13).setNumber(double.tryParse(rowData[12].toString()) ?? 0);
        electricalSheet.getRangeByIndex(row + 4, 14).setNumber(double.tryParse(rowData[13].toString()) ?? 0);
        electricalSheet.getRangeByIndex(row + 4, 15).setNumber(double.tryParse(rowData[14].toString()) ?? 0);
        electricalSheet.getRangeByIndex(row + 4, 16).setNumber(double.tryParse(rowData[15].toString()) ?? 0);
        electricalSheet.getRangeByIndex(row + 4, 17).setNumber(double.tryParse(rowData[16].toString()) ?? 0);
        electricalSheet.getRangeByIndex(row + 4, 18).setNumber(double.tryParse(rowData[17].toString()) ?? 0);
        electricalSheet.getRangeByIndex(row + 4, 19).setNumber(double.tryParse(rowData[18].toString()) ?? 0);
        electricalSheet.getRangeByIndex(row + 4, 20).setNumber(double.tryParse(rowData[19].toString()) ?? 0);
        electricalSheet.getRangeByIndex(row + 4, 21).setNumber(double.tryParse(rowData[20].toString()) ?? 0);
        electricalSheet.getRangeByIndex(row + 4, 22).setText(rowData[21].toString());
      }

      // Mechanical Sheet
      final mechanicalSheet = workbook.worksheets.addWithName('ميكانيكا');
      
      // Title
      final mechanicalTitleRange = mechanicalSheet.getRangeByIndex(1, 1, 1, 50); // Increased width for dynamic columns
      mechanicalTitleRange.setText('حصر الميكانيكا');
      mechanicalTitleRange.cellStyle.fontSize = 16;
      mechanicalTitleRange.cellStyle.bold = true;
      mechanicalSheet.getRangeByIndex(1, 1, 1, 50).merge();
      
      // Collect all unique heater IDs from all counts
      final Set<String> allHeaterIds = {};
      
      for (final count in allCounts) {
        final heaterEntries = count.heaterEntries;
        print('Heater entries for count ${count.id}: $heaterEntries'); // Debug
        
        if (heaterEntries.isNotEmpty) {
          // Process bathroom heaters
          final bathroomHeaters = heaterEntries['bathroom_heaters'] as List<dynamic>?;
          print('Bathroom heaters: $bathroomHeaters'); // Debug
          
          if (bathroomHeaters != null) {
            for (final heater in bathroomHeaters) {
              if (heater is Map<String, dynamic>) {
                final id = heater['id']?.toString() ?? '';
                print('Bathroom heater ID: $id'); // Debug
                if (id.isNotEmpty) {
                  allHeaterIds.add('bathroom_heaters_$id');
                }
              }
            }
          }
          
          // Process cafeteria heaters
          final cafeteriaHeaters = heaterEntries['cafeteria_heaters'] as List<dynamic>?;
          print('Cafeteria heaters: $cafeteriaHeaters'); // Debug
          
          if (cafeteriaHeaters != null) {
            for (final heater in cafeteriaHeaters) {
              if (heater is Map<String, dynamic>) {
                final id = heater['id']?.toString() ?? '';
                print('Cafeteria heater ID: $id'); // Debug
                if (id.isNotEmpty) {
                  allHeaterIds.add('cafeteria_heaters_$id');
                }
              }
            }
          }
        }
      }
      
      print('All heater IDs found: $allHeaterIds'); // Debug
      
      // Convert to sorted list for consistent column order
      final sortedHeaterIds = allHeaterIds.toList()..sort();
      
      // Create headers with dynamic heater columns
      final headers = [
        'اسم المدرسة',
        'تاريخ الحصر',
        ...sortedHeaterIds.map((heaterId) {
          final isBathroom = heaterId.startsWith('bathroom_heaters_');
          final id = heaterId.replaceFirst('bathroom_heaters_', '').replaceFirst('cafeteria_heaters_', '');
          final location = isBathroom ? 'حمام' : 'مقصف';
          // Try to get capacity from textAnswers
          String? capacity;
          for (final count in allCounts) {
            final capKey = '${heaterId}_capacity';
            final capValue = count.textAnswers[capKey];
            if (capValue != null && capValue.isNotEmpty) {
              capacity = capValue;
              break;
            }
          }
          if (capacity != null && capacity.isNotEmpty) {
            return 'سخان $location $capacity لتر';
          } else {
            return 'سخان $location رقم $id';
          }
        }),
        'مغاسل',
        'كرسي افرنجي',
        'كرسي عربي',
        'سيفونات',
        'شطافات',
        'مراوح شفط جدارية',
        'مراوح شفط مركزية',
        'مراوح شفط (مقصف)',
        'برادات مياة جدارية',
        'برادات مياة للممرات',
        'مضخات المياه',
        'رقم عداد المياه',
        'عدد المصاعد',
        'محرك المصاعد',
        'القطع الرئيسية للمصاعد',
      ];
      
      // Apply header styling
      final mechanicalHeaderRange = mechanicalSheet.getRangeByIndex(3, 1, 3, headers.length);
      mechanicalHeaderRange.cellStyle.fontSize = 12;
      mechanicalHeaderRange.cellStyle.bold = true;
      
      for (int i = 0; i < headers.length; i++) {
        mechanicalSheet.getRangeByIndex(3, i + 1).setText(headers[i]);
      }
      
      // Data rows
      for (int row = 0; row < allCounts.length; row++) {
        final count = allCounts[row];
        
        // Create heater data map for this count
        final Map<String, int> heaterData = {};
        final heaterEntries = count.heaterEntries;
        
        if (heaterEntries.isNotEmpty) {
          // Process bathroom heaters
          final bathroomHeaters = heaterEntries['bathroom_heaters'] as List<dynamic>?;
          if (bathroomHeaters != null) {
            for (final heater in bathroomHeaters) {
              if (heater is Map<String, dynamic>) {
                final id = heater['id']?.toString() ?? '';
                if (id.isNotEmpty) {
                  final heaterKey = 'bathroom_heaters_$id';
                  // Get quantity from itemCounts
                  heaterData[heaterKey] = count.itemCounts[heaterKey] ?? 0;
                }
              }
            }
          }
          
          // Process cafeteria heaters
          final cafeteriaHeaters = heaterEntries['cafeteria_heaters'] as List<dynamic>?;
          if (cafeteriaHeaters != null) {
            for (final heater in cafeteriaHeaters) {
              if (heater is Map<String, dynamic>) {
                final id = heater['id']?.toString() ?? '';
                if (id.isNotEmpty) {
                  final heaterKey = 'cafeteria_heaters_$id';
                  // Get quantity from itemCounts
                  heaterData[heaterKey] = count.itemCounts[heaterKey] ?? 0;
                }
              }
            }
          }
        }
        
        // Build row data with dynamic heater columns
        final rowData = [
          schoolNames[count.schoolId] ?? 'مدرسة ${count.schoolId}',
          _formatDate(count.createdAt),
          ...sortedHeaterIds.map((heaterId) => heaterData[heaterId] ?? 0),
          int.tryParse(count.itemCounts['sinks']?.toString() ?? '0') ?? 0,
          int.tryParse(count.itemCounts['western_toilet']?.toString() ?? '0') ?? 0,
          int.tryParse(count.itemCounts['arabic_toilet']?.toString() ?? '0') ?? 0,
          int.tryParse(count.itemCounts['siphons']?.toString() ?? '0') ?? 0,
          int.tryParse(count.itemCounts['bidets']?.toString() ?? '0') ?? 0,
          int.tryParse(count.itemCounts['wall_exhaust_fans']?.toString() ?? '0') ?? 0,
          int.tryParse(count.itemCounts['central_exhaust_fans']?.toString() ?? '0') ?? 0,
          int.tryParse(count.itemCounts['cafeteria_exhaust_fans']?.toString() ?? '0') ?? 0,
          int.tryParse(count.itemCounts['wall_water_coolers']?.toString() ?? '0') ?? 0,
          int.tryParse(count.itemCounts['corridor_water_coolers']?.toString() ?? '0') ?? 0,
          int.tryParse(count.itemCounts['water_pumps']?.toString() ?? '0') ?? 0,
          count.textAnswers['water_meter_number'] ?? '',
          int.tryParse(count.yesNoWithCounts['elevators']?.toString() ?? '0') ?? 0,
          count.textAnswers['elevators_motor'] ?? '',
          count.textAnswers['elevators_main_parts'] ?? '',
        ];
        
        // Set cell values
        mechanicalSheet.getRangeByIndex(row + 4, 1).setText(rowData[0].toString());
        mechanicalSheet.getRangeByIndex(row + 4, 2).setText(rowData[1].toString());
        
        // Set heater columns (dynamic)
        for (int i = 0; i < sortedHeaterIds.length; i++) {
          mechanicalSheet.getRangeByIndex(row + 4, i + 3).setNumber(double.tryParse(rowData[i + 2].toString()) ?? 0);
        }
        
        // Set remaining columns
        final baseColumns = 2; // School name and date
        final heaterColumns = sortedHeaterIds.length;
        final remainingColumns = rowData.length - baseColumns - heaterColumns;
        
        for (int i = 0; i < remainingColumns; i++) {
          final colIndex = baseColumns + heaterColumns + i + 1;
          final dataIndex = baseColumns + heaterColumns + i;
          
          if (dataIndex < rowData.length) {
            final value = rowData[dataIndex];
            if (value is String) {
              mechanicalSheet.getRangeByIndex(row + 4, colIndex).setText(value);
            } else {
              mechanicalSheet.getRangeByIndex(row + 4, colIndex).setNumber((double.tryParse(value.toString()) ?? 0).toDouble());
            }
          }
        }
      }

      // Civil Sheet
      final civilSheet = workbook.worksheets.addWithName('مدني');
      
      // Title
      final civilTitleRange = civilSheet.getRangeByIndex(1, 1, 1, 12);
      civilTitleRange.setText('حصر المدني');
      civilTitleRange.cellStyle.fontSize = 16;
      civilTitleRange.cellStyle.bold = true;
      civilSheet.getRangeByIndex(1, 1, 1, 12).merge();
      
      final civilHeaders = [
        'اسم المدرسة',
        'تاريخ الحصر',
        'سبورة',
        'نوافذ داخلية',
        'نوافذ خارجية',
        'تشققات في الجدران',
        'يوجد مصاعد',
        'تلف المظلات',
        'يوجد تسريب مياه',
        'ارتفاع السياج منخفض',
        'أضرار صدأ الخرسانة',
        'أضرار عزل السطح',
      ];
      
      // Apply header styling
      final civilHeaderRange = civilSheet.getRangeByIndex(3, 1, 3, civilHeaders.length);
      civilHeaderRange.cellStyle.fontSize = 12;
      civilHeaderRange.cellStyle.bold = true;
      
      for (int i = 0; i < civilHeaders.length; i++) {
        civilSheet.getRangeByIndex(3, i + 1).setText(civilHeaders[i]);
      }
      
      for (int row = 0; row < allCounts.length; row++) {
        final count = allCounts[row];
        final rowData = [
          schoolNames[count.schoolId] ?? 'مدرسة ${count.schoolId}',
          _formatDate(count.createdAt),
          int.tryParse(count.itemCounts['blackboard']?.toString() ?? '0') ?? 0,
          int.tryParse(count.itemCounts['internal_windows']?.toString() ?? '0') ?? 0,
          int.tryParse(count.itemCounts['external_windows']?.toString() ?? '0') ?? 0,
          count.yesNoAnswers['wall_cracks'] == true ? 'نعم' : 'لا',
          count.yesNoAnswers['has_elevators'] == true ? 'نعم' : 'لا',
          count.yesNoAnswers['falling_shades'] == true ? 'نعم' : 'لا',
          count.yesNoAnswers['has_water_leaks'] == true ? 'نعم' : 'لا',
          count.yesNoAnswers['low_railing_height'] == true ? 'نعم' : 'لا',
          count.yesNoAnswers['concrete_rust_damage'] == true ? 'نعم' : 'لا',
          count.yesNoAnswers['roof_insulation_damage'] == true ? 'نعم' : 'لا',
        ];
        
        civilSheet.getRangeByIndex(row + 4, 1).setText(rowData[0].toString());
        civilSheet.getRangeByIndex(row + 4, 2).setText(rowData[1].toString());
        civilSheet.getRangeByIndex(row + 4, 3).setNumber(double.tryParse(rowData[2].toString()) ?? 0);
        civilSheet.getRangeByIndex(row + 4, 4).setNumber(double.tryParse(rowData[3].toString()) ?? 0);
        civilSheet.getRangeByIndex(row + 4, 5).setNumber(double.tryParse(rowData[4].toString()) ?? 0);
        civilSheet.getRangeByIndex(row + 4, 6).setText(rowData[5].toString());
        civilSheet.getRangeByIndex(row + 4, 7).setText(rowData[6].toString());
        civilSheet.getRangeByIndex(row + 4, 8).setText(rowData[7].toString());
        civilSheet.getRangeByIndex(row + 4, 9).setText(rowData[8].toString());
        civilSheet.getRangeByIndex(row + 4, 10).setText(rowData[9].toString());
        civilSheet.getRangeByIndex(row + 4, 11).setText(rowData[10].toString());
        civilSheet.getRangeByIndex(row + 4, 12).setText(rowData[11].toString());
      }

      // Summary Sheet
      final summarySheet = workbook.worksheets.addWithName('ملخص');
      
      // Title
      final summaryTitleRange = summarySheet.getRangeByIndex(1, 1, 1, 4);
      summaryTitleRange.setText('ملخص حصر الصيانة');
      summaryTitleRange.cellStyle.fontSize = 18;
      summaryTitleRange.cellStyle.bold = true;
      summarySheet.getRangeByIndex(1, 1, 1, 4).merge();
      
      final schoolCounts = <String, int>{};
      for (final count in allCounts) {
        final schoolName = schoolNames[count.schoolId] ?? 'مدرسة ${count.schoolId}';
        schoolCounts[schoolName] = (schoolCounts[schoolName] ?? 0) + 1;
      }
      
      final summaryHeaders = ['اسم المدرسة', 'عدد الحصور', 'آخر تحديث', 'الحالة'];
      
      // Apply header styling
      final summaryHeaderRange = summarySheet.getRangeByIndex(3, 1, 3, summaryHeaders.length);
      summaryHeaderRange.cellStyle.fontSize = 12;
      summaryHeaderRange.cellStyle.bold = true;
      
      for (int i = 0; i < summaryHeaders.length; i++) {
        summarySheet.getRangeByIndex(3, i + 1).setText(summaryHeaders[i]);
      }
      
      int rowIndex = 4;
      for (final entry in schoolCounts.entries) {
        final schoolName = entry.key;
        final countNum = entry.value;
        final latestCount = allCounts
            .where((c) => (schoolNames[c.schoolId] ?? 'مدرسة ${c.schoolId}') == schoolName)
            .reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);
        final rowData = [
          schoolName,
          countNum,
          _formatDate(latestCount.createdAt),
          latestCount.status == 'submitted' ? 'مرسل' : 'مسودة',
        ];
        
        summarySheet.getRangeByIndex(rowIndex, 1).setText(rowData[0].toString());
        summarySheet.getRangeByIndex(rowIndex, 2).setNumber(double.tryParse(rowData[1].toString()) ?? 0);
        summarySheet.getRangeByIndex(rowIndex, 3).setText(rowData[2].toString());
        summarySheet.getRangeByIndex(rowIndex, 4).setText(rowData[3].toString());
        rowIndex++;
      }
      
      // Summary footer
      final footerRange1 = summarySheet.getRangeByIndex(rowIndex + 1, 1);
      footerRange1.setText('إجمالي المدارس: ${schoolCounts.length}');
      footerRange1.cellStyle.fontSize = 12;
      footerRange1.cellStyle.bold = true;
      
      final footerRange2 = summarySheet.getRangeByIndex(rowIndex + 2, 1);
      footerRange2.setText('إجمالي الحصور: ${allCounts.length}');
      footerRange2.cellStyle.fontSize = 12;
      footerRange2.cellStyle.bold = true;

      // Save and download
      print('💾 Saving workbook...');
      final List<int> bytes = workbook.saveAsStream();
      print('✅ Workbook saved, size: ${bytes.length} bytes');
      
      print('🧹 Disposing workbook...');
      workbook.dispose();
      print('✅ Workbook disposed');

      if (kIsWeb) {
        print('🌐 Creating web download...');
        try {
          final blob = html.Blob([Uint8List.fromList(bytes)]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute('download', 'حصر الاعداد والحالة.xlsx')
            ..click();
          html.Url.revokeObjectUrl(url);
          print('✅ Web download initiated');
        } catch (webError) {
          print('❌ Web download failed: $webError');
          rethrow;
        }
      } else {
        print('📱 Creating mobile download...');
        try {
          final directory = await getApplicationDocumentsDirectory();
          final path = '${directory.path}/حصر الاعداد والحالة.xlsx';
          final file = File(path);
          await file.writeAsBytes(bytes, flush: true);
          await Share.shareXFiles([XFile(path)], text: 'حصر الاعداد والحالة');
          print('✅ Mobile download completed');
        } catch (mobileError) {
          print('❌ Mobile download failed: $mobileError');
          rethrow;
        }
      }
    } catch (e) {
      print('Syncfusion export error: $e');
      rethrow;
    }
  }

  Future<void> _exportMaintenanceCountsExcelPackage(List<MaintenanceCount> allCounts, Map<String, String> schoolNames) async {
    try {
      print('🔄 Using Excel package fallback...');
      
      // Fallback to excel package
      final excel = Excel.createExcel();
      excel.delete('Sheet1');
      
      // Create a simple summary sheet as fallback
      final sheet = excel['ملخص حصر الصيانة'];
      print('✅ Excel package sheet created');
      
      // Headers
      final headers = [
        'اسم المدرسة',
        'تاريخ الحصر',
        'الحالة',
        'عدد العناصر',
      ];
      
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = headers[i];
      }
      
      // Data rows
      for (int row = 0; row < allCounts.length; row++) {
        final count = allCounts[row];
        final rowData = [
          schoolNames[count.schoolId] ?? 'مدرسة ${count.schoolId}',
          _formatDate(count.createdAt),
          count.status == 'submitted' ? 'مرسل' : 'مسودة',
          count.itemCounts.length,
        ];
        
        for (int i = 0; i < rowData.length; i++) {
          _setCellValue(sheet, i, row + 1, rowData[i]);
        }
      }
      
      // Save and download
      final bytes = excel.encode();
      if (bytes == null) {
        throw Exception('Failed to generate Excel file');
      }
      
      if (kIsWeb) {
        final blob = html.Blob([Uint8List.fromList(bytes)]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'حصر الاعداد والحالة_مبسط.xlsx')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // For mobile platforms, save to file and share
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/حصر الاعداد والحالة_مبسط.xlsx';
        final file = File(path);
        await file.writeAsBytes(bytes, flush: true);
        await Share.shareXFiles([XFile(path)], text: 'حصر الاعداد والحالة');
      }
    } catch (e) {
      print('Excel package fallback error: $e');
      rethrow;
    }
  }

  Future<void> exportAllDamageCounts() async {
    if (_damageRepository == null) {
      throw Exception('Damage repository not provided');
    }

    try {
      // Request storage permission for Android (not needed on web)
      if (!kIsWeb) {
        try {
          if (Platform.isAndroid) {
            final permission = await Permission.storage.request();
            if (!permission.isGranted) {
              throw Exception('Storage permission denied');
            }
          }
        } catch (e) {
          // Platform check failed, likely on web - continue without permission check
        }
      }

      // Get all damage counts and school names
      final allCounts = await _getAllDamageCounts();
      final schoolNames = await _getDamageSchoolNamesMap();

      if (allCounts.isEmpty) {
        throw Exception('No damage counts found');
      }

      // Use Syncfusion for web export
      if (kIsWeb) {
        await _exportDamageCountsSyncfusionWeb(allCounts, schoolNames);
        return;
      }

      // Fallback to old excel package for non-web (keep as-is for now)
      final excel = Excel.createExcel();
      excel.delete('Sheet1');
      _createMechanicalDamageSheet(excel, allCounts, schoolNames);
      _createElectricalDamageSheet(excel, allCounts, schoolNames);
      _createCivilDamageSheet(excel, allCounts, schoolNames);
      _createSafetyDamageSheet(excel, allCounts, schoolNames);
      _createAirConditioningDamageSheet(excel, allCounts, schoolNames);
      _createDamageSummarySheet(excel, allCounts, schoolNames);
    } catch (e) {
      throw Exception('Failed to export Damage Excel: ${e.toString()}');
    }
  }

  Future<List<MaintenanceCount>> _getAllMaintenanceCounts() async {
    final allCounts = <MaintenanceCount>[];

    // Get all schools with maintenance counts
    final schools = await _repository.getSchoolsWithMaintenanceCounts();

    for (final school in schools) {
      final schoolId = school['school_id'] as String;
      final counts = await _repository.getMaintenanceCounts(schoolId: schoolId);
      allCounts.addAll(counts);
    }

    return allCounts;
  }

  Future<List<DamageCount>> _getAllDamageCounts() async {
    final allCounts = <DamageCount>[];

    // Get all schools with damage counts
    final schools = await _damageRepository!.getSchoolsWithDamageCounts();

    for (final school in schools) {
      final schoolId = school['school_id'] as String;
      final counts =
          await _damageRepository!.getDamageCounts(schoolId: schoolId);
      allCounts.addAll(counts);
    }

    return allCounts;
  }

  Future<Map<String, String>> _getSchoolNamesMap() async {
    try {
      final schools = await _repository.getSchoolsWithMaintenanceCounts();
      final schoolMap = <String, String>{};

      for (final school in schools) {
        final schoolId = school['school_id'] as String;
        final schoolName = school['school_name'] as String;
        schoolMap[schoolId] = schoolName;
      }

      return schoolMap;
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, String>> _getDamageSchoolNamesMap() async {
    try {
      final schools = await _damageRepository!.getSchoolsWithDamageCounts();
      final schoolMap = <String, String>{};

      for (final school in schools) {
        final schoolId = school['school_id'] as String;
        final schoolName = school['school_name'] as String;
        schoolMap[schoolId] = schoolName;
      }

      return schoolMap;
    } catch (e) {
      return {};
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getFireExtinguisherExpiryDate(MaintenanceCount count) {
    final day = count.textAnswers['fire_extinguishers_expiry_day'] ?? '';
    final month = count.textAnswers['fire_extinguishers_expiry_month'] ?? '';
    final year = count.textAnswers['fire_extinguishers_expiry_year'] ?? '';

    if (day.isNotEmpty && month.isNotEmpty && year.isNotEmpty) {
      // Ensure proper formatting with leading zeros if needed
      final formattedDay = day.length == 1 ? '0$day' : day;
      final formattedMonth = month.length == 1 ? '0$month' : month;
      return '$formattedDay/$formattedMonth/$year';
    }
    return '';
  }

  // Helper method to get heater entries data
  Map<String, dynamic> _getHeaterEntriesData(MaintenanceCount count) {
    final heaterEntries = count.heaterEntries;
    if (heaterEntries == null || heaterEntries.isEmpty) {
      return {};
    }
    return heaterEntries;
  }

  // Helper method to get bathroom heaters count and capacities
  (int, String) _getBathroomHeatersData(MaintenanceCount count) {
    final heaterEntries = _getHeaterEntriesData(count);
    final bathroomHeaters = heaterEntries['bathroom_heaters'] as List<dynamic>?;
    
    if (bathroomHeaters != null && bathroomHeaters.isNotEmpty) {
      final count = bathroomHeaters.length;
      final capacities = bathroomHeaters.map((entry) {
        if (entry is Map<String, dynamic>) {
          return entry['capacity']?.toString() ?? '';
        }
        return '';
      }).where((capacity) => capacity.isNotEmpty).join(', ');
      
      return (count, capacities);
    }
    
    // Fallback to old structure
    final oldCount = int.tryParse(count.itemCounts['bathroom_heaters']?.toString() ?? '0') ?? 0;
    final oldCapacity = count.textAnswers['bathroom_heaters_capacity'] ?? '';
    return (oldCount, oldCapacity);
  }

  // Helper method to get cafeteria heaters count and capacities
  (int, String) _getCafeteriaHeatersData(MaintenanceCount count) {
    final heaterEntries = _getHeaterEntriesData(count);
    final cafeteriaHeaters = heaterEntries['cafeteria_heaters'] as List<dynamic>?;
    
    if (cafeteriaHeaters != null && cafeteriaHeaters.isNotEmpty) {
      final count = cafeteriaHeaters.length;
      final capacities = cafeteriaHeaters.map((entry) {
        if (entry is Map<String, dynamic>) {
          return entry['capacity']?.toString() ?? '';
        }
        return '';
      }).where((capacity) => capacity.isNotEmpty).join(', ');
      
      return (count, capacities);
    }
    
    // Fallback to old structure
    final oldCount = int.tryParse(count.itemCounts['cafeteria_heaters']?.toString() ?? '0') ?? 0;
    final oldCapacity = count.textAnswers['cafeteria_heaters_capacity'] ?? '';
    return (oldCount, oldCapacity);
  }

  void _createMechanicalDamageSheet(Excel excel, List<DamageCount> allCounts,
      Map<String, String> schoolNames) {
    final sheet = excel['أعمال الميكانيك والسباكة'];

    // Headers
    final headers = [
      'اسم المدرسة',
      'تاريخ الحصر',
      'كرسي شرقي',
      'كرسي افرنجي',
      'حوض مغسلة مع القاعدة',
      'صناديق طرد مخفي-للكرسي العربي',
      'صناديق طرد واطي-للكرسي الافرنجي',
      'مواسير upvc class 5',
      'خزان علوي فايبر جلاس سعة 5000 لتر',
      'خزان علوي فايبر جلاس سعة 4000 لتر',
      'خزان علوي فايبر جلاس سعة 3000 لتر',
      'مضخات مياة 3 حصان- Booster Pump',
      'محرك + صندوق تروس مصاعد - Elevators',
      'مواسير التغذية',
      'مواسير الصرف الخارجية',
    ];

    // Add headers to first row
    for (int i = 0; i < headers.length; i++) {
      final cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
    }

    // Add data rows
    int rowIndex = 1;
    for (final count in allCounts) {
      final schoolName =
          schoolNames[count.schoolId] ?? 'مدرسة ${count.schoolId}';

      final rowData = [
        schoolName, // Text
        _formatDate(count.createdAt), // Text
        count.itemCounts['plastic_chair'] ?? 0, // Number
        count.itemCounts['plastic_chair_external'] ?? 0, // Number
        count.itemCounts['water_sink'] ?? 0, // Number
        count.itemCounts['hidden_boxes'] ?? 0, // Number
        count.itemCounts['low_boxes'] ?? 0, // Number
        count.itemCounts['upvc_pipes_4_5'] ?? 0, // Number
        count.itemCounts['glass_fiber_tank_5000'] ?? 0, // Number
        count.itemCounts['glass_fiber_tank_4000'] ?? 0, // Number
        count.itemCounts['glass_fiber_tank_3000'] ?? 0, // Number
        count.itemCounts['booster_pump_3_phase'] ?? 0, // Number
        count.itemCounts['elevator_pulley_machine'] ?? 0, // Number
        count.itemCounts['feeding_pipes'] ?? 0, // Number
        count.itemCounts['external_drainage_pipes'] ?? 0, // Number
      ];

      for (int i = 0; i < rowData.length; i++) {
        _setCellValue(sheet, i, rowIndex, rowData[i]);
      }
      rowIndex++;
    }
  }

  void _createElectricalDamageSheet(Excel excel, List<DamageCount> allCounts,
      Map<String, String> schoolNames) {
    final sheet = excel['أعمال الكهرباء'];

    final headers = [
      'اسم المدرسة',
      'تاريخ الحصر',
      'قاطع كهرباني سعة (250) أمبير',
      'قاطع كهرباني سعة (400) أمبير',
      'قاطع كهرباني سعة 1250 أمبير',
      'أغطية لوحات التوزيع الفرعية',
      'كبل نحاس مسلح مقاس (4*16)',
      'لوحة توزيع فرعية (48) خط',
      'لوحة توزيع فرعية (36) خط',
      'سخانات المياه الكهربائية سعة 50 لتر',
      'سخانات المياه الكهربائية سعة 100 لتر',
    ];

    // Add headers
    for (int i = 0; i < headers.length; i++) {
      final cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
    }

    // Add data
    int rowIndex = 1;
    for (final count in allCounts) {
      final schoolName =
          schoolNames[count.schoolId] ?? 'مدرسة ${count.schoolId}';

      final rowData = [
        schoolName, // Text
        _formatDate(count.createdAt), // Text
        count.itemCounts['circuit_breaker_250'] ?? 0, // Number
        count.itemCounts['circuit_breaker_400'] ?? 0, // Number
        count.itemCounts['circuit_breaker_1250'] ?? 0, // Number
        count.itemCounts['electrical_distribution_unit'] ?? 0, // Number
        count.itemCounts['copper_cable'] ?? 0, // Number
        count.itemCounts['fluorescent_48w_main_branch'] ?? 0, // Number
        count.itemCounts['fluorescent_36w_sub_branch'] ?? 0, // Number
        count.itemCounts['electric_water_heater_50l'] ?? 0, // Number
        count.itemCounts['electric_water_heater_100l'] ?? 0, // Number
      ];

      for (int i = 0; i < rowData.length; i++) {
        _setCellValue(sheet, i, rowIndex, rowData[i]);
      }
      rowIndex++;
    }
  }

  void _createCivilDamageSheet(Excel excel, List<DamageCount> allCounts,
      Map<String, String> schoolNames) {
    final sheet = excel['أعمال مدنية'];

    final headers = [
      'اسم المدرسة',
      'تاريخ الحصر',
      'قماش مظلات من مادة (UPVC) لفة (50) متر مربع',
      'هبوط او تلف بلاط الموقع العام',
      'دهانات الواجهات الخارجية',
      'دهانات الحوائط والاسقف الداخلية',
      'اللياسة الخارجية',
      'لياسة الحوائط والاسقف الداخلية',
      'هبوط او تلف رخام الارضيات والحوائط الداخلية',
      'هبوط او تلف بلاط الارضيات والحوائط الداخلية',
      'عزل سطج المبنى الرئيسي',
      'النوافذ الداخلية',
      'النوافذ الخارجية',
      'شرائح معدنية ( اسقف مستعارة )',
      'تربيعات (اسقف مستعارة)',
      'الخزانات الارضية',
    ];

    // Add headers
    for (int i = 0; i < headers.length; i++) {
      final cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
    }

    // Add data
    int rowIndex = 1;
    for (final count in allCounts) {
      final schoolName =
          schoolNames[count.schoolId] ?? 'مدرسة ${count.schoolId}';

      final rowData = [
        schoolName, // Text
        _formatDate(count.createdAt), // Text
        count.itemCounts['upvc_50_meter'] ?? 0, // Number
        count.itemCounts['site_tile_damage'] ?? 0, // Number
        count.itemCounts['external_facade_paint'] ?? 0, // Number
        count.itemCounts['internal_wall_ceiling_paint'] ?? 0, // Number
        count.itemCounts['external_plastering'] ?? 0, // Number
        count.itemCounts['internal_wall_ceiling_plastering'] ?? 0, // Number
        count.itemCounts['internal_marble_damage'] ?? 0, // Number
        count.itemCounts['internal_tile_damage'] ?? 0, // Number
        count.itemCounts['main_building_roof_insulation'] ?? 0, // Number
        count.itemCounts['internal_windows'] ?? 0, // Number
        count.itemCounts['external_windows'] ?? 0, // Number
        count.itemCounts['metal_slats_suspended_ceiling'] ?? 0, // Number
        count.itemCounts['suspended_ceiling_grids'] ?? 0, // Number
        count.itemCounts['underground_tanks'] ?? 0, // Number
      ];

      for (int i = 0; i < rowData.length; i++) {
        _setCellValue(sheet, i, rowIndex, rowData[i]);
      }
      rowIndex++;
    }
  }

  void _createSafetyDamageSheet(Excel excel, List<DamageCount> allCounts,
      Map<String, String> schoolNames) {
    final sheet = excel['أعمال الامن والسلامة'];

    final headers = [
      'اسم المدرسة',
      'تاريخ الحصر',
      'محبس حريق OS&Y من قطر 4 بوصة',
      'لوحة انذار معنونه كاملة',
      'طفاية حريق Dry powder وزن 6 كيلو',
      'طفاية حريق CO2 وزن(9) كيلو',
      'مضخة حريق 1750 دورة/د',
      'مضخة حريق تعويضيه جوكي',
      'صدنوق إطفاء حريق',
      'شبكات الحريق والاطفاء',
      'اسلاك حرارية لشبكات الانذار',
    ];

    // Add headers
    for (int i = 0; i < headers.length; i++) {
      final cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
    }

    // Add data
    int rowIndex = 1;
    for (final count in allCounts) {
      final schoolName =
          schoolNames[count.schoolId] ?? 'مدرسة ${count.schoolId}';

      final rowData = [
        schoolName, // Text
        _formatDate(count.createdAt), // Text
        count.itemCounts['pvc_pipe_connection_4'] ?? 0, // Number
        count.itemCounts['fire_alarm_panel'] ?? 0, // Number
        count.itemCounts['dry_powder_6kg'] ?? 0, // Number
        count.itemCounts['co2_9kg'] ?? 0, // Number
        count.itemCounts['fire_pump_1750'] ?? 0, // Number
        count.itemCounts['joky_pump'] ?? 0, // Number
        count.itemCounts['fire_suppression_box'] ?? 0, // Number
        count.itemCounts['fire_extinguishing_networks'] ?? 0, // Number
        count.itemCounts['thermal_wires_alarm_networks'] ?? 0, // Number
      ];

      for (int i = 0; i < rowData.length; i++) {
        _setCellValue(sheet, i, rowIndex, rowData[i]);
      }
      rowIndex++;
    }
  }

  void _createAirConditioningDamageSheet(Excel excel,
      List<DamageCount> allCounts, Map<String, String> schoolNames) {
    final sheet = excel['التكييف'];

    final headers = [
      'اسم المدرسة',
      'تاريخ الحصر',
      'دولابي',
      'سبليت',
      'شباك',
      'باكدج',
    ];

    // Add headers
    for (int i = 0; i < headers.length; i++) {
      final cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
    }

    // Add data
    int rowIndex = 1;
    for (final count in allCounts) {
      final schoolName =
          schoolNames[count.schoolId] ?? 'مدرسة ${count.schoolId}';

      final rowData = [
        schoolName, // Text
        _formatDate(count.createdAt), // Text
        count.itemCounts['cabinet_ac'] ?? 0, // Number
        count.itemCounts['split_ac'] ?? 0, // Number
        count.itemCounts['window_ac'] ?? 0, // Number
        count.itemCounts['package_ac'] ?? 0, // Number
      ];

      for (int i = 0; i < rowData.length; i++) {
        _setCellValue(sheet, i, rowIndex, rowData[i]);
      }
      rowIndex++;
    }
  }

  void _createDamageSummarySheet(Excel excel, List<DamageCount> allCounts,
      Map<String, String> schoolNames) {
    final sheet = excel['ملخص التوالف'];

    // Title
    final titleCell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = 'ملخص حصر التوالف';

    // Summary data
    final schoolCounts = <String, int>{};
    final schoolTotalDamage = <String, int>{};

    for (final count in allCounts) {
      final schoolName =
          schoolNames[count.schoolId] ?? 'مدرسة ${count.schoolId}';
      schoolCounts[schoolName] = (schoolCounts[schoolName] ?? 0) + 1;
      schoolTotalDamage[schoolName] =
          (schoolTotalDamage[schoolName] ?? 0) + count.totalDamagedItems;
    }

    // Headers for summary
    final summaryHeaders = [
      'اسم المدرسة',
      'عدد الحصور',
      'إجمالي التوالف',
      'آخر تحديث',
      'الحالة'
    ];
    for (int i = 0; i < summaryHeaders.length; i++) {
      final cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2));
      cell.value = summaryHeaders[i];
    }

    // Add summary data
    int rowIndex = 3;
    for (final entry in schoolCounts.entries) {
      final schoolName = entry.key;
      final countNum = entry.value;
      final totalDamage = schoolTotalDamage[schoolName] ?? 0;

      // Find latest damage count for this school
      final latestCount = allCounts
          .where((c) =>
              (schoolNames[c.schoolId] ?? 'مدرسة ${c.schoolId}') == schoolName)
          .reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);

      final rowData = [
        schoolName, // Text
        countNum, // Number
        totalDamage, // Number
        _formatDate(latestCount.createdAt), // Text
        latestCount.status == 'submitted' ? 'مرسل' : 'مسودة', // Text
      ];

      for (int i = 0; i < rowData.length; i++) {
        _setCellValue(sheet, i, rowIndex, rowData[i]);
      }
      rowIndex++;
    }

    // Add totals
    final totalCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex + 1));
    totalCell.value = 'إجمالي المدارس: ${schoolCounts.length}';

    final totalCountsCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex + 2));
    totalCountsCell.value = 'إجمالي الحصور: ${allCounts.length}';

    final totalDamageCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex + 3));
    totalDamageCell.value =
        'إجمالي التوالف: ${schoolTotalDamage.values.fold(0, (sum, count) => sum + count)}';
  }

  Future<void> _exportDamageCountsSyncfusionWeb(List<DamageCount> allCounts, Map<String, String> schoolNames) async {
    final workbook = syncfusion.Workbook();

    // Mechanical Sheet
    final mechanicalSheet = workbook.worksheets[0];
    mechanicalSheet.name = 'أعمال الميكانيك والسباكة';
    
    // Title
    final mechanicalTitleRange = mechanicalSheet.getRangeByIndex(1, 1, 1, 15);
    mechanicalTitleRange.setText('حصر أعمال الميكانيك والسباكة');
    mechanicalTitleRange.cellStyle.fontSize = 16;
    mechanicalTitleRange.cellStyle.bold = true;
    mechanicalSheet.getRangeByIndex(1, 1, 1, 15).merge();
    
    final mechanicalHeaders = [
      'اسم المدرسة',
      'تاريخ الحصر',
      'كرسي شرقي',
      'كرسي افرنجي',
      'حوض مغسلة مع القاعدة',
      'صناديق طرد مخفي-للكرسي العربي',
      'صناديق طرد واطي-للكرسي الافرنجي',
      'مواسير upvc class 5',
      'خزان علوي فايبر جلاس سعة 5000 لتر',
      'خزان علوي فايبر جلاس سعة 4000 لتر',
      'خزان علوي فايبر جلاس سعة 3000 لتر',
      'مضخات مياة 3 حصان- Booster Pump',
      'محرك + صندوق تروس مصاعد - Elevators',
      'مواسير التغذية',
      'مواسير الصرف الخارجية',
    ];
    
    // Apply header styling
    final mechanicalHeaderRange = mechanicalSheet.getRangeByIndex(3, 1, 3, mechanicalHeaders.length);
    mechanicalHeaderRange.cellStyle.fontSize = 12;
    mechanicalHeaderRange.cellStyle.bold = true;
    
    for (int i = 0; i < mechanicalHeaders.length; i++) {
      mechanicalSheet.getRangeByIndex(3, i + 1).setText(mechanicalHeaders[i]);
    }
    
    for (int row = 0; row < allCounts.length; row++) {
      final count = allCounts[row];
      final rowData = [
        schoolNames[count.schoolId] ?? 'مدرسة ${count.schoolId}',
        _formatDate(count.createdAt),
        count.itemCounts['plastic_chair'] ?? 0,
        count.itemCounts['plastic_chair_external'] ?? 0,
        count.itemCounts['water_sink'] ?? 0,
        count.itemCounts['hidden_boxes'] ?? 0,
        count.itemCounts['low_boxes'] ?? 0,
        count.itemCounts['upvc_pipes_4_5'] ?? 0,
        count.itemCounts['glass_fiber_tank_5000'] ?? 0,
        count.itemCounts['glass_fiber_tank_4000'] ?? 0,
        count.itemCounts['glass_fiber_tank_3000'] ?? 0,
        count.itemCounts['booster_pump_3_phase'] ?? 0,
        count.itemCounts['elevator_pulley_machine'] ?? 0,
        count.itemCounts['feeding_pipes'] ?? 0,
        count.itemCounts['external_drainage_pipes'] ?? 0,
      ];
      
      mechanicalSheet.getRangeByIndex(row + 4, 1).setText(rowData[0].toString());
      mechanicalSheet.getRangeByIndex(row + 4, 2).setText(rowData[1].toString());
      for (int col = 2; col < rowData.length; col++) {
        mechanicalSheet.getRangeByIndex(row + 4, col + 1).setNumber(double.tryParse(rowData[col].toString()) ?? 0);
      }
    }

    // Electrical Sheet
    final electricalSheet = workbook.worksheets.addWithName('أعمال الكهرباء');
    
    // Title
    final electricalTitleRange = electricalSheet.getRangeByIndex(1, 1, 1, 11);
    electricalTitleRange.setText('حصر أعمال الكهرباء');
    electricalTitleRange.cellStyle.fontSize = 16;
    electricalTitleRange.cellStyle.bold = true;
    electricalSheet.getRangeByIndex(1, 1, 1, 11).merge();
    
    final electricalHeaders = [
      'اسم المدرسة',
      'تاريخ الحصر',
      'قاطع كهرباني سعة (250) أمبير',
      'قاطع كهرباني سعة (400) أمبير',
      'قاطع كهرباني سعة 1250 أمبير',
      'أغطية لوحات التوزيع الفرعية',
      'كبل نحاس مسلح مقاس (4*16)',
      'لوحة توزيع فرعية (48) خط',
      'لوحة توزيع فرعية (36) خط',
      'سخانات المياه الكهربائية سعة 50 لتر',
      'سخانات المياه الكهربائية سعة 100 لتر',
    ];
    
    // Apply header styling
    final electricalHeaderRange = electricalSheet.getRangeByIndex(3, 1, 3, electricalHeaders.length);
    electricalHeaderRange.cellStyle.fontSize = 12;
    electricalHeaderRange.cellStyle.bold = true;
    
    for (int i = 0; i < electricalHeaders.length; i++) {
      electricalSheet.getRangeByIndex(3, i + 1).setText(electricalHeaders[i]);
    }
    
    for (int row = 0; row < allCounts.length; row++) {
      final count = allCounts[row];
      final rowData = [
        schoolNames[count.schoolId] ?? 'مدرسة ${count.schoolId}',
        _formatDate(count.createdAt),
        count.itemCounts['circuit_breaker_250'] ?? 0,
        count.itemCounts['circuit_breaker_400'] ?? 0,
        count.itemCounts['circuit_breaker_1250'] ?? 0,
        count.itemCounts['electrical_distribution_unit'] ?? 0,
        count.itemCounts['copper_cable'] ?? 0,
        count.itemCounts['fluorescent_48w_main_branch'] ?? 0,
        count.itemCounts['fluorescent_36w_sub_branch'] ?? 0,
        count.itemCounts['electric_water_heater_50l'] ?? 0,
        count.itemCounts['electric_water_heater_100l'] ?? 0,
      ];
      
      electricalSheet.getRangeByIndex(row + 4, 1).setText(rowData[0].toString());
      electricalSheet.getRangeByIndex(row + 4, 2).setText(rowData[1].toString());
      for (int col = 2; col < rowData.length; col++) {
        electricalSheet.getRangeByIndex(row + 4, col + 1).setNumber(double.tryParse(rowData[col].toString()) ?? 0);
      }
    }

    // Civil Sheet
    final civilSheet = workbook.worksheets.addWithName('أعمال مدنية');
    
    // Title
    final civilTitleRange = civilSheet.getRangeByIndex(1, 1, 1, 16);
    civilTitleRange.setText('حصر الأعمال المدنية');
    civilTitleRange.cellStyle.fontSize = 16;
    civilTitleRange.cellStyle.bold = true;
    civilSheet.getRangeByIndex(1, 1, 1, 16).merge();
    
    final civilHeaders = [
      'اسم المدرسة',
      'تاريخ الحصر',
      'قماش مظلات من مادة (UPVC) لفة (50) متر مربع',
      'هبوط او تلف بلاط الموقع العام',
      'دهانات الواجهات الخارجية',
      'دهانات الحوائط والاسقف الداخلية',
      'اللياسة الخارجية',
      'لياسة الحوائط والاسقف الداخلية',
      'هبوط او تلف رخام الارضيات والحوائط الداخلية',
      'هبوط او تلف بلاط الارضيات والحوائط الداخلية',
      'عزل سطج المبنى الرئيسي',
      'النوافذ الداخلية',
      'النوافذ الخارجية',
      'شرائح معدنية ( اسقف مستعارة )',
      'تربيعات (اسقف مستعارة)',
      'الخزانات الارضية',
    ];
    
    // Apply header styling
    final civilHeaderRange = civilSheet.getRangeByIndex(3, 1, 3, civilHeaders.length);
    civilHeaderRange.cellStyle.fontSize = 12;
    civilHeaderRange.cellStyle.bold = true;
    
    for (int i = 0; i < civilHeaders.length; i++) {
      civilSheet.getRangeByIndex(3, i + 1).setText(civilHeaders[i]);
    }
    
    for (int row = 0; row < allCounts.length; row++) {
      final count = allCounts[row];
      final rowData = [
        schoolNames[count.schoolId] ?? 'مدرسة ${count.schoolId}',
        _formatDate(count.createdAt),
        count.itemCounts['upvc_50_meter'] ?? 0,
        count.itemCounts['site_tile_damage'] ?? 0,
        count.itemCounts['external_facade_paint'] ?? 0,
        count.itemCounts['internal_wall_ceiling_paint'] ?? 0,
        count.itemCounts['external_plastering'] ?? 0,
        count.itemCounts['internal_wall_ceiling_plastering'] ?? 0,
        count.itemCounts['internal_marble_damage'] ?? 0,
        count.itemCounts['internal_tile_damage'] ?? 0,
        count.itemCounts['main_building_roof_insulation'] ?? 0,
        count.itemCounts['internal_windows'] ?? 0,
        count.itemCounts['external_windows'] ?? 0,
        count.itemCounts['metal_slats_suspended_ceiling'] ?? 0,
        count.itemCounts['suspended_ceiling_grids'] ?? 0,
        count.itemCounts['underground_tanks'] ?? 0,
      ];
      
      civilSheet.getRangeByIndex(row + 4, 1).setText(rowData[0].toString());
      civilSheet.getRangeByIndex(row + 4, 2).setText(rowData[1].toString());
      for (int col = 2; col < rowData.length; col++) {
        civilSheet.getRangeByIndex(row + 4, col + 1).setNumber(double.tryParse(rowData[col].toString()) ?? 0);
      }
    }

    // Safety Sheet
    final safetySheet = workbook.worksheets.addWithName('أعمال الامن والسلامة');
    
    // Title
    final safetyTitleRange = safetySheet.getRangeByIndex(1, 1, 1, 11);
    safetyTitleRange.setText('حصر أعمال الأمن والسلامة');
    safetyTitleRange.cellStyle.fontSize = 16;
    safetyTitleRange.cellStyle.bold = true;
    safetySheet.getRangeByIndex(1, 1, 1, 11).merge();
    
    final safetyHeaders = [
      'اسم المدرسة',
      'تاريخ الحصر',
      'محبس حريق OS&Y من قطر 4 بوصة',
      'لوحة انذار معنونه كاملة',
      'طفاية حريق Dry powder وزن 6 كيلو',
      'طفاية حريق CO2 وزن(9) كيلو',
      'مضخة حريق 1750 دورة/د',
      'مضخة حريق تعويضيه جوكي',
      'صدنوق إطفاء حريق',
      'شبكات الحريق والاطفاء',
      'اسلاك حرارية لشبكات الانذار',
    ];
    
    // Apply header styling
    final safetyHeaderRange = safetySheet.getRangeByIndex(3, 1, 3, safetyHeaders.length);
    safetyHeaderRange.cellStyle.fontSize = 12;
    safetyHeaderRange.cellStyle.bold = true;
    
    for (int i = 0; i < safetyHeaders.length; i++) {
      safetySheet.getRangeByIndex(3, i + 1).setText(safetyHeaders[i]);
    }
    
    for (int row = 0; row < allCounts.length; row++) {
      final count = allCounts[row];
      final rowData = [
        schoolNames[count.schoolId] ?? 'مدرسة ${count.schoolId}',
        _formatDate(count.createdAt),
        count.itemCounts['pvc_pipe_connection_4'] ?? 0,
        count.itemCounts['fire_alarm_panel'] ?? 0,
        count.itemCounts['dry_powder_6kg'] ?? 0,
        count.itemCounts['co2_9kg'] ?? 0,
        count.itemCounts['fire_pump_1750'] ?? 0,
        count.itemCounts['joky_pump'] ?? 0,
        count.itemCounts['fire_suppression_box'] ?? 0,
        count.itemCounts['fire_extinguishing_networks'] ?? 0,
        count.itemCounts['thermal_wires_alarm_networks'] ?? 0,
      ];
      
      safetySheet.getRangeByIndex(row + 4, 1).setText(rowData[0].toString());
      safetySheet.getRangeByIndex(row + 4, 2).setText(rowData[1].toString());
      for (int col = 2; col < rowData.length; col++) {
        safetySheet.getRangeByIndex(row + 4, col + 1).setNumber(double.tryParse(rowData[col].toString()) ?? 0);
      }
    }

    // Air Conditioning Sheet
    final acSheet = workbook.worksheets.addWithName('التكييف');
    
    // Title
    final acTitleRange = acSheet.getRangeByIndex(1, 1, 1, 6);
    acTitleRange.setText('حصر التكييف');
    acTitleRange.cellStyle.fontSize = 16;
    acTitleRange.cellStyle.bold = true;
    acSheet.getRangeByIndex(1, 1, 1, 6).merge();
    
    final acHeaders = [
      'اسم المدرسة',
      'تاريخ الحصر',
      'دولابي',
      'سبليت',
      'شباك',
      'باكدج',
    ];
    
    // Apply header styling
    final acHeaderRange = acSheet.getRangeByIndex(3, 1, 3, acHeaders.length);
    acHeaderRange.cellStyle.fontSize = 12;
    acHeaderRange.cellStyle.bold = true;
    
    for (int i = 0; i < acHeaders.length; i++) {
      acSheet.getRangeByIndex(3, i + 1).setText(acHeaders[i]);
    }
    
    for (int row = 0; row < allCounts.length; row++) {
      final count = allCounts[row];
      final rowData = [
        schoolNames[count.schoolId] ?? 'مدرسة ${count.schoolId}',
        _formatDate(count.createdAt),
        count.itemCounts['cabinet_ac'] ?? 0,
        count.itemCounts['split_ac'] ?? 0,
        count.itemCounts['window_ac'] ?? 0,
        count.itemCounts['package_ac'] ?? 0,
      ];
      
      acSheet.getRangeByIndex(row + 4, 1).setText(rowData[0].toString());
      acSheet.getRangeByIndex(row + 4, 2).setText(rowData[1].toString());
      for (int col = 2; col < rowData.length; col++) {
        acSheet.getRangeByIndex(row + 4, col + 1).setNumber(double.tryParse(rowData[col].toString()) ?? 0);
      }
    }

    // Summary Sheet
    final summarySheet = workbook.worksheets.addWithName('ملخص التوالف');
    
    // Title
    final summaryTitleRange = summarySheet.getRangeByIndex(1, 1, 1, 5);
    summaryTitleRange.setText('ملخص حصر التوالف');
    summaryTitleRange.cellStyle.fontSize = 18;
    summaryTitleRange.cellStyle.bold = true;
    summarySheet.getRangeByIndex(1, 1, 1, 5).merge();
    
    final schoolCounts = <String, int>{};
    final schoolTotalDamage = <String, int>{};
    for (final count in allCounts) {
      final schoolName = schoolNames[count.schoolId] ?? 'مدرسة ${count.schoolId}';
      schoolCounts[schoolName] = (schoolCounts[schoolName] ?? 0) + 1;
      schoolTotalDamage[schoolName] = (schoolTotalDamage[schoolName] ?? 0) + count.totalDamagedItems;
    }
    
    final summaryHeaders = [
      'اسم المدرسة',
      'عدد الحصور',
      'إجمالي التوالف',
      'آخر تحديث',
      'الحالة'
    ];
    
    // Apply header styling
    final summaryHeaderRange = summarySheet.getRangeByIndex(3, 1, 3, summaryHeaders.length);
    summaryHeaderRange.cellStyle.fontSize = 12;
    summaryHeaderRange.cellStyle.bold = true;
    
    for (int i = 0; i < summaryHeaders.length; i++) {
      summarySheet.getRangeByIndex(3, i + 1).setText(summaryHeaders[i]);
    }
    
    int rowIndex = 4;
    for (final entry in schoolCounts.entries) {
      final schoolName = entry.key;
      final countNum = entry.value;
      final totalDamage = schoolTotalDamage[schoolName] ?? 0;
      final latestCount = allCounts
          .where((c) => (schoolNames[c.schoolId] ?? 'مدرسة ${c.schoolId}') == schoolName)
          .reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);
      final rowData = [
        schoolName,
        countNum,
        totalDamage,
        _formatDate(latestCount.createdAt),
        latestCount.status == 'submitted' ? 'مرسل' : 'مسودة',
      ];
      
      summarySheet.getRangeByIndex(rowIndex, 1).setText(rowData[0].toString());
      summarySheet.getRangeByIndex(rowIndex, 2).setNumber(double.tryParse(rowData[1].toString()) ?? 0);
      summarySheet.getRangeByIndex(rowIndex, 3).setNumber(double.tryParse(rowData[2].toString()) ?? 0);
      summarySheet.getRangeByIndex(rowIndex, 4).setText(rowData[3].toString());
      summarySheet.getRangeByIndex(rowIndex, 5).setText(rowData[4].toString());
      rowIndex++;
    }
    
    // Summary footer
    final footerRange1 = summarySheet.getRangeByIndex(rowIndex + 1, 1);
    footerRange1.setText('إجمالي المدارس: ${schoolCounts.length}');
    footerRange1.cellStyle.fontSize = 12;
    footerRange1.cellStyle.bold = true;
    
    final footerRange2 = summarySheet.getRangeByIndex(rowIndex + 2, 1);
    footerRange2.setText('إجمالي الحصور: ${allCounts.length}');
    footerRange2.cellStyle.fontSize = 12;
    footerRange2.cellStyle.bold = true;
    
    final footerRange3 = summarySheet.getRangeByIndex(rowIndex + 3, 1);
    footerRange3.setText('إجمالي التوالف: ${schoolTotalDamage.values.fold(0, (sum, count) => sum + count)}');
    footerRange3.cellStyle.fontSize = 12;
    footerRange3.cellStyle.bold = true;

    // Save and download
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final blob = html.Blob([Uint8List.fromList(bytes)]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'حصر التوالف.xlsx')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _setCellValue(
      Sheet sheet, int columnIndex, int rowIndex, dynamic value) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(
        columnIndex: columnIndex, rowIndex: rowIndex));

    if (value is int) {
      cell.value = value;
    } else if (value is double) {
      cell.value = value;
    } else if (value is String && value.isNotEmpty) {
      cell.value = value;
    } else {
      cell.value = '';
    }
  }

  Future<void> exportAllMaintenanceCountsSimplified() async {
    // Prevent multiple simultaneous downloads
    if (_isDownloading) {
      throw Exception('Download already in progress. Please wait.');
    }
    
    _isDownloading = true;
    
    try {
      print('🚀 Starting simplified maintenance counts export...');
      
      // Get all maintenance counts and school names with timeout
      final allCounts = await _getAllMaintenanceCounts()
          .timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Database query timeout - taking too long to fetch data');
      });
      
      final schoolNames = await _getSchoolNamesMap()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('School names query timeout');
      });

      print('📊 Data to export: ${allCounts.length} records');

      if (allCounts.isEmpty) {
        throw Exception('No maintenance counts found');
      }

      // Use excel package for simplified export
      final excel = Excel.createExcel();
      excel.delete('Sheet1');
      
      // Create a comprehensive summary sheet
      final sheet = excel['حصر الصيانة المبسط'];
      
      // Headers for simplified export
      final headers = [
        'اسم المدرسة',
        'تاريخ الحصر',
        'الحالة',
        'عدد العناصر',
        'عدد الإجابات النصية',
        'عدد الإجابات نعم/لا',
        'ملاحظات الصيانة',
        'بيانات لوحة الإنذار',
        'بيانات التكييف',
        'بيانات السخانات',
      ];
      
      // Add headers
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = headers[i];
      }
      
      // Add data rows
      print('📝 Adding data rows...');
      for (int row = 0; row < allCounts.length; row++) {
        final count = allCounts[row];
        
        // Progress logging every 20 rows
        if (row % 20 == 0) {
          print('   📊 Processing row ${row + 1}/${allCounts.length}');
        }
        
        final rowData = [
          schoolNames[count.schoolId] ?? 'مدرسة ${count.schoolId}',
          _formatDate(count.createdAt),
          count.status == 'submitted' ? 'مرسل' : 'مسودة',
          count.itemCounts.length,
          count.textAnswers.length,
          count.yesNoAnswers.length,
          count.maintenanceNotes.isNotEmpty ? 'نعم' : 'لا',
          count.fireSafetyAlarmPanelData.isNotEmpty ? 'نعم' : 'لا',
          count.fireSafetyConditionOnlyData.isNotEmpty ? 'نعم' : 'لا',
          count.heaterEntries.isNotEmpty ? 'نعم' : 'لا',
        ];
        
        for (int i = 0; i < rowData.length; i++) {
          _setCellValue(sheet, i, row + 1, rowData[i]);
        }
      }
      
      // Save and download
      print('💾 Saving simplified export...');
      final bytes = excel.encode();
      if (bytes == null) {
        throw Exception('Failed to generate simplified Excel file');
      }
      
      print('✅ Simplified export saved, size: ${bytes.length} bytes');
      
      if (kIsWeb) {
        print('🌐 Creating web download for simplified export...');
        final blob = html.Blob([Uint8List.fromList(bytes)]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'حصر الصيانة المبسط.xlsx')
          ..click();
        html.Url.revokeObjectUrl(url);
        print('✅ Simplified web download completed');
      } else {
        print('📱 Creating mobile download for simplified export...');
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/حصر الصيانة المبسط.xlsx';
        final file = File(path);
        await file.writeAsBytes(bytes, flush: true);
        await Share.shareXFiles([XFile(path)], text: 'حصر الصيانة المبسط');
        print('✅ Simplified mobile download completed');
      }
      
    } catch (e) {
      print('❌ Simplified export error: $e');
      throw Exception('Failed to export simplified Excel: ${e.toString()}');
    } finally {
      // Always reset the downloading state, even on error
      _isDownloading = false;
    }
  }

}
