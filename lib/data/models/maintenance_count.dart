import 'package:equatable/equatable.dart';

class MaintenanceCount extends Equatable {
  final String id;
  final String schoolId;
  final String schoolName;
  final String supervisorId;
  final String status; // 'draft' or 'submitted'

  // Data fields (stored as JSONB in database)
  final Map<String, int> itemCounts;
  final Map<String, String> textAnswers;
  final Map<String, bool> yesNoAnswers;
  final Map<String, int> yesNoWithCounts;
  final Map<String, String> surveyAnswers;
  final Map<String, String> maintenanceNotes;
  final Map<String, String> fireSafetyAlarmPanelData;
  final Map<String, String> fireSafetyConditionOnlyData;
  final Map<String, String> fireSafetyExpiryDates;
  final Map<String, List<String>> sectionPhotos;
  final Map<String, dynamic> heaterEntries; // New field for heater entries

  final DateTime createdAt;
  final DateTime? updatedAt;

  const MaintenanceCount({
    required this.id,
    required this.schoolId,
    required this.schoolName,
    required this.supervisorId,
    this.status = 'draft',
    this.itemCounts = const {},
    this.textAnswers = const {},
    this.yesNoAnswers = const {},
    this.yesNoWithCounts = const {},
    this.surveyAnswers = const {},
    this.maintenanceNotes = const {},
    this.fireSafetyAlarmPanelData = const {},
    this.fireSafetyConditionOnlyData = const {},
    this.fireSafetyExpiryDates = const {},
    this.sectionPhotos = const {},
    this.heaterEntries = const {},
    required this.createdAt,
    this.updatedAt,
  });

  factory MaintenanceCount.fromMap(Map<String, dynamic> map) {
    return MaintenanceCount(
      id: map['id']?.toString() ?? '',
      schoolId: map['school_id']?.toString() ?? '',
      schoolName: map['school_name']?.toString() ?? '',
      supervisorId: map['supervisor_id']?.toString() ?? '',
      status: map['status']?.toString() ?? 'draft',
      itemCounts: _parseIntMap(map['item_counts']),
      textAnswers: _parseStringMap(map['text_answers']),
      yesNoAnswers: _parseBoolMap(map['yes_no_answers']),
      yesNoWithCounts: _parseIntMap(map['yes_no_with_counts']),
      surveyAnswers: _parseStringMap(map['survey_answers']),
      maintenanceNotes: _parseStringMap(map['maintenance_notes']),
      fireSafetyAlarmPanelData:
          _parseStringMap(map['fire_safety_alarm_panel_data']),
      fireSafetyConditionOnlyData:
          _parseStringMap(map['fire_safety_condition_only_data']),
      fireSafetyExpiryDates: _parseStringMap(map['fire_safety_expiry_dates']),
      sectionPhotos: _parseStringListMap(map['section_photos']),
      heaterEntries: _parseHeaterEntriesMap(map['heater_entries']),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'school_name': schoolName,
      'supervisor_id': supervisorId,
      'status': status,
      'item_counts': itemCounts,
      'text_answers': textAnswers,
      'yes_no_answers': yesNoAnswers,
      'yes_no_with_counts': yesNoWithCounts,
      'survey_answers': surveyAnswers,
      'maintenance_notes': maintenanceNotes,
      'fire_safety_alarm_panel_data': fireSafetyAlarmPanelData,
      'fire_safety_condition_only_data': fireSafetyConditionOnlyData,
      'fire_safety_expiry_dates': fireSafetyExpiryDates,
      'section_photos': sectionPhotos,
      'heater_entries': heaterEntries,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  MaintenanceCount copyWith({
    String? id,
    String? schoolId,
    String? schoolName,
    String? supervisorId,
    String? status,
    Map<String, int>? itemCounts,
    Map<String, String>? textAnswers,
    Map<String, bool>? yesNoAnswers,
    Map<String, int>? yesNoWithCounts,
    Map<String, String>? surveyAnswers,
    Map<String, String>? maintenanceNotes,
    Map<String, String>? fireSafetyAlarmPanelData,
    Map<String, String>? fireSafetyConditionOnlyData,
    Map<String, String>? fireSafetyExpiryDates,
    Map<String, List<String>>? sectionPhotos,
    Map<String, dynamic>? heaterEntries,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaintenanceCount(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      supervisorId: supervisorId ?? this.supervisorId,
      status: status ?? this.status,
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
      sectionPhotos: sectionPhotos ?? this.sectionPhotos,
      heaterEntries: heaterEntries ?? this.heaterEntries,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods for parsing JSONB data
  static Map<String, int> _parseIntMap(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) {
      return data.map((key, value) => MapEntry(
          key, value is int ? value : int.tryParse(value.toString()) ?? 0));
    }
    return {};
  }

  static Map<String, String> _parseStringMap(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) {
      return data.map((key, value) => MapEntry(key, value.toString()));
    }
    return {};
  }

  static Map<String, bool> _parseBoolMap(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) {
      return data.map((key, value) => MapEntry(key,
          value is bool ? value : value.toString().toLowerCase() == 'true'));
    }
    return {};
  }

  static Map<String, List<String>> _parseStringListMap(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) {
      return data.map((key, value) {
        if (value is List) {
          return MapEntry(key, value.map((e) => e.toString()).toList());
        }
        return MapEntry(key, <String>[]);
      });
    }
    return {};
  }

  static Map<String, dynamic> _parseHeaterEntriesMap(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) {
      return data;
    }
    return {};
  }

  // Utility methods for checking data presence
  bool get hasAirConditioningData =>
      itemCounts.keys.any((key) => MaintenanceItemTypes.airConditioningTypes.contains(key));

  bool get hasElectricalData =>
      itemCounts.keys.any((key) => MaintenanceItemTypes.electricalTypes.contains(key)) ||
      itemCounts.keys.any((key) => MaintenanceItemTypes.electricalPanelTypes.contains(key)) ||
      itemCounts.keys.any((key) => MaintenanceItemTypes.electricalBreakerTypes.contains(key)) ||
      textAnswers.keys.any((key) => key.contains('electricity'));

  bool get hasFireSafetyData =>
      itemCounts.keys.any((key) => MaintenanceItemTypes.fireSafetyTypes.contains(key)) ||
      itemCounts.keys.any((key) => MaintenanceItemTypes.fireItemsWithCondition.contains(key)) ||
      itemCounts.keys.any((key) => MaintenanceItemTypes.fireSafetyItemsWithCountAndCondition.contains(key)) ||
      fireSafetyAlarmPanelData.isNotEmpty ||
      fireSafetyConditionOnlyData.isNotEmpty ||
      fireSafetyExpiryDates.isNotEmpty;

  bool get hasMechanicalData =>
      itemCounts.keys.any((key) => MaintenanceItemTypes.mechanicalTypes.contains(key)) ||
      itemCounts.keys.any((key) => MaintenanceItemTypes.mechanicalHeaterTypes.contains(key)) ||
      itemCounts.keys.any((key) => MaintenanceItemTypes.mechanicalItemsCountOnly.contains(key)) ||
      yesNoAnswers.keys.any((key) => key.contains('elevator') || key.contains('water'));

  bool get hasCivilData =>
      itemCounts.keys.any((key) => MaintenanceItemTypes.civilItemsCountOnly.contains(key)) ||
      yesNoAnswers.keys.any((key) =>
          key.contains('wall_') ||
          key.contains('roof_') ||
          key.contains('concrete_'));

  bool get hasDamageData =>
      yesNoAnswers.values.any((value) => value == true) ||
      fireSafetyConditionOnlyData.values.any((value) => value == 'تالف') ||
      surveyAnswers.values
          .any((value) => value == 'تالف' || value == 'يحتاج صيانة');

  // Get total photo count
  int get totalPhotoCount =>
      sectionPhotos.values.fold(0, (sum, photos) => sum + photos.length);

  // Get photos by section
  List<String> getPhotosBySection(String section) =>
      sectionPhotos[section] ?? [];

  // New utility methods for field types
  bool get hasTextAnswerData =>
      textAnswers.keys.any((key) => MaintenanceFieldTypes.textAnswerFields.contains(key));

  bool get hasYesNoAnswerData =>
      yesNoAnswers.keys.any((key) => MaintenanceFieldTypes.yesNoAnswerFields.contains(key));

  bool get hasYesNoWithCountsData =>
      yesNoWithCounts.keys.any((key) => MaintenanceFieldTypes.yesNoWithCountsFields.contains(key));

  bool get hasSurveyAnswerData =>
      surveyAnswers.keys.any((key) => MaintenanceFieldTypes.surveyAnswerFields.contains(key));

  // Get specific data by category
  Map<String, String> getTextAnswersByCategory() {
    return Map.fromEntries(
      textAnswers.entries.where((entry) => 
        MaintenanceFieldTypes.textAnswerFields.contains(entry.key))
    );
  }

  Map<String, bool> getYesNoAnswersByCategory() {
    return Map.fromEntries(
      yesNoAnswers.entries.where((entry) => 
        MaintenanceFieldTypes.yesNoAnswerFields.contains(entry.key))
    );
  }

  Map<String, int> getYesNoWithCountsByCategory() {
    return Map.fromEntries(
      yesNoWithCounts.entries.where((entry) => 
        MaintenanceFieldTypes.yesNoWithCountsFields.contains(entry.key))
    );
  }

  Map<String, String> getSurveyAnswersByCategory() {
    return Map.fromEntries(
      surveyAnswers.entries.where((entry) => 
        MaintenanceFieldTypes.surveyAnswerFields.contains(entry.key))
    );
  }

  // Get items by category
  Map<String, int> getItemsByCategory(String category) {
    final categoryItems = MaintenanceItemTypes.getItemsByCategory()[category] ?? [];
    return Map.fromEntries(
      itemCounts.entries.where((entry) => categoryItems.contains(entry.key))
    );
  }

  // Get total count for a specific category
  int getCategoryTotalCount(String category) {
    final categoryItems = getItemsByCategory(category);
    return categoryItems.values.fold(0, (sum, count) => sum + count);
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        schoolName,
        supervisorId,
        status,
        itemCounts,
        textAnswers,
        yesNoAnswers,
        yesNoWithCounts,
        surveyAnswers,
        maintenanceNotes,
        fireSafetyAlarmPanelData,
        fireSafetyConditionOnlyData,
        fireSafetyExpiryDates,
        sectionPhotos,
        heaterEntries,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'MaintenanceCount(id: $id, schoolName: $schoolName, status: $status, createdAt: $createdAt)';
  }
}

// Constants for condition options
class MaintenanceConditions {
  static const List<String> conditionOptions = [
    'جيد', // Good
    'يحتاج صيانة', // Needs Maintenance
    'تالف', // Damaged
  ];

  static const List<String> firePanelTypes = [
    'conventional', // Traditional
    'addressable', // Addressable
  ];
}

// Field types for different answer categories
class MaintenanceFieldTypes {
  // Text answer fields (amperage, capacity, meter numbers, etc.)
  static const List<String> textAnswerFields = [
    'ac_panel_amperage',
    'power_panel_amperage',
    'main_breaker_amperage',
    'lighting_panel_amperage',
    'electricity_meter_number',
    'bathroom_heaters_1_capacity',
    'bathroom_heaters_2_capacity',
    'concealed_ac_breaker_amperage',
    'main_distribution_panel_amperage',
    'fire_extinguishers_expiry_day',
    'fire_extinguishers_expiry_year',
    'fire_extinguishers_expiry_month',
  ];

  // Yes/No answer fields (structural issues, safety concerns)
  static const List<String> yesNoAnswerFields = [
    'elevators',
    'wall_cracks',
    'falling_shades',
    'has_water_leaks',
    'low_railing_height',
    'concrete_rust_damage',
    'roof_insulation_damage',
  ];

  // Yes/No with counts fields (same as yes/no but with counts)
  static const List<String> yesNoWithCountsFields = [
    'elevators',
    'wall_cracks',
    'falling_shades',
    'has_water_leaks',
    'low_railing_height',
    'concrete_rust_damage',
    'roof_insulation_damage',
  ];

  // Survey answer fields (condition assessments)
  static const List<String> surveyAnswerFields = [
    'bells_condition',
    'alarm_panel_type',
    'fire_alarm_system',
    'fire_hose_condition',
    'fire_boxes_condition',
    'alarm_panel_condition',
    'diesel_pump_condition',
    'electric_pump_condition',
    'fire_suppression_system',
    'auxiliary_pump_condition',
    'heat_detectors_condition',
    'emergency_exits_condition',
    'smoke_detectors_condition',
    'emergency_lights_condition',
    'fire_alarm_system_condition',
    'fire_suppression_system_condition',
  ];

  // Get all field types combined
  static List<String> getAllFieldTypes() {
    return [
      ...textAnswerFields,
      ...yesNoAnswerFields,
      ...yesNoWithCountsFields,
      ...surveyAnswerFields,
    ];
  }

  // Get fields by category
  static Map<String, List<String>> getFieldsByCategory() {
    return {
      'text': textAnswerFields,
      'yesNo': yesNoAnswerFields,
      'yesNoWithCounts': yesNoWithCountsFields,
      'survey': surveyAnswerFields,
    };
  }
}

// New constants for updated item structure
class MaintenanceItemTypes {
  // Air Conditioning Category (التكييف) - SEPARATE FROM ELECTRICAL
  static const List<String> airConditioningTypes = [
    'cabinet_ac',           // دولابي
    'split_concealed_ac',   // سبليت
    'hidden_ducts_ac',      // مخفي بداكت
    'window_ac',            // شباك
    'package_ac',           // باكدج
  ];

  // Electrical Category (كهرباء) - WITHOUT AC ITEMS
  static const List<String> electricalTypes = [
    'lamps',                // لمبات
    'projector',            // بروجيكتور
    'class_bell',           // جرس الفصول
    'speakers',             // السماعات
    'microphone_system',    // نظام الميكوفون
  ];

  // Electrical panels that need count and amperage
  static const List<String> electricalPanelTypes = [
    'lighting_panel',           // لوحة انارة
    'power_panel',              // لوحة باور(أفياش)
    'ac_panel',                 // لوحة تكييف
    'main_distribution_panel',  // لوحة توزيع رئيسية
  ];

  // Electrical breakers that need count and amperage
  static const List<String> electricalBreakerTypes = [
    'main_breaker',             // القاطع الرئيسي
    'concealed_ac_breaker',     // قاطع تكييف (كونسيلد)
    'package_ac_breaker',       // قاطع تكييف (باكدج)
  ];

  // Fire and Safety Category (أمان وسلامة)
  static const List<String> fireSafetyTypes = [
    'electric_pump',            // مضخة الكهرباء
    'diesel_pump',             // مضخة الديزل
    'auxiliary_pump',          // المضخة المساعدة
    'fire_extinguishers',       // طفايات الحريق
    'fire_boxes',              // صناديق الحريق
    'camera',                  // كاميرا
    'emergency_signs',         // لوحات الطوارئ
  ];

  // Fire items that need both count and condition
  static const List<String> fireItemsWithCondition = [
    'fire_hose',               // خرطوم الحريق
  ];

  // Fire safety items with count and condition
  static const List<String> fireSafetyItemsWithCountAndCondition = [
    'emergency_lights',        // كشافات طوارئ
    'emergency_exits',         // مخارج الطوارئ
    'smoke_detectors',         // كواشف دخان
    'heat_detectors',          // كواشف حرارة
    'breakers',                // كواسر
    'bells',                   // اجراس
  ];

  // Mechanical Category (ميكانيك)
  static const List<String> mechanicalTypes = [
    'water_pumps',             // مضخات المياة
  ];

  // Mechanical heaters with multiple entries (capacity and quantity)
  // Note: Individual heater entries are now combined into a single "سخانات" entry in Excel exports
  static const List<String> mechanicalHeaterTypes = [
    // Individual heater types removed - now handled as combined "سخانات" in exports
  ];

  // Mechanical items that only need count
  static const List<String> mechanicalItemsCountOnly = [
    'hand_sink',               // مغسلة يد
    'basin_sink',              // مغسلة حوض
    'western_toilet',          // كرسي افرنجي
    'arabic_toilet',           // كرسي عربي
    'arabic_siphon',           // سيفون عربي
    'english_siphon',          // سيفون افرنجي
    'bidets',                  // شطافات
    'wall_exhaust_fans',       // مراوح شفط جدارية
    'central_exhaust_fans',    // مراوح شفط مركزية
    'cafeteria_exhaust_fans',  // مراوح شفط (باقي الغرف)
    'wall_water_coolers',      // برادات مياة جدارية
    'corridor_water_coolers',  // برادات مياة للممرات
    'sink_mirrors',            // مرايا المغاسل
    'wall_tap',                // خلاط الحائط
    'sink_tap',                // خلاط المغسلة
    'upper_tank',              // خزان علوي
    'lower_tank',              // خزان سفلي
  ];

  // Civil Category (أعمال مدنية)
  static const List<String> civilItemsCountOnly = [
    'blackboard',              // سبورة
    'internal_windows',        // نوافذ داخلية
    'external_windows',        // نوافذ خارجية
    'single_door',             // باب مفرد
    'double_door',             // باب مزدوج
  ];

  // All item types combined
  static List<String> getAllItemTypes() {
    return [
      ...airConditioningTypes,
      ...electricalTypes,
      ...electricalPanelTypes,
      ...electricalBreakerTypes,
      ...fireSafetyTypes,
      ...fireItemsWithCondition,
      ...fireSafetyItemsWithCountAndCondition,
      ...mechanicalTypes,
      ...mechanicalHeaterTypes,
      ...mechanicalItemsCountOnly,
      ...civilItemsCountOnly,
      // Legacy items
      'alarm_panel_count',
    ];
  }

  // Get items by category for better organization
  static Map<String, List<String>> getItemsByCategory() {
    return {
      'air_conditioning': airConditioningTypes,
      'electrical': electricalTypes,
      'electrical_panels': electricalPanelTypes,
      'electrical_breakers': electricalBreakerTypes,
      'fire_safety': fireSafetyTypes,
      'fire_safety_with_condition': fireItemsWithCondition,
      'fire_safety_count_and_condition': fireSafetyItemsWithCountAndCondition,
      'mechanical': mechanicalTypes,
      // 'mechanical_heaters' category removed - heaters now handled as combined "سخانات" in exports
      'mechanical_items': mechanicalItemsCountOnly,
      'civil': civilItemsCountOnly,
    };
  }

  // Get category display names
  static String getCategoryDisplayName(String category) {
    switch (category) {
      case 'air_conditioning':
        return 'التكييف';
      case 'electrical':
        return 'كهرباء';
      case 'electrical_panels':
        return 'لوحات كهربائية';
      case 'electrical_breakers':
        return 'قواطع كهربائية';
      case 'fire_safety':
        return 'أمان وسلامة';
      case 'fire_safety_with_condition':
        return 'أمان وسلامة (مع حالة)';
      case 'fire_safety_count_and_condition':
        return 'أمان وسلامة (عدد وحالة)';
      case 'mechanical':
        return 'ميكانيك';
      case 'mechanical_heaters':
        return 'سخانات';
      case 'mechanical_items':
        return 'عناصر ميكانيكية';
      case 'civil':
        return 'أعمال مدنية';
      default:
        return 'فئة غير محددة';
    }
  }
}
