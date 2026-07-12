import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/chart_data_point_model.dart';
import '../../domain/repositories/admin_repository.dart';

part 'admin_analytics_state.dart';

/// Admin Analytics Cubit
class AdminAnalyticsCubit extends Cubit<AdminAnalyticsState> {
  final AdminRepository _repository;

  AdminAnalyticsCubit(this._repository) : super(AdminAnalyticsState());

  /// Load all analytics data
  Future<void> loadAnalytics() async {
    emit(state.copyWith(status: AdminAnalyticsStatus.loading));
    try {
      await Future.wait([
        _loadRevenueData(),
        _loadEnrollmentsData(),
        _loadTopCourses(),
        _loadTopInstructors(),
      ]);
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

  Future<void> _loadRevenueData() async {
    try {
      final data = await _repository.getRevenueChart(
        state.startDate,
        state.endDate,
      );
      final total = data.fold<double>(0, (sum, d) => sum + d.value);
      emit(state.copyWith(revenueData: data, totalRevenue: total));
    } catch (_) {}
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
      final courses = await _repository.getTopCourses(limit: 10);
      emit(state.copyWith(topCourses: courses));
    } catch (_) {}
  }

  Future<void> _loadTopInstructors() async {
    try {
      final instructors = await _repository.getTopInstructors(limit: 10);
      emit(state.copyWith(topInstructors: instructors));
    } catch (_) {}
  }
}
