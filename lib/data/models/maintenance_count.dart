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
  bool get hasFireSafetyData =>
      itemCounts.keys.any((key) => key.startsWith('fire_')) ||
      fireSafetyAlarmPanelData.isNotEmpty ||
      fireSafetyConditionOnlyData.isNotEmpty ||
      fireSafetyExpiryDates.isNotEmpty;

  bool get hasElectricalData =>
      itemCounts.keys.any((key) => key.startsWith('electrical_')) ||
      textAnswers.keys.any((key) => key.contains('electricity'));

  bool get hasMechanicalData =>
      itemCounts.keys.any((key) => key.startsWith('water_')) ||
      yesNoAnswers.keys
          .any((key) => key.contains('elevator') || key.contains('water'));

  bool get hasCivilData => yesNoAnswers.keys.any((key) =>
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
