import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/auth/domain/repositories/auth_repository.dart';

class SendPhoneOtpUseCase implements UseCaseWithParams<void, String> {
  final AuthRepository repository;

  SendPhoneOtpUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String phoneNumber) async {
    return await repository.sendPhoneOtp(phoneNumber);
  }

  /// إرسال OTP لربط الهاتف بحساب موجود
  Future<Either<Failure, void>> sendLinkOtp(String phoneNumber) async {
    return await repository.sendLinkPhoneOtp(phoneNumber);
  }
}
