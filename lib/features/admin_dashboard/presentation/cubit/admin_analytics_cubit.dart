import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_platform/features/admin_dashboard/data/models/chart_data_point_model.dart';
import 'package:lms_platform/features/admin_dashboard/domain/entities/admin_entities.dart';
import 'package:lms_platform/features/admin_dashboard/domain/repositories/admin_repository.dart';

part 'admin_analytics_state.dart';

/// Admin Analytics Cubit
class AdminAnalyticsCubit extends Cubit<AdminAnalyticsState> {
  final AdminRepository _repository;

  AdminAnalyticsCubit(this._repository) : super(AdminAnalyticsState());

  /// Load all analytics data
  Future<void> loadAnalytics() async {
    emit(state.copyWith(status: AdminAnalyticsStatus.loading));
    try {
      await _loadEnrollmentsData();
      await _loadPlatformStats();
      await _loadTopCourses();
      await _loadTopInstructors();
      await _ensureSelectedInstructor();
      emit(state.copyWith(status: AdminAnalyticsStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: AdminAnalyticsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Set date range
  void setDateRange(DateTime start, DateTime end) {
    emit(state.copyWith(startDate: start, endDate: end));
    loadAnalytics();
  }

  /// Select an instructor and load their date-filtered analytics.
  Future<void> selectInstructor(String instructorId) async {
    emit(state.copyWith(selectedInstructorId: instructorId));
    await _loadSelectedInstructorData();
  }

  Future<void> _loadEnrollmentsData() async {
    try {
      final data = await _repository.getEnrollmentsChart(
        state.startDate,
        state.endDate,
      );
      final total = data.fold<int>(0, (sum, d) => sum + d.value.toInt());
      emit(state.copyWith(enrollmentsData: data, totalEnrollments: total));
    } catch (_) {}
  }

  Future<void> _loadTopCourses() async {
    try {
      final courses = await _repository.getTopCourses(limit: 20);
      emit(state.copyWith(topCourses: courses));
    } catch (_) {}
  }

  Future<void> _loadPlatformStats() async {
    try {
      final stats = await _repository.getDashboardStats();
      emit(state.copyWith(platformStats: stats));
    } catch (_) {}
  }

  Future<void> _loadTopInstructors() async {
    try {
      final instructors = await _repository.getTopInstructors(limit: 100);
      emit(state.copyWith(topInstructors: instructors));
    } catch (_) {}
  }

  Future<void> _ensureSelectedInstructor() async {
    if (state.topInstructors.isEmpty) {
      emit(state.copyWith(
        instructorEnrollmentsData: const [],
        instructorEnrollmentsTotal: 0,
      ));
      return;
    }

    final currentId = state.selectedInstructorId;
    final hasCurrent = currentId != null &&
        state.topInstructors.any((instructor) => instructor.id == currentId);
    final selectedId = hasCurrent ? currentId : state.topInstructors.first.id;
    emit(state.copyWith(selectedInstructorId: selectedId));
    await _loadSelectedInstructorData();
  }

  Future<void> _loadSelectedInstructorData() async {
    final instructorId = state.selectedInstructorId;
    if (instructorId == null) return;

    try {
      final data = await _repository.getInstructorEnrollmentsChart(
        instructorId,
        state.startDate,
        state.endDate,
      );
      final total = data.fold<int>(0, (sum, d) => sum + d.value.toInt());
      emit(state.copyWith(
        instructorEnrollmentsData: data,
        instructorEnrollmentsTotal: total,
      ));
    } catch (_) {}
  }
}
