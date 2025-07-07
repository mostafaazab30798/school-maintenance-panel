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
    final response = await _client
        .from('schools')
        .select('*, supervisor_schools!inner(*)')
        .eq('supervisor_schools.supervisor_id', supervisorId)
        .order('name');

    return (response as List).map((data) => School.fromMap(data)).toList();
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
