import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/supervisor_attendance_repository.dart';
import '../../../data/models/supervisor_attendance.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final SupervisorAttendanceRepository _attendanceRepository;

  AttendanceBloc(this._attendanceRepository) : super(AttendanceInitial()) {
    on<LoadAttendanceForSupervisor>(_onLoadAttendanceForSupervisor);
    on<LoadAllAttendance>(_onLoadAllAttendance);
    on<CreateAttendance>(_onCreateAttendance);
    on<UpdateAttendance>(_onUpdateAttendance);
    on<DeleteAttendance>(_onDeleteAttendance);
    on<LoadAttendanceStats>(_onLoadAttendanceStats);
  }

  Future<void> _onLoadAttendanceForSupervisor(
    LoadAttendanceForSupervisor event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());
    try {
      final attendance = await _attendanceRepository.fetchAttendanceForSupervisor(event.supervisorId);
      emit(AttendanceLoaded(attendance: attendance));
    } catch (e) {
      emit(AttendanceError(message: e.toString()));
    }
  }

  Future<void> _onLoadAllAttendance(
    LoadAllAttendance event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());
    try {
      final attendance = await _attendanceRepository.fetchAllAttendance();
      emit(AttendanceLoaded(attendance: attendance));
    } catch (e) {
      emit(AttendanceError(message: e.toString()));
    }
  }

  Future<void> _onCreateAttendance(
    CreateAttendance event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      await _attendanceRepository.createAttendance(event.attendance);
      add(LoadAttendanceForSupervisor(supervisorId: event.attendance.supervisorId));
    } catch (e) {
      emit(AttendanceError(message: e.toString()));
    }
  }

  Future<void> _onUpdateAttendance(
    UpdateAttendance event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      await _attendanceRepository.updateAttendance(event.id, event.updates);
      add(LoadAttendanceForSupervisor(supervisorId: event.supervisorId));
    } catch (e) {
      emit(AttendanceError(message: e.toString()));
    }
  }

  Future<void> _onDeleteAttendance(
    DeleteAttendance event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      await _attendanceRepository.deleteAttendance(event.id);
      add(LoadAttendanceForSupervisor(supervisorId: event.supervisorId));
    } catch (e) {
      emit(AttendanceError(message: e.toString()));
    }
  }

  Future<void> _onLoadAttendanceStats(
    LoadAttendanceStats event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      final stats = await _attendanceRepository.getAttendanceStats(event.supervisorId);
      emit(AttendanceStatsLoaded(stats: stats));
    } catch (e) {
      emit(AttendanceError(message: e.toString()));
    }
  }
} 