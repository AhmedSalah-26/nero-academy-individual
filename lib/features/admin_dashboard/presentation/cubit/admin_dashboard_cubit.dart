import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/app_logger.dart';
import '../../domain/entities/admin_entities.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../data/models/chart_data_point_model.dart';

part 'admin_dashboard_state.dart';

/// Admin Dashboard Cubit
class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  final AdminRepository _repository;
  static const _tag = 'AdminDashboardCubit';

  AdminDashboardCubit(this._repository) : super(const AdminDashboardState());

  /// Load dashboard statistics
  Future<void> loadDashboardStats() async {
    AppLogger.d('[$_tag] loadDashboardStats: Starting...');
    emit(state.copyWith(statsStatus: DashboardStatus.loading));
    try {
      final stats = await _repository.getDashboardStats();
      AppLogger.d(
          '[$_tag] loadDashboardStats: Stats received - monthlyRevenue: ${stats.monthlyRevenue}');
      AppLogger.success('[$_tag] loadDashboardStats: Success');
      emit(state.copyWith(
        statsStatus: DashboardStatus.success,
        stats: stats,
      ));
    } catch (e, s) {
      AppLogger.e('[$_tag] loadDashboardStats: Error', e, s);
      emit(state.copyWith(
        statsStatus: DashboardStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Load revenue chart
  Future<void> loadRevenueChart({DateTime? start, DateTime? end}) async {
    AppLogger.d('[$_tag] loadRevenueChart: Starting...');
    emit(state.copyWith(revenueChartStatus: DashboardStatus.loading));
    try {
      final now = DateTime.now();
      final startDate = start ?? DateTime(now.year, now.month - 11, 1);
      final endDate = end ?? now;
      AppLogger.d(
          '[$_tag] loadRevenueChart: Fetching data from $startDate to $endDate');

      final chartData = await _repository.getRevenueChart(startDate, endDate);
      AppLogger.d(
          '[$_tag] loadRevenueChart: Received ${chartData.length} data points');

      if (chartData.isNotEmpty) {
        AppLogger.d(
            '[$_tag] loadRevenueChart: Data: ${chartData.map((e) => '${e.label}: ${e.value}').join(', ')}');
      } else {
        AppLogger.w(
            '[$_tag] loadRevenueChart: Chart data is EMPTY - revenue will not display!');
      }

      AppLogger.success('[$_tag] loadRevenueChart: Success');
      emit(state.copyWith(
        revenueChartStatus: DashboardStatus.success,
        revenueChartData: chartData,
      ));
    } catch (e, s) {
      AppLogger.e('[$_tag] loadRevenueChart: Error', e, s);
      emit(state.copyWith(
        revenueChartStatus: DashboardStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Load enrollments chart
  Future<void> loadEnrollmentsChart({DateTime? start, DateTime? end}) async {
    AppLogger.d('[$_tag] loadEnrollmentsChart: Starting...');
    emit(state.copyWith(enrollmentsChartStatus: DashboardStatus.loading));
    try {
      final now = DateTime.now();
      final startDate = start ?? DateTime(now.year, now.month - 11, 1);
      final endDate = end ?? now;
      AppLogger.d(
          '[$_tag] loadEnrollmentsChart: Fetching data from $startDate to $endDate');

      final chartData =
          await _repository.getEnrollmentsChart(startDate, endDate);
      AppLogger.d(
          '[$_tag] loadEnrollmentsChart: Received ${chartData.length} data points');

      AppLogger.success('[$_tag] loadEnrollmentsChart: Success');
      emit(state.copyWith(
        enrollmentsChartStatus: DashboardStatus.success,
        enrollmentsChartData: chartData,
      ));
    } catch (e, s) {
      AppLogger.e('[$_tag] loadEnrollmentsChart: Error', e, s);
      emit(state.copyWith(
        enrollmentsChartStatus: DashboardStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Load all dashboard data
  Future<void> loadAll() async {
    AppLogger.d('[$_tag] loadAll: Starting to load all dashboard data');
    await Future.wait([
      loadDashboardStats(),
      loadRevenueChart(),
      loadEnrollmentsChart(),
    ]);
    AppLogger.d('[$_tag] loadAll: Completed loading all dashboard data');
  }

  /// Refresh dashboard
  Future<void> refresh() async {
    AppLogger.d('[$_tag] refresh: Refreshing dashboard');
    await loadAll();
  }
}
