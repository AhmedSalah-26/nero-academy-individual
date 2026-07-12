import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/features/student/payments_history/domain/entities/payment_entity.dart';
import 'package:lms_platform/features/student/payments_history/domain/repositories/payments_repository.dart';

class GetUserPaymentsUseCase {
  final PaymentsRepository repository;

  GetUserPaymentsUseCase(this.repository);

  Future<Either<Failure, List<PaymentEntity>>> call(String userId) async {
    return await repository.getUserPayments(userId);
  }
}
