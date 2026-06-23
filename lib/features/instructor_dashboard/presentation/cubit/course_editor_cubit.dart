import 'package:equatable/equatable.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/app_logger.dart';
import '../../domain/repositories/instructor_repository.dart';

import 'mixins/course_sections_mixin.dart';
import 'mixins/course_lessons_mixin.dart';
import 'mixins/course_attachments_mixin.dart';
import 'mixins/course_publishing_mixin.dart';

part 'course_editor_state.dart';

/// Course Editor Cubit
class CourseEditorCubit extends Cubit<CourseEditorState>
    with
        CourseSectionsMixin,
        CourseLessonsMixin,
        CourseAttachmentsMixin,
        CoursePublishingMixin {
  @override
  final InstructorRepository repository;

  CourseEditorCubit(this.repository) : super(const CourseEditorState()) {
    AppLogger.i('📝 [CourseEditorCubit] Created');
  }

  /// Initialize for new course
  Future<void> initNewCourse() async {
    AppLogger.i('📝 [CourseEditorCubit] initNewCourse called');
    emit(state.copyWith(status: CourseEditorStatus.loading));
    try {
      await _loadCategories();
      AppLogger.success('[CourseEditorCubit] New course initialized');
      emit(state.copyWith(
        status: CourseEditorStatus.success,
        isEditing: false,
      ));
    } catch (e) {
      AppLogger.e('[CourseEditorCubit] initNewCourse error: $e');
      emit(state.copyWith(
        status: CourseEditorStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Initialize for editing existing course
  Future<void> initEditCourse(String courseId) async {
    AppLogger.i('📝 [CourseEditorCubit] initEditCourse called: $courseId');
    emit(state.copyWith(status: CourseEditorStatus.loading));
    try {
      await _loadCategories();
      await _loadCourse(courseId);
      AppLogger.success('[CourseEditorCubit] Course loaded for editing');
      emit(state.copyWith(
        status: CourseEditorStatus.success,
        isEditing: true,
        courseId: courseId,
      ));
    } catch (e) {
      AppLogger.e('[CourseEditorCubit] initEditCourse error: $e');
      emit(state.copyWith(
        status: CourseEditorStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _loadCategories() async {
    AppLogger.i('📝 [CourseEditorCubit] Loading categories...');
    final categories = await repository.getCategories();
    AppLogger.i(
        '📝 [CourseEditorCubit] Loaded ${categories.length} categories');
    emit(state.copyWith(categories: categories));
  }

  Future<void> _loadCourse(String courseId) async {
    final course = await repository.getCourseForEdit(courseId);
    if (course == null) {
      throw Exception('Course not found');
    }

    AppLogger.i(
        '📝 [CourseEditorCubit] _loadCourse: isPublished=${course.isPublished}');

    final sections = course.sections.map((s) {
      final lessons = s.lessons.map((l) {
        return LessonData(
          id: l.id,
          titleAr: l.titleAr,
          titleEn: l.titleEn,
          type: l.type,
          order: l.order,
          durationMinutes: l.durationMinutes,
          isFree: l.isFree,
          isPublished: l.isPublished,
          videoUrl: l.videoUrl,
          articleContent: l.articleContent,
          fileUrl: l.fileUrl,
          fileName: l.fileName,
          fileSize: l.fileSize,
          fileType: l.fileType,
          availableFrom: l.availableFrom,
          availableUntil: l.availableUntil,
        );
      }).toList();

      return SectionData(
        id: s.id,
        titleAr: s.titleAr,
        titleEn: s.titleEn,
        order: s.order,
        isPublished: s.isPublished,
        lessons: lessons,
      );
    }).toList();

    // Load attachments
    AppLogger.i(
        '📎 [CourseEditorCubit] Loading attachments for course: $courseId');
    final attachmentDtos = await repository.getCourseAttachments(courseId);
    final attachments = attachmentDtos.map((a) {
      return CourseAttachmentData(
        id: a.id,
        fileName: a.fileName,
        fileUrl: a.fileUrl,
        fileType: a.fileType,
        fileSize: a.fileSize,
        order: a.sortOrder,
      );
    }).toList();
    AppLogger.success(
        '📎 [CourseEditorCubit] Loaded ${attachments.length} attachments');

    emit(state.copyWith(
      titleAr: course.titleAr,
      titleEn: course.titleEn,
      subtitleAr: course.subtitleAr ?? '',
      subtitleEn: course.subtitleEn ?? '',
      descriptionAr: course.descriptionAr ?? '',
      descriptionEn: course.descriptionEn ?? '',
      thumbnailUrl: course.thumbnailUrl,
      previewVideoUrl: course.previewVideoUrl,
      categoryId: course.categoryId,
      level: course.level,
      price: course.price,
      discountPrice: course.discountPrice,
      currency: course.currency,
      sections: sections,
      attachments: attachments,
      isOriginalPublished: course.isPublished,
      badge: course.badge,
      isFlashSale: course.isFlashSale,
      flashSaleStart: course.flashSaleStart,
      flashSaleEnd: course.flashSaleEnd,
      availableFrom: course.availableFrom,
      availableUntil: course.availableUntil,
    ));
  }

  /// Set current step
  void setStep(int step) {
    emit(state.copyWith(currentStep: step));
  }

  /// Update basic info
  void updateBasicInfo({
    String? titleAr,
    String? titleEn,
    String? subtitleAr,
    String? subtitleEn,
    String? descriptionAr,
    String? descriptionEn,
    String? thumbnailUrl,
    String? previewVideoUrl,
    String? categoryId,
    String? level,
  }) {
    emit(state.copyWith(
      titleAr: titleAr,
      titleEn: titleEn,
      subtitleAr: subtitleAr,
      subtitleEn: subtitleEn,
      descriptionAr: descriptionAr,
      descriptionEn: descriptionEn,
      thumbnailUrl: thumbnailUrl,
      previewVideoUrl: previewVideoUrl,
      categoryId: categoryId,
      level: level,
    ));
  }

  /// Update pricing
  void updatePricing({
    double? price,
    double? discountPrice,
    bool clearDiscountPrice = false,
    String? currency,
    String? badge,
    bool clearBadge = false,
    bool? isFlashSale,
    DateTime? flashSaleStart,
    bool clearFlashSaleStart = false,
    DateTime? flashSaleEnd,
    bool clearFlashSaleEnd = false,
  }) {
    emit(state.copyWith(
      price: price,
      discountPrice: discountPrice,
      clearDiscountPrice: clearDiscountPrice,
      currency: currency,
      badge: badge,
      clearBadge: clearBadge,
      isFlashSale: isFlashSale,
      flashSaleStart: flashSaleStart,
      clearFlashSaleStart: clearFlashSaleStart,
      flashSaleEnd: flashSaleEnd,
      clearFlashSaleEnd: clearFlashSaleEnd,
    ));
  }

  void updateAvailabilitySchedule({
    DateTime? availableFrom,
    bool clearAvailableFrom = false,
    DateTime? availableUntil,
    bool clearAvailableUntil = false,
  }) {
    emit(state.copyWith(
      availableFrom: availableFrom,
      clearAvailableFrom: clearAvailableFrom,
      availableUntil: availableUntil,
      clearAvailableUntil: clearAvailableUntil,
    ));
  }
}
