import 'package:flutter_bloc/flutter_bloc.dart';
import 'multi_reports_event.dart';
import 'multi_reports_state.dart';
import '../../../data/repositories/multi_reports_repository.dart';

class MultipleReportBloc
    extends Bloc<MultipleReportEvent, MultipleReportState> {
  final MultiReportRepository reportRepository;

  MultipleReportBloc(this.reportRepository) : super(MultipleReportInitial()) {
    on<SubmitMultipleReports>(_onSubmitMultipleReports);
  }

  Future<void> _onSubmitMultipleReports(
    SubmitMultipleReports event,
    Emitter<MultipleReportState> emit,
  ) async {
    print('MultipleReportBloc: Received ${event.reports.length} reports to submit');
    emit(MultipleReportsSubmitting());
    try {
      print('MultipleReportBloc: Submitting reports to repository');
      await reportRepository.submitReports(event.reports);
      print('MultipleReportBloc: Reports submitted successfully');
      emit(MultipleReportsSuccess());
    } catch (e, stack) {
      print('MultipleReportBloc: Error submitting reports: $e');
      print(stack);
      emit(MultipleReportsFailure(e.toString()));
    }
  }
}
