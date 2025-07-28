import 'package:equatable/equatable.dart';
import '../../../data/models/supervisor_attendance.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

class LoadAttendanceForSupervisor extends AttendanceEvent {
  final String supervisorId;

  const LoadAttendanceForSupervisor({required this.supervisorId});

  @override
  List<Object?> get props => [supervisorId];
}

class LoadAllAttendance extends AttendanceEvent {
  const LoadAllAttendance();
}

class CreateAttendance extends AttendanceEvent {
  final SupervisorAttendance attendance;

  const CreateAttendance({required this.attendance});

  @override
  List<Object?> get props => [attendance];
}

class UpdateAttendance extends AttendanceEvent {
  final String id;
  final Map<String, dynamic> updates;
  final String supervisorId;

  const UpdateAttendance({
    required this.id,
    required this.updates,
    required this.supervisorId,
  });

  @override
  List<Object?> get props => [id, updates, supervisorId];
}

class DeleteAttendance extends AttendanceEvent {
  final String id;
  final String supervisorId;

  const DeleteAttendance({
    required this.id,
    required this.supervisorId,
  });

  @override
  List<Object?> get props => [id, supervisorId];
}

class LoadAttendanceStats extends AttendanceEvent {
  final String supervisorId;

  const LoadAttendanceStats({required this.supervisorId});

  @override
  List<Object?> get props => [supervisorId];
}

class UpdateLeaveInfo extends AttendanceEvent {
  final String attendanceId;
  final String supervisorId;
  final String? leavePhotoUrl;
  final DateTime? leaveTime;

  const UpdateLeaveInfo({
    required this.attendanceId,
    required this.supervisorId,
    this.leavePhotoUrl,
    this.leaveTime,
  });

  @override
  List<Object?> get props => [attendanceId, supervisorId, leavePhotoUrl, leaveTime];
}

class CreateAttendanceWithLeave extends AttendanceEvent {
  final SupervisorAttendance attendance;
  final String? leavePhotoUrl;
  final DateTime? leaveTime;

  const CreateAttendanceWithLeave({
    required this.attendance,
    this.leavePhotoUrl,
    this.leaveTime,
  });

  @override
  List<Object?> get props => [attendance, leavePhotoUrl, leaveTime];
} 