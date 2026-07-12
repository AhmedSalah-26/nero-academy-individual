import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/entities/instructor_entities.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/repositories/instructor_repository.dart';

part 'instructor_dashboard_state.dart';

/// Instructor Dashboard Cubit
class InstructorDashboardCubit extends Cubit<InstructorDashboardState> {
  final InstructorRepository _repository;
  static const _tag = 'InstructorDashboardCubit';

  InstructorDashboardCubit(this._repository)
      : super(InstructorDashboardState());

  /// Load all dashboard data
  Future<void> loadAll() async {
    AppLogger.d('[$_tag] loadAll: Starting to load dashboard data');
    emit(state.copyWith(status: InstructorDashboardStatus.loading));
    try {
      AppLogger.d('[$_tag] loadAll: Fetching dashboard stats...');
      final stats = await _repository.getDashboardStats();
      AppLogger.d(
          '[$_tag] loadAll: Stats received - totalEarnings: ${stats.totalEarnings}, availableBalance: ${stats.availableBalance}, pendingBalance: ${stats.pendingBalance}');

      AppLogger.d(
          '[$_tag] loadAll: Fetching revenue chart (${state.startDate} - ${state.endDate})...');
      final revenueChart =
          await _repository.getRevenueChart(state.startDate, state.endDate);
      AppLogger.d(
          '[$_tag] loadAll: Revenue chart received - ${revenueChart.length} data points');
      if (revenueChart.isNotEmpty) {
        AppLogger.d(
            '[$_tag] loadAll: Revenue chart data: ${revenueChart.map((e) => '${e.label}: ${e.value}').join(', ')}');
      } else {
        AppLogger.w(
            '[$_tag] loadAll: Revenue chart is EMPTY - this is why earnings are not showing!');
      }

      AppLogger.d('[$_tag] loadAll: Fetching enrollments chart...');
      final enrollmentsChart =
          await _repository.getEnrollmentsChart(state.startDate, state.endDate);
      AppLogger.d(
          '[$_tag] loadAll: Enrollments chart received - ${enrollmentsChart.length} data points');

      AppLogger.success('[$_tag] loadAll: Dashboard data loaded successfully');
      emit(state.copyWith(
        status: InstructorDashboardStatus.success,
        stats: stats,
        revenueChart: revenueChart,
        enrollmentsChart: enrollmentsChart,
      ));
    } catch (e, s) {
      AppLogger.e('[$_tag] loadAll: Error loading dashboard data', e, s);
      emit(state.copyWith(
        status: InstructorDashboardStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Set date range and reload charts
  Future<void> setDateRange(DateTime start, DateTime end) async {
    AppLogger.d('[$_tag] setDateRange: $start - $end');
    emit(state.copyWith(
      startDate: start,
      endDate: end,
      status: InstructorDashboardStatus.loading,
    ));

    try {
      final revenueChart = await _repository.getRevenueChart(start, end);
      final enrollmentsChart =
          await _repository.getEnrollmentsChart(start, end);

      emit(state.copyWith(
        status: InstructorDashboardStatus.success,
        revenueChart: revenueChart,
        enrollmentsChart: enrollmentsChart,
      ));
    } catch (e, s) {
      AppLogger.e('[$_tag] setDateRange: Error loading chart data', e, s);
      emit(state.copyWith(
        status: InstructorDashboardStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Refresh dashboard
  Future<void> refresh() async {
    AppLogger.d('[$_tag] refresh: Refreshing dashboard');
    await loadAll();
  }
}
