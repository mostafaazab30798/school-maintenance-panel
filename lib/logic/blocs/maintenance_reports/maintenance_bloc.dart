import 'package:admin_panel/logic/blocs/maintenance_reports/maintenance_event.dart';
import 'package:admin_panel/logic/blocs/maintenance_reports/maintenance_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class MaintenanceReportBloc
    extends Bloc<MaintenanceReportEvent, MaintenanceReportState> {
  final SupabaseClient client;

  MaintenanceReportBloc(this.client) : super(MaintenanceReportInitial()) {
    on<SubmitMaintenanceReport>(_onSubmit);
  }

  Future<void> _onSubmit(
    SubmitMaintenanceReport event,
    Emitter<MaintenanceReportState> emit,
  ) async {
    emit(MaintenanceReportLoading());

    try {
      final DateTime scheduled = _mapScheduleToDate(event.scheduledDate);

      // Insert the maintenance report and get the returned data
      final response = await client
          .from('maintenance_reports')
          .insert({
            'supervisor_id': event.supervisorId,
            'school_name': event.schoolName,
            'description': event.notes,
            'status': 'pending',
            'images': event.imageUrls,
            'priority':
                'routine', // Add default priority to satisfy database trigger
            'created_at': DateTime.now().toIso8601String(),
            'scheduled_date': scheduled.toIso8601String(),
          })
          .select()
          .single(); // Get the created record

      print('MaintenanceReportBloc: Maintenance report created successfully');

      // Send notification after successful creation
      try {
        await _sendMaintenanceNotification(
          reportId: response['id'],
          supervisorId: event.supervisorId,
          schoolName: event.schoolName,
          description: event.notes,
        );
        print('MaintenanceReportBloc: Notification sent successfully');
      } catch (notificationError) {
        // Don't let notification errors affect the main flow
        print(
            'MaintenanceReportBloc: Failed to send notification: $notificationError');
      }

      emit(MaintenanceReportSuccess());
    } catch (e) {
      emit(MaintenanceReportFailure(e.toString()));
    }
  }

  /// Send notification for maintenance report
  Future<void> _sendMaintenanceNotification({
    required String reportId,
    required String supervisorId,
    required String schoolName,
    required String description,
  }) async {
    try {
      final notificationData = {
        'user_id': supervisorId,
        'title': '🔧 بلاغ صيانة جديد',
        'body': 'لديك طلب صيانة جديد في $schoolName',
        'priority': 'routine',
        'school_name': schoolName,
        'data': {
          'type': 'maintenance',
          'report_id': reportId,
          'school_name': schoolName,
          'description': description,
          'priority': 'routine',
          'is_emergency': false,
          'is_maintenance': true,
        }
      };

      print(
          'MaintenanceReportBloc: Sending notification with data: $notificationData');

      await client.functions
          .invoke(
        'send_notification',
        body: notificationData,
      )
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Notification request timed out');
        },
      );
    } catch (e) {
      print('MaintenanceReportBloc: Error sending notification: $e');
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
}
