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
    int limit = 10, // Smaller limit for dashboard
  }) async {
    final cacheKey = _generateOptimizedCacheKey(
      supervisorId: supervisorId,
      supervisorIds: supervisorIds,
      status: status,
      limit: limit,
      page: 1,
    );

    // Check cache first
    final cached = getFromCache<List<MaintenanceReport>>(cacheKey);
    if (cached != null) {
      if (kDebugMode) {
        debugPrint('⚡ Dashboard cache hit - returning ${cached.length} maintenance reports');
      }
      return cached;
    }

    return await executeQuery(
      operation: 'fetchMaintenanceReportsForDashboard',
      query: () async {
        // 🚀 FIX: Use simplest possible Supabase query approach
        if (kDebugMode) {
          debugPrint('🔍 DEBUG: Using simplest query approach');
          if (supervisorIds != null) {
            debugPrint('🔍 DEBUG: Supervisor IDs: ${supervisorIds.length} IDs');
          }
        }

        // 🚀 FIX: Use basic query without complex filtering
        final response = await client
            .from('maintenance_reports')
            .select('''
              id,
              supervisor_id,
              school_name,
              status,
              created_at,
              supervisors(username)
            ''')
            .limit(limit * 2) // Get more records for filtering
            .order('created_at', ascending: false);

        if (kDebugMode) {
          debugPrint('🔍 DEBUG: Executing simple query...');
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
          
          // Apply limit
          if (filteredResults.length > limit) {
            filteredResults = filteredResults.take(limit).toList();
          }
          
          if (kDebugMode) {
            debugPrint('🔍 DEBUG: Applied in-memory filtering: ${results.length} -> ${filteredResults.length}');
            debugPrint('✅ Dashboard: Fetched ${filteredResults.length} maintenance reports');
          }
          return filteredResults;
        } else {
          throw Exception('Failed to load dashboard maintenance reports');
        }
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
