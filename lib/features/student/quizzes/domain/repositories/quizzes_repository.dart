import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/features/student/quizzes/domain/entities/quiz_entity.dart';
import 'package:lms_platform/features/student/quizzes/domain/entities/quiz_question_entity.dart';
import 'package:lms_platform/features/student/quizzes/domain/entities/quiz_attempt_entity.dart';

/// Quizzes Repository - Abstract Contract
abstract class QuizzesRepository {
  /// Get all quizzes for a course
  Future<Either<Failure, List<QuizEntity>>> getCourseQuizzes({
    required String courseId,
  });

  /// Get quiz details
  Future<Either<Failure, QuizEntity>> getQuiz({
    required String quizId,
  });

  /// Get quiz by lesson ID
  Future<Either<Failure, QuizEntity?>> getQuizByLessonId({
    required String lessonId,
  });

  /// Get quiz questions
  Future<Either<Failure, List<QuizQuestionEntity>>> getQuizQuestions({
    required String quizId,
    bool shuffle,
  });

  /// Get previous quiz attempts
  Future<Either<Failure, List<QuizAttemptEntity>>> getQuizAttempts({
    required String quizId,
    required String enrollmentId,
  });

  /// Start a new quiz attempt
  Future<Either<Failure, QuizAttemptEntity>> startQuizAttempt({
    required String quizId,
    required String enrollmentId,
  });

  /// Submit quiz answers
  Future<Either<Failure, QuizAttemptEntity>> submitQuiz({
    required String attemptId,
    required Map<String, List<String>> answers,
    required int timeSpentSeconds,
  });

  /// Get single attempt details
  Future<Either<Failure, QuizAttemptEntity>> getAttemptDetails({
    required String attemptId,
  });

  /// Check remaining attempts
  Future<Either<Failure, int>> getRemainingAttempts({
    required String quizId,
    required String enrollmentId,
  });
}
