import 'package:lms_platform/features/student/my_learning/domain/entities/enrollment_entity.dart';

/// Enrollment Model - Data Model with JSON serialization
class EnrollmentModel extends EnrollmentEntity {
  const EnrollmentModel({
    required super.id,
    required super.courseId,
    required super.userId,
    super.titleAr,
    super.titleEn,
    super.thumbnailUrl,
    super.instructorId,
    super.instructorName,
    super.instructorAvatar,
    super.progressPercentage,
    super.completedLessons,
    super.totalLessons,
    super.totalDurationMinutes,
    super.remainingMinutes,
    super.status,
    required super.enrolledAt,
    super.lastAccessedAt,
    super.completedAt,
    super.accessExpiresAt,
    super.availableFrom,
    super.availableUntil,
    super.rating,
    super.ratingCount,
  });

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    final course = json['courses'] as Map<String, dynamic>?;

    // Handle instructor name, id and avatar
    String? instructorId;
    String? instructorName;
    String? instructorAvatar;

    instructorId = course?['teacher_id'] as String?;

    final teacher = course?['teachers'] as Map<String, dynamic>?;
    if (teacher != null) {
      instructorName = teacher['display_name'] as String?;
      instructorAvatar = teacher['avatar_url'] as String?;
    }

    // Parse status
    EnrollmentStatus status = EnrollmentStatus.active;
    final statusStr = json['status'] as String?;
    if (statusStr == 'completed') {
      status = EnrollmentStatus.completed;
    } else if (statusStr == 'expired') {
      status = EnrollmentStatus.expired;
    } else if (statusStr == 'refunded') {
      status = EnrollmentStatus.refunded;
    }

    // Calculate remaining minutes
    final totalDuration = course?['total_duration'] as int? ?? 0;
    final progress = (json['progress_percentage'] as num?)?.toDouble() ?? 0;
    final remaining = (totalDuration * (100 - progress) / 100).round();

    return EnrollmentModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      userId: json['user_id'] as String,
      titleAr: course?['title_ar'] as String?,
      titleEn: course?['title_en'] as String?,
      thumbnailUrl: course?['thumbnail_url'] as String?,
      instructorId: instructorId,
      instructorName: instructorName,
      instructorAvatar: instructorAvatar,
      progressPercentage: progress,
      completedLessons: json['completed_lessons'] as int? ?? 0,
      totalLessons: course?['total_lessons'] as int? ?? 0,
      totalDurationMinutes: totalDuration,
      remainingMinutes: remaining,
      status: status,
      enrolledAt: DateTime.parse(json['enrolled_at'] as String),
      lastAccessedAt: json['last_accessed_at'] != null
          ? DateTime.parse(json['last_accessed_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      accessExpiresAt: json['access_expires_at'] != null
          ? DateTime.parse(json['access_expires_at'] as String)
          : null,
      availableFrom: course?['available_from'] != null
          ? DateTime.parse(course!['available_from'] as String)
          : null,
      availableUntil: course?['available_until'] != null
          ? DateTime.parse(course!['available_until'] as String)
          : null,
      rating: (course?['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: course?['rating_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'user_id': userId,
      'progress_percentage': progressPercentage,
      'completed_lessons': completedLessons,
      'status': status.name,
      'enrolled_at': enrolledAt.toIso8601String(),
      'last_accessed_at': lastAccessedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'access_expires_at': accessExpiresAt?.toIso8601String(),
      'available_from': availableFrom?.toIso8601String(),
      'available_until': availableUntil?.toIso8601String(),
    };
  }

  /// Create a copy with updated instructor data
  EnrollmentModel copyWithInstructor({
    String? instructorName,
    String? instructorAvatar,
  }) {
    return EnrollmentModel(
      id: id,
      courseId: courseId,
      userId: userId,
      titleAr: titleAr,
      titleEn: titleEn,
      thumbnailUrl: thumbnailUrl,
      instructorId: instructorId,
      instructorName: instructorName ?? this.instructorName,
      instructorAvatar: instructorAvatar ?? this.instructorAvatar,
      progressPercentage: progressPercentage,
      completedLessons: completedLessons,
      totalLessons: totalLessons,
      totalDurationMinutes: totalDurationMinutes,
      remainingMinutes: remainingMinutes,
      status: status,
      enrolledAt: enrolledAt,
      lastAccessedAt: lastAccessedAt,
      completedAt: completedAt,
      accessExpiresAt: accessExpiresAt,
      availableFrom: availableFrom,
      availableUntil: availableUntil,
      rating: rating,
      ratingCount: ratingCount,
    );
  }
}
