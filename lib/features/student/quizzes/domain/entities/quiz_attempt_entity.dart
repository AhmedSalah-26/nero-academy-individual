import 'package:equatable/equatable.dart';

/// Quiz Attempt Entity - Pure Dart Object
class QuizAttemptEntity extends Equatable {
  final String id;
  final String quizId;
  final String enrollmentId;
  final int score;
  final int totalPoints;
  final double percentage;
  final bool passed;
  final int? timeSpentSeconds;
  final Map<String, QuizAnswerEntity> answers;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const QuizAttemptEntity({
    required this.id,
    required this.quizId,
    required this.enrollmentId,
    required this.score,
    required this.totalPoints,
    required this.percentage,
    required this.passed,
    this.timeSpentSeconds,
    this.answers = const {},
    this.startedAt,
    this.completedAt,
  });

  /// Check if attempt is completed
  bool get isCompleted => completedAt != null;

  /// Get formatted time spent
  String get formattedTimeSpent {
    if (timeSpentSeconds == null) return '';
    final minutes = timeSpentSeconds! ~/ 60;
    final seconds = timeSpentSeconds! % 60;
    if (minutes > 0) {
      return '$minutes دقيقة ${seconds > 0 ? '$seconds ثانية' : ''}';
    }
    return '$seconds ثانية';
  }

  /// Get formatted percentage
  String get formattedPercentage => '${percentage.toStringAsFixed(0)}%';

  /// Get score display
  String get scoreDisplay => '$score/$totalPoints';

  @override
  List<Object?> get props => [
        id,
        quizId,
        enrollmentId,
        score,
        totalPoints,
        percentage,
        passed,
        timeSpentSeconds,
        completedAt,
      ];
}

/// Quiz Answer Entity
class QuizAnswerEntity extends Equatable {
  final String questionId;
  final List<String> selectedOptionIds;
  final String? textAnswer;
  final bool isCorrect;
  final int pointsEarned;

  const QuizAnswerEntity({
    required this.questionId,
    this.selectedOptionIds = const [],
    this.textAnswer,
    required this.isCorrect,
    required this.pointsEarned,
  });

  @override
  List<Object?> get props => [
        questionId,
        selectedOptionIds,
        textAnswer,
        isCorrect,
        pointsEarned,
      ];
}
