import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/report_form_data.dart';
import '../../data/models/excel_report_data.dart';
import 'add_multiple_reports_state.dart';
import '../../core/services/supabase_storage_service.dart';
import '../../core/services/excel_report_service.dart';
import '../../core/services/excel_data_service.dart';

class AddMultipleReportsCubit extends Cubit<AddMultipleReportsState> {
  final SupabaseStorageService _storageService;
  final ExcelReportService _excelService;
  
  AddMultipleReportsCubit(String supervisorId, {required SupabaseStorageService storageService, bool initialExcelMode = false})
      : _storageService = storageService,
        _excelService = ExcelReportService(),
        super(AddMultipleReportsState.initial(supervisorId, initialExcelMode: initialExcelMode)) {
    
    // Validate supervisorId
    if (supervisorId.isEmpty || supervisorId.trim().isEmpty) {
      print('🏫 ERROR: Invalid supervisor ID provided to AddMultipleReportsCubit: "$supervisorId"');
    }
    
    // Load Excel data if in Excel mode
    if (initialExcelMode) {
      _loadExcelDataFromService();
    }
  }

  void addReport(String supervisorId) {
    // Validate supervisorId
    if (supervisorId.isEmpty || supervisorId.trim().isEmpty) {
      print('🏫 ERROR: Invalid supervisor ID provided to addReport: "$supervisorId"');
      return;
    }
    
    final newReports = List<ReportFormData>.from(state.reports)
      ..add(ReportFormData(supervisorId: supervisorId));
    emit(state.copyWith(reports: newReports));
  }

  void removeReport(int index) {
    final updatedReports = List<ReportFormData>.from(state.reports)
      ..removeAt(index);
    emit(state.copyWith(reports: updatedReports));
  }

  void updateSchoolName(int index, String value) {
    print('🏫 Cubit: updateSchoolName called with index: $index, value: $value');
    final updated = List<ReportFormData>.from(state.reports);
    updated[index].schoolName = value;
    print('🏫 Cubit: Updated school name to: ${updated[index].schoolName}');
    emit(state.copyWith(reports: updated));
  }

  void updateDescription(int index, String value) {
    final updated = List<ReportFormData>.from(state.reports);
    updated[index].description = value;
    emit(state.copyWith(reports: updated));
  }

  void updateType(int index, String value) {
    final updated = List<ReportFormData>.from(state.reports);
    updated[index].type = value;
    emit(state.copyWith(reports: updated));
  }

  void updatePriority(int index, String value) {
    final updated = List<ReportFormData>.from(state.reports);
    updated[index].priority = value;
    emit(state.copyWith(reports: updated));
  }

  void updateSchedule(int index, String value) {
    final updated = List<ReportFormData>.from(state.reports);
    updated[index].scheduledDate = value;
    emit(state.copyWith(reports: updated));
  }

  void updateReportSource(int index, String value) {
    final updated = List<ReportFormData>.from(state.reports);
    updated[index].reportSource = value;
    emit(state.copyWith(reports: updated));
  }

  void updateImages(int index, List<String> urls) {
    final updatedReports = List<ReportFormData>.from(state.reports);

    final old = updatedReports[index];
    updatedReports[index] = old.copyWith(imageUrls: urls);

    emit(state.copyWith(reports: updatedReports));
  }

  // Excel functionality methods
  void toggleExcelMode(bool enabled) {
    emit(state.copyWith(
      isExcelMode: enabled,
      reports: enabled ? [] : state.reports,
      selectedSchoolForExcel: enabled ? null : state.selectedSchoolForExcel,
      excelErrorMessage: null,
    ));
  }

  Future<void> loadReportsFromExcel(String schoolName) async {
    emit(state.copyWith(isLoadingExcel: true, excelErrorMessage: null));
    
    try {
      final excelReports = state.excelReportsBySchool[schoolName] ?? [];
      if (excelReports.isEmpty) {
        emit(state.copyWith(
          isLoadingExcel: false,
          excelErrorMessage: 'لا توجد بلاغات لهذه المدرسة في ملف الإكسل',
        ));
        return;
      }
      
      final reportFormDataList = excelReports
          .map((excelReport) => excelReport.toReportFormData(state.reports.first.supervisorId ?? ''))
          .toList();
      
      emit(state.copyWith(
        reports: reportFormDataList,
        selectedSchoolForExcel: schoolName,
        isLoadingExcel: false,
        excelErrorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingExcel: false,
        excelErrorMessage: 'خطأ في تحميل البلاغات: $e',
      ));
    }
  }

  void setExcelReports(Map<String, List<ExcelReportData>> reportsBySchool) {
    emit(state.copyWith(
      excelReportsBySchool: reportsBySchool,
      excelErrorMessage: null,
    ));
  }

  void updateSelectedExcelSchoolName(String? schoolName) {
    emit(state.copyWith(
      selectedExcelSchoolName: schoolName,
      excelErrorMessage: null,
    ));
  }

  Future<void> loadExcelReports(String supervisorId, String schoolName) async {
    emit(state.copyWith(isLoadingExcel: true, excelErrorMessage: null));
    
    try {
      final excelReports = state.excelReportsBySchool[schoolName] ?? [];
      if (excelReports.isEmpty) {
        emit(state.copyWith(
          isLoadingExcel: false,
          excelErrorMessage: 'لا توجد بلاغات لهذه المدرسة في ملف الإكسل',
        ));
        return;
      }
      
      final reportFormDataList = excelReports
          .map((excelReport) => excelReport.toReportFormData(supervisorId))
          .toList();
      
      emit(state.copyWith(
        reports: reportFormDataList,
        selectedSchoolForExcel: schoolName,
        isLoadingExcel: false,
        excelErrorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingExcel: false,
        excelErrorMessage: 'خطأ في تحميل البلاغات: $e',
      ));
    }
  }

  void clearExcelReports() {
    emit(state.copyWith(
      excelReportsBySchool: const {},
      selectedSchoolForExcel: null,
      reports: [],
      excelErrorMessage: null,
    ));
  }

  List<String> getAvailableSchools() {
    return state.excelReportsBySchool.keys.toList()..sort();
  }

  bool validateReports() {
    // Check if there are any reports to validate
    if (state.reports.isEmpty) {
      return false;
    }

    // If in Excel mode, validate supervisor selection
    if (state.isExcelMode && (state.selectedSupervisorId == null || state.selectedSupervisorId!.isEmpty)) {
      return false;
    }

    // Check each report for required fields
    for (int i = 0; i < state.reports.length; i++) {
      final report = state.reports[i];
      if (report.schoolName == null ||
          report.schoolName!.isEmpty ||
          report.description == null ||
          report.description!.isEmpty ||
          report.type == null ||
          report.type!.isEmpty ||
          report.priority == null ||
          report.priority!.isEmpty ||
          report.scheduledDate == null ||
          report.scheduledDate!.isEmpty) {
        return false;
      }
    }

    return true;
  }

  // Returns a map of field validation errors for a specific report
  Map<String, String> getReportValidationErrors(int index) {
    final report = state.reports[index];
    final Map<String, String> errors = {};

    if (report.schoolName == null || report.schoolName!.isEmpty) {
      errors['schoolName'] = 'اسم المدرسة مطلوب';
    }

    if (report.description == null || report.description!.isEmpty) {
      errors['description'] = 'الوصف مطلوب';
    }

    if (report.type == null || report.type!.isEmpty) {
      errors['type'] = 'نوع البلاغ مطلوب';
    }

    if (report.priority == null || report.priority!.isEmpty) {
      errors['priority'] = 'الأولوية مطلوبة';
    }

    if (report.scheduledDate == null || report.scheduledDate!.isEmpty) {
      errors['scheduledDate'] = 'تاريخ الجدولة مطلوب';
    }

    return errors;
  }

  void submitReports(void Function(List<ReportFormData>) onSubmit) async {
    // Validate all reports before submission
    if (!validateReports()) {
      emit(state.copyWith(isSubmitting: false, validationFailed: true));
      return;
    }

    emit(state.copyWith(isSubmitting: true, validationFailed: false));

    try {
      print('Submitting reports: ${state.reports.length}');

      onSubmit(state.reports);
      emit(state.copyWith(isSubmitting: false));
    } catch (e, stack) {
      print('Error submitting reports: $e');
      print(stack);
      emit(state.copyWith(isSubmitting: false));
    }
  }

  void clearAllReports() {
    // Only preserve the supervisor ID, clear all other fields
    final supervisorId =
        state.reports.isNotEmpty ? state.reports.first.supervisorId ?? '' : '';
    emit(AddMultipleReportsState.initial(supervisorId));
  }

  // Supervisor selection methods
  void updateSelectedSupervisor(String supervisorId) {
    print('👥 Cubit: updateSelectedSupervisor called with: $supervisorId');
    emit(state.copyWith(
      selectedSupervisorId: supervisorId,
      showSupervisorSelection: false,
    ));
    
    // Update all existing reports with the new supervisor ID
    if (state.reports.isNotEmpty) {
      final updatedReports = state.reports.map((report) {
        return report.copyWith(supervisorId: supervisorId);
      }).toList();
      emit(state.copyWith(reports: updatedReports));
    }
  }

  void toggleSupervisorSelection() {
    emit(state.copyWith(showSupervisorSelection: !state.showSupervisorSelection));
  }

  // Load Excel data into the cubit state
  void loadExcelData(Map<String, List<ExcelReportData>> excelReportsBySchool) {
    print('📊 Loading Excel data into cubit state');
    print('📊 Schools available: ${excelReportsBySchool.keys.toList()}');
    print('📊 Total reports: ${excelReportsBySchool.values.expand((reports) => reports).length}');
    
    emit(state.copyWith(
      excelReportsBySchool: excelReportsBySchool,
      excelErrorMessage: null,
    ));
  }

  // Load Excel data from the global service
  void _loadExcelDataFromService() {
    final excelDataService = ExcelDataService();
    if (excelDataService.hasExcelData()) {
      final excelData = excelDataService.getExcelData();
      print('📊 Loading Excel data from service');
      print('📊 Schools available: ${excelData.keys.toList()}');
      loadExcelData(excelData);
      
      // Clear existing reports when starting fresh in Excel mode
      emit(state.copyWith(
        reports: [],
        excelErrorMessage: null,
      ));
    } else {
      print('📊 No Excel data available in service');
      emit(state.copyWith(
        excelErrorMessage: 'لا توجد بيانات إكسل متاحة. يرجى رفع ملف الإكسل أولاً.',
      ));
    }
  }

  void loadExcelReportsForSupervisor(String supervisorId, String schoolName) async {
    try {
      emit(state.copyWith(isLoadingExcel: true, excelErrorMessage: null));
      
      print('🔍 Loading Excel reports for supervisor: $supervisorId, school: $schoolName');
      print('🔍 Current Excel data keys: ${state.excelReportsBySchool.keys.toList()}');
      
      // Check if we have Excel data for this school
      if (state.excelReportsBySchool.containsKey(schoolName)) {
        final reports = state.excelReportsBySchool[schoolName] ?? [];
        print('🔍 Found ${reports.length} reports for school: $schoolName');
        
        // Convert Excel reports to ReportFormData and add them as separate cards
        final reportFormDataList = reports
            .map((excelReport) => excelReport.toReportFormData(supervisorId))
            .toList();
        
        // Add each report as a separate card instead of replacing all reports
        final updatedReports = List<ReportFormData>.from(state.reports);
        updatedReports.addAll(reportFormDataList);
        
        emit(state.copyWith(
          reports: updatedReports,
          selectedExcelSchoolName: schoolName,
          isLoadingExcel: false,
          excelErrorMessage: null,
        ));
        
        print('✅ Successfully added ${reportFormDataList.length} reports as separate cards for school: $schoolName');
        print('📊 Total reports now: ${updatedReports.length}');
      } else {
        print('❌ No Excel data found for school: $schoolName');
        print('🔍 Available schools: ${state.excelReportsBySchool.keys.toList()}');
        
        emit(state.copyWith(
          isLoadingExcel: false,
          excelErrorMessage: 'لا توجد بيانات إكسل متاحة لهذه المدرسة: $schoolName',
        ));
      }
    } catch (e) {
      print('❌ Error loading Excel reports: $e');
      emit(state.copyWith(
        isLoadingExcel: false,
        excelErrorMessage: 'فشل في تحميل البلاغات: $e',
      ));
    }
  }

  Future<void> pickImagesFromUI(int index, BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty) return;

    // Upload images to Supabase storage
    final uploadedUrls = await _storageService.uploadMultipleImages(picked);
    updateImages(index, uploadedUrls);
  }
}
