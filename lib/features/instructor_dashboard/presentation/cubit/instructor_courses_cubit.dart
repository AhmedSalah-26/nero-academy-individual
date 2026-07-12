import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/entities/instructor_entities.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/repositories/instructor_repository.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/instructor_course_model.dart';

part 'instructor_courses_state.dart';

/// Instructor Courses Cubit
class InstructorCoursesCubit extends Cubit<InstructorCoursesState> {
  final InstructorRepository _repository;
  static const _tag = 'InstructorCoursesCubit';

  InstructorCoursesCubit(this._repository)
      : super(const InstructorCoursesState());

  /// Load courses
  Future<void> loadCourses(
      {InstructorCourseStatus? status, bool refresh = false}) async {
    AppLogger.d('[$_tag] loadCourses: status=$status, refresh=$refresh');

    if (refresh) {
      emit(state.copyWith(
          status: InstructorCoursesStatus.loading,
          courses: [],
          currentPage: 1,
          hasMore: true));
    } else {
      emit(state.copyWith(status: InstructorCoursesStatus.loading));
    }

    try {
      final courses = await _repository.getMyCourses(status: status, page: 1);
      AppLogger.d('[$_tag] loadCourses: Received ${courses.length} courses');

      if (courses.isEmpty) {
        AppLogger.w('[$_tag] loadCourses: No courses found for status=$status');
      } else {
        for (final course in courses) {
          AppLogger.d(
              '[$_tag] loadCourses: Course "${course.titleAr}" - isPublished=${course.isPublished}');
        }
      }

      emit(state.copyWith(
        status: InstructorCoursesStatus.success,
        courses: courses,
        currentStatus: status ?? InstructorCourseStatus.all,
        currentPage: 1,
        hasMore: courses.length >= 20,
      ));
    } catch (e, s) {
      AppLogger.e('[$_tag] loadCourses: Error', e, s);
      emit(state.copyWith(
          status: InstructorCoursesStatus.error, errorMessage: e.toString()));
    }
  }

  /// Load more courses
  Future<void> loadMoreCourses() async {
    if (!state.hasMore || state.status == InstructorCoursesStatus.loadingMore) {
      return;
    }
    emit(state.copyWith(status: InstructorCoursesStatus.loadingMore));

    try {
      final nextPage = state.currentPage + 1;
      final courses = await _repository.getMyCourses(
          status: state.currentStatus, page: nextPage);
      emit(state.copyWith(
        status: InstructorCoursesStatus.success,
        courses: [...state.courses, ...courses],
        currentPage: nextPage,
        hasMore: courses.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
          status: InstructorCoursesStatus.error, errorMessage: e.toString()));
    }
  }

  /// Publish course
  Future<void> publishCourse(String courseId) async {
    AppLogger.d('[$_tag] publishCourse: $courseId');
    emit(state.copyWith(actionStatus: InstructorCoursesStatus.loading));
    try {
      await _repository.publishCourse(courseId);
      // Update course locally without reloading the entire list
      final updatedCourses = state.courses.map((course) {
        if (course.id == courseId) {
          return course.copyWith(isPublished: true);
        }
        return course;
      }).toList();
      emit(state.copyWith(
        actionStatus: InstructorCoursesStatus.success,
        courses: updatedCourses,
      ));
    } catch (e) {
      AppLogger.e('[$_tag] publishCourse: Error', e);
      emit(state.copyWith(
          actionStatus: InstructorCoursesStatus.error,
          errorMessage: e.toString()));
    }
  }

  /// Unpublish course
  Future<void> unpublishCourse(String courseId) async {
    AppLogger.d('[$_tag] unpublishCourse: $courseId');
    emit(state.copyWith(actionStatus: InstructorCoursesStatus.loading));
    try {
      await _repository.unpublishCourse(courseId);
      // Update course locally without reloading the entire list
      final updatedCourses = state.courses.map((course) {
        if (course.id == courseId) {
          return course.copyWith(isPublished: false);
        }
        return course;
      }).toList();
      emit(state.copyWith(
        actionStatus: InstructorCoursesStatus.success,
        courses: updatedCourses,
      ));
    } catch (e) {
      AppLogger.e('[$_tag] unpublishCourse: Error', e);
      emit(state.copyWith(
          actionStatus: InstructorCoursesStatus.error,
          errorMessage: e.toString()));
    }
  }

  /// Delete course
  Future<void> deleteCourse(String courseId) async {
    AppLogger.d('[$_tag] deleteCourse: $courseId');
    emit(state.copyWith(actionStatus: InstructorCoursesStatus.loading));
    try {
      await _repository.deleteCourse(courseId);
      final updatedCourses =
          state.courses.where((c) => c.id != courseId).toList();
      emit(state.copyWith(
        actionStatus: InstructorCoursesStatus.success,
        courses: updatedCourses,
      ));
    } catch (e) {
      AppLogger.e('[$_tag] deleteCourse: Error', e);
      emit(state.copyWith(
          actionStatus: InstructorCoursesStatus.error,
          errorMessage: e.toString()));
    }
  }

  /// Change status filter
  void changeStatus(InstructorCourseStatus status) {
    AppLogger.d('[$_tag] changeStatus: from ${state.currentStatus} to $status');
    if (status != state.currentStatus) {
      loadCourses(status: status, refresh: true);
    }
  }
}
