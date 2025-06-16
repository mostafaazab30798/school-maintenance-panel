import 'package:equatable/equatable.dart';

abstract class MaintenanceReportEvent extends Equatable {
  const MaintenanceReportEvent();

  @override
  List<Object> get props => [];
}

class SubmitMaintenanceReport extends MaintenanceReportEvent {
  final String supervisorId;
  final String schoolName;
  final String notes;
  final String scheduledDate;
  final List<String> imageUrls;

  const SubmitMaintenanceReport({
    required this.supervisorId,
    required this.schoolName,
    required this.notes,
    required this.scheduledDate,
    required this.imageUrls,
  });

  @override
  List<Object> get props =>
      [supervisorId, schoolName, notes, scheduledDate, imageUrls];
}
