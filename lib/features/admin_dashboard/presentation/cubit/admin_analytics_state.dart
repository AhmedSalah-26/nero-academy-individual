part of 'admin_analytics_cubit.dart';

/// Admin Analytics Status
enum AdminAnalyticsStatus { initial, loading, success, error }

/// Admin Analytics State
class AdminAnalyticsState extends Equatable {
  final AdminAnalyticsStatus status;
  final List<ChartDataPointModel> revenueData;
  final List<ChartDataPointModel> enrollmentsData;
  final List<TopCourseModel> topCourses;
  final List<TopInstructorModel> topInstructors;
  final DateTime startDate;
  final DateTime endDate;
  final double totalRevenue;
  final int totalEnrollments;
  final String? errorMessage;

  AdminAnalyticsState({
    this.status = AdminAnalyticsStatus.initial,
    this.revenueData = const [],
    this.enrollmentsData = const [],
    this.topCourses = const [],
    this.topInstructors = const [],
    DateTime? startDate,
    DateTime? endDate,
    this.totalRevenue = 0,
    this.totalEnrollments = 0,
    this.errorMessage,
  })  : startDate =
            startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        endDate = endDate ?? DateTime.now();

  bool get isLoading => status == AdminAnalyticsStatus.loading;

  AdminAnalyticsState copyWith({
    AdminAnalyticsStatus? status,
    List<ChartDataPointModel>? revenueData,
    List<ChartDataPointModel>? enrollmentsData,
    List<TopCourseModel>? topCourses,
    List<TopInstructorModel>? topInstructors,
    DateTime? startDate,
    DateTime? endDate,
    double? totalRevenue,
    int? totalEnrollments,
    String? errorMessage,
  }) {
    return AdminAnalyticsState(
      status: status ?? this.status,
      revenueData: revenueData ?? this.revenueData,
      enrollmentsData: enrollmentsData ?? this.enrollmentsData,
      topCourses: topCourses ?? this.topCourses,
      topInstructors: topInstructors ?? this.topInstructors,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalEnrollments: totalEnrollments ?? this.totalEnrollments,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        revenueData,
        enrollmentsData,
        topCourses,
        topInstructors,
        startDate,
        endDate,
        totalRevenue,
        totalEnrollments,
        errorMessage,
      ];
}
