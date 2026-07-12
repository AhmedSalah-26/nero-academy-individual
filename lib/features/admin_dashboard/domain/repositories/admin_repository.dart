import '../entities/admin_entities.dart';
import '../../data/models/admin_models.dart';

/// Admin Repository Interface
abstract class AdminRepository {
  // Dashboard
  Future<AdminDashboardStats> getDashboardStats();
  Future<List<ChartDataPointModel>> getRevenueChart(
      DateTime start, DateTime end);
  Future<List<ChartDataPointModel>> getEnrollmentsChart(
      DateTime start, DateTime end);

  // Users
  Future<List<AdminUserModel>> getUsers({
    required UserRole role,
    String? search,
    int page = 1,
    int limit = 20,
  });
  Future<bool> banUser(String userId, BanDuration duration, String reason);
  Future<bool> unbanUser(String userId);
  Future<bool> updateUser(String userId, UserUpdateDto dto);

  // Courses
  Future<List<AdminCourseModel>> getCourses({
    CourseStatus? status,
    String? search,
    int page = 1,
    int limit = 20,
  });
  Future<bool> suspendCourse(String courseId, String reason);
  Future<bool> unsuspendCourse(String courseId);
  Future<bool> deleteCourse(String courseId);

  // Analytics
  Future<List<TopCourseModel>> getTopCourses({int limit = 10});
  Future<List<TopInstructorModel>> getTopInstructors({int limit = 10});
  Future<List<ChartDataPointModel>> getInstructorEnrollmentsChart(
    String instructorId,
    DateTime start,
    DateTime end,
  );

  // ==========================================
  // NEW: Missing Permissions
  // ==========================================

  // User Management (extended)
  Future<bool> deleteUser(String userId);
  Future<bool> changeUserRole(String userId, String newRole);
  Future<bool> sendNotification({
    required String userId,
    required String titleAr,
    String? titleEn,
    String? bodyAr,
    String? bodyEn,
    String type = 'system',
  });
  Future<int> broadcastNotification({
    required String role,
    required String titleAr,
    String? titleEn,
    String? bodyAr,
    String? bodyEn,
    String type = 'announcement',
  });

  // Course Management (extended)
  Future<bool> publishCourse(String courseId);
  Future<bool> unpublishCourse(String courseId);

  // Enrollment Management (extended)
  Future<bool> enrollStudent(String studentId, String courseId);
  Future<bool> cancelEnrollment(String enrollmentId);
  Future<bool> extendEnrollmentAccess(String enrollmentId, int days);
}

/// Top Course Model for Analytics
class TopCourseModel {
  final String id;
  final String titleAr;
  final String titleEn;
  final String? thumbnailUrl;
  final String instructorName;
  final int enrollmentsCount;
  final double revenue;
  final double rating;

  const TopCourseModel({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    this.thumbnailUrl,
    required this.instructorName,
    required this.enrollmentsCount,
    required this.revenue,
    required this.rating,
  });

  factory TopCourseModel.fromJson(Map<String, dynamic> json) {
    return TopCourseModel(
      id: json['id'] as String,
      titleAr: json['title_ar'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String?,
      instructorName: json['profiles']?['name'] as String? ?? '',
      enrollmentsCount: json['enrollments_count'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      rating: (json['average_rating'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Top Instructor Model for Analytics
class TopInstructorModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final int coursesCount;
  final int studentsCount;
  final double totalRevenue;
  final double rating;

  const TopInstructorModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.coursesCount,
    required this.studentsCount,
    required this.totalRevenue,
    required this.rating,
  });

  factory TopInstructorModel.fromJson(Map<String, dynamic> json) {
    return TopInstructorModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      coursesCount: json['courses_count'] as int? ?? 0,
      studentsCount: json['students_count'] as int? ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
      rating: (json['average_rating'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// User Update DTO
class UserUpdateDto {
  final String? name;
  final String? phone;
  final String? role;
  final String? headlineAr;
  final String? headlineEn;
  final String? bioAr;
  final String? bioEn;
  final List<String>? expertise;
  final List<String>? interests;
  final bool? isActive;
  final bool? isVerifiedInstructor;

  const UserUpdateDto({
    this.name,
    this.phone,
    this.role,
    this.headlineAr,
    this.headlineEn,
    this.bioAr,
    this.bioEn,
    this.expertise,
    this.interests,
    this.isActive,
    this.isVerifiedInstructor,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (phone != null) map['phone'] = phone;
    if (role != null) map['role'] = role;
    if (headlineAr != null) map['headline_ar'] = headlineAr;
    if (headlineEn != null) map['headline_en'] = headlineEn;
    if (bioAr != null) map['bio_ar'] = bioAr;
    if (bioEn != null) map['bio_en'] = bioEn;
    if (expertise != null) map['expertise'] = expertise;
    if (interests != null) map['interests'] = interests;
    if (isActive != null) map['is_active'] = isActive;
    if (isVerifiedInstructor != null) {
      map['is_verified_instructor'] = isVerifiedInstructor;
    }
    return map;
  }
}
