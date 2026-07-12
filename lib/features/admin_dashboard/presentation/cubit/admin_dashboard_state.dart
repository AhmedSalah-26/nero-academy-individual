part of 'admin_dashboard_cubit.dart';

enum DashboardStatus { initial, loading, success, error }

class AdminDashboardState extends Equatable {
  final DashboardStatus statsStatus;
  final DashboardStatus revenueChartStatus;
  final DashboardStatus enrollmentsChartStatus;
  final AdminDashboardStats stats;
  final List<ChartDataPointModel> revenueChartData;
  final List<ChartDataPointModel> enrollmentsChartData;
  final String? errorMessage;

  const AdminDashboardState({
    this.statsStatus = DashboardStatus.initial,
    this.revenueChartStatus = DashboardStatus.initial,
    this.enrollmentsChartStatus = DashboardStatus.initial,
    this.stats = AdminDashboardStats.empty,
    this.revenueChartData = const [],
    this.enrollmentsChartData = const [],
    this.errorMessage,
  });

  bool get isLoading =>
      statsStatus == DashboardStatus.loading ||
      revenueChartStatus == DashboardStatus.loading ||
      enrollmentsChartStatus == DashboardStatus.loading;

  bool get hasError =>
      statsStatus == DashboardStatus.error ||
      revenueChartStatus == DashboardStatus.error ||
      enrollmentsChartStatus == DashboardStatus.error;

  AdminDashboardState copyWith({
    DashboardStatus? statsStatus,
    DashboardStatus? revenueChartStatus,
    DashboardStatus? enrollmentsChartStatus,
    AdminDashboardStats? stats,
    List<ChartDataPointModel>? revenueChartData,
    List<ChartDataPointModel>? enrollmentsChartData,
    String? errorMessage,
  }) {
    return AdminDashboardState(
      statsStatus: statsStatus ?? this.statsStatus,
      revenueChartStatus: revenueChartStatus ?? this.revenueChartStatus,
      enrollmentsChartStatus:
          enrollmentsChartStatus ?? this.enrollmentsChartStatus,
      stats: stats ?? this.stats,
      revenueChartData: revenueChartData ?? this.revenueChartData,
      enrollmentsChartData: enrollmentsChartData ?? this.enrollmentsChartData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        statsStatus,
        revenueChartStatus,
        enrollmentsChartStatus,
        stats,
        revenueChartData,
        enrollmentsChartData,
        errorMessage,
      ];
}
