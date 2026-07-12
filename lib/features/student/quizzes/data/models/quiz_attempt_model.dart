import 'package:lms_platform/features/student/quizzes/domain/entities/quiz_attempt_entity.dart';

/// Quiz Attempt Model - Data Model with JSON serialization
class QuizAttemptModel extends QuizAttemptEntity {
  const QuizAttemptModel({
    required super.id,
    required super.quizId,
    required super.enrollmentId,
    required super.score,
    required super.totalPoints,
    required super.percentage,
    required super.passed,
    super.timeSpentSeconds,
    super.answers,
    super.startedAt,
    super.completedAt,
  });

  /// Create from JSON
  factory QuizAttemptModel.fromJson(Map<String, dynamic> json) {
    final answers = <String, QuizAnswerEntity>{};

    // Handle answers - could be different formats
    final answersData = json['answers'];
    if (answersData is Map<String, dynamic>) {
      answersData.forEach((questionId, value) {
        if (value is Map<String, dynamic>) {
          // New format: {"question_id": {"selected_option_ids": [...], "is_correct": bool, "points_earned": int}}
          // Or full format: {"question_id": {"question_id": "...", "selected_option_ids": [...]}}
          answers[questionId] =
              QuizAnswerModel.fromJsonWithKey(questionId, value);
        } else if (value is List) {
          // Simple format: {"question_id": ["option1", "option2"]}
          answers[questionId] = QuizAnswerModel(
            questionId: questionId,
            selectedOptionIds: value.map((e) => e.toString()).toList(),
            isCorrect: false,
            pointsEarned: 0,
          );
        }
      });
    } else if (answersData is List) {
      for (final item in answersData) {
        if (item is Map<String, dynamic>) {
          final questionId = item['question_id'] as String?;
          if (questionId != null) {
            answers[questionId] = QuizAnswerModel.fromJson(item);
          }
        }
      }
    }

    return QuizAttemptModel(
      id: json['id'] as String,
      quizId: json['quiz_id'] as String,
      enrollmentId: json['enrollment_id'] as String,
      score: json['score'] as int? ?? 0,
      totalPoints: json['total_points'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      passed: json['passed'] as bool? ?? false,
      timeSpentSeconds: json['time_spent'] as int?,
      answers: answers,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    final answersJson = <String, dynamic>{};
    answers.forEach((key, value) {
      answersJson[key] = (value as QuizAnswerModel).toJson();
    });

    return {
      'id': id,
      'quiz_id': quizId,
      'enrollment_id': enrollmentId,
      'score': score,
      'total_points': totalPoints,
      'percentage': percentage,
      'passed': passed,
      'time_spent': timeSpentSeconds,
      'answers': answersJson,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}

/// Quiz Answer Model
class QuizAnswerModel extends QuizAnswerEntity {
  const QuizAnswerModel({
    required super.questionId,
    super.selectedOptionIds,
    super.textAnswer,
    required super.isCorrect,
    required super.pointsEarned,
  });

  /// Create from JSON (when question_id is inside the json)
  factory QuizAnswerModel.fromJson(Map<String, dynamic> json) {
    return QuizAnswerModel(
      questionId: json['question_id'] as String,
      selectedOptionIds: _parseOptionIds(json['selected_option_ids']),
      textAnswer: json['text_answer'] as String?,
      isCorrect: json['is_correct'] as bool? ?? false,
      pointsEarned: json['points_earned'] as int? ?? 0,
    );
  }

  /// Create from JSON with external key (when question_id is the map key)
  factory QuizAnswerModel.fromJsonWithKey(
      String questionId, Map<String, dynamic> json) {
    return QuizAnswerModel(
      questionId: json['question_id'] as String? ?? questionId,
      selectedOptionIds: _parseOptionIds(json['selected_option_ids']),
      textAnswer: json['text_answer'] as String?,
      isCorrect: json['is_correct'] as bool? ?? false,
      pointsEarned: json['points_earned'] as int? ?? 0,
    );
  }

  /// Parse option IDs from various formats
  static List<String> _parseOptionIds(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'selected_option_ids': selectedOptionIds,
      'text_answer': textAnswer,
      'is_correct': isCorrect,
      'points_earned': pointsEarned,
    };
  }
}
