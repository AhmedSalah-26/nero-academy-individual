import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/app_logger.dart';

/// Admin Reviews Data Source - Reviews management
class AdminReviewsDataSource {
  final SupabaseClient _client;
  static const _tag = 'AdminReviewsDS';

  AdminReviewsDataSource(this._client);

  /// Get all reviews with filtering
  Future<List<Map<String, dynamic>>> getAllReviews({
    String? courseId,
    int? minRating,
    int? maxRating,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.d('[$_tag] getAllReviews: courseId=$courseId, page=$page');
    try {
      var query = _client.from('course_reviews').select('''
        *, 
        course:courses(title_ar, title_en),
        user:profiles(name, avatar_url, email)
      ''');

      if (courseId != null) query = query.eq('course_id', courseId);
      if (minRating != null) query = query.gte('rating', minRating);
      if (maxRating != null) query = query.lte('rating', maxRating);

      final response = await query
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      var results = response as List;

      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        results = results.where((r) {
          final comment = (r['comment'] as String?)?.toLowerCase() ?? '';
          final userName = (r['user']?['name'] as String?)?.toLowerCase() ?? '';
          return comment.contains(searchLower) ||
              userName.contains(searchLower);
        }).toList();
      }

      AppLogger.success('[$_tag] getAllReviews: ${results.length} reviews');
      return results.cast<Map<String, dynamic>>();
    } catch (e, s) {
      AppLogger.e('[$_tag] getAllReviews error', e, s);
      rethrow;
    }
  }

  /// Delete a review
  Future<bool> deleteReview(String reviewId) async {
    AppLogger.d('[$_tag] deleteReview: $reviewId');
    try {
      await _client.from('course_reviews').delete().eq('id', reviewId);
      AppLogger.success('[$_tag] deleteReview success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteReview error', e, s);
      rethrow;
    }
  }

  /// Hide a review
  Future<bool> hideReview(String reviewId) async {
    AppLogger.d('[$_tag] hideReview: $reviewId');
    try {
      await _client.from('course_reviews').update({
        'is_hidden': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', reviewId);
      AppLogger.success('[$_tag] hideReview success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] hideReview error', e, s);
      rethrow;
    }
  }

  /// Unhide a review
  Future<bool> unhideReview(String reviewId) async {
    AppLogger.d('[$_tag] unhideReview: $reviewId');
    try {
      await _client.from('course_reviews').update({
        'is_hidden': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', reviewId);
      AppLogger.success('[$_tag] unhideReview success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] unhideReview error', e, s);
      rethrow;
    }
  }
}
