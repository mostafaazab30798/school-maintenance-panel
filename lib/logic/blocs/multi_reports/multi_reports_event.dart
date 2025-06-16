import 'package:equatable/equatable.dart';

import '../../../data/models/report_form_data.dart';

abstract class MultipleReportEvent extends Equatable {
  const MultipleReportEvent();

  @override
  List<Object?> get props => [];
}

class SubmitMultipleReports extends MultipleReportEvent {
  final List<ReportFormData> reports;

  const SubmitMultipleReports(this.reports);

  @override
  List<Object?> get props => [reports];
}
