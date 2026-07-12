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

  /// Get dashboard statistics
  Future<InstructorDashboardStatsModel> getDashboardStats() async {
    AppLogger.d('[$_tag] getDashboardStats: Starting RPC call');
    try {
      final response = await _client.rpc('get_instructor_dashboard_stats');
      AppLogger.d('[$_tag] getDashboardStats: Raw response: $response');

      final stats = InstructorDashboardStatsModel.fromJson(
          response as Map<String, dynamic>);
      AppLogger.success('[$_tag] getDashboardStats success');
      return stats;
    } catch (e, s) {
      AppLogger.e('[$_tag] getDashboardStats error', e, s);
      AppLogger.w('[$_tag] Using fallback stats calculation');
      return _calculateStatsFallback();
    }
  }

  /// Fallback method to calculate stats manually
  Future<InstructorDashboardStatsModel> _calculateStatsFallback() async {
    try {
      final coursesResponse = await _client
          .from('courses')
          .select('id, is_published')
          .eq('instructor_id', _userId);
      final courses = coursesResponse as List;
      final totalCourses = courses.length;
      final publishedCourses =
          courses.where((c) => c['is_published'] == true).length;

      final enrollmentsResponse = await _client
          .from('enrollments')
          .select('id, user_id, course:courses!inner(instructor_id)')
          .eq('course.instructor_id', _userId);
      final enrollments = enrollmentsResponse as List;
      final totalEnrollments = enrollments.length;
      final uniqueStudents =
          enrollments.map((e) => e['user_id']).toSet().length;

      final reviewsResponse = await _client
          .from('course_reviews')
          .select('rating, course:courses!inner(instructor_id)')
          .eq('course.instructor_id', _userId);
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
      final response =
          await _client.rpc('get_instructor_revenue_chart', params: {
        'p_start_date': start.toIso8601String(),
        'p_end_date': end.toIso8601String(),
      });

      final dataPoints = (response as List).map((e) {
        return ChartDataPoint(
          label: e['label'] as String? ?? '',
          value: (e['value'] as num?)?.toDouble() ?? 0,
        );
      }).toList();

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
    try {
      final response =
          await _client.rpc('get_instructor_enrollments_chart', params: {
        'p_start_date': start.toIso8601String(),
        'p_end_date': end.toIso8601String(),
      });

      final dataPoints = (response as List).map((e) {
        return ChartDataPoint(
          label: e['label'] as String? ?? '',
          value: (e['value'] as num?)?.toDouble() ?? 0,
        );
      }).toList();

      AppLogger.success(
          '[$_tag] getEnrollmentsChart: ${dataPoints.length} points');
      return dataPoints;
    } catch (e) {
      AppLogger.w('[$_tag] getEnrollmentsChart RPC failed, using fallback: $e');
      return _getEnrollmentsChartFallback(start, end);
    }
  }

  Future<List<ChartDataPoint>> _getEnrollmentsChartFallback(
      DateTime start, DateTime end) async {
    try {
      final response = await _client
          .from('enrollments')
          .select('enrolled_at, course:courses!inner(instructor_id)')
          .eq('course.instructor_id', _userId)
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
