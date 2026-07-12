import 'package:equatable/equatable.dart';
import 'lesson_entity.dart';

/// Section Entity - Pure Dart Object
class SectionEntity extends Equatable {
  final String id;
  final String courseId;
  final String? titleAr;
  final String? titleEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final int sortOrder;
  final bool isPublished;
  final List<LessonEntity> lessons;

  const SectionEntity({
    required this.id,
    required this.courseId,
    this.titleAr,
    this.titleEn,
    this.descriptionAr,
    this.descriptionEn,
    this.sortOrder = 0,
    this.isPublished = true,
    this.lessons = const [],
  });

  String getTitle(String locale) =>
      locale == 'ar' ? (titleAr ?? titleEn ?? '') : (titleEn ?? titleAr ?? '');

  String getDescription(String locale) => locale == 'ar'
      ? (descriptionAr ?? descriptionEn ?? '')
      : (descriptionEn ?? descriptionAr ?? '');

  /// Total lessons count
  int get totalLessons => lessons.length;

  /// Total duration in seconds
  int get totalDuration =>
      lessons.fold(0, (sum, lesson) => sum + lesson.videoDuration);

  /// Format duration as "Xh Ym" or "Ym"
  String get formattedDuration {
    final minutes = totalDuration ~/ 60;
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours > 0) return '${hours}h ${remainingMinutes}m';
    return '${remainingMinutes}m';
  }

  /// Completed lessons count
  int get completedLessons =>
      lessons.where((lesson) => lesson.isCompleted).length;

  @override
  List<Object?> get props => [
        id,
        courseId,
        titleAr,
        titleEn,
        sortOrder,
        isPublished,
        lessons,
      ];
}
