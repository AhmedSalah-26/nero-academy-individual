import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/error_handler.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/network/network_info.dart';
import 'package:lms_platform/features/student/quizzes/domain/entities/quiz_entity.dart';
import 'package:lms_platform/features/student/quizzes/domain/entities/quiz_question_entity.dart';
import 'package:lms_platform/features/student/quizzes/domain/entities/quiz_attempt_entity.dart';
import 'package:lms_platform/features/student/quizzes/domain/repositories/quizzes_repository.dart';
import 'package:lms_platform/features/student/quizzes/data/datasources/quizzes_remote_data_source.dart';
import 'package:lms_platform/features/student/quizzes/data/datasources/quizzes_local_data_source.dart';

/// Quizzes Repository Implementation
class QuizzesRepositoryImpl implements QuizzesRepository {
  final QuizzesRemoteDataSource remoteDataSource;
  final QuizzesLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  QuizzesRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<QuizEntity>>> getCourseQuizzes({
    required String courseId,
  }) async {
    try {
      final quizzes = await remoteDataSource.getCourseQuizzes(
        courseId: courseId,
      );
      return Right(quizzes);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  @override
  Future<Either<Failure, QuizEntity>> getQuiz({
    required String quizId,
  }) async {
    try {
      final quiz = await remoteDataSource.getQuiz(quizId: quizId);
      return Right(quiz);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  @override
  Future<Either<Failure, QuizEntity?>> getQuizByLessonId({
    required String lessonId,
  }) async {
    try {
      final quiz = await remoteDataSource.getQuizByLessonId(
        lessonId: lessonId,
      );
      return Right(quiz);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  @override
  Future<Either<Failure, List<QuizQuestionEntity>>> getQuizQuestions({
    required String quizId,
    bool shuffle = false,
  }) async {
    try {
      final questions = await remoteDataSource.getQuizQuestions(
        quizId: quizId,
        shuffle: shuffle,
      );
      return Right(questions);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  @override
  Future<Either<Failure, List<QuizAttemptEntity>>> getQuizAttempts({
    required String quizId,
    required String enrollmentId,
  }) async {
    try {
      final attempts = await remoteDataSource.getQuizAttempts(
        quizId: quizId,
        enrollmentId: enrollmentId,
      );
      return Right(attempts);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  @override
  Future<Either<Failure, QuizAttemptEntity>> startQuizAttempt({
    required String quizId,
    required String enrollmentId,
  }) async {
    try {
      final attempt = await remoteDataSource.startQuizAttempt(
        quizId: quizId,
        enrollmentId: enrollmentId,
      );

      // Cache start time locally
      await localDataSource.cacheQuizStartTime(
        attemptId: attempt.id,
        startTime: DateTime.now(),
      );

      return Right(attempt);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  @override
  Future<Either<Failure, QuizAttemptEntity>> submitQuiz({
    required String attemptId,
    required Map<String, List<String>> answers,
    required int timeSpentSeconds,
  }) async {
    try {
      final result = await remoteDataSource.submitQuiz(
        attemptId: attemptId,
        answers: answers,
        timeSpentSeconds: timeSpentSeconds,
      );

      // Clear cached answers
      await localDataSource.clearCachedAnswers(attemptId: attemptId);

      return Right(result);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  @override
  Future<Either<Failure, QuizAttemptEntity>> getAttemptDetails({
    required String attemptId,
  }) async {
    try {
      final attempt = await remoteDataSource.getAttemptDetails(
        attemptId: attemptId,
      );
      return Right(attempt);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  @override
  Future<Either<Failure, int>> getRemainingAttempts({
    required String quizId,
    required String enrollmentId,
  }) async {
    try {
      final remaining = await remoteDataSource.getRemainingAttempts(
        quizId: quizId,
        enrollmentId: enrollmentId,
      );
      return Right(remaining);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }
}
