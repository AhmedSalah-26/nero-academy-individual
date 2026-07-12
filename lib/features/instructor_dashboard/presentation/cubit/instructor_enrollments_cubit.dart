import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/instructor_enrollment_model.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/repositories/instructor_repository.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

part 'instructor_enrollments_state.dart';

/// Instructor Enrollments Cubit
class InstructorEnrollmentsCubit extends Cubit<InstructorEnrollmentsState> {
  final InstructorRepository _repository;

  InstructorEnrollmentsCubit(this._repository)
      : super(const InstructorEnrollmentsState());

  /// Load enrollments
  Future<void> loadEnrollments() async {
    emit(state.copyWith(status: InstructorEnrollmentsStatus.loading));

    try {
      final enrollments = await _repository.getEnrollments(
        courseId: state.selectedCourseId,
        startDate: state.startDate,
        endDate: state.endDate,
      );

      // Calculate totals
      double totalRevenue = 0;
      for (final enrollment in enrollments) {
        totalRevenue += enrollment.paidAmount ?? 0;
      }

      emit(state.copyWith(
        status: InstructorEnrollmentsStatus.success,
        enrollments: enrollments,
        totalRevenue: totalRevenue,
        totalEnrollments: enrollments.length,
        hasMore: enrollments.length >= 20,
      ));
    } catch (e) {
      String message = e.toString();
      if (e is PostgrestException) {
        message = 'Error Code: ${e.code}';
      }

      emit(state.copyWith(
        status: InstructorEnrollmentsStatus.error,
        errorMessage: message,
      ));
    }
  }

  /// Load more enrollments (pagination)
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    emit(state.copyWith(isLoadingMore: true));

    try {
      final page = (state.enrollments.length ~/ 20) + 1;
      final enrollments = await _repository.getEnrollments(
        courseId: state.selectedCourseId,
        startDate: state.startDate,
        endDate: state.endDate,
        page: page,
      );

      emit(state.copyWith(
        isLoadingMore: false,
        enrollments: [...state.enrollments, ...enrollments],
        hasMore: enrollments.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  /// Set filter
  void setFilter(EnrollmentStatusFilter filter) {
    emit(state.copyWith(filter: filter));
  }

  /// Set course filter
  void setCourseFilter(String? courseId) {
    emit(state.copyWith(
      selectedCourseId: courseId,
      clearCourseId: courseId == null,
    ));
    loadEnrollments();
  }

  /// Set date range
  void setDateRange(DateTime? start, DateTime? end) {
    emit(state.copyWith(
      startDate: start,
      endDate: end,
      clearStartDate: start == null,
      clearEndDate: end == null,
    ));
    loadEnrollments();
  }

  /// Clear filters
  void clearFilters() {
    emit(const InstructorEnrollmentsState());
    loadEnrollments();
  }
}
