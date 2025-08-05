import 'package:admin_panel/data/models/report_form_data.dart';
import 'package:admin_panel/data/models/excel_report_data.dart';
import 'package:equatable/equatable.dart';

class AddMultipleReportsState extends Equatable {
  final List<ReportFormData> reports;
  final bool isSubmitting;
  final bool validationFailed;
  
  // Excel functionality
  final bool isExcelMode;
  final Map<String, List<ExcelReportData>> excelReportsBySchool;
  final String? selectedSchoolForExcel;
  final String? selectedExcelSchoolName;
  final bool isLoadingExcel;
  final String? excelErrorMessage;
  
  // Supervisor selection functionality
  final String? selectedSupervisorId;
  final bool showSupervisorSelection;

  AddMultipleReportsState({
    required this.reports,
    required this.isSubmitting,
    this.validationFailed = false,
    this.isExcelMode = false,
    this.excelReportsBySchool = const {},
    this.selectedSchoolForExcel,
    this.selectedExcelSchoolName,
    this.isLoadingExcel = false,
    this.excelErrorMessage,
    this.selectedSupervisorId,
    this.showSupervisorSelection = false,
  });

  @override
  List<Object?> get props => [
    reports, 
    isSubmitting, 
    validationFailed,
    isExcelMode,
    excelReportsBySchool,
    selectedSchoolForExcel,
    selectedExcelSchoolName,
    isLoadingExcel,
    excelErrorMessage,
    selectedSupervisorId,
    showSupervisorSelection,
  ];

  factory AddMultipleReportsState.initial(String supervisorId, {bool initialExcelMode = false}) {
    return AddMultipleReportsState(
      reports: initialExcelMode ? [] : [ReportFormData(supervisorId: supervisorId)],
      isSubmitting: false,
      validationFailed: false,
      isExcelMode: initialExcelMode,
      excelReportsBySchool: const {},
      selectedSchoolForExcel: null,
      selectedExcelSchoolName: null,
      isLoadingExcel: false,
      excelErrorMessage: null,
      selectedSupervisorId: supervisorId,
      showSupervisorSelection: false,
    );
  }

  AddMultipleReportsState copyWith({
    List<ReportFormData>? reports,
    bool? isSubmitting,
    bool? validationFailed,
    bool? isExcelMode,
    Map<String, List<ExcelReportData>>? excelReportsBySchool,
    String? selectedSchoolForExcel,
    String? selectedExcelSchoolName,
    bool? isLoadingExcel,
    String? excelErrorMessage,
    String? selectedSupervisorId,
    bool? showSupervisorSelection,
  }) {
    return AddMultipleReportsState(
      reports: reports ?? this.reports,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      validationFailed: validationFailed ?? this.validationFailed,
      isExcelMode: isExcelMode ?? this.isExcelMode,
      excelReportsBySchool: excelReportsBySchool ?? this.excelReportsBySchool,
      selectedSchoolForExcel: selectedSchoolForExcel ?? this.selectedSchoolForExcel,
      selectedExcelSchoolName: selectedExcelSchoolName ?? this.selectedExcelSchoolName,
      isLoadingExcel: isLoadingExcel ?? this.isLoadingExcel,
      excelErrorMessage: excelErrorMessage ?? this.excelErrorMessage,
      selectedSupervisorId: selectedSupervisorId ?? this.selectedSupervisorId,
      showSupervisorSelection: showSupervisorSelection ?? this.showSupervisorSelection,
    );
  }
}
