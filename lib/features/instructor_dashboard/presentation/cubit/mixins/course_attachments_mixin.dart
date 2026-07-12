import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/repositories/instructor_repository.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/cubit/course_editor_cubit.dart';

mixin CourseAttachmentsMixin on Cubit<CourseEditorState> {
  InstructorRepository get repository;

  /// Add attachment
  void addAttachment(CourseAttachmentData attachment) {
    final attachments = List<CourseAttachmentData>.from(state.attachments);
    attachments.add(attachment.copyWith(order: attachments.length));
    emit(state.copyWith(attachments: attachments));
  }

  /// Update attachment
  void updateAttachment(int index, CourseAttachmentData attachment) {
    final attachments = List<CourseAttachmentData>.from(state.attachments);
    attachments[index] = attachment;
    emit(state.copyWith(attachments: attachments));
  }

  /// Delete attachment
  void deleteAttachment(int index) {
    final attachments = List<CourseAttachmentData>.from(state.attachments);
    attachments.removeAt(index);
    for (int i = 0; i < attachments.length; i++) {
      attachments[i] = attachments[i].copyWith(order: i);
    }
    emit(state.copyWith(attachments: attachments));
  }

  /// Reorder attachments
  void reorderAttachments(int oldIndex, int newIndex) {
    final attachments = List<CourseAttachmentData>.from(state.attachments);
    if (newIndex > oldIndex) newIndex--;
    final item = attachments.removeAt(oldIndex);
    attachments.insert(newIndex, item);
    for (int i = 0; i < attachments.length; i++) {
      attachments[i] = attachments[i].copyWith(order: i);
    }
    emit(state.copyWith(attachments: attachments));
  }

  /// Save attachments to database
  Future<void> saveAttachments(
      String courseId, List<CourseAttachmentData> attachments) async {
    try {
      // Delete all existing attachments for this course
      await repository.deleteAllCourseAttachments(courseId);

      // Insert new attachments
      for (final attachment in attachments) {
        if (attachment.fileUrl == null) continue; // Skip if no URL

        await repository.addCourseAttachment(
          courseId: courseId,
          fileName: attachment.fileName,
          fileUrl: attachment.fileUrl!,
          fileType: attachment.fileType,
          fileSize: attachment.fileSize,
          sortOrder: attachment.order,
        );
      }
    } catch (e) {
      AppLogger.e('[CourseAttachmentsMixin] saveAttachments error: $e');
      rethrow;
    }
  }
}
