import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supervisor_attendance.dart';

class SupervisorAttendanceRepository {
  final SupabaseClient _client;

  SupervisorAttendanceRepository(this._client);

  /// Fetch attendance records for a specific supervisor
  Future<List<SupervisorAttendance>> fetchAttendanceForSupervisor(String supervisorId) async {
    try {
      final response = await _client
          .from('supervisor_attendance')
          .select('*')
          .eq('supervisor_id', supervisorId)
          .order('created_at', ascending: false);

      if (response is List) {
        return response.map((map) => SupervisorAttendance.fromMap(map)).toList();
      } else {
        throw Exception('Failed to load attendance records');
      }
    } catch (e) {
      throw Exception('Failed to load attendance records: $e');
    }
  }

  /// Fetch all attendance records (for admin dashboard)
  Future<List<SupervisorAttendance>> fetchAllAttendance() async {
    try {
      final response = await _client
          .from('supervisor_attendance')
          .select('*')
          .order('created_at', ascending: false);

      if (response is List) {
        return response.map((map) => SupervisorAttendance.fromMap(map)).toList();
      } else {
        throw Exception('Failed to load attendance records');
      }
    } catch (e) {
      throw Exception('Failed to load attendance records: $e');
    }
  }

  /// Create a new attendance record
  Future<void> createAttendance(SupervisorAttendance attendance) async {
    try {
      final data = attendance.toMap()..remove('id');
      await _client.from('supervisor_attendance').insert(data);
    } catch (e) {
      throw Exception('Failed to create attendance record: $e');
    }
  }

  /// Update an attendance record
  Future<void> updateAttendance(String id, Map<String, dynamic> updates) async {
    try {
      await _client.from('supervisor_attendance').update(updates).eq('id', id);
    } catch (e) {
      throw Exception('Failed to update attendance record: $e');
    }
  }

  /// Delete an attendance record
  Future<void> deleteAttendance(String id) async {
    try {
      await _client.from('supervisor_attendance').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete attendance record: $e');
    }
  }

  /// Get attendance statistics for a supervisor
  Future<Map<String, dynamic>> getAttendanceStats(String supervisorId) async {
    try {
      final attendance = await fetchAttendanceForSupervisor(supervisorId);
      
      final today = DateTime.now();
      final startOfMonth = DateTime(today.year, today.month, 1);
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

      final totalRecords = attendance.length;
      final thisMonth = attendance.where((a) => a.createdAt.isAfter(startOfMonth)).length;
      final thisWeek = attendance.where((a) => a.createdAt.isAfter(startOfWeek)).length;
      final todayRecords = attendance.where((a) => 
        a.createdAt.year == today.year && 
        a.createdAt.month == today.month && 
        a.createdAt.day == today.day
      ).length;

      return {
        'total': totalRecords,
        'this_month': thisMonth,
        'this_week': thisWeek,
        'today': todayRecords,
      };
    } catch (e) {
      throw Exception('Failed to get attendance stats: $e');
    }
  }

  /// Get attendance statistics for all supervisors (admin dashboard)
  Future<Map<String, dynamic>> getAllAttendanceStats() async {
    try {
      final allAttendance = await fetchAllAttendance();
      
      final today = DateTime.now();
      final startOfMonth = DateTime(today.year, today.month, 1);
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

      final totalRecords = allAttendance.length;
      final thisMonth = allAttendance.where((a) => a.createdAt.isAfter(startOfMonth)).length;
      final thisWeek = allAttendance.where((a) => a.createdAt.isAfter(startOfWeek)).length;
      final todayRecords = allAttendance.where((a) => 
        a.createdAt.year == today.year && 
        a.createdAt.month == today.month && 
        a.createdAt.day == today.day
      ).length;

      return {
        'total': totalRecords,
        'this_month': thisMonth,
        'this_week': thisWeek,
        'today': todayRecords,
      };
    } catch (e) {
      throw Exception('Failed to get all attendance stats: $e');
    }
  }
} 