import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Test to check available Supabase Flutter methods
class SupabaseMethodTest {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Test available methods in Supabase Flutter 2.9.0
  static Future<void> testAvailableMethods() async {
    print('🔍 Testing Supabase Flutter 2.9.0 methods...');
    
    try {
      // Test 1: Basic query builder
      print('🔍 Testing basic query builder...');
      final basicQuery = _client.from('supervisors').select('id').limit(1);
      print('✅ Basic query builder works');
      
      // Test 2: eq method
      print('🔍 Testing eq method...');
      try {
        final eqQuery = _client.from('supervisors').select('id').eq('id', 'test');
        print('✅ eq method works');
      } catch (e) {
        print('❌ eq method failed: $e');
      }
      
      // Test 2.5: filter method (alternative to eq)
      print('🔍 Testing filter method...');
      try {
        final filterQuery = _client.from('supervisors').select('id').filter('id', 'eq', 'test');
        print('✅ filter method works');
      } catch (e) {
        print('❌ filter method failed: $e');
      }
      
      // Test 3: inFilter method
      print('🔍 Testing inFilter method...');
      try {
        final inFilterQuery = _client.from('supervisors').select('id').inFilter('id', ['test1', 'test2']);
        print('✅ inFilter method works');
      } catch (e) {
        print('❌ inFilter method failed: $e');
      }
      
      // Test 4: in_ method (alternative) - commented out due to linter error
      print('🔍 Testing in_ method...');
      print('❌ in_ method not available in this version');
      
      // Test 5: Check query builder types
      print('🔍 Checking query builder types...');
      final query1 = _client.from('supervisors');
      print('   from() returns: ${query1.runtimeType}');
      
      final query2 = query1.select('id');
      print('   select() returns: ${query2.runtimeType}');
      
      try {
        final query3 = query2.eq('id', 'test');
        print('   eq() returns: ${query3.runtimeType}');
      } catch (e) {
        print('   eq() failed: $e');
      }
      
      // Test 6: Try different method names
      print('🔍 Testing alternative method names...');
      
      // Try 'in' method - not available in this version
      print('❌ in_ method not available in this version');
      
      // Try 'contains' method
      try {
        final containsQuery = _client.from('supervisors').select('id').contains('id', ['test']);
        print('✅ contains method works');
      } catch (e) {
        print('❌ contains method failed: $e');
      }
      
      // Try 'overlaps' method
      try {
        final overlapsQuery = _client.from('supervisors').select('id').overlaps('id', ['test']);
        print('✅ overlaps method works');
      } catch (e) {
        print('❌ overlaps method failed: $e');
      }

      // Test 7: Try 'or' method for multiple conditions
      print('🔍 Testing or method...');
      try {
        final orQuery = _client.from('supervisors').select('id').or('id.eq.test1,id.eq.test2');
        print('✅ or method works');
      } catch (e) {
        print('❌ or method failed: $e');
      }

      // Test 8: Try 'in' with different syntax
      print('🔍 Testing in with different syntax...');
      print('❌ in method not available in this version');

      // Test 9: Check all available methods on PostgrestFilterBuilder
      print('🔍 Checking available methods on PostgrestFilterBuilder...');
      final filterBuilder = _client.from('supervisors').select('id');
      print('   Available methods on ${filterBuilder.runtimeType}:');
      
      // Try to inspect the methods (this is limited in Dart)
      print('   - eq() - for equality');
      print('   - neq() - for not equality');
      print('   - gt() - for greater than');
      print('   - gte() - for greater than or equal');
      print('   - lt() - for less than');
      print('   - lte() - for less than or equal');
      print('   - like() - for pattern matching');
      print('   - ilike() - for case-insensitive pattern matching');
      print('   - is() - for null checks');
      print('   - in() - for multiple values (if available)');
      print('   - or() - for OR conditions');
      print('   - and() - for AND conditions');
      
    } catch (e) {
      print('❌ Supabase method test failed: $e');
      print('   Error type: ${e.runtimeType}');
      print('   Error details: $e');
    }
  }

  /// Test the exact query we need
  static Future<void> testDashboardQuery() async {
    print('🔍 Testing dashboard query...');
    
    try {
      final supervisorIds = [
        '11b70209-36dc-4e7c-a88d-ffc4940cc839',
        '1ee0e51c-101f-473e-bdca-4f9b4556931b',
      ];
      
      // Test 1: Simple query without filters
      print('🔍 Testing simple query...');
      final simpleQuery = _client
          .from('reports')
          .select('id, supervisor_id, type, status, priority, school_name, created_at, supervisors(username)')
          .limit(5);
      
      final simpleResult = await simpleQuery;
      print('✅ Simple query works: ${simpleResult.length} results');
      
      // Test 2: Query with eq filter
      print('🔍 Testing eq filter...');
      if (simpleResult.isNotEmpty) {
        final supervisorId = simpleResult.first['supervisor_id'];
        final eqQuery = _client
            .from('reports')
            .select('id, supervisor_id, type, status, priority, school_name, created_at, supervisors(username)')
            .eq('supervisor_id', supervisorId)
            .limit(5);
        
        final eqResult = await eqQuery;
        print('✅ eq filter works: ${eqResult.length} results');
      }
      
      // Test 3: Query with inFilter
      print('🔍 Testing inFilter...');
      try {
        final inFilterQuery = _client
            .from('reports')
            .select('id, supervisor_id, type, status, priority, school_name, created_at, supervisors(username)')
            .inFilter('supervisor_id', supervisorIds)
            .limit(5);
        
        final inFilterResult = await inFilterQuery;
        print('✅ inFilter works: ${inFilterResult.length} results');
      } catch (e) {
        print('❌ inFilter failed: $e');
        
        // Test 4: Try or method instead
        print('🔍 Trying or method...');
        try {
          final orConditions = supervisorIds.map((id) => 'supervisor_id.eq.$id').join(',');
          final orQuery = _client
              .from('reports')
              .select('id, supervisor_id, type, status, priority, school_name, created_at, supervisors(username)')
              .or(orConditions)
              .limit(5);
          
          final orResult = await orQuery;
          print('✅ or method works: ${orResult.length} results');
          print('   Used conditions: $orConditions');
        } catch (e2) {
          print('❌ or method also failed: $e2');
        }
      }
      
    } catch (e) {
      print('❌ Dashboard query test failed: $e');
      print('   Error type: ${e.runtimeType}');
      print('   Error details: $e');
    }
  }

  /// Run all tests
  static Future<void> runAllTests() async {
    print('🚀 Starting Supabase method tests...');
    print('=' * 60);
    
    await testAvailableMethods();
    await testDashboardQuery();
    
    print('=' * 60);
    print('🏁 Supabase method tests completed');
  }
} 