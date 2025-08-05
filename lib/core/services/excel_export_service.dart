import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/maintenance_count.dart';
import '../../data/models/damage_count.dart';
import '../../data/repositories/maintenance_count_repository.dart';
import '../../data/repositories/damage_count_repository.dart';
import '../../data/repositories/supervisor_repository.dart';
import '../services/admin_service.dart';
import '../../data/models/maintenance_count.dart' show MaintenanceItemTypes;
// Web-specific imports - conditional
import 'dart:html' as html;
// Conditional import for Syncfusion - only import if available
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as syncfusion;

class ExcelExportService {
  final MaintenanceCountRepository _repository;
  final DamageCountRepository? _damageRepository;
  final AdminService _adminService;
  final SupervisorRepository _supervisorRepository;
  
  // Global state to prevent multiple simultaneous downloads
  static bool _isDownloading = false;

  ExcelExportService(this._repository,
      {DamageCountRepository? damageRepository,
      SupervisorRepository? supervisorRepository})
      : _damageRepository = damageRepository,
        _adminService = AdminService(Supabase.instance.client),
        _supervisorRepository = supervisorRepository ?? SupervisorRepository(Supabase.instance.client);

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

      // Get all maintenance counts and school names with increased timeout and chunking
      print('🔍 Fetching maintenance counts data...');
      final allCounts = await _getAllMaintenanceCounts()
          .timeout(const Duration(seconds: 120), onTimeout: () {
        throw Exception('Database query timeout - taking too long to fetch data. Please try with fewer schools or contact support.');
      });
      
      print('🔍 Fetching school names...');
      final schoolNames = await _getSchoolNamesMap()
          .timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('School names query timeout. Please try again.');
      });

      print('Total maintenance counts: ${allCounts.length}'); // Debug
      
      // Validate data before export
      if (allCounts.isEmpty) {
        throw Exception('No maintenance counts found');
      }

      // Check if dataset is too large and suggest simplified export
      if (allCounts.length > 100) {
        print('⚠️ Large dataset detected: ${allCounts.length} records');
        print('💡 Consider using simplified export for better performance');
      }
      
      // Add progress tracking for large exports
      if (allCounts.length > 50) {
        print('📊 Processing ${allCounts.length} records...');
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

      // For very large datasets, use simplified export
      if (allCounts.length > 1000) {
        print('📊 Large dataset detected (${allCounts.length} records). Using simplified export...');
        await _exportMaintenanceCountsSimplified(allCounts, schoolNames)
            .timeout(const Duration(minutes: 3), onTimeout: () {
          throw Exception('Export timeout - taking too long to generate file. Please try with fewer schools.');
        });
      } else if (syncfusionAvailable) {
        try {
          // Add timeout to prevent hanging
          print('🔄 Using Syncfusion for export...');
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
        try {
          await _exportMaintenanceCountsExcelPackage(allCounts, schoolNames)
              .timeout(const Duration(minutes: 1), onTimeout: () {
            throw Exception('Export timeout - taking too long to generate file');
          });
        } catch (excelPackageError) {
          print('Excel package fallback failed: $excelPackageError');
          print('Trying basic Excel export as final fallback...');
          await _exportMaintenanceCountsBasic(allCounts, schoolNames)
              .timeout(const Duration(minutes: 1), onTimeout: () {
            throw Exception('Basic export timeout - taking too long to generate file');
          });
        }
      }
    } catch (e) {
      print('❌ Export error: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Error stack trace: ${StackTrace.current}');
      
      // Provide more specific error messages
      String errorMessage = 'Failed to export Excel';
      if (e.toString().contains('No maintenance counts found')) {
        errorMessage = 'No maintenance counts found';
      } else if (e.toString().contains('Storage permission denied')) {
        errorMessage = 'Storage permission denied';
      } else if (e.toString().contains('Download already in progress')) {
        errorMessage = 'Download already in progress';
      } else if (e.toString().contains('Export timeout')) {
        errorMessage = 'Export timeout - taking too long to generate file';
      } else if (e.toString().contains('Database query timeout')) {
        errorMessage = 'Database query timeout - taking too long to fetch data';
      } else if (e.toString().contains('School names query timeout')) {
        errorMessage = 'School names query timeout';
      } else {
        errorMessage = 'Failed to export Excel: ${e.toString()}';
      }
      
      throw Exception(errorMessage);
    } finally {
      stopwatch.stop();
      print('⏱️ Export completed in ${stopwatch.elapsed.inSeconds} seconds');
      // Always reset the downloading state, even on error
      _isDownloading = false;
    }
  }

  // Helper methods for summary calculations
  Map<String, int> _calculateCategoryTotals(List<MaintenanceCount> allCounts) {
    final Map<String, int> totals = {};
    int totalHeaters = 0; // Sum all heaters into one category
    
    for (final count in allCounts) {
      // Calculate total heaters for this count (same logic as maintenance_count_detail_screen.dart)
      int countHeaters = 0;
      final heaterEntries = count.heaterEntries;
      
      if (heaterEntries.isNotEmpty) {
        // Process new heater structure
        final bathroomHeaters = heaterEntries['bathroom_heaters'] as List<dynamic>?;
        if (bathroomHeaters != null) {
          for (final heater in bathroomHeaters) {
            if (heater is Map<String, dynamic>) {
              final id = heater['id']?.toString() ?? '';
              if (id.isNotEmpty) {
                final heaterKey = 'bathroom_heaters_$id';
                int heaterCount = count.itemCounts[heaterKey] ?? 0;
                
                // If no count in itemCounts, try to get from heater entry or default to 1
                if (heaterCount == 0) {
                  heaterCount = int.tryParse(heater['quantity']?.toString() ?? '1') ?? 1;
                }
                
                countHeaters += heaterCount;
              }
            }
          }
        }
        
        final cafeteriaHeaters = heaterEntries['cafeteria_heaters'] as List<dynamic>?;
        if (cafeteriaHeaters != null) {
          for (final heater in cafeteriaHeaters) {
            if (heater is Map<String, dynamic>) {
              final id = heater['id']?.toString() ?? '';
              if (id.isNotEmpty) {
                final heaterKey = 'cafeteria_heaters_$id';
                int heaterCount = count.itemCounts[heaterKey] ?? 0;
                
                // If no count in itemCounts, try to get from heater entry or default to 1
                if (heaterCount == 0) {
                  heaterCount = int.tryParse(heater['quantity']?.toString() ?? '1') ?? 1;
                }
                
                countHeaters += heaterCount;
              }
            }
          }
        }
      } else {
        // Fallback to old structure
        countHeaters += count.itemCounts['bathroom_heaters'] ?? 0;
        countHeaters += count.itemCounts['cafeteria_heaters'] ?? 0;
      }
      
      totalHeaters += countHeaters;
      
      // Process all other items (excluding individual heater entries)
      for (final entry in count.itemCounts.entries) {
        final key = entry.key;
        final value = entry.value;
        
        // Skip individual heater entries - we'll handle them as one "سخانات" total
        if (key.startsWith('bathroom_heaters_') || 
            key.startsWith('cafeteria_heaters_') ||
            key == 'bathroom_heaters' || 
            key == 'cafeteria_heaters') {
          continue;
        }
        
        totals[key] = (totals[key] ?? 0) + value;
      }
    }
    
    // Add combined heaters total
    if (totalHeaters > 0) {
      totals['سخانات'] = totalHeaters;
    }
    
    return totals;
  }
  
  int _countSchoolsWithItem(List<MaintenanceCount> allCounts, String itemKey) {
    final schoolsWithItem = <String>{};
    
    for (final count in allCounts) {
      if (itemKey == 'سخانات') {
        // Special handling for combined heaters
        bool hasHeaters = false;
        final heaterEntries = count.heaterEntries;
        
        if (heaterEntries.isNotEmpty) {
          // Check new heater structure
          final bathroomHeaters = heaterEntries['bathroom_heaters'] as List<dynamic>?;
          final cafeteriaHeaters = heaterEntries['cafeteria_heaters'] as List<dynamic>?;
          
          if (bathroomHeaters != null && bathroomHeaters.isNotEmpty) {
            for (final heater in bathroomHeaters) {
              if (heater is Map<String, dynamic>) {
                final id = heater['id']?.toString() ?? '';
                if (id.isNotEmpty) {
                  final heaterKey = 'bathroom_heaters_$id';
                  if ((count.itemCounts[heaterKey] ?? 0) > 0) {
                    hasHeaters = true;
                    break;
                  }
                }
              }
            }
          }
          
          if (!hasHeaters && cafeteriaHeaters != null && cafeteriaHeaters.isNotEmpty) {
            for (final heater in cafeteriaHeaters) {
              if (heater is Map<String, dynamic>) {
                final id = heater['id']?.toString() ?? '';
                if (id.isNotEmpty) {
                  final heaterKey = 'cafeteria_heaters_$id';
                  if ((count.itemCounts[heaterKey] ?? 0) > 0) {
                    hasHeaters = true;
                    break;
                  }
                }
              }
            }
          }
        } else {
          // Check old structure
          hasHeaters = (count.itemCounts['bathroom_heaters'] ?? 0) > 0 || 
                      (count.itemCounts['cafeteria_heaters'] ?? 0) > 0;
        }
        
        if (hasHeaters) {
          schoolsWithItem.add(count.schoolId);
        }
      } else {
        // Normal item handling
        if (count.itemCounts.containsKey(itemKey) && count.itemCounts[itemKey]! > 0) {
          schoolsWithItem.add(count.schoolId);
        }
      }
    }
    
    return schoolsWithItem.length;
  }
  
  String _getItemDisplayName(String itemKey) {
    final displayNames = {
      // Fire Safety Items
      'fire_hose': 'خرطوم الحريق',
      'fire_boxes': 'صناديق الحريق',
      'fire_extinguishers': 'طفايات الحريق',
      'diesel_pump': 'مضخة الديزل',
      'electric_pump': 'مضخة الكهرباء',
      'auxiliary_pump': 'المضخة المساعدة',
      'emergency_lights': 'كشافات الطوارئ',
      'emergency_exits': 'مخارج الطوارئ',
      'smoke_detectors': 'كواشف دخان',
      'heat_detectors': 'كواشف حرارة',
      'breakers': 'كواسر',
      'bells': 'أجراس',
      
      // Electrical Panels
      'lighting_panel': 'لوحة إنارة',
      'power_panel': 'لوحة باور',
      'ac_panel': 'لوحة تكييف',
      'main_distribution_panel': 'لوحة توزيع رئيسية',
      
      // Electrical Breakers
      'main_breaker': 'القاطع الرئيسي',
      'concealed_ac_breaker': 'قاطع تكييف (كونسيلد)',
      'package_ac_breaker': 'قاطع تكييف (باكدج)',
      
      // Electrical Items
      'lamps': 'لمبات',
      'projector': 'بروجيكتور',
      'class_bell': 'جرس الفصول',
      'speakers': 'السماعات',
      'microphone_system': 'نظام الميكوفون',
      
      // Air Conditioning Items
      'cabinet_ac': 'تكييف دولابي',
      'split_concealed_ac': 'تكييف سبليت',
      'hidden_ducts_ac': 'تكييف مخفي بداكت',
      'window_ac': 'تكييف شباك',
      'package_ac': 'تكييف باكدج',
      
      // Mechanical Items
      'water_pumps': 'مضخات المياه',
      'hand_sink': 'مغسلة يد',
      'basin_sink': 'مغسلة حوض',
      'western_toilet': 'كرسي افرنجي',
      'arabic_toilet': 'كرسي عربي',
      'arabic_siphon': 'سيفون عربي',
      'english_siphon': 'سيفون افرنجي',
      'bidets': 'شطافات',
      'wall_exhaust_fans': 'مراوح شفط جدارية',
      'central_exhaust_fans': 'مراوح شفط مركزية',
      'cafeteria_exhaust_fans': 'مراوح شفط (مقصف)',
      'wall_water_coolers': 'برادات مياه جدارية',
      'corridor_water_coolers': 'برادات مياه للممرات',
      'sink_mirrors': 'مرايا المغاسل',
      'wall_tap': 'خلاط الحائط',
      'sink_tap': 'خلاط المغسلة',
      'upper_tank': 'خزان علوي',
      'lower_tank': 'خزان سفلي',
      
      // Civil Items
      'blackboard': 'سبورة',
      'internal_windows': 'نوافذ داخلية',
      'external_windows': 'نوافذ خارجية',
      'single_door': 'باب مفرد',
      'double_door': 'باب مزدوج',
      
      // Additional Fire Safety Items
      'camera': 'كاميرا',
      'emergency_signs': 'لوحات الطوارئ',
      
      // Combined heaters entry for summary
      'سخانات': 'سخانات',
      // Individual heater entries - these will be dynamically generated
      'bathroom_heaters': 'سخانات الحمام',
      'cafeteria_heaters': 'سخانات المقصف',
      
      // Legacy items
      'alarm_panel_count': 'عدد لوحات الإنذار',
    };
    
    // Handle dynamic heater entries
    if (itemKey.startsWith('bathroom_heaters_')) {
      final id = itemKey.replaceFirst('bathroom_heaters_', '');
      return 'سخان حمام رقم $id';
    } else if (itemKey.startsWith('cafeteria_heaters_')) {
      final id = itemKey.replaceFirst('cafeteria_heaters_', '');
      return 'سخان مقصف رقم $id';
    }
    
    return displayNames[itemKey] ?? itemKey;
  }
  
  String _getItemNotes(String itemKey) {
    const notes = {
      // Combined heaters
      'سخانات': 'مجموع جميع السخانات (حمام + مقصف)',
      
      // Fire Safety Items
      'fire_extinguishers': 'يجب فحص تاريخ الانتهاء',
      'fire_boxes': 'يجب التأكد من سلامة الصناديق',
      'fire_hose': 'يجب فحص حالة الخرطوم',
      'emergency_exits': 'يجب التأكد من سهولة الوصول',
      'emergency_lights': 'يجب فحص البطاريات',
      'smoke_detectors': 'يجب فحص الحساسية',
      'heat_detectors': 'يجب فحص الحساسية',
      'breakers': 'يجب فحص حالة الكواسر',
      'bells': 'يجب فحص عمل الأجراس',
      'camera': 'يجب فحص عمل الكاميرات',
      'emergency_signs': 'يجب التأكد من وضوح اللوحات',
      
      // Electrical Items
      'lighting_panel': 'يجب فحص لوحة الإنارة',
      'power_panel': 'يجب فحص لوحة الباور',
      'ac_panel': 'يجب فحص لوحة التكييف',
      'main_distribution_panel': 'يجب فحص لوحة التوزيع الرئيسية',
      'main_breaker': 'يجب فحص القاطع الرئيسي',
      'concealed_ac_breaker': 'يجب فحص قاطع التكييف',
      'package_ac_breaker': 'يجب فحص قاطع التكييف',
      'lamps': 'يجب فحص عمل اللمبات',
      'projector': 'يجب فحص عمل البروجيكتور',
      'class_bell': 'يجب فحص عمل جرس الفصول',
      'speakers': 'يجب فحص عمل السماعات',
      'microphone_system': 'يجب فحص نظام الميكروفون',
      
      // Air Conditioning Items
      'cabinet_ac': 'يجب فحص عمل التكييف الدولابي',
      'split_concealed_ac': 'يجب فحص عمل التكييف السبليت',
      'hidden_ducts_ac': 'يجب فحص عمل التكييف المخفي',
      'window_ac': 'يجب فحص عمل التكييف الشباك',
      'package_ac': 'يجب فحص عمل التكييف الباكدج',
      
      // Mechanical Items
      'water_pumps': 'فحص دوري مطلوب',
      'hand_sink': 'يجب فحص عمل مغسلة اليد',
      'basin_sink': 'يجب فحص عمل مغسلة الحوض',
      'western_toilet': 'يجب فحص عمل الكرسي الإفرنجي',
      'arabic_toilet': 'يجب فحص عمل الكرسي العربي',
      'arabic_siphon': 'يجب فحص عمل السيفون العربي',
      'english_siphon': 'يجب فحص عمل السيفون الإفرنجي',
      'bidets': 'يجب فحص عمل الشطافات',
      'wall_exhaust_fans': 'يجب فحص عمل مراوح الشفط الجدارية',
      'central_exhaust_fans': 'يجب فحص عمل مراوح الشفط المركزية',
      'cafeteria_exhaust_fans': 'يجب فحص عمل مراوح شفط المقصف',
      'wall_water_coolers': 'يجب فحص عمل برادات المياه الجدارية',
      'corridor_water_coolers': 'يجب فحص عمل برادات المياه للممرات',
      'sink_mirrors': 'يجب فحص حالة مرايا المغاسل',
      'wall_tap': 'يجب فحص عمل خلاط الحائط',
      'sink_tap': 'يجب فحص عمل خلاط المغسلة',
      'upper_tank': 'يجب فحص حالة الخزان العلوي',
      'lower_tank': 'يجب فحص حالة الخزان السفلي',
      
      // Civil Items
      'blackboard': 'يجب فحص حالة السبورة',
      'internal_windows': 'يجب فحص حالة النوافذ الداخلية',
      'external_windows': 'يجب فحص حالة النوافذ الخارجية',
      'single_door': 'يجب فحص حالة الباب المفرد',
      'double_door': 'يجب فحص حالة الباب المزدوج',
      
      // Legacy items
      'alarm_panel_count': 'يجب فحص عدد لوحات الإنذار',
    };
    
    return notes[itemKey] ?? '';
  }

  Future<void> _exportMaintenanceCountsSyncfusion(List<MaintenanceCount> allCounts, Map<String, String> schoolNames) async {
    try {
      print('🚀 Starting Syncfusion export...');
      print('📊 Data to export:');
      print('   - Total counts: ${allCounts.length}');
      print('   - Schools: ${schoolNames.length}');
      print('   - Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
      
      // Validate input data
      if (allCounts.isEmpty) {
        throw Exception('No maintenance counts to export');
      }
      
      // Use Syncfusion for all platforms
      final workbook = syncfusion.Workbook();
      print('✅ Workbook created successfully');

      // Create Summary Sheet with Totals
      print('📋 Creating Summary Sheet...');
      final summarySheet = workbook.worksheets.addWithName('ملخص شامل');
      
      // Title
      final summaryTitleRange = summarySheet.getRangeByIndex(1, 1, 1, 6);
      summaryTitleRange.setText('ملخص شامل لحصر الصيانة');
      summaryTitleRange.cellStyle.fontSize = 18;
      summaryTitleRange.cellStyle.bold = true;
      summarySheet.getRangeByIndex(1, 1, 1, 6).merge();
      
      // Calculate totals for all categories
      print('📊 Calculating category totals...');
      final Map<String, int> categoryTotals = _calculateCategoryTotals(allCounts);
      print('✅ Category totals calculated: ${categoryTotals.length} categories');
      
      // Summary headers
      final summaryHeaders = [
        'الفئة',
        'العنصر',
        'إجمالي العدد',
        'عدد المدارس التي تحتوي على العنصر',
        'متوسط العدد لكل مدرسة',
      ];
      
      // Apply header styling
      final summaryHeaderRange = summarySheet.getRangeByIndex(3, 1, 3, summaryHeaders.length);
      summaryHeaderRange.cellStyle.fontSize = 12;
      summaryHeaderRange.cellStyle.bold = true;
      
      for (int i = 0; i < summaryHeaders.length; i++) {
        summarySheet.getRangeByIndex(3, i + 1).setText(summaryHeaders[i]);
      }
      
      // Add category totals
      int rowIndex = 4;
      
      // Add special entry for combined heaters first
      if (categoryTotals.containsKey('سخانات')) {
        print('🔥 Adding heaters data...');
        final heatersTotal = categoryTotals['سخانات']!;
        final schoolsWithHeaters = _countSchoolsWithItem(allCounts, 'سخانات');
        final heatersAverage = schoolsWithHeaters > 0 ? heatersTotal / schoolsWithHeaters : 0.0;
        
        // Add heaters category header
        final heatersHeaderRange = summarySheet.getRangeByIndex(rowIndex, 1, rowIndex, summaryHeaders.length);
        heatersHeaderRange.cellStyle.fontSize = 14;
        heatersHeaderRange.cellStyle.bold = true;
        summarySheet.getRangeByIndex(rowIndex, 1).setText('=== سخانات ===');
        summarySheet.getRangeByIndex(rowIndex, 1, rowIndex, summaryHeaders.length).merge();
        rowIndex++;
        
        // Add heaters row
        final heatersRowData = [
          'سخانات',
          'سخانات',
          heatersTotal,
          schoolsWithHeaters,
          heatersAverage.toStringAsFixed(1),
        ];
        
        summarySheet.getRangeByIndex(rowIndex, 1).setText(heatersRowData[0].toString());
        summarySheet.getRangeByIndex(rowIndex, 2).setText(heatersRowData[1].toString());
        summarySheet.getRangeByIndex(rowIndex, 3).setNumber(double.tryParse(heatersRowData[2].toString()) ?? 0);
        summarySheet.getRangeByIndex(rowIndex, 4).setNumber(double.tryParse(heatersRowData[3].toString()) ?? 0);
        summarySheet.getRangeByIndex(rowIndex, 5).setNumber(double.tryParse(heatersRowData[4].toString()) ?? 0);
        rowIndex++;
        
        // Add empty row after heaters
        rowIndex++;
      }

      // Add category totals - using the 5 main categories from inventory screen
      print('📊 Adding category data...');
      
      // Define the 5 main categories as used in the inventory screen
      final mainCategories = [
        {
          'key': 'civil',
          'name': 'أعمال مدنية',
          'items': MaintenanceItemTypes.civilItemsCountOnly,
        },
        {
          'key': 'electrical',
          'name': 'كهرباء',
          'items': [
            ...MaintenanceItemTypes.electricalTypes,
            ...MaintenanceItemTypes.electricalPanelTypes,
            ...MaintenanceItemTypes.electricalBreakerTypes,
          ],
        },
        {
          'key': 'mechanical',
          'name': 'ميكانيك',
          'items': [
            ...MaintenanceItemTypes.mechanicalTypes,
            ...MaintenanceItemTypes.mechanicalItemsCountOnly,
          ],
        },
        {
          'key': 'safety',
          'name': 'أمان وسلامة',
          'items': [
            ...MaintenanceItemTypes.fireSafetyTypes,
            ...MaintenanceItemTypes.fireItemsWithCondition,
            ...MaintenanceItemTypes.fireSafetyItemsWithCountAndCondition,
          ],
        },
        {
          'key': 'air_conditioning',
          'name': 'التكييف',
          'items': MaintenanceItemTypes.airConditioningTypes,
        },
      ];
      
      for (final category in mainCategories) {
        final categoryName = category['name'] as String;
        final items = category['items'] as List<String>;
        
        // Add category header
        final categoryHeaderRange = summarySheet.getRangeByIndex(rowIndex, 1, rowIndex, summaryHeaders.length);
        categoryHeaderRange.cellStyle.fontSize = 14;
        categoryHeaderRange.cellStyle.bold = true;
        summarySheet.getRangeByIndex(rowIndex, 1).setText('=== $categoryName ===');
        summarySheet.getRangeByIndex(rowIndex, 1, rowIndex, summaryHeaders.length).merge();
        rowIndex++;
        
        // Add items in this category - include ALL items even with zero counts
        for (final item in items) {
          final total = categoryTotals[item] ?? 0;
          final schoolsWithItem = _countSchoolsWithItem(allCounts, item);
          final average = schoolsWithItem > 0 ? total / schoolsWithItem : 0.0;
          
          final rowData = [
            categoryName,
            _getItemDisplayName(item),
            total,
            schoolsWithItem,
            average.toStringAsFixed(1),
          ];
          
          summarySheet.getRangeByIndex(rowIndex, 1).setText(rowData[0].toString());
          summarySheet.getRangeByIndex(rowIndex, 2).setText(rowData[1].toString());
          summarySheet.getRangeByIndex(rowIndex, 3).setNumber(double.tryParse(rowData[2].toString()) ?? 0);
          summarySheet.getRangeByIndex(rowIndex, 4).setNumber(double.tryParse(rowData[3].toString()) ?? 0);
          summarySheet.getRangeByIndex(rowIndex, 5).setNumber(double.tryParse(rowData[4].toString()) ?? 0);
          rowIndex++;
        }
        
        // Add empty row after category
        rowIndex++;
      }
      
      // Add grand totals
      final grandTotalRow = rowIndex;
      final grandTotalRange = summarySheet.getRangeByIndex(grandTotalRow, 1, grandTotalRow, summaryHeaders.length);
      grandTotalRange.cellStyle.fontSize = 14;
      grandTotalRange.cellStyle.bold = true;
      
      final totalItems = categoryTotals.values.fold(0, (sum, count) => sum + count);
      final totalSchools = allCounts.map((c) => c.schoolId).toSet().length;
      
      summarySheet.getRangeByIndex(grandTotalRow, 1).setText('إجمالي شامل');
      summarySheet.getRangeByIndex(grandTotalRow, 2).setText('جميع العناصر');
      summarySheet.getRangeByIndex(grandTotalRow, 3).setNumber(totalItems.toDouble());
      summarySheet.getRangeByIndex(grandTotalRow, 4).setNumber(totalSchools.toDouble());
      summarySheet.getRangeByIndex(grandTotalRow, 5).setNumber(totalSchools > 0 ? totalItems / totalSchools : 0);

      // Safety Sheet
      print('📋 Creating Safety Sheet...');
      final safetySheet = workbook.worksheets.addWithName('أمن وسلامة');
      print('✅ Safety Sheet created');
      
      // Title
      final titleRange = safetySheet.getRangeByIndex(1, 1, 1, 24);
      titleRange.setText('حصر الأمن والسلامة');
      titleRange.cellStyle.fontSize = 16;
      titleRange.cellStyle.bold = true;
      safetySheet.getRangeByIndex(1, 1, 1, 31).merge();

      final safetyHeaders = [
        'اسم المدرسة',
        'تاريخ الحصر',
        'المشرفون',
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
        'مخارج الطوارئ',
        'حالة مخارج الطوارئ',
        'أضواء الطوارئ',
        'حالة أضواء الطوارئ',
        'أجهزة استشعار الدخان',
        'حالة أجهزة استشعار الدخان',
        'أجهزة استشعار الحرارة',
        'حالة أجهزة استشعار الحرارة',
        'أجراس',
        'حالة الأجراس',
        'كواسر',
        'حالة كواسر',
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
      
      // Fetch supervisor names in batch for better performance
      final Map<String, String> supervisorNames = {};
      final Set<String> uniqueSupervisorIds = {};
      
      // Collect all unique supervisor IDs
      for (final count in allCounts) {
        if (count.supervisorId.contains(', ')) {
          // Split merged supervisor IDs
          final supervisorIdList = count.supervisorId.split(', ');
          uniqueSupervisorIds.addAll(supervisorIdList.map((id) => id.trim()));
        } else {
          uniqueSupervisorIds.add(count.supervisorId);
        }
      }
      
      // Fetch supervisor names in batch
      if (uniqueSupervisorIds.isNotEmpty) {
        try {
          final supervisors = await _supervisorRepository.getSupervisorsByIds(uniqueSupervisorIds.toList());
          for (final supervisor in supervisors) {
            supervisorNames[supervisor.id] = supervisor.username;
          }
          print('🔍 DEBUG: Fetched ${supervisorNames.length} supervisor names for detailed Excel export');
        } catch (e) {
          print('⚠️ WARNING: Failed to fetch supervisor names for detailed export: $e');
        }
      }
      
      for (int row = 0; row < allCounts.length; row++) {
        final count = allCounts[row];
        
        // Progress logging every 10 rows
        if (row % 10 == 0) {
          print('   📊 Processing Safety row ${row + 1}/${allCounts.length}');
        }
        
        // Get supervisor names for this record
        String supervisorDisplay = 'غير محدد';
        if (count.supervisorId.contains(', ')) {
          // Multiple supervisors
          final supervisorIdList = count.supervisorId.split(', ');
          final supervisorNameList = <String>[];
          
          for (final id in supervisorIdList) {
            final name = supervisorNames[id.trim()];
            if (name != null && name.isNotEmpty) {
              supervisorNameList.add(name);
            }
          }
          
          if (supervisorNameList.isNotEmpty) {
            supervisorDisplay = supervisorNameList.join('، ');
          }
        } else {
          // Single supervisor
          final supervisorName = supervisorNames[count.supervisorId];
          supervisorDisplay = supervisorName ?? 'غير محدد';
        }
        
        final rowData = [
          schoolNames[count.schoolId] ?? 'مدرسة ${count.schoolId}',
          _formatDate(count.createdAt),
          supervisorDisplay,
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
          int.tryParse(count.itemCounts['emergency_exits']?.toString() ?? '0') ?? 0,
          count.surveyAnswers['emergency_exits_condition'] ?? '',
          int.tryParse(count.itemCounts['emergency_lights']?.toString() ?? '0') ?? 0,
          count.surveyAnswers['emergency_lights_condition'] ?? '',
          int.tryParse(count.itemCounts['smoke_detectors']?.toString() ?? '0') ?? 0,
          count.surveyAnswers['smoke_detectors_condition'] ?? '',
          int.tryParse(count.itemCounts['heat_detectors']?.toString() ?? '0') ?? 0,
          count.surveyAnswers['heat_detectors_condition'] ?? '',
          int.tryParse(count.itemCounts['bells']?.toString() ?? '0') ?? 0,
          count.surveyAnswers['break_glasses_bells_condition'] ?? '',
          int.tryParse(count.itemCounts['breakers']?.toString() ?? '0') ?? 0,
          count.surveyAnswers['break_glasses_bells_condition'] ?? '',
        ];
        
        safetySheet.getRangeByIndex(row + 4, 1).setText(rowData[0].toString());
        safetySheet.getRangeByIndex(row + 4, 2).setText(rowData[1].toString());
        safetySheet.getRangeByIndex(row + 4, 3).setText(rowData[2].toString());
        safetySheet.getRangeByIndex(row + 4, 4).setNumber(double.tryParse(rowData[3].toString()) ?? 0);
        safetySheet.getRangeByIndex(row + 4, 5).setNumber(double.tryParse(rowData[4].toString()) ?? 0);
        safetySheet.getRangeByIndex(row + 4, 6).setText(rowData[5].toString());
        safetySheet.getRangeByIndex(row + 4, 7).setNumber(double.tryParse(rowData[6].toString()) ?? 0);
        safetySheet.getRangeByIndex(row + 4, 8).setText(rowData[7].toString());
        safetySheet.getRangeByIndex(row + 4, 9).setNumber(double.tryParse(rowData[8].toString()) ?? 0);
        safetySheet.getRangeByIndex(row + 4, 10).setText(rowData[9].toString());
        safetySheet.getRangeByIndex(row + 4, 11).setNumber(double.tryParse(rowData[10].toString()) ?? 0);
        safetySheet.getRangeByIndex(row + 4, 12).setText(rowData[11].toString());
        safetySheet.getRangeByIndex(row + 4, 13).setNumber(double.tryParse(rowData[12].toString()) ?? 0);
        safetySheet.getRangeByIndex(row + 4, 14).setText(rowData[13].toString());
        safetySheet.getRangeByIndex(row + 4, 15).setText(rowData[14].toString());
        safetySheet.getRangeByIndex(row + 4, 16).setNumber(double.tryParse(rowData[15].toString()) ?? 0);
        safetySheet.getRangeByIndex(row + 4, 17).setText(rowData[16].toString());
        safetySheet.getRangeByIndex(row + 4, 18).setText(rowData[17].toString());
        safetySheet.getRangeByIndex(row + 4, 19).setText(rowData[18].toString());
        safetySheet.getRangeByIndex(row + 4, 20).setNumber(double.tryParse(rowData[19].toString()) ?? 0);
        safetySheet.getRangeByIndex(row + 4, 21).setText(rowData[20].toString());
        safetySheet.getRangeByIndex(row + 4, 22).setNumber(double.tryParse(rowData[21].toString()) ?? 0);
        safetySheet.getRangeByIndex(row + 4, 23).setText(rowData[22].toString());
        safetySheet.getRangeByIndex(row + 4, 24).setNumber(double.tryParse(rowData[23].toString()) ?? 0);
        safetySheet.getRangeByIndex(row + 4, 25).setText(rowData[24].toString());
        safetySheet.getRangeByIndex(row + 4, 26).setNumber(double.tryParse(rowData[25].toString()) ?? 0);
        safetySheet.getRangeByIndex(row + 4, 27).setText(rowData[26].toString());
        safetySheet.getRangeByIndex(row + 4, 28).setNumber(double.tryParse(rowData[27].toString()) ?? 0);
        safetySheet.getRangeByIndex(row + 4, 29).setText(rowData[28].toString());
        safetySheet.getRangeByIndex(row + 4, 30).setNumber(double.tryParse(rowData[29].toString()) ?? 0);
        safetySheet.getRangeByIndex(row + 4, 31).setText(rowData[30].toString());
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
      final mechanicalTitleRange = mechanicalSheet.getRangeByIndex(1, 1, 1, 18);
      mechanicalTitleRange.setText('حصر الميكانيكا');
      mechanicalTitleRange.cellStyle.fontSize = 16;
      mechanicalTitleRange.cellStyle.bold = true;
      mechanicalSheet.getRangeByIndex(1, 1, 1, 18).merge();
      
      // Create headers with single combined heater column
      final headers = [
        'اسم المدرسة',
        'تاريخ الحصر',
        'سخانات',
        'مغاسل يد',
        'مغاسل حوض',
        'كرسي افرنجي',
        'كرسي عربي',
        'سيفون عربي',
        'سيفون افرنجي',
        'شطافات',
        'مراوح شفط جدارية',
        'مراوح شفط مركزية',
        'مراوح شفط (مقصف)',
        'برادات مياه جدارية',
        'برادات مياه للممرات',
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
        
        // Calculate total heater count for this record (matches logic from maintenance_count_detail_screen.dart)
        int totalHeaterCount = 0;
        final heaterEntries = count.heaterEntries;
        
        if (heaterEntries.isNotEmpty) {
          // Sum all bathroom heaters
          final bathroomHeaters = heaterEntries['bathroom_heaters'] as List<dynamic>?;
          if (bathroomHeaters != null) {
            for (final heater in bathroomHeaters) {
              if (heater is Map<String, dynamic>) {
                final id = heater['id']?.toString() ?? '';
                if (id.isNotEmpty) {
                  final heaterKey = 'bathroom_heaters_$id';
                  // Try to get quantity from itemCounts first, then from heater entry itself
                  int heaterCount = count.itemCounts[heaterKey] ?? 0;
                  
                  // If no count in itemCounts, try to get from heater entry or default to 1
                  if (heaterCount == 0) {
                    heaterCount = int.tryParse(heater['quantity']?.toString() ?? '1') ?? 1;
                  }
                  
                  totalHeaterCount += heaterCount;
                }
              }
            }
          }
          
          // Sum all cafeteria heaters
          final cafeteriaHeaters = heaterEntries['cafeteria_heaters'] as List<dynamic>?;
          if (cafeteriaHeaters != null) {
            for (final heater in cafeteriaHeaters) {
              if (heater is Map<String, dynamic>) {
                final id = heater['id']?.toString() ?? '';
                if (id.isNotEmpty) {
                  final heaterKey = 'cafeteria_heaters_$id';
                  // Try to get quantity from itemCounts first, then from heater entry itself
                  int heaterCount = count.itemCounts[heaterKey] ?? 0;
                  
                  // If no count in itemCounts, try to get from heater entry or default to 1
                  if (heaterCount == 0) {
                    heaterCount = int.tryParse(heater['quantity']?.toString() ?? '1') ?? 1;
                  }
                  
                  totalHeaterCount += heaterCount;
                }
              }
            }
          }
        } else {
          // Fallback: Use old structure
          totalHeaterCount = (count.itemCounts['bathroom_heaters'] ?? 0) + (count.itemCounts['cafeteria_heaters'] ?? 0);
        }
        
        // Build row data with single heater total
        final rowData = [
          schoolNames[count.schoolId] ?? 'مدرسة ${count.schoolId}',
          _formatDate(count.createdAt),
          totalHeaterCount,
          int.tryParse(count.itemCounts['hand_sink']?.toString() ?? '0') ?? 0,
          int.tryParse(count.itemCounts['basin_sink']?.toString() ?? '0') ?? 0,
          int.tryParse(count.itemCounts['western_toilet']?.toString() ?? '0') ?? 0,
          int.tryParse(count.itemCounts['arabic_toilet']?.toString() ?? '0') ?? 0,
          int.tryParse(count.itemCounts['arabic_siphon']?.toString() ?? '0') ?? 0,
          int.tryParse(count.itemCounts['english_siphon']?.toString() ?? '0') ?? 0,
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
        
        // Set cell values for all columns
        for (int col = 0; col < rowData.length; col++) {
          final value = rowData[col];
          if (value is String) {
            mechanicalSheet.getRangeByIndex(row + 4, col + 1).setText(value);
          } else {
            mechanicalSheet.getRangeByIndex(row + 4, col + 1).setNumber((double.tryParse(value.toString()) ?? 0).toDouble());
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
          count.itemCounts['split_concealed_ac'] ?? 0,
          count.itemCounts['window_ac'] ?? 0,
          count.itemCounts['package_ac'] ?? 0,
        ];
        
        acSheet.getRangeByIndex(row + 4, 1).setText(rowData[0].toString());
        acSheet.getRangeByIndex(row + 4, 2).setText(rowData[1].toString());
        for (int col = 2; col < rowData.length; col++) {
          acSheet.getRangeByIndex(row + 4, col + 1).setNumber(double.tryParse(rowData[col].toString()) ?? 0);
        }
      }

      // School Summary Sheet
      final schoolSummarySheet = workbook.worksheets.addWithName('ملخص المدارس');
      
      // Title
      final schoolSummaryTitleRange = schoolSummarySheet.getRangeByIndex(1, 1, 1, 4);
      schoolSummaryTitleRange.setText('ملخص حصر الصيانة');
      schoolSummaryTitleRange.cellStyle.fontSize = 18;
      schoolSummaryTitleRange.cellStyle.bold = true;
      schoolSummarySheet.getRangeByIndex(1, 1, 1, 4).merge();
      
      final schoolCounts = <String, int>{};
      for (final count in allCounts) {
        final schoolName = schoolNames[count.schoolId] ?? 'مدرسة ${count.schoolId}';
        schoolCounts[schoolName] = (schoolCounts[schoolName] ?? 0) + 1;
      }
      
      final schoolSummaryHeaders = ['اسم المدرسة', 'عدد الحصور', 'آخر تحديث', 'الحالة'];
      
      // Apply header styling
      final schoolSummaryHeaderRange = schoolSummarySheet.getRangeByIndex(3, 1, 3, schoolSummaryHeaders.length);
      schoolSummaryHeaderRange.cellStyle.fontSize = 12;
      schoolSummaryHeaderRange.cellStyle.bold = true;
      
      for (int i = 0; i < schoolSummaryHeaders.length; i++) {
        schoolSummarySheet.getRangeByIndex(3, i + 1).setText(schoolSummaryHeaders[i]);
      }
      
      int schoolRowIndex = 4;
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
        
        schoolSummarySheet.getRangeByIndex(schoolRowIndex, 1).setText(rowData[0].toString());
        schoolSummarySheet.getRangeByIndex(schoolRowIndex, 2).setNumber(double.tryParse(rowData[1].toString()) ?? 0);
        schoolSummarySheet.getRangeByIndex(schoolRowIndex, 3).setText(rowData[2].toString());
        schoolSummarySheet.getRangeByIndex(schoolRowIndex, 4).setText(rowData[3].toString());
        schoolRowIndex++;
      }
      
      // Summary footer
      final footerRange1 = schoolSummarySheet.getRangeByIndex(schoolRowIndex + 1, 1);
      footerRange1.setText('إجمالي المدارس: ${schoolCounts.length}');
      footerRange1.cellStyle.fontSize = 12;
      footerRange1.cellStyle.bold = true;
      
      final footerRange2 = schoolSummarySheet.getRangeByIndex(schoolRowIndex + 2, 1);
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
          html.AnchorElement(href: url)
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

  Future<void> _exportMaintenanceCountsSimplified(List<MaintenanceCount> allCounts, Map<String, String> schoolNames) async {
    try {
      print('🔄 Using simplified export for large dataset...');
      
      // Use excel package for simplified export
      final excel = Excel.createExcel();
      excel.delete('Sheet1');
      
      // Create a simplified summary sheet
      final sheet = excel['ملخص مبسط'];
      print('✅ Simplified sheet created');
      
      // Headers for simplified export
      final headers = [
        'اسم المدرسة',
        'تاريخ الحصر',
        'الحالة',
        'إجمالي العناصر',
        'طفايات الحريق',
        'مغاسل',
        'لمبات',
        'لوحات كهربائية',
        'سخانات',
      ];
      
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = headers[i];
      }
      
      // Add data rows with key metrics only
      print('📝 Adding simplified data rows...');
      
      for (int row = 0; row < allCounts.length; row++) {
        final count = allCounts[row];
        
        // Progress logging every 50 rows
        if (row % 50 == 0) {
          print('   📊 Processing simplified row ${row + 1}/${allCounts.length}');
        }
        
        final totalItems = count.itemCounts.values.fold(0, (sum, count) => sum + count);
        final fireExtinguishers = count.itemCounts['fire_extinguishers'] ?? 0;
        final sinks = (count.itemCounts['hand_sink'] ?? 0) + (count.itemCounts['basin_sink'] ?? 0);
        final lamps = count.itemCounts['lamps'] ?? 0;
        final panels = (count.itemCounts['lighting_panel'] ?? 0) + 
                      (count.itemCounts['power_panel'] ?? 0) + 
                      (count.itemCounts['ac_panel'] ?? 0);
        final heaters = count.heaterEntries.isNotEmpty ? 
                       ((count.heaterEntries['bathroom_heaters'] as List<dynamic>?)?.length ?? 0) +
                       ((count.heaterEntries['cafeteria_heaters'] as List<dynamic>?)?.length ?? 0) : 0;
        
        final rowData = [
          schoolNames[count.schoolId] ?? 'مدرسة ${count.schoolId}',
          _formatDate(count.createdAt),
          count.status == 'submitted' ? 'مرسل' : 'مسودة',
          totalItems,
          fireExtinguishers,
          sinks,
          lamps,
          panels,
          heaters,
        ];
        
        for (int col = 0; col < rowData.length; col++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1));
          cell.value = rowData[col];
        }
      }
      
      // Save and download
      print('💾 Saving simplified workbook...');
      final bytes = excel.encode();
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Failed to generate simplified Excel file');
      }
      print('✅ Simplified workbook saved, size: ${bytes.length} bytes');
      
      if (kIsWeb) {
        print('🌐 Creating web download for simplified export...');
        try {
          final blob = html.Blob([Uint8List.fromList(bytes)]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          html.AnchorElement(href: url)
            ..setAttribute('download', 'حصر مبسط.xlsx')
            ..click();
          html.Url.revokeObjectUrl(url);
          print('✅ Simplified web download initiated');
        } catch (webError) {
          print('❌ Simplified web download failed: $webError');
          rethrow;
        }
      } else {
        print('📱 Creating mobile download for simplified export...');
        try {
          final directory = await getApplicationDocumentsDirectory();
          final path = '${directory.path}/حصر مبسط.xlsx';
          final file = File(path);
          await file.writeAsBytes(bytes, flush: true);
          await Share.shareXFiles([XFile(path)], text: 'حصر مبسط');
          print('✅ Simplified mobile download completed');
        } catch (mobileError) {
          print('❌ Simplified mobile download failed: $mobileError');
          rethrow;
        }
      }
    } catch (e) {
      print('Simplified export error: $e');
      rethrow;
    }
  }

  Future<void> _exportMaintenanceCountsExcelPackage(List<MaintenanceCount> allCounts, Map<String, String> schoolNames) async {
    try {
      print('🔄 Using Excel package fallback...');
      
      // Validate input data
      if (allCounts.isEmpty) {
        throw Exception('No maintenance counts to export');
      }
      
      if (schoolNames.isEmpty) {
        print('⚠️ Warning: No school names available, using school IDs instead');
      }
      
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
      print('📝 Adding ${allCounts.length} data rows...');
      for (int row = 0; row < allCounts.length; row++) {
        try {
          final count = allCounts[row];
          
          // Validate count data
          if (count.schoolId.isEmpty) {
            print('⚠️ Warning: Skipping record with empty school ID at row $row');
            continue;
          }
          
          final rowData = [
            schoolNames[count.schoolId] ?? 'مدرسة ${count.schoolId}',
            _formatDate(count.createdAt),
            count.status == 'submitted' ? 'مرسل' : 'مسودة',
            count.itemCounts.length.toString(),
          ];
          
          for (int i = 0; i < rowData.length; i++) {
            try {
              _setCellValue(sheet, i, row + 1, rowData[i]);
            } catch (cellError) {
              print('⚠️ Warning: Failed to set cell value at row $row, column $i: $cellError');
              // Set empty value as fallback
              final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row + 1));
              cell.value = '';
            }
          }
        } catch (rowError) {
          print('⚠️ Warning: Failed to process row $row: $rowError');
          // Continue with next row
          continue;
        }
      }
      
      print('💾 Encoding Excel file...');
      // Save and download
      final bytes = excel.encode();
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Failed to generate Excel file - encoded bytes are null or empty');
      }
      
      print('✅ Excel file encoded successfully, size: ${bytes.length} bytes');
      
      if (kIsWeb) {
        print('🌐 Creating web download...');
        try {
          final blob = html.Blob([Uint8List.fromList(bytes)]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          html.AnchorElement(href: url)
            ..setAttribute('download', 'حصر الاعداد والحالة_مبسط.xlsx')
            ..click();
          html.Url.revokeObjectUrl(url);
          print('✅ Web download initiated successfully');
        } catch (webError) {
          print('❌ Web download failed: $webError');
          throw Exception('Failed to create web download: $webError');
        }
      } else {
        print('📱 Creating mobile download...');
        try {
          // For mobile platforms, save to file and share
          final directory = await getApplicationDocumentsDirectory();
          final path = '${directory.path}/حصر الاعداد والحالة_مبسط.xlsx';
          final file = File(path);
          await file.writeAsBytes(bytes, flush: true);
          await Share.shareXFiles([XFile(path)], text: 'حصر الاعداد والحالة');
          print('✅ Mobile download completed successfully');
        } catch (mobileError) {
          print('❌ Mobile download failed: $mobileError');
          throw Exception('Failed to create mobile download: $mobileError');
        }
      }
    } catch (e) {
      print('❌ Excel package fallback error: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Error stack trace: ${StackTrace.current}');
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

      // Fetch supervisor names in batch for better performance
      final Map<String, String> supervisorNames = {};
      final Set<String> uniqueSupervisorIds = {};
      
      // Collect all unique supervisor IDs
      for (final count in allCounts) {
        uniqueSupervisorIds.add(count.supervisorId);
      }
      
      // Fetch supervisor names in batch
      if (uniqueSupervisorIds.isNotEmpty) {
        try {
          final supervisors = await _supervisorRepository.getSupervisorsByIds(uniqueSupervisorIds.toList());
          for (final supervisor in supervisors) {
            supervisorNames[supervisor.id] = supervisor.username;
          }
          print('🔍 DEBUG: Fetched ${supervisorNames.length} supervisor names for damage count Excel export');
        } catch (e) {
          print('⚠️ WARNING: Failed to fetch supervisor names for damage count export: $e');
        }
      }

      // Use Syncfusion for web export
      if (kIsWeb) {
        await _exportDamageCountsSyncfusionWeb(allCounts, schoolNames);
        return;
      }

      // Fallback to old excel package for non-web (keep as-is for now)
      final excel = Excel.createExcel();
      excel.delete('Sheet1');
      _createMechanicalDamageSheet(excel, allCounts, schoolNames, supervisorNames);
      _createElectricalDamageSheet(excel, allCounts, schoolNames, supervisorNames);
      _createCivilDamageSheet(excel, allCounts, schoolNames, supervisorNames);
      _createSafetyDamageSheet(excel, allCounts, schoolNames, supervisorNames);
      _createAirConditioningDamageSheet(excel, allCounts, schoolNames, supervisorNames);
      _createDamageSummarySheet(excel, allCounts, schoolNames);
    } catch (e) {
      throw Exception('Failed to export Damage Excel: ${e.toString()}');
    }
  }

  Future<List<MaintenanceCount>> _getAllMaintenanceCounts() async {
    try {
      print('🔍 DEBUG: Starting _getAllMaintenanceCounts for Excel export');
      
      // Check admin access and get supervisor IDs
      final admin = await _adminService.getCurrentAdmin();
      if (admin == null) {
        print('❌ ERROR: Admin profile not found for Excel export');
        throw Exception('Admin profile not found');
      }

      List<String> supervisorIds = [];
      
      // Get supervisor IDs based on admin role
      if (admin.role == 'admin') {
        // For regular admins, get their assigned supervisor IDs
        supervisorIds = await _adminService.getCurrentAdminSupervisorIds();
        print('🔍 DEBUG: Regular admin has ${supervisorIds.length} assigned supervisors: $supervisorIds');
      } else if (admin.role == 'super_admin') {
        // For super admins, no filtering (can see all data)
        print('🔍 DEBUG: Super admin - no supervisor filtering applied');
      }

      // Use optimized merged records with better timeout handling
      print('🔍 DEBUG: Using optimized merge for Excel export');
      final mergedCounts = await _repository.getMergedMaintenanceCountRecords(
        supervisorIds: supervisorIds.isNotEmpty ? supervisorIds : null,
        limit: 2000, // Increased limit for large exports
      ).timeout(const Duration(seconds: 90), onTimeout: () {
        throw Exception('Database query timeout - taking too long to fetch data. Please try with fewer schools or contact support.');
      });

      print('🔍 DEBUG: Retrieved ${mergedCounts.length} merged maintenance counts for Excel export');
      
      // If dataset is very large, warn user
      if (mergedCounts.length > 500) {
        print('⚠️ WARNING: Large dataset detected (${mergedCounts.length} records). Export may take longer.');
      }
      
      return mergedCounts;
    } catch (e) {
      print('❌ ERROR: Failed to get merged maintenance counts for Excel export: $e');
      
      // Fallback to chunked approach for large datasets
      try {
        print('🔄 Using fallback method with progressive loading...');
        final allCounts = <MaintenanceCount>[];
        final schools = await _repository.getSchoolsWithMaintenanceCounts()
            .timeout(const Duration(seconds: 30), onTimeout: () {
          throw Exception('Failed to fetch schools list');
        });
        
        print('🔄 Processing ${schools.length} schools in chunks...');
        
        // Process schools in smaller chunks to avoid timeout
        const chunkSize = 15; // Reduced chunk size
        for (int i = 0; i < schools.length; i += chunkSize) {
          final chunk = schools.skip(i).take(chunkSize);
          
          // Process chunk in parallel with individual timeouts
          final futures = chunk.map((school) async {
            final schoolId = school['school_id'] as String;
            try {
              return await _repository.getMaintenanceCounts(schoolId: schoolId)
                  .timeout(const Duration(seconds: 8), onTimeout: () {
                print('⚠️ WARNING: Timeout for school: $schoolId');
                return <MaintenanceCount>[];
              });
            } catch (e) {
              print('⚠️ WARNING: Error for school $schoolId: $e');
              return <MaintenanceCount>[];
            }
          });
          
          // Wait for chunk with timeout
          final chunkResults = await Future.wait(futures)
              .timeout(const Duration(seconds: 25), onTimeout: () {
            print('⚠️ WARNING: Chunk timeout, continuing with next chunk');
            return List<List<MaintenanceCount>>.filled(chunk.length, []);
          });
          
          for (final counts in chunkResults) {
            allCounts.addAll(counts);
          }
          
          print('🔍 DEBUG: Processed chunk ${(i ~/ chunkSize) + 1}/${(schools.length / chunkSize).ceil()}, total records: ${allCounts.length}');
          
          // Add small delay between chunks to prevent overwhelming the database
          if (i + chunkSize < schools.length) {
            await Future.delayed(const Duration(milliseconds: 150));
          }
        }
        
        print('✅ Fallback method completed with ${allCounts.length} records');
        return allCounts;
      } catch (fallbackError) {
        print('❌ ERROR: Fallback method also failed: $fallbackError');
        throw Exception('Failed to fetch maintenance data. Please try again or contact support.');
      }
    }
  }

  Future<List<DamageCount>> _getAllDamageCounts() async {
    try {
      print('🔍 DEBUG: Starting _getAllDamageCounts for Excel export');
      
      // Check admin access and get supervisor IDs
      final admin = await _adminService.getCurrentAdmin();
      if (admin == null) {
        print('❌ ERROR: Admin profile not found for damage counts Excel export');
        throw Exception('Admin profile not found');
      }

      List<String> supervisorIds = [];
      
      // Get supervisor IDs based on admin role
      if (admin.role == 'admin') {
        // For regular admins, get their assigned supervisor IDs
        supervisorIds = await _adminService.getCurrentAdminSupervisorIds();
        print('🔍 DEBUG: Regular admin has ${supervisorIds.length} assigned supervisors for damage counts: $supervisorIds');
      } else if (admin.role == 'super_admin') {
        // For super admins, no filtering (can see all data)
        print('🔍 DEBUG: Super admin - no supervisor filtering applied for damage counts');
      }

      final allCounts = <DamageCount>[];

      // Get all schools with damage counts, filtered by supervisor IDs
      final schools = await _damageRepository!.getSchoolsWithDamageCounts(
        supervisorIds: supervisorIds.isNotEmpty ? supervisorIds : null,
      );

      for (final school in schools) {
        final schoolId = school['school_id'] as String;
        // For damage counts, we need to get all counts for the school and filter by supervisor
        final counts = await _damageRepository.getDamageCounts(
          schoolId: schoolId,
        );
        
        // Filter counts by supervisor IDs if needed
        if (supervisorIds.isNotEmpty) {
          final filteredCounts = counts.where((count) => 
            supervisorIds.contains(count.supervisorId)
          ).toList();
          allCounts.addAll(filteredCounts);
        } else {
          allCounts.addAll(counts);
        }
      }

      print('🔍 DEBUG: Retrieved ${allCounts.length} damage counts for Excel export');
      return allCounts;
    } catch (e) {
      print('❌ ERROR: Failed to get damage counts for Excel export: $e');
      return [];
    }
  }

  Future<Map<String, String>> _getSchoolNamesMap() async {
    try {
      final schools = await _repository.getSchoolsWithMaintenanceCounts();
      final schoolMap = <String, String>{};

      // Process schools in parallel for better performance
      final futures = schools.map((school) async {
        final schoolId = school['school_id'] as String;
        final schoolName = school['school_name'] as String? ?? 'مدرسة $schoolId';
        return MapEntry(schoolId, schoolName);
      });
      
      final results = await Future.wait(futures);
      schoolMap.addAll(Map.fromEntries(results));
      
      print('✅ Retrieved ${schoolMap.length} school names');
      return schoolMap;
    } catch (e) {
      print('❌ ERROR: Failed to get school names: $e');
      // Return empty map instead of throwing to allow export to continue
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





  void _createMechanicalDamageSheet(Excel excel, List<DamageCount> allCounts,
      Map<String, String> schoolNames, Map<String, String> supervisorNames) {
    final sheet = excel['أعمال الميكانيك والسباكة'];

    final headers = [
      'اسم المدرسة',
      'تاريخ الحصر',
      'المشرفون',
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
        supervisorNames[count.supervisorId] ?? 'غير محدد', // Text
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
      Map<String, String> schoolNames, Map<String, String> supervisorNames) {
    final sheet = excel['أعمال الكهرباء'];

    final headers = [
      'اسم المدرسة',
      'تاريخ الحصر',
      'المشرفون',
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
        supervisorNames[count.supervisorId] ?? 'غير محدد', // Text
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
      Map<String, String> schoolNames, Map<String, String> supervisorNames) {
    final sheet = excel['أعمال مدنية'];

    final headers = [
      'اسم المدرسة',
      'تاريخ الحصر',
      'المشرفون',
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
        supervisorNames[count.supervisorId] ?? 'غير محدد', // Text
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
      Map<String, String> schoolNames, Map<String, String> supervisorNames) {
    final sheet = excel['أعمال الامن والسلامة'];

    final headers = [
      'اسم المدرسة',
      'تاريخ الحصر',
      'المشرفون',
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
        supervisorNames[count.supervisorId] ?? 'غير محدد', // Text
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
      List<DamageCount> allCounts, Map<String, String> schoolNames, Map<String, String> supervisorNames) {
    final sheet = excel['التكييف'];

    final headers = [
      'اسم المدرسة',
      'تاريخ الحصر',
      'المشرفون',
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
        supervisorNames[count.supervisorId] ?? 'غير محدد', // Text
        count.itemCounts['air_conditioning_cabinet'] ?? 0, // Number
        count.itemCounts['air_conditioning_split'] ?? 0, // Number
        count.itemCounts['air_conditioning_window'] ?? 0, // Number
        count.itemCounts['air_conditioning_package'] ?? 0, // Number
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

    // Fetch supervisor names in batch for better performance
    final Map<String, String> supervisorNames = {};
    final Set<String> uniqueSupervisorIds = {};
    
    // Collect all unique supervisor IDs
    for (final count in allCounts) {
      uniqueSupervisorIds.add(count.supervisorId);
    }
    
    // Fetch supervisor names in batch
    if (uniqueSupervisorIds.isNotEmpty) {
      try {
        final supervisors = await _supervisorRepository.getSupervisorsByIds(uniqueSupervisorIds.toList());
        for (final supervisor in supervisors) {
          supervisorNames[supervisor.id] = supervisor.username;
        }
        print('🔍 DEBUG: Fetched ${supervisorNames.length} supervisor names for damage count Excel export');
      } catch (e) {
        print('⚠️ WARNING: Failed to fetch supervisor names for damage count export: $e');
      }
    }

    // Mechanical Sheet
    final mechanicalSheet = workbook.worksheets[0];
    mechanicalSheet.name = 'أعمال الميكانيك والسباكة';
    
    // Title
    final mechanicalTitleRange = mechanicalSheet.getRangeByIndex(1, 1, 1, 16);
    mechanicalTitleRange.setText('حصر أعمال الميكانيك والسباكة');
    mechanicalTitleRange.cellStyle.fontSize = 16;
    mechanicalTitleRange.cellStyle.bold = true;
    mechanicalSheet.getRangeByIndex(1, 1, 1, 16).merge();
    
    final mechanicalHeaders = [
      'اسم المدرسة',
      'تاريخ الحصر',
      'المشرفون',
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
      
      // Get supervisor name for this record
      final supervisorName = supervisorNames[count.supervisorId] ?? 'غير محدد';
      
      final rowData = [
        schoolNames[count.schoolId] ?? 'مدرسة ${count.schoolId}',
        _formatDate(count.createdAt),
        supervisorName,
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
      mechanicalSheet.getRangeByIndex(row + 4, 3).setText(rowData[2].toString());
      for (int col = 3; col < rowData.length; col++) {
        mechanicalSheet.getRangeByIndex(row + 4, col + 1).setNumber(double.tryParse(rowData[col].toString()) ?? 0);
      }
    }

    // Electrical Sheet
    final electricalSheet = workbook.worksheets.addWithName('أعمال الكهرباء');
    
    // Title
    final electricalTitleRange = electricalSheet.getRangeByIndex(1, 1, 1, 12);
    electricalTitleRange.setText('حصر أعمال الكهرباء');
    electricalTitleRange.cellStyle.fontSize = 16;
    electricalTitleRange.cellStyle.bold = true;
    electricalSheet.getRangeByIndex(1, 1, 1, 12).merge();
    
    final electricalHeaders = [
      'اسم المدرسة',
      'تاريخ الحصر',
      'المشرفون',
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
      
      // Get supervisor name for this record
      final supervisorName = supervisorNames[count.supervisorId] ?? 'غير محدد';
      
      final rowData = [
        schoolNames[count.schoolId] ?? 'مدرسة ${count.schoolId}',
        _formatDate(count.createdAt),
        supervisorName,
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
      electricalSheet.getRangeByIndex(row + 4, 3).setText(rowData[2].toString());
      for (int col = 3; col < rowData.length; col++) {
        electricalSheet.getRangeByIndex(row + 4, col + 1).setNumber(double.tryParse(rowData[col].toString()) ?? 0);
      }
    }

    // Civil Sheet
    final civilSheet = workbook.worksheets.addWithName('أعمال مدنية');
    
    // Title
    final civilTitleRange = civilSheet.getRangeByIndex(1, 1, 1, 17);
    civilTitleRange.setText('حصر الأعمال المدنية');
    civilTitleRange.cellStyle.fontSize = 16;
    civilTitleRange.cellStyle.bold = true;
    civilSheet.getRangeByIndex(1, 1, 1, 17).merge();
    
    final civilHeaders = [
      'اسم المدرسة',
      'تاريخ الحصر',
      'المشرفون',
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
      
      // Get supervisor name for this record
      final supervisorName = supervisorNames[count.supervisorId] ?? 'غير محدد';
      
      final rowData = [
        schoolNames[count.schoolId] ?? 'مدرسة ${count.schoolId}',
        _formatDate(count.createdAt),
        supervisorName,
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
      civilSheet.getRangeByIndex(row + 4, 3).setText(rowData[2].toString());
      for (int col = 3; col < rowData.length; col++) {
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
    html.AnchorElement(href: url)
      ..setAttribute('download', 'حصر التوالف.xlsx')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _setCellValue(
      Sheet sheet, int columnIndex, int rowIndex, dynamic value) {
    try {
      final cell = sheet.cell(CellIndex.indexByColumnRow(
          columnIndex: columnIndex, rowIndex: rowIndex));

      if (value == null) {
        cell.value = '';
        return;
      }

      if (value is int) {
        cell.value = value;
      } else if (value is double) {
        cell.value = value;
      } else if (value is String) {
        // Handle empty strings and null strings
        if (value.isEmpty) {
          cell.value = '';
        } else {
          cell.value = value;
        }
      } else if (value is bool) {
        cell.value = value;
      } else {
        // Convert to string for other types
        cell.value = value.toString();
      }
    } catch (e) {
      print('⚠️ Warning: Failed to set cell value at column $columnIndex, row $rowIndex: $e');
      // Set empty value as fallback
      try {
        final cell = sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: columnIndex, rowIndex: rowIndex));
        cell.value = '';
      } catch (fallbackError) {
        print('❌ Critical: Failed to set fallback cell value: $fallbackError');
      }
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
          .timeout(const Duration(seconds: 60), onTimeout: () {
        throw Exception('Database query timeout - taking too long to fetch data');
      });
      
      final schoolNames = await _getSchoolNamesMap()
          .timeout(const Duration(seconds: 15), onTimeout: () {
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
        'المشرفون',
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
      
      // Fetch supervisor names in batch for better performance
      final supervisorIds = allCounts.map((c) => c.supervisorId).toSet().toList();
      final supervisorNames = <String, String>{};
      
      try {
                 final supervisors = await _supervisorRepository.getSupervisorsByIds(supervisorIds);
         for (final supervisor in supervisors) {
           supervisorNames[supervisor.id] = supervisor.username;
         }
      } catch (e) {
        print('⚠️ WARNING: Failed to fetch supervisor names: $e');
      }
      
      int rowIndex = 1;
      for (final count in allCounts) {
        try {
          final schoolName = schoolNames[count.schoolId] ?? count.schoolName;
          final supervisorName = supervisorNames[count.supervisorId] ?? count.supervisorId;
          
          // Calculate totals
          final totalItems = count.itemCounts.values.fold<int>(0, (sum, count) => sum + count);
          final totalTextAnswers = count.textAnswers.length;
          final totalYesNoAnswers = count.yesNoAnswers.length;
          
          // Get maintenance notes summary
          final maintenanceNotesSummary = count.maintenanceNotes.values
              .where((note) => note.isNotEmpty)
              .take(3) // Limit to first 3 notes
              .join(' | ');
          
          // Get fire safety data summary
          final fireSafetySummary = count.fireSafetyAlarmPanelData.values
              .where((data) => data.isNotEmpty)
              .take(2) // Limit to first 2 entries
              .join(' | ');
          
          // Get AC data summary
          final acDataSummary = count.itemCounts.entries
              .where((entry) => entry.key.contains('ac') || entry.key.contains('air'))
              .map((entry) => '${entry.key}: ${entry.value}')
              .join(', ');
          
          // Get heater data summary
          String heaterDataSummary = '';
          if (count.heaterEntries.isNotEmpty) {
            final heaterCounts = <String, int>{};
            for (final entry in count.heaterEntries.values) {
              if (entry is Map<String, dynamic>) {
                final type = entry['type']?.toString() ?? '';
                if (type.isNotEmpty) {
                  heaterCounts[type] = (heaterCounts[type] ?? 0) + 1;
                }
              }
            }
            heaterDataSummary = heaterCounts.entries
                .map((entry) => '${entry.key}: ${entry.value}')
                .join(', ');
          }
          
          // Add row data
          final rowData = [
            schoolName,
            count.createdAt.toString().substring(0, 10),
            count.status,
            supervisorName,
            totalItems.toString(),
            totalTextAnswers.toString(),
            totalYesNoAnswers.toString(),
            maintenanceNotesSummary,
            fireSafetySummary,
            acDataSummary,
            heaterDataSummary,
          ];
          
          for (int i = 0; i < rowData.length; i++) {
            final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex));
            cell.value = rowData[i];
          }
          
          rowIndex++;
        } catch (e) {
          print('⚠️ WARNING: Error processing row for school ${count.schoolId}: $e');
          // Continue with next record
        }
      }
      
      print('✅ Simplified export completed with ${rowIndex - 1} rows');
      
             // Save and download
       print('💾 Saving simplified export...');
       final bytes = excel.encode();
       if (bytes == null || bytes.isEmpty) {
         throw Exception('Failed to generate simplified Excel file');
       }
       
       print('✅ Simplified export saved, size: ${bytes.length} bytes');
       
       if (kIsWeb) {
         print('🌐 Creating web download for simplified export...');
         final blob = html.Blob([Uint8List.fromList(bytes)]);
         final url = html.Url.createObjectUrlFromBlob(blob);
         html.AnchorElement(href: url)
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
      print('❌ ERROR: Simplified export failed: $e');
      throw Exception('Failed to export simplified Excel: $e');
    } finally {
      _isDownloading = false;
    }
  }



  // Diagnostic method to identify export issues
  Future<void> diagnoseExportIssue() async {
    try {
      print('🔍 Starting export diagnosis...');
      
      // Test 1: Check if we can access the repository
      print('📊 Test 1: Repository access...');
      final admin = await _adminService.getCurrentAdmin();
      if (admin == null) {
        throw Exception('Admin profile not found');
      }
      print('✅ Repository access successful');
      
      // Test 2: Check if we can fetch maintenance counts
      print('📊 Test 2: Maintenance counts fetch...');
      final allCounts = await _getAllMaintenanceCounts();
      print('✅ Fetched ${allCounts.length} maintenance counts');
      
      // Test 3: Check if we can fetch school names
      print('📊 Test 3: School names fetch...');
      final schoolNames = await _getSchoolNamesMap();
      print('✅ Fetched ${schoolNames.length} school names');
      
      // Test 4: Check if we can create Excel file
      print('📊 Test 4: Excel file creation...');
      final excel = Excel.createExcel();
      excel.delete('Sheet1');
      final sheet = excel['Test'];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = 'Test';
      final bytes = excel.encode();
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Excel encoding failed');
      }
      print('✅ Excel file creation successful');
      
      // Test 5: Check data validation
      print('📊 Test 5: Data validation...');
      if (allCounts.isNotEmpty) {
        final sampleCount = allCounts.first;
        print('✅ Sample count data:');
        print('   - School ID: ${sampleCount.schoolId}');
        print('   - School Name: ${sampleCount.schoolName}');
        print('   - Supervisor ID: ${sampleCount.supervisorId}');
        print('   - Status: ${sampleCount.status}');
        print('   - Item counts: ${sampleCount.itemCounts.length}');
        print('   - Created at: ${sampleCount.createdAt}');
      }
      
      print('✅ All diagnostic tests passed');
      print('💡 The export should work now. Try downloading again.');
      
    } catch (e) {
      print('❌ Diagnostic test failed: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Error stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Simple fallback method for basic Excel export
  Future<void> _exportMaintenanceCountsBasic(List<MaintenanceCount> allCounts, Map<String, String> schoolNames) async {
    try {
      print('🔄 Using basic Excel export fallback...');
      
      // Create a very simple Excel file
      final excel = Excel.createExcel();
      excel.delete('Sheet1');
      
      final sheet = excel['حصر الصيانة'];
      
      // Simple headers
      final headers = ['اسم المدرسة', 'تاريخ الحصر', 'الحالة', 'عدد العناصر'];
      
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = headers[i];
      }
      
      // Simple data rows
      for (int row = 0; row < allCounts.length; row++) {
        try {
          final count = allCounts[row];
          
          final rowData = [
            schoolNames[count.schoolId] ?? 'مدرسة ${count.schoolId}',
            _formatDate(count.createdAt),
            count.status == 'submitted' ? 'مرسل' : 'مسودة',
            count.itemCounts.length.toString(),
          ];
          
          for (int i = 0; i < rowData.length; i++) {
            final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row + 1));
            cell.value = rowData[i];
          }
        } catch (e) {
          print('⚠️ Warning: Failed to add row $row: $e');
          continue;
        }
      }
      
      // Save and download
      final bytes = excel.encode();
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Failed to generate basic Excel file');
      }
      
      if (kIsWeb) {
        final blob = html.Blob([Uint8List.fromList(bytes)]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', 'حصر_صيانة_مبسط.xlsx')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/حصر_صيانة_مبسط.xlsx';
        final file = File(path);
        await file.writeAsBytes(bytes, flush: true);
        await Share.shareXFiles([XFile(path)], text: 'حصر صيانة مبسط');
      }
      
      print('✅ Basic Excel export completed successfully');
    } catch (e) {
      print('❌ Basic Excel export failed: $e');
      rethrow;
    }
  }
}
