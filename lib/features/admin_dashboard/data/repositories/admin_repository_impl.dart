import 'package:lms_platform/features/admin_dashboard/domain/entities/admin_entities.dart';
import 'package:lms_platform/features/admin_dashboard/domain/repositories/admin_repository.dart';
import 'package:lms_platform/features/admin_dashboard/data/datasources/admin_courses_data_source.dart';
import 'package:lms_platform/features/admin_dashboard/data/datasources/admin_stats_data_source.dart';
import 'package:lms_platform/features/admin_dashboard/data/datasources/admin_users_data_source.dart';
import 'package:lms_platform/features/admin_dashboard/data/models/admin_models.dart';

/// Admin Repository Implementation
class AdminRepositoryImpl implements AdminRepository {
  final AdminStatsDataSource _statsDataSource;
  final AdminUsersDataSource _usersDataSource;
  final AdminCoursesDataSource _coursesDataSource;

  AdminRepositoryImpl({
    required AdminStatsDataSource statsDataSource,
    required AdminUsersDataSource usersDataSource,
    required AdminCoursesDataSource coursesDataSource,
  })  : _statsDataSource = statsDataSource,
        _usersDataSource = usersDataSource,
        _coursesDataSource = coursesDataSource;

  @override
  Future<AdminDashboardStats> getDashboardStats() {
    return _statsDataSource.getDashboardStats();
  }

  @override
  Future<List<ChartDataPointModel>> getRevenueChart(
    DateTime start,
    DateTime end,
  ) {
    return _statsDataSource.getRevenueChart(start, end);
  }

  @override
  Future<List<ChartDataPointModel>> getEnrollmentsChart(
    DateTime start,
    DateTime end,
  ) {
    return _statsDataSource.getEnrollmentsChart(start, end);
  }

  @override
  Future<List<AdminUserModel>> getUsers({
    required UserRole role,
    String? search,
    int page = 1,
    int limit = 20,
  }) {
    return _usersDataSource.getUsers(
      role: role,
      search: search,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<bool> banUser(String userId, BanDuration duration, String reason) {
    return _usersDataSource.banUser(userId, duration, reason);
  }

  @override
  Future<bool> unbanUser(String userId) {
    return _usersDataSource.unbanUser(userId);
  }

  @override
  Future<bool> updateUser(String userId, UserUpdateDto dto) {
    return _usersDataSource.updateUser(userId, dto.toJson());
  }

  @override
  Future<List<AdminCourseModel>> getCourses({
    CourseStatus? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) {
    return _coursesDataSource.getCourses(
      status: status,
      search: search,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<bool> suspendCourse(String courseId, String reason) {
    return _coursesDataSource.suspendCourse(courseId, reason);
  }

  @override
  Future<bool> unsuspendCourse(String courseId) {
    return _coursesDataSource.unsuspendCourse(courseId);
  }

  @override
  Future<bool> deleteCourse(String courseId) {
    return _coursesDataSource.deleteCourse(courseId);
  }

  @override
  Future<List<TopCourseModel>> getTopCourses({int limit = 10}) {
    return _statsDataSource.getTopCourses(limit: limit);
  }

  @override
  Future<List<TopInstructorModel>> getTopInstructors({int limit = 10}) {
    return _statsDataSource.getTopInstructors(limit: limit);
  }

  @override
  Future<List<ChartDataPointModel>> getInstructorEnrollmentsChart(
    String teacherId,
    DateTime start,
    DateTime end,
  ) {
    return _statsDataSource.getInstructorEnrollmentsChart(
      teacherId,
      start,
      end,
    );
  }

  @override
  Future<bool> deleteUser(String userId) {
    return _usersDataSource.deleteUser(userId);
  }

  @override
  Future<bool> changeUserRole(String userId, String newRole) {
    return _usersDataSource.changeUserRole(userId, newRole);
  }

  @override
  Future<bool> sendNotification({
    required String userId,
    required String titleAr,
    String? titleEn,
    String? bodyAr,
    String? bodyEn,
    String type = 'system',
  }) {
    return _usersDataSource.sendNotification(
      userId: userId,
      titleAr: titleAr,
      titleEn: titleEn,
      bodyAr: bodyAr,
      bodyEn: bodyEn,
      type: type,
    );
  }

  @override
  Future<int> broadcastNotification({
    required String role,
    required String titleAr,
    String? titleEn,
    String? bodyAr,
    String? bodyEn,
    String type = 'announcement',
  }) {
    return _usersDataSource.broadcastNotification(
      role: role,
      titleAr: titleAr,
      titleEn: titleEn,
      bodyAr: bodyAr,
      bodyEn: bodyEn,
      type: type,
    );
  }

  @override
  Future<bool> publishCourse(String courseId) {
    return _coursesDataSource.publishCourse(courseId);
  }

  @override
  Future<bool> unpublishCourse(String courseId) {
    return _coursesDataSource.unpublishCourse(courseId);
  }

  @override
  Future<bool> enrollStudent(String studentId, String courseId) {
    return _coursesDataSource.enrollStudent(studentId, courseId);
  }

  @override
  Future<bool> cancelEnrollment(String enrollmentId) {
    return _coursesDataSource.cancelEnrollment(enrollmentId);
  }

  @override
  Future<bool> extendEnrollmentAccess(String enrollmentId, int days) {
    return _coursesDataSource.extendEnrollmentAccess(enrollmentId, days);
  }
}
