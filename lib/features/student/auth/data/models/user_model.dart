import 'package:lms_platform/features/student/auth/domain/entities/user_entity.dart';

/// User Model - Data Model with JSON serialization
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.name,
    super.phone,
    super.role,
    super.avatarUrl,
    super.interests,
    super.isActive,
    super.isBanned,
    super.bannedUntil,
    super.banReason,
    required super.createdAt,
    super.updatedAt,
    super.headlineAr,
    super.headlineEn,
    super.bioAr,
    super.bioEn,
    super.expertise,
    super.socialLinks,
    super.isVerifiedInstructor,
    super.linkedStudentIds,
    super.parentVerificationStatus,
    super.parentPhone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      role: UserRole.fromString(json['role'] as String? ?? 'student'),
      avatarUrl: json['avatar_url'] as String?,
      interests: (json['interests'] as List<dynamic>?)?.cast<String>() ?? [],
      isActive: json['is_active'] as bool? ?? true,
      isBanned: json['is_banned'] as bool? ?? false,
      bannedUntil: json['banned_until'] != null
          ? DateTime.parse(json['banned_until'] as String)
          : null,
      banReason: json['ban_reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      headlineAr: json['headline_ar'] as String?,
      headlineEn: json['headline_en'] as String?,
      bioAr: json['bio_ar'] as String?,
      bioEn: json['bio_en'] as String?,
      expertise: (json['expertise'] as List<dynamic>?)?.cast<String>() ?? [],
      socialLinks: (json['social_links'] as Map<String, dynamic>?) ?? {},
      isVerifiedInstructor: json['is_verified_instructor'] as bool? ?? false,
      linkedStudentIds:
          (json['linked_student_ids'] as List<dynamic>?)?.cast<String>() ?? [],
      parentVerificationStatus: json['parent_verification_status'] as String?,
      parentPhone: json['parent_phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role.toJson(),
      'avatar_url': avatarUrl,
      'interests': interests,
      'is_active': isActive,
      'is_banned': isBanned,
      'banned_until': bannedUntil?.toIso8601String(),
      'ban_reason': banReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'headline_ar': headlineAr,
      'headline_en': headlineEn,
      'bio_ar': bioAr,
      'bio_en': bioEn,
      'expertise': expertise,
      'social_links': socialLinks,
      'is_verified_instructor': isVerifiedInstructor,
      'linked_student_ids': linkedStudentIds,
      'parent_verification_status': parentVerificationStatus,
      'parent_phone': parentPhone,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    UserRole? role,
    String? avatarUrl,
    List<String>? interests,
    bool? isActive,
    bool? isBanned,
    DateTime? bannedUntil,
    String? banReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? headlineAr,
    String? headlineEn,
    String? bioAr,
    String? bioEn,
    List<String>? expertise,
    Map<String, dynamic>? socialLinks,
    bool? isVerifiedInstructor,
    List<String>? linkedStudentIds,
    String? parentVerificationStatus,
    String? parentPhone,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      interests: interests ?? this.interests,
      isActive: isActive ?? this.isActive,
      isBanned: isBanned ?? this.isBanned,
      bannedUntil: bannedUntil ?? this.bannedUntil,
      banReason: banReason ?? this.banReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      headlineAr: headlineAr ?? this.headlineAr,
      headlineEn: headlineEn ?? this.headlineEn,
      bioAr: bioAr ?? this.bioAr,
      bioEn: bioEn ?? this.bioEn,
      expertise: expertise ?? this.expertise,
      socialLinks: socialLinks ?? this.socialLinks,
      isVerifiedInstructor: isVerifiedInstructor ?? this.isVerifiedInstructor,
      linkedStudentIds: linkedStudentIds ?? this.linkedStudentIds,
      parentVerificationStatus:
          parentVerificationStatus ?? this.parentVerificationStatus,
      parentPhone: parentPhone ?? this.parentPhone,
    );
  }
}
