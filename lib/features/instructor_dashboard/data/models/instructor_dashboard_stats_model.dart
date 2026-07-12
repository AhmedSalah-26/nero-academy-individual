import 'package:lms_platform/features/instructor_dashboard/domain/entities/instructor_entities.dart';

/// Instructor Dashboard Stats Model
class InstructorDashboardStatsModel extends InstructorDashboardStats {
  const InstructorDashboardStatsModel({
    required super.totalCourses,
    required super.publishedCourses,
    required super.totalStudents,
    required super.totalEnrollments,
    required super.monthlyEnrollments,
    required super.totalEarnings,
    required super.availableBalance,
    required super.pendingBalance,
    required super.averageRating,
    required super.totalReviews,
    required super.unansweredQuestions,
  });

  factory InstructorDashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return InstructorDashboardStatsModel(
      totalCourses: json['total_courses'] as int? ?? 0,
      publishedCourses: json['published_courses'] as int? ?? 0,
      totalStudents: json['total_students'] as int? ?? 0,
      totalEnrollments: json['total_enrollments'] as int? ?? 0,
      monthlyEnrollments: json['monthly_enrollments'] as int? ?? 0,
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0,
      availableBalance: (json['available_balance'] as num?)?.toDouble() ?? 0,
      pendingBalance: (json['pending_balance'] as num?)?.toDouble() ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      unansweredQuestions: json['unanswered_questions'] as int? ?? 0,
    );
  }
}
