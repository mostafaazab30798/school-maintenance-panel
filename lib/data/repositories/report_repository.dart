import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report.dart';
import '../../core/repositories/base_repository.dart';
import '../../core/services/cache_invalidation_service.dart';
import 'package:flutter/foundation.dart';

class ReportRepository extends BaseRepository<Report> {
  ReportRepository(SupabaseClient client)
      : super(
          client: client,
          repositoryName: 'ReportRepository',
          cacheConfig: CacheConfig.defaults,
        );

  @override
  String get tableName => 'reports';

  @override
  Report fromMap(Map<String, dynamic> map) => Report.fromMap(map);

  @override
  Map<String, dynamic> toMap(Report item) => item.toMap();

  /// Invalidates all cached reports
  ///
  /// This method clears the BaseRepository cache for all report-related operations
  void invalidateCache() {
    clearCache('fetchReports');
    // Also invalidate cross-component caches
    CacheInvalidationService.invalidateReportCaches();
  }

  Future<List<Report>> fetchReports({
    String? supervisorId,
    List<String>? supervisorIds,
    String? type,
    String? status,
    String? priority,
    String? schoolName,
    bool forceRefresh = false,
    int? limit,
    int? page,
  }) async {
    // 🚀 PERFORMANCE OPTIMIZATION: Use optimized cache key generation
    final cacheKey = _generateOptimizedCacheKey(
      supervisorId: supervisorId,
      supervisorIds: supervisorIds,
      type: type,
      status: status,
      priority: priority,
      schoolName: schoolName,
      limit: limit,
      page: page,
    );

    // 🚀 PERFORMANCE OPTIMIZATION: Check cache first for instant response
    if (!forceRefresh) {
      final cached = getFromCache<List<Report>>(cacheKey);
      if (cached != null) {
        if (kDebugMode) {
          debugPrint('⚡ ReportRepository: Cache hit - returning ${cached.length} reports instantly');
        }
        return cached;
      }
    }

    if (kDebugMode) {
      debugPrint('🔍 ReportRepository.fetchReports called with:');
      debugPrint('  supervisorId: $supervisorId');
      debugPrint('  supervisorIds: $supervisorIds');
      debugPrint('  type: $type');
      debugPrint('  status: $status');
      debugPrint('  priority: $priority');
      debugPrint('  schoolName: $schoolName');
      debugPrint('  forceRefresh: $forceRefresh');
      debugPrint('  limit: $limit');
      debugPrint('  page: $page');
    }

    // 🚀 PERFORMANCE OPTIMIZATION: Use BaseRepository's executeQuery with optimized parameters
    return await executeQuery(
      operation: 'fetchReports',
      query: () async {
        // 🚀 PERFORMANCE OPTIMIZATION: Optimize query construction
        dynamic query = client.from('reports').select('*, supervisors(username)');

        // 🚀 PERFORMANCE OPTIMIZATION: Apply filters in order of selectivity
        if (supervisorId != null) {
          query = query.eq('supervisor_id', supervisorId);
        } else if (supervisorIds != null && supervisorIds.isNotEmpty) {
          query = query.inFilter('supervisor_id', supervisorIds);
        }
        
        if (status != null) {
          query = query.eq('status', status);
        }
        
        if (type != null) {
          query = query.eq('type', type);
        }
        
        if (priority != null) {
          query = query.eq('priority', priority);
        }
        
        if (schoolName != null) {
          query = query.eq('school_name', schoolName);
        }

        // Order the results by created_at in descending order
        query = query.order('created_at', ascending: false);

        // 🚀 PERFORMANCE OPTIMIZATION: Add pagination support
        final itemsPerPage = limit ?? 20; // Default to 20 items per page
        final currentPage = page ?? 1;
        final offset = (currentPage - 1) * itemsPerPage;
        
        query = query.range(offset, offset + itemsPerPage - 1);

        if (kDebugMode) {
          debugPrint('🚀 Executing optimized Supabase query with pagination...');
          debugPrint('  Items per page: $itemsPerPage');
          debugPrint('  Current page: $currentPage');
          debugPrint('  Offset: $offset');
        }

        final response = await query;

        if (kDebugMode) {
          debugPrint('📊 Query response type: ${response.runtimeType}');
          debugPrint(
              '📊 Query response length: ${response is List ? response.length : 'N/A'}');
          if (response is List && response.isNotEmpty) {
            debugPrint('📊 First result sample: ${response.first}');
          }
        }

        if (response is List) {
          final results = response.cast<Map<String, dynamic>>();
          if (kDebugMode) {
            debugPrint(
                '✅ Successfully fetched ${results.length} reports from database');
          }
          return results;
        } else {
          if (kDebugMode) {
            debugPrint('❌ Unexpected response type: ${response.runtimeType}');
          }
          throw Exception('Failed to load reports');
        }
      },
      cacheParams: {
        'supervisorId': supervisorId,
        'supervisorIds': supervisorIds,
        'type': type,
        'status': status,
        'priority': priority,
        'schoolName': schoolName,
        'limit': limit,
        'page': page,
        'userId': client.auth.currentUser?.id,
      },
      useCache: true,
      forceRefresh: forceRefresh,
    );
  }

  /// 🚀 PERFORMANCE OPTIMIZATION: Generate optimized cache key
  String _generateOptimizedCacheKey({
    String? supervisorId,
    List<String>? supervisorIds,
    String? type,
    String? status,
    String? priority,
    String? schoolName,
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
    
    if (type != null) params['type'] = type;
    if (status != null) params['status'] = status;
    if (priority != null) params['priority'] = priority;
    if (schoolName != null) params['schoolName'] = schoolName;
    if (limit != null) params['limit'] = limit;
    if (page != null) params['page'] = page;
    
    return generateCacheKey('fetchReports', params);
  }

  Future<Report> fetchReportById(String id) async {
    final response = await client
        .from('reports')
        .select(
            '*, supervisors(username)') // Fixed to use 'username' consistently
        .eq('id', id)
        .single();

    return Report.fromMap(response);
  }

  Future<void> createReport(Report report) async {
    await executeMutation(
      operation: 'createReport',
      mutation: () async {
        final data = report.toMap()..remove('id'); // Let Supabase handle the ID
        await client.from('reports').insert(data);
        return null; // No return data expected
      },
      clearCacheOnSuccess: true,
    );
  }

  Future<void> updateReport(String id, Map<String, dynamic> updates) async {
    await executeMutation(
      operation: 'updateReport',
      mutation: () async {
        await client.from('reports').update(updates).eq('id', id);
        return null; // No return data expected
      },
      clearCacheOnSuccess: true,
    );
  }

  Future<void> deleteReport(String id) async {
    await executeMutation(
      operation: 'deleteReport',
      mutation: () async {
        await client.from('reports').delete().eq('id', id);
        return null; // No return data expected
      },
      clearCacheOnSuccess: true,
    );
  }

  /// Test method to verify report filtering consistency
  /// This helps debug why dashboard counts work but report page doesn't
  Future<List<Report>> testReportFiltering({
    String? supervisorId,
    List<String>? supervisorIds,
    String? type,
    String? status,
    String? priority,
    String? schoolName,
  }) async {
    if (kDebugMode) {
      debugPrint('🧪 Testing report filtering with:');
      debugPrint('  supervisorId: $supervisorId');
      debugPrint('  supervisorIds: $supervisorIds');
      debugPrint('  type: $type');
      debugPrint('  status: $status');
      debugPrint('  priority: $priority');
      debugPrint('  schoolName: $schoolName');
    }

    return await fetchReports(
      supervisorId: supervisorId,
      supervisorIds: supervisorIds,
      type: type,
      status: status,
      priority: priority,
      schoolName: schoolName,
      forceRefresh: true, // Force fresh data for testing
    );
  }
}
