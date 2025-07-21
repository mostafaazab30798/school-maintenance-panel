import 'package:equatable/equatable.dart';

class CarMaintenance extends Equatable {
  final String id;
  final String supervisorId;
  final int? maintenanceMeter;
  final DateTime? maintenanceMeterDate;
  final List<TyreChange> tyreChanges;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CarMaintenance({
    required this.id,
    required this.supervisorId,
    this.maintenanceMeter,
    this.maintenanceMeterDate,
    this.tyreChanges = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory CarMaintenance.fromMap(Map<String, dynamic> map) {
    return CarMaintenance(
      id: map['id']?.toString() ?? '',
      supervisorId: map['supervisor_id']?.toString() ?? '',
      maintenanceMeter: map['maintenance_meter'] as int?,
      maintenanceMeterDate: map['maintenance_meter_date'] != null
          ? DateTime.parse(map['maintenance_meter_date'].toString())
          : null,
      tyreChanges: _parseTyreChanges(map['tyre_changes']),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : DateTime.now(),
    );
  }

  static List<TyreChange> _parseTyreChanges(dynamic tyreChangesData) {
    if (tyreChangesData == null) return [];
    
    if (tyreChangesData is List) {
      return tyreChangesData
          .map((item) => TyreChange.fromMap(item))
          .toList();
    }
    
    return [];
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supervisor_id': supervisorId,
      'maintenance_meter': maintenanceMeter,
      'maintenance_meter_date': maintenanceMeterDate?.toIso8601String(),
      'tyre_changes': tyreChanges.map((change) => change.toMap()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CarMaintenance copyWith({
    String? id,
    String? supervisorId,
    int? maintenanceMeter,
    DateTime? maintenanceMeterDate,
    List<TyreChange>? tyreChanges,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CarMaintenance(
      id: id ?? this.id,
      supervisorId: supervisorId ?? this.supervisorId,
      maintenanceMeter: maintenanceMeter ?? this.maintenanceMeter,
      maintenanceMeterDate: maintenanceMeterDate ?? this.maintenanceMeterDate,
      tyreChanges: tyreChanges ?? this.tyreChanges,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        supervisorId,
        maintenanceMeter,
        maintenanceMeterDate,
        tyreChanges,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'CarMaintenance(id: $id, supervisorId: $supervisorId, maintenanceMeter: $maintenanceMeter, tyreChanges: ${tyreChanges.length})';
  }
}

class TyreChange extends Equatable {
  final DateTime changeDate;
  final String tyrePosition;

  const TyreChange({
    required this.changeDate,
    required this.tyrePosition,
  });

  factory TyreChange.fromMap(Map<String, dynamic> map) {
    return TyreChange(
      changeDate: map['change_date'] != null
          ? DateTime.parse(map['change_date'].toString())
          : DateTime.now(),
      tyrePosition: map['tyre_position']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'change_date': changeDate.toIso8601String(),
      'tyre_position': tyrePosition,
    };
  }

  TyreChange copyWith({
    DateTime? changeDate,
    String? tyrePosition,
  }) {
    return TyreChange(
      changeDate: changeDate ?? this.changeDate,
      tyrePosition: tyrePosition ?? this.tyrePosition,
    );
  }

  @override
  List<Object?> get props => [changeDate, tyrePosition];

  @override
  String toString() {
    return 'TyreChange(changeDate: $changeDate, tyrePosition: $tyrePosition)';
  }
}

// Constants for tyre positions
class TyrePositions {
  static const String frontLeft = 'front_left';
  static const String frontRight = 'front_right';
  static const String rearLeft = 'rear_left';
  static const String rearRight = 'rear_right';
  static const String spare = 'spare';

  static const Map<String, String> arabicLabels = {
    frontLeft: 'أمامي يسار',
    frontRight: 'أمامي يمين',
    rearLeft: 'خلفي يسار',
    rearRight: 'خلفي يمين',
    spare: 'احتياطي',
  };

  static String getArabicLabel(String position) {
    return arabicLabels[position] ?? position;
  }
} 