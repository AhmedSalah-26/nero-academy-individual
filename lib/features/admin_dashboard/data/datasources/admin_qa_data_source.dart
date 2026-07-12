import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/app_logger.dart';

/// Admin Q&A Data Source - Q&A management
class AdminQADataSource {
  final SupabaseClient _client;
  static const _tag = 'AdminQADS';

  AdminQADataSource(this._client);

  /// Get all questions with filtering
  Future<List<Map<String, dynamic>>> getAllQuestions({
    String? courseId,
    bool? isAnswered,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.d('[$_tag] getAllQuestions: courseId=$courseId, page=$page');
    try {
      var query = _client.from('qa_questions').select('''
        *, 
        course:courses(title_ar, title_en),
        lesson:lessons(title_ar),
        user:profiles(name, avatar_url),
        qa_answers(
          *,
          user:profiles(name, avatar_url)
        )
      ''');

      if (courseId != null) query = query.eq('course_id', courseId);
      if (isAnswered != null) query = query.eq('is_answered', isAnswered);

      final response = await query
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      var results = response as List;

      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        results = results.where((r) {
          final title = (r['title'] as String?)?.toLowerCase() ?? '';
          final content = (r['content'] as String?)?.toLowerCase() ?? '';
          final userName = (r['user']?['name'] as String?)?.toLowerCase() ?? '';
          return title.contains(searchLower) ||
              content.contains(searchLower) ||
              userName.contains(searchLower);
        }).toList();
      }

      AppLogger.success('[$_tag] getAllQuestions: ${results.length} questions');
      return results.cast<Map<String, dynamic>>();
    } catch (e, s) {
      AppLogger.e('[$_tag] getAllQuestions error', e, s);
      rethrow;
    }
  }

  /// Delete a question
  Future<bool> deleteQuestion(String questionId) async {
    AppLogger.d('[$_tag] deleteQuestion: $questionId');
    try {
      await _client.from('qa_questions').delete().eq('id', questionId);
      AppLogger.success('[$_tag] deleteQuestion success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteQuestion error', e, s);
      rethrow;
    }
  }

  /// Delete an answer
  Future<bool> deleteAnswer(String answerId) async {
    AppLogger.d('[$_tag] deleteAnswer: $answerId');
    try {
      await _client.from('qa_answers').delete().eq('id', answerId);
      AppLogger.success('[$_tag] deleteAnswer success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteAnswer error', e, s);
      rethrow;
    }
  }

  /// Hide a question
  Future<bool> hideQuestion(String questionId) async {
    AppLogger.d('[$_tag] hideQuestion: $questionId');
    try {
      await _client.from('qa_questions').update({
        'is_hidden': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', questionId);
      AppLogger.success('[$_tag] hideQuestion success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] hideQuestion error', e, s);
      rethrow;
    }
  }

  /// Unhide a question
  Future<bool> unhideQuestion(String questionId) async {
    AppLogger.d('[$_tag] unhideQuestion: $questionId');
    try {
      await _client.from('qa_questions').update({
        'is_hidden': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', questionId);
      AppLogger.success('[$_tag] unhideQuestion success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] unhideQuestion error', e, s);
      rethrow;
    }
  }
}
