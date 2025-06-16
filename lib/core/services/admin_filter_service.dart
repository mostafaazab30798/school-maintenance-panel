import 'package:flutter/foundation.dart';
import 'admin_service.dart';

/// Result wrapper for admin-filtered data operations
class FilterResult<T> {
  final List<T> data;
  final bool isSuperAdmin;
  final bool hasAccess;
  final List<String>? supervisorIds;

  const FilterResult({
    required this.data,
    required this.isSuperAdmin,
    required this.hasAccess,
    this.supervisorIds,
  });

  /// Factory constructor for super admin results
  factory FilterResult.superAdmin(List<T> data) {
    return FilterResult<T>(
      data: data,
      isSuperAdmin: true,
      hasAccess: true,
      supervisorIds: null,
    );
  }

  /// Factory constructor for regular admin results
  factory FilterResult.regularAdmin(List<T> data, List<String> supervisorIds) {
    return FilterResult<T>(
      data: data,
      isSuperAdmin: false,
      hasAccess: true,
      supervisorIds: supervisorIds,
    );
  }

  /// Factory constructor for no access results
  factory FilterResult.noAccess() {
    return FilterResult<T>(
      data: <T>[],
      isSuperAdmin: false,
      hasAccess: false,
      supervisorIds: null,
    );
  }
}

/// Service for filtering data based on admin permissions
///
/// This service provides a centralized way to apply admin-based filtering
/// to different types of data (reports, maintenance, etc.) while maintaining
/// consistent security and access control.
class AdminFilterService {
  static const String _logPrefix = 'AdminFilterService';

  /// Applies admin-based filtering to any data type
  ///
  /// This method determines if the current user is a super admin or regular admin,
  /// then fetches appropriate data based on their permissions.
  ///
  /// [adminService] - Service to check admin permissions
  /// [fetchAllData] - Function to fetch all data (for super admins)
  /// [fetchFilteredData] - Function to fetch filtered data by supervisor IDs
  /// [debugContext] - Optional context for debugging (e.g., 'Reports', 'Maintenance')
  static Future<FilterResult<T>> filterByAdminPermissions<T>({
    required AdminService adminService,
    required Future<List<T>> Function() fetchAllData,
    required Future<List<T>> Function(List<String> supervisorIds)
        fetchFilteredData,
    String? debugContext,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
            '$_logPrefix: Starting admin filtering${debugContext != null ? ' for $debugContext' : ''}');
      }

      // Check if current user is super admin
      final isSuperAdmin = await adminService.isCurrentUserSuperAdmin();

      if (kDebugMode) {
        debugPrint('$_logPrefix: User is super admin: $isSuperAdmin');
      }

      if (isSuperAdmin) {
        // Super admin can see all data
        if (kDebugMode) {
          debugPrint('$_logPrefix: Fetching all data for super admin');
        }

        final data = await fetchAllData();

        if (kDebugMode) {
          debugPrint(
              '$_logPrefix: Fetched ${data.length} items for super admin');
        }

        return FilterResult.superAdmin(data);
      } else {
        // Regular admin - get their assigned supervisors
        if (kDebugMode) {
          debugPrint('$_logPrefix: Fetching supervisor IDs for regular admin');
        }

        final supervisorIds = await adminService.getCurrentAdminSupervisorIds();

        if (kDebugMode) {
          debugPrint(
              '$_logPrefix: Admin has ${supervisorIds.length} assigned supervisors: $supervisorIds');
        }

        if (supervisorIds.isEmpty) {
          // Admin has no supervisors - return empty result
          if (kDebugMode) {
            debugPrint(
                '$_logPrefix: Admin has no supervisors, returning empty result');
          }

          return FilterResult.noAccess();
        } else {
          // Fetch data for assigned supervisors
          if (kDebugMode) {
            debugPrint(
                '$_logPrefix: Fetching filtered data for supervisors: $supervisorIds');
          }

          final data = await fetchFilteredData(supervisorIds);

          if (kDebugMode) {
            debugPrint('$_logPrefix: Fetched ${data.length} filtered items');
          }

          return FilterResult.regularAdmin(data, supervisorIds);
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('$_logPrefix: Error during admin filtering: $e');
        debugPrint('$_logPrefix: Stack trace: $stackTrace');
      }

      // Return no access on error for security
      return FilterResult.noAccess();
    }
  }

  /// Checks if current admin has access to a specific supervisor
  ///
  /// This method validates if the current user (either super admin or regular admin)
  /// has permission to access data for the specified supervisor.
  ///
  /// [adminService] - Service to check admin permissions
  /// [supervisorId] - ID of the supervisor to check access for
  /// [debugContext] - Optional context for debugging
  static Future<bool> hasAccessToSupervisor({
    required AdminService adminService,
    required String supervisorId,
    String? debugContext,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
            '$_logPrefix: Checking access to supervisor $supervisorId${debugContext != null ? ' for $debugContext' : ''}');
      }

      // Super admins have access to all supervisors
      final isSuperAdmin = await adminService.isCurrentUserSuperAdmin();
      if (isSuperAdmin) {
        if (kDebugMode) {
          debugPrint(
              '$_logPrefix: Super admin has access to supervisor $supervisorId');
        }
        return true;
      }

      // Regular admin - check if supervisor is in their assigned list
      final assignedSupervisorIds =
          await adminService.getCurrentAdminSupervisorIds();

      final hasAccess = assignedSupervisorIds.contains(supervisorId);

      if (kDebugMode) {
        debugPrint(
            '$_logPrefix: Regular admin access to supervisor $supervisorId: $hasAccess (assigned supervisors: $assignedSupervisorIds)');
      }

      return hasAccess;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('$_logPrefix: Error checking supervisor access: $e');
        debugPrint('$_logPrefix: Stack trace: $stackTrace');
      }

      // Deny access on error for security
      return false;
    }
  }

  /// Gets current admin context information for debugging and logging
  ///
  /// Returns a map containing current admin's role and permission information.
  /// This is useful for debugging access issues and logging.
  ///
  /// [adminService] - Service to check admin permissions
  static Future<Map<String, dynamic>> getAdminContext({
    required AdminService adminService,
  }) async {
    try {
      final isSuperAdmin = await adminService.isCurrentUserSuperAdmin();
      final supervisorIds = isSuperAdmin
          ? <String>[]
          : await adminService.getCurrentAdminSupervisorIds();

      return {
        'isSuperAdmin': isSuperAdmin,
        'supervisorIds': supervisorIds,
        'supervisorCount': supervisorIds.length,
        'hasAccess': isSuperAdmin || supervisorIds.isNotEmpty,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$_logPrefix: Error getting admin context: $e');
      }

      return {
        'isSuperAdmin': false,
        'supervisorIds': <String>[],
        'supervisorCount': 0,
        'hasAccess': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
