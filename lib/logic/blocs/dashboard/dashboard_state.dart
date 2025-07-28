import 'package:equatable/equatable.dart';
import '../../../data/models/report.dart';
import '../../../data/models/supervisor.dart';
import '../../../data/models/maintenance_report.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final int totalReports;
  final int emergencyReports;
  final int completedReports;
  final int overdueReports;
  final int lateCompletedReports;
  final int totalSupervisors;
  final double completionRate;
  final List<Report> reports;
  final List<Supervisor> supervisors;
  final int routineReports;
  final int pendingReports;

  // Maintenance reports statistics
  final int totalMaintenanceReports;
  final int completedMaintenanceReports;
  final int pendingMaintenanceReports;
  final List<MaintenanceReport> maintenanceReports;

  // Inventory count statistics
  final int schoolsWithCounts;
  final int schoolsWithDamage;

  // Schools statistics
  final int totalSchools;
  final int schoolsWithAchievements;

  // FCI Assessment statistics
  final int totalFciAssessments;
  final int submittedFciAssessments;
  final int draftFciAssessments;
  final int schoolsWithFciAssessments;

  const DashboardLoaded({
    required this.totalReports,
    required this.emergencyReports,
    required this.completedReports,
    required this.overdueReports,
    required this.lateCompletedReports,
    required this.totalSupervisors,
    required this.completionRate,
    required this.reports,
    required this.supervisors,
    required this.routineReports,
    required this.pendingReports,
    required this.totalMaintenanceReports,
    required this.completedMaintenanceReports,
    required this.pendingMaintenanceReports,
    required this.maintenanceReports,
    required this.schoolsWithCounts,
    required this.schoolsWithDamage,
    required this.totalSchools,
    required this.schoolsWithAchievements,
    required this.totalFciAssessments,
    required this.submittedFciAssessments,
    required this.draftFciAssessments,
    required this.schoolsWithFciAssessments,
  });

  @override
  List<Object?> get props => [
        totalReports,
        emergencyReports,
        completedReports,
        overdueReports,
        lateCompletedReports,
        totalSupervisors,
        completionRate,
        reports,
        supervisors,
        routineReports,
        pendingReports,
        totalMaintenanceReports,
        completedMaintenanceReports,
        pendingMaintenanceReports,
        maintenanceReports,
        schoolsWithCounts,
        schoolsWithDamage,
        totalSchools,
        schoolsWithAchievements,
        totalFciAssessments,
        submittedFciAssessments,
        draftFciAssessments,
        schoolsWithFciAssessments,
      ];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
