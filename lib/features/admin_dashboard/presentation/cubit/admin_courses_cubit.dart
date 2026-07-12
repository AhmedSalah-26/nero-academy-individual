import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/app_logger.dart';
import '../../domain/entities/admin_entities.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../data/models/admin_course_model.dart';

part 'admin_courses_state.dart';

/// Admin Courses Cubit
class AdminCoursesCubit extends Cubit<AdminCoursesState> {
  final AdminRepository _repository;
  static const _tag = 'AdminCoursesCubit';

  AdminCoursesCubit(this._repository) : super(const AdminCoursesState());

  /// Load courses
  Future<void> loadCourses({
    CourseStatus? status,
    String? search,
    bool refresh = false,
  }) async {
    if (refresh) {
      emit(state.copyWith(
        status: AdminCoursesStatus.loading,
        courses: [],
        currentPage: 1,
        hasMore: true,
      ));
    } else {
      emit(state.copyWith(status: AdminCoursesStatus.loading));
    }

    try {
      final courses = await _repository.getCourses(
        status: status,
        search: search,
        page: 1,
      );
      emit(state.copyWith(
        status: AdminCoursesStatus.success,
        courses: courses,
        currentStatus: status ?? CourseStatus.all,
        searchQuery: search,
        currentPage: 1,
        hasMore: courses.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminCoursesStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Load more courses (pagination)
  Future<void> loadMoreCourses() async {
    if (!state.hasMore || state.status == AdminCoursesStatus.loadingMore) {
      return;
    }

    emit(state.copyWith(status: AdminCoursesStatus.loadingMore));

    try {
      final nextPage = state.currentPage + 1;
      final courses = await _repository.getCourses(
        status: state.currentStatus,
        search: state.searchQuery,
        page: nextPage,
      );
      emit(state.copyWith(
        status: AdminCoursesStatus.success,
        courses: [...state.courses, ...courses],
        currentPage: nextPage,
        hasMore: courses.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminCoursesStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Suspend course
  Future<void> suspendCourse(String courseId, String reason) async {
    emit(state.copyWith(actionStatus: AdminCoursesStatus.loading));
    try {
      await _repository.suspendCourse(courseId, reason);
      await loadCourses(
          status: state.currentStatus,
          search: state.searchQuery,
          refresh: true);
      emit(state.copyWith(actionStatus: AdminCoursesStatus.success));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminCoursesStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Unsuspend course
  Future<void> unsuspendCourse(String courseId) async {
    emit(state.copyWith(actionStatus: AdminCoursesStatus.loading));
    try {
      await _repository.unsuspendCourse(courseId);
      await loadCourses(
          status: state.currentStatus,
          search: state.searchQuery,
          refresh: true);
      emit(state.copyWith(actionStatus: AdminCoursesStatus.success));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminCoursesStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Delete course
  Future<void> deleteCourse(String courseId) async {
    emit(state.copyWith(actionStatus: AdminCoursesStatus.loading));
    try {
      await _repository.deleteCourse(courseId);
      await loadCourses(
          status: state.currentStatus,
          search: state.searchQuery,
          refresh: true);
      emit(state.copyWith(actionStatus: AdminCoursesStatus.success));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminCoursesStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Change status tab
  void changeStatus(CourseStatus status) {
    if (status != state.currentStatus) {
      loadCourses(status: status, refresh: true);
    }
  }

  /// Search courses
  void search(String query) {
    loadCourses(
      status: state.currentStatus,
      search: query.isEmpty ? null : query,
      refresh: true,
    );
  }

  /// Publish course (admin override)
  Future<void> publishCourse(String courseId) async {
    AppLogger.d('[$_tag] publishCourse: $courseId');
    emit(state.copyWith(actionStatus: AdminCoursesStatus.loading));
    try {
      await Supabase.instance.client.from('courses').update({
        'is_published': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', courseId);
      await loadCourses(
          status: state.currentStatus,
          search: state.searchQuery,
          refresh: true);
      emit(state.copyWith(actionStatus: AdminCoursesStatus.success));
      AppLogger.success('[$_tag] publishCourse success');
    } catch (e) {
      AppLogger.e('[$_tag] publishCourse error', e);
      emit(state.copyWith(
        actionStatus: AdminCoursesStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Unpublish course (admin override)
  Future<void> unpublishCourse(String courseId) async {
    AppLogger.d('[$_tag] unpublishCourse: $courseId');
    emit(state.copyWith(actionStatus: AdminCoursesStatus.loading));
    try {
      await Supabase.instance.client.from('courses').update({
        'is_published': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', courseId);
      await loadCourses(
          status: state.currentStatus,
          search: state.searchQuery,
          refresh: true);
      emit(state.copyWith(actionStatus: AdminCoursesStatus.success));
      AppLogger.success('[$_tag] unpublishCourse success');
    } catch (e) {
      AppLogger.e('[$_tag] unpublishCourse error', e);
      emit(state.copyWith(
        actionStatus: AdminCoursesStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Get course enrollments
  Future<List<Map<String, dynamic>>> getCourseEnrollments(
      String courseId) async {
    AppLogger.d('[$_tag] getCourseEnrollments: $courseId');
    try {
      final response = await Supabase.instance.client
          .from('enrollments')
          .select('*, user:profiles!enrollments_user_id_fkey(name, email)')
          .eq('course_id', courseId)
          .order('enrolled_at', ascending: false);
      AppLogger.success(
          '[$_tag] getCourseEnrollments success: ${(response as List).length}');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.e('[$_tag] getCourseEnrollments error', e);
      rethrow;
    }
  }

  /// Feature course
  Future<void> featureCourse(String courseId) async {
    AppLogger.d('[$_tag] featureCourse: $courseId');
    emit(state.copyWith(actionStatus: AdminCoursesStatus.loading));
    try {
      await Supabase.instance.client.from('courses').update({
        'is_featured': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', courseId);
      await loadCourses(
          status: state.currentStatus,
          search: state.searchQuery,
          refresh: true);
      emit(state.copyWith(actionStatus: AdminCoursesStatus.success));
      AppLogger.success('[$_tag] featureCourse success');
    } catch (e) {
      AppLogger.e('[$_tag] featureCourse error', e);
      emit(state.copyWith(
        actionStatus: AdminCoursesStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Unfeature course
  Future<void> unfeatureCourse(String courseId) async {
    AppLogger.d('[$_tag] unfeatureCourse: $courseId');
    emit(state.copyWith(actionStatus: AdminCoursesStatus.loading));
    try {
      await Supabase.instance.client.from('courses').update({
        'is_featured': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', courseId);
      await loadCourses(
          status: state.currentStatus,
          search: state.searchQuery,
          refresh: true);
      emit(state.copyWith(actionStatus: AdminCoursesStatus.success));
      AppLogger.success('[$_tag] unfeatureCourse success');
    } catch (e) {
      AppLogger.e('[$_tag] unfeatureCourse error', e);
      emit(state.copyWith(
        actionStatus: AdminCoursesStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
