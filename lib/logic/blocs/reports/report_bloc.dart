import 'package:flutter_bloc/flutter_bloc.dart';
import 'report_event.dart';
import 'report_state.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../data/models/report.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/mixins/admin_filter_mixin.dart';
import '../../../core/services/performance_monitoring_service.dart';
import '../../../core/services/error_handling_service.dart';
import 'package:flutter/foundation.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> with AdminFilterMixin {
  final ReportRepository reportRepository;
  final CacheService _cacheService = CacheService();

  @override
  final AdminService adminService;

  ReportBloc(this.reportRepository, this.adminService)
      : super(ReportInitial()) {
    on<FetchReports>(_onFetchReports);
  }

  /// Invalidates all cached reports in the repository
  void invalidateCache() {
    reportRepository.invalidateCache();
    _cacheService.invalidatePattern('reports');
  }

  /// Clears all caches when user changes to prevent cross-user data contamination
  void clearUserCache() {
    reportRepository.invalidateCache();
    _cacheService.invalidatePattern('reports');
    print('🐛 DEBUG: Cleared report cache for user change');
  }

  Future<void> _onFetchReports(
      FetchReports event, Emitter<ReportState> emit) async {
    
    final cacheKey = _generateCacheKey(event);

    // 🚀 PERFORMANCE OPTIMIZATION: Check cache first for instant response
    if (!event.forceRefresh) {
      final cachedReports = _cacheService.getCached<List<Report>>(cacheKey);
      if (cachedReports != null) {
        // ⚡ Emit cached data first for instant loading
        emit(ReportLoaded(cachedReports));
        
        if (kDebugMode) {
          debugPrint('⚡ ReportBloc: Cache hit - returning ${cachedReports.length} reports instantly');
        }

        // If cache is near expiry, refresh in background
        if (_cacheService.isNearExpiry(cacheKey)) {
          _refreshReportsInBackground(event, emit);
        }
        return;
      }
    }

    // Show loading only if no cached data
    if (state is! ReportLoaded) {
      emit(ReportLoading());
    }

    final performanceTimer = PerformanceMonitoringService().startOperation(
      'ReportBloc:FetchReports',
      metadata: {
        'supervisorId': event.supervisorId,
        'type': event.type,
        'status': event.status,
        'priority': event.priority,
        'forceRefresh': event.forceRefresh,
      },
    );

    final totalStopwatch = Stopwatch()..start();

    logAdminFilterDebug(
        'Starting report fetch with filters: supervisorId=${event.supervisorId}, type=${event.type}, status=${event.status}, priority=${event.priority}, forceRefresh=${event.forceRefresh}',
        context: 'ReportBloc');

    try {
      final reports =
          await ErrorHandlingService().executeWithResilience<List<Report>>(
        'ReportBloc:FetchReports',
        () async {
          List<Report> reports;

          // 🚀 PERFORMANCE OPTIMIZATION: Optimize admin filtering logic
          if (event.supervisorId == null) {
            logAdminFilterDebug(
                'No specific supervisorId - applying admin filtering',
                context: 'ReportBloc');

            // 🚀 PERFORMANCE OPTIMIZATION: Quick access check to prevent unnecessary processing
            final isSuperAdmin = await adminService.isCurrentUserSuperAdmin();
            if (!isSuperAdmin) {
              final supervisorIds =
                  await adminService.getCurrentAdminSupervisorIds();
              if (supervisorIds.isEmpty) {
                return <Report>[];
              }
            }

            // Use AdminFilterMixin to apply admin-based filtering
            final filterResult = await applyAdminFilter<Report>(
              fetchAllData: () async {
                return await reportRepository.fetchReports(
                  type: event.type,
                  status: event.status,
                  priority: event.priority,
                  schoolName: event.schoolName,
                  forceRefresh: event.forceRefresh,
                  limit: event.limit,
                  page: event.page,
                );
              },
              fetchFilteredData: (supervisorIds) async {
                return await reportRepository.fetchReports(
                  supervisorIds: supervisorIds,
                  type: event.type,
                  status: event.status,
                  priority: event.priority,
                  schoolName: event.schoolName,
                  forceRefresh: event.forceRefresh,
                  limit: event.limit,
                  page: event.page,
                );
              },
              debugContext: 'Reports',
            );

            reports = filterResult.data;
          } else {
            // 🚀 PERFORMANCE OPTIMIZATION: Specific supervisor requested - validate access first
            final hasAccess = await hasAccessToSupervisor(
              supervisorId: event.supervisorId!,
              debugContext: 'Reports',
            );

            if (!hasAccess) {
              throw Exception('Access denied to supervisor data');
            }

            reports = await reportRepository.fetchReports(
              supervisorId: event.supervisorId,
              type: event.type,
              status: event.status,
              priority: event.priority,
              schoolName: event.schoolName,
              forceRefresh: event.forceRefresh,
              limit: event.limit,
              page: event.page,
            );
          }

          return reports;
        },
        timeout: const Duration(seconds: 15), // 🚀 Reduced timeout for faster failure detection
        fallbackValue: <Report>[],
      );

      totalStopwatch.stop();
      if (kDebugMode) {
        debugPrint(
            '🐛 DEBUG: Total ReportBloc operation took ${totalStopwatch.elapsedMilliseconds}ms');
      }

      // 🚀 PERFORMANCE OPTIMIZATION: Cache the fresh data with optimized storage
      _cacheService.setCached(cacheKey, reports);
      if (kDebugMode) {
        debugPrint('💾 Reports cached for 3 minutes: ${reports.length} reports');
      }

      performanceTimer.stop(success: true);
      emit(ReportLoaded(reports));
    } catch (error, stackTrace) {
      await ErrorHandlingService().handleError(
        'ReportBloc:FetchReports',
        error,
        stackTrace,
        metadata: {
          'supervisorId': event.supervisorId,
          'type': event.type,
          'status': event.status,
          'priority': event.priority,
        },
      );

      performanceTimer.stop(success: false, errorMessage: error.toString());
      emit(ReportError(error.toString()));
    }
  }

  /// 🚀 PERFORMANCE OPTIMIZATION: Generate optimized cache key
  String _generateCacheKey(FetchReports event) {
    final params = <String, dynamic>{};
    
    if (event.supervisorId != null) {
      params['supervisorId'] = event.supervisorId;
    }
    if (event.type != null) params['type'] = event.type;
    if (event.status != null) params['status'] = event.status;
    if (event.priority != null) params['priority'] = event.priority;
    if (event.schoolName != null) params['schoolName'] = event.schoolName;
    if (event.limit != null) params['limit'] = event.limit;
    if (event.page != null) params['page'] = event.page;
    
    // Sort parameters for consistent cache key
    final sortedParams = Map.fromEntries(
        params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
    
    return 'ReportBloc:FetchReports:${sortedParams.toString()}';
  }

  /// 🚀 PERFORMANCE OPTIMIZATION: Background refresh with optimized logic
  Future<void> _refreshReportsInBackground(
      FetchReports event, Emitter<ReportState> emit) async {
    if (kDebugMode) {
      debugPrint('🔄 Starting background refresh for reports...');
    }

    try {
      final reports = await ErrorHandlingService().executeWithResilience<List<Report>>(
        'ReportBloc:BackgroundRefresh',
        () async {
          if (event.supervisorId == null) {
            final filterResult = await applyAdminFilter<Report>(
              fetchAllData: () => reportRepository.fetchReports(
                type: event.type,
                status: event.status,
                priority: event.priority,
                schoolName: event.schoolName,
                forceRefresh: true,
                limit: event.limit,
                page: event.page,
              ),
              fetchFilteredData: (supervisorIds) =>
                  reportRepository.fetchReports(
                supervisorIds: supervisorIds,
                type: event.type,
                status: event.status,
                priority: event.priority,
                schoolName: event.schoolName,
                forceRefresh: true,
                limit: event.limit,
                page: event.page,
              ),
              debugContext: 'Reports',
            );
            return filterResult.data;
          } else {
            return await reportRepository.fetchReports(
              supervisorId: event.supervisorId,
              type: event.type,
              status: event.status,
              priority: event.priority,
              schoolName: event.schoolName,
              forceRefresh: true,
              limit: event.limit,
              page: event.page,
            );
          }
        },
        timeout: const Duration(seconds: 15), // 🚀 Reduced timeout
        fallbackValue: <Report>[],
      );

      final cacheKey = _generateCacheKey(event);
      _cacheService.setCached(cacheKey, reports);

      // Only emit if data has actually changed
      if (state is ReportLoaded) {
        final currentReports = (state as ReportLoaded).reports;
        if (_isReportsDataDifferent(currentReports, reports)) {
          emit(ReportLoaded(reports));
          if (kDebugMode) {
            debugPrint('✅ Background refresh completed with new reports data');
          }
        } else {
          if (kDebugMode) {
            debugPrint('✅ Background refresh completed - no changes');
          }
        }
      }
    } catch (e) {
      // Fail silently for background refresh
      if (kDebugMode) {
        debugPrint('Background reports refresh failed: $e');
      }
    }
  }

  /// 🚀 PERFORMANCE OPTIMIZATION: Optimized data comparison
  bool _isReportsDataDifferent(List<Report> current, List<Report> newData) {
    if (current.length != newData.length) return true;
    
    // Quick comparison by IDs first
    final currentIds = current.map((r) => r.id).toSet();
    final newIds = newData.map((r) => r.id).toSet();
    
    if (currentIds != newIds) return true;
    
    // If IDs match, check for any updates
    for (int i = 0; i < current.length; i++) {
      if (current[i].updatedAt != newData[i].updatedAt) {
        return true;
      }
    }
    
    return false;
  }
}
