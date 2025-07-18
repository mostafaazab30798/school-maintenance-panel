import 'package:equatable/equatable.dart';

class SupervisorAttendance extends Equatable {
  final String id;
  final String supervisorId;
  final String photoUrl;
  final DateTime createdAt;

  const SupervisorAttendance({
    required this.id,
    required this.supervisorId,
    required this.photoUrl,
    required this.createdAt,
  });

  factory SupervisorAttendance.fromMap(Map<String, dynamic> map) {
    return SupervisorAttendance(
      id: map['id'] as String? ?? '',
      supervisorId: map['supervisor_id'] as String? ?? '',
      photoUrl: map['photo_url'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supervisor_id': supervisorId,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  SupervisorAttendance copyWith({
    String? id,
    String? supervisorId,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return SupervisorAttendance(
      id: id ?? this.id,
      supervisorId: supervisorId ?? this.supervisorId,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, supervisorId, photoUrl, createdAt];
} 