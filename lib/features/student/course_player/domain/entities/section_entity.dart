import 'package:equatable/equatable.dart';
import 'lesson_entity.dart';

/// Section Entity - Pure Dart Object
class SectionEntity extends Equatable {
  final String id;
  final String courseId;
  final String titleAr;
  final String? titleEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final int sortOrder;
  final bool isPublished;
  final List<LessonEntity> lessons;
  final DateTime? createdAt;

  const SectionEntity({
    required this.id,
    required this.courseId,
    required this.titleAr,
    this.titleEn,
    this.descriptionAr,
    this.descriptionEn,
    this.sortOrder = 0,
    this.isPublished = true,
    this.lessons = const [],
    this.createdAt,
  });

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

  /// Get total lessons count
  int get totalLessons => lessons.length;

  /// Get total duration in seconds
  int get totalDuration {
    return lessons.fold(0, (sum, lesson) => sum + (lesson.videoDuration ?? 0));
  }

  /// Get formatted total duration (e.g., "1h 30m")
  String get formattedDuration {
    final totalMinutes = totalDuration ~/ 60;
    if (totalMinutes < 60) {
      return '$totalMinutes min';
    }
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (minutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${minutes}m';
  }

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
