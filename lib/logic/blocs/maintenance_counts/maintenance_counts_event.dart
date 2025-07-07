part of 'maintenance_counts_bloc.dart';

abstract class MaintenanceCountsEvent extends Equatable {
  const MaintenanceCountsEvent();

  @override
  List<Object> get props => [];
}

class LoadSchoolsWithCounts extends MaintenanceCountsEvent {
  const LoadSchoolsWithCounts();
}

class LoadSchoolsWithDamage extends MaintenanceCountsEvent {
  const LoadSchoolsWithDamage();
}

class LoadMaintenanceCountSummary extends MaintenanceCountsEvent {
  const LoadMaintenanceCountSummary();
}

class RefreshMaintenanceCounts extends MaintenanceCountsEvent {
  const RefreshMaintenanceCounts();
}

// New damage count specific events
class LoadDamageCountDetails extends MaintenanceCountsEvent {
  final String schoolId;

  const LoadDamageCountDetails({required this.schoolId});

  @override
  List<Object> get props => [schoolId];
}

class LoadDamageCountSummary extends MaintenanceCountsEvent {
  const LoadDamageCountSummary();
}

class SaveDamageCount extends MaintenanceCountsEvent {
  final String schoolId;
  final String schoolName;
  final Map<String, int> itemCounts;

  const SaveDamageCount({
    required this.schoolId,
    required this.schoolName,
    required this.itemCounts,
  });

  @override
  List<Object> get props => [schoolId, schoolName, itemCounts];
}
