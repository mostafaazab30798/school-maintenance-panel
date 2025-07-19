import 'package:equatable/equatable.dart';
import '../../../data/models/supervisor.dart';

abstract class SupervisorState extends Equatable {
  const SupervisorState();

  @override
  List<Object?> get props => [];
}

class SupervisorInitial extends SupervisorState {}

class SupervisorLoading extends SupervisorState {}

class SupervisorLoaded extends SupervisorState {
  final List<Supervisor> supervisors;

  const SupervisorLoaded(this.supervisors);

  @override
  List<Object?> get props => [supervisors];
}

class SupervisorDetailLoaded extends SupervisorState {
  final Supervisor supervisor;

  const SupervisorDetailLoaded(this.supervisor);

  @override
  List<Object?> get props => [supervisor];
}

class SupervisorError extends SupervisorState {
  final String message;

  const SupervisorError(this.message);

  @override
  List<Object?> get props => [message];
}

class SupervisorTechnicianUpdating extends SupervisorState {
  final String supervisorId;
  final String operation; // 'add', 'remove', 'update'

  const SupervisorTechnicianUpdating({
    required this.supervisorId,
    required this.operation,
  });

  @override
  List<Object?> get props => [supervisorId, operation];
}

class SupervisorUpdating extends SupervisorState {
  final String supervisorId;

  const SupervisorUpdating({required this.supervisorId});

  @override
  List<Object?> get props => [supervisorId];
}

class SupervisorSchoolRemoving extends SupervisorState {
  final String supervisorId;
  final String schoolId;

  const SupervisorSchoolRemoving({
    required this.supervisorId,
    required this.schoolId,
  });

  @override
  List<Object?> get props => [supervisorId, schoolId];
}

class SupervisorSchoolsRemoving extends SupervisorState {
  final String supervisorId;
  final List<String> schoolIds;

  const SupervisorSchoolsRemoving({
    required this.supervisorId,
    required this.schoolIds,
  });

  @override
  List<Object?> get props => [supervisorId, schoolIds];
}
