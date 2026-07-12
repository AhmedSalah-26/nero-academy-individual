import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/auth/domain/entities/user_entity.dart';
import 'package:lms_platform/features/student/auth/domain/repositories/auth_repository.dart';

class UpdateInterestsUseCase
    implements UseCaseWithParams<UserEntity, List<String>> {
  final AuthRepository repository;

  UpdateInterestsUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(List<String> interests) {
    return repository.updateInterests(interests);
  }
}
