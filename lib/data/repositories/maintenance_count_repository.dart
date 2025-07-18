import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/maintenance_count.dart';

class MaintenanceCountRepository {
  final SupabaseClient _client;

  MaintenanceCountRepository(this._client);

  /// Fetch all maintenance counts with optional filtering
  Future<List<MaintenanceCount>> getMaintenanceCounts({
    int page = 0,
    int limit = 20,
    String? supervisorId,
    String? schoolId,
    String? status,
  }) async {
    try {
      // RULE: For complex queries with range/order, apply filters after select but before range/order
      var query = _client.from('maintenance_counts').select('''
        id,
        school_id,
        school_name,
        supervisor_id,
        status,
        item_counts,
        text_answers,
        yes_no_answers,
        yes_no_with_counts,
        survey_answers,
        maintenance_notes,
        fire_safety_alarm_panel_data,
        fire_safety_condition_only_data,
        fire_safety_expiry_dates,
        section_photos,
        heater_entries,
        created_at,
        updated_at
      ''');

      // Apply filters first
      if (supervisorId != null) {
        query = query.eq('supervisor_id', supervisorId);
      }

      if (schoolId != null) {
        query = query.eq('school_id', schoolId);
      }

      if (status != null) {
        query = query.eq('status', status);
      }

      // Then apply range and order
      final response = await query
          .range(page * limit, (page + 1) * limit - 1)
          .order('created_at', ascending: false);

      return response
          .map<MaintenanceCount>((data) => MaintenanceCount.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch maintenance counts: $e');
    }
  }

  /// Fetch all maintenance count records with detailed data (for listing)
  Future<List<MaintenanceCount>> getAllMaintenanceCountRecords({
    List<String>? supervisorIds,
    String? schoolId,
    String? status,
    int limit = 50,
  }) async {
    try {
      print('🔍 DEBUG: Starting getAllMaintenanceCountRecords');
      print('🔍 DEBUG: supervisorIds: $supervisorIds');
      print('🔍 DEBUG: schoolId: $schoolId');
      print('🔍 DEBUG: status: $status');
      print('🔍 DEBUG: limit: $limit');

      var query = _client.from('maintenance_counts').select('''
        id,
        school_id,
        school_name,
        supervisor_id,
        status,
        item_counts,
        text_answers,
        yes_no_answers,
        yes_no_with_counts,
        survey_answers,
        maintenance_notes,
        fire_safety_alarm_panel_data,
        fire_safety_condition_only_data,
        fire_safety_expiry_dates,
        section_photos,
        heater_entries,
        created_at,
        updated_at
      ''');

      // Apply filters
      if (supervisorIds != null && supervisorIds.isNotEmpty) {
        query = query.inFilter('supervisor_id', supervisorIds);
        print('🔍 DEBUG: Applied supervisor filter for IDs: $supervisorIds');
      }

      if (schoolId != null) {
        query = query.eq('school_id', schoolId);
        print('🔍 DEBUG: Applied school filter: $schoolId');
      }

      if (status != null) {
        query = query.eq('status', status);
        print('🔍 DEBUG: Applied status filter: $status');
      }

      print('🔍 DEBUG: Executing query...');
      
      // Apply order and limit
      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      print('🔍 DEBUG: Query executed successfully');
      print('🔍 DEBUG: Response type: ${response.runtimeType}');
      print('🔍 DEBUG: Response length: ${response?.length ?? 'null'}');
      
      if (response != null && response.isNotEmpty) {
        print('🔍 DEBUG: First record: ${response.first}');
      }

      final result = response
          .map<MaintenanceCount>((data) => MaintenanceCount.fromMap(data))
          .toList();

      print('🔍 DEBUG: Parsed ${result.length} MaintenanceCount objects');
      return result;
    } catch (e, stackTrace) {
      print('❌ ERROR: Failed to fetch maintenance count records: $e');
      print('❌ ERROR: Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get schools that have maintenance counts
  Future<List<Map<String, dynamic>>> getSchoolsWithMaintenanceCounts({
    List<String>? supervisorIds,
  }) async {
    try {
      // RULE: Supabase query pattern is: from() -> select() -> where/eq/filter -> order()
      // Never apply filters before select() - it causes NoSuchMethodError
      var query = _client.from('maintenance_counts').select('''
            school_id,
            school_name,
            supervisor_id
          ''');

      // Apply supervisor filter after select
      if (supervisorIds != null && supervisorIds.isNotEmpty) {
        query = query.inFilter('supervisor_id', supervisorIds);
      }

      // Finally apply ordering
      final response = await query.order('school_name');

      // Handle empty response
      if (response == null || response.isEmpty) {
        return [];
      }

      // Group by school and count maintenance records
      final Map<String, Map<String, dynamic>> schoolCounts = {};

      for (final item in response) {
        final schoolId = item['school_id']?.toString() ?? '';
        final schoolName = item['school_name']?.toString() ?? '';

        if (schoolId.isNotEmpty) {
          if (!schoolCounts.containsKey(schoolId)) {
            schoolCounts[schoolId] = {
              'school_id': schoolId,
              'school_name': schoolName,
              'address': '', // Default empty address
              'maintenance_count': 0,
            };
          }
          schoolCounts[schoolId]!['maintenance_count'] =
              (schoolCounts[schoolId]!['maintenance_count'] as int) + 1;
        }
      }

      return schoolCounts.values.toList();
    } catch (e) {
      // Return empty list instead of throwing exception for better UX
      print('⚠️ WARNING: Failed to fetch schools with maintenance counts: $e');
      return [];
    }
  }

  /// Get schools with damaged items (schools that have damage data from damage_inventory table)
  Future<List<Map<String, dynamic>>> getSchoolsWithDamage({
    String? supervisorId,
  }) async {
    try {
      // RULE: Supabase query pattern is: from() -> select() -> where/eq/filter -> order()
      // Never apply filters before select() - it causes NoSuchMethodError
      var query = _client.from('damage_inventory').select('''
            school_id,
            school_name,
            supervisor_id,
            damage_type,
            damage_severity,
            damage_description
          ''');

      // Apply supervisor filter after select
      if (supervisorId != null) {
        query = query.eq('supervisor_id', supervisorId);
      }

      // Finally apply ordering
      final response = await query.order('school_name');

      // Handle empty response
      if (response == null || response.isEmpty) {
        return [];
      }

      final Map<String, Map<String, dynamic>> schoolData = {};

      for (final item in response) {
        final schoolId = item['school_id']?.toString() ?? '';
        final schoolName = item['school_name']?.toString() ?? '';

        if (schoolId.isNotEmpty) {
          if (!schoolData.containsKey(schoolId)) {
            schoolData[schoolId] = {
              'school_id': schoolId,
              'school_name': schoolName,
              'address': '', // Default empty address
              'damage_reports_count': 0,
            };
          }
          schoolData[schoolId]!['damage_reports_count'] =
              (schoolData[schoolId]!['damage_reports_count'] as int) + 1;
        }
      }

      return schoolData.values.toList();
    } catch (e) {
      // Return empty list instead of throwing exception for better UX
      print('⚠️ WARNING: Failed to fetch schools with damage: $e');
      return [];
    }
  }

  /// Get summary statistics for dashboard
  Future<Map<String, int>> getDashboardSummary({List<String>? supervisorIds}) async {
    try {
      // RULE: Supabase query pattern is: from() -> select() -> where/eq/filter -> order()
      // Never apply filters before select() - it causes NoSuchMethodError
      var query = _client.from('maintenance_counts').select(
          'status, school_id, yes_no_answers, fire_safety_condition_only_data, survey_answers');

      if (supervisorIds != null && supervisorIds.isNotEmpty) {
        query = query.inFilter('supervisor_id', supervisorIds);
      }

      final response = await query;

      // Handle empty response
      if (response == null || response.isEmpty) {
        return {
          'total_maintenance_counts': 0,
          'schools_with_counts': 0,
          'schools_with_damage': 0,
          'submitted_counts': 0,
          'draft_counts': 0,
        };
      }

      final Set<String> schoolsWithCounts = {};
      final Set<String> schoolsWithDamage = {};
      int totalCounts = response.length;
      int submittedCounts = 0;

      for (final item in response) {
        final status = item['status']?.toString() ?? 'draft';
        final schoolId = item['school_id']?.toString() ?? '';

        if (schoolId.isNotEmpty) {
          schoolsWithCounts.add(schoolId);
        }

        if (status == 'submitted') {
          submittedCounts++;
        }

        try {
          // Check for damage data
          final maintenanceCount = MaintenanceCount.fromMap(item);
          if (maintenanceCount.hasDamageData && schoolId.isNotEmpty) {
            schoolsWithDamage.add(schoolId);
          }
        } catch (e) {
          // Skip invalid records
          print('Warning: Skipping invalid record in summary: $e');
          continue;
        }
      }

      return {
        'total_maintenance_counts': totalCounts,
        'schools_with_counts': schoolsWithCounts.length,
        'schools_with_damage': schoolsWithDamage.length,
        'submitted_counts': submittedCounts,
        'draft_counts': totalCounts - submittedCounts,
      };
    } catch (e) {
      print('⚠️ WARNING: Failed to get dashboard summary: $e');
      return {
        'total_maintenance_counts': 0,
        'schools_with_counts': 0,
        'schools_with_damage': 0,
        'submitted_counts': 0,
        'draft_counts': 0,
      };
    }
  }
}
