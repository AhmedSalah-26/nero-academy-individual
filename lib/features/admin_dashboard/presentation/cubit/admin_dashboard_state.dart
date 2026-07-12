part of 'admin_dashboard_cubit.dart';

enum DashboardStatus { initial, loading, success, error }

class AdminDashboardState extends Equatable {
  final DashboardStatus statsStatus;
  final DashboardStatus enrollmentsChartStatus;
  final AdminDashboardStats stats;
  final List<ChartDataPointModel> enrollmentsChartData;
  final String? errorMessage;

  const AdminDashboardState({
    this.statsStatus = DashboardStatus.initial,
    this.enrollmentsChartStatus = DashboardStatus.initial,
    this.stats = AdminDashboardStats.empty,
    this.enrollmentsChartData = const [],
    this.errorMessage,
  });

  bool get isLoading =>
      statsStatus == DashboardStatus.loading ||
      enrollmentsChartStatus == DashboardStatus.loading;

  bool get hasError =>
      statsStatus == DashboardStatus.error ||
      enrollmentsChartStatus == DashboardStatus.error;

  AdminDashboardState copyWith({
    DashboardStatus? statsStatus,
    DashboardStatus? enrollmentsChartStatus,
    AdminDashboardStats? stats,
    List<ChartDataPointModel>? enrollmentsChartData,
    String? errorMessage,
  }) {
    return AdminDashboardState(
      statsStatus: statsStatus ?? this.statsStatus,
      enrollmentsChartStatus:
          enrollmentsChartStatus ?? this.enrollmentsChartStatus,
      stats: stats ?? this.stats,
      enrollmentsChartData: enrollmentsChartData ?? this.enrollmentsChartData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        statsStatus,
        enrollmentsChartStatus,
        stats,
        enrollmentsChartData,
        errorMessage,
      ];
}
