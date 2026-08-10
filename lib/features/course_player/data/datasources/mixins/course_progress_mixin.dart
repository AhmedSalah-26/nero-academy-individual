import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../../../../../../core/services/app_logger.dart';
import '../../models/lesson_progress_model.dart';

mixin CoursePlayerProgressMixin {
  SupabaseClient get client;

  Future<LessonProgressModel?> getLessonProgress({
    required String lessonId,
    required String enrollmentId,
  }) async {
    try {
      final response = await client
          .from('lesson_progress')
          .select()
          .eq('lesson_id', lessonId)
          .eq('enrollment_id', enrollmentId)
          .maybeSingle();

      if (response == null) return null;
      return LessonProgressModel.fromJson(response);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<List<LessonProgressModel>> getAllLessonProgress({
    required String enrollmentId,
  }) async {
    try {
      final response = await client
          .from('lesson_progress')
          .select()
          .eq('enrollment_id', enrollmentId);

      return (response as List)
          .map((e) => LessonProgressModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<Set<String>> getIncompleteQuizLessonIds({
    required String courseId,
    required String enrollmentId,
  }) async {
    try {
      final quizRows = await client
          .from('quizzes')
          .select('id, lesson_id, available_until')
          .eq('course_id', courseId)
          .eq('is_published', true)
          .not('lesson_id', 'is', null);

      final now = DateTime.now().toUtc();

      // Filter out expired quizzes — if the quiz window has closed the student
      // can no longer take it, so we should not keep the lesson locked.
      final quizzes = (quizRows as List)
          .whereType<Map<String, dynamic>>()
          .where((row) {
            if (row['id'] == null || row['lesson_id'] == null) return false;
            final availableUntil = row['available_until'] as String?;
            if (availableUntil != null) {
              final until = DateTime.parse(availableUntil).toUtc();
              if (now.isAfter(until)) return false; // expired → ignore
            }
            return true;
          })
          .toList();
      if (quizzes.isEmpty) return <String>{};

      final quizIds = quizzes.map((row) => row['id'] as String).toList();
      final attemptRows = await client
          .from('quiz_attempts')
          .select('quiz_id')
          .eq('enrollment_id', enrollmentId)
          .inFilter('quiz_id', quizIds)
          .not('completed_at', 'is', null);

      final completedQuizIds = (attemptRows as List)
          .whereType<Map<String, dynamic>>()
          .map((row) => row['quiz_id'] as String?)
          .whereType<String>()
          .toSet();

      return quizzes
          .where((row) => !completedQuizIds.contains(row['id']))
          .map((row) => row['lesson_id'] as String)
          .toSet();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<LessonProgressModel> updateLessonProgress({
    required String lessonId,
    required String enrollmentId,
    required int watchedSeconds,
    required int lastPosition,
  }) async {
    try {
      AppLogger.i(
          '⏱️ [DataSource] Calling update_lesson_progress RPC: lessonId=$lessonId, watchTime=$watchedSeconds, lastPosition=$lastPosition');

      final rpcResponse = await client.rpc('update_lesson_progress', params: {
        'p_lesson_id': lessonId,
        'p_watch_time': watchedSeconds,
        'p_last_position': lastPosition,
        'p_is_completed': false,
      });

      if (rpcResponse is Map && rpcResponse['success'] == false) {
        throw ServerException(
            rpcResponse['error']?.toString() ?? 'Unknown error');
      }

      final response = await client
          .from('lesson_progress')
          .select()
          .eq('lesson_id', lessonId)
          .eq('enrollment_id', enrollmentId)
          .single();

      return LessonProgressModel.fromJson(response);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<LessonProgressModel> markLessonComplete({
    required String lessonId,
    required String enrollmentId,
  }) async {
    try {
      int currentWatchTime = 0;
      try {
        final existing = await client
            .from('lesson_progress')
            .select('watch_time')
            .eq('lesson_id', lessonId)
            .eq('enrollment_id', enrollmentId)
            .maybeSingle();
        if (existing != null) {
          currentWatchTime = existing['watch_time'] as int? ?? 0;
        }
      } catch (_) {}

      final rpcResponse = await client.rpc('update_lesson_progress', params: {
        'p_lesson_id': lessonId,
        'p_watch_time': currentWatchTime,
        'p_last_position': currentWatchTime,
        'p_is_completed': true,
      });
      if (rpcResponse is Map && rpcResponse['success'] == false) {
        throw ServerException(
          rpcResponse['error']?.toString() ??
              'Complete the lesson quizzes first',
        );
      }

      final response = await client
          .from('lesson_progress')
          .select()
          .eq('lesson_id', lessonId)
          .eq('enrollment_id', enrollmentId)
          .single();

      return LessonProgressModel.fromJson(response);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
