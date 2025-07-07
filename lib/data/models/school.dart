import 'package:equatable/equatable.dart';

class School extends Equatable {
  final String id;
  final String name;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;

  const School({
    required this.id,
    required this.name,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  factory School.fromMap(Map<String, dynamic> map) {
    return School(
      id: map['id'] as String,
      name: map['name'] as String,
      address: map['address'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  School copyWith({
    String? id,
    String? name,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return School(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, address, createdAt, updatedAt];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is School &&
        other.id == id &&
        other.name == name &&
        other.address == address &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        address.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  @override
  String toString() {
    return 'School(id: $id, name: $name, address: $address, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
