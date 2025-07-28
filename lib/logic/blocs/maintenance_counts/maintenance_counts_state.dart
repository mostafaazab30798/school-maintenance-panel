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
  final Map<String, String> supervisorNames; // Map supervisor ID to name

  const MaintenanceCountRecordsLoaded({
    required this.records,
    this.supervisorNames = const {},
  });

  @override
  List<Object> get props => [records, supervisorNames];
}

class DamageCountRecordsLoaded extends MaintenanceCountsState {
  final List<DamageCount> records;
  final Map<String, String> supervisorNames; // Map supervisor ID to name

  const DamageCountRecordsLoaded({
    required this.records,
    this.supervisorNames = const {},
  });

  @override
  List<Object> get props => [records, supervisorNames];
}

class SchoolsWithCountsLoaded extends MaintenanceCountsState {
  final List<Map<String, dynamic>> schools;

  const SchoolsWithCountsLoaded({required this.schools});

  @override
  List<Object> get props => [schools];
}

class SchoolsWithDamageLoaded extends MaintenanceCountsState {
  final List<Map<String, dynamic>> schools;
  final Map<String, String> supervisorNames; // Map supervisor ID to name

  const SchoolsWithDamageLoaded({
    required this.schools,
    this.supervisorNames = const {},
  });

  @override
  List<Object> get props => [schools, supervisorNames];
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
  final String? supervisorName;

  const DamageCountDetailsLoaded({
    required this.damageCount,
    this.supervisorName,
  });

  @override
  List<Object> get props => [damageCount, supervisorName ?? ''];
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
