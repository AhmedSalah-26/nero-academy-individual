import 'package:flutter/foundation.dart';
import 'package:lms_platform/features/student/course_player/domain/entities/section_entity.dart';
import 'lesson_model.dart';

/// Section Model - Data Model with JSON serialization
class SectionModel extends SectionEntity {
  const SectionModel({
    required super.id,
    required super.courseId,
    required super.titleAr,
    super.titleEn,
    super.descriptionAr,
    super.descriptionEn,
    super.sortOrder,
    super.isPublished,
    super.lessons,
    super.createdAt,
  });

  /// Create from JSON
  factory SectionModel.fromJson(Map<String, dynamic> json) {
    final lessonsJson = json['lessons'] as List<dynamic>?;

    // Debug logging
    debugPrint('🔍 [SectionModel] Parsing section: ${json['title_en']}');
    debugPrint(
        '🔍 [SectionModel] lessonsJson type: ${lessonsJson.runtimeType}');
    debugPrint('🔍 [SectionModel] lessonsJson length: ${lessonsJson?.length}');
    debugPrint('🔍 [SectionModel] lessonsJson content: $lessonsJson');

    final allLessons = lessonsJson?.map((e) {
          debugPrint('🔍 [SectionModel] Parsing lesson: $e');
          return LessonModel.fromJson(e as Map<String, dynamic>);
        }).toList() ??
        [];

    debugPrint('🔍 [SectionModel] Total lessons parsed: ${allLessons.length}');

    // Filter out unpublished lessons for student view
    final lessons = allLessons.where((lesson) {
      debugPrint(
          '🔍 [SectionModel] Lesson ${lesson.titleEn} isPublished: ${lesson.isPublished}');
      return lesson.isPublished;
    }).toList();

    debugPrint('🔍 [SectionModel] Published lessons: ${lessons.length}');

    return SectionModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      titleAr: json['title_ar'] as String,
      titleEn: json['title_en'] as String?,
      descriptionAr: json['description_ar'] as String?,
      descriptionEn: json['description_en'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isPublished: json['is_published'] as bool? ?? true,
      lessons: lessons,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'title_ar': titleAr,
      'title_en': titleEn,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'sort_order': sortOrder,
      'is_published': isPublished,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
