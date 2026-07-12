import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/features/student/settings/domain/entities/settings_entity.dart';
import 'package:lms_platform/features/student/settings/domain/entities/user_profile_entity.dart';
import 'package:lms_platform/features/student/settings/domain/repositories/settings_repository.dart';
import 'package:lms_platform/features/student/settings/data/datasources/settings_local_data_source.dart';
import 'package:lms_platform/features/student/settings/data/datasources/settings_remote_data_source.dart';
import 'package:lms_platform/features/student/settings/data/models/user_profile_model.dart';

/// Settings Repository Implementation
class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDataSource remoteDataSource;
  final SettingsLocalDataSource localDataSource;

  SettingsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, SettingsEntity>> getSettings({
    required String userId,
  }) async {
    try {
      AppLogger.i('⚙️ [SettingsRepo] Getting settings (LOCAL ONLY): $userId');

      // LOCAL ONLY: Get settings from local storage only
      final cached = await localDataSource.getCachedSettings(userId);
      if (cached != null) {
        AppLogger.success('[SettingsRepo] Settings loaded from local storage');
        return Right(cached);
      }

      // Return default settings if nothing cached
      final defaultSettings = SettingsEntity(
        userId: userId,
        languageCode: 'en',
        isDarkMode: false,
        notificationsEnabled: true,
        videoAutoplay: true,
      );

      AppLogger.i('[SettingsRepo] Returning default settings');
      return Right(defaultSettings);
    } catch (e) {
      AppLogger.e('[SettingsRepo] Error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SettingsEntity>> updateSettings({
    required String userId,
    String? languageCode,
    bool? isDarkMode,
    bool? notificationsEnabled,
    bool? videoAutoplay,
  }) async {
    try {
      AppLogger.i('⚙️ [SettingsRepo] Updating settings (LOCAL ONLY): $userId');

      final data = <String, dynamic>{};
      if (languageCode != null) data['language_code'] = languageCode;
      if (isDarkMode != null) data['is_dark_mode'] = isDarkMode;
      if (notificationsEnabled != null) {
        data['notifications_enabled'] = notificationsEnabled;
      }
      if (videoAutoplay != null) data['video_autoplay'] = videoAutoplay;

      // LOCAL ONLY: Language and theme are stored locally only
      final localSettings =
          await localDataSource.updateLocalSettings(userId, data);
      AppLogger.success(
          '[SettingsRepo] Settings saved locally (no remote sync)');

      return Right(localSettings);
    } catch (e) {
      AppLogger.e('[SettingsRepo] Error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserProfileEntity>> getUserProfile({
    required String userId,
  }) async {
    try {
      AppLogger.i('👤 [SettingsRepo] Getting profile for: $userId');

      // Try cache first
      final cached = await localDataSource.getCachedProfile(userId);
      if (cached != null) {
        AppLogger.i('[SettingsRepo] Returning cached profile');
        _refreshProfile(userId);
        return Right(cached);
      }

      final profile = await remoteDataSource.getUserProfile(userId);
      final achievements = await remoteDataSource.getUserAchievements(userId);

      final profileWithAchievements = UserProfileModel(
        id: profile.id,
        name: profile.name,
        email: profile.email,
        phone: profile.phone,
        avatarUrl: profile.avatarUrl,
        role: profile.role,
        interests: profile.interests,
        coursesCount: profile.coursesCount,
        totalWatchTimeSeconds: profile.totalWatchTimeSeconds,
        dayStreak: profile.dayStreak,
        achievements: achievements,
        createdAt: profile.createdAt,
        // Instructor fields
        headlineAr: profile.headlineAr,
        headlineEn: profile.headlineEn,
        bioAr: profile.bioAr,
        bioEn: profile.bioEn,
        expertise: profile.expertise,
        socialLinks: profile.socialLinks,
        websiteUrl: profile.websiteUrl,
        coverImageUrl: profile.coverImageUrl,
        parentPhone: profile.parentPhone,
      );

      await localDataSource.cacheProfile(profileWithAchievements);

      AppLogger.success('[SettingsRepo] Profile loaded');
      return Right(profileWithAchievements);
    } catch (e) {
      AppLogger.e('[SettingsRepo] Error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<void> _refreshProfile(String userId) async {
    try {
      final profile = await remoteDataSource.getUserProfile(userId);
      await localDataSource.cacheProfile(profile);
    } catch (e) {
      AppLogger.e('[SettingsRepo] Background refresh failed: $e');
    }
  }

  @override
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
  }) async {
    try {
      AppLogger.i('👤 [SettingsRepo] Updating profile for: $userId');

      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (phone != null) data['phone'] = phone;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;
      if (interests != null) data['interests'] = interests;
      // Instructor fields
      if (displayName != null) data['display_name'] = displayName;
      if (headlineAr != null) data['headline_ar'] = headlineAr;
      if (headlineEn != null) data['headline_en'] = headlineEn;
      if (bioAr != null) data['bio_ar'] = bioAr;
      if (bioEn != null) data['bio_en'] = bioEn;
      if (expertise != null) data['expertise'] = expertise;
      if (socialLinks != null) data['social_links'] = socialLinks;
      if (websiteUrl != null) data['website_url'] = websiteUrl;
      if (coverImageUrl != null) data['cover_image_url'] = coverImageUrl;
      if (parentPhone != null) data['parent_phone'] = parentPhone;

      final profile = await remoteDataSource.updateUserProfile(userId, data);
      await localDataSource.cacheProfile(profile);

      AppLogger.success('[SettingsRepo] Profile updated');
      return Right(profile);
    } catch (e) {
      AppLogger.e('[SettingsRepo] Error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AchievementEntity>>> getUserAchievements({
    required String userId,
  }) async {
    try {
      AppLogger.i('🏆 [SettingsRepo] Getting achievements for: $userId');

      final achievements = await remoteDataSource.getUserAchievements(userId);

      AppLogger.success('[SettingsRepo] Achievements loaded');
      return Right(achievements);
    } catch (e) {
      AppLogger.e('[SettingsRepo] Error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteAccount({required String userId}) async {
    try {
      AppLogger.i('🗑️ [SettingsRepo] Deleting account: $userId');

      final result = await remoteDataSource.deleteAccount(userId);
      await localDataSource.clearCache();

      AppLogger.success('[SettingsRepo] Account deleted');
      return Right(result);
    } catch (e) {
      AppLogger.e('[SettingsRepo] Error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> logout() async {
    try {
      AppLogger.i('🚪 [SettingsRepo] Logging out');

      final result = await remoteDataSource.logout();
      await localDataSource.clearCache();

      AppLogger.success('[SettingsRepo] Logged out');
      return Right(result);
    } catch (e) {
      AppLogger.e('[SettingsRepo] Error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }
}
