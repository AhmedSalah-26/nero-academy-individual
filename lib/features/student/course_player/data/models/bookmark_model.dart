import 'package:lms_platform/features/student/course_player/domain/entities/bookmark_entity.dart';

/// Bookmark Model - Data Model with JSON serialization
class BookmarkModel extends BookmarkEntity {
  const BookmarkModel({
    required super.id,
    required super.lessonId,
    required super.enrollmentId,
    super.note,
    required super.createdAt,
    super.lessonTitle,
  });

  /// Create from JSON
  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    // Handle nested lesson data
    String? lessonTitle;
    if (json['lessons'] != null) {
      final lesson = json['lessons'] as Map<String, dynamic>;
      // Try to get title_ar first, fallback to title_en
      lessonTitle =
          lesson['title_ar'] as String? ?? lesson['title_en'] as String?;
    }

    return BookmarkModel(
      id: json['id'] as String,
      lessonId: json['lesson_id'] as String,
      // Database uses user_id, but we store it as enrollmentId for app logic
      enrollmentId: json['user_id'] as String? ?? '',
      note: json['note'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      lessonTitle: lessonTitle,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lesson_id': lessonId,
      'user_id': enrollmentId,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
