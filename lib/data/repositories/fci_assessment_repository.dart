import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fci_assessment.dart';

class FciAssessmentRepository {
  final SupabaseClient _client;

  FciAssessmentRepository(this._client);

  /// Helper method to fetch supervisor names by IDs
  Future<Map<String, String>> _fetchSupervisorNames(Set<String> supervisorIds) async {
    if (supervisorIds.isEmpty) return {};
    
    try {
      final supervisorsResponse = await _client
          .from('supervisors')
          .select('id, username')
          .inFilter('id', supervisorIds.toList());
      
      final Map<String, String> supervisorNames = {};
      for (final supervisor in supervisorsResponse) {
        final id = supervisor['id'] as String?;
        final username = supervisor['username'] as String?;
        if (id != null && username != null) {
          supervisorNames[id] = username;
        }
      }
      return supervisorNames;
    } catch (e) {
      print('⚠️ Warning: Could not fetch supervisor names: $e');
      return {};
    }
  }

  /// Get all FCI assessments for dashboard summary
  Future<List<FciAssessment>> getAllAssessments({List<String>? supervisorIds}) async {
    try {
      var query = _client.from('fci_assessments').select('*');

      // 🚀 FILTER: Only show FCI assessments from supervisors assigned to the current admin
      if (supervisorIds != null && supervisorIds.isNotEmpty) {
        query = query.inFilter('supervisor_id', supervisorIds);
        print('🔍 FCI Assessment Debug: Filtering by ${supervisorIds.length} supervisor IDs: $supervisorIds');
      } else {
        print('🔍 FCI Assessment Debug: No supervisor IDs provided - showing no assessments');
        return []; // Return empty list if no supervisor IDs (admin has no assigned supervisors)
      }

      final response = await query.order('created_at', ascending: false);
      
      if (response == null) return [];
      
      print('🔍 FCI Assessment Debug: Found ${response.length} assessments after filtering');
      
      // Get unique supervisor IDs to fetch their names
      final Set<String> supervisorIdsSet = {};
      for (final assessment in response) {
        final supervisorId = assessment['supervisor_id'] as String?;
        if (supervisorId != null && supervisorId.isNotEmpty) {
          supervisorIdsSet.add(supervisorId);
        }
      }
      
      // Fetch supervisor names
      final Map<String, String> supervisorNames = await _fetchSupervisorNames(supervisorIdsSet);
      
      return (response as List).map((json) {
        final supervisorId = json['supervisor_id'] as String? ?? '';
        final supervisorName = supervisorNames[supervisorId] ?? '';
        
        // Create a new JSON object with supervisor_name included
        final modifiedJson = Map<String, dynamic>.from(json);
        modifiedJson['supervisor_name'] = supervisorName;
        
        return FciAssessment.fromJson(modifiedJson);
      }).toList();
    } catch (e) {
      print('❌ Error fetching FCI assessments: $e');
      return [];
    }
  }

  /// Get FCI assessments for a specific school
  Future<List<FciAssessment>> getAssessmentsBySchool(String schoolId, {List<String>? supervisorIds}) async {
    try {
      var query = _client
          .from('fci_assessments')
          .select('*')
          .eq('school_id', schoolId);

      // 🚀 FILTER: Only show FCI assessments from supervisors assigned to the current admin
      if (supervisorIds != null && supervisorIds.isNotEmpty) {
        query = query.inFilter('supervisor_id', supervisorIds);
      } else {
        return []; // Return empty list if no supervisor IDs
      }

      final response = await query.order('created_at', ascending: false);

      if (response == null) return [];
      
      // Get unique supervisor IDs to fetch their names
      final Set<String> supervisorIdsSet = {};
      for (final assessment in response) {
        final supervisorId = assessment['supervisor_id'] as String?;
        if (supervisorId != null && supervisorId.isNotEmpty) {
          supervisorIdsSet.add(supervisorId);
        }
      }
      
      // Fetch supervisor names
      final Map<String, String> supervisorNames = await _fetchSupervisorNames(supervisorIdsSet);
      
      return (response as List).map((json) {
        final supervisorId = json['supervisor_id'] as String? ?? '';
        final supervisorName = supervisorNames[supervisorId] ?? '';
        
        // Create a new JSON object with supervisor_name included
        final modifiedJson = Map<String, dynamic>.from(json);
        modifiedJson['supervisor_name'] = supervisorName;
        
        return FciAssessment.fromJson(modifiedJson);
      }).toList();
    } catch (e) {
      print('❌ Error fetching FCI assessments for school $schoolId: $e');
      return [];
    }
  }

  /// Get FCI assessments by supervisor
  Future<List<FciAssessment>> getAssessmentsBySupervisor(String supervisorId, {List<String>? adminSupervisorIds}) async {
    try {
      // 🚀 FILTER: Only allow access if the supervisor is assigned to the current admin
      if (adminSupervisorIds != null && !adminSupervisorIds.contains(supervisorId)) {
        print('🔍 FCI Assessment Debug: Supervisor $supervisorId not assigned to current admin');
        return [];
      }

      final response = await _client
          .from('fci_assessments')
          .select('*')
          .eq('supervisor_id', supervisorId)
          .order('created_at', ascending: false);

      if (response == null) return [];
      
      // Fetch supervisor name for this specific supervisor
      String supervisorName = '';
      try {
        final supervisorResponse = await _client
            .from('supervisors')
            .select('username')
            .eq('id', supervisorId)
            .single();
        
        supervisorName = supervisorResponse['username'] as String? ?? '';
      } catch (e) {
        print('⚠️ Warning: Could not fetch supervisor name: $e');
      }
      
      return (response as List).map((json) {
        // Create a new JSON object with supervisor_name included
        final modifiedJson = Map<String, dynamic>.from(json);
        modifiedJson['supervisor_name'] = supervisorName;
        
        return FciAssessment.fromJson(modifiedJson);
      }).toList();
    } catch (e) {
      print('❌ Error fetching FCI assessments for supervisor $supervisorId: $e');
      return [];
    }
  }

  /// Get dashboard summary statistics
  Future<Map<String, int>> getDashboardSummary({List<String>? supervisorIds}) async {
    try {
      print('🔍 FCI Assessment Debug: Starting getDashboardSummary');
      print('🔍 FCI Assessment Debug: Supervisor IDs filter: $supervisorIds');
      
      // 🚀 FILTER: Only show FCI assessments from supervisors assigned to the current admin
      var query = _client.from('fci_assessments').select('status, school_id, supervisor_id');

      if (supervisorIds != null && supervisorIds.isNotEmpty) {
        query = query.inFilter('supervisor_id', supervisorIds);
        print('🔍 FCI Assessment Debug: Applied supervisor filter for ${supervisorIds.length} supervisors');
      } else {
        print('🔍 FCI Assessment Debug: No supervisor IDs provided - showing no assessments');
        return {
          'total_assessments': 0,
          'submitted_assessments': 0,
          'draft_assessments': 0,
          'schools_with_assessments': 0,
        };
      }

      final response = await query;
      
      print('🔍 FCI Assessment Debug: Database response length: ${response?.length ?? 0}');
      if (response != null && response.isNotEmpty) {
        print('🔍 FCI Assessment Debug: Sample response: ${response.first}');
      }

      if (response == null || response.isEmpty) {
        print('🔍 FCI Assessment Debug: No data found, returning zeros');
        return {
          'total_assessments': 0,
          'submitted_assessments': 0,
          'draft_assessments': 0,
          'schools_with_assessments': 0,
        };
      }

      final Set<String> schoolsWithAssessments = {};
      int totalAssessments = response.length;
      int submittedAssessments = 0;
      int draftAssessments = 0;

      for (final assessment in response) {
        final schoolId = assessment['school_id'] as String?;
        final status = assessment['status'] as String?;

        if (schoolId != null) {
          schoolsWithAssessments.add(schoolId);
        }

        if (status == 'submitted') {
          submittedAssessments++;
        } else if (status == 'draft') {
          draftAssessments++;
        }
      }

      final result = {
        'total_assessments': totalAssessments,
        'submitted_assessments': submittedAssessments,
        'draft_assessments': draftAssessments,
        'schools_with_assessments': schoolsWithAssessments.length,
      };
      
      print('🔍 FCI Assessment Debug: Final result: $result');
      return result;
    } catch (e) {
      print('❌ Error fetching FCI assessment summary: $e');
      return {
        'total_assessments': 0,
        'submitted_assessments': 0,
        'draft_assessments': 0,
        'schools_with_assessments': 0,
      };
    }
  }

  /// Force refresh dashboard summary statistics (bypasses any caching)
  Future<Map<String, int>> getDashboardSummaryForceRefresh({List<String>? supervisorIds}) async {
    try {
      print('🔍 FCI Assessment Debug: Starting getDashboardSummaryForceRefresh');
      print('🔍 FCI Assessment Debug: Supervisor IDs filter: $supervisorIds');
      
      // 🚀 FILTER: Only show FCI assessments from supervisors assigned to the current admin
      var query = _client
          .from('fci_assessments')
          .select('status, school_id, supervisor_id');

      if (supervisorIds != null && supervisorIds.isNotEmpty) {
        query = query.inFilter('supervisor_id', supervisorIds);
        print('🔍 FCI Assessment Debug: Applied supervisor filter for ${supervisorIds.length} supervisors');
      } else {
        print('🔍 FCI Assessment Debug: No supervisor IDs provided - showing no assessments');
        return {
          'total_assessments': 0,
          'submitted_assessments': 0,
          'draft_assessments': 0,
          'schools_with_assessments': 0,
        };
      }

      final response = await query.order('created_at', ascending: false);

      print('🔍 FCI Assessment Debug: Database response length: ${response?.length ?? 0}');
      if (response != null && response.isNotEmpty) {
        print('🔍 FCI Assessment Debug: Sample response: ${response.first}');
      }

      if (response == null || response.isEmpty) {
        print('🔍 FCI Assessment Debug: No data found, returning zeros');
        return {
          'total_assessments': 0,
          'submitted_assessments': 0,
          'draft_assessments': 0,
          'schools_with_assessments': 0,
        };
      }

      final Set<String> schoolsWithAssessments = {};
      int totalAssessments = response.length;
      int submittedAssessments = 0;
      int draftAssessments = 0;

      for (final assessment in response) {
        final schoolId = assessment['school_id'] as String?;
        final status = assessment['status'] as String?;

        if (schoolId != null) {
          schoolsWithAssessments.add(schoolId);
        }

        if (status == 'submitted') {
          submittedAssessments++;
        } else if (status == 'draft') {
          draftAssessments++;
        }
      }

      final result = {
        'total_assessments': totalAssessments,
        'submitted_assessments': submittedAssessments,
        'draft_assessments': draftAssessments,
        'schools_with_assessments': schoolsWithAssessments.length,
      };
      
      print('🔍 FCI Assessment Debug: Final result: $result');
      return result;
    } catch (e) {
      print('❌ Error fetching FCI assessment summary (force refresh): $e');
      return {
        'total_assessments': 0,
        'submitted_assessments': 0,
        'draft_assessments': 0,
        'schools_with_assessments': 0,
      };
    }
  }

  /// Get schools with FCI assessments
  Future<List<Map<String, dynamic>>> getSchoolsWithAssessments({List<String>? supervisorIds}) async {
    try {
      var query = _client
          .from('fci_assessments')
          .select('school_id, school_name, status, created_at, supervisor_id');

      if (supervisorIds != null && supervisorIds.isNotEmpty) {
        query = query.inFilter('supervisor_id', supervisorIds);
      }

      final response = await query.order('created_at', ascending: false);

      if (response == null) return [];

      // Get unique supervisor IDs to fetch their names
      final Set<String> supervisorIdsSet = {};
      for (final assessment in response) {
        final supervisorId = assessment['supervisor_id'] as String?;
        if (supervisorId != null && supervisorId.isNotEmpty) {
          supervisorIdsSet.add(supervisorId);
        }
      }
      
      // Fetch supervisor names
      final Map<String, String> supervisorNames = await _fetchSupervisorNames(supervisorIdsSet);

      // Group by school and get the latest assessment
      final Map<String, Map<String, dynamic>> schoolsMap = {};
      
      for (final assessment in response) {
        final schoolId = assessment['school_id'] as String;
        final supervisorId = assessment['supervisor_id'] as String? ?? '';
        final supervisorName = supervisorNames[supervisorId] ?? '';
        
        if (!schoolsMap.containsKey(schoolId)) {
          schoolsMap[schoolId] = {
            'school_id': schoolId,
            'school_name': assessment['school_name'],
            'latest_assessment_date': assessment['created_at'],
            'status': assessment['status'],
            'supervisor_name': supervisorName,
            'assessment_count': 1,
          };
        } else {
          // Update count and check if this is a more recent assessment
          schoolsMap[schoolId]!['assessment_count'] = 
              (schoolsMap[schoolId]!['assessment_count'] as int) + 1;
          
          final currentDate = DateTime.parse(assessment['created_at']);
          final existingDate = DateTime.parse(schoolsMap[schoolId]!['latest_assessment_date']);
          
          if (currentDate.isAfter(existingDate)) {
            schoolsMap[schoolId]!['latest_assessment_date'] = assessment['created_at'];
            schoolsMap[schoolId]!['status'] = assessment['status'];
            schoolsMap[schoolId]!['supervisor_name'] = supervisorName;
          }
        }
      }

      return schoolsMap.values.toList();
    } catch (e) {
      print('❌ Error fetching schools with FCI assessments: $e');
      return [];
    }
  }

  /// Create a new FCI assessment
  Future<FciAssessment?> createAssessment({
    required String schoolId,
    required String schoolName,
    required String supervisorId,
    Map<String, dynamic>? categoryAssessments,
    Map<String, dynamic>? sectionPhotos,
  }) async {
    try {
      final response = await _client.from('fci_assessments').insert({
        'school_id': schoolId,
        'school_name': schoolName,
        'supervisor_id': supervisorId,
        'category_assessments': categoryAssessments ?? {},
        'section_photos': sectionPhotos ?? {},
        'status': 'draft',
      }).select().single();

      return FciAssessment.fromJson(response);
    } catch (e) {
      print('❌ Error creating FCI assessment: $e');
      return null;
    }
  }

  /// Update an FCI assessment
  Future<FciAssessment?> updateAssessment({
    required String id,
    Map<String, dynamic>? categoryAssessments,
    Map<String, dynamic>? sectionPhotos,
    String? status,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (categoryAssessments != null) {
        updateData['category_assessments'] = categoryAssessments;
      }
      if (sectionPhotos != null) {
        updateData['section_photos'] = sectionPhotos;
      }
      if (status != null) {
        updateData['status'] = status;
      }

      final response = await _client
          .from('fci_assessments')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      return FciAssessment.fromJson(response);
    } catch (e) {
      print('❌ Error updating FCI assessment: $e');
      return null;
    }
  }

  /// Delete an FCI assessment
  Future<bool> deleteAssessment(String id) async {
    try {
      await _client.from('fci_assessments').delete().eq('id', id);
      return true;
    } catch (e) {
      print('❌ Error deleting FCI assessment: $e');
      return false;
    }
  }

  /// Debug method to check all FCI assessments in the database
  Future<void> debugAllFciAssessments() async {
    try {
      print('🔍 FCI Assessment Debug: Checking all assessments in database...');
      
      final allAssessments = await _client
          .from('fci_assessments')
          .select('id, school_id, supervisor_id, status, created_at')
          .order('created_at', ascending: false);
      
      print('🔍 FCI Assessment Debug: Total assessments in database: ${allAssessments.length}');
      
      if (allAssessments.isNotEmpty) {
        print('🔍 FCI Assessment Debug: Sample assessments:');
        for (int i = 0; i < allAssessments.length && i < 5; i++) {
          final assessment = allAssessments[i];
          print('  ${i + 1}. ID: ${assessment['id']}, School: ${assessment['school_id']}, Supervisor: ${assessment['supervisor_id']}, Status: ${assessment['status']}');
        }
      }
      
      // Get unique supervisor IDs
      final Set<String> uniqueSupervisorIds = {};
      for (final assessment in allAssessments) {
        final supervisorId = assessment['supervisor_id'] as String?;
        if (supervisorId != null && supervisorId.isNotEmpty) {
          uniqueSupervisorIds.add(supervisorId);
        }
      }
      
      print('🔍 FCI Assessment Debug: Unique supervisor IDs in assessments: $uniqueSupervisorIds');
      
    } catch (e) {
      print('❌ Error in debugAllFciAssessments: $e');
    }
  }
} 