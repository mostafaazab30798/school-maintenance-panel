import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/report_form_data.dart';
import 'add_multiple_reports_state.dart';
import 'package:http/http.dart' as http;

class AddMultipleReportsCubit extends Cubit<AddMultipleReportsState> {
  AddMultipleReportsCubit(String supervisorId)
      : super(AddMultipleReportsState.initial(supervisorId));

  void addReport(String supervisorId) {
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
    final updated = List<ReportFormData>.from(state.reports);
    updated[index].schoolName = value;
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

  bool validateReports() {
    // Check if there are any reports to validate
    if (state.reports.isEmpty) {
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

  Future<void> pickImagesFromUI(int index, BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty) return;

    List<String> uploadedUrls = [];
    for (var file in picked) {
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final publicId = 'image_$timestamp';

      final response = await http.post(
        Uri.parse('https://api.cloudinary.com/v1_1/dg7rsus0g/image/upload'),
        body: {
          'file': 'data:image/jpeg;base64,$base64Image',
          'upload_preset': 'managment_upload',
          'public_id': publicId,
          'folder': 'reports'
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final url = data['secure_url'];
        uploadedUrls.add(url);
      }
    }

    updateImages(index, uploadedUrls);
  }
}
