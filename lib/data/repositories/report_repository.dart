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
        // 🚀 FIX: Use simplest possible Supabase query approach
        final itemsPerPage = limit ?? 20; // Default to 20 items per page
        final currentPage = page ?? 1;
        final offset = (currentPage - 1) * itemsPerPage;
        
        // 🚀 FIX: Use basic query without complex filtering
        final response = await client
            .from('reports')
            .select('''
              id,
              supervisor_id,
              type,
              status,
              priority,
              school_name,
              created_at,
              supervisors(username)
            ''')
            .limit(itemsPerPage + 10) // Get more records for filtering
            .order('created_at', ascending: false);

        if (kDebugMode) {
          debugPrint('🚀 Executing simple reports query...');
          debugPrint('  Items per page: $itemsPerPage');
          debugPrint('  Current page: $currentPage');
          debugPrint('  Offset: $offset');
        }

        if (response is List) {
          final results = response.cast<Map<String, dynamic>>();
          
          // 🚀 FIX: Apply all filtering in memory
          List<Map<String, dynamic>> filteredResults = results;
          
          // Filter by supervisor IDs
          if (supervisorId != null) {
            filteredResults = filteredResults.where((item) {
              final itemSupervisorId = item['supervisor_id']?.toString();
              return itemSupervisorId == supervisorId;
            }).toList();
          } else if (supervisorIds != null && supervisorIds.isNotEmpty) {
            filteredResults = filteredResults.where((item) {
              final itemSupervisorId = item['supervisor_id']?.toString();
              return itemSupervisorId != null && supervisorIds.contains(itemSupervisorId);
            }).toList();
          }
          
          // Filter by status
          if (status != null) {
            filteredResults = filteredResults.where((item) {
              final itemStatus = item['status']?.toString();
              return itemStatus == status;
            }).toList();
          }
          
          // Filter by type
          if (type != null) {
            filteredResults = filteredResults.where((item) {
              final itemType = item['type']?.toString();
              return itemType == type;
            }).toList();
          }
          
          // Filter by priority
          if (priority != null) {
            filteredResults = filteredResults.where((item) {
              final itemPriority = item['priority']?.toString();
              return itemPriority == priority;
            }).toList();
          }
          
          // Filter by school name
          if (schoolName != null) {
            filteredResults = filteredResults.where((item) {
              final itemSchoolName = item['school_name']?.toString();
              return itemSchoolName == schoolName;
            }).toList();
          }
          
          // Apply pagination
          if (filteredResults.length > offset + itemsPerPage) {
            filteredResults = filteredResults.skip(offset).take(itemsPerPage).toList();
          } else if (filteredResults.length > offset) {
            filteredResults = filteredResults.skip(offset).toList();
          } else {
            filteredResults = [];
          }
          
          if (kDebugMode) {
            debugPrint('✅ Successfully fetched ${filteredResults.length} reports from database');
          }
          return filteredResults;
        } else {
          if (kDebugMode) {
            debugPrint('❌ Unexpected reports response type: ${response.runtimeType}');
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

  /// 🚀 PERFORMANCE OPTIMIZATION: Fetch reports for dashboard with minimal data
  Future<List<Report>> fetchReportsForDashboard({
    String? supervisorId,
    List<String>? supervisorIds,
    String? type,
    String? status,
    String? priority,
    String? schoolName,
    bool forceRefresh = false,
    int limit = 50, // Larger limit for dashboard but still limited
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
      page: 1,
    );

    // 🚀 PERFORMANCE OPTIMIZATION: Check cache first for instant response
    if (!forceRefresh) {
      final cached = getFromCache<List<Report>>(cacheKey);
      if (cached != null) {
        if (kDebugMode) {
          debugPrint('⚡ ReportRepository: Dashboard cache hit - returning ${cached.length} reports instantly');
        }
        return cached;
      }
    }

    // 🚀 PERFORMANCE OPTIMIZATION: Use BaseRepository's executeQuery with optimized parameters
    return await executeQuery(
      operation: 'fetchReportsForDashboard',
      query: () async {
        // 🚀 PERFORMANCE OPTIMIZATION: Use database-level filtering for better performance
        if (kDebugMode) {
          debugPrint('🔍 DEBUG: Using optimized database-level filtering');
          if (supervisorIds != null) {
            debugPrint('🔍 DEBUG: Supervisor IDs: ${supervisorIds.length} IDs');
          }
          debugPrint('🔍 DEBUG: Requested limit: $limit');
        }

        // 🚀 PERFORMANCE OPTIMIZATION: Build query with database-level filters
        PostgrestList response;
        
        if (kDebugMode) {
          debugPrint('🔍 ReportRepository: Building query with supervisorId: $supervisorId, supervisorIds: $supervisorIds');
        }
        
        if (supervisorId != null) {
          // Single supervisor filter - use database-level filtering
          if (kDebugMode) {
            debugPrint('🔍 ReportRepository: Using single supervisor filter: $supervisorId');
          }
          response = await client
              .from('reports')
              .select('''
                id,
                supervisor_id,
                type,
                status,
                priority,
                school_name,
                created_at,
                supervisors(username)
              ''')
              .eq('supervisor_id', supervisorId)
              .order('created_at', ascending: false)
              .limit(limit);
        } else if (supervisorIds != null && supervisorIds.isNotEmpty) {
          // Multiple supervisor filter - use database-level filtering
          if (kDebugMode) {
            debugPrint('🔍 ReportRepository: Using multiple supervisor filter: $supervisorIds');
          }
          response = await client
              .from('reports')
              .select('''
                id,
                supervisor_id,
                type,
                status,
                priority,
                school_name,
                created_at,
                supervisors(username)
              ''')
              .inFilter('supervisor_id', supervisorIds)
              .order('created_at', ascending: false)
              .limit(limit);
        } else {
          // No supervisor filter - get all records
          if (kDebugMode) {
            debugPrint('🔍 ReportRepository: No supervisor filter - getting all records');
          }
          response = await client
              .from('reports')
              .select('''
                id,
                supervisor_id,
                type,
                status,
                priority,
                school_name,
                created_at,
                supervisors(username)
              ''')
              .order('created_at', ascending: false)
              .limit(limit);
        }

        // Apply additional filters if needed
        if (status != null || type != null || priority != null || schoolName != null) {
          // For additional filters, we'll need to filter in memory
          // This is a trade-off for the complex filtering requirements
          final results = response.cast<Map<String, dynamic>>();
          List<Map<String, dynamic>> filteredResults = results;
          
          if (status != null) {
            filteredResults = filteredResults.where((item) {
              final itemStatus = item['status']?.toString();
              return itemStatus == status;
            }).toList();
          }
          if (type != null) {
            filteredResults = filteredResults.where((item) {
              final itemType = item['type']?.toString();
              return itemType == type;
            }).toList();
          }
          if (priority != null) {
            filteredResults = filteredResults.where((item) {
              final itemPriority = item['priority']?.toString();
              return itemPriority == priority;
            }).toList();
          }
          if (schoolName != null) {
            filteredResults = filteredResults.where((item) {
              final itemSchoolName = item['school_name']?.toString() ?? '';
              return itemSchoolName.toLowerCase().contains(schoolName.toLowerCase());
            }).toList();
          }
          
          if (kDebugMode) {
            debugPrint('🔍 DEBUG: Applied additional filters: ${results.length} -> ${filteredResults.length}');
          }
          
          return filteredResults;
        }

        if (kDebugMode) {
          debugPrint('✅ Dashboard: Fetched ${response.length} reports with database filtering');
        }
        return response.cast<Map<String, dynamic>>();
      },
      cacheParams: {
        'supervisorId': supervisorId,
        'supervisorIds': supervisorIds,
        'type': type,
        'status': status,
        'priority': priority,
        'schoolName': schoolName,
        'limit': limit,
        'page': 1,
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
    // 🚀 FIX: Use simple query approach
    final response = await client
        .from('reports')
        .select('*, supervisors(username)')
        .limit(1)
        .order('created_at', ascending: false);

    if (response is List && response.isNotEmpty) {
      // Find the specific ID in memory
      final results = response.cast<Map<String, dynamic>>();
      final item = results.firstWhere(
        (item) => item['id']?.toString() == id,
        orElse: () => throw Exception('Report not found'),
      );
      return Report.fromMap(item);
    }
    
    throw Exception('Report not found');
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
}
