import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/report_form_data.dart';
import 'report_repository.dart';
import '../../core/services/notification_service.dart';

class MultiReportRepository {
  final SupabaseClient client;
  final ReportRepository? reportRepository;

  MultiReportRepository({required this.client, this.reportRepository});

  Future<void> submitReports(List<ReportFormData> reports) async {
    print(
        'MultiReportRepository: Starting to submit ${reports.length} reports');

    if (reports.isEmpty) {
      print('MultiReportRepository: No reports to submit');
      return;
    }

    try {
      // Determine which table to insert into based on the first report's type
      final String tableName =
          reports.first.type?.toLowerCase() == 'maintenance'
              ? 'maintenance_reports'
              : 'reports';

      print('MultiReportRepository: Inserting into table: $tableName');

      final List<Map<String, dynamic>> payload = reports.map((r) {
        // Update scheduled date if present
        if (r.scheduledDate != null && r.scheduledDate!.isNotEmpty) {
          r.scheduledDate =
              _mapScheduleToDate(r.scheduledDate!).toIso8601String();
        }

        print(
            'MultiReportRepository: Processing report - School: ${r.schoolName}, Type: ${r.type}');

        // Use the model's toMap method which now handles different report types
        final reportData = r.toMap();

        if (r.type?.toLowerCase() == 'maintenance') {
          print('MultiReportRepository: Creating maintenance report');
        }

        return reportData;
      }).toList();

      print('MultiReportRepository: Final payload to Supabase: $payload');
      final insertedReports = await client.from(tableName).insert(payload).select();
      print('MultiReportRepository: Reports inserted successfully');
      print('MultiReportRepository: Inserted reports with IDs: $insertedReports');

      // Invalidate report repository cache if available
      reportRepository?.invalidateCache();

      // Reports were successfully submitted
      print('MultiReportRepository: Reports submitted successfully');

      // Trigger notifications in a separate isolate to avoid affecting the UI
      // This is wrapped in try-catch to ensure it doesn't affect the main flow
      try {
        // Use Future.delayed to ensure the UI has time to update before attempting notifications
        Future.delayed(const Duration(milliseconds: 300), () {
          _triggerNotificationsNonBlocking(
              insertedReports, reports.first.type?.toLowerCase() == 'maintenance');
        });
      } catch (notificationError) {
        // Just log the error, don't let it affect the main flow
        print(
            'MultiReportRepository: Failed to schedule notifications: $notificationError');
      }
    } catch (e, stack) {
      print('MultiReportRepository: Error inserting reports: $e');
      print(stack);
      rethrow;
    }
  }

  DateTime _mapScheduleToDate(String value) {
    final today = DateTime.now();
    switch (value) {
      case 'today':
        return today;
      case 'tomorrow':
        return today.add(const Duration(days: 1));
      case 'after_tomorrow':
        return today.add(const Duration(days: 2));
      default:
        return today;
    }
  }

  /// Triggers notifications using the centralized notification service
  void _triggerNotificationsNonBlocking(
      List<Map<String, dynamic>> reports, bool isMaintenance) {
    Future.microtask(() async {
      try {
        print('MultiReportRepository: Starting notifications via NotificationService');

        // Use the centralized notification service
        final results = await NotificationService.instance.sendBulkReportNotifications(
          reports: reports,
          isMaintenance: isMaintenance,
        );

        // Log results
        final successCount = results.where((r) => r.isSuccess).length;
        print('MultiReportRepository: Notifications complete: $successCount/${results.length} successful');

        // Log any failures for debugging
        for (int i = 0; i < results.length; i++) {
          final result = results[i];
          if (!result.isSuccess && !result.isDuplicate) {
            print('MultiReportRepository: Notification ${i + 1} failed: ${result.message}');
          }
        }
      } catch (e) {
        print('MultiReportRepository: Error in notification process: $e');
      }
    });
  }
}
