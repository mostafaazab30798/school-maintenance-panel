import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Initialize Supabase (you'll need to add your credentials)
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  final client = Supabase.instance.client;

  try {
    // Test 1: Check if supervisors table exists and has data
    print('🔍 Testing supervisors table...');
    
    final supervisorsResponse = await client
        .from('supervisors')
        .select('id, username, email, auth_user_id')
        .limit(5);

    print('🔍 Found ${supervisorsResponse.length} supervisors:');
    for (final supervisor in supervisorsResponse) {
      print('  - ID: ${supervisor['id']}');
      print('    Username: ${supervisor['username']}');
      print('    Email: ${supervisor['email']}');
      print('    Auth User ID: ${supervisor['auth_user_id']}');
      print('');
    }

    // Test 2: Check if admins table exists and has data
    print('🔍 Testing admins table...');
    
    final adminsResponse = await client
        .from('admins')
        .select('id, name, email, role, auth_user_id')
        .limit(5);

    print('🔍 Found ${adminsResponse.length} admins:');
    for (final admin in adminsResponse) {
      print('  - ID: ${admin['id']}');
      print('    Name: ${admin['name']}');
      print('    Email: ${admin['email']}');
      print('    Role: ${admin['role']}');
      print('    Auth User ID: ${admin['auth_user_id']}');
      print('');
    }

    // Test 3: Check if password_change_logs table exists
    print('🔍 Testing password_change_logs table...');
    
    try {
      final logsResponse = await client
          .from('password_change_logs')
          .select('*')
          .limit(5);

      print('🔍 Found ${logsResponse.length} password change logs');
    } catch (e) {
      print('❌ password_change_logs table does not exist or has issues: $e');
    }

  } catch (e) {
    print('❌ Error during testing: $e');
  }
} 