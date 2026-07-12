import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/repositories/instructor_repository.dart';

part 'instructor_announcements_state.dart';

/// Instructor Announcements Cubit
class InstructorAnnouncementsCubit extends Cubit<InstructorAnnouncementsState> {
  final InstructorRepository _repository;

  InstructorAnnouncementsCubit(this._repository)
      : super(const InstructorAnnouncementsState());

  /// Load courses for the announcements dropdown
  Future<void> loadCourses() async {
    try {
      final courses = await _repository.getAnnouncementCourses();
      emit(state.copyWith(courses: courses));
    } catch (e) {
      emit(state.copyWith(
          status: InstructorAnnouncementsStatus.error,
          errorMessage: e.toString()));
    }
  }

  /// Load announcements for a specific course
  Future<void> loadAnnouncements(String courseId,
      {bool refresh = false}) async {
    if (refresh) {
      emit(state.copyWith(
        status: InstructorAnnouncementsStatus.loading,
        announcements: [],
        selectedCourseId: courseId,
        currentPage: 1,
        hasMore: true,
      ));
    } else {
      emit(state.copyWith(
        status: InstructorAnnouncementsStatus.loading,
        selectedCourseId: courseId,
      ));
    }

    try {
      final announcements = await _repository.getAnnouncements(
        courseId: courseId,
        page: 1,
      );
      emit(state.copyWith(
        status: InstructorAnnouncementsStatus.success,
        announcements: announcements,
        currentPage: 1,
        hasMore: announcements.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
          status: InstructorAnnouncementsStatus.error,
          errorMessage: e.toString()));
    }
  }

  /// Load more announcements
  Future<void> loadMoreAnnouncements() async {
    if (!state.hasMore ||
        state.status == InstructorAnnouncementsStatus.loadingMore ||
        state.selectedCourseId == null) {
      return;
    }
    emit(state.copyWith(status: InstructorAnnouncementsStatus.loadingMore));

    try {
      final nextPage = state.currentPage + 1;
      final announcements = await _repository.getAnnouncements(
        courseId: state.selectedCourseId!,
        page: nextPage,
      );
      emit(state.copyWith(
        status: InstructorAnnouncementsStatus.success,
        announcements: [...state.announcements, ...announcements],
        currentPage: nextPage,
        hasMore: announcements.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
          status: InstructorAnnouncementsStatus.error,
          errorMessage: e.toString()));
    }
  }

  /// Create announcement
  Future<void> createAnnouncement({
    required String courseId,
    required String titleAr,
    String? titleEn,
    String? contentAr,
    String? contentEn,
  }) async {
    emit(state.copyWith(actionStatus: InstructorAnnouncementsStatus.loading));
    try {
      await _repository.createAnnouncement(
        courseId: courseId,
        titleAr: titleAr,
        titleEn: titleEn,
        contentAr: contentAr,
        contentEn: contentEn,
      );
      emit(state.copyWith(actionStatus: InstructorAnnouncementsStatus.success));
      // Reload announcements for the current course
      if (state.selectedCourseId != null) {
        await loadAnnouncements(state.selectedCourseId!, refresh: true);
      }
    } catch (e) {
      emit(state.copyWith(
          actionStatus: InstructorAnnouncementsStatus.error,
          errorMessage: e.toString()));
    }
  }

  /// Update announcement
  Future<void> updateAnnouncement(
      String announcementId, Map<String, dynamic> data) async {
    emit(state.copyWith(actionStatus: InstructorAnnouncementsStatus.loading));
    try {
      await _repository.updateAnnouncement(announcementId, data);
      emit(state.copyWith(actionStatus: InstructorAnnouncementsStatus.success));
      if (state.selectedCourseId != null) {
        await loadAnnouncements(state.selectedCourseId!, refresh: true);
      }
    } catch (e) {
      emit(state.copyWith(
          actionStatus: InstructorAnnouncementsStatus.error,
          errorMessage: e.toString()));
    }
  }

  /// Delete announcement
  Future<void> deleteAnnouncement(String announcementId) async {
    emit(state.copyWith(actionStatus: InstructorAnnouncementsStatus.loading));
    try {
      await _repository.deleteAnnouncement(announcementId);
      final updated =
          state.announcements.where((a) => a['id'] != announcementId).toList();
      emit(state.copyWith(
        actionStatus: InstructorAnnouncementsStatus.success,
        announcements: updated,
      ));
    } catch (e) {
      emit(state.copyWith(
          actionStatus: InstructorAnnouncementsStatus.error,
          errorMessage: e.toString()));
    }
  }
}
