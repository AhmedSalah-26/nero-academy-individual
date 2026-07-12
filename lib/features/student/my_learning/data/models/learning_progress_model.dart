import 'package:lms_platform/features/student/my_learning/domain/entities/learning_progress_entity.dart';

/// Learning Progress Model - Data Model with JSON serialization
class LearningProgressModel extends LearningProgressEntity {
  const LearningProgressModel({
    required super.id,
    required super.lessonId,
    required super.enrollmentId,
    super.isCompleted,
    super.watchedSeconds,
    super.totalSeconds,
    super.lastWatchedAt,
    super.completedAt,
  });

  factory LearningProgressModel.fromJson(Map<String, dynamic> json) {
    return LearningProgressModel(
      id: json['id'] as String,
      lessonId: json['lesson_id'] as String,
      enrollmentId: json['enrollment_id'] as String,
      isCompleted: json['is_completed'] as bool? ?? false,
      watchedSeconds: json['watch_time'] as int? ?? 0,
      totalSeconds: 0,
      lastWatchedAt: json['last_watched_at'] != null
          ? DateTime.parse(json['last_watched_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lesson_id': lessonId,
      'enrollment_id': enrollmentId,
      'is_completed': isCompleted,
      'watch_time': watchedSeconds,
      'last_watched_at': lastWatchedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}
