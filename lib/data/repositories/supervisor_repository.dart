import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supervisor.dart';
import '../models/technician.dart';

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

  /// Update supervisor technicians list
  Future<void> updateSupervisorTechnicians(
    String supervisorId,
    List<String> technicians,
  ) async {
    // Validate technician names
    final validTechnicians = technicians
        .where((name) => name.trim().isNotEmpty)
        .map((name) => name.trim())
        .toList();

    await _client
        .from('supervisors')
        .update({'technicians': validTechnicians}).eq('id', supervisorId);
  }

  /// Add a single technician to supervisor
  Future<void> addTechnicianToSupervisor(
    String supervisorId,
    String technicianName,
  ) async {
    final trimmedName = technicianName.trim();
    if (trimmedName.isEmpty) return;

    // Get current supervisor data
    final response = await _client
        .from('supervisors')
        .select('technicians')
        .eq('id', supervisorId)
        .single();

    final currentTechnicians = _parseTechnicians(response['technicians']);

    // Add if not already exists
    if (!currentTechnicians.contains(trimmedName)) {
      final updatedTechnicians = [...currentTechnicians, trimmedName];
      await updateSupervisorTechnicians(supervisorId, updatedTechnicians);
    }
  }

  /// Remove a technician from supervisor
  Future<void> removeTechnicianFromSupervisor(
    String supervisorId,
    String technicianName,
  ) async {
    // Get current supervisor data
    final response = await _client
        .from('supervisors')
        .select('technicians')
        .eq('id', supervisorId)
        .single();

    final currentTechnicians = _parseTechnicians(response['technicians']);
    final updatedTechnicians = currentTechnicians
        .where((name) => name != technicianName.trim())
        .toList();

    await updateSupervisorTechnicians(supervisorId, updatedTechnicians);
  }

  static List<String> _parseTechnicians(dynamic techniciansData) {
    if (techniciansData == null) return [];
    if (techniciansData is List) {
      return techniciansData.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Update supervisor technicians with detailed information
  Future<void> updateSupervisorTechniciansDetailed(
    String supervisorId,
    List<Technician> technicians,
  ) async {
    print(
        '🔥 DB: updateSupervisorTechniciansDetailed called for supervisor $supervisorId');
    print('🔥 DB: Input technicians count: ${technicians.length}');

    // Validate and clean technician data
    final validTechnicians = technicians
        .where((tech) => tech.name.trim().isNotEmpty)
        .map((tech) => tech.copyWith(
              name: tech.name.trim(),
              workId: tech.workId.trim(),
              profession: tech.profession.trim(),
              phoneNumber: tech.phoneNumber.trim(),
            ))
        .toList();

    print('🔥 DB: Valid technicians count: ${validTechnicians.length}');
    print(
        '🔥 DB: Valid technicians: ${validTechnicians.map((t) => t.name).toList()}');

    // Convert to JSON format for database storage
    final techniciansData =
        validTechnicians.map((tech) => tech.toMap()).toList();

    print('🔥 DB: About to update database...');

    // Only update technicians_detailed column
    final result = await _client.from('supervisors').update({
      'technicians_detailed': techniciansData,
    }).eq('id', supervisorId);

    print('🔥 DB: Database update completed. Result: $result');
  }

  /// Get supervisor technicians in detailed format
  Future<List<Technician>> getSupervisorTechniciansDetailed(
      String supervisorId) async {
    final response = await _client
        .from('supervisors')
        .select('technicians_detailed, technicians')
        .eq('id', supervisorId)
        .single();

    // Try to parse detailed technicians first
    if (response['technicians_detailed'] != null) {
      try {
        final List<dynamic> detailedData = response['technicians_detailed'];
        return detailedData.map((data) => Technician.fromMap(data)).toList();
      } catch (e) {
        print('Error parsing detailed technicians: $e');
      }
    }

    // Fallback to simple technicians format
    final simpleTechnicians = _parseTechnicians(response['technicians']);
    return simpleTechnicians
        .map((name) => Technician(name: name, workId: '', profession: ''))
        .toList();
  }

  /// Add a detailed technician to supervisor
  Future<void> addDetailedTechnicianToSupervisor(
    String supervisorId,
    Technician technician,
  ) async {
    if (technician.name.trim().isEmpty) return;

    // Get current technicians
    final currentTechnicians =
        await getSupervisorTechniciansDetailed(supervisorId);

    // Check if technician already exists (by name)
    final existingIndex = currentTechnicians.indexWhere(
      (tech) => tech.name.toLowerCase() == technician.name.toLowerCase(),
    );

    if (existingIndex >= 0) {
      // Update existing technician
      currentTechnicians[existingIndex] = technician;
    } else {
      // Add new technician
      currentTechnicians.add(technician);
    }

    await updateSupervisorTechniciansDetailed(supervisorId, currentTechnicians);
  }

  /// Remove a technician from supervisor (by name)
  Future<void> removeDetailedTechnicianFromSupervisor(
    String supervisorId,
    String technicianName,
  ) async {
    // Get current technicians
    final currentTechnicians =
        await getSupervisorTechniciansDetailed(supervisorId);

    // Remove technician by name
    final updatedTechnicians = currentTechnicians
        .where(
            (tech) => tech.name.toLowerCase() != technicianName.toLowerCase())
        .toList();

    await updateSupervisorTechniciansDetailed(supervisorId, updatedTechnicians);
  }

  /// Update a specific technician's details
  Future<void> updateTechnicianDetails(
    String supervisorId,
    String originalName,
    Technician updatedTechnician,
  ) async {
    // Get current technicians
    final currentTechnicians =
        await getSupervisorTechniciansDetailed(supervisorId);

    // Find and update the technician
    final index = currentTechnicians.indexWhere(
      (tech) => tech.name.toLowerCase() == originalName.toLowerCase(),
    );

    if (index >= 0) {
      currentTechnicians[index] = updatedTechnician;
      await updateSupervisorTechniciansDetailed(
          supervisorId, currentTechnicians);
    }
  }

  /// Get accurate schools count for a supervisor (handles large datasets)
  Future<int> getSupervisorSchoolsCount(String supervisorId) async {
    try {
      // Use a count query to get the exact number without fetching all records
      final response = await _client
          .from('supervisor_schools')
          .select('*')
          .eq('supervisor_id', supervisorId)
          .count(CountOption.exact);
      
      // Extract count from response with null safety
      final count = response.count;
      return count ?? 0;
    } catch (e) {
      print('Error getting schools count for supervisor $supervisorId: $e');
      return 0;
    }
  }

  /// Get accurate schools count for multiple supervisors (handles large datasets)
  Future<Map<String, int>> getSupervisorsSchoolsCount(List<String> supervisorIds) async {
    try {
      if (supervisorIds.isEmpty) return {};
      
      // 🚀 PERFORMANCE OPTIMIZATION: Use single query with GROUP BY for better performance
      final response = await _client
          .from('supervisor_schools')
          .select('supervisor_id')
          .inFilter('supervisor_id', supervisorIds);
      
      // Count schools per supervisor
      final Map<String, int> counts = {};
      for (final supervisorId in supervisorIds) {
        counts[supervisorId] = 0;
      }
      
      for (final record in response) {
        final supervisorId = record['supervisor_id']?.toString();
        if (supervisorId != null && counts.containsKey(supervisorId)) {
          counts[supervisorId] = (counts[supervisorId] ?? 0) + 1;
        }
      }
      
      return counts;
    } catch (e) {
      print('Error getting schools count for supervisors: $e');
      return {for (final id in supervisorIds) id: 0};
    }
  }
}
