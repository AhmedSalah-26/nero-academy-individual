import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/instructor_models.dart';

/// Instructor Reviews Data Source - Reviews management
class InstructorReviewsDataSource {
  final SupabaseClient _client;
  static const _tag = 'InstructorReviewsDS';

  InstructorReviewsDataSource(this._client);

  String get _userId => _client.auth.currentUser!.id;

  /// Get reviews
  Future<List<InstructorReviewModel>> getReviews({
    String? courseId,
    int? minRating,
    int? maxRating,
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.d('[$_tag] getReviews: courseId=$courseId, page=$page');
    try {
      var query = _client
          .from('course_reviews')
          .select('''*, course:courses!inner(title_ar, instructor_id), 
            user:profiles(name, avatar_url)''').eq('course.instructor_id', _userId);

      if (courseId != null) query = query.eq('course_id', courseId);
      if (minRating != null) query = query.gte('rating', minRating);
      if (maxRating != null) query = query.lte('rating', maxRating);

      final response = await query
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      AppLogger.success(
          '[$_tag] getReviews: ${(response as List).length} reviews');
      return response.map((e) => InstructorReviewModel.fromJson(e)).toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getReviews error', e, s);
      rethrow;
    }
  }

  /// Reply to a review
  Future<bool> replyToReview(String reviewId, String reply) async {
    AppLogger.d('[$_tag] replyToReview: reviewId=$reviewId');
    try {
      await _client.from('course_reviews').update({
        'instructor_reply': reply,
        'replied_at': DateTime.now().toIso8601String(),
      }).eq('id', reviewId);
      AppLogger.success('[$_tag] replyToReview success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] replyToReview error', e, s);
      rethrow;
    }
  }
}
