import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/features/student/settings/domain/entities/settings_entity.dart';
import 'package:lms_platform/features/student/settings/domain/entities/user_profile_entity.dart';

/// Settings Repository - Abstract Contract
abstract class SettingsRepository {
  /// Get user settings
  Future<Either<Failure, SettingsEntity>> getSettings({required String userId});

  /// Update user settings
  Future<Either<Failure, SettingsEntity>> updateSettings({
    required String userId,
    String? languageCode,
    bool? isDarkMode,
    bool? notificationsEnabled,
    bool? videoAutoplay,
  });

  /// Get user profile
  Future<Either<Failure, UserProfileEntity>> getUserProfile({
    required String userId,
  });

  /// Update user profile
  Future<Either<Failure, UserProfileEntity>> updateUserProfile({
    required String userId,
    String? name,
    String? phone,
    String? avatarUrl,
    List<String>? interests,
    // Instructor fields
    String? displayName,
    String? headlineAr,
    String? headlineEn,
    String? bioAr,
    String? bioEn,
    List<String>? expertise,
    Map<String, String>? socialLinks,
    String? websiteUrl,
    String? coverImageUrl,
    String? parentPhone,
  });

  /// Get user achievements
  Future<Either<Failure, List<AchievementEntity>>> getUserAchievements({
    required String userId,
  });

  /// Delete user account
  Future<Either<Failure, bool>> deleteAccount({required String userId});

  /// Logout user
  Future<Either<Failure, bool>> logout();
}
