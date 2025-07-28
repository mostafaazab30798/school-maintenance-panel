import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // Initialize Supabase
  await dotenv.load(fileName: ".env");
  final String baseUrl = dotenv.env['SUPBASE_URL'] ?? '';
  final String apiKey = dotenv.env['SUPBASE_ANONKEY'] ?? '';
  
  await Supabase.initialize(
    url: baseUrl,
    anonKey: apiKey,
  );
  
  final client = Supabase.instance.client;
  
  print('🔍 Testing FCI Assessment Data...');
  
  try {
    // Test 1: Get all FCI assessments
    final allAssessments = await client
        .from('fci_assessments')
        .select('*');
    
    print('📊 Total FCI assessments in database: ${allAssessments.length}');
    
    if (allAssessments.isNotEmpty) {
      print('📋 Sample assessment: ${allAssessments.first}');
    }
    
    // Test 2: Get all supervisors
    final supervisors = await client
        .from('supervisors')
        .select('id, username, admin_id');
    
    print('👥 Total supervisors: ${supervisors.length}');
    
    if (supervisors.isNotEmpty) {
      print('👤 Sample supervisor: ${supervisors.first}');
    }
    
    // Test 3: Get all admins
    final admins = await client
        .from('admins')
        .select('id, username, role');
    
    print('👨‍💼 Total admins: ${admins.length}');
    
    if (admins.isNotEmpty) {
      print('👨‍💼 Sample admin: ${admins.first}');
    }
    
    // Test 4: Check FCI assessments by status
    int submitted = 0;
    int draft = 0;
    int other = 0;
    
    for (final assessment in allAssessments) {
      final status = assessment['status'] as String?;
      if (status == 'submitted') {
        submitted++;
      } else if (status == 'draft') {
        draft++;
      } else {
        other++;
      }
    }
    
    print('📈 FCI Assessment Status Breakdown:');
    print('   Submitted: $submitted');
    print('   Draft: $draft');
    print('   Other: $other');
    print('   Total: ${allAssessments.length}');
    
    // Test 5: Check unique schools
    final Set<String> uniqueSchools = {};
    for (final assessment in allAssessments) {
      final schoolId = assessment['school_id'] as String?;
      if (schoolId != null) {
        uniqueSchools.add(schoolId);
      }
    }
    
    print('🏫 Unique schools with FCI assessments: ${uniqueSchools.length}');
    
  } catch (e) {
    print('❌ Error: $e');
  }
} 