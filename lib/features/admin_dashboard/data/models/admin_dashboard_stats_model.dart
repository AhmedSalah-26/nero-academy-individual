import '../../domain/entities/admin_entities.dart';

/// Admin Dashboard Stats Model
class AdminDashboardStatsModel extends AdminDashboardStats {
  const AdminDashboardStatsModel({
    required super.totalStudents,
    required super.totalInstructors,
    required super.totalCourses,
    required super.totalEnrollments,
    required super.todayEnrollments,
    required super.monthlyRevenue,
    super.revenueChange,
    super.enrollmentChange,
  });

  factory AdminDashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStatsModel(
      totalStudents: json['total_students'] as int? ?? 0,
      totalInstructors: json['total_instructors'] as int? ?? 0,
      totalCourses: json['total_courses'] as int? ?? 0,
      totalEnrollments: json['total_enrollments'] as int? ?? 0,
      todayEnrollments: json['today_enrollments'] as int? ?? 0,
      monthlyRevenue: (json['monthly_revenue'] as num?)?.toDouble() ?? 0,
      revenueChange: (json['revenue_change'] as num?)?.toDouble() ?? 0,
      enrollmentChange: json['enrollment_change'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_students': totalStudents,
      'total_instructors': totalInstructors,
      'total_courses': totalCourses,
      'total_enrollments': totalEnrollments,
      'today_enrollments': todayEnrollments,
      'monthly_revenue': monthlyRevenue,
      'revenue_change': revenueChange,
      'enrollment_change': enrollmentChange,
    };
  }
}
