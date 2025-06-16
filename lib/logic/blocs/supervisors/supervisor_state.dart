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