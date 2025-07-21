import 'package:excel/excel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/school.dart';
import 'dart:typed_data';

class SchoolAssignmentService {
  final SupabaseClient _client;

  SchoolAssignmentService(this._client);

  /// Get all schools
  Future<List<School>> getAllSchools() async {
    final response = await _client.from('schools').select().order('name');

    return (response as List).map((data) => School.fromMap(data)).toList();
  }

  /// Get schools assigned to a supervisor
  Future<List<School>> getSchoolsForSupervisor(String supervisorId) async {
    try {
      // First, get the count to see if we need pagination
      final countResponse = await _client
          .from('supervisor_schools')
          .select('school_id')
          .eq('supervisor_id', supervisorId);
      
      final totalCount = countResponse.length;
      print('🏫 DEBUG: Total schools for supervisor $supervisorId: $totalCount');
      
      List<School> allSchools = [];
      
      if (totalCount > 1000) {
        // Use pagination for large datasets
        print('🏫 DEBUG: Large dataset detected, using pagination');
        int offset = 0;
        const int pageSize = 1000;
        
        while (offset < totalCount) {
          final response = await _client
              .from('schools')
              .select('*, supervisor_schools!inner(*)')
              .eq('supervisor_schools.supervisor_id', supervisorId)
              .range(offset, offset + pageSize - 1)
              .order('name');
          
          final schools = (response as List).map((data) => School.fromMap(data)).toList();
          allSchools.addAll(schools);
          
          print('🏫 DEBUG: Fetched ${schools.length} schools (offset: $offset)');
          offset += pageSize;
        }
      } else {
        // Use regular query for smaller datasets
        final response = await _client
            .from('schools')
            .select('*, supervisor_schools!inner(*)')
            .eq('supervisor_schools.supervisor_id', supervisorId)
            .order('name');
        
        allSchools = (response as List).map((data) => School.fromMap(data)).toList();
        print('🏫 DEBUG: Fetched ${allSchools.length} schools in single query');
      }
      
      print('🏫 DEBUG: Total schools returned: ${allSchools.length}');
      return allSchools;
    } catch (e) {
      print('🏫 ERROR: Failed to fetch schools for supervisor $supervisorId: $e');
      rethrow;
    }
  }

  /// Process Excel file and assign schools to supervisor
  Future<Map<String, dynamic>> processExcelAndAssignSchools({
    required Uint8List fileBytes,
    required String supervisorId,
    required Function(String) onProgress,
  }) async {
    try {
      // Parse Excel file
      final excel = Excel.decodeBytes(fileBytes);
      final sheet = excel.tables.keys.first;
      final table = excel.tables[sheet]!;

      if (table.rows.isEmpty) {
        throw Exception('الملف فارغ');
      }

      // Skip header row and process schools
      final dataRows = table.rows.skip(1).where((row) {
        return row.isNotEmpty &&
            row[0]?.value != null &&
            row[0]!.value.toString().trim().isNotEmpty;
      }).toList();

      if (dataRows.isEmpty) {
        throw Exception('لا توجد بيانات صالحة في الملف');
      }

      onProgress('جاري معالجة قائمة المدارس...');

      // Extract school names and addresses from Excel
      List<Map<String, String>> excelSchools = [];
      for (final row in dataRows) {
        final schoolName = row[0]?.value?.toString().trim() ?? '';
        final schoolAddress =
            row.length > 1 ? (row[1]?.value?.toString().trim() ?? '') : '';

        if (schoolName.isNotEmpty) {
          excelSchools.add({
            'name': schoolName,
            'address': schoolAddress.isEmpty ? '' : schoolAddress,
          });
        }
      }

      onProgress('جاري البحث عن المدارس الموجودة...');

      // Get all existing schools from database
      final existingSchoolsResponse =
          await _client.from('schools').select('id, name, address');

      final existingSchools = Map<String, String>.fromEntries(
          (existingSchoolsResponse as List).map((school) =>
              MapEntry(school['name'] as String, school['id'] as String)));

      onProgress('جاري تحديد المدارس الجديدة...');

      // Determine which schools need to be created
      List<String> finalSchoolIds = [];
      List<Map<String, dynamic>> schoolsToCreate = [];

      int processedCount = 0;
      for (final excelSchool in excelSchools) {
        final schoolName = excelSchool['name']!;

        if (existingSchools.containsKey(schoolName)) {
          // School already exists, use existing ID
          finalSchoolIds.add(existingSchools[schoolName]!);
        } else {
          // School doesn't exist, mark for creation
          schoolsToCreate.add({
            'name': schoolName,
            'address':
                excelSchool['address']!.isEmpty ? null : excelSchool['address'],
          });
        }

        processedCount++;
        final progress = ((processedCount / excelSchools.length) * 30).round();
        onProgress(
            'تم معالجة ${processedCount} من ${excelSchools.length} مدرسة... ($progress%)');
      }

      // Create new schools if any
      if (schoolsToCreate.isNotEmpty) {
        onProgress('جاري إنشاء المدارس الجديدة...');

        final newSchoolsResponse =
            await _client.from('schools').insert(schoolsToCreate).select('id');

        final newSchoolIds = (newSchoolsResponse as List)
            .map((school) => school['id'] as String)
            .toList();

        finalSchoolIds.addAll(newSchoolIds);
      }

      onProgress('جاري إزالة الربط السابق...');

      // Remove all existing assignments for this supervisor
      await _client
          .from('supervisor_schools')
          .delete()
          .eq('supervisor_id', supervisorId);

      onProgress('جاري ربط المدارس الجديدة...');

      // Create new assignments
      if (finalSchoolIds.isNotEmpty) {
        final assignments = finalSchoolIds
            .map((schoolId) => {
                  'supervisor_id': supervisorId,
                  'school_id': schoolId,
                })
            .toList();

        await _client.from('supervisor_schools').insert(assignments);
      }

      onProgress('تم إكمال العملية بنجاح!');

      return {
        'success': true,
        'total_schools': finalSchoolIds.length,
        'new_schools_created': schoolsToCreate.length,
        'existing_schools_used': finalSchoolIds.length - schoolsToCreate.length,
        'supervisor_id': supervisorId,
      };
    } catch (e) {
      throw Exception('خطأ في معالجة الملف: $e');
    }
  }

  /// Remove a school assignment from a supervisor
  Future<void> removeSchoolFromSupervisor(String supervisorId, String schoolId) async {
    try {
      await _client
          .from('supervisor_schools')
          .delete()
          .eq('supervisor_id', supervisorId)
          .eq('school_id', schoolId);
    } catch (e) {
      throw Exception('فشل في إزالة المدرسة من المشرف: $e');
    }
  }

  /// Remove multiple school assignments from a supervisor
  Future<void> removeSchoolsFromSupervisor(String supervisorId, List<String> schoolIds) async {
    try {
      print('🔍 DEBUG: removeSchoolsFromSupervisor called');
      print('🔍 DEBUG: supervisorId: $supervisorId');
      print('🔍 DEBUG: schoolIds count: ${schoolIds.length}');
      
      if (schoolIds.isEmpty) {
        print('🔍 DEBUG: schoolIds is empty, returning early');
        return;
      }
      
      // Check if client is connected
      print('🔍 DEBUG: Checking Supabase client connection');
      if (_client.auth.currentSession == null) {
        print('🔍 DEBUG: No active session found');
        throw Exception('No active session - user may need to re-authenticate');
      }
      
      // For large datasets, use a more efficient approach
      if (schoolIds.length > 100) {
        print('🔍 DEBUG: Large dataset detected (${schoolIds.length} schools), using optimized bulk delete');
        
        // Use a different approach for large datasets - delete all schools for this supervisor
        // and then reassign only the schools we want to keep (if any)
        print('🔍 DEBUG: Deleting ALL schools for supervisor $supervisorId');
        
        final result = await _client
            .from('supervisor_schools')
            .delete()
            .eq('supervisor_id', supervisorId)
            .timeout(const Duration(seconds: 60)); // Longer timeout for large operations
        
        print('🔍 DEBUG: Bulk delete all completed successfully');
        print('🔍 DEBUG: Delete result: $result');
        return;
      } else {
        // For smaller datasets, use the IN filter approach
        print('🔍 DEBUG: Small dataset (${schoolIds.length} schools), using IN filter delete');
        print('🔍 DEBUG: Query: DELETE FROM supervisor_schools WHERE supervisor_id = $supervisorId AND school_id IN (${schoolIds.take(5).join(', ')}${schoolIds.length > 5 ? '...' : ''})');
        
        final result = await _client
            .from('supervisor_schools')
            .delete()
            .eq('supervisor_id', supervisorId)
            .inFilter('school_id', schoolIds)
            .timeout(const Duration(seconds: 30));
        
        print('🔍 DEBUG: IN filter delete completed successfully');
        print('🔍 DEBUG: Delete result: $result');
        return;
      }
    } catch (e) {
      print('🔍 DEBUG: Error in removeSchoolsFromSupervisor: $e');
      print('🔍 DEBUG: Error type: ${e.runtimeType}');
      
      if (e.toString().contains('Failed to fetch')) {
        throw Exception('فشل في الاتصال بقاعدة البيانات. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.');
      } else {
        throw Exception('فشل في إزالة المدارس من المشرف: $e');
      }
    }
  }

  /// Get statistics for school assignments
  Future<Map<String, dynamic>> getSchoolAssignmentStats() async {
    try {
      // Get total schools count
      final schoolsCount = await _client
          .from('schools')
          .select('id')
          .then((response) => response.length);

      // Get assigned schools count
      final assignedSchoolsCount = await _client
          .from('supervisor_schools')
          .select('school_id')
          .then((response) => response.length);

      // Get unassigned schools count
      final unassignedSchoolsCount = schoolsCount - assignedSchoolsCount;

      // Get supervisors with schools count
      final supervisorsWithSchools = await _client
          .from('supervisor_schools')
          .select('supervisor_id')
          .then((response) {
        final supervisorIds = response.map((r) => r['supervisor_id']).toSet();
        return supervisorIds.length;
      });

      return {
        'total_schools': schoolsCount,
        'assigned_schools': assignedSchoolsCount,
        'unassigned_schools': unassignedSchoolsCount,
        'supervisors_with_schools': supervisorsWithSchools,
      };
    } catch (e) {
      throw Exception('فشل في جلب إحصائيات المدارس: $e');
    }
  }
}
