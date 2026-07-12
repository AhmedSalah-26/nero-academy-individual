import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/quizzes/domain/entities/quiz_entity.dart';
import 'package:lms_platform/features/student/quizzes/domain/repositories/quizzes_repository.dart';

/// Get Quiz UseCase
class GetQuizUseCase extends UseCaseWithParams<QuizEntity, GetQuizParams> {
  final QuizzesRepository repository;

  GetQuizUseCase(this.repository);

  @override
  Future<Either<Failure, QuizEntity>> call(GetQuizParams params) {
    return repository.getQuiz(quizId: params.quizId);
  }
}

/// Get Quiz Parameters
class GetQuizParams {
  final String quizId;

  const GetQuizParams({required this.quizId});
}

/// Get Quiz By Lesson UseCase
class GetQuizByLessonUseCase
    extends UseCaseWithParams<QuizEntity?, GetQuizByLessonParams> {
  final QuizzesRepository repository;

  GetQuizByLessonUseCase(this.repository);

  @override
  Future<Either<Failure, QuizEntity?>> call(GetQuizByLessonParams params) {
    return repository.getQuizByLessonId(lessonId: params.lessonId);
  }
}

/// Get Quiz By Lesson Parameters
class GetQuizByLessonParams {
  final String lessonId;

  const GetQuizByLessonParams({required this.lessonId});
}
