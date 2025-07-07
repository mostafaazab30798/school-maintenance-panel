import 'package:equatable/equatable.dart';

class DamageCount extends Equatable {
  final String id;
  final String schoolId;
  final String schoolName;
  final String supervisorId;
  final String status; // 'draft' or 'submitted'

  // Damage data fields (stored as JSONB in database)
  final Map<String, int> itemCounts;
  final Map<String, List<String>> sectionPhotos;

  final DateTime createdAt;
  final DateTime? updatedAt;

  const DamageCount({
    required this.id,
    required this.schoolId,
    required this.schoolName,
    required this.supervisorId,
    this.status = 'draft',
    this.itemCounts = const {},
    this.sectionPhotos = const {},
    required this.createdAt,
    this.updatedAt,
  });

  factory DamageCount.fromMap(Map<String, dynamic> map) {
    print('🔍 DEBUG: Creating DamageCount from map: $map');

    final damageCount = DamageCount(
      id: map['id']?.toString() ?? '',
      schoolId: map['school_id']?.toString() ?? '',
      schoolName: map['school_name']?.toString() ?? '',
      supervisorId: map['supervisor_id']?.toString() ?? '',
      status: map['status']?.toString() ?? 'draft',
      itemCounts: _parseIntMap(map['item_counts']),
      sectionPhotos: _parseStringListMap(map['section_photos']),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : null,
    );

    print(
        '🔍 DEBUG: Created DamageCount - ID: ${damageCount.id}, School: ${damageCount.schoolName}, Items: ${damageCount.itemCounts}');
    return damageCount;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'school_name': schoolName,
      'supervisor_id': supervisorId,
      'status': status,
      'item_counts': itemCounts,
      'section_photos': sectionPhotos,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  DamageCount copyWith({
    String? id,
    String? schoolId,
    String? schoolName,
    String? supervisorId,
    String? status,
    Map<String, int>? itemCounts,
    Map<String, List<String>>? sectionPhotos,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DamageCount(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      supervisorId: supervisorId ?? this.supervisorId,
      status: status ?? this.status,
      itemCounts: itemCounts ?? this.itemCounts,
      sectionPhotos: sectionPhotos ?? this.sectionPhotos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods for parsing JSONB data
  static Map<String, int> _parseIntMap(dynamic data) {
    print('🔍 DEBUG: Parsing int map from: $data (type: ${data.runtimeType})');
    if (data == null) return {};
    if (data is Map<String, dynamic>) {
      final result = data.map((key, value) => MapEntry(key,
          value is num ? value.toInt() : int.tryParse(value.toString()) ?? 0));
      print('🔍 DEBUG: Parsed int map result: $result');
      return result;
    }
    return {};
  }

  static Map<String, List<String>> _parseStringListMap(dynamic data) {
    print(
        '🔍 DEBUG: Parsing string list map from: $data (type: ${data.runtimeType})');
    if (data == null) return {};
    if (data is Map<String, dynamic>) {
      final result = data.map((key, value) {
        if (value is List) {
          return MapEntry(key, value.map((e) => e.toString()).toList());
        }
        return MapEntry(key, <String>[]);
      });
      print('🔍 DEBUG: Parsed string list map result: $result');
      return result;
    }
    return {};
  }

  // Utility methods
  int get totalDamagedItems =>
      itemCounts.values.fold(0, (sum, count) => sum + count);

  bool get hasDamage => itemCounts.values.any((count) => count > 0);

  List<String> get damagedItemNames => itemCounts.entries
      .where((entry) => entry.value > 0)
      .map((entry) => entry.key)
      .toList();

  // Get item display names in Arabic
  String getItemDisplayName(String itemKey) {
    const itemNames = {
      // أعمال الميكانيك والسباكة (Mechanical and Plumbing Work)
      'plastic_chair': 'كرسي شرقي',
      'plastic_chair_external': 'كرسي افرنجي',
      'water_sink': 'حوض مغسلة مع القاعدة',
      'hidden_boxes': 'صناديق طرد مخفي-للكرسي العربي',
      'low_boxes': 'صناديق طرد واطي-للكرسي الافرنجي',
      'upvc_pipes_4_5':
          'مواسير قطر من(4 الى 0.5) بوصة upvc class 5 وضغط داخلي 16pin',
      'glass_fiber_tank_5000': 'خزان علوي فايبر جلاس سعة 5000 لتر',
      'glass_fiber_tank_4000': 'خزان علوي فايبر جلاس سعة 4000 لتر',
      'glass_fiber_tank_3000': 'خزان علوي فايبر جلاس سعة 3000 لتر',
      'booster_pump_3_phase': 'مضخات مياة 3 حصان- Booster Pump',
      'elevator_pulley_machine': 'محرك  + صندوق تروس مصاعد - Elevators',

      // أعمال الكهرباء (Electrical Work)
      'circuit_breaker_250': 'قاطع كهرباني سعة (250) أمبير',
      'circuit_breaker_400': 'قاطع كهرباني سعة (400) أمبير',
      'circuit_breaker_1250': 'قاطع كهرباني سعة 1250 أمبير',
      'electrical_distribution_unit': 'أغطية لوحات التوزيع الفرعية',
      'copper_cable': 'كبل نحاس  مسلح مقاس (4*16)',
      'fluorescent_48w_main_branch':
          'لوحة توزيع فرعية (48) خط مزوده عدد (24) قاطع فرعي مزدوج سعة (30 امبير) وقاطع رئيسي سعة 125 امبير',
      'fluorescent_36w_sub_branch':
          'لوحة توزيع فرعية (36) خط مزوده عدد (24) قاطع فرعي مزدوج سعة (30 امبير) وقاطع رئيسي سعة 125 امبير',
      'electric_water_heater_50l': 'سخانات المياه الكهربائية سعة 50 لتر',
      'electric_water_heater_100l': 'سخانات المياه الكهربائية سعة 100 لتر',

      // أعمال مدنية (Civil Work)
      'upvc_50_meter': 'قماش مظلات من مادة (UPVC) لفة (50) متر مربع',

      // أعمال الامن والسلامة (Safety and Security Work)
      'pvc_pipe_connection_4':
          'محبس حريق OS&Y من قطر 4 بوصة الى 3 بوصة كامل Flange End',
      'fire_alarm_panel':
          'لوحة انذار معنونه كاملة ( مع الاكسسوارات ) والبطارية ( 12/10/8 ) زون',
      'dry_powder_6kg': 'طفاية حريق Dry powder وزن 6 كيلو',
      'co2_9kg': 'طفاية حريق CO2 وزن(9) كيلو',
      'fire_pump_1750': 'مضخة حريق 1750 دورة/د وتصرف 125 جالون/ضغط 7 بار',
      'joky_pump': 'مضخة حريق تعويضيه جوكي ضغط 7 بار',
      'fire_suppression_box': 'صدنوق إطفاء حريق بكامل عناصره',

      // التكييف (Air Conditioning)
      'cabinet_ac': 'دولابي',
      'split_ac': 'سبليت',
      'window_ac': 'شباك',
      'package_ac': 'باكدج',
    };

    return itemNames[itemKey] ?? itemKey;
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        schoolName,
        supervisorId,
        status,
        itemCounts,
        sectionPhotos,
        createdAt,
        updatedAt,
      ];
}
