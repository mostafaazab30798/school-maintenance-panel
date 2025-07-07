import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/damage_count.dart';

class DamageCountRepository {
  final SupabaseClient _client;

  DamageCountRepository(this._client);

  /// Fetch all damage counts with optional filtering
  Future<List<DamageCount>> getDamageCounts({
    int page = 0,
    int limit = 20,
    String? supervisorId,
    String? schoolId,
    String? status,
  }) async {
    try {
      // RULE: For complex queries with range/order, apply filters after select but before range/order
      var query = _client.from('damage_counts').select('*');

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
          .map<DamageCount>((data) => DamageCount.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch damage counts: $e');
    }
  }

  /// Get schools that have damage counts
  Future<List<Map<String, dynamic>>> getSchoolsWithDamageCounts({
    String? supervisorId,
  }) async {
    try {
      print(
          '🔍 DEBUG: Starting getSchoolsWithDamageCounts with supervisorId: $supervisorId');

      // RULE: Supabase query pattern is: from() -> select() -> where/eq/filter -> order()
      // Never apply filters before select() - it causes NoSuchMethodError
      var query = _client.from('damage_counts').select('''
            school_id,
            school_name,
            supervisor_id,
            item_counts,
            status
          ''');

      print('🔍 DEBUG: Initial query created');

      // Apply supervisor filter after select
      if (supervisorId != null) {
        query = query.eq('supervisor_id', supervisorId);
        print('🔍 DEBUG: Applied supervisor filter: $supervisorId');
      } else {
        print('🔍 DEBUG: No supervisor filter applied (super admin)');
      }

      // TEMPORARY DEBUG: Also try without filter to see if any data exists
      final debugQuery = _client.from('damage_counts').select('*');
      final debugResponse = await debugQuery;
      print(
          '🔍 DEBUG: Total records in damage_counts table: ${debugResponse?.length ?? 0}');
      if (debugResponse != null && debugResponse.isNotEmpty) {
        print('🔍 DEBUG: Sample record: ${debugResponse.first}');
        final supervisorIds =
            debugResponse.map((r) => r['supervisor_id']).toSet();
        print('🔍 DEBUG: Available supervisor IDs: $supervisorIds');

        // Check if any records match our supervisor
        final matchingRecords = debugResponse
            .where((r) => r['supervisor_id'].toString() == supervisorId)
            .toList();
        print(
            '🔍 DEBUG: Records matching supervisor $supervisorId: ${matchingRecords.length}');
        if (matchingRecords.isNotEmpty) {
          print('🔍 DEBUG: Matching record details: ${matchingRecords.first}');
        }
      }

      // Finally apply ordering
      final response = await query.order('school_name');

      print('🔍 DEBUG: Query executed. Response type: ${response.runtimeType}');
      print('🔍 DEBUG: Response length: ${response?.length ?? 'null'}');
      print('🔍 DEBUG: Raw response: $response');

      // Handle empty response
      if (response == null || response.isEmpty) {
        print('🔍 DEBUG: Empty response, returning empty list');
        return [];
      }

      // Group by school and count damage records
      final Map<String, Map<String, dynamic>> schoolData = {};

      print('🔍 DEBUG: Processing ${response.length} records');

      for (final item in response) {
        print('🔍 DEBUG: Processing item: $item');

        final schoolId = item['school_id']?.toString() ?? '';
        final schoolName = item['school_name']?.toString() ?? '';
        final itemCounts = item['item_counts'] as Map<String, dynamic>? ?? {};
        final status = item['status']?.toString() ?? 'draft';

        print('🔍 DEBUG: School ID: $schoolId, Name: $schoolName');
        print('🔍 DEBUG: Item counts: $itemCounts');
        print('🔍 DEBUG: Status: $status');

        if (schoolId.isNotEmpty) {
          if (!schoolData.containsKey(schoolId)) {
            schoolData[schoolId] = {
              'school_id': schoolId,
              'school_name': schoolName,
              'address': '', // Default empty address
              'damage_count': 0,
              'total_damaged_items': 0,
              'has_damage': false,
            };
            print('🔍 DEBUG: Created new school entry for: $schoolId');
          }

          // Count total damaged items
          int totalDamaged = 0;
          bool hasDamage = false;

          for (var entry in itemCounts.entries) {
            final count = entry.value is num
                ? (entry.value as num).toInt()
                : int.tryParse(entry.value.toString()) ?? 0;
            totalDamaged += count;
            if (count > 0) hasDamage = true;
            print(
                '🔍 DEBUG: Item ${entry.key}: $count (hasDamage: ${count > 0})');
          }

          print(
              '🔍 DEBUG: School $schoolId - Total damaged: $totalDamaged, Has damage: $hasDamage');

          schoolData[schoolId]!['damage_count'] =
              (schoolData[schoolId]!['damage_count'] as int) + 1;
          schoolData[schoolId]!['total_damaged_items'] =
              (schoolData[schoolId]!['total_damaged_items'] as int) +
                  totalDamaged;
          schoolData[schoolId]!['has_damage'] =
              (schoolData[schoolId]!['has_damage'] as bool) || hasDamage;
        }
      }

      print('🔍 DEBUG: Processed school data: $schoolData');

      // Only return schools that actually have damage
      final filteredSchools = schoolData.values
          .where((school) => school['has_damage'] as bool)
          .toList();

      print(
          '🔍 DEBUG: Filtered schools with damage: ${filteredSchools.length}');
      print('🔍 DEBUG: Final result: $filteredSchools');

      return filteredSchools;
    } catch (e) {
      // Return empty list instead of throwing exception for better UX
      print('❌ ERROR: Failed to fetch schools with damage counts: $e');
      print('❌ ERROR: Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// Get damage count details for a specific school
  Future<DamageCount?> getDamageCountBySchool({
    required String schoolId,
    String? supervisorId,
  }) async {
    try {
      print(
          '🔍 DEBUG: Getting damage count for school: $schoolId, supervisor: $supervisorId');

      var query = _client.from('damage_counts').select('*');

      query = query.eq('school_id', schoolId);
      print('🔍 DEBUG: Applied school_id filter: $schoolId');

      if (supervisorId != null) {
        query = query.eq('supervisor_id', supervisorId);
        print('🔍 DEBUG: Applied supervisor_id filter: $supervisorId');
      }

      final response = await query.single();
      print('🔍 DEBUG: Single query response: $response');

      final damageCount = DamageCount.fromMap(response);
      print('🔍 DEBUG: Created DamageCount object: ${damageCount.id}');

      return damageCount;
    } catch (e) {
      print('❌ ERROR: Failed to fetch damage count for school $schoolId: $e');
      print('❌ ERROR: Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  /// Create or update damage count
  Future<DamageCount> upsertDamageCount(DamageCount damageCount) async {
    try {
      final data = damageCount.toMap();

      final response =
          await _client.from('damage_counts').upsert(data).select().single();

      return DamageCount.fromMap(response);
    } catch (e) {
      throw Exception('Failed to upsert damage count: $e');
    }
  }

  /// Get summary statistics for dashboard
  Future<Map<String, int>> getDashboardSummary({String? supervisorId}) async {
    try {
      var query = _client.from('damage_counts').select('*');

      if (supervisorId != null) {
        query = query.eq('supervisor_id', supervisorId);
      }

      final response = await query;

      // Handle empty response
      if (response == null || response.isEmpty) {
        return {
          'total_damage_reports': 0,
          'schools_with_damage': 0,
          'total_damaged_items': 0,
          'pending_repairs': 0,
          'completed_repairs': 0,
        };
      }

      final Set<String> schoolsWithDamage = {};
      int totalDamageReports = response.length;
      int totalDamagedItems = 0;
      int pendingRepairs = 0;
      int completedRepairs = 0;

      for (final item in response) {
        final schoolId = item['school_id']?.toString() ?? '';
        final itemCounts = item['item_counts'] as Map<String, dynamic>? ?? {};
        final repairStatus =
            item['repair_status'] as Map<String, dynamic>? ?? {};

        if (schoolId.isNotEmpty) {
          // Check if school has actual damage
          bool hasDamage = false;
          for (var entry in itemCounts.entries) {
            final count = entry.value is num
                ? (entry.value as num).toInt()
                : int.tryParse(entry.value.toString()) ?? 0;
            totalDamagedItems += count;
            if (count > 0) hasDamage = true;
          }

          if (hasDamage) {
            schoolsWithDamage.add(schoolId);
          }
        }

        // Count repair statuses
        for (var status in repairStatus.values) {
          final statusStr = status.toString().toLowerCase();
          if (statusStr == 'pending' || statusStr == 'in_progress') {
            pendingRepairs++;
          } else if (statusStr == 'completed') {
            completedRepairs++;
          }
        }
      }

      return {
        'total_damage_reports': totalDamageReports,
        'schools_with_damage': schoolsWithDamage.length,
        'total_damaged_items': totalDamagedItems,
        'pending_repairs': pendingRepairs,
        'completed_repairs': completedRepairs,
      };
    } catch (e) {
      print('⚠️ WARNING: Failed to get dashboard summary: $e');
      return {
        'total_damage_reports': 0,
        'schools_with_damage': 0,
        'total_damaged_items': 0,
        'pending_repairs': 0,
        'completed_repairs': 0,
      };
    }
  }

  /// Delete damage count
  Future<void> deleteDamageCount(String id) async {
    try {
      await _client.from('damage_counts').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete damage count: $e');
    }
  }
}
