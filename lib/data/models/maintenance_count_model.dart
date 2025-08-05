import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Model representing maintenance count items for a school
class MaintenanceCountModel extends Equatable {
  final String id;
  final String schoolId;
  final String schoolName;
  final Map<String, int> itemCounts;
  final Map<String, String> textAnswers;
  final Map<String, bool> yesNoAnswers;
  final Map<String, int> yesNoWithCounts;
  final Map<String, String> surveyAnswers;
  final Map<String, String> maintenanceNotes; // notes for maintenance items
  final Map<String, String> fireSafetyAlarmPanelData; // alarm panel data
  final Map<String, String> fireSafetyConditionOnlyData; // condition only items
  final Map<String, String> fireSafetyExpiryDates; // expiry date data
  final Map<String, List<Map<String, String>>> heaterEntries; // Multiple heater entries with capacity and quantity
  final Map<String, List<String>> sectionPhotos; // Photos by section
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String supervisorId;
  final String status; // 'draft', 'submitted'

  const MaintenanceCountModel({
    required this.id,
    required this.schoolId,
    required this.schoolName,
    required this.itemCounts,
    required this.textAnswers,
    required this.yesNoAnswers,
    required this.yesNoWithCounts,
    required this.surveyAnswers,
    required this.maintenanceNotes,
    required this.fireSafetyAlarmPanelData,
    required this.fireSafetyConditionOnlyData,
    required this.fireSafetyExpiryDates,
    this.heaterEntries = const {},
    this.sectionPhotos = const {},
    required this.createdAt,
    this.updatedAt,
    required this.supervisorId,
    this.status = 'draft',
  });

  factory MaintenanceCountModel.fromMap(Map<String, dynamic> map) {
    return MaintenanceCountModel(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      schoolName: map['school_name'] as String,
      itemCounts: Map<String, int>.from(map['item_counts'] ?? {}),
      textAnswers: Map<String, String>.from(map['text_answers'] ?? {}),
      yesNoAnswers: Map<String, bool>.from(map['yes_no_answers'] ?? {}),
      yesNoWithCounts: Map<String, int>.from(map['yes_no_with_counts'] ?? {}),
      surveyAnswers: Map<String, String>.from(map['survey_answers'] ?? {}),
      maintenanceNotes: Map<String, String>.from(map['maintenance_notes'] ?? {}),
      fireSafetyAlarmPanelData: Map<String, String>.from(map['fire_safety_alarm_panel_data'] ?? {}),
      fireSafetyConditionOnlyData: Map<String, String>.from(map['fire_safety_condition_only_data'] ?? {}),
      fireSafetyExpiryDates: Map<String, String>.from(map['fire_safety_expiry_dates'] ?? {}),
      heaterEntries: _parseHeaterEntries(map['heater_entries']),
      sectionPhotos: _parseSectionPhotos(map['section_photos']),
      createdAt: DateTime.parse(map['created_at']).toLocal(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']).toLocal() : null,
      supervisorId: map['supervisor_id'] as String,
      status: map['status'] as String? ?? 'draft',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'school_name': schoolName,
      'item_counts': itemCounts,
      'text_answers': textAnswers,
      'yes_no_answers': yesNoAnswers,
      'yes_no_with_counts': yesNoWithCounts,
      'survey_answers': surveyAnswers,
      'maintenance_notes': maintenanceNotes,
      'fire_safety_alarm_panel_data': fireSafetyAlarmPanelData,
      'fire_safety_condition_only_data': fireSafetyConditionOnlyData,
      'fire_safety_expiry_dates': fireSafetyExpiryDates,
      'heater_entries': heaterEntries,
      'section_photos': sectionPhotos,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'supervisor_id': supervisorId,
      'status': status,
    };
  }

  MaintenanceCountModel copyWith({
    String? id,
    String? schoolId,
    String? schoolName,
    Map<String, int>? itemCounts,
    Map<String, String>? textAnswers,
    Map<String, bool>? yesNoAnswers,
    Map<String, int>? yesNoWithCounts,
    Map<String, String>? surveyAnswers,
    Map<String, String>? maintenanceNotes,
    Map<String, String>? fireSafetyAlarmPanelData,
    Map<String, String>? fireSafetyConditionOnlyData,
    Map<String, String>? fireSafetyExpiryDates,
    Map<String, List<Map<String, String>>>? heaterEntries,
    Map<String, List<String>>? sectionPhotos,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? supervisorId,
    String? status,
  }) {
    return MaintenanceCountModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      itemCounts: itemCounts ?? this.itemCounts,
      textAnswers: textAnswers ?? this.textAnswers,
      yesNoAnswers: yesNoAnswers ?? this.yesNoAnswers,
      yesNoWithCounts: yesNoWithCounts ?? this.yesNoWithCounts,
      surveyAnswers: surveyAnswers ?? this.surveyAnswers,
      maintenanceNotes: maintenanceNotes ?? this.maintenanceNotes,
      fireSafetyAlarmPanelData:
          fireSafetyAlarmPanelData ?? this.fireSafetyAlarmPanelData,
      fireSafetyConditionOnlyData:
          fireSafetyConditionOnlyData ?? this.fireSafetyConditionOnlyData,
      fireSafetyExpiryDates:
          fireSafetyExpiryDates ?? this.fireSafetyExpiryDates,
      heaterEntries: heaterEntries ?? this.heaterEntries,
      sectionPhotos: sectionPhotos ?? this.sectionPhotos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      supervisorId: supervisorId ?? this.supervisorId,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        schoolName,
        itemCounts,
        textAnswers,
        yesNoAnswers,
        yesNoWithCounts,
        surveyAnswers,
        maintenanceNotes,
        fireSafetyAlarmPanelData,
        fireSafetyConditionOnlyData,
        fireSafetyExpiryDates,
        heaterEntries,
        sectionPhotos,
        createdAt,
        updatedAt,
        supervisorId,
        status,
      ];

  /// Parse heater entries from JSON
  static Map<String, List<Map<String, String>>> _parseHeaterEntries(dynamic data) {
    if (data == null) return {};
    
    try {
      if (data is Map<String, dynamic>) {
        return data.map((key, value) {
          if (value is List) {
            final List<Map<String, String>> entries = value.map((item) {
              if (item is Map<String, dynamic>) {
                return item.map((k, v) => MapEntry(k, v.toString()));
              }
              return <String, String>{};
            }).toList();
            return MapEntry(key, entries);
          }
          return MapEntry(key, <Map<String, String>>[]);
        });
      }
    } catch (e) {
      print('Error parsing heater entries: $e');
    }
    return {};
  }

  /// Parse section photos from JSON
  static Map<String, List<String>> _parseSectionPhotos(dynamic data) {
    if (data == null) return {};
    
    try {
      if (data is Map<String, dynamic>) {
        return data.map((key, value) {
          if (value is List) {
            return MapEntry(key, value.map((item) => item.toString()).toList());
          }
          return MapEntry(key, <String>[]);
        });
      }
    } catch (e) {
      print('Error parsing section photos: $e');
    }
    return {};
  }
}

/// Maintenance survey categories and questions
class MaintenanceCategories {
  // Fire and Safety Category
  static const Map<String, String> fireSafetyItems = {
    'electric_pump': 'مضخة الكهرباء',
    'diesel_pump': 'مضخة الديزل',
    'auxiliary_pump': 'المضخة المساعدة',
    'fire_extinguishers': 'طفايات الحريق',
    'fire_boxes': 'صناديق الحريق',
    'camera': 'كاميرا',
    'emergency_signs': 'لوحات الطوارئ',
  };

  // Fire items that need both count and condition
  static const Map<String, String> fireItemsWithCondition = {
    'fire_hose': 'خرطوم الحريق',
  };

  static const Map<String, String> fireSafetyConditions = {
    'electric_pump_condition': 'حالة مضخة الكهرباء',
    'diesel_pump_condition': 'حالة مضخة الديزل',
    'auxiliary_pump_condition': 'حالة المضخة المساعدة',
    'fire_boxes_condition': 'حالة صناديق الحريق',
    'fire_hose_condition': 'حالة خرطوم الحريق',
  };

  static const Map<String, String> fireSafetyExpiryDates = {
    'fire_extinguishers_expiry': 'تاريخ انتهاء طفايات الحريق',
  };

  // Alarm panel with type, count, and condition
  static const Map<String, String> fireSafetyAlarmPanel = {
    'alarm_panel': 'لوحة الانذار',
  };

  static const Map<String, String> fireSafetyAlarmPanelProperties = {
    'alarm_panel_type': 'نوع لوحة الانذار',
    'alarm_panel_count': 'عدد لوحة الانذار',
    'alarm_panel_condition': 'حالة لوحة الانذار',
  };

  // Fire safety items with condition only
  static const Map<String, String> fireSafetyConditionOnly = {
    // Empty - moved breakers and bells to count and condition category
  };

  // Fire safety items with count and condition
  static const Map<String, String> fireSafetyItemsWithCountAndCondition = {
    'emergency_lights': 'كشافات طوارئ',
    'emergency_exits': 'مخارج الطوارئ',
    'smoke_detectors': 'كواشف دخان',
    'heat_detectors': 'كواشف حرارة',
    'breakers': 'كواسر',
    'bells': 'اجراس',
  };

  // Alarm panel condition options
  static const List<String> alarmPanelConditionOptions = [
    'جيد',
    'يحتاج صيانة',
    'تالف',
  ];

  // Fire panel type options
  static const List<String> firePanelTypeOptions = [
    'CONVENTIONAL',
    'ADDRESSABLE',
  ];

  static const Map<String, String> fireSafetySurvey = {
    'fire_suppression_system': 'حالة شبكة الحريق؟',
    'fire_alarm_system': 'حالة نظام انذار الحريق؟',
  };

  // Electrical Category
  static const Map<String, String> electricalItems = {
    // Removed electrical_panels as requested
  };

  // Electrical panels that need count and amperage
  static const Map<String, String> electricalPanelsWithAmperage = {
    'lighting_panel': 'لوحة انارة',
    'power_panel': 'لوحة باور(أفياش)',
    'ac_panel': 'لوحة تكييف',
    'main_distribution_panel': 'لوحة توزيع رئيسية',
  };

  // Electrical breakers that need count and amperage
  static const Map<String, String> electricalBreakersWithAmperage = {
    'main_breaker': 'القاطع الرئيسي',
    'concealed_ac_breaker': 'قاطع تكييف (كونسيلد)',
    'package_ac_breaker': 'قاطع تكييف (باكدج)',
  };

  // Electrical items that only need count
  static const Map<String, String> electricalItemsCountOnly = {
    'lamps': 'لمبات',
    'projector': 'بروجيكتور',
    'class_bell': 'جرس الفصول',
    'speakers': 'السماعات',
    'microphone_system': 'نظام الميكوفون',
  };

  static const Map<String, String> electricalTextFields = {
    'electricity_meter_number': 'رقم عداد الكهرباء',
  };

  // Mechanical Category
  static const Map<String, String> mechanicalItems = {
    'water_pumps': 'مضخات المياة',
  };

  // Mechanical heaters with multiple entries (capacity and quantity)
  static const Map<String, String> mechanicalHeatersMultiple = {
    'bathroom_heaters': 'سخانات(حمام)',
    'cafeteria_heaters': 'سخانات(باقي الغرف)',
  };

  // Mechanical items that only need count
  static const Map<String, String> mechanicalItemsCountOnly = {
    'hand_sink': 'مغسلة يد',
    'basin_sink': 'مغسلة حوض',
    'western_toilet': 'كرسي افرنجي',
    'arabic_toilet': 'كرسي عربي',
    'arabic_siphon': 'سيفون عربي',
    'english_siphon': 'سيفون افرنجي',
    'bidets': 'شطافات',
    'wall_exhaust_fans': 'مراوح شفط جدارية',
    'central_exhaust_fans': 'مراوح شفط مركزية',
    'cafeteria_exhaust_fans': 'مراوح شفط (باقي الغرف)',
    'wall_water_coolers': 'برادات مياة جدارية',
    'corridor_water_coolers': 'برادات مياة للممرات',
    'sink_mirrors': 'مرايا المغاسل',
    'wall_tap': 'خلاط الحائط',
    'sink_tap': 'خلاط المغسلة',
    'upper_tank': 'خزان علوي',
    'lower_tank': 'خزان سفلي',
  };

  // Mechanical items with additional text fields
  static const Map<String, String> mechanicalItemsWithTextFields = {
    'elevators': 'المصاعد',
  };

  static const Map<String, String> mechanicalYesNo = {
    'has_water_leaks': 'هل يوجد تسريب في دورات المياة؟',
  };

  static const Map<String, String> mechanicalTextFields = {
    'water_meter_number': 'رقم عداد المياة',
  };

  // Civil Category
  static const Map<String, String> civilItemsCountOnly = {
    'blackboard': 'سبورة',
    'internal_windows': 'نوافذ داخلية',
    'external_windows': 'نوافذ خارجية',
    'single_door': 'باب مفرد',
    'double_door': 'باب مزدوج',
  };

  static const Map<String, String> civilYesNo = {
    'wall_cracks': 'هل يوجد تصدع وميول بالاسوار؟',
    'falling_shades': 'هل يوجد مظلات ايلة للسقوط؟',
    'concrete_rust_damage': 'هل يوجد خرسانة متضررة بصدأ الحديد بالسقف؟',
    'roof_insulation_damage': 'هل يوجد تضرر بعزل السقف وتسرب مياة؟',
    'low_railing_height': 'هل منسوب الدرابزين منخفض عن 1.5 متر؟',
  };

  // Air Conditioning Category (التكييف) - SEPARATE FROM ELECTRICAL
  static const Map<String, String> airConditioningItems = {
    'cabinet_ac': 'دولابي',
    'split_concealed_ac': 'سبليت',
    'hidden_ducts_ac': 'مخفي بداكت',
    'window_ac': 'شباك',
    'package_ac': 'باكدج',
  };

  // Survey answer options - now using the same as alarm panel
  static const List<String> surveyOptions = [
    'جيد',
    'يحتاج صيانة',
    'تالف',
  ];

  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'fire_safety':
        return Icons.local_fire_department_rounded;
      case 'electrical':
        return Icons.electrical_services_rounded;
      case 'mechanical':
        return Icons.engineering_rounded;
      case 'civil':
        return Icons.construction_rounded;
      case 'air_conditioning':
        return Icons.ac_unit_rounded;
      default:
        return Icons.device_unknown_rounded;
    }
  }

  static Color getCategoryColor(String category) {
    switch (category) {
      case 'fire_safety':
        return const Color(0xFFE53E3E); // Red
      case 'electrical':
        return const Color(0xFFFFD700); // Gold
      case 'mechanical':
        return const Color(0xFF3182CE); // Blue
      case 'civil':
        return const Color(0xFF38A169); // Green
      case 'air_conditioning':
        return const Color(0xFF17A2B8); // Light Blue
      default:
        return const Color(0xFF718096); // Gray
    }
  }

  static String getCategoryName(String category) {
    switch (category) {
      case 'fire_safety':
        return 'أمان وسلامة';
      case 'electrical':
        return 'كهرباء';
      case 'mechanical':
        return 'ميكانيك';
      case 'civil':
        return 'أعمال مدنية';
      case 'air_conditioning':
        return 'التكييف';
      default:
        return 'فئة غير محددة';
    }
  }
} 