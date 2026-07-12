import 'package:lms_platform/features/student/settings/domain/entities/settings_entity.dart';

/// Settings Model - Data Model with JSON serialization
class SettingsModel extends SettingsEntity {
  const SettingsModel({
    required super.userId,
    super.languageCode,
    super.isDarkMode,
    super.notificationsEnabled,
    super.videoAutoplay,
    super.updatedAt,
  });

  /// Create from JSON
  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      userId: json['user_id'] as String,
      languageCode: json['language_code'] as String? ?? 'en',
      isDarkMode: json['is_dark_mode'] as bool? ?? false,
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      videoAutoplay: json['video_autoplay'] as bool? ?? true,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'language_code': languageCode,
      'is_dark_mode': isDarkMode,
      'notifications_enabled': notificationsEnabled,
      'video_autoplay': videoAutoplay,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create from Entity
  factory SettingsModel.fromEntity(SettingsEntity entity) {
    return SettingsModel(
      userId: entity.userId,
      languageCode: entity.languageCode,
      isDarkMode: entity.isDarkMode,
      notificationsEnabled: entity.notificationsEnabled,
      videoAutoplay: entity.videoAutoplay,
      updatedAt: entity.updatedAt,
    );
  }

  /// Default settings
  factory SettingsModel.defaultSettings(String userId) {
    return SettingsModel(
      userId: userId,
      languageCode: 'en',
      isDarkMode: false,
      notificationsEnabled: true,
      videoAutoplay: true,
    );
  }
}
