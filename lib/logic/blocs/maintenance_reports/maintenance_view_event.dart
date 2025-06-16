import 'package:equatable/equatable.dart';

abstract class MaintenanceViewEvent extends Equatable {
  const MaintenanceViewEvent();

  @override
  List<Object?> get props => [];
}

class FetchMaintenanceReports extends MaintenanceViewEvent {
  final String? supervisorId;
  final String? status;
  final bool forceRefresh;

  const FetchMaintenanceReports({
    this.supervisorId,
    this.status,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [supervisorId, status, forceRefresh];
}
