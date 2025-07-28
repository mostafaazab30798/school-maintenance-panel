import 'package:equatable/equatable.dart';

class SupervisorAttendance extends Equatable {
  final String id;
  final String supervisorId;
  final String photoUrl;
  final DateTime createdAt;
  final String? leavePhotoUrl; // New field for leave photo
  final DateTime? leaveTime; // New field for leave time

  const SupervisorAttendance({
    required this.id,
    required this.supervisorId,
    required this.photoUrl,
    required this.createdAt,
    this.leavePhotoUrl,
    this.leaveTime,
  });

  factory SupervisorAttendance.fromMap(Map<String, dynamic> map) {
    return SupervisorAttendance(
      id: map['id'] as String? ?? '',
      supervisorId: map['supervisor_id'] as String? ?? '',
      photoUrl: map['photo_url'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      leavePhotoUrl: map['leave_photo_url'] as String?,
      leaveTime: map['leave_time'] != null
          ? DateTime.parse(map['leave_time'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supervisor_id': supervisorId,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
      if (leavePhotoUrl != null) 'leave_photo_url': leavePhotoUrl,
      if (leaveTime != null) 'leave_time': leaveTime!.toIso8601String(),
    };
  }

  SupervisorAttendance copyWith({
    String? id,
    String? supervisorId,
    String? photoUrl,
    DateTime? createdAt,
    String? leavePhotoUrl,
    DateTime? leaveTime,
  }) {
    return SupervisorAttendance(
      id: id ?? this.id,
      supervisorId: supervisorId ?? this.supervisorId,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      leavePhotoUrl: leavePhotoUrl ?? this.leavePhotoUrl,
      leaveTime: leaveTime ?? this.leaveTime,
    );
  }

  @override
  List<Object?> get props => [id, supervisorId, photoUrl, createdAt, leavePhotoUrl, leaveTime];
} 