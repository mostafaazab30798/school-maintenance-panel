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
    // 🚀 Create cache key based on filters
    final cacheKey = _generateCacheKey(event);

    // 🚀 Check cache first if not forcing refresh (instant loading like dashboard)
    if (!event.forceRefresh) {
      final cachedReports = _cacheService.getCached<List<Report>>(cacheKey);
      if (cachedReports != null) {
        // ⚡ Emit cached data first for instant loading
        emit(ReportLoaded(cachedReports));

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

          // If no specific supervisorId is provided, use admin filtering
          if (event.supervisorId == null) {
            logAdminFilterDebug(
                'No specific supervisorId - applying admin filtering',
                context: 'ReportBloc');

            // Quick access check to prevent unnecessary processing
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
                );
              },
              debugContext: 'Reports',
            );

            reports = filterResult.data;
          } else {
            // Specific supervisor requested - validate access first
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
            );
          }

          return reports;
        },
        timeout: const Duration(seconds: 30),
        fallbackValue: <Report>[],
      );

      totalStopwatch.stop();
      print(
          '🐛 DEBUG: Total ReportBloc operation took ${totalStopwatch.elapsedMilliseconds}ms');

      // 🚀 Cache the fresh data
      _cacheService.setCached(cacheKey, reports);
      print('💾 Reports cached for 3 minutes: ${reports.length} reports');

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

  /// Generate cache key based on filters
  String _generateCacheKey(FetchReports event) {
    final parts = <String>['reports'];
    if (event.supervisorId != null) parts.add('sup_${event.supervisorId}');
    if (event.type != null) parts.add('type_${event.type}');
    if (event.status != null) parts.add('status_${event.status}');
    if (event.priority != null) parts.add('priority_${event.priority}');
    if (event.schoolName != null) parts.add('school_${event.schoolName}');
    return parts.join('_');
  }

  /// Refresh reports in background (like dashboard)
  Future<void> _refreshReportsInBackground(
      FetchReports event, Emitter<ReportState> emit) async {
    try {
      print('🔄 Background refresh started for reports...');

      final reports =
          await ErrorHandlingService().executeWithResilience<List<Report>>(
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
              ),
              fetchFilteredData: (supervisorIds) =>
                  reportRepository.fetchReports(
                supervisorIds: supervisorIds,
                type: event.type,
                status: event.status,
                priority: event.priority,
                schoolName: event.schoolName,
                forceRefresh: true,
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
            );
          }
        },
        timeout: const Duration(seconds: 30),
        fallbackValue: <Report>[],
      );

      final cacheKey = _generateCacheKey(event);
      _cacheService.setCached(cacheKey, reports);

      // Only emit if data has actually changed
      if (state is ReportLoaded) {
        final currentReports = (state as ReportLoaded).reports;
        if (_isReportsDataDifferent(currentReports, reports)) {
          emit(ReportLoaded(reports));
          print('✅ Background refresh completed with new reports data');
        } else {
          print('✅ Background refresh completed - no changes');
        }
      }
    } catch (e) {
      // Fail silently for background refresh
      print('Background reports refresh failed: $e');
    }
  }

  /// Check if reports data has changed
  bool _isReportsDataDifferent(List<Report> current, List<Report> fresh) {
    if (current.length != fresh.length) return true;
    // Could add more sophisticated comparison if needed
    return false;
  }
}
