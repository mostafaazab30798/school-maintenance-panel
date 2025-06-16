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
  final bool forceRefresh;
  final int? limit;

  const FetchReports({
    this.supervisorId,
    this.type,
    this.status,
    this.priority,
    this.forceRefresh = false,
    this.limit = 100,
  });

  @override
  List<Object?> get props =>
      [supervisorId, type, status, priority, forceRefresh, limit];
}
