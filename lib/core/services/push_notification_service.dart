import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class PushNotificationService {
  static const String appId = "19cc330b-c04c-4568-a34e-05cb98e1a385";
  static bool _isInitialized = false;
  static String? _pendingUserId;
  static String _pendingRole = 'student';

  static Future<void> initialize() async {
    if (_isInitialized || kIsWeb) return;

    try {
      // Set Log Level in debug mode
      if (kDebugMode) {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      }

      // Initialize OneSignal
      OneSignal.initialize(appId);

      // Request notification permission
      await OneSignal.Notifications.requestPermission(true);

      _isInitialized = true;
      debugPrint('[PushNotificationService] OneSignal initialized successfully');

      // Auth restoration can finish before OneSignal initialization. Keep the
      // identity and apply it now so targeted pushes work on every app launch.
      final pendingUserId = _pendingUserId;
      if (pendingUserId != null) {
        login(pendingUserId, role: _pendingRole);
      }
    } catch (e, stackTrace) {
      debugPrint('[PushNotificationService] Error initializing OneSignal: $e');
      debugPrint('[PushNotificationService] Stack trace: $stackTrace');
    }
  }

  /// Link Supabase User ID to OneSignal and set role tag for targeting
  /// role: 'admin', 'student', 'instructor', 'parent'
  static void login(String userId, {String role = 'student'}) {
    if (kIsWeb) return;

    _pendingUserId = userId;
    _pendingRole = role;
    if (!_isInitialized) return;

    try {
      // ربط الـ Supabase user ID بـ OneSignal
      OneSignal.login(userId);

      // وضع تاغ بالدور للاستهداف لاحقاً (الأدمن يستقبل إشعارات الطلبات الجديدة)
      OneSignal.User.addTagWithKey('role', role);

      debugPrint('[PushNotificationService] OneSignal logged in user: $userId (role: $role)');
    } catch (e, stackTrace) {
      debugPrint('[PushNotificationService] OneSignal login error: $e');
      debugPrint('[PushNotificationService] Stack trace: $stackTrace');
    }
  }

  /// Unlink user ID on logout
  static void logout() {
    _pendingUserId = null;
    _pendingRole = 'student';
    if (!_isInitialized || kIsWeb) return;

    try {
      OneSignal.logout();
      debugPrint('[PushNotificationService] OneSignal logged out user');
    } catch (e, stackTrace) {
      debugPrint('[PushNotificationService] OneSignal logout error: $e');
      debugPrint('[PushNotificationService] Stack trace: $stackTrace');
    }
  }
}
