import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Simple database connection test to diagnose query issues
class DatabaseConnectionTest {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Test basic database connection
  static Future<void> testConnection() async {
    print('🔍 Testing database connection...');
    
    try {
      // Test 1: Basic connection
      final response = await _client.from('supervisors').select('id').limit(1);
      print('✅ Basic connection test passed');
      print('   Response type: ${response.runtimeType}');
      print('   Response length: ${response is List ? response.length : 'N/A'}');
      
      // Test 2: Maintenance reports query
      await testMaintenanceReportsQuery();
      
      // Test 3: Reports query
      await testReportsQuery();
      
      print('✅ All database tests passed');
    } catch (e) {
      print('❌ Database connection test failed: $e');
      print('   Error type: ${e.runtimeType}');
      print('   Error details: $e');
    }
  }

  /// Test maintenance reports query
  static Future<void> testMaintenanceReportsQuery() async {
    print('🔍 Testing maintenance reports query...');
    
    try {
      // Test with simple query first
      final simpleResponse = await _client
          .from('maintenance_reports')
          .select('id, supervisor_id, school_name, status, created_at')
          .limit(5);
      
      print('✅ Simple maintenance query passed');
      print('   Found ${simpleResponse.length} records');
      
      // Test with supervisor join
      final joinResponse = await _client
          .from('maintenance_reports')
          .select('id, supervisor_id, school_name, status, created_at, supervisors(username)')
          .limit(5);
      
      print('✅ Maintenance query with supervisor join passed');
      print('   Found ${joinResponse.length} records');
      
      // Test with specific supervisor filter
      if (simpleResponse.isNotEmpty) {
        final supervisorId = simpleResponse.first['supervisor_id'];
        final filterResponse = await _client
            .from('maintenance_reports')
            .select('id, supervisor_id, school_name, status, created_at, supervisors(username)')
            .eq('supervisor_id', supervisorId)
            .limit(5);
        
        print('✅ Maintenance query with supervisor filter passed');
        print('   Found ${filterResponse.length} records for supervisor $supervisorId');
      }
      
    } catch (e) {
      print('❌ Maintenance reports query test failed: $e');
      print('   Error type: ${e.runtimeType}');
      print('   Error details: $e');
    }
  }

  /// Test reports query
  static Future<void> testReportsQuery() async {
    print('🔍 Testing reports query...');
    
    try {
      // Test with simple query first
      final simpleResponse = await _client
          .from('reports')
          .select('id, supervisor_id, type, status, priority, school_name, created_at')
          .limit(5);
      
      print('✅ Simple reports query passed');
      print('   Found ${simpleResponse.length} records');
      
      // Test with supervisor join
      final joinResponse = await _client
          .from('reports')
          .select('id, supervisor_id, type, status, priority, school_name, created_at, supervisors(username)')
          .limit(5);
      
      print('✅ Reports query with supervisor join passed');
      print('   Found ${joinResponse.length} records');
      
      // Test with specific supervisor filter
      if (simpleResponse.isNotEmpty) {
        final supervisorId = simpleResponse.first['supervisor_id'];
        final filterResponse = await _client
            .from('reports')
            .select('id, supervisor_id, type, status, priority, school_name, created_at, supervisors(username)')
            .eq('supervisor_id', supervisorId)
            .limit(5);
        
        print('✅ Reports query with supervisor filter passed');
        print('   Found ${filterResponse.length} records for supervisor $supervisorId');
      }
      
    } catch (e) {
      print('❌ Reports query test failed: $e');
      print('   Error type: ${e.runtimeType}');
      print('   Error details: $e');
    }
  }

  /// Test supervisor IDs query
  static Future<void> testSupervisorIdsQuery() async {
    print('🔍 Testing supervisor IDs query...');
    
    try {
      // Get some supervisor IDs
      final supervisorsResponse = await _client
          .from('supervisors')
          .select('id')
          .limit(5);
      
      if (supervisorsResponse.isNotEmpty) {
        final supervisorIds = supervisorsResponse.map((s) => s['id']).toList();
        print('✅ Found supervisor IDs: $supervisorIds');
        
        // Test inFilter with these IDs
        final maintenanceResponse = await _client
            .from('maintenance_reports')
            .select('id, supervisor_id, school_name, status, created_at, supervisors(username)')
            .inFilter('supervisor_id', supervisorIds)
            .limit(10);
        
        print('✅ inFilter query passed');
        print('   Found ${maintenanceResponse.length} maintenance reports');
        
        final reportsResponse = await _client
            .from('reports')
            .select('id, supervisor_id, type, status, priority, school_name, created_at, supervisors(username)')
            .inFilter('supervisor_id', supervisorIds)
            .limit(10);
        
        print('✅ inFilter reports query passed');
        print('   Found ${reportsResponse.length} reports');
      }
      
    } catch (e) {
      print('❌ Supervisor IDs query test failed: $e');
      print('   Error type: ${e.runtimeType}');
      print('   Error details: $e');
    }
  }

  /// Run all tests
  static Future<void> runAllTests() async {
    print('🚀 Starting comprehensive database connection tests...');
    print('=' * 60);
    
    await testConnection();
    await testSupervisorIdsQuery();
    
    print('=' * 60);
    print('🏁 Database tests completed');
  }
}

/// Usage:
/// 
/// ```dart
/// // Run all tests
/// await DatabaseConnectionTest.runAllTests();
/// 
/// // Or run individual tests
/// await DatabaseConnectionTest.testConnection();
/// await DatabaseConnectionTest.testMaintenanceReportsQuery();
/// await DatabaseConnectionTest.testReportsQuery();
/// await DatabaseConnectionTest.testSupervisorIdsQuery();
/// ``` 