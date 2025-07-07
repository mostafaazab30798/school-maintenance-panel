import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/admin.dart';
import 'dart:convert';

class AdminManagementService {
  final SupabaseClient _client;

  AdminManagementService(this._client);

  /// Get all admins
  Future<List<Admin>> getAllAdmins() async {
    final response = await _client
        .from('admins')
        .select()
        .order('created_at', ascending: false);

    if (response is List) {
      return response.map((map) => Admin.fromMap(map)).toList();
    } else {
      throw Exception('Failed to load admins');
    }
  }

  /// Create admin with auth user (complete signup process via Edge Function)
  Future<String> createAdminWithAuth({
    required String name,
    required String email,
    required String password,
    String role = 'admin',
  }) async {
    try {
      // Get current session to include auth headers
      final session = _client.auth.currentSession;
      if (session == null) {
        throw Exception('No active session. Please login first.');
      }

      // Call the Edge Function to create both auth user and admin record
      final response = await _client.functions.invoke(
        'create-admin-user',
        body: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        },
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.status != 200) {
        final errorData = response.data as Map<String, dynamic>?;
        final errorMessage = errorData?['error'] ?? 'Unknown error occurred';
        throw Exception(errorMessage);
      }

      final data = response.data as Map<String, dynamic>;
      final adminData = data['admin'] as Map<String, dynamic>;

      return adminData['id'] as String;
    } catch (e) {
      if (e.toString().contains('FunctionsException')) {
        // Extract the actual error message from FunctionsException
        final errorString = e.toString();
        if (errorString.contains('error":')) {
          final startIndex = errorString.indexOf('"error":"') + 9;
          final endIndex = errorString.indexOf('"', startIndex);
          if (startIndex > 8 && endIndex > startIndex) {
            final errorMessage = errorString.substring(startIndex, endIndex);
            throw Exception(errorMessage);
          }
        }
      }
      throw Exception('Failed to create admin: $e');
    }
  }

  /// Create admin record (auth user must be created manually first)
  Future<String> createAdmin({
    required String name,
    required String email,
    required String authUserId,
    String role = 'admin',
  }) async {
    try {
      final admin = Admin(
        id: '', // Will be generated
        name: name,
        email: email,
        authUserId: authUserId,
        role: role,
        createdAt: DateTime.now(),
      );

      final response = await _client
          .from('admins')
          .insert(admin.toMap()..remove('id'))
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to create admin: $e');
    }
  }

  /// Update admin
  Future<void> updateAdmin({
    required String adminId,
    String? name,
    String? email,
    String? role,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (email != null) updates['email'] = email;
    if (role != null) updates['role'] = role;
    updates['updated_at'] = DateTime.now().toIso8601String();

    await _client.from('admins').update(updates).eq('id', adminId);
  }

  /// Delete admin and associated auth user (via Edge Function)
  Future<void> deleteAdmin(String adminId) async {
    try {
      // Get admin details first
      final adminResponse = await _client
          .from('admins')
          .select('auth_user_id')
          .eq('id', adminId)
          .single();

      final authUserId = adminResponse['auth_user_id'] as String?;

      // First, unassign all supervisors
      await _client
          .from('supervisors')
          .update({'admin_id': null}).eq('admin_id', adminId);

      // Delete the admin record
      await _client.from('admins').delete().eq('id', adminId);

      // Try to delete auth user via Edge Function (if available)
      if (authUserId != null) {
        try {
          // Get current session for auth headers
          final session = _client.auth.currentSession;
          if (session != null) {
            await _client.functions.invoke(
              'delete-admin-user',
              body: {'auth_user_id': authUserId},
              headers: {
                'Authorization': 'Bearer ${session.accessToken}',
                'Content-Type': 'application/json',
              },
            );
          }
        } catch (e) {
          // Log warning but don't fail the operation if auth user deletion fails
          print('Warning: Failed to delete auth user $authUserId: $e');
        }
      }
    } catch (e) {
      throw Exception('Failed to delete admin: $e');
    }
  }

  /// Get supervisors assigned to admin
  Future<List<Map<String, dynamic>>> getSupervisorsForAdmin(
      String adminId) async {
    final response = await _client
        .from('supervisors')
        .select('id, username, email')
        .eq('admin_id', adminId);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get unassigned supervisors
  Future<List<Map<String, dynamic>>> getUnassignedSupervisors() async {
    final response = await _client
        .from('supervisors')
        .select('id, username, email, technicians_detailed')
        .filter('admin_id', 'is', null);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Assign supervisors to admin (handles both assignment and unassignment)
  Future<void> assignSupervisorsToAdmin({
    required String adminId,
    required List<String> supervisorIds,
  }) async {
    // First, get all currently assigned supervisors for this admin
    final currentlyAssignedResponse =
        await _client.from('supervisors').select('id').eq('admin_id', adminId);

    final currentlyAssignedIds = (currentlyAssignedResponse as List)
        .map((s) => s['id'] as String)
        .toSet();

    final newAssignedIds = supervisorIds.toSet();

    // Find supervisors to assign (new ones not currently assigned)
    final toAssign = newAssignedIds.difference(currentlyAssignedIds).toList();

    // Find supervisors to unassign (currently assigned but not in new list)
    final toUnassign = currentlyAssignedIds.difference(newAssignedIds).toList();

    // Assign new supervisors
    if (toAssign.isNotEmpty) {
      await _client
          .from('supervisors')
          .update({'admin_id': adminId}).inFilter('id', toAssign);
    }

    // Unassign removed supervisors
    if (toUnassign.isNotEmpty) {
      await _client
          .from('supervisors')
          .update({'admin_id': null}).inFilter('id', toUnassign);
    }
  }

  /// Unassign supervisors from admin
  Future<void> unassignSupervisorsFromAdmin({
    required List<String> supervisorIds,
  }) async {
    if (supervisorIds.isEmpty) return;

    await _client
        .from('supervisors')
        .update({'admin_id': null}).inFilter('id', supervisorIds);
  }

  /// Get admin statistics
  Future<Map<String, dynamic>> getAdminStats(String adminId) async {
    // Get supervisor count
    final supervisorsResponse =
        await _client.from('supervisors').select('id').eq('admin_id', adminId);

    final supervisorCount = supervisorsResponse.length;
    final supervisorIds =
        (supervisorsResponse as List).map((s) => s['id'] as String).toList();

    if (supervisorIds.isEmpty) {
      return {
        'supervisors': 0,
        'reports': 0,
        'maintenance': 0,
        'completed_reports': 0,
        'completed_maintenance': 0,
        'late_reports': 0,
        'late_completed_reports': 0,
        'completion_rate': 0.0,
      };
    }

    // Get reports count and status breakdown
    final reportsResponse = await _client
        .from('reports')
        .select('id, status')
        .inFilter('supervisor_id', supervisorIds);

    final completedReports = reportsResponse
        .where((report) => report['status'] == 'completed')
        .length;

    final lateReports =
        reportsResponse.where((report) => report['status'] == 'late').length;

    final lateCompletedReports = reportsResponse
        .where((report) => report['status'] == 'late_completed')
        .length;

    // Get maintenance count and completed maintenance
    final maintenanceResponse = await _client
        .from('maintenance_reports')
        .select('id, status')
        .inFilter('supervisor_id', supervisorIds);

    final completedMaintenance = maintenanceResponse
        .where((maintenance) => maintenance['status'] == 'completed')
        .length;

    // Calculate completion rate
    final totalWork = reportsResponse.length + maintenanceResponse.length;
    final completedWork = completedReports + completedMaintenance;
    final completionRate = totalWork > 0 ? (completedWork / totalWork) : 0.0;

    return {
      'supervisors': supervisorCount,
      'reports': reportsResponse.length,
      'maintenance': maintenanceResponse.length,
      'completed_reports': completedReports,
      'completed_maintenance': completedMaintenance,
      'late_reports': lateReports,
      'late_completed_reports': lateCompletedReports,
      'completion_rate': completionRate,
    };
  }

  /// Get individual supervisor statistics
  Future<Map<String, dynamic>> getSupervisorStats(String supervisorId) async {
    // Get reports count and status breakdown
    final reportsResponse = await _client
        .from('reports')
        .select('id, status')
        .eq('supervisor_id', supervisorId);

    final completedReports = reportsResponse
        .where((report) => report['status'] == 'completed')
        .length;

    final lateReports =
        reportsResponse.where((report) => report['status'] == 'late').length;

    final lateCompletedReports = reportsResponse
        .where((report) => report['status'] == 'late_completed')
        .length;

    // Get maintenance count and completed maintenance
    final maintenanceResponse = await _client
        .from('maintenance_reports')
        .select('id, status')
        .eq('supervisor_id', supervisorId);

    final completedMaintenance = maintenanceResponse
        .where((maintenance) => maintenance['status'] == 'completed')
        .length;

    // Calculate completion rate
    final totalWork = reportsResponse.length + maintenanceResponse.length;
    final completedWork = completedReports + completedMaintenance;
    final completionRate = totalWork > 0 ? (completedWork / totalWork) : 0.0;

    return {
      'reports': reportsResponse.length,
      'maintenance': maintenanceResponse.length,
      'completed_reports': completedReports,
      'completed_maintenance': completedMaintenance,
      'late_reports': lateReports,
      'late_completed_reports': lateCompletedReports,
      'completion_rate': completionRate,
    };
  }

  /// Get all supervisors with their individual statistics
  Future<List<Map<String, dynamic>>> getAllSupervisorsWithStats() async {
    // Get all supervisors
    final supervisorsResponse = await _client
        .from('supervisors')
        .select('id, username, email, admin_id, technicians_detailed')
        .order('created_at', ascending: false);

    List<Map<String, dynamic>> supervisorsWithStats = [];

    for (final supervisor in supervisorsResponse) {
      final supervisorId = supervisor['id'] as String;
      final stats = await getSupervisorStats(supervisorId);

      // Get school count for this supervisor
      final schoolsResponse = await _client
          .from('supervisor_schools')
          .select('id')
          .eq('supervisor_id', supervisorId);
      final schoolsCount = schoolsResponse.length;

      supervisorsWithStats.add({
        'id': supervisorId,
        'username': supervisor['username'],
        'email': supervisor['email'],
        'admin_id': supervisor['admin_id'],
        'technicians_detailed': supervisor['technicians_detailed'] ?? [],
        'schools_count': schoolsCount,
        'stats': stats,
      });
    }

    return supervisorsWithStats;
  }

  /// Get report types statistics for super admin dashboard
  Future<Map<String, int>> getReportTypesStats() async {
    final reportsResponse = await _client.from('reports').select('type');

    Map<String, int> typeCounts = {
      'Civil': 0,
      'Plumbing': 0,
      'Electricity': 0,
      'AC': 0,
      'Fire': 0,
    };

    for (final report in reportsResponse) {
      final type = report['type'] as String?;
      if (type != null && typeCounts.containsKey(type)) {
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      }
    }

    return typeCounts;
  }

  /// Get report sources statistics for super admin dashboard
  Future<Map<String, int>> getReportSourcesStats() async {
    final reportsResponse =
        await _client.from('reports').select('report_source');

    Map<String, int> sourceCounts = {
      'unifier': 0,
      'check_list': 0,
      'consultant': 0,
    };

    for (final report in reportsResponse) {
      final source =
          report['report_source'] as String? ?? 'unifier'; // Default to unifier
      if (sourceCounts.containsKey(source)) {
        sourceCounts[source] = (sourceCounts[source] ?? 0) + 1;
      }
    }

    return sourceCounts;
  }

  /// Get maintenance status statistics for super admin dashboard
  Future<Map<String, int>> getMaintenanceStatusStats() async {
    final maintenanceResponse =
        await _client.from('maintenance_reports').select('status');

    Map<String, int> statusCounts = {
      'pending': 0,
      'in_progress': 0,
      'completed': 0,
    };

    for (final maintenance in maintenanceResponse) {
      final status = maintenance['status'] as String?;
      if (status != null && statusCounts.containsKey(status)) {
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }
    }

    return statusCounts;
  }

  /// Get admin reports distribution for super admin dashboard
  Future<Map<String, int>> getAdminReportsDistribution() async {
    final admins = await getAllAdmins();
    Map<String, int> adminReportsCount = {};

    for (final admin in admins) {
      final stats = await getAdminStats(admin.id);
      final reportsCount = stats['reports'] as int? ?? 0;
      adminReportsCount[admin.name] = reportsCount;
    }

    return adminReportsCount;
  }

  /// Get admin maintenance distribution for super admin dashboard
  Future<Map<String, int>> getAdminMaintenanceDistribution() async {
    final admins = await getAllAdmins();
    Map<String, int> adminMaintenanceCount = {};

    for (final admin in admins) {
      final stats = await getAdminStats(admin.id);
      final maintenanceCount = stats['maintenance'] as int? ?? 0;
      adminMaintenanceCount[admin.name] = maintenanceCount;
    }

    return adminMaintenanceCount;
  }

  /// Get completion rates by report type for super admin dashboard
  Future<Map<String, Map<String, dynamic>>>
      getReportTypesCompletionRates() async {
    final reportsResponse =
        await _client.from('reports').select('type, status');

    Map<String, Map<String, dynamic>> typeStats = {
      'Civil': {'total': 0, 'completed': 0, 'rate': 0.0},
      'Plumbing': {'total': 0, 'completed': 0, 'rate': 0.0},
      'Electricity': {'total': 0, 'completed': 0, 'rate': 0.0},
      'AC': {'total': 0, 'completed': 0, 'rate': 0.0},
      'Fire': {'total': 0, 'completed': 0, 'rate': 0.0},
    };

    for (final report in reportsResponse) {
      final type = report['type'] as String?;
      final status = report['status'] as String?;

      if (type != null && typeStats.containsKey(type)) {
        typeStats[type]!['total'] = (typeStats[type]!['total'] as int) + 1;

        if (status == 'completed') {
          typeStats[type]!['completed'] =
              (typeStats[type]!['completed'] as int) + 1;
        }
      }
    }

    // Calculate completion rates
    for (final type in typeStats.keys) {
      final total = typeStats[type]!['total'] as int;
      final completed = typeStats[type]!['completed'] as int;
      final rate = total > 0 ? (completed / total) : 0.0;
      typeStats[type]!['rate'] = rate;
    }

    return typeStats;
  }

  /// Get completion rates by report source for super admin dashboard
  Future<Map<String, Map<String, dynamic>>>
      getReportSourcesCompletionRates() async {
    final reportsResponse =
        await _client.from('reports').select('report_source, status');

    Map<String, Map<String, dynamic>> sourceStats = {
      'unifier': {'total': 0, 'completed': 0, 'rate': 0.0},
      'check_list': {'total': 0, 'completed': 0, 'rate': 0.0},
      'consultant': {'total': 0, 'completed': 0, 'rate': 0.0},
    };

    for (final report in reportsResponse) {
      final source =
          report['report_source'] as String? ?? 'unifier'; // Default to unifier
      final status = report['status'] as String?;

      if (sourceStats.containsKey(source)) {
        sourceStats[source]!['total'] =
            (sourceStats[source]!['total'] as int) + 1;

        if (status == 'completed') {
          sourceStats[source]!['completed'] =
              (sourceStats[source]!['completed'] as int) + 1;
        }
      }
    }

    // Calculate completion rates
    for (final source in sourceStats.keys) {
      final total = sourceStats[source]!['total'] as int;
      final completed = sourceStats[source]!['completed'] as int;
      final rate = total > 0 ? (completed / total) : 0.0;
      sourceStats[source]!['rate'] = rate;
    }

    return sourceStats;
  }

  /// 🚀 OPTIMIZED: Get all dashboard data in a single optimized call
  /// This replaces all the individual methods above to eliminate the N+1 query problem
  Future<Map<String, dynamic>> getAllDashboardDataOptimized() async {
    print('🚀 Starting optimized dashboard data fetch...');
    final stopwatch = Stopwatch()..start();

    try {
      // Step 1: Fetch all base data in parallel (reduces total query time)
      final baseDataFutures = await Future.wait<dynamic>([
        getAllAdmins(), // We need admin objects, not just raw data
        _client
            .from('supervisors')
            .select(
                'id, username, email, admin_id, technicians, technicians_detailed')
            .order('created_at', ascending: false),

        // All reports and maintenance data (we'll process these in memory)
        _client
            .from('reports')
            .select('id, type, status, report_source, supervisor_id, priority'),
        _client.from('maintenance_reports').select('id, status, supervisor_id'),

        // All supervisor school assignments
        _client.from('supervisor_schools').select('supervisor_id, school_id'),
      ]);

      final admins = baseDataFutures[0] as List<Admin>;
      final supervisorsRaw = baseDataFutures[1] as List<Map<String, dynamic>>;
      final allReports = baseDataFutures[2] as List<Map<String, dynamic>>;
      final allMaintenance = baseDataFutures[3] as List<Map<String, dynamic>>;
      final allSchools = baseDataFutures[4] as List<Map<String, dynamic>>;

      print('🔄 Base data fetched in ${stopwatch.elapsedMilliseconds}ms');
      print(
          '📊 Data summary: ${admins.length} admins, ${supervisorsRaw.length} supervisors, ${allReports.length} reports, ${allMaintenance.length} maintenance, ${allSchools.length} schools');

      // Step 2: Process all statistics in memory (much faster than separate DB calls)
      print('🔄 Processing statistics in memory...');

      // Convert supervisors to the expected format
      final allSupervisors = supervisorsRaw
          .map((s) => {
                'id': s['id'],
                'username': s['username'],
                'email': s['email'],
                'admin_id': s['admin_id'],
                'technicians': s['technicians'] ?? [],
                'technicians_detailed': s['technicians_detailed'] ?? [],
              })
          .toList();

      // Calculate supervisor stats in memory
      final supervisorsWithStats = _calculateSupervisorsWithStatsInMemory(
          supervisorsRaw, allReports, allMaintenance, allSchools);

      // Calculate admin stats in memory
      final adminStats = _calculateAdminStatsInMemory(
          admins, allSupervisors, allReports, allMaintenance);

      // Calculate report type statistics
      final reportTypesStats = _calculateReportTypesStats(allReports);

      // Calculate report source statistics
      final reportSourcesStats = _calculateReportSourcesStats(allReports);

      // Calculate maintenance status statistics
      final maintenanceStatusStats =
          _calculateMaintenanceStatusStats(allMaintenance);

      // Calculate admin distributions
      final adminReportsDistribution =
          _calculateAdminReportsDistribution(admins, adminStats);
      final adminMaintenanceDistribution =
          _calculateAdminMaintenanceDistribution(admins, adminStats);

      // Calculate completion rates
      final reportTypesCompletionRates =
          _calculateReportTypesCompletionRates(allReports);
      final reportSourcesCompletionRates =
          _calculateReportSourcesCompletionRates(allReports);

      // Calculate priority statistics (emergency/routine)
      final reportPriorityStats = _calculateReportPriorityStats(allReports);
      final reportPriorityCompletionRates =
          _calculateReportPriorityCompletionRates(allReports);

      stopwatch.stop();
      print(
          '✅ Optimized dashboard data fetch completed in ${stopwatch.elapsedMilliseconds}ms');

      return {
        'admins': admins,
        'allSupervisors': allSupervisors,
        'adminStats': adminStats,
        'supervisorsWithStats': supervisorsWithStats,
        'reportTypesStats': reportTypesStats,
        'reportSourcesStats': reportSourcesStats,
        'maintenanceStatusStats': maintenanceStatusStats,
        'adminReportsDistribution': adminReportsDistribution,
        'adminMaintenanceDistribution': adminMaintenanceDistribution,
        'reportTypesCompletionRates': reportTypesCompletionRates,
        'reportSourcesCompletionRates': reportSourcesCompletionRates,
        'reportPriorityStats': reportPriorityStats,
        'reportPriorityCompletionRates': reportPriorityCompletionRates,
      };
    } catch (e) {
      stopwatch.stop();
      print(
          '❌ Error in optimized dashboard fetch after ${stopwatch.elapsedMilliseconds}ms: $e');
      rethrow;
    }
  }

  /// Calculate supervisor statistics in memory (eliminates N+1 queries)
  List<Map<String, dynamic>> _calculateSupervisorsWithStatsInMemory(
    List<Map<String, dynamic>> supervisors,
    List<Map<String, dynamic>> allReports,
    List<Map<String, dynamic>> allMaintenance,
    List<Map<String, dynamic>> allSchools,
  ) {
    return supervisors.map((supervisor) {
      final supervisorId = supervisor['id'] as String;

      // Filter reports for this supervisor
      final supervisorReports =
          allReports.where((r) => r['supervisor_id'] == supervisorId).toList();
      final supervisorMaintenance = allMaintenance
          .where((m) => m['supervisor_id'] == supervisorId)
          .toList();

      // Calculate stats
      final completedReports =
          supervisorReports.where((r) => r['status'] == 'completed').length;
      final lateReports =
          supervisorReports.where((r) => r['status'] == 'late').length;
      final lateCompletedReports = supervisorReports
          .where((r) => r['status'] == 'late_completed')
          .length;
      final completedMaintenance =
          supervisorMaintenance.where((m) => m['status'] == 'completed').length;

      final totalWork = supervisorReports.length + supervisorMaintenance.length;
      final completedWork = completedReports + completedMaintenance;
      final completionRate = totalWork > 0 ? (completedWork / totalWork) : 0.0;

      // Get school count for this supervisor
      final schoolsResponse =
          allSchools.where((s) => s['supervisor_id'] == supervisorId).toList();
      final schoolsCount = schoolsResponse.length;

      return {
        'id': supervisorId,
        'username': supervisor['username'],
        'email': supervisor['email'],
        'admin_id': supervisor['admin_id'],
        'technicians_detailed': supervisor['technicians_detailed'] ??
            [], // Include detailed technicians field
        'schools_count': schoolsCount,
        'stats': {
          'reports': supervisorReports.length,
          'maintenance': supervisorMaintenance.length,
          'completed_reports': completedReports,
          'completed_maintenance': completedMaintenance,
          'late_reports': lateReports,
          'late_completed_reports': lateCompletedReports,
          'completion_rate': completionRate,
        },
      };
    }).toList();
  }

  /// Calculate admin statistics in memory (eliminates N+1 queries)
  Map<String, Map<String, dynamic>> _calculateAdminStatsInMemory(
    List<Admin> admins,
    List<Map<String, dynamic>> allSupervisors,
    List<Map<String, dynamic>> allReports,
    List<Map<String, dynamic>> allMaintenance,
  ) {
    final Map<String, Map<String, dynamic>> adminStats = {};

    for (final admin in admins) {
      // Get supervisors for this admin
      final adminSupervisors =
          allSupervisors.where((s) => s['admin_id'] == admin.id).toList();
      final supervisorIds =
          adminSupervisors.map((s) => s['id'] as String).toList();

      if (supervisorIds.isEmpty) {
        adminStats[admin.id] = {
          'supervisors': 0,
          'reports': 0,
          'maintenance': 0,
          'completed_reports': 0,
          'completed_maintenance': 0,
          'late_reports': 0,
          'late_completed_reports': 0,
          'completion_rate': 0.0,
        };
        continue;
      }

      // Filter reports and maintenance for this admin's supervisors
      final adminReports = allReports
          .where((r) => supervisorIds.contains(r['supervisor_id']))
          .toList();
      final adminMaintenance = allMaintenance
          .where((m) => supervisorIds.contains(m['supervisor_id']))
          .toList();

      // Calculate stats
      final completedReports =
          adminReports.where((r) => r['status'] == 'completed').length;
      final lateReports =
          adminReports.where((r) => r['status'] == 'late').length;
      final lateCompletedReports =
          adminReports.where((r) => r['status'] == 'late_completed').length;
      final completedMaintenance =
          adminMaintenance.where((m) => m['status'] == 'completed').length;

      final totalWork = adminReports.length + adminMaintenance.length;
      final completedWork = completedReports + completedMaintenance;
      final completionRate = totalWork > 0 ? (completedWork / totalWork) : 0.0;

      adminStats[admin.id] = {
        'supervisors': supervisorIds.length,
        'reports': adminReports.length,
        'maintenance': adminMaintenance.length,
        'completed_reports': completedReports,
        'completed_maintenance': completedMaintenance,
        'late_reports': lateReports,
        'late_completed_reports': lateCompletedReports,
        'completion_rate': completionRate,
      };
    }

    return adminStats;
  }

  /// Calculate report types statistics in memory
  Map<String, int> _calculateReportTypesStats(
      List<Map<String, dynamic>> allReports) {
    final Map<String, int> typeCounts = {
      'Civil': 0,
      'Plumbing': 0,
      'Electricity': 0,
      'AC': 0,
      'Fire': 0,
    };

    for (final report in allReports) {
      final type = report['type'] as String?;
      if (type != null && typeCounts.containsKey(type)) {
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      }
    }

    return typeCounts;
  }

  /// Calculate report sources statistics in memory
  Map<String, int> _calculateReportSourcesStats(
      List<Map<String, dynamic>> allReports) {
    final Map<String, int> sourceCounts = {
      'unifier': 0,
      'check_list': 0,
      'consultant': 0,
    };

    for (final report in allReports) {
      final source = report['report_source'] as String? ?? 'unifier';
      if (sourceCounts.containsKey(source)) {
        sourceCounts[source] = (sourceCounts[source] ?? 0) + 1;
      }
    }

    return sourceCounts;
  }

  /// Calculate maintenance status statistics in memory
  Map<String, int> _calculateMaintenanceStatusStats(
      List<Map<String, dynamic>> allMaintenance) {
    final Map<String, int> statusCounts = {
      'pending': 0,
      'in_progress': 0,
      'completed': 0,
    };

    for (final maintenance in allMaintenance) {
      final status = maintenance['status'] as String?;
      if (status != null && statusCounts.containsKey(status)) {
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }
    }

    return statusCounts;
  }

  /// Calculate admin reports distribution in memory
  Map<String, int> _calculateAdminReportsDistribution(
    List<Admin> admins,
    Map<String, Map<String, dynamic>> adminStats,
  ) {
    final Map<String, int> distribution = {};

    for (final admin in admins) {
      final stats = adminStats[admin.id] ?? {};
      final reportsCount = stats['reports'] as int? ?? 0;
      distribution[admin.name] = reportsCount;
    }

    return distribution;
  }

  /// Calculate admin maintenance distribution in memory
  Map<String, int> _calculateAdminMaintenanceDistribution(
    List<Admin> admins,
    Map<String, Map<String, dynamic>> adminStats,
  ) {
    final Map<String, int> distribution = {};

    for (final admin in admins) {
      final stats = adminStats[admin.id] ?? {};
      final maintenanceCount = stats['maintenance'] as int? ?? 0;
      distribution[admin.name] = maintenanceCount;
    }

    return distribution;
  }

  /// Calculate report types completion rates in memory
  Map<String, Map<String, dynamic>> _calculateReportTypesCompletionRates(
      List<Map<String, dynamic>> allReports) {
    final Map<String, Map<String, dynamic>> typeStats = {
      'Civil': {'total': 0, 'completed': 0, 'rate': 0.0},
      'Plumbing': {'total': 0, 'completed': 0, 'rate': 0.0},
      'Electricity': {'total': 0, 'completed': 0, 'rate': 0.0},
      'AC': {'total': 0, 'completed': 0, 'rate': 0.0},
      'Fire': {'total': 0, 'completed': 0, 'rate': 0.0},
    };

    for (final report in allReports) {
      final type = report['type'] as String?;
      final status = report['status'] as String?;

      if (type != null && typeStats.containsKey(type)) {
        typeStats[type]!['total'] = (typeStats[type]!['total'] as int) + 1;

        if (status == 'completed') {
          typeStats[type]!['completed'] =
              (typeStats[type]!['completed'] as int) + 1;
        }
      }
    }

    // Calculate completion rates
    for (final type in typeStats.keys) {
      final total = typeStats[type]!['total'] as int;
      final completed = typeStats[type]!['completed'] as int;
      final rate = total > 0 ? (completed / total) : 0.0;
      typeStats[type]!['rate'] = rate;
    }

    return typeStats;
  }

  /// Calculate report sources completion rates in memory
  Map<String, Map<String, dynamic>> _calculateReportSourcesCompletionRates(
      List<Map<String, dynamic>> allReports) {
    final Map<String, Map<String, dynamic>> sourceStats = {
      'unifier': {'total': 0, 'completed': 0, 'rate': 0.0},
      'check_list': {'total': 0, 'completed': 0, 'rate': 0.0},
      'consultant': {'total': 0, 'completed': 0, 'rate': 0.0},
    };

    for (final report in allReports) {
      final source = report['report_source'] as String? ?? 'unifier';
      final status = report['status'] as String?;

      if (sourceStats.containsKey(source)) {
        sourceStats[source]!['total'] =
            (sourceStats[source]!['total'] as int) + 1;

        if (status == 'completed') {
          sourceStats[source]!['completed'] =
              (sourceStats[source]!['completed'] as int) + 1;
        }
      }
    }

    // Calculate completion rates
    for (final source in sourceStats.keys) {
      final total = sourceStats[source]!['total'] as int;
      final completed = sourceStats[source]!['completed'] as int;
      final rate = total > 0 ? (completed / total) : 0.0;
      sourceStats[source]!['rate'] = rate;
    }

    return sourceStats;
  }

  /// Calculate report priority statistics in memory (emergency/routine)
  Map<String, int> _calculateReportPriorityStats(
      List<Map<String, dynamic>> allReports) {
    final Map<String, int> priorityCounts = {
      'emergency': 0,
      'routine': 0,
    };

    for (final report in allReports) {
      final priority = report['priority'] as String?;
      if (priority != null &&
          priorityCounts.containsKey(priority.toLowerCase())) {
        priorityCounts[priority.toLowerCase()] =
            (priorityCounts[priority.toLowerCase()] ?? 0) + 1;
      }
    }

    return priorityCounts;
  }

  /// Calculate report priority completion rates in memory
  Map<String, Map<String, dynamic>> _calculateReportPriorityCompletionRates(
      List<Map<String, dynamic>> allReports) {
    final Map<String, Map<String, dynamic>> priorityStats = {
      'emergency': {'total': 0, 'completed': 0, 'rate': 0.0},
      'routine': {'total': 0, 'completed': 0, 'rate': 0.0},
    };

    for (final report in allReports) {
      final priority = report['priority'] as String?;
      final status = report['status'] as String?;

      if (priority != null &&
          priorityStats.containsKey(priority.toLowerCase())) {
        priorityStats[priority.toLowerCase()]!['total'] =
            (priorityStats[priority.toLowerCase()]!['total'] as int) + 1;

        if (status == 'completed') {
          priorityStats[priority.toLowerCase()]!['completed'] =
              (priorityStats[priority.toLowerCase()]!['completed'] as int) + 1;
        }
      }
    }

    // Calculate completion rates
    for (final priority in priorityStats.keys) {
      final total = priorityStats[priority]!['total'] as int;
      final completed = priorityStats[priority]!['completed'] as int;
      final rate = total > 0 ? (completed / total) : 0.0;
      priorityStats[priority]!['rate'] = rate;
    }

    return priorityStats;
  }
}
