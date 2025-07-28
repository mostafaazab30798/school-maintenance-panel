import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Debug test for FCI assessments to identify the issue with dashboard numbers
class FciAssessmentDebugTest {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Test FCI assessments data and queries
  static Future<void> testFciAssessments() async {
    print('🔍 Testing FCI assessments data...');
    
    try {
      // Test 1: Check if table exists and has data
      await testBasicFciQuery();
      
      // Test 2: Check supervisor filtering
      await testSupervisorFiltering();
      
      // Test 3: Check status counting
      await testStatusCounting();
      
      // Test 4: Check schools counting
      await testSchoolsCounting();
      
      print('✅ All FCI assessment tests completed');
    } catch (e) {
      print('❌ FCI assessment test failed: $e');
      print('   Error type: ${e.runtimeType}');
      print('   Error details: $e');
    }
  }

  /// Test basic FCI query
  static Future<void> testBasicFciQuery() async {
    print('🔍 Testing basic FCI query...');
    
    try {
      // Get all FCI assessments
      final allAssessments = await _client
          .from('fci_assessments')
          .select('*');
      
      print('✅ Basic FCI query passed');
      print('   Total assessments in database: ${allAssessments.length}');
      
      if (allAssessments.isNotEmpty) {
        print('   Sample assessment: ${allAssessments.first}');
      }
      
    } catch (e) {
      print('❌ Basic FCI query failed: $e');
    }
  }

  /// Test supervisor filtering
  static Future<void> testSupervisorFiltering() async {
    print('🔍 Testing supervisor filtering...');
    
    try {
      // Get all supervisors first
      final supervisors = await _client
          .from('supervisors')
          .select('id, username')
          .limit(5);
      
      print('   Found ${supervisors.length} supervisors for testing');
      
      if (supervisors.isNotEmpty) {
        final supervisorId = supervisors.first['id'];
        print('   Testing with supervisor ID: $supervisorId');
        
        // Test FCI assessments for this supervisor
        final supervisorAssessments = await _client
            .from('fci_assessments')
            .select('*')
            .eq('supervisor_id', supervisorId);
        
        print('   FCI assessments for supervisor $supervisorId: ${supervisorAssessments.length}');
        
        // Test the dashboard summary method
        final summary = await getDashboardSummary([supervisorId]);
        print('   Dashboard summary for supervisor $supervisorId: $summary');
      }
      
    } catch (e) {
      print('❌ Supervisor filtering test failed: $e');
    }
  }

  /// Test status counting
  static Future<void> testStatusCounting() async {
    print('🔍 Testing status counting...');
    
    try {
      // Get all assessments with status
      final assessments = await _client
          .from('fci_assessments')
          .select('status');
      
      int submitted = 0;
      int draft = 0;
      int other = 0;
      
      for (final assessment in assessments) {
        final status = assessment['status'] as String?;
        if (status == 'submitted') {
          submitted++;
        } else if (status == 'draft') {
          draft++;
        } else {
          other++;
        }
      }
      
      print('   Status breakdown:');
      print('     Submitted: $submitted');
      print('     Draft: $draft');
      print('     Other: $other');
      print('     Total: ${assessments.length}');
      
    } catch (e) {
      print('❌ Status counting test failed: $e');
    }
  }

  /// Test schools counting
  static Future<void> testSchoolsCounting() async {
    print('🔍 Testing schools counting...');
    
    try {
      // Get all assessments with school_id
      final assessments = await _client
          .from('fci_assessments')
          .select('school_id');
      
      final Set<String> uniqueSchools = {};
      for (final assessment in assessments) {
        final schoolId = assessment['school_id'] as String?;
        if (schoolId != null) {
          uniqueSchools.add(schoolId);
        }
      }
      
      print('   Schools with assessments: ${uniqueSchools.length}');
      print('   Total assessments: ${assessments.length}');
      
    } catch (e) {
      print('❌ Schools counting test failed: $e');
    }
  }

  /// Replicate the dashboard summary method
  static Future<Map<String, int>> getDashboardSummary(List<String> supervisorIds) async {
    try {
      var query = _client.from('fci_assessments').select('status, school_id');

      if (supervisorIds.isNotEmpty) {
        query = query.inFilter('supervisor_id', supervisorIds);
      }

      final response = await query;

      if (response == null || response.isEmpty) {
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
        final schoolId = assessment['school_id'] as String;
        final status = assessment['status'] as String;

        schoolsWithAssessments.add(schoolId);

        if (status == 'submitted') {
          submittedAssessments++;
        } else if (status == 'draft') {
          draftAssessments++;
        }
      }

      return {
        'total_assessments': totalAssessments,
        'submitted_assessments': submittedAssessments,
        'draft_assessments': draftAssessments,
        'schools_with_assessments': schoolsWithAssessments.length,
      };
    } catch (e) {
      print('❌ Error in getDashboardSummary: $e');
      return {
        'total_assessments': 0,
        'submitted_assessments': 0,
        'draft_assessments': 0,
        'schools_with_assessments': 0,
      };
    }
  }
}

void main() async {
  // Initialize Supabase
  await dotenv.load(fileName: ".env");
  final String baseUrl = dotenv.env['SUPBASE_URL'] ?? '';
  final String apiKey = dotenv.env['SUPBASE_ANONKEY'] ?? '';
  
  await Supabase.initialize(
    url: baseUrl,
    anonKey: apiKey,
  );
  
  // Run the test
  await FciAssessmentDebugTest.testFciAssessments();
} 