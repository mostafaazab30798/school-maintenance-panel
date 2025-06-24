import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Enhanced navigation service that maintains proper navigation stack
class AppNavigationService {
  /// Navigate to super admin dashboard (replace navigation)
  static void goToSuperAdminDashboard(BuildContext context) {
    context.go('/super-admin');
  }

  /// Navigate to regular admin dashboard (replace navigation)
  static void goToRegularDashboard(BuildContext context) {
    context.go('/');
  }

  /// Navigate to auth screen (replace navigation)
  static void goToAuth(BuildContext context) {
    context.go('/auth');
  }

  // PUSH NAVIGATION (maintains navigation stack for back button)

  /// Navigate to super admin progress screen
  static void pushToSuperAdminProgress(BuildContext context) {
    context.push('/super-admin-progress');
  }

  /// Navigate to admins list screen
  static void pushToAdminsList(BuildContext context) {
    context.push('/admins-list');
  }

  /// Navigate to supervisors list screen
  static void pushToSupervisorsList(BuildContext context) {
    context.push('/supervisors-list');
  }

  /// Navigate to admin progress screen
  static void pushToAdminProgress(BuildContext context) {
    context.push('/progress');
  }

  /// Navigate to reports screen with parameters
  static void pushToReports(
    BuildContext context, {
    String? title,
    String? status,
    String? priority,
    String? supervisorId,
    String? type,
  }) {
    final queryParams = <String, String>{};

    if (title != null) queryParams['title'] = title;
    if (status != null) queryParams['status'] = status;
    if (priority != null) queryParams['priority'] = priority;
    if (supervisorId != null) queryParams['supervisorId'] = supervisorId;
    if (type != null) queryParams['type'] = type;

    final uri = Uri(
        path: '/reports',
        queryParameters: queryParams.isNotEmpty ? queryParams : null);
    context.push(uri.toString());
  }

  /// Navigate to all reports screen
  static void pushToAllReports(BuildContext context) {
    context.push('/all-reports');
  }

  /// Navigate to all maintenance screen
  static void pushToAllMaintenance(BuildContext context) {
    context.push('/all-maintenance');
  }

  /// Navigate to maintenance reports with supervisor ID
  static void pushToMaintenanceReports(
    BuildContext context, {
    required String supervisorId,
    String title = 'بلاغات الصيانة',
  }) {
    context.push('/maintenance-list/$supervisorId');
  }

  /// Navigate to add multiple reports screen
  static void pushToAddMultipleReports(BuildContext context) {
    context.push('/add-reports');
  }

  /// Navigate to add maintenance screen
  static void pushToAddMaintenance(BuildContext context, String supervisorId) {
    context.push('/add-maintenance/$supervisorId');
  }

  /// Navigate to supervisors screen (for regular admin)
  static void pushToSupervisors(BuildContext context) {
    context.push('/supervisors');
  }

  /// Navigate to admin management screen
  static void pushToAdminManagement(BuildContext context) {
    context.push('/admin-management');
  }

  /// Navigate to test connection screen
  static void pushToTestConnection(BuildContext context) {
    context.push('/test-connection');
  }

  /// Navigate to debug auth screen
  static void pushToDebugAuth(BuildContext context) {
    context.push('/debug-auth');
  }

  // UTILITY METHODS

  /// Go back to previous screen
  static void goBack(BuildContext context) {
    if (GoRouter.of(context).canPop()) {
      context.pop();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      // Last resort - go to appropriate dashboard
      goToRegularDashboard(context);
    }
  }

  /// Check if we can go back
  static bool canGoBack(BuildContext context) {
    return GoRouter.of(context).canPop() || Navigator.canPop(context);
  }

  /// Pop until reaching a specific route
  static void popUntil(BuildContext context, String routeName) {
    while (GoRouter.of(context).canPop()) {
      final currentRoute = GoRouterState.of(context).uri.path;
      if (currentRoute == routeName) break;
      context.pop();
    }
  }

  /// Replace current route with new one
  static void replaceWith(BuildContext context, String route) {
    context.go(route);
  }

  /// Clear navigation stack and go to route
  static void clearAndGoTo(BuildContext context, String route) {
    context.go(route);
  }
}
