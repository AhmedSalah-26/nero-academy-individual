/// Admin User Model - Complete schema fields
class AdminUserModel {
  final String id;
  final String email;
  final String? name;
  final String? phone;
  final String role;
  final String? avatarUrl;
  // Instructor specific fields
  final String? headlineAr;
  final String? headlineEn;
  final String? bioAr;
  final String? bioEn;
  final List<String> expertise;
  final Map<String, dynamic> socialLinks;
  final bool isVerifiedInstructor;
  // Student specific fields
  final List<String> interests;
  // Common fields
  final bool isActive;
  final bool isBanned;
  final DateTime? bannedUntil;
  final String? banReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  // For instructors (stats)
  final int? totalCourses;
  final int? totalStudents;
  final double? averageRating;

  const AdminUserModel({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    required this.role,
    this.avatarUrl,
    this.headlineAr,
    this.headlineEn,
    this.bioAr,
    this.bioEn,
    this.expertise = const [],
    this.socialLinks = const {},
    this.isVerifiedInstructor = false,
    this.interests = const [],
    this.isActive = true,
    this.isBanned = false,
    this.bannedUntil,
    this.banReason,
    required this.createdAt,
    DateTime? updatedAt,
    this.totalCourses,
    this.totalStudents,
    this.averageRating,
  }) : updatedAt = updatedAt ?? createdAt;

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'student',
      avatarUrl: json['avatar_url'] as String?,
      headlineAr: json['headline_ar'] as String?,
      headlineEn: json['headline_en'] as String?,
      bioAr: json['bio_ar'] as String?,
      bioEn: json['bio_en'] as String?,
      expertise: (json['expertise'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      socialLinks: (json['social_links'] as Map<String, dynamic>?) ?? {},
      isVerifiedInstructor: json['is_verified_instructor'] as bool? ?? false,
      interests: (json['interests'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isActive: json['is_active'] as bool? ?? true,
      isBanned: json['is_banned'] as bool? ?? false,
      bannedUntil: json['banned_until'] != null
          ? DateTime.parse(json['banned_until'] as String)
          : null,
      banReason: json['ban_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      totalCourses: json['total_courses'] as int?,
      totalStudents: json['total_students'] as int?,
      averageRating: (json['average_rating'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'avatar_url': avatarUrl,
      'headline_ar': headlineAr,
      'headline_en': headlineEn,
      'bio_ar': bioAr,
      'bio_en': bioEn,
      'expertise': expertise,
      'social_links': socialLinks,
      'is_verified_instructor': isVerifiedInstructor,
      'interests': interests,
      'is_active': isActive,
      'is_banned': isBanned,
      'banned_until': bannedUntil?.toIso8601String(),
      'ban_reason': banReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'total_courses': totalCourses,
      'total_students': totalStudents,
      'average_rating': averageRating,
    };
  }

  String get displayName => name ?? email.split('@').first;

  AdminUserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? role,
    String? avatarUrl,
    String? headlineAr,
    String? headlineEn,
    String? bioAr,
    String? bioEn,
    List<String>? expertise,
    Map<String, dynamic>? socialLinks,
    bool? isVerifiedInstructor,
    List<String>? interests,
    bool? isActive,
    bool? isBanned,
    DateTime? bannedUntil,
    String? banReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalCourses,
    int? totalStudents,
    double? averageRating,
  }) {
    return AdminUserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      headlineAr: headlineAr ?? this.headlineAr,
      headlineEn: headlineEn ?? this.headlineEn,
      bioAr: bioAr ?? this.bioAr,
      bioEn: bioEn ?? this.bioEn,
      expertise: expertise ?? this.expertise,
      socialLinks: socialLinks ?? this.socialLinks,
      isVerifiedInstructor: isVerifiedInstructor ?? this.isVerifiedInstructor,
      interests: interests ?? this.interests,
      isActive: isActive ?? this.isActive,
      isBanned: isBanned ?? this.isBanned,
      bannedUntil: bannedUntil ?? this.bannedUntil,
      banReason: banReason ?? this.banReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalCourses: totalCourses ?? this.totalCourses,
      totalStudents: totalStudents ?? this.totalStudents,
      averageRating: averageRating ?? this.averageRating,
    );
  }
}
