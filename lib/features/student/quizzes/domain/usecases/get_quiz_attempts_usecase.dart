import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/quizzes/domain/entities/quiz_attempt_entity.dart';
import 'package:lms_platform/features/student/quizzes/domain/repositories/quizzes_repository.dart';

/// Get Quiz Attempts UseCase
class GetQuizAttemptsUseCase
    extends UseCaseWithParams<List<QuizAttemptEntity>, GetQuizAttemptsParams> {
  final QuizzesRepository repository;

  GetQuizAttemptsUseCase(this.repository);

  @override
  Future<Either<Failure, List<QuizAttemptEntity>>> call(
    GetQuizAttemptsParams params,
  ) {
    return repository.getQuizAttempts(
      quizId: params.quizId,
      enrollmentId: params.enrollmentId,
    );
  }
}

/// Get Quiz Attempts Parameters
class GetQuizAttemptsParams {
  final String quizId;
  final String enrollmentId;

  const GetQuizAttemptsParams({
    required this.quizId,
    required this.enrollmentId,
  });
}

/// Get Remaining Attempts UseCase
class GetRemainingAttemptsUseCase
    extends UseCaseWithParams<int, GetRemainingAttemptsParams> {
  final QuizzesRepository repository;

  GetRemainingAttemptsUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(GetRemainingAttemptsParams params) {
    return repository.getRemainingAttempts(
      quizId: params.quizId,
      enrollmentId: params.enrollmentId,
    );
  }
}

/// Get Remaining Attempts Parameters
class GetRemainingAttemptsParams {
  final String quizId;
  final String enrollmentId;

  const GetRemainingAttemptsParams({
    required this.quizId,
    required this.enrollmentId,
  });
}
