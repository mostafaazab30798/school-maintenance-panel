import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/admin.dart';
import 'package:flutter/foundation.dart';

class AdminService {
  final SupabaseClient _client;
  static const String _logPrefix = 'AdminService';

  // 🚀 PERFORMANCE: Cache supervisor IDs to prevent redundant 1.5+ second calls
  static final Map<String, List<String>> _supervisorCache = {};
  static final Map<String, DateTime> _cacheTimestamp = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  AdminService(this._client);

  /// Get current admin info based on auth user
  Future<Admin?> getCurrentAdmin() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('admins')
          .select()
          .eq('auth_user_id', user.id)
          .single();

      return Admin.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  /// Gets supervisor IDs assigned to the current admin (with caching)
  ///
  /// This method fetches the list of supervisor IDs that the current admin
  /// is authorized to access. Results are cached for 5 minutes to prevent
  /// redundant expensive database calls.
  Future<List<String>> getCurrentAdminSupervisorIds() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          debugPrint('$_logPrefix: ❌ No authenticated user');
        }
        return [];
      }

      final authUserId = user.id;

      if (kDebugMode) {
        debugPrint(
            '$_logPrefix: 🔍 Looking up supervisors for auth user $authUserId');
      }

      // 🚀 Check cache first
      final cachedResult = _supervisorCache[authUserId];
      final cacheTime = _cacheTimestamp[authUserId];

      if (cachedResult != null && cacheTime != null) {
        final age = DateTime.now().difference(cacheTime);
        if (age < _cacheExpiry) {
          if (kDebugMode) {
            debugPrint(
                '$_logPrefix: ⚡ Cache hit for auth user $authUserId: $cachedResult (age: ${age.inSeconds}s)');
          }
          return cachedResult;
        } else {
          // Clear expired cache
          _supervisorCache.remove(authUserId);
          _cacheTimestamp.remove(authUserId);
          if (kDebugMode) {
            debugPrint(
                '$_logPrefix: 🗑️ Cache expired for auth user $authUserId, fetching fresh data');
          }
        }
      }

      if (kDebugMode) {
        debugPrint('$_logPrefix: 🔄 Fetching supervisor IDs from database...');
      }

      // First, get the admin's database ID from the admins table
      final adminResponse = await _client
          .from('admins')
          .select('id')
          .eq('auth_user_id', authUserId)
          .single();

      final adminId = adminResponse['id'] as String;

      if (kDebugMode) {
        debugPrint('$_logPrefix: 👤 Admin database ID: $adminId');
      }

      // Query supervisors table for supervisors assigned to this admin
      final response = await _client
          .from('supervisors')
          .select('id')
          .eq('admin_id', adminId);

      if (kDebugMode) {
        debugPrint('$_logPrefix: 📊 Database response: $response');
      }

      final supervisorIds =
          (response as List).map((item) => item['id'] as String).toList();

      // 🚀 Cache the result
      _supervisorCache[authUserId] = supervisorIds;
      _cacheTimestamp[authUserId] = DateTime.now();

      if (kDebugMode) {
        debugPrint(
            '$_logPrefix: ✅ Found ${supervisorIds.length} supervisors for admin $adminId: $supervisorIds');
        debugPrint('$_logPrefix: 💾 Cached result for future requests');
      }

      return supervisorIds;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('$_logPrefix: ❌ Error fetching admin supervisor IDs: $e');
        debugPrint('$_logPrefix: 📍 Stack trace: $stackTrace');
      }
      return [];
    }
  }

  /// Check if current user is an admin
  Future<bool> isCurrentUserAdmin() async {
    final admin = await getCurrentAdmin();
    return admin != null;
  }

  /// Check if current user is a super admin
  Future<bool> isCurrentUserSuperAdmin() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          debugPrint('$_logPrefix: No authenticated user');
        }
        return false;
      }

      final response = await _client
          .from('admins')
          .select('role')
          .eq('user_id', user.id)
          .single();

      final role = response['role'] as String?;
      final isSuperAdmin = role == 'super_admin';

      if (kDebugMode) {
        debugPrint(
            '$_logPrefix: Admin role = $role, isSuperAdmin = $isSuperAdmin');
      }

      return isSuperAdmin;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$_logPrefix: Error checking super admin status: $e');
      }
      return false;
    }
  }

  /// Get current user role
  Future<String?> getCurrentUserRole() async {
    final admin = await getCurrentAdmin();
    return admin?.role;
  }

  /// Get admin by ID
  Future<Admin?> getAdminById(String adminId) async {
    try {
      final response =
          await _client.from('admins').select().eq('id', adminId).single();

      return Admin.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  /// Create new admin
  Future<void> createAdmin(Admin admin) async {
    final data = admin.toMap()..remove('id');
    await _client.from('admins').insert(data);
  }

  /// Update admin
  Future<void> updateAdmin(String id, Map<String, dynamic> updates) async {
    await _client.from('admins').update(updates).eq('id', id);
  }

  /// Delete admin
  Future<void> deleteAdmin(String id) async {
    await _client.from('admins').delete().eq('id', id);
  }

  /// Clears the supervisor cache (useful for testing or when permissions change)
  static void clearCache([String? adminId]) {
    if (adminId != null) {
      _supervisorCache.remove(adminId);
      _cacheTimestamp.remove(adminId);
      if (kDebugMode) {
        debugPrint('AdminService: Cleared cache for admin $adminId');
      }
    } else {
      _supervisorCache.clear();
      _cacheTimestamp.clear();
      if (kDebugMode) {
        debugPrint('AdminService: Cleared all supervisor cache');
      }
    }
  }
}
