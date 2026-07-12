import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'app_logger.dart';

/// Service to prevent screen recording and screenshots.
///
/// Android: Sets [WindowManager.FLAG_SECURE] via a MethodChannel.
/// iOS:     Activates a secure UITextField layer that iOS blurs on capture.
/// Web:     No-op (not supported by browsers).
class ScreenProtectionService {
  ScreenProtectionService._();

  static const _channel = MethodChannel('nero_academy/screen_secure');

  static bool _isProtected = false;

  /// Enable screen protection (prevents recording & screenshots).
  static Future<void> enable() async {
    if (_isProtected) return;
    if (kIsWeb) return;

    try {
      await _channel.invokeMethod<void>('setScreenSecure', {'enable': true});
      _isProtected = true;
      AppLogger.i('🔒 [ScreenProtection] Enabled');
    } catch (e) {
      AppLogger.e('🔒 [ScreenProtection] Failed to enable: $e');
    }
  }

  /// Disable screen protection (allows recording & screenshots again).
  static Future<void> disable() async {
    if (!_isProtected) return;
    if (kIsWeb) return;

    try {
      await _channel.invokeMethod<void>('setScreenSecure', {'enable': false});
      _isProtected = false;
      AppLogger.i('🔓 [ScreenProtection] Disabled');
    } catch (e) {
      AppLogger.e('🔓 [ScreenProtection] Failed to disable: $e');
    }
  }

  /// Returns whether screen protection is currently active.
  static bool get isProtected => _isProtected;
}
