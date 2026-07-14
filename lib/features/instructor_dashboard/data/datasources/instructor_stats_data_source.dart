import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/repositories/instructor_repository.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/instructor_models.dart';

/// Instructor Stats Data Source - Dashboard statistics and charts
class InstructorStatsDataSource {
  final SupabaseClient _client;
  static const _tag = 'InstructorStatsDS';

  InstructorStatsDataSource(this._client);

  String get _userId => _client.auth.currentUser!.id;
  String? _cachedTeacherId;

  Future<String> _currentTeacherId() async {
    final cached = _cachedTeacherId;
    if (cached != null) return cached;

    final teacher = await _client
        .from('teachers')
        .select('id')
        .eq('profile_id', _userId)
        .maybeSingle();

    final teacherId = teacher?['id'] as String? ?? _userId;
    _cachedTeacherId = teacherId;
    return teacherId;
  }

  /// Get dashboard statistics
  Future<InstructorDashboardStatsModel> getDashboardStats() async {
    AppLogger.d('[$_tag] getDashboardStats: calculating from teacher_id data');
    return _calculateStatsFallback();
  }

  /// Fallback method to calculate stats manually
  Future<InstructorDashboardStatsModel> _calculateStatsFallback() async {
    try {
      final teacherId = await _currentTeacherId();
      final coursesResponse = await _client
          .from('courses')
          .select('id, is_published')
          .eq('teacher_id', teacherId);
      final courses = coursesResponse as List;
      final totalCourses = courses.length;
      final publishedCourses =
          courses.where((c) => c['is_published'] == true).length;

      final enrollmentsResponse = await _client
          .from('enrollments')
          .select('id, user_id')
          .eq('teacher_id', teacherId);
      final enrollments = enrollmentsResponse as List;
      final totalEnrollments = enrollments.length;
      final uniqueStudents =
          enrollments.map((e) => e['user_id']).toSet().length;

      final reviewsResponse = await _client
          .from('course_reviews')
          .select('rating, course:courses!inner(teacher_id)')
          .eq('course.teacher_id', teacherId);
      final reviews = reviewsResponse as List;
      final totalReviews = reviews.length;
      final avgRating = reviews.isEmpty
          ? 0.0
          : reviews
                  .map((r) => (r['rating'] as num).toDouble())
                  .reduce((a, b) => a + b) /
              reviews.length;

      return InstructorDashboardStatsModel(
        totalCourses: totalCourses,
        publishedCourses: publishedCourses,
        totalStudents: uniqueStudents,
        totalEnrollments: totalEnrollments,
        monthlyEnrollments: 0,
        totalEarnings: 0,
        availableBalance: 0,
        pendingBalance: 0,
        averageRating: avgRating,
        totalReviews: totalReviews,
        unansweredQuestions: 0,
      );
    } catch (e) {
      AppLogger.e('[$_tag] Fallback stats calculation failed', e);
      return const InstructorDashboardStatsModel(
        totalCourses: 0,
        publishedCourses: 0,
        totalStudents: 0,
        totalEnrollments: 0,
        monthlyEnrollments: 0,
        totalEarnings: 0,
        availableBalance: 0,
        pendingBalance: 0,
        averageRating: 0,
        totalReviews: 0,
        unansweredQuestions: 0,
      );
    }
  }

  /// Get revenue chart data
  Future<List<ChartDataPoint>> getRevenueChart(
      DateTime start, DateTime end) async {
    AppLogger.d('[$_tag] getRevenueChart: start=$start, end=$end');
    try {
      final teacherId = await _currentTeacherId();
      final response = await _client
          .from('manual_purchase_request_items')
          .select(
              'price, discount, parent_enrollments!inner(payment_status, paid_at)')
          .eq('teacher_id', teacherId)
          .eq('parent_enrollments.payment_status', 'paid')
          .gte('parent_enrollments.paid_at', start.toIso8601String())
          .lte('parent_enrollments.paid_at', end.toIso8601String());

      final totalsByDate = <String, double>{};
      for (final row in response as List) {
        final parent = row['parent_enrollments'] as Map<String, dynamic>?;
        final paidAt = parent?['paid_at'] as String?;
        if (paidAt == null) continue;

        final date = paidAt.substring(0, 10);
        final price = (row['price'] as num?)?.toDouble() ?? 0;
        final discount = (row['discount'] as num?)?.toDouble() ?? 0;
        totalsByDate[date] = (totalsByDate[date] ?? 0) + (price - discount);
      }

      final dataPoints = totalsByDate.entries
          .map((e) => ChartDataPoint(label: e.key, value: e.value))
          .toList()
        ..sort((a, b) => a.label.compareTo(b.label));

      AppLogger.success('[$_tag] getRevenueChart: ${dataPoints.length} points');
      return dataPoints;
    } catch (e, s) {
      AppLogger.e('[$_tag] getRevenueChart error', e, s);
      return [];
    }
  }

  /// Get enrollments chart data
  Future<List<ChartDataPoint>> getEnrollmentsChart(
      DateTime start, DateTime end) async {
    AppLogger.d('[$_tag] getEnrollmentsChart: start=$start, end=$end');
    return _getEnrollmentsChartFallback(start, end);
  }

  Future<List<ChartDataPoint>> _getEnrollmentsChartFallback(
      DateTime start, DateTime end) async {
    try {
      final teacherId = await _currentTeacherId();
      final response = await _client
          .from('enrollments')
          .select('enrolled_at')
          .eq('teacher_id', teacherId)
          .gte('enrolled_at', start.toIso8601String())
          .lte('enrolled_at', end.toIso8601String());

      final Map<String, int> countByDate = {};
      for (final enrollment in (response as List)) {
        final enrolledAt = enrollment['enrolled_at'] as String?;
        if (enrolledAt != null) {
          final date = enrolledAt.substring(0, 10);
          countByDate[date] = (countByDate[date] ?? 0) + 1;
        }
      }

      final dataPoints = countByDate.entries.map((e) {
        return ChartDataPoint(label: e.key, value: e.value.toDouble());
      }).toList();

      dataPoints.sort((a, b) => a.label.compareTo(b.label));
      AppLogger.success(
          '[$_tag] getEnrollmentsChart fallback: ${dataPoints.length} points');
      return dataPoints;
    } catch (e2, s2) {
      AppLogger.e('[$_tag] getEnrollmentsChart fallback error', e2, s2);
      return [];
    }
  }
}
