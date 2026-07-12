import 'package:equatable/equatable.dart';

/// Learning Progress Entity - Tracks lesson-level progress
class LearningProgressEntity extends Equatable {
  final String id;
  final String lessonId;
  final String enrollmentId;
  final bool isCompleted;
  final int watchedSeconds;
  final int totalSeconds;
  final DateTime? lastWatchedAt;
  final DateTime? completedAt;

  const LearningProgressEntity({
    required this.id,
    required this.lessonId,
    required this.enrollmentId,
    this.isCompleted = false,
    this.watchedSeconds = 0,
    this.totalSeconds = 0,
    this.lastWatchedAt,
    this.completedAt,
  });

  /// Get watch progress percentage
  double get watchPercentage {
    if (totalSeconds <= 0) return 0;
    return (watchedSeconds / totalSeconds * 100).clamp(0, 100);
  }

  /// Check if lesson is started
  bool get isStarted => watchedSeconds > 0;

  @override
  List<Object?> get props => [
        id,
        lessonId,
        enrollmentId,
        isCompleted,
        watchedSeconds,
      ];
}
