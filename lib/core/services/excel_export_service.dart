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

class ExcelExportService {
  final MaintenanceCountRepository _repository;
  final DamageCountRepository? _damageRepository;

  ExcelExportService(this._repository,
      {DamageCountRepository? damageRepository})
      : _damageRepository = damageRepository;

  Future<void> exportAllMaintenanceCounts() async {
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

      // Get all maintenance counts and school names
      final allCounts = await _getAllMaintenanceCounts();
      final schoolNames = await _getSchoolNamesMap();

      if (allCounts.isEmpty) {
        throw Exception('No maintenance counts found');
      }

      // Create Excel workbook
      final excel = Excel.createExcel();

      // Remove default sheet
      excel.delete('Sheet1');

      // Create sheets for each category
      _createSafetySheet(excel, allCounts, schoolNames);
      _createMechanicalSheet(excel, allCounts, schoolNames);
      _createElectricalSheet(excel, allCounts, schoolNames);
      _createCivilSheet(excel, allCounts, schoolNames);
      _createSummarySheet(excel, allCounts, schoolNames);

      // Save and share the file
      await _saveAndShareExcel(excel);
    } catch (e) {
      throw Exception('Failed to export Excel: ${e.toString()}');
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

      // Create Excel workbook
      final excel = Excel.createExcel();

      // Remove default sheet
      excel.delete('Sheet1');

      // Create sheets for each category
      _createMechanicalDamageSheet(excel, allCounts, schoolNames);
      _createElectricalDamageSheet(excel, allCounts, schoolNames);
      _createCivilDamageSheet(excel, allCounts, schoolNames);
      _createSafetyDamageSheet(excel, allCounts, schoolNames);
      _createAirConditioningDamageSheet(excel, allCounts, schoolNames);
      _createDamageSummarySheet(excel, allCounts, schoolNames);

      // Save and share the file
      await _saveAndShareDamageExcel(excel);
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

  void _createSafetySheet(Excel excel, List<MaintenanceCount> allCounts,
      Map<String, String> schoolNames) {
    final sheet = excel['أمن وسلامة'];

    // Headers
    final headers = [
      'اسم المدرسة',
      'تاريخ الحصر',
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
      'حالة أجراس كسر الزجاج',
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
        int.tryParse(count.itemCounts['fire_boxes']?.toString() ?? '0') ??
            0, // Number
        count.surveyAnswers['fire_boxes_condition'] ?? '', // Text
        int.tryParse(
                count.itemCounts['fire_extinguishers']?.toString() ?? '0') ??
            0, // Number
        _getFireExtinguisherExpiryDate(count), // Text
        int.tryParse(count.itemCounts['diesel_pump']?.toString() ?? '0') ??
            0, // Number
        count.surveyAnswers['diesel_pump_condition'] ?? '', // Text
        int.tryParse(count.itemCounts['electric_pump']?.toString() ?? '0') ??
            0, // Number
        count.surveyAnswers['electric_pump_condition'] ?? '', // Text
        int.tryParse(count.itemCounts['auxiliary_pump']?.toString() ?? '0') ??
            0, // Number
        count.surveyAnswers['auxiliary_pump_condition'] ?? '', // Text
        count.fireSafetyAlarmPanelData['alarm_panel_type'] ?? '', // Text
        int.tryParse(count.fireSafetyAlarmPanelData['alarm_panel_count']
                    ?.toString() ??
                '0') ??
            0, // Number
        count.surveyAnswers['alarm_panel_condition'] ?? '', // Text
        count.surveyAnswers['fire_alarm_system_condition'] ?? '', // Text
        count.surveyAnswers['fire_suppression_system_condition'] ?? '', // Text
        count.surveyAnswers['emergency_exits_condition'] ?? '', // Text
        count.surveyAnswers['emergency_lights_condition'] ?? '', // Text
        count.surveyAnswers['smoke_detectors_condition'] ?? '', // Text
        count.surveyAnswers['heat_detectors_condition'] ?? '', // Text
        count.surveyAnswers['break_glasses_bells_condition'] ?? '', // Text
      ];

      for (int i = 0; i < rowData.length; i++) {
        _setCellValue(sheet, i, rowIndex, rowData[i]);
      }
      rowIndex++;
    }
  }

  void _createMechanicalSheet(Excel excel, List<MaintenanceCount> allCounts,
      Map<String, String> schoolNames) {
    final sheet = excel['ميكانيكا'];

    final headers = [
      'اسم المدرسة',
      'تاريخ الحصر',
      'مضخات المياه',
      'رقم عداد المياه',
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
        int.tryParse(count.itemCounts['water_pumps']?.toString() ?? '0') ??
            0, // Number
        count.textAnswers['water_meter_number'] ?? '', // Text
      ];

      for (int i = 0; i < rowData.length; i++) {
        _setCellValue(sheet, i, rowIndex, rowData[i]);
      }
      rowIndex++;
    }
  }

  void _createElectricalSheet(Excel excel, List<MaintenanceCount> allCounts,
      Map<String, String> schoolNames) {
    final sheet = excel['كهرباء'];

    final headers = [
      'اسم المدرسة',
      'تاريخ الحصر',
      'اللوحات الكهربائية',
      'رقم عداد الكهرباء',
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
        int.tryParse(
                count.itemCounts['electrical_panels']?.toString() ?? '0') ??
            0, // Number
        count.textAnswers['electricity_meter_number'] ?? '', // Text
      ];

      for (int i = 0; i < rowData.length; i++) {
        _setCellValue(sheet, i, rowIndex, rowData[i]);
      }
      rowIndex++;
    }
  }

  void _createCivilSheet(Excel excel, List<MaintenanceCount> allCounts,
      Map<String, String> schoolNames) {
    final sheet = excel['مدني'];

    final headers = [
      'اسم المدرسة',
      'تاريخ الحصر',
      'تشققات في الجدران',
      'يوجد مصاعد',
      'سقوط الظلال',
      'يوجد تسريب مياه',
      'ارتفاع السياج منخفض',
      'أضرار صدأ الخرسانة',
      'أضرار عزل السطح',
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
        count.yesNoAnswers['wall_cracks'] == true ? 'نعم' : 'لا', // Text
        count.yesNoAnswers['has_elevators'] == true ? 'نعم' : 'لا', // Text
        count.yesNoAnswers['falling_shades'] == true ? 'نعم' : 'لا', // Text
        count.yesNoAnswers['has_water_leaks'] == true ? 'نعم' : 'لا', // Text
        count.yesNoAnswers['low_railing_height'] == true ? 'نعم' : 'لا', // Text
        count.yesNoAnswers['concrete_rust_damage'] == true
            ? 'نعم'
            : 'لا', // Text
        count.yesNoAnswers['roof_insulation_damage'] == true
            ? 'نعم'
            : 'لا', // Text
      ];

      for (int i = 0; i < rowData.length; i++) {
        _setCellValue(sheet, i, rowIndex, rowData[i]);
      }
      rowIndex++;
    }
  }

  void _createSummarySheet(Excel excel, List<MaintenanceCount> allCounts,
      Map<String, String> schoolNames) {
    final sheet = excel['ملخص'];

    // Title
    final titleCell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = 'ملخص حصر الصيانة';

    // Summary data
    final schoolCounts = <String, int>{};
    for (final count in allCounts) {
      final schoolName =
          schoolNames[count.schoolId] ?? 'مدرسة ${count.schoolId}';
      schoolCounts[schoolName] = (schoolCounts[schoolName] ?? 0) + 1;
    }

    // Headers for summary
    final summaryHeaders = ['اسم المدرسة', 'عدد الحصور', 'آخر تحديث', 'الحالة'];
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

      // Find latest maintenance count for this school
      final latestCount = allCounts
          .where((c) =>
              (schoolNames[c.schoolId] ?? 'مدرسة ${c.schoolId}') == schoolName)
          .reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);

      final rowData = [
        schoolName, // Text
        countNum, // Number
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
  }

  Future<void> _saveAndShareExcel(Excel excel) async {
    try {
      final bytes = excel.save()!;
      final fileName =
          'حصر الاعداد والحالة_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      if (kIsWeb) {
        // For web, trigger download using a different approach
        await _downloadFileOnWeb(bytes, fileName);
      } else {
        // For mobile, save to local directory then share
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';

        // Save file
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        // Share file
        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'ملف حصر الصيانة',
          subject: 'تصدير حصر الصيانة',
        );
      }
    } catch (e) {
      throw Exception('Failed to save Excel file: ${e.toString()}');
    }
  }

  Future<void> _downloadFileOnWeb(List<int> bytes, String fileName) async {
    if (kIsWeb) {
      try {
        // Create a blob with the Excel data
        final blob = html.Blob([
          bytes
        ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');

        // Create a download URL
        final url = html.Url.createObjectUrlFromBlob(blob);

        // Create an anchor element and trigger the download
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..style.display = 'none';

        // Add to DOM, click, and remove
        html.document.body!.children.add(anchor);
        anchor.click();
        html.document.body!.children.remove(anchor);

        // Clean up the URL
        html.Url.revokeObjectUrl(url);

        if (kDebugMode) {
          print('File downloaded successfully with name: $fileName');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error downloading file on web: $e');
        }
        // Fallback to share plugin if HTML download fails
        try {
          await Share.shareXFiles(
            [
              XFile.fromData(
                Uint8List.fromList(bytes),
                name: fileName,
                mimeType:
                    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
              )
            ],
            text: 'ملف حصر الصيانة',
            subject: 'تصدير حصر الصيانة',
          );
        } catch (shareError) {
          // Even if share fails, don't throw error as download might have worked
          if (kDebugMode) {
            print('Share fallback also failed: $shareError');
          }
        }
      }
    }
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

  String _getFireExtinguisherExpiryDate(MaintenanceCount count) {
    final day = count.textAnswers['fire_extinguishers_expiry_day'] ?? '';
    final month = count.textAnswers['fire_extinguishers_expiry_month'] ?? '';
    final year = count.textAnswers['fire_extinguishers_expiry_year'] ?? '';

    if (day.isNotEmpty && month.isNotEmpty && year.isNotEmpty) {
      return '$day/$month/$year';
    }
    return '';
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

  Future<void> _saveAndShareDamageExcel(Excel excel) async {
    try {
      final bytes = excel.save()!;
      final fileName =
          'حصر التوالف_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      if (kIsWeb) {
        // For web, trigger download using a different approach
        await _downloadFileOnWebDamage(bytes, fileName);
      } else {
        // For mobile, save to local directory then share
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';

        // Save file
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        // Share file
        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'ملف حصر التوالف',
          subject: 'تصدير حصر التوالف',
        );
      }
    } catch (e) {
      throw Exception('Failed to save and share damage Excel: $e');
    }
  }

  Future<void> _downloadFileOnWebDamage(
      List<int> bytes, String fileName) async {
    if (kIsWeb) {
      try {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download = fileName;
        html.document.body?.children.add(anchor);

        // trigger download
        anchor.click();

        // cleanup
        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
      } catch (e) {
        if (kDebugMode) {
          print('Error downloading damage file on web: $e');
        }
        // Fallback to share plugin if HTML download fails
        try {
          await Share.shareXFiles(
            [
              XFile.fromData(
                Uint8List.fromList(bytes),
                name: fileName,
                mimeType:
                    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
              )
            ],
            text: 'ملف حصر التوالف',
            subject: 'تصدير حصر التوالف',
          );
        } catch (shareError) {
          // Even if share fails, don't throw error as download might have worked
          if (kDebugMode) {
            print('Share fallback also failed: $shareError');
          }
        }
      }
    }
  }
}
