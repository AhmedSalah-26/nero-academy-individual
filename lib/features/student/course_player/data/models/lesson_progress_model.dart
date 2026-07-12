import 'package:lms_platform/features/student/course_player/domain/entities/lesson_progress_entity.dart';

/// Lesson Progress Model - Data Model with JSON serialization
class LessonProgressModel extends LessonProgressEntity {
  const LessonProgressModel({
    required super.id,
    required super.lessonId,
    required super.enrollmentId,
    super.isCompleted,
    super.watchedSeconds,
    super.lastPosition,
    super.completedAt,
    super.lastAccessedAt,
  });

  /// Create from JSON
  factory LessonProgressModel.fromJson(Map<String, dynamic> json) {
    return LessonProgressModel(
      id: json['id'] as String,
      lessonId: json['lesson_id'] as String,
      enrollmentId: json['enrollment_id'] as String,
      isCompleted: json['is_completed'] as bool? ?? false,
      watchedSeconds: json['watch_time'] as int? ?? 0,
      lastPosition: json['last_position'] as int? ?? 0,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      lastAccessedAt: json['last_watched_at'] != null
          ? DateTime.parse(json['last_watched_at'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lesson_id': lessonId,
      'enrollment_id': enrollmentId,
      'is_completed': isCompleted,
      'watch_time': watchedSeconds,
      'last_position': lastPosition,
      'completed_at': completedAt?.toIso8601String(),
      'last_watched_at': lastAccessedAt?.toIso8601String(),
    };
  }
}
