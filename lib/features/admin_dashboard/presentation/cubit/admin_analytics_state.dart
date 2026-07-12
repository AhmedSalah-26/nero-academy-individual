part of 'admin_analytics_cubit.dart';

/// Admin Analytics Status
enum AdminAnalyticsStatus { initial, loading, success, error }

/// Admin Analytics State
class AdminAnalyticsState extends Equatable {
  final AdminAnalyticsStatus status;
  final AdminDashboardStats platformStats;
  final List<ChartDataPointModel> revenueData;
  final List<ChartDataPointModel> enrollmentsData;
  final List<ChartDataPointModel> instructorEnrollmentsData;
  final List<TopCourseModel> topCourses;
  final List<TopInstructorModel> topInstructors;
  final String? selectedInstructorId;
  final DateTime startDate;
  final DateTime endDate;
  final double totalRevenue;
  final int totalEnrollments;
  final int instructorEnrollmentsTotal;
  final String? errorMessage;

  AdminAnalyticsState({
    this.status = AdminAnalyticsStatus.initial,
    this.platformStats = AdminDashboardStats.empty,
    this.revenueData = const [],
    this.enrollmentsData = const [],
    this.instructorEnrollmentsData = const [],
    this.topCourses = const [],
    this.topInstructors = const [],
    this.selectedInstructorId,
    DateTime? startDate,
    DateTime? endDate,
    this.totalRevenue = 0,
    this.totalEnrollments = 0,
    this.instructorEnrollmentsTotal = 0,
    this.errorMessage,
  })  : startDate =
            startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        endDate = endDate ?? DateTime.now();

  bool get isLoading => status == AdminAnalyticsStatus.loading;

  AdminAnalyticsState copyWith({
    AdminAnalyticsStatus? status,
    AdminDashboardStats? platformStats,
    List<ChartDataPointModel>? revenueData,
    List<ChartDataPointModel>? enrollmentsData,
    List<ChartDataPointModel>? instructorEnrollmentsData,
    List<TopCourseModel>? topCourses,
    List<TopInstructorModel>? topInstructors,
    String? selectedInstructorId,
    DateTime? startDate,
    DateTime? endDate,
    double? totalRevenue,
    int? totalEnrollments,
    int? instructorEnrollmentsTotal,
    String? errorMessage,
  }) {
    return AdminAnalyticsState(
      status: status ?? this.status,
      platformStats: platformStats ?? this.platformStats,
      revenueData: revenueData ?? this.revenueData,
      enrollmentsData: enrollmentsData ?? this.enrollmentsData,
      instructorEnrollmentsData:
          instructorEnrollmentsData ?? this.instructorEnrollmentsData,
      topCourses: topCourses ?? this.topCourses,
      topInstructors: topInstructors ?? this.topInstructors,
      selectedInstructorId: selectedInstructorId ?? this.selectedInstructorId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalEnrollments: totalEnrollments ?? this.totalEnrollments,
      instructorEnrollmentsTotal:
          instructorEnrollmentsTotal ?? this.instructorEnrollmentsTotal,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        platformStats,
        revenueData,
        enrollmentsData,
        instructorEnrollmentsData,
        topCourses,
        topInstructors,
        selectedInstructorId,
        startDate,
        endDate,
        totalRevenue,
        totalEnrollments,
        instructorEnrollmentsTotal,
        errorMessage,
      ];
}
