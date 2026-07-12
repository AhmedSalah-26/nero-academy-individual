class ManagedCourse {
  final String id;
  final String titleAr;
  final String titleEn;
  final bool hasGroup;

  const ManagedCourse({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.hasGroup,
  });

  factory ManagedCourse.fromJson(Map<String, dynamic> row) {
    return ManagedCourse(
      id: row['course_id'] as String,
      titleAr: row['title_ar'] as String? ?? '',
      titleEn: row['title_en'] as String? ?? '',
      hasGroup: row['has_group'] as bool? ?? false,
    );
  }

  ManagedCourse copyWith({
    String? id,
    String? titleAr,
    String? titleEn,
    bool? hasGroup,
  }) {
    return ManagedCourse(
      id: id ?? this.id,
      titleAr: titleAr ?? this.titleAr,
      titleEn: titleEn ?? this.titleEn,
      hasGroup: hasGroup ?? this.hasGroup,
    );
  }

  String displayTitle(bool isArabic) {
    if (isArabic) {
      if (titleAr.isNotEmpty) return titleAr;
      if (titleEn.isNotEmpty) return titleEn;
      return 'بدون عنوان';
    }
    if (titleEn.isNotEmpty) return titleEn;
    if (titleAr.isNotEmpty) return titleAr;
    return 'Untitled course';
  }
}

class ManagedMember {
  final String userId;
  final String userName;
  final String? userAvatar;
  final String role;
  final bool isBanned;
  final String? bannedReason;

  const ManagedMember({
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.role,
    required this.isBanned,
    required this.bannedReason,
  });

  factory ManagedMember.fromJson(
    Map<String, dynamic> row, {
    required String unknownName,
  }) {
    return ManagedMember(
      userId: row['user_id'] as String,
      userName: row['user_name'] as String? ?? unknownName,
      userAvatar: row['user_avatar'] as String?,
      role: (row['role'] as String? ?? 'member').toLowerCase(),
      isBanned: row['is_banned'] as bool? ?? false,
      bannedReason: row['banned_reason'] as String?,
    );
  }

  String subtitle(bool isArabic) {
    if (isBanned) {
      final base = isArabic ? 'محظور' : 'Banned';
      if (bannedReason != null && bannedReason!.isNotEmpty) {
        return '$base: $bannedReason';
      }
      return base;
    }
    if (role == 'admin') {
      return isArabic ? 'أدمن' : 'Admin';
    }
    return isArabic ? 'عضو' : 'Member';
  }
}
