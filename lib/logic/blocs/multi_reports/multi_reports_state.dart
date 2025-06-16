import 'package:equatable/equatable.dart';

abstract class MultipleReportState extends Equatable {
  const MultipleReportState();

  @override
  List<Object?> get props => [];
}

class MultipleReportInitial extends MultipleReportState {}

class MultipleReportsSubmitting extends MultipleReportState {}

class MultipleReportsSuccess extends MultipleReportState {}

class MultipleReportsFailure extends MultipleReportState {
  final String error;

  const MultipleReportsFailure(this.error);

  @override
  List<Object?> get props => [error];
}
