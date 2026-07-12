import 'package:lms_platform/features/student/course_details/domain/entities/instructor_entity.dart';

/// Instructor Model - Data Model with JSON serialization
class InstructorModel extends InstructorEntity {
  const InstructorModel({
    required super.id,
    super.displayName,
    super.headlineAr,
    super.headlineEn,
    super.bioAr,
    super.bioEn,
    super.avatarUrl,
    super.coverImageUrl,
    super.totalStudents,
    super.totalCourses,
    super.totalReviews,
    super.averageRating,
    super.isVerified,
    super.expertise,
    super.socialLinks,
  });

  factory InstructorModel.fromJson(Map<String, dynamic> json) {
    // Parse expertise array
    List<String>? expertise;
    if (json['expertise'] != null) {
      expertise = (json['expertise'] as List).cast<String>();
    }

    // Parse social links
    Map<String, String>? socialLinks;
    if (json['social_links'] != null) {
      socialLinks = Map<String, String>.from(json['social_links'] as Map);
    }

    return InstructorModel(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      headlineAr: json['headline_ar'] as String?,
      headlineEn: json['headline_en'] as String?,
      bioAr: json['bio_ar'] as String?,
      bioEn: json['bio_en'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      totalStudents: json['total_students'] as int? ?? 0,
      totalCourses: json['total_courses'] as int? ?? 0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      expertise: expertise,
      socialLinks: socialLinks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'headline_ar': headlineAr,
      'headline_en': headlineEn,
      'bio_ar': bioAr,
      'bio_en': bioEn,
      'avatar_url': avatarUrl,
      'cover_image_url': coverImageUrl,
      'total_students': totalStudents,
      'total_courses': totalCourses,
      'total_reviews': totalReviews,
      'average_rating': averageRating,
      'is_verified': isVerified,
      'expertise': expertise,
      'social_links': socialLinks,
    };
  }
}
