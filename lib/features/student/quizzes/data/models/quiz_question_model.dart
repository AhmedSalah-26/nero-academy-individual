import 'package:lms_platform/features/student/quizzes/domain/entities/quiz_question_entity.dart';

/// Quiz Question Model - Data Model with JSON serialization
class QuizQuestionModel extends QuizQuestionEntity {
  const QuizQuestionModel({
    required super.id,
    required super.quizId,
    required super.questionAr,
    super.questionEn,
    super.imageUrl,
    required super.questionType,
    required super.points,
    super.explanationAr,
    super.explanationEn,
    super.options,
    super.sortOrder,
  });

  /// Create from JSON
  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    final optionsJson = json['options'] as List<dynamic>? ?? [];
    final options = optionsJson
        .map((o) => QuizOptionModel.fromJson(o as Map<String, dynamic>))
        .toList();

    return QuizQuestionModel(
      id: json['id'] as String? ?? '',
      quizId: json['quiz_id'] as String? ?? '',
      questionAr: json['question_ar'] as String? ?? '',
      questionEn: json['question_en'] as String?,
      imageUrl: json['image_url'] as String?,
      questionType: _parseQuestionType(json['question_type'] as String?),
      points: json['points'] as int? ?? 1,
      explanationAr: json['explanation_ar'] as String?,
      explanationEn: json['explanation_en'] as String?,
      options: options,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quiz_id': quizId,
      'question_ar': questionAr,
      'question_en': questionEn,
      'image_url': imageUrl,
      'question_type': questionType.name,
      'points': points,
      'explanation_ar': explanationAr,
      'explanation_en': explanationEn,
      'options': options.map((o) => (o as QuizOptionModel).toJson()).toList(),
      'sort_order': sortOrder,
    };
  }

  static QuestionType _parseQuestionType(String? type) {
    switch (type) {
      case 'single':
        return QuestionType.single;
      case 'multiple':
        return QuestionType.multiple;
      case 'true_false':
        return QuestionType.trueFalse;
      case 'text':
        return QuestionType.text;
      default:
        return QuestionType.single;
    }
  }
}

/// Quiz Option Model
class QuizOptionModel extends QuizOptionEntity {
  const QuizOptionModel({
    required super.id,
    required super.textAr,
    super.textEn,
    required super.isCorrect,
    super.sortOrder,
  });

  /// Create from JSON
  factory QuizOptionModel.fromJson(Map<String, dynamic> json) {
    return QuizOptionModel(
      id: json['id'] as String? ?? '',
      textAr: json['text_ar'] as String? ?? '',
      textEn: json['text_en'] as String?,
      isCorrect: json['is_correct'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text_ar': textAr,
      'text_en': textEn,
      'is_correct': isCorrect,
      'sort_order': sortOrder,
    };
  }
}
