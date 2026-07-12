import 'package:lms_platform/features/student/settings/domain/entities/user_profile_entity.dart';

/// User Profile Model - Data Model with JSON serialization
class UserProfileModel extends UserProfileEntity {
  const UserProfileModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    super.avatarUrl,
    super.role,
    super.interests,
    super.coursesCount,
    super.totalWatchTimeSeconds,
    super.dayStreak,
    super.achievements,
    super.createdAt,
    super.displayName,
    super.headlineAr,
    super.headlineEn,
    super.bioAr,
    super.bioEn,
    super.expertise,
    super.socialLinks,
    super.websiteUrl,
    super.coverImageUrl,
    super.parentPhone,
  });

  /// Create from JSON
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'student',
      interests: (json['interests'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      coursesCount: json['courses_count'] as int? ?? 0,
      totalWatchTimeSeconds: json['total_watch_time_seconds'] as int? ?? 0,
      dayStreak: json['day_streak'] as int? ?? 0,
      achievements: (json['achievements'] as List<dynamic>?)
              ?.map((e) => AchievementModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      // Instructor fields
      displayName: json['display_name'] as String?,
      headlineAr: json['headline_ar'] as String?,
      headlineEn: json['headline_en'] as String?,
      bioAr: json['bio_ar'] as String?,
      bioEn: json['bio_en'] as String?,
      expertise: (json['expertise'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      socialLinks: json['social_links'] as Map<String, dynamic>?,
      websiteUrl: json['website_url'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      parentPhone: json['parent_phone'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'role': role,
      'interests': interests,
      'courses_count': coursesCount,
      'total_watch_time_seconds': totalWatchTimeSeconds,
      'day_streak': dayStreak,
      'created_at': createdAt?.toIso8601String(),
      'display_name': displayName,
      'headline_ar': headlineAr,
      'headline_en': headlineEn,
      'bio_ar': bioAr,
      'bio_en': bioEn,
      'expertise': expertise,
      'social_links': socialLinks,
      'website_url': websiteUrl,
      'cover_image_url': coverImageUrl,
      'parent_phone': parentPhone,
    };
  }

  /// Create from Entity
  factory UserProfileModel.fromEntity(UserProfileEntity entity) {
    return UserProfileModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      phone: entity.phone,
      avatarUrl: entity.avatarUrl,
      role: entity.role,
      interests: entity.interests,
      coursesCount: entity.coursesCount,
      totalWatchTimeSeconds: entity.totalWatchTimeSeconds,
      dayStreak: entity.dayStreak,
      achievements: entity.achievements,
      createdAt: entity.createdAt,
      displayName: entity.displayName,
      headlineAr: entity.headlineAr,
      headlineEn: entity.headlineEn,
      bioAr: entity.bioAr,
      bioEn: entity.bioEn,
      expertise: entity.expertise,
      socialLinks: entity.socialLinks,
      websiteUrl: entity.websiteUrl,
      coverImageUrl: entity.coverImageUrl,
      parentPhone: entity.parentPhone,
    );
  }
}

/// Achievement Model
class AchievementModel extends AchievementEntity {
  const AchievementModel({
    required super.id,
    required super.title,
    required super.description,
    required super.iconName,
    super.isUnlocked,
    super.unlockedAt,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconName: json['icon_name'] as String,
      isUnlocked: json['is_unlocked'] as bool? ?? false,
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.parse(json['unlocked_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon_name': iconName,
      'is_unlocked': isUnlocked,
      'unlocked_at': unlockedAt?.toIso8601String(),
    };
  }
}
