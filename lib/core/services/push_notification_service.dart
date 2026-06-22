import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class PushNotificationService {
  static const String appId = "19cc330b-c04c-4568-a34e-05cb98e1a385";

  static Future<void> initialize() async {
    try {
      // Set Log Level in debug mode
      if (kDebugMode) {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      }

      // Initialize OneSignal
      OneSignal.initialize(appId);

      // Request notification permission
      await OneSignal.Notifications.requestPermission(true);

      debugPrint('🔔 [PushNotificationService] OneSignal Initialized successfully');
    } catch (e) {
      debugPrint('⚠️ [PushNotificationService] Error initializing OneSignal: $e');
    }
  }

  /// Link Supabase User ID to OneSignal and set role tag for targeting
  /// role: 'admin', 'student', 'instructor', 'parent'
  static void login(String userId, {String role = 'student'}) {
    try {
      // ربط الـ Supabase user ID بـ OneSignal
      OneSignal.login(userId);

      // وضع تاغ بالدور للاستهداف لاحقاً (الأدمن يستقبل إشعارات الطلبات الجديدة)
      OneSignal.User.addTagWithKey('role', role);

      debugPrint('🔔 [PushNotificationService] OneSignal logged in user: $userId (role: $role)');
    } catch (e) {
      debugPrint('⚠️ [PushNotificationService] OneSignal login error: $e');
    }
  }

  /// Unlink user ID on logout
  static void logout() {
    try {
      OneSignal.logout();
      debugPrint('🔔 [PushNotificationService] OneSignal logged out user');
    } catch (e) {
      debugPrint('⚠️ [PushNotificationService] OneSignal logout error: $e');
    }
  }
}

