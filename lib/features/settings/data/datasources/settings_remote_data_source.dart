import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/app_logger.dart';
import '../models/settings_model.dart';
import '../models/user_profile_model.dart';

/// Settings Remote Data Source
abstract class SettingsRemoteDataSource {
  Future<SettingsModel> getSettings(String userId);
  Future<SettingsModel> updateSettings(
      String userId, Map<String, dynamic> data);
  Future<UserProfileModel> getUserProfile(String userId);
  Future<UserProfileModel> updateUserProfile(
      String userId, Map<String, dynamic> data);
  Future<List<AchievementModel>> getUserAchievements(String userId);
  Future<bool> deleteAccount(String userId);
  Future<bool> logout();
}

/// Settings Remote Data Source Implementation
class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  final SupabaseClient client;

  SettingsRemoteDataSourceImpl({required this.client});

  @override
  Future<SettingsModel> getSettings(String userId) async {
    AppLogger.i('⚙️ [SettingsRemote] Getting settings for: $userId');

    final response = await client
        .from('user_settings')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      // Return default settings if not found
      return SettingsModel.defaultSettings(userId);
    }

    return SettingsModel.fromJson(response);
  }

  @override
  Future<SettingsModel> updateSettings(
      String userId, Map<String, dynamic> data) async {
    AppLogger.i('⚙️ [SettingsRemote] Updating settings for: $userId');

    final updateData = {
      'user_id': userId,
      ...data,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response =
        await client.from('user_settings').upsert(updateData).select().single();

    return SettingsModel.fromJson(response);
  }

  @override
  Future<UserProfileModel> getUserProfile(String userId) async {
    AppLogger.i('👤 [SettingsRemote] Getting profile for: $userId');

    final response =
        await client.from('profiles').select().eq('id', userId).single();

    // Get additional stats
    final enrollmentsCount = await _getEnrollmentsCount(userId);
    final totalWatchTimeSeconds = await _getTotalWatchTimeSeconds(userId);
    final dayStreak = await _getDayStreak(userId);

    // Get instructor-specific fields if user is an instructor
    Map<String, dynamic>? teacherData;
    if (response['role'] == 'instructor') {
      teacherData = await client
          .from('teachers')
          .select()
          .eq('profile_id', userId)
          .maybeSingle();
    }

    final profileData = {
      ...response,
      'courses_count': enrollmentsCount,
      'total_watch_time_seconds': totalWatchTimeSeconds,
      'day_streak': dayStreak,
      // Add instructor fields if available
      if (response['role'] == 'instructor') ...{
        'display_name': teacherData?['display_name'] ?? response['name'],
        'headline_ar': response['headline_ar'],
        'headline_en': response['headline_en'],
        'bio_ar': response['bio_ar'],
        'bio_en': response['bio_en'],
        'expertise': response['expertise'],
        'social_links': response['social_links'],
        'website_url': teacherData?['website_url'],
        'cover_image_url': teacherData?['cover_image_url'] ?? response['avatar_url'],
      },
    };

    return UserProfileModel.fromJson(profileData);
  }

  Future<int> _getEnrollmentsCount(String userId) async {
    try {
      final response =
          await client.from('enrollments').select('id').eq('user_id', userId);
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Get total watch time in seconds (not hours)
  Future<int> _getTotalWatchTimeSeconds(String userId) async {
    try {
      final response = await client
          .from('lesson_progress')
          .select('watch_time')
          .eq('user_id', userId);

      int totalSeconds = 0;
      for (final item in response as List) {
        final watchTime = item['watch_time'];
        if (watchTime != null) {
          totalSeconds += watchTime as int;
        }
      }
      return totalSeconds;
    } catch (e) {
      return 0;
    }
  }

  /// Calculate consecutive days streak based on lesson_progress activity
  Future<int> _getDayStreak(String userId) async {
    try {
      // Get distinct dates when user had activity, ordered by most recent
      final response = await client
          .from('lesson_progress')
          .select('last_watched_at')
          .eq('user_id', userId)
          .order('last_watched_at', ascending: false);

      if ((response as List).isEmpty) return 0;

      // Extract unique dates (ignoring time)
      final Set<String> uniqueDates = {};
      for (final item in response) {
        final dateStr = item['last_watched_at'] as String?;
        if (dateStr != null) {
          final date = DateTime.parse(dateStr);
          uniqueDates.add('${date.year}-${date.month}-${date.day}');
        }
      }

      if (uniqueDates.isEmpty) return 0;

      // Sort dates descending
      final sortedDates = uniqueDates.toList()..sort((a, b) => b.compareTo(a));

      // Calculate streak starting from today or yesterday
      final now = DateTime.now();
      final today = '${now.year}-${now.month}-${now.day}';
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr =
          '${yesterday.year}-${yesterday.month}-${yesterday.day}';

      int streak = 0;
      DateTime checkDate;

      // Start from today if there's activity today, otherwise from yesterday
      if (sortedDates.contains(today)) {
        checkDate = now;
      } else if (sortedDates.contains(yesterdayStr)) {
        checkDate = yesterday;
      } else {
        return 0; // No recent activity, streak is 0
      }

      // Count consecutive days
      for (int i = 0; i < 365; i++) {
        final dateToCheck = checkDate.subtract(Duration(days: i));
        final dateStr =
            '${dateToCheck.year}-${dateToCheck.month}-${dateToCheck.day}';

        if (sortedDates.contains(dateStr)) {
          streak++;
        } else {
          break;
        }
      }

      return streak;
    } catch (e) {
      AppLogger.e('[SettingsRemote] Error calculating streak: $e');
      return 0;
    }
  }

  @override
  Future<UserProfileModel> updateUserProfile(
      String userId, Map<String, dynamic> data) async {
    AppLogger.i('👤 [SettingsRemote] Updating profile for: $userId');

    final profileMeta = await client
        .from('profiles')
        .select('role, name')
        .eq('id', userId)
        .maybeSingle();

    final isInstructor = profileMeta?['role'] == 'instructor';

    // Separate profiles table fields and teachers table fields
    final profileFields = <String, dynamic>{};
    final teacherFields = <String, dynamic>{};

    // Columns that go directly into profiles table (both student and instructor fields)
    final profileColumns = [
      'name',
      'email',
      'phone',
      'avatar_url',
      'interests',
      'headline_ar',
      'headline_en',
      'bio_ar',
      'bio_en',
      'expertise',
      'social_links',
      'parent_phone',
    ];

    data.forEach((key, value) {
      if (key == 'display_name') {
        if (isInstructor) {
          teacherFields['display_name'] = value;
        }
        return;
      }
      if (key == 'bio') {
        if (isInstructor) {
          teacherFields['bio'] = value;
        }
        return;
      }
      if (key == 'avatar_url') {
        profileFields[key] = value;
        if (isInstructor) {
          teacherFields['avatar_url'] = value;
        }
        return;
      }

      if (profileColumns.contains(key)) {
        profileFields[key] = value;
      } else {
        if (isInstructor) {
          teacherFields[key] = value;
        }
      }
    });

    // Update profiles table if there are profile fields
    if (profileFields.isNotEmpty) {
      await client.from('profiles').update(profileFields).eq('id', userId);
    }

    // Update teachers table if instructor
    if (isInstructor && teacherFields.isNotEmpty) {
      // Sync teacher display name with profiles.name if not specified
      if (!teacherFields.containsKey('display_name') && profileFields.containsKey('name')) {
        teacherFields['display_name'] = profileFields['name'];
      }
      // Sync teacher avatar if profiles.avatar_url is updated
      if (!teacherFields.containsKey('avatar_url') && profileFields.containsKey('avatar_url')) {
        teacherFields['avatar_url'] = profileFields['avatar_url'];
      }

      await client.from('teachers').upsert({
        'profile_id': userId,
        'display_name': teacherFields['display_name'] ?? profileMeta?['name'] ?? 'مدرس',
        ...teacherFields,
      }, onConflict: 'profile_id');
    }

    // Fetch and return the updated profile
    return getUserProfile(userId);
  }

  @override
  Future<List<AchievementModel>> getUserAchievements(String userId) async {
    AppLogger.i('🏆 [SettingsRemote] Getting achievements for: $userId');

    // Mock achievements for now - can be replaced with actual DB query
    return [
      const AchievementModel(
        id: '1',
        title: 'First Steps',
        description: 'Completed 1st Course',
        iconName: 'military_tech',
        isUnlocked: true,
      ),
      const AchievementModel(
        id: '2',
        title: 'Fast Learner',
        description: '3h in one day',
        iconName: 'electric_bolt',
        isUnlocked: true,
      ),
      const AchievementModel(
        id: '3',
        title: 'Scholar',
        description: '5 Courses Done',
        iconName: 'auto_stories',
        isUnlocked: false,
      ),
      const AchievementModel(
        id: '4',
        title: 'Champion',
        description: '10 Courses Done',
        iconName: 'trophy',
        isUnlocked: false,
      ),
    ];
  }

  @override
  Future<bool> deleteAccount(String userId) async {
    AppLogger.i('🗑️ [SettingsRemote] Deleting account: $userId');
    // Account deletion logic - typically handled by backend
    return true;
  }

  @override
  Future<bool> logout() async {
    AppLogger.i('🚪 [SettingsRemote] Logging out');
    try {
      // Sign out from all devices (global scope)
      await client.auth.signOut(scope: SignOutScope.global);
      AppLogger.success('🚪 [SettingsRemote] Signed out successfully');
      return true;
    } catch (e) {
      AppLogger.e('🚪 [SettingsRemote] Sign out error: $e');
      // Try local sign out as fallback
      try {
        await client.auth.signOut(scope: SignOutScope.local);
        return true;
      } catch (e2) {
        AppLogger.e('🚪 [SettingsRemote] Local sign out also failed: $e2');
        return false;
      }
    }
  }
}
