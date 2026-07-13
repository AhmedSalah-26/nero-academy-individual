import 'package:lms_platform/features/student/course_search/domain/entities/course_entity.dart';
import 'package:lms_platform/core/utils/text_encoding_utils.dart';

/// Course Model - Data Model with JSON serialization
class CourseModel extends CourseEntity {
  const CourseModel({
    required super.id,
    required super.title,
    required super.instructorName,
    super.instructorAvatar,
    required super.thumbnailUrl,
    required super.rating,
    required super.reviewCount,
    required super.price,
    super.originalPrice,
    super.badge,
    super.categoryId,
    super.categoryName,
    super.durationMinutes,
    super.lectureCount,
    super.level,
    super.createdAt,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id']?.toString() ?? '',
      title: TextEncodingUtils.clean(json['title'] as String?),
      instructorName: TextEncodingUtils.clean(
          json['instructor_name'] as String? ??
              json['instructorName'] as String?),
      instructorAvatar: json['instructor_avatar'] ?? json['instructorAvatar'],
      thumbnailUrl: json['thumbnail_url'] ?? json['thumbnailUrl'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['review_count'] ?? json['reviewCount'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      originalPrice: json['original_price'] != null
          ? (json['original_price']).toDouble()
          : json['originalPrice'] != null
              ? (json['originalPrice']).toDouble()
              : null,
      badge: json['badge'],
      categoryId: json['category_id'] ?? json['categoryId'],
      categoryName: TextEncodingUtils.clean(
          json['category_name'] as String? ?? json['categoryName'] as String?),
      durationMinutes: json['duration_minutes'] ?? json['durationMinutes'],
      lectureCount: json['lecture_count'] ?? json['lectureCount'],
      level: json['level'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'instructor_name': instructorName,
      'instructor_avatar': instructorAvatar,
      'thumbnail_url': thumbnailUrl,
      'rating': rating,
      'review_count': reviewCount,
      'price': price,
      'original_price': originalPrice,
      'badge': badge,
      'category_id': categoryId,
      'category_name': categoryName,
      'duration_minutes': durationMinutes,
      'lecture_count': lectureCount,
      'level': level,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  CourseEntity toEntity() => this;
}
