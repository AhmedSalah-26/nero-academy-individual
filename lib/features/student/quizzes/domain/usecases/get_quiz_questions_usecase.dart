import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/quizzes/domain/entities/quiz_question_entity.dart';
import 'package:lms_platform/features/student/quizzes/domain/repositories/quizzes_repository.dart';

/// Get Quiz Questions UseCase
class GetQuizQuestionsUseCase extends UseCaseWithParams<
    List<QuizQuestionEntity>, GetQuizQuestionsParams> {
  final QuizzesRepository repository;

  GetQuizQuestionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<QuizQuestionEntity>>> call(
    GetQuizQuestionsParams params,
  ) {
    return repository.getQuizQuestions(
      quizId: params.quizId,
      shuffle: params.shuffle,
    );
  }
}

/// Get Quiz Questions Parameters
class GetQuizQuestionsParams {
  final String quizId;
  final bool shuffle;

  const GetQuizQuestionsParams({
    required this.quizId,
    this.shuffle = false,
  });
}
