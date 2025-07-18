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

  /// Fetch all damage count records with detailed data (for listing)
  Future<List<DamageCount>> getAllDamageCountRecords({
    List<String>? supervisorIds,
    String? schoolId,
    String? status,
    int limit = 50,
  }) async {
    try {
      print('🔍 DEBUG: Starting getAllDamageCountRecords with supervisorIds: $supervisorIds');

      var query = _client.from('damage_counts').select('''
        id,
        school_id,
        school_name,
        supervisor_id,
        status,
        item_counts,
        section_photos,
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
      }

      if (status != null) {
        query = query.eq('status', status);
      }

      // Apply order and limit
      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      print('🔍 DEBUG: Query executed. Response length: ${response?.length ?? 'null'}');

      return response
          .map<DamageCount>((data) => DamageCount.fromMap(data))
          .toList();
    } catch (e) {
      print('⚠️ WARNING: Failed to fetch damage count records: $e');
      return [];
    }
  }

  /// Get schools that have damage counts
  Future<List<Map<String, dynamic>>> getSchoolsWithDamageCounts({
    List<String>? supervisorIds,
  }) async {
    try {
      print(
          '🔍 DEBUG: Starting getSchoolsWithDamageCounts with supervisorIds: $supervisorIds');

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
      if (supervisorIds != null && supervisorIds.isNotEmpty) {
        query = query.inFilter('supervisor_id', supervisorIds);
        print('🔍 DEBUG: Applied supervisor filter for IDs: $supervisorIds');
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

        // Check if any records match our supervisors
        if (supervisorIds != null && supervisorIds.isNotEmpty) {
          final matchingRecords = debugResponse
              .where((r) => supervisorIds.contains(r['supervisor_id'].toString()))
              .toList();
          print(
              '🔍 DEBUG: Records matching supervisors $supervisorIds: ${matchingRecords.length}');
          if (matchingRecords.isNotEmpty) {
            print('🔍 DEBUG: Matching record details: ${matchingRecords.first}');
          }
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

      // Return ALL schools, not just those with damage
      final allSchools = schoolData.values.toList();

      print(
          '🔍 DEBUG: All schools (including those without damage): ${allSchools.length}');
      print('🔍 DEBUG: Final result: $allSchools');

      return allSchools;
    } catch (e) {
      // Return empty list instead of throwing exception for better UX
      print('❌ ERROR: Failed to fetch schools with damage counts: $e');
      print('❌ ERROR: Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// Get all damage count details for a specific school (without supervisor filtering)
  /// This is useful for super admins or debugging purposes
  Future<List<DamageCount>> getAllDamageCountsForSchool({
    required String schoolId,
  }) async {
    try {
      print('🔍 DEBUG: Getting ALL damage counts for school: $schoolId');

      final response = await _client
          .from('damage_counts')
          .select('*')
          .eq('school_id', schoolId)
          .order('created_at', ascending: false);

      print('🔍 DEBUG: Found ${response?.length ?? 0} total damage count records for school $schoolId');

      if (response == null || response.isEmpty) {
        return [];
      }

      return response
          .map<DamageCount>((data) => DamageCount.fromMap(data))
          .toList();
    } catch (e) {
      print('❌ ERROR: Failed to fetch all damage counts for school $schoolId: $e');
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

      // Get all records for this school and return the most recent one
      final response = await query.order('created_at', ascending: false);
      print('🔍 DEBUG: Query response length: ${response?.length ?? 0}');

      if (response == null || response.isEmpty) {
        print('🔍 DEBUG: No damage count records found for school: $schoolId');
        
        // Let's also check if there are any records at all in the table
        try {
          final allRecords = await _client.from('damage_counts').select('school_id, school_name, supervisor_id').limit(5);
          print('🔍 DEBUG: Sample records in damage_counts table: $allRecords');
        } catch (e) {
          print('🔍 DEBUG: Could not fetch sample records: $e');
        }
        
        return null;
      }

      // Log all found records for debugging
      print('🔍 DEBUG: Found ${response.length} damage count records for school $schoolId:');
      for (int i = 0; i < response.length; i++) {
        final record = response[i];
        print('🔍 DEBUG: Record $i - ID: ${record['id']}, Supervisor: ${record['supervisor_id']}, Status: ${record['status']}, Created: ${record['created_at']}');
      }

      // Return the most recent record (first in the ordered list)
      final mostRecentRecord = response.first;
      print('🔍 DEBUG: Most recent record: $mostRecentRecord');

      final damageCount = DamageCount.fromMap(mostRecentRecord);
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
  Future<Map<String, int>> getDashboardSummary({List<String>? supervisorIds}) async {
    try {
      var query = _client.from('damage_counts').select('*');

      if (supervisorIds != null && supervisorIds.isNotEmpty) {
        query = query.inFilter('supervisor_id', supervisorIds);
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
