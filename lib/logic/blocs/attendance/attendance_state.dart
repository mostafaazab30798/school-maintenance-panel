import 'package:equatable/equatable.dart';
import '../../../data/models/supervisor_attendance.dart';

abstract class AttendanceState extends Equatable {
  const AttendanceState();

  @override
  List<Object?> get props => [];
}

class AttendanceInitial extends AttendanceState {}

class AttendanceLoading extends AttendanceState {}

class AttendanceLoaded extends AttendanceState {
  final List<SupervisorAttendance> attendance;

  const AttendanceLoaded({required this.attendance});

  @override
  List<Object?> get props => [attendance];
}

class AttendanceStatsLoaded extends AttendanceState {
  final Map<String, dynamic> stats;

  const AttendanceStatsLoaded({required this.stats});

  @override
  List<Object?> get props => [stats];
}

class AttendanceError extends AttendanceState {
  final String message;

  const AttendanceError({required this.message});

  @override
  List<Object?> get props => [message];
} 