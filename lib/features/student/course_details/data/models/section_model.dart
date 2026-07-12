import 'package:lms_platform/features/student/course_details/domain/entities/section_entity.dart';
import 'lesson_model.dart';

/// Section Model - Data Model with JSON serialization
class SectionModel extends SectionEntity {
  const SectionModel({
    required super.id,
    required super.courseId,
    super.titleAr,
    super.titleEn,
    super.descriptionAr,
    super.descriptionEn,
    super.sortOrder,
    super.isPublished,
    super.lessons,
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    // Parse nested lessons
    List<LessonModel> allLessons = [];
    if (json['lessons'] != null) {
      allLessons = (json['lessons'] as List)
          .map((e) => LessonModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Keep all lessons in course details and sort by order.
    // Access control is handled at UI/action level (preview/lock).
    final lessons = allLessons.toList();
    lessons.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return SectionModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      titleAr: json['title_ar'] as String?,
      titleEn: json['title_en'] as String?,
      descriptionAr: json['description_ar'] as String?,
      descriptionEn: json['description_en'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isPublished: json['is_published'] as bool? ?? true,
      lessons: lessons,
    );
  }

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
    };
  }
}
