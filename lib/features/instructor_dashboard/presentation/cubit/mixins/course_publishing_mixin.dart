import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/services/app_logger.dart';
import '../../../domain/repositories/instructor_repository.dart';
import '../course_editor_cubit.dart';
import 'course_attachments_mixin.dart';

mixin CoursePublishingMixin
    on Cubit<CourseEditorState>, CourseAttachmentsMixin {
  @override
  InstructorRepository get repository;

  /// Save course as draft
  Future<bool> saveDraft() async {
    AppLogger.i('[CoursePublishingMixin] saveDraft called');
    AppLogger.i(
        '[CoursePublishingMixin] isEditing=${state.isEditing}, courseId=${state.courseId}');
    emit(state.copyWith(status: CourseEditorStatus.loading));
    try {
      if (!state.hasValidAvailabilityWindow) {
        throw Exception('Invalid availability window');
      }
      if (state.sections
          .expand((section) => section.lessons)
          .any((lesson) => !lesson.hasValidAvailabilityWindow)) {
        throw Exception('Invalid lesson availability window');
      }
      String courseId;

      // Flash sale uses discount value as timed sale price.
      final hasValidFlashSaleWindow = state.flashSaleStart != null &&
          state.flashSaleEnd != null &&
          state.flashSaleEnd!.isAfter(state.flashSaleStart!);
      final hasValidFlashSalePrice = state.discountPrice != null &&
          state.discountPrice! > 0 &&
          state.discountPrice! < state.price;
      final isFlashSale = state.isFlashSale &&
          hasValidFlashSaleWindow &&
          hasValidFlashSalePrice;
      final normalizedDiscountPrice = state.discountPrice;
      final normalizedFlashSaleStart =
          isFlashSale ? state.flashSaleStart?.toUtc() : null;
      final normalizedFlashSaleEnd =
          isFlashSale ? state.flashSaleEnd?.toUtc() : null;

      final dto = CourseCreateDto(
        titleAr: state.titleAr,
        titleEn: state.titleEn,
        subtitleAr: state.subtitleAr.isNotEmpty ? state.subtitleAr : null,
        subtitleEn: state.subtitleEn.isNotEmpty ? state.subtitleEn : null,
        descriptionAr:
            state.descriptionAr.isNotEmpty ? state.descriptionAr : null,
        descriptionEn:
            state.descriptionEn.isNotEmpty ? state.descriptionEn : null,
        thumbnailUrl: state.thumbnailUrl,
        previewVideoUrl: state.previewVideoUrl,
        categoryId: state.categoryId,
        level: state.level,
        price: state.price,
        discountPrice: normalizedDiscountPrice,
        currency: state.currency,
        isPublished: false,
        badge: state.badge,
        isFlashSale: isFlashSale,
        flashSaleStart: normalizedFlashSaleStart,
        flashSaleEnd: normalizedFlashSaleEnd,
        availableFrom: state.availableFrom?.toUtc(),
        availableUntil: state.availableUntil?.toUtc(),
      );

      if (state.isEditing && state.courseId != null) {
        // Update existing course
        AppLogger.i(
            '[CoursePublishingMixin] Updating existing course: ${state.courseId}');
        await repository.updateCourse(
          state.courseId!,
          CourseUpdateDto(
            titleAr: dto.titleAr,
            titleEn: dto.titleEn,
            subtitleAr: dto.subtitleAr,
            subtitleEn: dto.subtitleEn,
            descriptionAr: dto.descriptionAr,
            descriptionEn: dto.descriptionEn,
            thumbnailUrl: dto.thumbnailUrl,
            previewVideoUrl: dto.previewVideoUrl,
            categoryId: dto.categoryId,
            level: dto.level,
            price: dto.price,
            discountPrice: dto.discountPrice,
            clearDiscountPrice: dto.discountPrice == null,
            currency: dto.currency,
            badge: dto.badge,
            clearBadge: dto.badge == null || dto.badge!.trim().isEmpty,
            isFlashSale: dto.isFlashSale,
            flashSaleStart: dto.flashSaleStart,
            flashSaleEnd: dto.flashSaleEnd,
            clearFlashSaleData: !dto.isFlashSale,
            availableFrom: dto.availableFrom,
            availableUntil: dto.availableUntil,
            clearAvailabilityWindow:
                dto.availableFrom == null && dto.availableUntil == null,
          ),
        );
        courseId = state.courseId!;
      } else {
        AppLogger.i('[CoursePublishingMixin] Creating new course');
        courseId = await repository.createCourse(dto);
        AppLogger.i(
            '[CoursePublishingMixin] Course created with ID: $courseId');
        emit(state.copyWith(courseId: courseId, isEditing: true));
      }

      // Save sections and lessons
      final sections = state.sections.map((s) {
        return SectionDto(
          id: s.id,
          titleAr: s.titleAr,
          titleEn: s.titleEn,
          order: s.order,
          isPublished: s.isPublished,
          lessons: s.lessons.map((l) {
            return LessonDto(
              id: l.id,
              titleAr: l.titleAr,
              titleEn: l.titleEn,
              type: l.type,
              order: l.order,
              durationMinutes: l.durationMinutes,
              isFree: l.isFree,
              isPublished: l.isPublished,
              availableFrom: l.availableFrom?.toUtc(),
              availableUntil: l.availableUntil?.toUtc(),
              videoUrl: l.videoUrl,
              articleContent: l.articleContent,
              fileUrl: l.fileUrl,
              fileName: l.fileName,
              fileSize: l.fileSize,
              fileType: l.fileType,
            );
          }).toList(),
        );
      }).toList();

      AppLogger.i('[CoursePublishingMixin] Saving ${sections.length} sections');
      await repository.saveSectionsAndLessons(courseId, sections);

      // Save attachments using the mixin method
      if (state.attachments.isNotEmpty) {
        AppLogger.i(
            '[CoursePublishingMixin] Saving ${state.attachments.length} attachments');
        await saveAttachments(courseId, state.attachments);
      }

      AppLogger.success('[CoursePublishingMixin] Draft saved successfully');
      emit(state.copyWith(status: CourseEditorStatus.success));
      return true;
    } catch (e) {
      AppLogger.e('[CoursePublishingMixin] saveDraft error: $e');
      emit(state.copyWith(
          status: CourseEditorStatus.error, errorMessage: e.toString()));
      return false;
    }
  }

  /// Publish course
  Future<bool> publishCourse() async {
    AppLogger.i('[CoursePublishingMixin] publishCourse called');

    if (!state.canPublish) {
      AppLogger.w('[CoursePublishingMixin] Cannot publish - validation failed');
      return false;
    }

    emit(state.copyWith(status: CourseEditorStatus.loading));
    try {
      // Save first
      final draftSaved = await saveDraft();
      if (!draftSaved) {
        AppLogger.e(
            '[CoursePublishingMixin] Failed to save draft before publish');
        return false;
      }

      // Update status to published
      await repository.updateCourse(
        state.courseId!,
        const CourseUpdateDto(isPublished: true),
      );

      AppLogger.success(
          '[CoursePublishingMixin] Course published successfully');
      emit(state.copyWith(status: CourseEditorStatus.success));
      return true;
    } catch (e) {
      AppLogger.e('[CoursePublishingMixin] publishCourse error: $e');
      emit(state.copyWith(
          status: CourseEditorStatus.error, errorMessage: e.toString()));
      return false;
    }
  }

  /// Save Basic Info only (for separate editing)
  Future<bool> saveBasicInfoOnly() async {
    AppLogger.i('[CoursePublishingMixin] saveBasicInfoOnly called');
    if (!state.isEditing || state.courseId == null) return false;
    emit(state.copyWith(status: CourseEditorStatus.loading));
    try {
      if (!state.hasValidAvailabilityWindow) {
        throw Exception('Invalid availability window');
      }
      await repository.updateCourse(
        state.courseId!,
        CourseUpdateDto(
          titleAr: state.titleAr,
          titleEn: state.titleEn,
          subtitleAr: state.subtitleAr.isNotEmpty ? state.subtitleAr : null,
          subtitleEn: state.subtitleEn.isNotEmpty ? state.subtitleEn : null,
          descriptionAr:
              state.descriptionAr.isNotEmpty ? state.descriptionAr : null,
          descriptionEn:
              state.descriptionEn.isNotEmpty ? state.descriptionEn : null,
          thumbnailUrl: state.thumbnailUrl,
          previewVideoUrl: state.previewVideoUrl,
          categoryId: state.categoryId,
          level: state.level,
        ),
      );
      emit(state.copyWith(status: CourseEditorStatus.success));
      return true;
    } catch (e) {
      AppLogger.e('[CoursePublishingMixin] saveBasicInfoOnly error: $e');
      emit(state.copyWith(
          status: CourseEditorStatus.error, errorMessage: e.toString()));
      return false;
    }
  }

  /// Save Curriculum only (for separate editing)
  Future<bool> saveCurriculumOnly() async {
    AppLogger.i('[CoursePublishingMixin] saveCurriculumOnly called');
    if (!state.isEditing || state.courseId == null) return false;
    emit(state.copyWith(status: CourseEditorStatus.loading));
    try {
      if (state.sections
          .expand((section) => section.lessons)
          .any((lesson) => !lesson.hasValidAvailabilityWindow)) {
        throw Exception('Invalid lesson availability window');
      }
      final sections = state.sections.map((s) {
        return SectionDto(
          id: s.id,
          titleAr: s.titleAr,
          titleEn: s.titleEn,
          order: s.order,
          isPublished: s.isPublished,
          lessons: s.lessons.map((l) {
            return LessonDto(
              id: l.id,
              titleAr: l.titleAr,
              titleEn: l.titleEn,
              type: l.type,
              order: l.order,
              durationMinutes: l.durationMinutes,
              isFree: l.isFree,
              isPublished: l.isPublished,
              availableFrom: l.availableFrom?.toUtc(),
              availableUntil: l.availableUntil?.toUtc(),
              videoUrl: l.videoUrl,
              articleContent: l.articleContent,
              fileUrl: l.fileUrl,
              fileName: l.fileName,
              fileSize: l.fileSize,
              fileType: l.fileType,
            );
          }).toList(),
        );
      }).toList();
      await repository.saveSectionsAndLessons(state.courseId!, sections);
      emit(state.copyWith(status: CourseEditorStatus.success));
      return true;
    } catch (e) {
      AppLogger.e('[CoursePublishingMixin] saveCurriculumOnly error: $e');
      emit(state.copyWith(
          status: CourseEditorStatus.error, errorMessage: e.toString()));
      return false;
    }
  }

  /// Save Pricing only (for separate editing)
  Future<bool> savePricingOnly() async {
    AppLogger.i('[CoursePublishingMixin] savePricingOnly called');
    if (!state.isEditing || state.courseId == null) return false;
    emit(state.copyWith(status: CourseEditorStatus.loading));
    try {
      final hasValidFlashSaleWindow = state.flashSaleStart != null &&
          state.flashSaleEnd != null &&
          state.flashSaleEnd!.isAfter(state.flashSaleStart!);
      final hasValidFlashSalePrice = state.discountPrice != null &&
          state.discountPrice! > 0 &&
          state.discountPrice! < state.price;
      final isFlashSale = state.isFlashSale &&
          hasValidFlashSaleWindow &&
          hasValidFlashSalePrice;

      await repository.updateCourse(
        state.courseId!,
        CourseUpdateDto(
          price: state.price,
          discountPrice: state.discountPrice,
          clearDiscountPrice: state.discountPrice == null,
          currency: state.currency,
          isFlashSale: isFlashSale,
          flashSaleStart: isFlashSale ? state.flashSaleStart?.toUtc() : null,
          flashSaleEnd: isFlashSale ? state.flashSaleEnd?.toUtc() : null,
          clearFlashSaleData: !isFlashSale,
        ),
      );
      emit(state.copyWith(status: CourseEditorStatus.success));
      return true;
    } catch (e) {
      AppLogger.e('[CoursePublishingMixin] savePricingOnly error: $e');
      emit(state.copyWith(
          status: CourseEditorStatus.error, errorMessage: e.toString()));
      return false;
    }
  }

  /// Save Settings only (for separate editing)
  Future<bool> saveSettingsOnly() async {
    AppLogger.i('[CoursePublishingMixin] saveSettingsOnly called');
    if (!state.isEditing || state.courseId == null) return false;
    emit(state.copyWith(status: CourseEditorStatus.loading));
    try {
      await repository.updateCourse(
        state.courseId!,
        CourseUpdateDto(
          badge: state.badge,
          clearBadge: state.badge == null || state.badge!.trim().isEmpty,
          availableFrom: state.availableFrom?.toUtc(),
          availableUntil: state.availableUntil?.toUtc(),
          clearAvailabilityWindow:
              state.availableFrom == null && state.availableUntil == null,
        ),
      );
      emit(state.copyWith(status: CourseEditorStatus.success));
      return true;
    } catch (e) {
      AppLogger.e('[CoursePublishingMixin] saveSettingsOnly error: $e');
      emit(state.copyWith(
          status: CourseEditorStatus.error, errorMessage: e.toString()));
      return false;
    }
  }

  /// Save Attachments only (for separate editing)
  Future<bool> saveAttachmentsOnly() async {
    AppLogger.i('[CoursePublishingMixin] saveAttachmentsOnly called');
    if (!state.isEditing || state.courseId == null) return false;
    emit(state.copyWith(status: CourseEditorStatus.loading));
    try {
      await saveAttachments(state.courseId!, state.attachments);
      emit(state.copyWith(status: CourseEditorStatus.success));
      return true;
    } catch (e) {
      AppLogger.e('[CoursePublishingMixin] saveAttachmentsOnly error: $e');
      emit(state.copyWith(
          status: CourseEditorStatus.error, errorMessage: e.toString()));
      return false;
    }
  }
}
