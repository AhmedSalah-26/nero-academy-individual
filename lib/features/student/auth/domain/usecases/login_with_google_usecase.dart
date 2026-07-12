import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/auth/domain/entities/user_entity.dart';
import 'package:lms_platform/features/student/auth/domain/repositories/auth_repository.dart';

class LoginWithGoogleUseCase implements UseCase<UserEntity> {
  final AuthRepository repository;

  LoginWithGoogleUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call() {
    return repository.loginWithGoogle();
  }
}
