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

  /// Test specific supervisor IDs from the dashboard
  static Future<void> testDashboardSupervisorIds() async {
    print('🔍 Testing dashboard supervisor IDs...');
    
    // These are the supervisor IDs from the dashboard logs
    final dashboardSupervisorIds = [
      '11b70209-36dc-4e7c-a88d-ffc4940cc839',
      '1ee0e51c-101f-473e-bdca-4f9b4556931b',
      '48b4dac5-0eec-4f00-b25b-3815cf94140a',
      '77e3cc14-9c07-46e6-b4fd-921fdc6225db',
      'a9fb7e0b-cb09-4767-b160-b21414b8f433',
      'f3986092-3856-4fa3-9f5e-c2002f57f687',
    ];
    
    try {
      // Test 1: Check if these supervisor IDs exist
      print('🔍 Checking if supervisor IDs exist...');
      for (final supervisorId in dashboardSupervisorIds) {
        try {
          final response = await _client
              .from('supervisors')
              .select('id, username')
              .eq('id', supervisorId)
              .single();
          
          print('✅ Supervisor $supervisorId exists: ${response['username']}');
        } catch (e) {
          print('❌ Supervisor $supervisorId does not exist: $e');
        }
      }
      
      // Test 2: Check if there are any maintenance reports for these supervisors
      print('🔍 Checking maintenance reports for dashboard supervisors...');
      for (final supervisorId in dashboardSupervisorIds) {
        try {
          final response = await _client
              .from('maintenance_reports')
              .select('id, supervisor_id, school_name')
              .eq('supervisor_id', supervisorId)
              .limit(5);
          
          print('✅ Supervisor $supervisorId has ${response.length} maintenance reports');
          if (response.isNotEmpty) {
            print('   Sample: ${response.first}');
          }
        } catch (e) {
          print('❌ Error checking maintenance reports for $supervisorId: $e');
        }
      }
      
      // Test 3: Check if there are any reports for these supervisors
      print('🔍 Checking reports for dashboard supervisors...');
      for (final supervisorId in dashboardSupervisorIds) {
        try {
          final response = await _client
              .from('reports')
              .select('id, supervisor_id, type, school_name')
              .eq('supervisor_id', supervisorId)
              .limit(5);
          
          print('✅ Supervisor $supervisorId has ${response.length} reports');
          if (response.isNotEmpty) {
            print('   Sample: ${response.first}');
          }
        } catch (e) {
          print('❌ Error checking reports for $supervisorId: $e');
        }
      }
      
      // Test 4: Try inFilter with these specific IDs
      print('🔍 Testing inFilter with dashboard supervisor IDs...');
      try {
        final maintenanceResponse = await _client
            .from('maintenance_reports')
            .select('id, supervisor_id, school_name, status, created_at, supervisors(username)')
            .inFilter('supervisor_id', dashboardSupervisorIds)
            .limit(10);
        
        print('✅ inFilter maintenance query passed');
        print('   Found ${maintenanceResponse.length} maintenance reports');
        if (maintenanceResponse.isNotEmpty) {
          print('   Sample: ${maintenanceResponse.first}');
        }
      } catch (e) {
        print('❌ inFilter maintenance query failed: $e');
        print('   Error type: ${e.runtimeType}');
        print('   Error details: $e');
      }
      
      try {
        final reportsResponse = await _client
            .from('reports')
            .select('id, supervisor_id, type, status, priority, school_name, created_at, supervisors(username)')
            .inFilter('supervisor_id', dashboardSupervisorIds)
            .limit(10);
        
        print('✅ inFilter reports query passed');
        print('   Found ${reportsResponse.length} reports');
        if (reportsResponse.isNotEmpty) {
          print('   Sample: ${reportsResponse.first}');
        }
      } catch (e) {
        print('❌ inFilter reports query failed: $e');
        print('   Error type: ${e.runtimeType}');
        print('   Error details: $e');
      }
      
    } catch (e) {
      print('❌ Dashboard supervisor IDs test failed: $e');
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
    await testDashboardSupervisorIds(); // 🚀 NEW: Test specific dashboard IDs
    
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