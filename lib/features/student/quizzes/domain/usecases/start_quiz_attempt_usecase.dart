import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/quizzes/domain/entities/quiz_attempt_entity.dart';
import 'package:lms_platform/features/student/quizzes/domain/repositories/quizzes_repository.dart';

/// Start Quiz Attempt UseCase
class StartQuizAttemptUseCase
    extends UseCaseWithParams<QuizAttemptEntity, StartQuizAttemptParams> {
  final QuizzesRepository repository;

  StartQuizAttemptUseCase(this.repository);

  @override
  Future<Either<Failure, QuizAttemptEntity>> call(
    StartQuizAttemptParams params,
  ) {
    return repository.startQuizAttempt(
      quizId: params.quizId,
      enrollmentId: params.enrollmentId,
    );
  }
}

/// Start Quiz Attempt Parameters
class StartQuizAttemptParams {
  final String quizId;
  final String enrollmentId;

  const StartQuizAttemptParams({
    required this.quizId,
    required this.enrollmentId,
  });
}
