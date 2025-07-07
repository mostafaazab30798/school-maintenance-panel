import 'package:equatable/equatable.dart';

abstract class ReportEvent extends Equatable {
  const ReportEvent();

  @override
  List<Object?> get props => [];
}

class FetchReports extends ReportEvent {
  final String? supervisorId;
  final String? type;
  final String? status;
  final String? priority;
  final String? schoolName;
  final bool forceRefresh;
  final int? limit;

  const FetchReports({
    this.supervisorId,
    this.type,
    this.status,
    this.priority,
    this.schoolName,
    this.forceRefresh = false,
    this.limit,
  });

  @override
  List<Object?> get props =>
      [supervisorId, type, status, priority, schoolName, forceRefresh, limit];
}
