import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/features/student/settings/data/models/settings_model.dart';
import 'package:lms_platform/features/student/settings/data/models/user_profile_model.dart';

/// Settings Local Data Source
abstract class SettingsLocalDataSource {
  Future<SettingsModel?> getCachedSettings(String userId);
  Future<void> cacheSettings(SettingsModel settings);
  Future<SettingsModel> updateLocalSettings(
      String userId, Map<String, dynamic> updates);
  Future<UserProfileModel?> getCachedProfile(String userId);
  Future<void> cacheProfile(UserProfileModel profile);
  Future<void> clearCache();

  // Direct preference getters/setters for immediate UI updates
  bool getDarkMode(String userId);
  Future<void> setDarkMode(String userId, bool value);
  String getLanguage(String userId);
  Future<void> setLanguage(String userId, String value);
  bool getNotifications(String userId);
  Future<void> setNotifications(String userId, bool value);
  bool getVideoAutoplay(String userId);
  Future<void> setVideoAutoplay(String userId, bool value);
}

/// Settings Local Data Source Implementation
class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final SharedPreferences prefs;

  static const String _settingsKey = 'cached_settings_';
  static const String _profileKey = 'cached_profile_';
  static const String _darkModeKey = 'settings_dark_mode_';
  static const String _languageKey = 'settings_language_';
  static const String _notificationsKey = 'settings_notifications_';
  static const String _videoAutoplayKey = 'settings_video_autoplay_';

  SettingsLocalDataSourceImpl({required this.prefs});

  @override
  Future<SettingsModel?> getCachedSettings(String userId) async {
    AppLogger.i('💾 [SettingsLocal] Getting cached settings for: $userId');

    final jsonString = prefs.getString('$_settingsKey$userId');
    if (jsonString == null) {
      // Return settings from individual keys if full cache not available
      return SettingsModel(
        userId: userId,
        isDarkMode: getDarkMode(userId),
        languageCode: getLanguage(userId),
        notificationsEnabled: getNotifications(userId),
        videoAutoplay: getVideoAutoplay(userId),
      );
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return SettingsModel.fromJson(json);
    } catch (e) {
      AppLogger.e('[SettingsLocal] Error parsing cached settings: $e');
      return null;
    }
  }

  @override
  Future<void> cacheSettings(SettingsModel settings) async {
    AppLogger.i('💾 [SettingsLocal] Caching settings for: ${settings.userId}');

    final jsonString = jsonEncode(settings.toJson());
    await prefs.setString('$_settingsKey${settings.userId}', jsonString);

    // Also save individual keys for quick access
    await setDarkMode(settings.userId, settings.isDarkMode);
    await setLanguage(settings.userId, settings.languageCode);
    await setNotifications(settings.userId, settings.notificationsEnabled);
    await setVideoAutoplay(settings.userId, settings.videoAutoplay);
  }

  @override
  Future<SettingsModel> updateLocalSettings(
      String userId, Map<String, dynamic> updates) async {
    AppLogger.i('💾 [SettingsLocal] Updating local settings for: $userId');

    // Get current settings or create default
    var current = await getCachedSettings(userId);
    current ??= SettingsModel.defaultSettings(userId);

    // Apply updates
    final updated = SettingsModel(
      userId: userId,
      languageCode: updates['language_code'] as String? ?? current.languageCode,
      isDarkMode: updates['is_dark_mode'] as bool? ?? current.isDarkMode,
      notificationsEnabled: updates['notifications_enabled'] as bool? ??
          current.notificationsEnabled,
      videoAutoplay:
          updates['video_autoplay'] as bool? ?? current.videoAutoplay,
      updatedAt: DateTime.now(),
    );

    // Save updated settings
    await cacheSettings(updated);

    return updated;
  }

  @override
  Future<UserProfileModel?> getCachedProfile(String userId) async {
    AppLogger.i('💾 [SettingsLocal] Getting cached profile for: $userId');

    final jsonString = prefs.getString('$_profileKey$userId');
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserProfileModel.fromJson(json);
    } catch (e) {
      AppLogger.e('[SettingsLocal] Error parsing cached profile: $e');
      return null;
    }
  }

  @override
  Future<void> cacheProfile(UserProfileModel profile) async {
    AppLogger.i('💾 [SettingsLocal] Caching profile for: ${profile.id}');

    final jsonString = jsonEncode(profile.toJson());
    await prefs.setString('$_profileKey${profile.id}', jsonString);
  }

  @override
  Future<void> clearCache() async {
    AppLogger.i('💾 [SettingsLocal] Clearing cache');

    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_settingsKey) ||
          key.startsWith(_profileKey) ||
          key.startsWith(_darkModeKey) ||
          key.startsWith(_languageKey) ||
          key.startsWith(_notificationsKey) ||
          key.startsWith(_videoAutoplayKey)) {
        await prefs.remove(key);
      }
    }
  }

  // ============ Direct Preference Methods ============

  @override
  bool getDarkMode(String userId) {
    return prefs.getBool('$_darkModeKey$userId') ?? false;
  }

  @override
  Future<void> setDarkMode(String userId, bool value) async {
    await prefs.setBool('$_darkModeKey$userId', value);
  }

  @override
  String getLanguage(String userId) {
    return prefs.getString('$_languageKey$userId') ?? 'en';
  }

  @override
  Future<void> setLanguage(String userId, String value) async {
    await prefs.setString('$_languageKey$userId', value);
  }

  @override
  bool getNotifications(String userId) {
    return prefs.getBool('$_notificationsKey$userId') ?? true;
  }

  @override
  Future<void> setNotifications(String userId, bool value) async {
    await prefs.setBool('$_notificationsKey$userId', value);
  }

  @override
  bool getVideoAutoplay(String userId) {
    return prefs.getBool('$_videoAutoplayKey$userId') ?? true;
  }

  @override
  Future<void> setVideoAutoplay(String userId, bool value) async {
    await prefs.setBool('$_videoAutoplayKey$userId', value);
  }
}
