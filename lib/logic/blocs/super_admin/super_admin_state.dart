import '../../../data/models/admin.dart';

abstract class SuperAdminState {}

class SuperAdminInitial extends SuperAdminState {}

class SuperAdminLoading extends SuperAdminState {}

class SuperAdminPartiallyLoaded extends SuperAdminState {
  final List<Admin> admins;
  final List<Map<String, dynamic>> allSupervisors;

  SuperAdminPartiallyLoaded({
    required this.admins,
    required this.allSupervisors,
  });
}

class SuperAdminLoaded extends SuperAdminState {
  final List<Admin> admins;
  final List<Map<String, dynamic>> allSupervisors;
  final Map<String, Map<String, dynamic>> adminStats;
  final List<Map<String, dynamic>> supervisorsWithStats;
  final Map<String, int> reportTypesStats;
  final Map<String, int> reportSourcesStats;
  final Map<String, int> maintenanceStatusStats;
  final Map<String, int> adminReportsDistribution;
  final Map<String, int> adminMaintenanceDistribution;
  final Map<String, Map<String, dynamic>> reportTypesCompletionRates;
  final Map<String, Map<String, dynamic>> reportSourcesCompletionRates;

  SuperAdminLoaded({
    required this.admins,
    required this.allSupervisors,
    required this.adminStats,
    required this.supervisorsWithStats,
    required this.reportTypesStats,
    required this.reportSourcesStats,
    required this.maintenanceStatusStats,
    required this.adminReportsDistribution,
    required this.adminMaintenanceDistribution,
    required this.reportTypesCompletionRates,
    required this.reportSourcesCompletionRates,
  });
}

class SuperAdminError extends SuperAdminState {
  final String message;
  SuperAdminError(this.message);
}
