import 'package:flutter/foundation.dart';
import 'app_logger.dart';

/// Service to prevent screen recording and screenshots.
/// Note: flutter_windowmanager was removed due to incompatibility with
/// newer Flutter versions. Screen protection is currently a no-op.
class ScreenProtectionService {
  ScreenProtectionService._();

  static bool _isProtected = false;

  /// Enable screen protection (prevents recording & screenshots).
  static Future<void> enable() async {
    if (_isProtected) return;
    if (kIsWeb) return;

    try {
      // TODO: Replace with a compatible screen protection package when needed.
      _isProtected = true;
      AppLogger.i('🔒 [ScreenProtection] Enabled (stub - no-op)');
    } catch (e) {
      AppLogger.e('🔒 [ScreenProtection] Failed to enable: $e');
    }
  }

  /// Disable screen protection (allows recording & screenshots again).
  static Future<void> disable() async {
    if (!_isProtected) return;
    if (kIsWeb) return;

    try {
      _isProtected = false;
      AppLogger.i('🔓 [ScreenProtection] Disabled (stub - no-op)');
    } catch (e) {
      AppLogger.e('🔓 [ScreenProtection] Failed to disable: $e');
    }
  }
}
