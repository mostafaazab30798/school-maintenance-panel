part of 'maintenance_counts_bloc.dart';

abstract class MaintenanceCountsState extends Equatable {
  const MaintenanceCountsState();

  @override
  List<Object> get props => [];
}

class MaintenanceCountsInitial extends MaintenanceCountsState {}

class MaintenanceCountsLoading extends MaintenanceCountsState {}

class MaintenanceCountsError extends MaintenanceCountsState {
  final String message;

  const MaintenanceCountsError(this.message);

  @override
  List<Object> get props => [message];
}

class MaintenanceCountRecordsLoaded extends MaintenanceCountsState {
  final List<MaintenanceCount> records;

  const MaintenanceCountRecordsLoaded({required this.records});

  @override
  List<Object> get props => [records];
}

class DamageCountRecordsLoaded extends MaintenanceCountsState {
  final List<DamageCount> records;

  const DamageCountRecordsLoaded({required this.records});

  @override
  List<Object> get props => [records];
}

class SchoolsWithCountsLoaded extends MaintenanceCountsState {
  final List<Map<String, dynamic>> schools;

  const SchoolsWithCountsLoaded({required this.schools});

  @override
  List<Object> get props => [schools];
}

class SchoolsWithDamageLoaded extends MaintenanceCountsState {
  final List<Map<String, dynamic>> schools;

  const SchoolsWithDamageLoaded({required this.schools});

  @override
  List<Object> get props => [schools];
}

class MaintenanceCountSummaryLoaded extends MaintenanceCountsState {
  final Map<String, int> summary;

  const MaintenanceCountSummaryLoaded({required this.summary});

  @override
  List<Object> get props => [summary];
}

// New damage count specific states
class DamageCountDetailsLoaded extends MaintenanceCountsState {
  final DamageCount damageCount;

  const DamageCountDetailsLoaded({required this.damageCount});

  @override
  List<Object> get props => [damageCount];
}

class DamageCountSummaryLoaded extends MaintenanceCountsState {
  final Map<String, int> summary;

  const DamageCountSummaryLoaded({required this.summary});

  @override
  List<Object> get props => [summary];
}

class DamageCountSaved extends MaintenanceCountsState {
  final DamageCount damageCount;

  const DamageCountSaved({required this.damageCount});

  @override
  List<Object> get props => [damageCount];
}
