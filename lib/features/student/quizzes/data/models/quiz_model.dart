import 'package:lms_platform/features/student/quizzes/domain/entities/quiz_entity.dart';

/// Quiz Model - Data Model with JSON serialization
class QuizModel extends QuizEntity {
  const QuizModel({
    required super.id,
    super.sectionId,
    super.lessonId,
    required super.titleAr,
    super.titleEn,
    super.descriptionAr,
    super.descriptionEn,
    required super.passingScore,
    super.timeLimit,
    super.maxAttempts,
    super.shuffleQuestions,
    super.shuffleAnswers,
    super.showCorrectAnswers,
    super.isMandatory,
    super.isPublished,
    super.totalQuestions,
    super.availableFrom,
    super.availableUntil,
    super.createdAt,
  });

  /// Create from JSON
  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['id'] as String,
      sectionId: json['section_id'] as String?,
      lessonId: json['lesson_id'] as String?,
      titleAr: json['title_ar'] as String,
      titleEn: json['title_en'] as String?,
      descriptionAr: json['description_ar'] as String?,
      descriptionEn: json['description_en'] as String?,
      passingScore: json['passing_score'] as int? ?? 70,
      timeLimit: json['time_limit'] as int?,
      maxAttempts: json['max_attempts'] as int?,
      shuffleQuestions: json['shuffle_questions'] as bool? ?? false,
      shuffleAnswers: json['shuffle_answers'] as bool? ?? false,
      showCorrectAnswers: json['show_correct_answers'] as bool? ?? true,
      isMandatory: json['is_mandatory'] as bool? ?? false,
      isPublished: json['is_published'] as bool? ?? true,
      totalQuestions: json['total_questions'] as int? ?? 0,
      availableFrom: json['available_from'] != null
          ? DateTime.parse(json['available_from'] as String)
          : null,
      availableUntil: json['available_until'] != null
          ? DateTime.parse(json['available_until'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'section_id': sectionId,
      'lesson_id': lessonId,
      'title_ar': titleAr,
      'title_en': titleEn,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'passing_score': passingScore,
      'time_limit': timeLimit,
      'max_attempts': maxAttempts,
      'shuffle_questions': shuffleQuestions,
      'shuffle_answers': shuffleAnswers,
      'show_correct_answers': showCorrectAnswers,
      'is_mandatory': isMandatory,
      'is_published': isPublished,
      'total_questions': totalQuestions,
      'available_from': availableFrom?.toUtc().toIso8601String(),
      'available_until': availableUntil?.toUtc().toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
