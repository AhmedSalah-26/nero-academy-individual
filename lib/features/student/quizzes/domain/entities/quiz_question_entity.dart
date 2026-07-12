import 'package:equatable/equatable.dart';

/// Quiz Question Entity - Pure Dart Object
class QuizQuestionEntity extends Equatable {
  final String id;
  final String quizId;
  final String questionAr;
  final String? questionEn;
  final String? imageUrl;
  final QuestionType questionType;
  final int points;
  final String? explanationAr;
  final String? explanationEn;
  final List<QuizOptionEntity> options;
  final int sortOrder;

  const QuizQuestionEntity({
    required this.id,
    required this.quizId,
    required this.questionAr,
    this.questionEn,
    this.imageUrl,
    required this.questionType,
    required this.points,
    this.explanationAr,
    this.explanationEn,
    this.options = const [],
    this.sortOrder = 0,
  });

  /// Get localized question
  String getQuestion(String locale) {
    if (locale == 'en' && questionEn != null && questionEn!.isNotEmpty) {
      return questionEn!;
    }
    return questionAr;
  }

  /// Get localized explanation
  String? getExplanation(String locale) {
    if (locale == 'en' && explanationEn != null && explanationEn!.isNotEmpty) {
      return explanationEn;
    }
    return explanationAr;
  }

  /// Get correct option(s)
  List<QuizOptionEntity> get correctOptions {
    return options.where((o) => o.isCorrect).toList();
  }

  /// Check if answer is correct
  bool isAnswerCorrect(List<String> selectedOptionIds) {
    final correctIds = correctOptions.map((o) => o.id).toSet();
    final selectedIds = selectedOptionIds.toSet();
    return correctIds.length == selectedIds.length &&
        correctIds.containsAll(selectedIds);
  }

  @override
  List<Object?> get props => [
        id,
        quizId,
        questionAr,
        imageUrl,
        questionType,
        points,
        options,
        sortOrder,
      ];
}

/// Quiz Option Entity
class QuizOptionEntity extends Equatable {
  final String id;
  final String textAr;
  final String? textEn;
  final bool isCorrect;
  final int sortOrder;

  const QuizOptionEntity({
    required this.id,
    required this.textAr,
    this.textEn,
    required this.isCorrect,
    this.sortOrder = 0,
  });

  /// Get localized text
  String getText(String locale) {
    if (locale == 'en' && textEn != null && textEn!.isNotEmpty) {
      return textEn!;
    }
    return textAr;
  }

  @override
  List<Object?> get props => [id, textAr, textEn, isCorrect, sortOrder];
}

/// Question Type Enum
enum QuestionType {
  single,
  multiple,
  trueFalse,
  text;

  String get displayNameAr {
    switch (this) {
      case QuestionType.single:
        return 'اختيار واحد';
      case QuestionType.multiple:
        return 'اختيار متعدد';
      case QuestionType.trueFalse:
        return 'صح أو خطأ';
      case QuestionType.text:
        return 'إجابة نصية';
    }
  }

  String get displayNameEn {
    switch (this) {
      case QuestionType.single:
        return 'Single Choice';
      case QuestionType.multiple:
        return 'Multiple Choice';
      case QuestionType.trueFalse:
        return 'True/False';
      case QuestionType.text:
        return 'Text Answer';
    }
  }
}
