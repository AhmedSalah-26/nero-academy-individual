import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/errors/exceptions.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/features/student/quizzes/data/models/quiz_model.dart';
import 'package:lms_platform/features/student/quizzes/data/models/quiz_question_model.dart';
import 'package:lms_platform/features/student/quizzes/data/models/quiz_attempt_model.dart';

/// Quizzes Remote Data Source - Handles API calls
abstract class QuizzesRemoteDataSource {
  Future<List<QuizModel>> getCourseQuizzes({required String courseId});
  Future<QuizModel> getQuiz({required String quizId});
  Future<QuizModel?> getQuizByLessonId({required String lessonId});
  Future<List<QuizQuestionModel>> getQuizQuestions({
    required String quizId,
    bool shuffle,
  });
  Future<List<QuizAttemptModel>> getQuizAttempts({
    required String quizId,
    required String enrollmentId,
  });
  Future<QuizAttemptModel> startQuizAttempt({
    required String quizId,
    required String enrollmentId,
  });
  Future<QuizAttemptModel> submitQuiz({
    required String attemptId,
    required Map<String, List<String>> answers,
    required int timeSpentSeconds,
  });
  Future<QuizAttemptModel> getAttemptDetails({required String attemptId});
  Future<int> getRemainingAttempts({
    required String quizId,
    required String enrollmentId,
  });
}

/// Quizzes Remote Data Source Implementation
class QuizzesRemoteDataSourceImpl implements QuizzesRemoteDataSource {
  final SupabaseClient supabaseClient;

  QuizzesRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<QuizModel>> getCourseQuizzes({required String courseId}) async {
    try {
      final response = await supabaseClient
          .from('quizzes')
          .select('*, quiz_questions(count)')
          .eq('course_id', courseId)
          .eq('is_published', true)
          .order('created_at');

      return (response as List).map((q) {
        final questionsCount = q['quiz_questions'] as List?;
        final count = questionsCount?.isNotEmpty == true
            ? questionsCount!.first['count'] as int? ?? 0
            : 0;
        return QuizModel.fromJson({...q, 'total_questions': count});
      }).toList();
    } catch (e) {
      throw ServerException('فشل في تحميل اختبارات الكورس: $e');
    }
  }

  @override
  Future<QuizModel> getQuiz({required String quizId}) async {
    try {
      final response = await supabaseClient
          .from('quizzes')
          .select('*, quiz_questions(count)')
          .eq('id', quizId)
          .single();

      final questionsCount = response['quiz_questions'] as List?;
      final count = questionsCount?.isNotEmpty == true
          ? questionsCount!.first['count'] as int? ?? 0
          : 0;

      return QuizModel.fromJson({
        ...response,
        'total_questions': count,
      });
    } catch (e) {
      throw ServerException('فشل في تحميل بيانات الاختبار: $e');
    }
  }

  @override
  Future<QuizModel?> getQuizByLessonId({required String lessonId}) async {
    try {
      final response = await supabaseClient
          .from('quizzes')
          .select('*, quiz_questions(count)')
          .eq('lesson_id', lessonId)
          .eq('is_published', true)
          .maybeSingle();

      if (response == null) return null;

      final questionsCount = response['quiz_questions'] as List?;
      final count = questionsCount?.isNotEmpty == true
          ? questionsCount!.first['count'] as int? ?? 0
          : 0;

      return QuizModel.fromJson({
        ...response,
        'total_questions': count,
      });
    } catch (e) {
      throw ServerException('فشل في تحميل بيانات الاختبار: $e');
    }
  }

  @override
  Future<List<QuizQuestionModel>> getQuizQuestions({
    required String quizId,
    bool shuffle = false,
  }) async {
    try {
      final response = await supabaseClient
          .from('quiz_questions')
          .select()
          .eq('quiz_id', quizId)
          .order('sort_order');

      var questions = (response as List)
          .map((q) => QuizQuestionModel.fromJson(q as Map<String, dynamic>))
          .toList();

      if (shuffle) {
        questions.shuffle();
      }

      return questions;
    } catch (e) {
      throw ServerException('فشل في تحميل أسئلة الاختبار: $e');
    }
  }

  @override
  Future<List<QuizAttemptModel>> getQuizAttempts({
    required String quizId,
    required String enrollmentId,
  }) async {
    try {
      final response = await supabaseClient
          .from('quiz_attempts')
          .select()
          .eq('quiz_id', quizId)
          .eq('enrollment_id', enrollmentId)
          .order('started_at', ascending: false);

      return (response as List)
          .map((a) => QuizAttemptModel.fromJson(a))
          .toList();
    } catch (e) {
      throw ServerException('فشل في تحميل محاولات الاختبار: $e');
    }
  }

  @override
  Future<QuizAttemptModel> startQuizAttempt({
    required String quizId,
    required String enrollmentId,
  }) async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw const ServerException('المستخدم غير مسجل الدخول');
      }

      final quiz = await getQuiz(quizId: quizId);
      if (!quiz.isAvailableNow) {
        throw const ServerException('Quiz is not available now');
      }

      final response = await supabaseClient.from('quiz_attempts').insert({
        'quiz_id': quizId,
        'enrollment_id': enrollmentId,
        'user_id': userId,
        'started_at': DateTime.now().toIso8601String(),
      }).select();

      if (response.isEmpty) {
        throw const ServerException('فشل في إنشاء محاولة الاختبار');
      }

      return QuizAttemptModel.fromJson(response.first);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('فشل في بدء الاختبار: $e');
    }
  }

  @override
  Future<QuizAttemptModel> submitQuiz({
    required String attemptId,
    required Map<String, List<String>> answers,
    required int timeSpentSeconds,
  }) async {
    try {
      AppLogger.i('📝 [QuizDataSource] submitQuiz: attemptId=$attemptId');
      AppLogger.d('📝 [QuizDataSource] answers: $answers');
      AppLogger.d('📝 [QuizDataSource] timeSpent: $timeSpentSeconds seconds');

      // Call RPC function to calculate and save results
      final response = await supabaseClient.rpc(
        'submit_quiz_attempt',
        params: {
          'p_attempt_id': attemptId,
          'p_answers': answers,
          'p_time_spent': timeSpentSeconds,
        },
      );

      AppLogger.d('📝 [QuizDataSource] submitQuiz response: $response');

      if (response == null || response['success'] != true) {
        AppLogger.e(
            '📝 [QuizDataSource] submitQuiz failed: ${response?['error']}');
        throw ServerException(response?['error'] ?? 'فشل في إرسال الاختبار');
      }

      AppLogger.success(
          '📝 [QuizDataSource] submitQuiz success - score: ${response['score']}/${response['total_points']} (${response['percentage']}%)');

      // Get the updated attempt details
      return getAttemptDetails(attemptId: attemptId);
    } catch (e) {
      AppLogger.e('📝 [QuizDataSource] submitQuiz error: $e');
      if (e is ServerException) rethrow;
      throw ServerException('فشل في إرسال الاختبار: $e');
    }
  }

  @override
  Future<QuizAttemptModel> getAttemptDetails({
    required String attemptId,
  }) async {
    try {
      final response = await supabaseClient
          .from('quiz_attempts')
          .select()
          .eq('id', attemptId)
          .single();

      return QuizAttemptModel.fromJson(response);
    } catch (e) {
      throw ServerException('فشل في تحميل تفاصيل المحاولة: $e');
    }
  }

  @override
  Future<int> getRemainingAttempts({
    required String quizId,
    required String enrollmentId,
  }) async {
    try {
      // Get quiz max attempts
      final quiz = await getQuiz(quizId: quizId);
      if (!quiz.hasAttemptLimit) return -1; // Unlimited

      // Get completed attempts count
      final response = await supabaseClient
          .from('quiz_attempts')
          .select('id')
          .eq('quiz_id', quizId)
          .eq('enrollment_id', enrollmentId)
          .not('completed_at', 'is', null);

      final completedCount = (response as List).length;
      return quiz.maxAttempts! - completedCount;
    } catch (e) {
      throw ServerException('فشل في حساب المحاولات المتبقية: $e');
    }
  }
}
