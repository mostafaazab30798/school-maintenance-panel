import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/maintenance_report.dart';
import '../../core/repositories/base_repository.dart';

class MaintenanceReportRepository extends BaseRepository<MaintenanceReport> {
  MaintenanceReportRepository(SupabaseClient client)
      : super(
          client: client,
          repositoryName: 'MaintenanceReportRepository',
          cacheConfig: CacheConfig.defaults,
        );

  @override
  String get tableName => 'maintenance_reports';

  @override
  MaintenanceReport fromMap(Map<String, dynamic> map) =>
      MaintenanceReport.fromMap(map);

  @override
  Map<String, dynamic> toMap(MaintenanceReport item) => item.toMap();

  Future<List<MaintenanceReport>> fetchMaintenanceReports({
    String? supervisorId,
    List<String>? supervisorIds,
    String? status,
  }) async {
    // Use BaseRepository's executeQuery for better caching and error handling
    return await executeQuery(
      operation: 'fetchMaintenanceReports',
      query: () async {
        dynamic query = client
            .from('maintenance_reports')
            .select('*, supervisors(username)');

        if (supervisorId != null) {
          query = query.eq('supervisor_id', supervisorId);
        }
        if (supervisorIds != null && supervisorIds.isNotEmpty) {
          query = query.inFilter('supervisor_id', supervisorIds);
        }
        if (status != null) {
          query = query.eq('status', status);
        }

        query = query.order('created_at', ascending: false);

        final response = await query;
        if (response is List) {
          return response.cast<Map<String, dynamic>>();
        } else {
          throw Exception('Failed to load maintenance reports');
        }
      },
      cacheParams: {
        'supervisorId': supervisorId,
        'supervisorIds': supervisorIds,
        'status': status,
      },
      useCache: true,
    );
  }

  Future<MaintenanceReport> fetchMaintenanceReportById(String id) async {
    final response = await client
        .from('maintenance_reports')
        .select('*, supervisors(username)')
        .eq('id', id)
        .single();

    return MaintenanceReport.fromMap(response);
  }

  Future<void> createMaintenanceReport(MaintenanceReport report) async {
    await executeMutation(
      operation: 'createMaintenanceReport',
      mutation: () async {
        final data = report.toMap()..remove('id');
        await client.from('maintenance_reports').insert(data);
        return null; // No return data expected
      },
      clearCacheOnSuccess: true,
    );
  }

  Future<void> updateMaintenanceReport(
      String id, Map<String, dynamic> updates) async {
    await executeMutation(
      operation: 'updateMaintenanceReport',
      mutation: () async {
        await client.from('maintenance_reports').update(updates).eq('id', id);
        return null; // No return data expected
      },
      clearCacheOnSuccess: true,
    );
  }

  Future<void> deleteMaintenanceReport(String id) async {
    await executeMutation(
      operation: 'deleteMaintenanceReport',
      mutation: () async {
        await client.from('maintenance_reports').delete().eq('id', id);
        return null; // No return data expected
      },
      clearCacheOnSuccess: true,
    );
  }
}
