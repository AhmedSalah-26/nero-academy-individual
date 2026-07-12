import 'package:equatable/equatable.dart';

/// User Entity - Pure Dart Object
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String? phone;
  final UserRole role;
  final String? avatarUrl;
  final List<String> interests;
  final bool isActive;
  final bool isBanned;
  final DateTime? bannedUntil;
  final String? banReason;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Instructor specific fields
  final String? headlineAr;
  final String? headlineEn;
  final String? bioAr;
  final String? bioEn;
  final List<String> expertise;
  final Map<String, dynamic> socialLinks;
  final bool isVerifiedInstructor;

  // Parent specific fields
  final List<String> linkedStudentIds;
  final String? parentVerificationStatus;
  final String? parentPhone;

  const UserEntity({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    this.role = UserRole.student,
    this.avatarUrl,
    this.interests = const [],
    this.isActive = true,
    this.isBanned = false,
    this.bannedUntil,
    this.banReason,
    required this.createdAt,
    this.updatedAt,
    this.headlineAr,
    this.headlineEn,
    this.bioAr,
    this.bioEn,
    this.expertise = const [],
    this.socialLinks = const {},
    this.isVerifiedInstructor = false,
    this.linkedStudentIds = const [],
    this.parentVerificationStatus,
    this.parentPhone,
  });

  bool get isStudent => role == UserRole.student;
  bool get isInstructor => role == UserRole.instructor;
  bool get isParent => role == UserRole.parent;
  bool get isAdmin => role == UserRole.admin;
  bool get isVerifiedParent => parentVerificationStatus == 'verified';

  bool get canAccess {
    if (!isActive) return false;
    if (isBanned) {
      if (bannedUntil == null) return false;
      return DateTime.now().isAfter(bannedUntil!);
    }
    return true;
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        phone,
        role,
        avatarUrl,
        interests,
        isActive,
        isBanned,
        bannedUntil,
        banReason,
        createdAt,
        updatedAt,
        headlineAr,
        headlineEn,
        bioAr,
        bioEn,
        expertise,
        socialLinks,
        isVerifiedInstructor,
        linkedStudentIds,
        parentVerificationStatus,
        parentPhone,
      ];
}

/// User Role Enum
enum UserRole {
  student,
  instructor,
  parent,
  admin;

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'instructor':
        return UserRole.instructor;
      case 'parent':
        return UserRole.parent;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.student;
    }
  }

  String toJson() => name;
}
