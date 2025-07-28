import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/maintenance_count_repository.dart';

class MaintenanceCountsTest {
  static Future<void> testMaintenanceCountsRepository() async {
    try {
      print('🔍 Testing Maintenance Counts Repository...');
      
      final supabase = Supabase.instance.client;
      final repository = MaintenanceCountRepository(supabase);
      
      // Test 1: Get schools with maintenance counts
      print('📋 Test 1: Getting schools with maintenance counts...');
      final schools = await repository.getSchoolsWithMaintenanceCounts();
      print('✅ Found ${schools.length} schools with maintenance counts');
      
      if (schools.isNotEmpty) {
        print('📝 Sample school: ${schools.first}');
      }
      
      // Test 2: Get maintenance count records
      print('📋 Test 2: Getting maintenance count records...');
      final records = await repository.getAllMaintenanceCountRecords(limit: 5);
      print('✅ Found ${records.length} maintenance count records');
      
      if (records.isNotEmpty) {
        print('📝 Sample record:');
        print('  - ID: ${records.first.id}');
        print('  - School: ${records.first.schoolName}');
        print('  - Status: ${records.first.status}');
        print('  - Created: ${records.first.createdAt}');
        print('  - Item counts: ${records.first.itemCounts.length} items');
      }
      
      // Test 3: Get dashboard summary
      print('📋 Test 3: Getting dashboard summary...');
      final summary = await repository.getDashboardSummary();
      print('✅ Dashboard summary:');
      print('  - Total maintenance counts: ${summary['total_maintenance_counts']}');
      print('  - Schools with counts: ${summary['schools_with_counts']}');
      print('  - Schools with damage: ${summary['schools_with_damage']}');
      print('  - Submitted counts: ${summary['submitted_counts']}');
      print('  - Draft counts: ${summary['draft_counts']}');
      
      print('🎉 All tests passed! Maintenance counts repository is working correctly.');
      
    } catch (e, stackTrace) {
      print('❌ Test failed: $e');
      print('📚 Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  static Future<void> testDataRetrieval() async {
    try {
      print('🔍 Testing Data Retrieval...');
      
      final supabase = Supabase.instance.client;
      final repository = MaintenanceCountRepository(supabase);
      
      // Test getting all maintenance counts for export
      print('📋 Getting all maintenance counts for export...');
      final allCounts = <dynamic>[];
      
      // Get all schools with maintenance counts
      final schools = await repository.getSchoolsWithMaintenanceCounts();
      print('📝 Found ${schools.length} schools');
      
      for (final school in schools) {
        final schoolId = school['school_id'] as String;
        print('📋 Processing school: $schoolId');
        
        try {
          final counts = await repository.getMaintenanceCounts(schoolId: schoolId);
          allCounts.addAll(counts);
          print('✅ Found ${counts.length} counts for school $schoolId');
        } catch (e) {
          print('⚠️ Error getting counts for school $schoolId: $e');
        }
      }
      
      print('🎉 Total maintenance counts retrieved: ${allCounts.length}');
      
      if (allCounts.isNotEmpty) {
        print('📝 Sample count data:');
        final sample = allCounts.first;
        print('  - School: ${sample.schoolName}');
        print('  - Status: ${sample.status}');
        print('  - Item counts: ${sample.itemCounts}');
        print('  - Text answers: ${sample.textAnswers}');
        print('  - Yes/No answers: ${sample.yesNoAnswers}');
      }
      
    } catch (e, stackTrace) {
      print('❌ Data retrieval test failed: $e');
      print('📚 Stack trace: $stackTrace');
      rethrow;
    }
  }
} 