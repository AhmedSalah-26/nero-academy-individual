import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/di/injection_container.dart';

/// Service to check user role from database
class UserRoleService {
  static final SupabaseClient _client = sl<SupabaseClient>();

  /// Cache for user role to avoid repeated DB calls
  static String? _cachedRole;
  static String? _cachedUserId;

  /// Get current user role from database
  static Future<String?> getCurrentUserRole() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    // Return cached role if same user
    if (_cachedUserId == user.id && _cachedRole != null) {
      return _cachedRole;
    }

    try {
      final response = await _client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        _cachedRole = response['role'] as String? ?? 'student';
        _cachedUserId = user.id;
        return _cachedRole;
      }

      // Fallback to userMetadata if profile not found
      return user.userMetadata?['role'] as String? ?? 'student';
    } catch (e) {
      // Fallback to userMetadata on error
      return user.userMetadata?['role'] as String? ?? 'student';
    }
  }

  /// Check if current user is admin
  static Future<bool> isAdmin() async {
    final role = await getCurrentUserRole();
    return role == 'admin';
  }

  /// Check if current user is instructor
  static Future<bool> isInstructor() async {
    final role = await getCurrentUserRole();
    return role == 'instructor' || role == 'admin';
  }

  /// Check if current user is parent
  static Future<bool> isParent() async {
    return false;
  }

  /// Check if current user is student
  static Future<bool> isStudent() async {
    final role = await getCurrentUserRole();
    return role == 'student';
  }

  /// Clear cached role (call on logout)
  static void clearCache() {
    _cachedRole = null;
    _cachedUserId = null;
  }

  /// Get role synchronously from cache (may be null if not loaded)
  static String? getCachedRole() => _cachedRole;
}
