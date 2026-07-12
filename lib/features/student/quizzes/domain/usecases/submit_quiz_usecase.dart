import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/quizzes/domain/entities/quiz_attempt_entity.dart';
import 'package:lms_platform/features/student/quizzes/domain/repositories/quizzes_repository.dart';

/// Submit Quiz UseCase
class SubmitQuizUseCase
    extends UseCaseWithParams<QuizAttemptEntity, SubmitQuizParams> {
  final QuizzesRepository repository;

  SubmitQuizUseCase(this.repository);

  @override
  Future<Either<Failure, QuizAttemptEntity>> call(SubmitQuizParams params) {
    return repository.submitQuiz(
      attemptId: params.attemptId,
      answers: params.answers,
      timeSpentSeconds: params.timeSpentSeconds,
    );
  }
}

/// Submit Quiz Parameters
class SubmitQuizParams {
  final String attemptId;
  final Map<String, List<String>> answers;
  final int timeSpentSeconds;

  const SubmitQuizParams({
    required this.attemptId,
    required this.answers,
    required this.timeSpentSeconds,
  });
}
