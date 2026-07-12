import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/auth/domain/repositories/auth_repository.dart';

class ForgotPasswordUseCase implements UseCaseWithParams<void, String> {
  final AuthRepository repository;

  ForgotPasswordUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String email) {
    return repository.forgotPassword(email);
  }
}
