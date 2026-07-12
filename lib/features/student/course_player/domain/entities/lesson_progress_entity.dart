import 'package:equatable/equatable.dart';

/// Lesson Progress Entity - Pure Dart Object
class LessonProgressEntity extends Equatable {
  final String id;
  final String lessonId;
  final String enrollmentId;
  final bool isCompleted;
  final int watchedSeconds;
  final int lastPosition;
  final DateTime? completedAt;
  final DateTime? lastAccessedAt;

  const LessonProgressEntity({
    required this.id,
    required this.lessonId,
    required this.enrollmentId,
    this.isCompleted = false,
    this.watchedSeconds = 0,
    this.lastPosition = 0,
    this.completedAt,
    this.lastAccessedAt,
  });

  /// Get progress percentage (0-100)
  double getProgressPercentage(int totalDuration) {
    if (totalDuration <= 0) return 0;
    return (watchedSeconds / totalDuration * 100).clamp(0, 100);
  }

  /// Check if lesson is started
  bool get isStarted => watchedSeconds > 0 || isCompleted;

  @override
  List<Object?> get props => [
        id,
        lessonId,
        enrollmentId,
        isCompleted,
        watchedSeconds,
        lastPosition,
        completedAt,
        lastAccessedAt,
      ];
}
