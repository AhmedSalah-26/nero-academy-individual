import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/app_logger.dart';
import '../../domain/entities/instructor_entities.dart';
import '../models/instructor_models.dart';

/// Instructor Q&A Data Source - Q&A management
class InstructorQADataSource {
  final SupabaseClient _client;
  static const _tag = 'InstructorQADS';

  InstructorQADataSource(this._client);

  String get _userId => _client.auth.currentUser!.id;

  /// Get questions
  Future<List<InstructorQuestionModel>> getQuestions({
    QAStatus? status,
    String? courseId,
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.d('[$_tag] getQuestions: status=$status, courseId=$courseId');
    try {
      var query = _client.from('qa_questions').select('''
            *, 
            course:courses!inner(title_ar, instructor_id), 
            lesson:lessons(title_ar), 
            user:profiles(name, avatar_url),
            qa_answers(
              *,
              user:profiles(name, avatar_url)
            )
          ''').eq('course.instructor_id', _userId);

      if (courseId != null) query = query.eq('course_id', courseId);
      if (status != null && status != QAStatus.all) {
        if (status == QAStatus.unanswered) {
          query = query.eq('is_answered', false);
        } else {
          query = query.eq('is_answered', true);
        }
      }

      final response = await query
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      AppLogger.success(
          '[$_tag] getQuestions: ${(response as List).length} questions');
      return response.map((e) => InstructorQuestionModel.fromJson(e)).toList();
    } catch (e, s) {
      AppLogger.e('[$_tag] getQuestions error', e, s);
      rethrow;
    }
  }

  /// Answer question
  Future<bool> answerQuestion(String questionId, String answer) async {
    AppLogger.d('[$_tag] answerQuestion: questionId=$questionId');
    try {
      await _client.from('qa_answers').insert({
        'question_id': questionId,
        'user_id': _userId,
        'content': answer,
        'is_instructor_answer': true,
      });

      await _client.from('qa_questions').update({
        'is_answered': true,
      }).eq('id', questionId);

      AppLogger.success('[$_tag] answerQuestion success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] answerQuestion error', e, s);
      rethrow;
    }
  }

  /// Update an answer
  Future<bool> updateAnswer(String answerId, String newContent) async {
    AppLogger.d('[$_tag] updateAnswer: answerId=$answerId');
    try {
      await _client
          .from('qa_answers')
          .update({
            'content': newContent,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', answerId)
          .eq('user_id', _userId);
      AppLogger.success('[$_tag] updateAnswer success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] updateAnswer error', e, s);
      rethrow;
    }
  }

  /// Delete an answer
  Future<bool> deleteAnswer(String answerId) async {
    AppLogger.d('[$_tag] deleteAnswer: answerId=$answerId');
    try {
      await _client
          .from('qa_answers')
          .delete()
          .eq('id', answerId)
          .eq('user_id', _userId);
      AppLogger.success('[$_tag] deleteAnswer success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] deleteAnswer error', e, s);
      rethrow;
    }
  }

  /// Hide a question (instructor moderation)
  Future<bool> hideQuestion(String questionId) async {
    AppLogger.d('[$_tag] hideQuestion: $questionId');
    try {
      await _client.from('qa_questions').update({
        'is_visible': false,
      }).eq('id', questionId);
      AppLogger.success('[$_tag] hideQuestion success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] hideQuestion error', e, s);
      rethrow;
    }
  }

  /// Pin a question
  Future<bool> pinQuestion(String questionId, bool isPinned) async {
    AppLogger.d('[$_tag] pinQuestion: $questionId, isPinned=$isPinned');
    try {
      await _client.from('qa_questions').update({
        'is_pinned': isPinned,
      }).eq('id', questionId);
      AppLogger.success('[$_tag] pinQuestion success');
      return true;
    } catch (e, s) {
      AppLogger.e('[$_tag] pinQuestion error', e, s);
      rethrow;
    }
  }
}
