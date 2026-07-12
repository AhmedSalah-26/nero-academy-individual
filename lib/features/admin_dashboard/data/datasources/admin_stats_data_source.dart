import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/features/admin_dashboard/data/models/admin_models.dart';
import 'package:lms_platform/features/admin_dashboard/domain/repositories/admin_repository.dart';

/// Admin Stats Data Source - Dashboard statistics and charts
class AdminStatsDataSource {
  final SupabaseClient _client;
  static const _tag = 'AdminStatsDS';

  AdminStatsDataSource(this._client);

  /// Get dashboard statistics - calculates from tables directly
  Future<AdminDashboardStatsModel> getDashboardStats() async {
    AppLogger.d('[$_tag] getDashboardStats: Calculating stats');
    try {
      // Get users count
      final usersResponse = await _client.from('profiles').select('id, role');
      final users = usersResponse as List;
      final totalInstructors =
          users.where((u) => u['role'] == 'instructor').length;
      final totalStudents = users.where((u) => u['role'] == 'student').length;

      // Get courses count
      final coursesResponse = await _client.from('courses').select('id');
      final totalCourses = (coursesResponse as List).length;

      // Get enrollments count
      final enrollmentsResponse =
          await _client.from('enrollments').select('id, price, enrolled_at');
      final enrollments = enrollmentsResponse as List;
      final totalEnrollments = enrollments.length;

      // Today's enrollments
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnrollments = enrollments.where((e) {
        final enrolledAt = DateTime.tryParse(e['enrolled_at'] as String? ?? '');
        return enrolledAt != null && enrolledAt.isAfter(todayStart);
      }).length;

      // Monthly revenue
      final monthStart = DateTime(today.year, today.month, 1);
      final monthlyRevenue = enrollments.where((e) {
        final enrolledAt = DateTime.tryParse(e['enrolled_at'] as String? ?? '');
        return enrolledAt != null && enrolledAt.isAfter(monthStart);
      }).fold<double>(
          0, (sum, e) => sum + ((e['price'] as num?)?.toDouble() ?? 0));

      AppLogger.success('[$_tag] getDashboardStats success');
      return AdminDashboardStatsModel(
        totalStudents: totalStudents,
        totalInstructors: totalInstructors,
        totalCourses: totalCourses,
        totalEnrollments: totalEnrollments,
        todayEnrollments: todayEnrollments,
        monthlyRevenue: monthlyRevenue,
      );
    } catch (e) {
      AppLogger.e('[$_tag] getDashboardStats error', e);
      rethrow;
    }
  }

  /// Get revenue chart data for date range
  Future<List<ChartDataPointModel>> getRevenueChart(
      DateTime start, DateTime end) async {
    AppLogger.d('[$_tag] getRevenueChart: $start to $end');
    try {
      final response = await _client
          .from('enrollments')
          .select('enrolled_at, price')
          .gte('enrolled_at', start.toIso8601String())
          .lte('enrolled_at', end.toIso8601String())
          .order('enrolled_at');

      final enrollments = response as List;

      // Group by date
      final Map<String, double> revenueByDate = {};
      for (final e in enrollments) {
        final date = DateTime.parse(e['enrolled_at'] as String);
        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        revenueByDate[dateKey] = (revenueByDate[dateKey] ?? 0) +
            ((e['price'] as num?)?.toDouble() ?? 0);
      }

      final result = revenueByDate.entries
          .map((e) => ChartDataPointModel(
                label: e.key,
                value: e.value,
                date: DateTime.parse(e.key),
              ))
          .toList()
        ..sort((a, b) => a.date!.compareTo(b.date!));

      AppLogger.success(
          '[$_tag] getRevenueChart success: ${result.length} points');
      return result;
    } catch (e) {
      AppLogger.e('[$_tag] getRevenueChart error', e);
      rethrow;
    }
  }

  /// Get enrollments chart data for date range
  Future<List<ChartDataPointModel>> getEnrollmentsChart(
      DateTime start, DateTime end) async {
    AppLogger.d('[$_tag] getEnrollmentsChart: $start to $end');
    try {
      final response = await _client
          .from('enrollments')
          .select('enrolled_at')
          .gte('enrolled_at', start.toIso8601String())
          .lte('enrolled_at', end.toIso8601String())
          .order('enrolled_at');

      final enrollments = response as List;

      // Group by date
      final Map<String, int> enrollmentsByDate = {};
      for (final e in enrollments) {
        final date = DateTime.parse(e['enrolled_at'] as String);
        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        enrollmentsByDate[dateKey] = (enrollmentsByDate[dateKey] ?? 0) + 1;
      }

      final result = enrollmentsByDate.entries
          .map((e) => ChartDataPointModel(
                label: e.key,
                value: e.value.toDouble(),
                date: DateTime.parse(e.key),
              ))
          .toList()
        ..sort((a, b) => a.date!.compareTo(b.date!));

      AppLogger.success(
          '[$_tag] getEnrollmentsChart success: ${result.length} points');
      return result;
    } catch (e) {
      AppLogger.e('[$_tag] getEnrollmentsChart error', e);
      rethrow;
    }
  }

  /// Get instructor enrollments chart data for date range
  Future<List<ChartDataPointModel>> getInstructorEnrollmentsChart(
    String instructorId,
    DateTime start,
    DateTime end,
  ) async {
    AppLogger.d(
      '[$_tag] getInstructorEnrollmentsChart: $instructorId, $start to $end',
    );
    try {
      final response = await _client
          .from('enrollments')
          .select('enrolled_at, course:courses!inner(instructor_id)')
          .eq('course.instructor_id', instructorId)
          .gte('enrolled_at', start.toIso8601String())
          .lte('enrolled_at', end.toIso8601String())
          .order('enrolled_at');

      final enrollments = response as List;

      final Map<String, int> enrollmentsByDate = {};
      for (final e in enrollments) {
        final date = DateTime.parse(e['enrolled_at'] as String);
        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        enrollmentsByDate[dateKey] = (enrollmentsByDate[dateKey] ?? 0) + 1;
      }

      final result = enrollmentsByDate.entries
          .map((e) => ChartDataPointModel(
                label: e.key,
                value: e.value.toDouble(),
                date: DateTime.parse(e.key),
              ))
          .toList()
        ..sort((a, b) => a.date!.compareTo(b.date!));

      AppLogger.success(
        '[$_tag] getInstructorEnrollmentsChart success: ${result.length} points',
      );
      return result;
    } catch (e) {
      AppLogger.e('[$_tag] getInstructorEnrollmentsChart error', e);
      rethrow;
    }
  }

  /// Get top courses by enrollments.
  Future<List<TopCourseModel>> getTopCourses({int limit = 10}) async {
    AppLogger.d('[$_tag] getTopCourses: limit=$limit');
    try {
      final response = await _client.from('courses').select('''
            id, title_ar, title_en, thumbnail_url,
            profiles!courses_instructor_id_fkey(name),
            enrollments(id, price)
          ''').limit(limit);

      final courses = response as List;

      // Calculate enrollments for each course.
      final topCourses = courses.map((c) {
        final enrollments = (c['enrollments'] as List?) ?? [];
        final enrollmentsCount = enrollments.length;
        final revenue = enrollments.fold<double>(
            0, (sum, e) => sum + ((e['price'] as num?)?.toDouble() ?? 0));

        return TopCourseModel(
          id: c['id'] as String,
          titleAr: c['title_ar'] as String? ?? '',
          titleEn: c['title_en'] as String? ?? '',
          thumbnailUrl: c['thumbnail_url'] as String?,
          instructorName: c['profiles']?['name'] as String? ?? '',
          enrollmentsCount: enrollmentsCount,
          revenue: revenue,
          rating: 0, // Rating will be calculated from reviews if needed
        );
      }).toList()
        ..sort((a, b) => b.enrollmentsCount.compareTo(a.enrollmentsCount));

      AppLogger.success(
          '[$_tag] getTopCourses success: ${topCourses.length} courses');
      return topCourses.take(limit).toList();
    } catch (e) {
      AppLogger.e('[$_tag] getTopCourses error', e);
      rethrow;
    }
  }

  /// Get instructors by activity.
  Future<List<TopInstructorModel>> getTopInstructors({int limit = 10}) async {
    AppLogger.d('[$_tag] getTopInstructors: limit=$limit');
    try {
      final response = await _client.from('profiles').select('''
            id, name, avatar_url,
            courses!courses_instructor_id_fkey(
              id,
              enrollments(id, price)
            )
          ''').eq('role', 'instructor').limit(limit);

      final instructors = response as List;

      // Calculate stats for each instructor
      final topInstructors = instructors.map((i) {
        final courses = (i['courses'] as List?) ?? [];
        final coursesCount = courses.length;

        // Calculate total students and keep revenue only for legacy model shape.
        int totalStudents = 0;
        double totalRevenue = 0;

        for (final course in courses) {
          final enrollments = (course['enrollments'] as List?) ?? [];
          totalStudents += enrollments.length;
          totalRevenue += enrollments.fold<double>(
              0, (sum, e) => sum + ((e['price'] as num?)?.toDouble() ?? 0));
        }

        return TopInstructorModel(
          id: i['id'] as String,
          name: i['name'] as String? ?? '',
          avatarUrl: i['avatar_url'] as String?,
          coursesCount: coursesCount,
          studentsCount: totalStudents,
          totalRevenue: totalRevenue,
          rating: 0,
        );
      }).toList()
        ..sort((a, b) {
          final students = b.studentsCount.compareTo(a.studentsCount);
          if (students != 0) return students;
          return b.coursesCount.compareTo(a.coursesCount);
        });

      AppLogger.success(
          '[$_tag] getTopInstructors success: ${topInstructors.length} instructors');
      return topInstructors.take(limit).toList();
    } catch (e) {
      AppLogger.e('[$_tag] getTopInstructors error', e);
      rethrow;
    }
  }
}
