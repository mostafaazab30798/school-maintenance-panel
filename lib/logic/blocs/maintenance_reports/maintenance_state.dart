import 'package:equatable/equatable.dart';

abstract class MaintenanceReportState extends Equatable {
  const MaintenanceReportState();

  @override
  List<Object?> get props => [];
}

class MaintenanceReportInitial extends MaintenanceReportState {}

class MaintenanceReportLoading extends MaintenanceReportState {}

class MaintenanceReportSuccess extends MaintenanceReportState {}

class MaintenanceReportFailure extends MaintenanceReportState {
  final String error;

  const MaintenanceReportFailure(this.error);

  @override
  List<Object?> get props => [error];
}
