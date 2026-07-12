import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/my_learning/domain/entities/enrollment_entity.dart';
import 'package:lms_platform/features/student/my_learning/domain/repositories/my_learning_repository.dart';

/// Get Continue Learning Use Case
class GetContinueLearningUseCase
    extends UseCaseWithParams<EnrollmentEntity?, String> {
  final MyLearningRepository repository;

  GetContinueLearningUseCase(this.repository);

  @override
  Future<Either<Failure, EnrollmentEntity?>> call(String userId) {
    return repository.getContinueLearning(userId);
  }
}
