import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/errors/exceptions.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/features/student/course_player/data/models/lesson_progress_model.dart';

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

      await client.rpc('update_lesson_progress', params: {
        'p_lesson_id': lessonId,
        'p_watch_time': currentWatchTime,
        'p_last_position': currentWatchTime,
        'p_is_completed': true,
      });

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
