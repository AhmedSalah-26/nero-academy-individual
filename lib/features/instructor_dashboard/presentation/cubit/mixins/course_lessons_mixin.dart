import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/repositories/instructor_repository.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/cubit/course_editor_cubit.dart';

mixin CourseLessonsMixin on Cubit<CourseEditorState> {
  InstructorRepository get repository;

  /// Add lesson to section
  void addLesson(int sectionIndex, LessonData lesson) {
    // Only local
    final sections = List<SectionData>.from(state.sections);
    final lessons = List<LessonData>.from(sections[sectionIndex].lessons);
    lessons.add(lesson.copyWith(order: lessons.length));
    sections[sectionIndex] = sections[sectionIndex].copyWith(lessons: lessons);
    emit(state.copyWith(sections: sections));
  }

  /// Add lesson and save to database immediately
  Future<void> addLessonAndSave(int sectionIndex, LessonData lesson) async {
    final section = state.sections[sectionIndex];
    if (section.id == null || state.courseId == null) {
      addLesson(sectionIndex, lesson);
      return;
    }

    emit(state.copyWith(status: CourseEditorStatus.loading));
    try {
      final dto = LessonCreateDto(
        titleAr: lesson.titleAr,
        titleEn: lesson.titleEn,
        type: lesson.type,
        videoUrl: lesson.videoUrl,
        articleContentAr: lesson.articleContent,
        isPreview: lesson.isFree,
        isPublished: lesson.isPublished,
        availableFrom: lesson.availableFrom?.toUtc(),
        availableUntil: lesson.availableUntil?.toUtc(),
        videoDuration: lesson.durationMinutes * 60,
        fileUrl: lesson.fileUrl,
        fileName: lesson.fileName,
        fileSize: lesson.fileSize,
        fileType: lesson.fileType,
      );
      final lessonId =
          await repository.createLesson(section.id!, state.courseId!, dto);

      final sections = List<SectionData>.from(state.sections);
      final lessons = List<LessonData>.from(sections[sectionIndex].lessons);
      lessons.add(lesson.copyWith(id: lessonId, order: lessons.length));
      sections[sectionIndex] =
          sections[sectionIndex].copyWith(lessons: lessons);

      AppLogger.success('[CourseLessonsMixin] Lesson created: $lessonId');
      emit(state.copyWith(
          status: CourseEditorStatus.success, sections: sections));
    } catch (e) {
      AppLogger.e('[CourseLessonsMixin] addLessonAndSave error: $e');
      emit(state.copyWith(
          status: CourseEditorStatus.error, errorMessage: e.toString()));
    }
  }

  /// Update lesson
  void updateLesson(int sectionIndex, int lessonIndex, LessonData lesson) {
    final sections = List<SectionData>.from(state.sections);
    final lessons = List<LessonData>.from(sections[sectionIndex].lessons);
    lessons[lessonIndex] = lesson;
    sections[sectionIndex] = sections[sectionIndex].copyWith(lessons: lessons);
    emit(state.copyWith(sections: sections));
  }

  /// Update lesson and save to database immediately
  Future<void> updateLessonAndSave(
      int sectionIndex, int lessonIndex, LessonData lesson) async {
    final existingLesson = state.sections[sectionIndex].lessons[lessonIndex];
    if (existingLesson.id == null) {
      updateLesson(sectionIndex, lessonIndex, lesson);
      return;
    }

    emit(state.copyWith(status: CourseEditorStatus.loading));
    try {
      final dto = LessonUpdateDto(
        titleAr: lesson.titleAr,
        titleEn: lesson.titleEn,
        type: lesson.type,
        videoUrl: lesson.videoUrl,
        articleContentAr: lesson.articleContent,
        isPreview: lesson.isFree,
        isPublished: lesson.isPublished,
        availableFrom: lesson.availableFrom?.toUtc(),
        availableUntil: lesson.availableUntil?.toUtc(),
        clearAvailabilityWindow:
            lesson.availableFrom == null && lesson.availableUntil == null,
        videoDuration: lesson.durationMinutes * 60,
        fileUrl: lesson.fileUrl,
        fileName: lesson.fileName,
        fileSize: lesson.fileSize,
        fileType: lesson.fileType,
      );
      await repository.updateLesson(existingLesson.id!, dto);

      final sections = List<SectionData>.from(state.sections);
      final lessons = List<LessonData>.from(sections[sectionIndex].lessons);
      lessons[lessonIndex] = lesson;
      sections[sectionIndex] =
          sections[sectionIndex].copyWith(lessons: lessons);

      AppLogger.success(
          '[CourseLessonsMixin] Lesson updated: ${existingLesson.id}');
      emit(state.copyWith(
          status: CourseEditorStatus.success, sections: sections));
    } catch (e) {
      AppLogger.e('[CourseLessonsMixin] updateLessonAndSave error: $e');
      emit(state.copyWith(
          status: CourseEditorStatus.error, errorMessage: e.toString()));
    }
  }

  /// Delete lesson
  void deleteLesson(int sectionIndex, int lessonIndex) {
    final sections = List<SectionData>.from(state.sections);
    final lessons = List<LessonData>.from(sections[sectionIndex].lessons);
    lessons.removeAt(lessonIndex);
    for (int i = 0; i < lessons.length; i++) {
      lessons[i] = lessons[i].copyWith(order: i);
    }
    sections[sectionIndex] = sections[sectionIndex].copyWith(lessons: lessons);
    emit(state.copyWith(sections: sections));
  }

  /// Delete lesson from database immediately
  Future<void> deleteLessonAndSave(int sectionIndex, int lessonIndex) async {
    final lesson = state.sections[sectionIndex].lessons[lessonIndex];
    if (lesson.id == null) {
      deleteLesson(sectionIndex, lessonIndex);
      return;
    }

    emit(state.copyWith(status: CourseEditorStatus.loading));
    try {
      await repository.deleteLesson(lesson.id!);

      final sections = List<SectionData>.from(state.sections);
      final lessons = List<LessonData>.from(sections[sectionIndex].lessons);
      lessons.removeAt(lessonIndex);
      for (int i = 0; i < lessons.length; i++) {
        lessons[i] = lessons[i].copyWith(order: i);
      }
      sections[sectionIndex] =
          sections[sectionIndex].copyWith(lessons: lessons);

      AppLogger.success('[CourseLessonsMixin] Lesson deleted: ${lesson.id}');
      emit(state.copyWith(
          status: CourseEditorStatus.success, sections: sections));
    } catch (e) {
      AppLogger.e('[CourseLessonsMixin] deleteLessonAndSave error: $e');
      emit(state.copyWith(
          status: CourseEditorStatus.error, errorMessage: e.toString()));
    }
  }

  /// Reorder lessons within a section
  void reorderLessons(int sectionIndex, int oldIndex, int newIndex) {
    final sections = List<SectionData>.from(state.sections);
    final lessons = List<LessonData>.from(sections[sectionIndex].lessons);

    if (newIndex > oldIndex) newIndex--;
    final item = lessons.removeAt(oldIndex);
    lessons.insert(newIndex, item);

    for (int i = 0; i < lessons.length; i++) {
      lessons[i] = lessons[i].copyWith(order: i);
    }

    sections[sectionIndex] = sections[sectionIndex].copyWith(lessons: lessons);
    emit(state.copyWith(sections: sections));

    saveLessonOrder(sectionIndex, lessons);
  }

  /// Reorder lessons within a section and save
  Future<void> reorderLessonsAndSave(
      int sectionIndex, int oldIndex, int newIndex) async {
    // This method seems redundant if reorderLessons calls saveLessonOrder, but
    // sometimes we want to await the save.
    // The original code has reorderLessons (sync updates state, calls async save)
    // and reorderLessonsAndSave (async updates state and awaits save).
    // Let's implement fully.

    final sections = List<SectionData>.from(state.sections);
    final lessons = List<LessonData>.from(sections[sectionIndex].lessons);

    if (newIndex > oldIndex) newIndex--;
    final item = lessons.removeAt(oldIndex);
    lessons.insert(newIndex, item);

    for (int i = 0; i < lessons.length; i++) {
      lessons[i] = lessons[i].copyWith(order: i);
    }
    sections[sectionIndex] = sections[sectionIndex].copyWith(lessons: lessons);
    emit(state.copyWith(sections: sections));

    final section = state.sections[sectionIndex];
    if (section.id != null) {
      try {
        final lessonIds =
            lessons.where((l) => l.id != null).map((l) => l.id!).toList();
        if (lessonIds.isNotEmpty) {
          await repository.reorderLessons(section.id!, lessonIds);
          AppLogger.success('[CourseLessonsMixin] Lessons reordered');
        }
      } catch (e) {
        AppLogger.e('[CourseLessonsMixin] reorderLessonsAndSave error: $e');
      }
    }
  }

  /// Save lesson order to database
  Future<void> saveLessonOrder(
      int sectionIndex, List<LessonData> lessons) async {
    if (state.courseId == null) return;

    // We need to access the section from state carefully, or use the passed lessons list
    // The sectionIndex might be invalid if sections changed rapidly, but typically safe here.
    if (sectionIndex >= state.sections.length) return;

    final section = state.sections[sectionIndex];
    if (section.id == null) return;

    try {
      final lessonIds =
          lessons.where((l) => l.id != null).map((l) => l.id!).toList();
      if (lessonIds.isNotEmpty) {
        await repository.reorderLessons(section.id!, lessonIds);
        AppLogger.success('[CourseLessonsMixin] Lessons reordered');
      }
    } catch (e) {
      AppLogger.e('[CourseLessonsMixin] saveLessonOrder error: $e');
    }
  }
}
