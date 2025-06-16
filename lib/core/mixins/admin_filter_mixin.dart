import 'package:flutter/foundation.dart';
import '../services/admin_service.dart';
import '../services/admin_filter_service.dart';

/// Mixin that provides admin filtering functionality to blocs
///
/// This mixin centralizes admin filtering logic and provides a consistent
/// interface for applying admin-based data filtering across different blocs.
///
/// Usage:
/// ```dart
/// class MyBloc extends Bloc<MyEvent, MyState> with AdminFilterMixin {
///   MyBloc(super.initialState, this.adminService);
///
///   @override
///   final AdminService adminService;
/// }
/// ```
mixin AdminFilterMixin {
  /// AdminService instance for checking admin permissions
  AdminService get adminService;

  /// Applies admin-based filtering to data
  ///
  /// This method is a convenience wrapper around AdminFilterService.filterByAdminPermissions
  /// that provides a consistent interface for blocs.
  ///
  /// [fetchAllData] - Function to fetch all data (for super admins)
  /// [fetchFilteredData] - Function to fetch filtered data by supervisor IDs
  /// [debugContext] - Optional context for debugging
  Future<FilterResult<T>> applyAdminFilter<T>({
    required Future<List<T>> Function() fetchAllData,
    required Future<List<T>> Function(List<String> supervisorIds)
        fetchFilteredData,
    String? debugContext,
  }) async {
    return AdminFilterService.filterByAdminPermissions<T>(
      adminService: adminService,
      fetchAllData: fetchAllData,
      fetchFilteredData: fetchFilteredData,
      debugContext: debugContext,
    );
  }

  /// Checks if the current admin has access to a specific supervisor
  ///
  /// This is useful for validating access before performing operations
  /// on supervisor-specific data.
  Future<bool> hasAccessToSupervisor({
    required String supervisorId,
    String? debugContext,
  }) async {
    return AdminFilterService.hasAccessToSupervisor(
      adminService: adminService,
      supervisorId: supervisorId,
      debugContext: debugContext,
    );
  }

  /// Gets current admin context for debugging and logging
  ///
  /// Returns information about the current admin's role and permissions
  Future<Map<String, dynamic>> getAdminContext() async {
    return AdminFilterService.getAdminContext(adminService: adminService);
  }

  /// Determines if current admin is a super admin
  ///
  /// This is a convenience method for quick permission checks
  Future<bool> isSuperAdmin() async {
    try {
      return await adminService.isCurrentUserSuperAdmin();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AdminFilterMixin: Error checking super admin status: $e');
      }
      return false;
    }
  }

  /// Gets current admin's supervisor IDs
  ///
  /// Returns empty list for super admins or if there's an error
  Future<List<String>> getCurrentAdminSupervisorIds() async {
    try {
      final isSuperAdmin = await adminService.isCurrentUserSuperAdmin();
      if (isSuperAdmin) {
        return [];
      }
      return await adminService.getCurrentAdminSupervisorIds();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AdminFilterMixin: Error getting supervisor IDs: $e');
      }
      return [];
    }
  }

  /// Logs admin filtering debug information
  ///
  /// This method provides consistent debug logging across all blocs
  /// using the admin filter mixin.
  void logAdminFilterDebug(String message, {String? context}) {
    if (kDebugMode) {
      final prefix =
          context != null ? 'AdminFilterMixin($context)' : 'AdminFilterMixin';
      debugPrint('$prefix: $message');
    }
  }
}
