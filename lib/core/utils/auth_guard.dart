import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/admin_service.dart';

class AuthGuard {
  static final AdminService _adminService =
      AdminService(Supabase.instance.client);

  /// Check if user is authenticated and has admin privileges
  static Future<AuthResult> checkAuth() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;

      if (currentUser == null) {
        return AuthResult(
          isAuthenticated: false,
          isAdmin: false,
          isSuperAdmin: false,
          shouldRedirect: true,
          redirectPath: '/auth',
        );
      }

      final isAdmin = await _adminService.isCurrentUserAdmin();
      final isSuperAdmin = await _adminService.isCurrentUserSuperAdmin();

      if (!isAdmin && !isSuperAdmin) {
        // User is authenticated but not an admin
        await Supabase.instance.client.auth.signOut();
        return AuthResult(
          isAuthenticated: false,
          isAdmin: false,
          isSuperAdmin: false,
          shouldRedirect: true,
          redirectPath: '/auth',
          errorMessage: 'User does not have admin privileges',
        );
      }

      return AuthResult(
        isAuthenticated: true,
        isAdmin: isAdmin,
        isSuperAdmin: isSuperAdmin,
        shouldRedirect: false,
      );
    } catch (e) {
      // If role check fails, logout and redirect to auth
      await Supabase.instance.client.auth.signOut();
      return AuthResult(
        isAuthenticated: false,
        isAdmin: false,
        isSuperAdmin: false,
        shouldRedirect: true,
        redirectPath: '/auth',
        errorMessage: e.toString(),
      );
    }
  }

  /// Get appropriate redirect path for authenticated admin
  static String getAdminDashboardPath(bool isSuperAdmin) {
    return isSuperAdmin ? '/super-admin' : '/';
  }
}

class AuthResult {
  final bool isAuthenticated;
  final bool isAdmin;
  final bool isSuperAdmin;
  final bool shouldRedirect;
  final String? redirectPath;
  final String? errorMessage;

  AuthResult({
    required this.isAuthenticated,
    required this.isAdmin,
    required this.isSuperAdmin,
    required this.shouldRedirect,
    this.redirectPath,
    this.errorMessage,
  });
}
