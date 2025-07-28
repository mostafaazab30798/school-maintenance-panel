import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

/// FCI Assessment model
class FciAssessment extends Equatable {
  final String id;
  final String schoolId;
  final String schoolName;
  final Map<String, Map<String, String>> categoryAssessments;
  final Map<String, dynamic> sectionPhotos;
  final String supervisorId;
  final String supervisorName; // Add supervisor name field
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FciAssessment({
    required this.id,
    required this.schoolId,
    required this.schoolName,
    required this.categoryAssessments,
    required this.sectionPhotos,
    required this.supervisorId,
    required this.supervisorName, // Add supervisor name parameter
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    schoolId,
    schoolName,
    categoryAssessments,
    sectionPhotos,
    supervisorId,
    supervisorName,
    status,
    createdAt,
    updatedAt,
  ];

  factory FciAssessment.fromJson(Map<String, dynamic> json) {
    try {
      // Properly cast the category_assessments to the correct type
      Map<String, Map<String, String>> categoryAssessments = {};
      if (json['category_assessments'] != null) {
        final rawCategories = json['category_assessments'];
        if (rawCategories is Map<String, dynamic>) {
          for (String categoryKey in rawCategories.keys) {
            final rawItems = rawCategories[categoryKey];
            if (rawItems is Map<String, dynamic>) {
              Map<String, String> items = {};
              for (String itemKey in rawItems.keys) {
                items[itemKey] = rawItems[itemKey].toString();
              }
              categoryAssessments[categoryKey] = items;
            }
          }
        }
      }

      return FciAssessment(
        id: json['id']?.toString() ?? '',
        schoolId: json['school_id']?.toString() ?? '',
        schoolName: json['school_name']?.toString() ?? '',
        categoryAssessments: categoryAssessments,
        sectionPhotos: json['section_photos'] is Map<String, dynamic> 
            ? Map<String, dynamic>.from(json['section_photos']) 
            : <String, dynamic>{},
        supervisorId: json['supervisor_id']?.toString() ?? '',
        supervisorName: json['supervisor_name']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        createdAt: _parseDateTime(json['created_at']),
        updatedAt: _parseDateTime(json['updated_at']),
      );
    } catch (e) {
      print('❌ Error parsing FciAssessment from JSON: $e');
      print('❌ JSON data: $json');
      rethrow;
    }
  }

  /// Helper method to safely parse DateTime
  static DateTime _parseDateTime(dynamic dateValue) {
    try {
      if (dateValue is String) {
        return DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        return dateValue;
      } else {
        return DateTime.now();
      }
    } catch (e) {
      print('⚠️ Warning: Could not parse date: $dateValue, using current time');
      return DateTime.now();
    }
  }

  /// Debug method to log assessment details
  void debugPrint() {
    print('🔍 FciAssessment Debug:');
    print('  ID: $id');
    print('  School: $schoolName ($schoolId)');
    print('  Supervisor: $supervisorName ($supervisorId)');
    print('  Status: $status');
    print('  Categories: ${categoryAssessments.length}');
    print('  Created: $createdAt');
    print('  Updated: $updatedAt');
  }

  /// Check if this assessment is valid
  bool get isValid => 
    id.isNotEmpty && 
    schoolId.isNotEmpty && 
    schoolName.isNotEmpty && 
    supervisorId.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'school_name': schoolName,
      'category_assessments': categoryAssessments,
      'section_photos': sectionPhotos,
      'supervisor_id': supervisorId,
      'supervisor_name': supervisorName, // Add supervisor name to JSON
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Creates a copy of this FciAssessment with updated fields
  FciAssessment copyWith({
    String? id,
    String? schoolId,
    String? schoolName,
    Map<String, Map<String, String>>? categoryAssessments,
    Map<String, dynamic>? sectionPhotos,
    String? supervisorId,
    String? supervisorName,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FciAssessment(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      categoryAssessments: categoryAssessments ?? this.categoryAssessments,
      sectionPhotos: sectionPhotos ?? this.sectionPhotos,
      supervisorId: supervisorId ?? this.supervisorId,
      supervisorName: supervisorName ?? this.supervisorName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculate overall building state based on weighted percentages
  BuildingState calculateBuildingState() {
    double totalScore = 0.0;
    double totalWeight = 0.0;
    Map<String, CategoryScore> categoryScores = {};

    // Calculate score for each category
    for (String categoryKey in FCICategories.categoryWeights.keys) {
      if (categoryAssessments.containsKey(categoryKey)) {
        CategoryScore categoryScore = _calculateCategoryScore(categoryKey);
        categoryScores[categoryKey] = categoryScore;
        
        // Add weighted score to total
        double categoryWeight = FCICategories.categoryWeights[categoryKey]!;
        totalScore += categoryScore.score * categoryWeight;
        totalWeight += categoryWeight;
      }
    }

    // Calculate overall percentage
    double overallPercentage = totalWeight > 0 ? (totalScore / totalWeight) * 100 : 0;

    return BuildingState(
      overallPercentage: overallPercentage,
      categoryScores: categoryScores,
      totalItems: _getTotalItems(),
      goodItems: _getGoodItems(),
      poorItems: _getPoorItems(),
      acceptableItems: _getAcceptableItems(),
      criticalItems: _getCriticalItems(),
      damagedItems: _getDamagedItems(),
    );
  }

  /// Calculate score for a specific category
  CategoryScore _calculateCategoryScore(String categoryKey) {
    double categoryScore = 0.0;
    double categoryWeight = 0.0;
    Map<String, ItemScore> itemScores = {};

    Map<String, String> items = categoryAssessments[categoryKey] ?? {};
    Map<String, double> itemWeights = FCICategories.itemWeights[categoryKey] ?? {};

    for (String itemKey in items.keys) {
      if (itemWeights.containsKey(itemKey)) {
        String status = items[itemKey] ?? '';
        double itemWeight = itemWeights[itemKey]!;
        double itemScore = _getStatusScore(status);
        
        itemScores[itemKey] = ItemScore(
          status: status,
          score: itemScore,
          weight: itemWeight,
        );
        
        categoryScore += itemScore * itemWeight;
        categoryWeight += itemWeight;
      }
    }

    double finalCategoryScore = categoryWeight > 0 ? categoryScore / categoryWeight : 0;

    return CategoryScore(
      score: finalCategoryScore,
      weight: FCICategories.categoryWeights[categoryKey] ?? 0,
      itemScores: itemScores,
    );
  }

  /// Get score for a status (جيد = 0.9, مناسب = 0.6, ضعيف = 0.4, حرج = 0.2, تالف = 0.0)
  double _getStatusScore(String status) {
    switch (status) {
      case 'جيد':
        return 0.9; // 80-100% average
      case 'مناسب':
        return 0.6; // 60%
      case 'ضعيف':
        return 0.4; // 40%
      case 'حرج':
        return 0.2; // 20%
      case 'تالف':
        return 0.0; // 0%
      case 'غير موجود':
        return 0.0; // 0% (treat as damaged)
      default:
        return 0.0;
    }
  }

  /// Get total number of items
  int _getTotalItems() {
    int total = 0;
    for (Map<String, String> items in categoryAssessments.values) {
      total += items.length;
    }
    return total;
  }

  /// Get number of good items
  int _getGoodItems() {
    int good = 0;
    for (Map<String, String> items in categoryAssessments.values) {
      for (String status in items.values) {
        if (status == 'جيد') good++;
      }
    }
    return good;
  }

  /// Get number of poor items (ضعيف)
  int _getPoorItems() {
    int poor = 0;
    for (Map<String, String> items in categoryAssessments.values) {
      for (String status in items.values) {
        if (status == 'ضعيف') poor++;
      }
    }
    return poor;
  }

  /// Get number of acceptable items (مناسب)
  int _getAcceptableItems() {
    int acceptable = 0;
    for (Map<String, String> items in categoryAssessments.values) {
      for (String status in items.values) {
        if (status == 'مناسب') acceptable++;
      }
    }
    return acceptable;
  }

  /// Get number of critical items (حرج)
  int _getCriticalItems() {
    int critical = 0;
    for (Map<String, String> items in categoryAssessments.values) {
      for (String status in items.values) {
        if (status == 'حرج') critical++;
      }
    }
    return critical;
  }

  /// Get number of damaged items (تالف, غير موجود)
  int _getDamagedItems() {
    int damaged = 0;
    for (Map<String, String> items in categoryAssessments.values) {
      for (String status in items.values) {
        if (status == 'تالف' || status == 'غير موجود') damaged++;
      }
    }
    return damaged;
  }
}

/// Building state calculation result
class BuildingState {
  final double overallPercentage;
  final Map<String, CategoryScore> categoryScores;
  final int totalItems;
  final int goodItems;
  final int poorItems;
  final int acceptableItems;
  final int criticalItems;
  final int damagedItems;

  BuildingState({
    required this.overallPercentage,
    required this.categoryScores,
    required this.totalItems,
    required this.goodItems,
    required this.poorItems,
    required this.acceptableItems,
    required this.criticalItems,
    required this.damagedItems,
  });

  /// Get overall condition text
  String get overallCondition {
    if (overallPercentage >= 85) return 'ممتاز';
    if (overallPercentage >= 70) return 'جيد جداً';
    if (overallPercentage >= 55) return 'جيد';
    if (overallPercentage >= 40) return 'مناسب';
    if (overallPercentage >= 25) return 'ضعيف';
    if (overallPercentage >= 10) return 'حرج';
    return 'تالف';
  }

  /// Get overall condition color
  Color get overallConditionColor {
    if (overallPercentage >= 85) return Colors.green;
    if (overallPercentage >= 70) return Colors.lightGreen;
    if (overallPercentage >= 55) return const Color(0xFF26A69A);
    if (overallPercentage >= 40) return const Color(0xFF26A69A);
    if (overallPercentage >= 25) return Colors.deepOrange;
    if (overallPercentage >= 10) return Colors.red;
    return Colors.red.shade900;
  }

  /// Get category condition text
  String getCategoryCondition(String categoryKey) {
    CategoryScore? categoryScore = categoryScores[categoryKey];
    if (categoryScore == null) return 'غير محدد';
    
    double percentage = categoryScore.score * 100;
    if (percentage >= 85) return 'ممتاز';
    if (percentage >= 70) return 'جيد جداً';
    if (percentage >= 55) return 'جيد';
    if (percentage >= 40) return 'مناسب';
    if (percentage >= 25) return 'ضعيف';
    if (percentage >= 10) return 'حرج';
    return 'تالف';
  }

  /// Get category condition color
  Color getCategoryConditionColor(String categoryKey) {
    CategoryScore? categoryScore = categoryScores[categoryKey];
    if (categoryScore == null) return Colors.grey;
    
    double percentage = categoryScore.score * 100;
    if (percentage >= 85) return Colors.green;
    if (percentage >= 70) return Colors.lightGreen;
    if (percentage >= 55) return const Color(0xFF26A69A);
    if (percentage >= 40) return const Color(0xFF26A69A);
    if (percentage >= 25) return Colors.deepOrange;
    if (percentage >= 10) return Colors.red;
    return Colors.red.shade900;
  }
}

/// Category score calculation result
class CategoryScore {
  final double score;
  final double weight;
  final Map<String, ItemScore> itemScores;

  CategoryScore({
    required this.score,
    required this.weight,
    required this.itemScores,
  });

  /// Get category percentage
  double get percentage => score * 100;
}

/// Item score calculation result
class ItemScore {
  final String status;
  final double score;
  final double weight;

  ItemScore({
    required this.status,
    required this.score,
    required this.weight,
  });

  /// Get item percentage
  double get percentage => score * 100;
}

/// FCI categories and items based on the requirements
class FCICategories {
  // Category weights (percentage of overall building state)
  static const Map<String, double> categoryWeights = {
    'foundations': 10.0,           // الأساسات
    'structural': 15.0,            // الهيكل الإنشائي
    'walls': 7.0,                  // الحوائط
    'tiles_floors': 2.0,           // البلاط والأرضيات
    'woodwork': 2.0,               // أعمال النجارة
    'aluminum': 2.0,               // أعمال الألمونيوم
    'ironwork': 3.0,               // أعمال الحديد
    'plastering': 5.0,             // أعمال اللياسة والمحارة
    'paintings': 2.0,              // أعمال الدهانات والديكورات
    'insulation': 5.0,             // أعمال العزل
    'site_floors': 2.0,            // أرضيات الموقع العام
    'suspended_ceilings': 2.0,     // أعمال الأسقف المستعارة
    'shades': 3.0,                 // المظلات
    'fire_fighting': 5.0,          // أنظمة مكافحة الحريق
    'plumbing': 6.0,               // أنظمة السباكة والصرف الصحي
    'hvac': 6.0,                   // أنظمة التكييف والتهوية والتدفئة
    'electrical': 14.0,            // أنظمة الكهرباء والطاقة
    'low_voltage': 8.0,            // أنظمة الجهد المنخفض
    'elevators': 2.0,              // أنظمة المصاعد
  };

  // Item weights within each category (percentage of category)
  static const Map<String, Map<String, double>> itemWeights = {
    'foundations': {
      'foundations': 70.0,         // الأساسات
      'ground_bridges': 30.0,      // الجسور الأرضية
    },
    'structural': {
      'columns': 45.0,             // الأعمدة
      'ceilings': 40.0,            // الأسقف
      'concrete_stairs': 15.0,     // السلالم الخرسانية
    },
    'walls': {
      'internal_walls': 50.0,      // الحوائط الداخلية
      'external_walls': 50.0,      // الحوائط الخارجية
    },
    'tiles_floors': {
      'floor_tiles': 70.0,         // بلاط الأرضيات
      'stair_tiles': 30.0,         // بلاط السلالم
    },
    'woodwork': {
      'doors': 40.0,               // الأبواب
      'windows': 30.0,             // الشبابيك
      'furniture': 15.0,           // الأثاث
      'partitions': 15.0,          // القواطع
    },
    'aluminum': {
      'doors': 30.0,               // الأبواب
      'windows': 60.0,             // الشبابيك
      'kitchens': 10.0,            // المطابخ
    },
    'ironwork': {
      'doors': 50.0,               // الأبواب
      'window_protection': 10.0,   // حماية الشبابيك
      'handrails': 20.0,           // الدرابزين
      'escape_stairs': 10.0,       // سلالم الهروب
      'pump_rooms': 10.0,          // غرف المضخات
    },
    'plastering': {
      'internal_plastering': 70.0, // اللياسة الداخلية
      'external_plastering': 30.0, // اللياسة الخارجية
    },
    'paintings': {
      'internal_paintings': 50.0,  // الدهانات الداخلية
      'external_paintings': 50.0,  // الدهانات الخارجية
    },
    'insulation': {
      'roof_insulation': 60.0,     // عزل السطح
      'floor_insulation': 30.0,    // عزل الأرضيات
      'expansion_joints': 10.0,    // فواصل التمدد
    },
    'site_floors': {
      'external_yards': 70.0,      // الساحات الخارجية
      'playground_floors': 25.0,   // أرضيات الملاعب
      'fences': 5.0,               // الأسوار
    },
    'suspended_ceilings': {
      'gypsum_partitions': 50.0,   // قواطع جبسية
      'aluminum_ceiling_strips': 50.0, // شرائح ألمونيوم أسقف مستعارة
    },
    'shades': {
      'shades': 100.0,             // المظلات
    },
    'fire_fighting': {
      'electric_pump': 25.0,       // مضخة الكهرباء
      'diesel_pump': 25.0,         // مضخة الديزل
      'jockey_pump': 10.0,         // مضخة الجوكي
      'system_electricity': 30.0,  // كهرباء النظام
      'fire_pipes': 10.0,          // مواسير الحريق
    },
    'plumbing': {
      'feeding_system': 20.0,      // نظام التغذية
      'drainage_system': 20.0,     // نظام الصرف
      'heaters': 2.0,              // السخانات
      'water_pumps': 45.0,         // مضخات المياه
      'accessories': 13.0,         // الإكسسوارات
    },
    'hvac': {
      'ac_units': 70.0,            // أجهزة التكييف
      'drainage_system': 5.0,      // نظام الصرف
      'ac_electricity': 20.0,      // كهرباء التكييف
      'exhaust_fans': 5.0,         // الشفاطات
    },
    'electrical': {
      'electrical_breakers': 25.0, // القواطع الكهربية
      'main_panels': 30.0,         // اللوحات الرئيسية
      'sub_panels': 25.0,          // اللوحات الفرعية
      'extensions': 15.0,          // التمديدات
      'lighting_system': 5.0,      // نظام الإنارة
    },
    'low_voltage': {
      'fire_alarm': 50.0,          // إنذار الحريق
      'class_bell': 5.0,           // جرس الحصص
      'emergency_exits': 5.0,      // مخارج الطوارئ
      'sound_systems': 10.0,       // أنظمة الصوت
      'surveillance_systems': 20.0, // أنظمة المراقبة
      'communication_systems': 10.0, // أنظمة الإتصالات
    },
    'elevators': {
      'elevators': 100.0,          // المصاعد
    },
  };

  static const Map<String, Map<String, String>> allCategories = {
    'foundations': {
      'foundations': 'الأساسات',
      'ground_bridges': 'الجسور الأرضية',
    },
    'structural': {
      'columns': 'الأعمدة',
      'ceilings': 'الأسقف',
      'concrete_stairs': 'السلالم الخرسانية',
    },
    'walls': {
      'internal_walls': 'الحوائط الداخلية',
      'external_walls': 'الحوائط الخارجية',
    },
    'tiles_floors': {
      'floor_tiles': 'بلاط الأرضيات',
      'stair_tiles': 'بلاط السلالم',
    },
    'woodwork': {
      'doors': 'الأبواب',
      'windows': 'الشبابيك',
      'furniture': 'الأثاث',
      'partitions': 'القواطع',
    },
    'aluminum': {
      'doors': 'الأبواب',
      'windows': 'الشبابيك',
      'kitchens': 'المطابخ',
    },
    'ironwork': {
      'doors': 'الأبواب',
      'window_protection': 'حماية الشبابيك',
      'handrails': 'الدرابزين',
      'escape_stairs': 'سلالم الهروب',
      'pump_rooms': 'غرف المضخات',
    },
    'plastering': {
      'internal_plastering': 'اللياسة الداخلية',
      'external_plastering': 'اللياسة الخارجية',
    },
    'paintings': {
      'internal_paintings': 'الدهانات الداخلية',
      'external_paintings': 'الدهانات الخارجية',
    },
    'insulation': {
      'roof_insulation': 'عزل السطح',
      'floor_insulation': 'عزل الأرضيات',
      'expansion_joints': 'فواصل التمدد',
    },
    'site_floors': {
      'external_yards': 'الساحات الخارجية',
      'playground_floors': 'أرضيات الملاعب',
      'fences': 'الأسوار',
    },
    'suspended_ceilings': {
      'gypsum_partitions': 'قواطع جبسية',
      'aluminum_ceiling_strips': 'شرائح ألمونيوم أسقف مستعارة',
    },
    'shades': {
      'shades': 'المظلات',
    },
    'fire_fighting': {
      'electric_pump': 'مضخة الكهرباء',
      'diesel_pump': 'مضخة الديزل',
      'jockey_pump': 'مضخة الجوكي',
      'system_electricity': 'كهرباء النظام',
      'fire_pipes': 'مواسير الحريق',
    },
    'plumbing': {
      'feeding_system': 'نظام التغذية',
      'drainage_system': 'نظام الصرف',
      'heaters': 'السخانات',
      'water_pumps': 'مضخات المياه',
      'accessories': 'الإكسسوارات',
    },
    'hvac': {
      'ac_units': 'أجهزة التكييف',
      'drainage_system': 'نظام الصرف',
      'ac_electricity': 'كهرباء التكييف',
      'exhaust_fans': 'الشفاطات',
    },
    'electrical': {
      'electrical_breakers': 'القواطع الكهربية',
      'main_panels': 'اللوحات الرئيسية',
      'sub_panels': 'اللوحات الفرعية',
      'extensions': 'التمديدات',
      'lighting_system': 'نظام الإنارة',
    },
    'low_voltage': {
      'fire_alarm': 'إنذار الحريق',
      'class_bell': 'جرس الحصص',
      'emergency_exits': 'مخارج الطوارئ',
      'sound_systems': 'أنظمة الصوت',
      'surveillance_systems': 'أنظمة المراقبة',
      'communication_systems': 'أنظمة الإتصالات',
    },
    'elevators': {
      'elevators': 'المصاعد',
    },
  };

  static const Map<String, String> categoryNames = {
    'foundations': 'الأساسات',
    'structural': 'الهيكل الإنشائي',
    'walls': 'الحوائط',
    'tiles_floors': 'البلاط والأرضيات',
    'woodwork': 'أعمال النجارة',
    'aluminum': 'أعمال الألمونيوم',
    'ironwork': 'أعمال الحديد',
    'plastering': 'أعمال اللياسة والمحارة',
    'paintings': 'أعمال الدهانات والديكورات',
    'insulation': 'أعمال العزل',
    'site_floors': 'أرضيات الموقع العام',
    'suspended_ceilings': 'أعمال الأسقف المستعارة',
    'shades': 'المظلات',
    'fire_fighting': 'أنظمة مكافحة الحريق',
    'plumbing': 'أنظمة السباكة والصرف الصحي',
    'hvac': 'أنظمة التكييف والتهوية والتدفئة',
    'electrical': 'أنظمة الكهرباء والطاقة',
    'low_voltage': 'أنظمة الجهد المنخفض',
    'elevators': 'أنظمة المصاعد',
  };

  static const Map<String, String> statusTranslations = {
    'جيد': 'Good',
    'مناسب': 'Suitable',
    'ضعيف': 'Weak',
    'حرج': 'Critical',
    'تالف': 'Damaged',
    'غير موجود': 'Not Available',
  };

  static const Map<String, Color> statusColors = {
    'جيد': Colors.green,
    'مناسب': Color(0xFF26A69A),
    'ضعيف': Colors.deepOrange,
    'حرج': Colors.red,
    'تالف': Color(0xFF7F0000),
    'غير موجود': Color(0xFF7F0000),
  };
} 