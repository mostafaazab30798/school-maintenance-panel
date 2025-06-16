import 'package:admin_panel/data/models/report_form_data.dart';

class AddMultipleReportsState {
  final List<ReportFormData> reports;
  final bool isSubmitting;
  final bool validationFailed;

  AddMultipleReportsState({
    required this.reports,
    required this.isSubmitting,
    this.validationFailed = false,
  });

  factory AddMultipleReportsState.initial(String supervisorId) {
    return AddMultipleReportsState(
      reports: [ReportFormData(supervisorId: supervisorId)],
      isSubmitting: false,
      validationFailed: false,
    );
  }

  AddMultipleReportsState copyWith({
    List<ReportFormData>? reports,
    bool? isSubmitting,
    bool? validationFailed,
  }) {
    return AddMultipleReportsState(
      reports: reports ?? this.reports,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      validationFailed: validationFailed ?? this.validationFailed,
    );
  }
}
