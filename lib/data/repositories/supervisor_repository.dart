import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supervisor.dart';

class SupervisorRepository {
  final SupabaseClient _client;

  SupervisorRepository(this._client);

  Future<List<Supervisor>> fetchSupervisors({String? adminId}) async {
    var query = _client.from('supervisors').select('*');

    // Filter by admin ID if provided
    if (adminId != null) {
      query = query.eq('admin_id', adminId);
    }

    final response = await query.order('created_at', ascending: false);

    if (response is List) {
      return response.map((map) => Supervisor.fromMap(map)).toList();
    } else {
      throw Exception('Failed to load supervisors');
    }
  }

  /// Fetch supervisors for current admin
  Future<List<Supervisor>> fetchSupervisorsForCurrentAdmin() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // First, get the admin's database ID from the admins table
    final adminResponse = await _client
        .from('admins')
        .select('id')
        .eq('auth_user_id', user.id)
        .single();

    final adminId = adminResponse['id'] as String;

    // Fetch supervisors assigned to this admin
    return fetchSupervisors(adminId: adminId);
  }

  /// Creates a supervisor in the database
  ///
  /// This method creates a supervisor record in the supervisors table.
  /// The auth_user_id will be null initially and will be updated when the
  /// supervisor is registered in Supabase Auth through the admin dashboard.
  Future<void> createSupervisor(Supervisor supervisor) async {
    try {
      // Create the supervisor record
      final data = supervisor.toMap()..remove('id');

      // Insert the supervisor into the database
      await _client.from('supervisors').insert(data);

      // Note: The auth user creation is now handled manually in the Supabase dashboard
      // After creating the user in Supabase Auth, you'll need to update the supervisor record
      // with the auth_user_id using the updateSupervisor method
    } catch (e) {
      throw Exception('Failed to create supervisor: $e');
    }
  }

  Future<void> updateSupervisor(String id, Map<String, dynamic> updates) async {
    await _client.from('supervisors').update(updates).eq('id', id);
  }

  // Auth-related functionality is commented out for now
  /*
  /// Fetches a supervisor by their auth user ID
  /// 
  /// This is useful for the mobile app to fetch the supervisor's data
  /// after they log in with their email.
  Future<Supervisor> fetchSupervisorByAuthUserId(String authUserId) async {
    try {
      final response = await _client
          .from('supervisors')
          .select('*')
          .eq('auth_user_id', authUserId)
          .single();
      return Supervisor.fromMap(response);
    } catch (e) {
      throw Exception('Failed to fetch supervisor by auth user ID: $e');
    }
  }
  */

  Future<void> deleteSupervisor(String id) async {
    await _client.from('supervisors').delete().eq('id', id);
  }
}
