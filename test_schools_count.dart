import 'package:supabase_flutter/supabase_flutter.dart';

/// Test script to verify schools counting logic
void main() async {
  // Initialize Supabase (you'll need to add your credentials)
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  await testSchoolsCount();
}

Future<void> testSchoolsCount() async {
  try {
    final client = Supabase.instance.client;
    
    // Test with some supervisor IDs (replace with actual IDs)
    final supervisorIds = ['supervisor1', 'supervisor2', 'supervisor3'];
    
    print('🔍 Testing Schools Count Logic...');
    print('Supervisor IDs: $supervisorIds');
    
    // Method 1: Current implementation (should count unique schools)
    final response = await client
        .from('supervisor_schools')
        .select('school_id')
        .inFilter('supervisor_id', supervisorIds);
    
    final uniqueSchools = <String>{};
    for (final item in response) {
      final schoolId = item['school_id']?.toString();
      if (schoolId != null && schoolId.isNotEmpty) {
        uniqueSchools.add(schoolId);
      }
    }
    
    print('📊 Results:');
    print('  - Total records: ${response.length}');
    print('  - Unique schools: ${uniqueSchools.length}');
    print('  - Unique school IDs: ${uniqueSchools.toList()}');
    
    // Method 2: Count per supervisor (includes duplicates)
    final schoolsPerSupervisor = <String, int>{};
    for (final supervisorId in supervisorIds) {
      schoolsPerSupervisor[supervisorId] = response
          .where((item) => item['supervisor_id'] == supervisorId)
          .length;
    }
    
    print('  - Schools per supervisor: $schoolsPerSupervisor');
    print('  - Total if counting duplicates: ${schoolsPerSupervisor.values.fold(0, (sum, count) => sum + count)}');
    
    // Method 3: Verify with schools table
    if (uniqueSchools.isNotEmpty) {
      final schoolsResponse = await client
          .from('schools')
          .select('id')
          .inFilter('id', uniqueSchools.toList());
      
      final existingSchools = schoolsResponse
          .map((item) => item['id']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .toSet();
      
      print('  - Schools existing in schools table: ${existingSchools.length}');
      print('  - Missing schools: ${uniqueSchools.length - existingSchools.length}');
    }
    
  } catch (e) {
    print('❌ Error testing schools count: $e');
  }
} 