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
    bool forceRefresh = false,
    int? limit,
  }) async {
    // 🔧 IMMEDIATE FIX: Clear cache on type mismatch to prevent 6+ second failures
    try {
      // Clear corrupted cache entries before any operation
      clearCache('fetchReports');
      print('🔧 Cleared potentially corrupted cache for fetchReports');
    } catch (e) {
      print('⚠️ Cache clear failed: $e');
    }

    // 🐛 DEBUG: Log the exact parameters being used
    if (kDebugMode) {
      debugPrint('🔍 ReportRepository.fetchReports called with:');
      debugPrint('  supervisorId: $supervisorId');
      debugPrint('  supervisorIds: $supervisorIds');
      debugPrint('  type: $type');
      debugPrint('  status: $status');
      debugPrint('  priority: $priority');
      debugPrint('  forceRefresh: $forceRefresh');
      debugPrint('  limit: $limit');
    }

    // Clear any corrupted cache entries on type mismatch
    try {
      // Use BaseRepository's executeQuery for professional caching and error handling
      return await executeQuery(
        operation: 'fetchReports',
        query: () async {
          dynamic query =
              client.from('reports').select('*, supervisors(username)');

          if (supervisorId != null) {
            query = query.eq('supervisor_id', supervisorId);
            if (kDebugMode) {
              debugPrint('🔍 Added supervisorId filter: $supervisorId');
            }
          }
          if (supervisorIds != null && supervisorIds.isNotEmpty) {
            query = query.inFilter('supervisor_id', supervisorIds);
            if (kDebugMode) {
              debugPrint('🔍 Added supervisorIds filter: $supervisorIds');
            }
          }
          if (type != null) {
            query = query.eq('type', type);
            if (kDebugMode) {
              debugPrint('🔍 Added type filter: $type');
            }
          }
          if (status != null) {
            query = query.eq('status', status);
            if (kDebugMode) {
              debugPrint('🔍 Added status filter: $status');
            }
          }
          if (priority != null) {
            query = query.eq('priority', priority);
            if (kDebugMode) {
              debugPrint('🔍 Added priority filter: $priority');
            }
          }

          // Order the results by created_at in descending order
          query = query.order('created_at', ascending: false);

          // Add pagination for better performance
          if (limit != null) {
            query = query.limit(limit);
          }

          if (kDebugMode) {
            debugPrint('🚀 Executing Supabase query...');
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
          'limit': limit,
          'userId': client.auth.currentUser
              ?.id, // Add current user ID to prevent cache collision
        },
        useCache: true, // Enable optimized caching
        forceRefresh: forceRefresh, // Respect the forceRefresh parameter
      );
    } catch (e) {
      // If cache type error, clear cache and retry without cache
      if (e.toString().contains('CacheEntry') ||
          e.toString().contains('not a subtype')) {
        print('🔧 Cache type mismatch detected - clearing corrupted cache');
        clearCache('fetchReports'); // Clear corrupted cache

        // Retry without cache
        return await executeQuery(
          operation: 'fetchReports',
          query: () async {
            dynamic query =
                client.from('reports').select('*, supervisors(username)');

            if (supervisorId != null) {
              query = query.eq('supervisor_id', supervisorId);
            }
            if (supervisorIds != null && supervisorIds.isNotEmpty) {
              query = query.inFilter('supervisor_id', supervisorIds);
            }
            if (type != null) {
              query = query.eq('type', type);
            }
            if (status != null) {
              query = query.eq('status', status);
            }
            if (priority != null) {
              query = query.eq('priority', priority);
            }

            query = query.order('created_at', ascending: false);

            if (limit != null) {
              query = query.limit(limit);
            }

            final response = await query;
            if (response is List) {
              return response.cast<Map<String, dynamic>>();
            } else {
              throw Exception('Failed to load reports');
            }
          },
          cacheParams: {
            'supervisorId': supervisorId,
            'supervisorIds': supervisorIds,
            'type': type,
            'status': status,
            'priority': priority,
            'limit': limit,
            'userId': client.auth.currentUser?.id,
          },
          useCache: false, // Force fresh data after cache clear
          forceRefresh: true,
        );
      }
      rethrow; // Re-throw if not a cache issue
    }
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
  Future<void> testReportFiltering() async {
    if (!kDebugMode) return;

    try {
      debugPrint('🧪 Testing report filtering consistency...');

      // Test 1: Get ALL reports (no filters)
      final allReports = await client
          .from('reports')
          .select('id, supervisor_id, type, status, priority, school_name')
          .limit(10);
      debugPrint('🧪 Total reports in DB (sample): ${allReports.length}');

      // Test 2: Get current user info
      final user = client.auth.currentUser;
      debugPrint('🧪 Current user ID: ${user?.id}');

      // Test 3: Check admin_supervisors for current user
      if (user != null) {
        final adminSupervisors = await client
            .from('admin_supervisors')
            .select('supervisor_id')
            .eq('admin_id', user.id);
        debugPrint('🧪 Admin supervisors: $adminSupervisors');

        // Test 4: If we have supervisors, test filtering
        if (adminSupervisors.isNotEmpty) {
          final supervisorIds = (adminSupervisors as List)
              .map((item) => item['supervisor_id'] as String)
              .toList();

          final filteredReports = await client
              .from('reports')
              .select('id, supervisor_id, school_name')
              .inFilter('supervisor_id', supervisorIds)
              .limit(10);
          debugPrint('🧪 Filtered reports: ${filteredReports.length}');
          debugPrint('🧪 Filtered reports sample: $filteredReports');
        }
      }

      debugPrint('🧪 Report filtering test completed');
    } catch (e) {
      debugPrint('🧪 Test failed: $e');
    }
  }
}
