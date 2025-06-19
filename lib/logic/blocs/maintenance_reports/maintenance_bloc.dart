import 'package:admin_panel/logic/blocs/maintenance_reports/maintenance_event.dart';
import 'package:admin_panel/logic/blocs/maintenance_reports/maintenance_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/notification_service.dart';
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

      // Send notification after successful creation using NotificationService
      try {
        final result = await NotificationService.instance.sendReportNotification(
          supervisorId: event.supervisorId,
          reportId: response['id'],
          schoolName: event.schoolName,
          priority: 'routine',
          description: event.notes,
          isMaintenance: true,
        );
        
        if (result.isSuccess) {
          print('MaintenanceReportBloc: Notification sent successfully');
        } else {
          print('MaintenanceReportBloc: Notification failed: ${result.message}');
        }
      } catch (notificationError) {
        // Don't let notification errors affect the main flow
        print('MaintenanceReportBloc: Failed to send notification: $notificationError');
      }

      emit(MaintenanceReportSuccess());
    } catch (e) {
      emit(MaintenanceReportFailure(e.toString()));
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
