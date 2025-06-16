import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/report_form_data.dart';
import 'report_repository.dart';

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
      await client.from(tableName).insert(payload);
      print('MultiReportRepository: Reports inserted successfully');

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
              payload, reports.first.type?.toLowerCase() == 'maintenance');
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

  /// Triggers notifications in a non-blocking way to prevent UI freezes
  void _triggerNotificationsNonBlocking(
      List<Map<String, dynamic>> reports, bool isMaintenance) {
    Future.microtask(() async {
      try {
        print('MultiReportRepository: Starting background notifications');

        for (final report in reports) {
          try {
            final reportId = report['id'];
            final supervisorId = report['supervisor_id'];

            // Debug: Print available fields
            print(
                'MultiReportRepository: Available fields in report: ${report.keys.toList()}');

            // Extract fields based on report type
            final String schoolName;
            final String priority;
            final bool isEmergency;

            if (isMaintenance) {
              // For maintenance reports
              schoolName = report['school_name'] ?? 'مدرسة غير معروفة';
              // Maintenance reports don't have priority, use a default
              priority = 'عادي';
              isEmergency = false;
            } else {
              // For regular reports
              schoolName = report['school_name'] ?? 'مدرسة غير معروفة';
              priority = report['priority'] ?? 'عادي';
              isEmergency = priority.toLowerCase() == 'high' ||
                  priority.toLowerCase() == 'emergency';
            }

            print('MultiReportRepository: Resolved school name: $schoolName');
            print(
                'MultiReportRepository: Report type: ${isMaintenance ? "maintenance" : "regular"}');

            // Create different notification payloads based on report type
            final Map<String, dynamic> notificationData;

            if (isMaintenance) {
              // For maintenance reports - completely different payload structure
              // This avoids the Edge Function trying to access fields that don't exist
              notificationData = {
                'user_id': supervisorId,
                'title': 'صيانة دورية 🔧',
                'body': 'لديك صيانة دورية في $schoolName',
                'priority':
                    'routine', // Always provide priority to prevent database errors
                'school_name': schoolName,
                'data': {
                  'type': 'maintenance',
                  'report_id': reportId,
                  'school_name': schoolName,
                  'description': report['description'] ?? '',
                  'priority': 'routine', // Always provide priority
                  'is_emergency': false,
                  'is_maintenance': true,
                }
              };
            } else {
              // For regular reports
              notificationData = {
                'user_id': supervisorId,
                'title': isEmergency ? 'بلاغ طارئ 🚨' : 'بلاغ روتيني 📋',
                'body': 'لديك بلاغ جديد في $schoolName',
                'priority': priority, // This should always be present now
                'school_name': schoolName,
                'data': {
                  'type': 'new_report',
                  'report_id': reportId,
                  'school_name': schoolName,
                  'priority': priority,
                  'is_emergency': isEmergency,
                  'description': report['description'] ?? '',
                }
              };
            }

            // Add debug information to help diagnose issues
            print(
                'MultiReportRepository: Notification type: ${isMaintenance ? "maintenance" : "regular"}');
            print(
                'MultiReportRepository: Notification data: $notificationData');

            await client.functions
                .invoke(
              'send_notification',
              body: notificationData,
            )
                .timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                print(
                    'MultiReportRepository: Notification request timed out for report $reportId');
                throw TimeoutException('Notification request timed out');
              },
            );

            print(
                'MultiReportRepository: Notification sent successfully for report $reportId');

            await Future.delayed(const Duration(milliseconds: 200));
          } catch (e) {
            print('MultiReportRepository: Error processing notification: $e');
          }
        }
      } catch (e) {
        print(
            'MultiReportRepository: Error in background notification process: $e');
      }
    });
  }
}
