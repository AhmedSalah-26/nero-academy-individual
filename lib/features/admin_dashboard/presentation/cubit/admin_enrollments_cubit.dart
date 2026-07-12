import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/admin_entities.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../data/models/admin_enrollment_model.dart';

part 'admin_enrollments_state.dart';

/// Admin Enrollments Cubit
class AdminEnrollmentsCubit extends Cubit<AdminEnrollmentsState> {
  final AdminRepository _repository;

  AdminEnrollmentsCubit(this._repository)
      : super(const AdminEnrollmentsState());

  /// Load enrollments
  Future<void> loadEnrollments({
    EnrollmentStatus? status,
    String? search,
    bool refresh = false,
  }) async {
    if (refresh) {
      emit(state.copyWith(
        status: AdminEnrollmentsStatus.loading,
        enrollments: [],
        currentPage: 1,
        hasMore: true,
      ));
    } else {
      emit(state.copyWith(status: AdminEnrollmentsStatus.loading));
    }

    try {
      final enrollments = await _repository.getEnrollments(
        status: status,
        search: search,
        page: 1,
      );
      emit(state.copyWith(
        status: AdminEnrollmentsStatus.success,
        enrollments: enrollments,
        currentStatus: status ?? EnrollmentStatus.all,
        searchQuery: search,
        currentPage: 1,
        hasMore: enrollments.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminEnrollmentsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Load more enrollments (pagination)
  Future<void> loadMoreEnrollments() async {
    if (!state.hasMore || state.status == AdminEnrollmentsStatus.loadingMore) {
      return;
    }

    emit(state.copyWith(status: AdminEnrollmentsStatus.loadingMore));

    try {
      final nextPage = state.currentPage + 1;
      final enrollments = await _repository.getEnrollments(
        status: state.currentStatus,
        search: state.searchQuery,
        page: nextPage,
      );
      emit(state.copyWith(
        status: AdminEnrollmentsStatus.success,
        enrollments: [...state.enrollments, ...enrollments],
        currentPage: nextPage,
        hasMore: enrollments.length >= 20,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminEnrollmentsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Process refund
  Future<void> processRefund(String enrollmentId, String reason) async {
    emit(state.copyWith(actionStatus: AdminEnrollmentsStatus.loading));
    try {
      await _repository.processRefund(enrollmentId, reason);
      await loadEnrollments(
        status: state.currentStatus,
        search: state.searchQuery,
        refresh: true,
      );
      emit(state.copyWith(actionStatus: AdminEnrollmentsStatus.success));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminEnrollmentsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Change status filter
  void changeStatus(EnrollmentStatus status) {
    if (status != state.currentStatus) {
      loadEnrollments(status: status, refresh: true);
    }
  }

  /// Search enrollments
  void search(String query) {
    loadEnrollments(
      status: state.currentStatus,
      search: query.isEmpty ? null : query,
      refresh: true,
    );
  }
}
