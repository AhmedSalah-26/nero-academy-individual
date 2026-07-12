/// Admin Dashboard Entities
library admin_entities;

/// Admin Dashboard Statistics Entity
class AdminDashboardStats {
  final int totalStudents;
  final int totalInstructors;
  final int totalCourses;
  final int totalEnrollments;
  final int todayEnrollments;
  final double monthlyRevenue;
  final double revenueChange;
  final int enrollmentChange;

  const AdminDashboardStats({
    required this.totalStudents,
    required this.totalInstructors,
    required this.totalCourses,
    required this.totalEnrollments,
    required this.todayEnrollments,
    required this.monthlyRevenue,
    this.revenueChange = 0,
    this.enrollmentChange = 0,
  });

  static const empty = AdminDashboardStats(
    totalStudents: 0,
    totalInstructors: 0,
    totalCourses: 0,
    totalEnrollments: 0,
    todayEnrollments: 0,
    monthlyRevenue: 0,
  );
}

/// User Role Enum
enum UserRole { student, instructor, admin }

/// Ban Duration Enum
enum BanDuration { hours24, days7, days30, permanent }

extension BanDurationExtension on BanDuration {
  String get value {
    switch (this) {
      case BanDuration.hours24:
        return '24h';
      case BanDuration.days7:
        return '7d';
      case BanDuration.days30:
        return '30d';
      case BanDuration.permanent:
        return 'permanent';
    }
  }

  String getLabel(bool isArabic) {
    switch (this) {
      case BanDuration.hours24:
        return isArabic ? '24 ساعة' : '24 Hours';
      case BanDuration.days7:
        return isArabic ? '7 أيام' : '7 Days';
      case BanDuration.days30:
        return isArabic ? '30 يوم' : '30 Days';
      case BanDuration.permanent:
        return isArabic ? 'دائم' : 'Permanent';
    }
  }
}

/// Course Status Enum
enum CourseStatus { all, published, draft, suspended }

extension CourseStatusExtension on CourseStatus {
  String getLabel(bool isArabic) {
    switch (this) {
      case CourseStatus.all:
        return isArabic ? 'الكل' : 'All';
      case CourseStatus.published:
        return isArabic ? 'منشور' : 'Published';
      case CourseStatus.draft:
        return isArabic ? 'مسودة' : 'Draft';
      case CourseStatus.suspended:
        return isArabic ? 'موقوف' : 'Suspended';
    }
  }
}

/// Enrollment Status Enum
enum EnrollmentStatus { all, active, completed, pending, refunded }

/// Payout Status Enum
enum PayoutStatus { pending, processing, completed, failed, cancelled }

extension PayoutStatusExtension on PayoutStatus {
  String getLabel(bool isArabic) {
    switch (this) {
      case PayoutStatus.pending:
        return isArabic ? 'قيد الانتظار' : 'Pending';
      case PayoutStatus.processing:
        return isArabic ? 'قيد المعالجة' : 'Processing';
      case PayoutStatus.completed:
        return isArabic ? 'مكتمل' : 'Completed';
      case PayoutStatus.failed:
        return isArabic ? 'فشل' : 'Failed';
      case PayoutStatus.cancelled:
        return isArabic ? 'ملغي' : 'Cancelled';
    }
  }
}

/// Report Status Enum
enum ReportStatus { pending, reviewed, resolved, rejected }

extension ReportStatusExtension on ReportStatus {
  String getLabel(bool isArabic) {
    switch (this) {
      case ReportStatus.pending:
        return isArabic ? 'قيد الانتظار' : 'Pending';
      case ReportStatus.reviewed:
        return isArabic ? 'تمت المراجعة' : 'Reviewed';
      case ReportStatus.resolved:
        return isArabic ? 'تم الحل' : 'Resolved';
      case ReportStatus.rejected:
        return isArabic ? 'مرفوض' : 'Rejected';
    }
  }
}

/// Banner Type Enum
enum BannerType { home, course, category }

extension BannerTypeExtension on BannerType {
  String getLabel(bool isArabic) {
    switch (this) {
      case BannerType.home:
        return isArabic ? 'الرئيسية' : 'Home';
      case BannerType.course:
        return isArabic ? 'الكورسات' : 'Courses';
      case BannerType.category:
        return isArabic ? 'التصنيفات' : 'Categories';
    }
  }
}
