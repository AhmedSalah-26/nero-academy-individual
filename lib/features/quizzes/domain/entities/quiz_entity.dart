import 'package:equatable/equatable.dart';

/// Quiz Entity - Pure Dart Object
class QuizEntity extends Equatable {
  final String id;
  final String? lessonId;
  final String titleAr;
  final String? titleEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final int passingScore;
  final int? timeLimit;
  final int? maxAttempts;
  final bool shuffleQuestions;
  final bool shuffleAnswers;
  final bool showCorrectAnswers;
  final bool isMandatory;
  final int totalQuestions;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final DateTime? createdAt;

  const QuizEntity({
    required this.id,
    this.lessonId,
    required this.titleAr,
    this.titleEn,
    this.descriptionAr,
    this.descriptionEn,
    required this.passingScore,
    this.timeLimit,
    this.maxAttempts,
    this.shuffleQuestions = false,
    this.shuffleAnswers = false,
    this.showCorrectAnswers = true,
    this.isMandatory = false,
    this.totalQuestions = 0,
    this.availableFrom,
    this.availableUntil,
    this.createdAt,
  });

  /// Check if quiz is course-level (not tied to specific lesson)
  bool get isCourseLevelQuiz => lessonId == null;

  /// Get localized title
  String getTitle(String locale) {
    if (locale == 'en' && titleEn != null && titleEn!.isNotEmpty) {
      return titleEn!;
    }
    return titleAr;
  }

  /// Get localized description
  String? getDescription(String locale) {
    if (locale == 'en' && descriptionEn != null && descriptionEn!.isNotEmpty) {
      return descriptionEn;
    }
    return descriptionAr;
  }

  /// Check if quiz has time limit
  bool get hasTimeLimit => timeLimit != null && timeLimit! > 0;

  /// Check if quiz has attempt limit
  bool get hasAttemptLimit => maxAttempts != null && maxAttempts! > 0;

  bool get isScheduled =>
      availableFrom != null && DateTime.now().isBefore(availableFrom!);

  bool get isExpired =>
      availableUntil != null && !DateTime.now().isBefore(availableUntil!);

  bool get isAvailableNow => !isScheduled && !isExpired;

  /// Format time limit as string
  String get formattedTimeLimit {
    if (!hasTimeLimit) return '';
    final minutes = timeLimit!;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '$hours ساعة $mins دقيقة' : '$hours ساعة';
    }
    return '$minutes دقيقة';
  }

  @override
  List<Object?> get props => [
        id,
        lessonId,
        titleAr,
        titleEn,
        passingScore,
        timeLimit,
        maxAttempts,
        totalQuestions,
        availableFrom,
        availableUntil,
      ];
}
