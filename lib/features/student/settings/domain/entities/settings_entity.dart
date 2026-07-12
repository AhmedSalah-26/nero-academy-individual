import 'package:equatable/equatable.dart';

/// Settings Entity - Pure Dart Object
class SettingsEntity extends Equatable {
  final String userId;
  final String languageCode;
  final bool isDarkMode;
  final bool notificationsEnabled;
  final bool videoAutoplay;
  final DateTime? updatedAt;

  const SettingsEntity({
    required this.userId,
    this.languageCode = 'en',
    this.isDarkMode = false,
    this.notificationsEnabled = true,
    this.videoAutoplay = true,
    this.updatedAt,
  });

  SettingsEntity copyWith({
    String? userId,
    String? languageCode,
    bool? isDarkMode,
    bool? notificationsEnabled,
    bool? videoAutoplay,
    DateTime? updatedAt,
  }) {
    return SettingsEntity(
      userId: userId ?? this.userId,
      languageCode: languageCode ?? this.languageCode,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      videoAutoplay: videoAutoplay ?? this.videoAutoplay,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        languageCode,
        isDarkMode,
        notificationsEnabled,
        videoAutoplay,
        updatedAt,
      ];
}
