import 'package:equatable/equatable.dart';
import '../../../data/models/maintenance_report.dart';

abstract class MaintenanceViewState extends Equatable {
  const MaintenanceViewState();

  @override
  List<Object?> get props => [];
}

class MaintenanceViewInitial extends MaintenanceViewState {}

class MaintenanceViewLoading extends MaintenanceViewState {}

class MaintenanceViewLoaded extends MaintenanceViewState {
  final List<MaintenanceReport> maintenanceReports;

  const MaintenanceViewLoaded(this.maintenanceReports);

  @override
  List<Object?> get props => [maintenanceReports];
}

class MaintenanceViewError extends MaintenanceViewState {
  final String message;

  const MaintenanceViewError(this.message);

  @override
  List<Object?> get props => [message];
}
