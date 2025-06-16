import 'package:equatable/equatable.dart';

class Admin extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? authUserId;
  final String role;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Admin({
    required this.id,
    required this.name,
    required this.email,
    this.authUserId,
    this.role = 'admin',
    required this.createdAt,
    this.updatedAt,
  });

  factory Admin.fromMap(Map<String, dynamic> map) {
    return Admin(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      authUserId: map['auth_user_id'] as String?,
      role: map['role'] as String? ?? 'admin',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (authUserId != null) 'auth_user_id': authUserId,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  @override
  List<Object?> get props =>
      [id, name, email, authUserId, role, createdAt, updatedAt];
}
