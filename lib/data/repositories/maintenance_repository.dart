import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/maintenance_report.dart';
import '../../core/repositories/base_repository.dart';
import 'package:flutter/foundation.dart';

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
    int? limit,
    int? page,
  }) async {
    // 🚀 PERFORMANCE OPTIMIZATION: Use optimized cache key generation
    final cacheKey = _generateOptimizedCacheKey(
      supervisorId: supervisorId,
      supervisorIds: supervisorIds,
      status: status,
      limit: limit,
      page: page,
    );

    // 🚀 PERFORMANCE OPTIMIZATION: Check cache first for instant response
    final cached = getFromCache<List<MaintenanceReport>>(cacheKey);
    if (cached != null) {
      if (kDebugMode) {
        debugPrint('⚡ MaintenanceReportRepository: Cache hit - returning ${cached.length} maintenance reports instantly');
      }
      return cached;
    }

    if (kDebugMode) {
      debugPrint('MaintenanceReportRepository: Starting fetchMaintenanceReports');
    }

    // 🚀 PERFORMANCE OPTIMIZATION: Use BaseRepository's executeQuery with optimized parameters
    return await executeQuery(
      operation: 'fetchMaintenanceReports',
      query: () async {
        // 🚀 PERFORMANCE OPTIMIZATION: Optimize query construction
        dynamic query = client
            .from('maintenance_reports')
            .select('*, supervisors(username)');

        // 🚀 PERFORMANCE OPTIMIZATION: Apply filters in order of selectivity
        if (supervisorId != null) {
          query = query.eq('supervisor_id', supervisorId);
        } else if (supervisorIds != null && supervisorIds.isNotEmpty) {
          query = query.inFilter('supervisor_id', supervisorIds);
        }
        
        if (status != null) {
          query = query.eq('status', status);
        }

        // Order the results by created_at in descending order
        query = query.order('created_at', ascending: false);

        // 🚀 PERFORMANCE OPTIMIZATION: Add pagination support
        final itemsPerPage = limit ?? 20; // Default to 20 items per page
        final currentPage = page ?? 1;
        final offset = (currentPage - 1) * itemsPerPage;
        
        query = query.range(offset, offset + itemsPerPage - 1);

        if (kDebugMode) {
          debugPrint('🚀 Executing optimized maintenance reports query with pagination...');
          debugPrint('  Items per page: $itemsPerPage');
          debugPrint('  Current page: $currentPage');
          debugPrint('  Offset: $offset');
        }

        final response = await query;
        
        if (kDebugMode) {
          debugPrint('📊 Maintenance reports query response length: ${response is List ? response.length : 'N/A'}');
        }

        if (response is List) {
          final results = response.cast<Map<String, dynamic>>();
          if (kDebugMode) {
            debugPrint('✅ Successfully fetched ${results.length} maintenance reports from database');
          }
          return results;
        } else {
          if (kDebugMode) {
            debugPrint('❌ Unexpected maintenance reports response type: ${response.runtimeType}');
          }
          throw Exception('Failed to load maintenance reports');
        }
      },
      cacheParams: {
        'supervisorId': supervisorId,
        'supervisorIds': supervisorIds,
        'status': status,
        'limit': limit,
        'page': page,
      },
      useCache: true,
    );
  }

  /// 🚀 PERFORMANCE OPTIMIZATION: Generate optimized cache key
  String _generateOptimizedCacheKey({
    String? supervisorId,
    List<String>? supervisorIds,
    String? status,
    int? limit,
    int? page,
  }) {
    final params = <String, dynamic>{};
    
    if (supervisorId != null) {
      params['supervisorId'] = supervisorId;
    } else if (supervisorIds != null && supervisorIds.isNotEmpty) {
      // Sort supervisorIds for consistent cache key
      params['supervisorIds'] = supervisorIds..sort();
    }
    
    if (status != null) params['status'] = status;
    if (limit != null) params['limit'] = limit;
    if (page != null) params['page'] = page;
    
    return generateCacheKey('fetchMaintenanceReports', params);
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
