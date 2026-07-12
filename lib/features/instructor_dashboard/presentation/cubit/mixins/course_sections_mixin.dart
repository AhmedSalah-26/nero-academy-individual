import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/repositories/instructor_repository.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/cubit/course_editor_cubit.dart';

mixin CourseSectionsMixin on Cubit<CourseEditorState> {
  InstructorRepository get repository;

  /// Add section
  void addSection(String titleAr, String titleEn) {
    // Only local update
    final newSection = SectionData(
      titleAr: titleAr,
      titleEn: titleEn,
      order: state.sections.length,
    );
    emit(state.copyWith(sections: [...state.sections, newSection]));
  }

  /// Add section and save to database immediately
  Future<void> addSectionAndSave(String titleAr, String titleEn) async {
    if (state.courseId == null) {
      addSection(titleAr, titleEn);
      return;
    }

    emit(state.copyWith(status: CourseEditorStatus.loading));
    try {
      final dto = SectionCreateDto(titleAr: titleAr, titleEn: titleEn);
      final sectionId = await repository.createSection(state.courseId!, dto);

      final newSection = SectionData(
        id: sectionId,
        titleAr: titleAr,
        titleEn: titleEn,
        order: state.sections.length,
      );

      AppLogger.success('[CourseSectionsMixin] Section created: $sectionId');
      emit(state.copyWith(
        status: CourseEditorStatus.success,
        sections: [...state.sections, newSection],
      ));
    } catch (e) {
      AppLogger.e('[CourseSectionsMixin] addSectionAndSave error: $e');
      emit(state.copyWith(
          status: CourseEditorStatus.error, errorMessage: e.toString()));
    }
  }

  /// Update section
  void updateSection(int index, String titleAr, String titleEn,
      {bool? isPublished}) {
    final sections = List<SectionData>.from(state.sections);
    sections[index] = sections[index].copyWith(
      titleAr: titleAr,
      titleEn: titleEn,
      isPublished: isPublished,
    );
    emit(state.copyWith(sections: sections));
  }

  /// Update section and save to database immediately
  Future<void> updateSectionAndSave(
      int index, String titleAr, String titleEn) async {
    final section = state.sections[index];
    if (section.id == null) {
      updateSection(index, titleAr, titleEn);
      return;
    }

    emit(state.copyWith(status: CourseEditorStatus.loading));
    try {
      final updateDto = SectionUpdateDto(
        titleAr: titleAr,
        titleEn: titleEn,
        isPublished: section.isPublished,
      );
      await repository.updateSection(section.id!, updateDto);

      final sections = List<SectionData>.from(state.sections);
      sections[index] =
          sections[index].copyWith(titleAr: titleAr, titleEn: titleEn);

      AppLogger.success('[CourseSectionsMixin] Section updated: ${section.id}');
      emit(state.copyWith(
          status: CourseEditorStatus.success, sections: sections));
    } catch (e) {
      AppLogger.e('[CourseSectionsMixin] updateSectionAndSave error: $e');
      emit(state.copyWith(
          status: CourseEditorStatus.error, errorMessage: e.toString()));
    }
  }

  /// Delete section
  void deleteSection(int index) {
    final sections = List<SectionData>.from(state.sections);
    sections.removeAt(index);
    for (int i = 0; i < sections.length; i++) {
      sections[i] = sections[i].copyWith(order: i);
    }
    emit(state.copyWith(sections: sections));
  }

  /// Delete section from database immediately
  Future<void> deleteSectionAndSave(int index) async {
    final section = state.sections[index];
    if (section.id == null) {
      deleteSection(index);
      return;
    }

    emit(state.copyWith(status: CourseEditorStatus.loading));
    try {
      await repository.deleteSection(section.id!);

      final sections = List<SectionData>.from(state.sections);
      sections.removeAt(index);
      for (int i = 0; i < sections.length; i++) {
        sections[i] = sections[i].copyWith(order: i);
      }

      AppLogger.success('[CourseSectionsMixin] Section deleted: ${section.id}');
      emit(state.copyWith(
          status: CourseEditorStatus.success, sections: sections));
    } catch (e) {
      AppLogger.e('[CourseSectionsMixin] deleteSectionAndSave error: $e');
      emit(state.copyWith(
          status: CourseEditorStatus.error, errorMessage: e.toString()));
    }
  }

  /// Reorder sections
  void reorderSections(int oldIndex, int newIndex) {
    final sections = List<SectionData>.from(state.sections);
    if (newIndex > oldIndex) newIndex--;
    final item = sections.removeAt(oldIndex);
    sections.insert(newIndex, item);
    for (int i = 0; i < sections.length; i++) {
      sections[i] = sections[i].copyWith(order: i);
    }
    emit(state.copyWith(sections: sections));
  }

  /// Reorder sections and save to database
  Future<void> reorderSectionsAndSave(int oldIndex, int newIndex) async {
    // 1. Build the reordered list locally
    final sections = List<SectionData>.from(state.sections);
    if (newIndex > oldIndex) newIndex--;
    final item = sections.removeAt(oldIndex);
    sections.insert(newIndex, item);
    for (int i = 0; i < sections.length; i++) {
      sections[i] = sections[i].copyWith(order: i);
    }

    // 2. Update UI immediately (optimistic update)
    emit(state.copyWith(sections: sections));

    // 3. Persist to database using the locally computed list
    if (state.courseId != null) {
      try {
        final sectionIds =
            sections.where((s) => s.id != null).map((s) => s.id!).toList();
        if (sectionIds.isNotEmpty) {
          await repository.reorderSections(state.courseId!, sectionIds);
          AppLogger.success('[CourseSectionsMixin] Sections reordered & saved');
        }
      } catch (e) {
        AppLogger.e('[CourseSectionsMixin] reorderSectionsAndSave error: $e');
      }
    }
  }
}
