import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/auth/domain/entities/user_entity.dart';
import 'package:lms_platform/features/student/auth/domain/repositories/auth_repository.dart';

class GetCurrentUserUseCase implements UseCase<UserEntity?> {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity?>> call() {
    return repository.getCurrentUser();
  }
}
