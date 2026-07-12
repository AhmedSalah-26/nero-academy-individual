import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/my_learning/domain/entities/learning_progress_entity.dart';
import 'package:lms_platform/features/student/my_learning/domain/repositories/my_learning_repository.dart';

/// Update Progress Use Case Parameters
class UpdateProgressParams {
  final String enrollmentId;
  final String lessonId;
  final int watchedSeconds;
  final bool isCompleted;

  const UpdateProgressParams({
    required this.enrollmentId,
    required this.lessonId,
    required this.watchedSeconds,
    this.isCompleted = false,
  });
}

/// Update Progress Use Case
class UpdateProgressUseCase
    extends UseCaseWithParams<LearningProgressEntity, UpdateProgressParams> {
  final MyLearningRepository repository;

  UpdateProgressUseCase(this.repository);

  @override
  Future<Either<Failure, LearningProgressEntity>> call(
    UpdateProgressParams params,
  ) {
    return repository.updateLessonProgress(
      enrollmentId: params.enrollmentId,
      lessonId: params.lessonId,
      watchedSeconds: params.watchedSeconds,
      isCompleted: params.isCompleted,
    );
  }
}
