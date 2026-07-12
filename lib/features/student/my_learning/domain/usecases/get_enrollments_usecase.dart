import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/my_learning/domain/entities/enrollment_entity.dart';
import 'package:lms_platform/features/student/my_learning/domain/repositories/my_learning_repository.dart';

/// Get Enrollments Use Case Parameters
class GetEnrollmentsParams {
  final String userId;
  final EnrollmentStatus? status;
  final int page;
  final int limit;

  const GetEnrollmentsParams({
    required this.userId,
    this.status,
    this.page = 1,
    this.limit = 20,
  });
}

/// Get Enrollments Use Case
class GetEnrollmentsUseCase
    extends UseCaseWithParams<List<EnrollmentEntity>, GetEnrollmentsParams> {
  final MyLearningRepository repository;

  GetEnrollmentsUseCase(this.repository);

  @override
  Future<Either<Failure, List<EnrollmentEntity>>> call(
    GetEnrollmentsParams params,
  ) {
    return repository.getEnrollments(
      userId: params.userId,
      status: params.status,
      page: params.page,
      limit: params.limit,
    );
  }
}
