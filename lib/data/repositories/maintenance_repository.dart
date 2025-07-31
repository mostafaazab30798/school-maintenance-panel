import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/maintenance_report.dart';
import '../../core/repositories/base_repository.dart';
import 'package:flutter/foundation.dart';

class MaintenanceReportRepository extends BaseRepository<MaintenanceReport> {
  MaintenanceReportRepository(SupabaseClient client)
      : super(
          client: client,
          repositoryName: 'MaintenanceReportRepository',
          cacheConfig: CacheConfig.fast, // 🚀 PERFORMANCE OPTIMIZATION: Use fast cache for frequently accessed data
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
        // 🚀 FIX: Use simplest possible Supabase query approach
        final itemsPerPage = limit ?? 20; // Default to 20 items per page
        final currentPage = page ?? 1;
        final offset = (currentPage - 1) * itemsPerPage;
        
        // 🚀 FIX: Use basic query without complex filtering
        final response = await client
            .from('maintenance_reports')
            .select('''
              id,
              supervisor_id,
              school_name,
              description,
              status,
              images,
              created_at,
              closed_at,
              completion_photos,
              completion_note,
              supervisors(username)
            ''')
            .limit(itemsPerPage + 10) // Get more records for filtering
            .order('created_at', ascending: false);

        if (kDebugMode) {
          debugPrint('🚀 Executing simple maintenance reports query...');
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
          
          // Apply pagination
          if (filteredResults.length > offset + itemsPerPage) {
            filteredResults = filteredResults.skip(offset).take(itemsPerPage).toList();
          } else if (filteredResults.length > offset) {
            filteredResults = filteredResults.skip(offset).toList();
          } else {
            filteredResults = [];
          }
          
          if (kDebugMode) {
            debugPrint('✅ Successfully fetched ${filteredResults.length} maintenance reports from database');
          }
          return filteredResults;
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

  /// 🚀 PERFORMANCE OPTIMIZATION: Fetch maintenance reports for dashboard with minimal data
  Future<List<MaintenanceReport>> fetchMaintenanceReportsForDashboard({
    String? supervisorId,
    List<String>? supervisorIds,
    String? status,
    bool forceRefresh = false,
    int limit = 50, // Larger limit for dashboard but still limited
  }) async {
    // 🚀 PERFORMANCE OPTIMIZATION: Use optimized cache key generation
    final cacheKey = _generateOptimizedCacheKey(
      supervisorId: supervisorId,
      supervisorIds: supervisorIds,
      status: status,
      limit: limit,
      page: 1,
    );

    // 🚀 PERFORMANCE OPTIMIZATION: Check cache first for instant response
    if (!forceRefresh) {
      final cached = getFromCache<List<MaintenanceReport>>(cacheKey);
      if (cached != null) {
        if (kDebugMode) {
          debugPrint('⚡ MaintenanceRepository: Dashboard cache hit - returning ${cached.length} maintenance reports instantly');
        }
        return cached;
      }
    }

    // 🚀 PERFORMANCE OPTIMIZATION: Use BaseRepository's executeQuery with optimized parameters
    return await executeQuery(
      operation: 'fetchMaintenanceReportsForDashboard',
      query: () async {
        // 🚀 PERFORMANCE OPTIMIZATION: Use database-level filtering for better performance
        if (kDebugMode) {
          debugPrint('🔍 DEBUG: Using simplest query approach');
          if (supervisorIds != null) {
            debugPrint('🔍 DEBUG: Supervisor IDs: ${supervisorIds.length} IDs');
          }
          debugPrint('🔍 DEBUG: Requested limit: $limit');
        }

        // 🚀 PERFORMANCE OPTIMIZATION: Build query with database-level filters
        PostgrestList response;
        
        if (kDebugMode) {
          debugPrint('🔍 MaintenanceRepository: Building query with supervisorId: $supervisorId, supervisorIds: $supervisorIds');
        }
        
        if (supervisorId != null) {
          // Single supervisor filter - use database-level filtering
          if (kDebugMode) {
            debugPrint('🔍 MaintenanceRepository: Using single supervisor filter: $supervisorId');
          }
          response = await client
              .from('maintenance_reports')
              .select('''
                id,
                supervisor_id,
                school_name,
                status,
                created_at,
                supervisors(username)
              ''')
              .eq('supervisor_id', supervisorId)
              .order('created_at', ascending: false)
              .limit(limit);
        } else if (supervisorIds != null && supervisorIds.isNotEmpty) {
          // Multiple supervisor filter - use database-level filtering
          if (kDebugMode) {
            debugPrint('🔍 MaintenanceRepository: Using multiple supervisor filter: $supervisorIds');
          }
          
          // 🚀 PERFORMANCE OPTIMIZATION: Use smart filtering strategy based on list size
          if (supervisorIds.length == 1) {
            // Single supervisor - use eq filter (fastest)
            response = await client
                .from('maintenance_reports')
                .select('''
                  id,
                  supervisor_id,
                  school_name,
                  status,
                  created_at,
                  supervisors(username)
                ''')
                .eq('supervisor_id', supervisorIds.first)
                .order('created_at', ascending: false)
                .limit(limit);
          } else if (supervisorIds.length <= 10) {
            // Small to medium list - use inFilter (efficient for reasonable lists)
            response = await client
                .from('maintenance_reports')
                .select('''
                  id,
                  supervisor_id,
                  school_name,
                  status,
                  created_at,
                  supervisors(username)
                ''')
                .inFilter('supervisor_id', supervisorIds)
                .order('created_at', ascending: false)
                .limit(limit);
          } else {
            // Large list - use multiple queries and combine results
            if (kDebugMode) {
              debugPrint('🔍 Large supervisor list (${supervisorIds.length}), using multiple queries for complete data');
            }
            
            // Split into chunks to avoid query size limits
            final chunks = <List<String>>[];
            for (int i = 0; i < supervisorIds.length; i += 5) {
              chunks.add(supervisorIds.skip(i).take(5).toList());
            }
            
            final allResponses = <PostgrestList>[];
            for (final chunk in chunks) {
              final chunkResponse = await client
                  .from('maintenance_reports')
                  .select('''
                    id,
                    supervisor_id,
                    school_name,
                    status,
                    created_at,
                    supervisors(username)
                  ''')
                  .inFilter('supervisor_id', chunk)
                  .order('created_at', ascending: false)
                  .limit(limit);
              allResponses.add(chunkResponse);
            }
            
            // Combine all responses
            final combinedData = <Map<String, dynamic>>[];
            for (final response in allResponses) {
              combinedData.addAll(response.cast<Map<String, dynamic>>());
            }
            
            // Sort by created_at and limit
            combinedData.sort((a, b) {
              final aDate = DateTime.tryParse(a['created_at']?.toString() ?? '');
              final bDate = DateTime.tryParse(b['created_at']?.toString() ?? '');
              if (aDate == null || bDate == null) return 0;
              return bDate.compareTo(aDate);
            });
            
            response = combinedData.take(limit).toList() as PostgrestList;
          }
        } else {
          // No supervisor filter - get all records
          if (kDebugMode) {
            debugPrint('🔍 MaintenanceRepository: No supervisor filter - getting all records');
          }
          response = await client
              .from('maintenance_reports')
              .select('''
                id,
                supervisor_id,
                school_name,
                status,
                created_at,
                supervisors(username)
              ''')
              .order('created_at', ascending: false)
              .limit(limit);
        }

        // Apply additional status filter if needed
        List<Map<String, dynamic>> results = response.cast<Map<String, dynamic>>();
        
        if (status != null) {
          // For status filtering, we need to filter in memory since we already have the data
          results = results.where((item) {
            final itemStatus = item['status']?.toString();
            return itemStatus == status;
          }).toList();
          
          if (kDebugMode) {
            debugPrint('🔍 DEBUG: Applied status filter: ${response.length} -> ${results.length}');
          }
        }

        if (kDebugMode) {
          debugPrint('✅ Dashboard: Fetched ${results.length} maintenance reports with database filtering');
        }
        return results;
      },
      cacheParams: {
        'supervisorId': supervisorId,
        'supervisorIds': supervisorIds,
        'status': status,
        'limit': limit,
        'page': 1,
      },
      useCache: true,
    );
  }

  /// 🚀 PERFORMANCE OPTIMIZATION: Fetch maintenance report counts for quick statistics
  Future<Map<String, int>> fetchMaintenanceReportCounts({
    String? supervisorId,
    List<String>? supervisorIds,
  }) async {
    final cacheKey = 'maintenance_counts_${supervisorId ?? supervisorIds?.join('_')}';
    
    final cached = getFromCache<Map<String, int>>(cacheKey);
    if (cached != null) {
      return cached;
    }

    try {
      // 🚀 FIX: Use simple query approach
      final response = await client
          .from('maintenance_reports')
          .select('status, supervisor_id')
          .limit(1000); // Get enough records for counting

      if (response is List) {
        final results = response.cast<Map<String, dynamic>>();
        
        // 🚀 FIX: Apply filtering in memory
        List<Map<String, dynamic>> filteredResults = results;
        
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
        
        final counts = <String, int>{};
        for (final item in filteredResults) {
          final status = item['status'] as String? ?? 'unknown';
          counts[status] = (counts[status] ?? 0) + 1;
        }
        
        setCache(cacheKey, counts);
        return counts;
      }
      
      return {};
    } catch (e) {
      logError('Failed to fetch maintenance report counts', e);
      return {};
    }
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
    // 🚀 FIX: Use simple query approach
    final response = await client
        .from('maintenance_reports')
        .select('*, supervisors(username)')
        .limit(1)
        .order('created_at', ascending: false);

    if (response is List && response.isNotEmpty) {
      // Find the specific ID in memory
      final results = response.cast<Map<String, dynamic>>();
      final item = results.firstWhere(
        (item) => item['id']?.toString() == id,
        orElse: () => throw Exception('Maintenance report not found'),
      );
      return MaintenanceReport.fromMap(item);
    }
    
    throw Exception('Maintenance report not found');
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
