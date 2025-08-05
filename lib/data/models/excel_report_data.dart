import 'package:equatable/equatable.dart';
import 'report_form_data.dart';

class ExcelReportData extends Equatable {
  final String schoolName;
  final String description;
  final String type;
  final String priority;
  final String status;
  final bool isHvacReport;
  
  const ExcelReportData({
    required this.schoolName,
    required this.description,
    required this.type,
    required this.priority,
    required this.status,
    required this.isHvacReport,
  });
  
  @override
  List<Object?> get props => [
    schoolName,
    description,
    type,
    priority,
    status,
    isHvacReport,
  ];
  
  ReportFormData toReportFormData(String supervisorId) {
    return ReportFormData(
      supervisorId: supervisorId,
      schoolName: schoolName,
      description: description,
      type: type,
      priority: priority,
      scheduledDate: 'today', // Default to today
      imageUrls: [],
      reportSource: 'unifier',
    );
  }
  
  @override
  String toString() {
    return 'ExcelReportData(schoolName: $schoolName, description: $description, type: $type, priority: $priority, status: $status, isHvacReport: $isHvacReport)';
  }
} 