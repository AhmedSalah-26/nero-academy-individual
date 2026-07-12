import 'package:equatable/equatable.dart';

/// User Profile Entity - Pure Dart Object
class UserProfileEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final List<String> interests;
  final int coursesCount;
  final int totalWatchTimeSeconds; // Store in seconds for better precision
  final int dayStreak;
  final List<AchievementEntity> achievements;
  final DateTime? createdAt;
  // Instructor fields
  final String? displayName;
  final String? headlineAr;
  final String? headlineEn;
  final String? bioAr;
  final String? bioEn;
  final String? websiteUrl;
  final String? coverImageUrl;
  final List<String>? expertise;
  final Map<String, dynamic>? socialLinks;
  final String? parentPhone;

  const UserProfileEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.role = 'student',
    this.interests = const [],
    this.coursesCount = 0,
    this.totalWatchTimeSeconds = 0,
    this.dayStreak = 0,
    this.achievements = const [],
    this.createdAt,
    this.displayName,
    this.headlineAr,
    this.headlineEn,
    this.bioAr,
    this.bioEn,
    this.websiteUrl,
    this.coverImageUrl,
    this.expertise,
    this.socialLinks,
    this.parentPhone,
  });

  /// Get formatted watch time string (e.g., "45m", "2h 30m", "1h")
  String get formattedWatchTime {
    if (totalWatchTimeSeconds <= 0) return '0m';

    final hours = totalWatchTimeSeconds ~/ 3600;
    final minutes = (totalWatchTimeSeconds % 3600) ~/ 60;

    if (hours == 0) {
      return '${minutes}m';
    } else if (minutes == 0) {
      return '${hours}h';
    } else {
      return '${hours}h ${minutes}m';
    }
  }

  UserProfileEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? role,
    List<String>? interests,
    int? coursesCount,
    int? totalWatchTimeSeconds,
    int? dayStreak,
    List<AchievementEntity>? achievements,
    DateTime? createdAt,
    String? displayName,
    String? headlineAr,
    String? headlineEn,
    String? bioAr,
    String? bioEn,
    String? websiteUrl,
    String? coverImageUrl,
    List<String>? expertise,
    Map<String, dynamic>? socialLinks,
    String? parentPhone,
  }) {
    return UserProfileEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      interests: interests ?? this.interests,
      coursesCount: coursesCount ?? this.coursesCount,
      totalWatchTimeSeconds:
          totalWatchTimeSeconds ?? this.totalWatchTimeSeconds,
      dayStreak: dayStreak ?? this.dayStreak,
      achievements: achievements ?? this.achievements,
      createdAt: createdAt ?? this.createdAt,
      displayName: displayName ?? this.displayName,
      headlineAr: headlineAr ?? this.headlineAr,
      headlineEn: headlineEn ?? this.headlineEn,
      bioAr: bioAr ?? this.bioAr,
      bioEn: bioEn ?? this.bioEn,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      expertise: expertise ?? this.expertise,
      socialLinks: socialLinks ?? this.socialLinks,
      parentPhone: parentPhone ?? this.parentPhone,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        avatarUrl,
        role,
        interests,
        coursesCount,
        totalWatchTimeSeconds,
        dayStreak,
        achievements,
        createdAt,
        displayName,
        headlineAr,
        headlineEn,
        bioAr,
        bioEn,
        websiteUrl,
        coverImageUrl,
        expertise,
        socialLinks,
        parentPhone,
      ];
}

/// Achievement Entity
class AchievementEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const AchievementEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  @override
  List<Object?> get props =>
      [id, title, description, iconName, isUnlocked, unlockedAt];
}
