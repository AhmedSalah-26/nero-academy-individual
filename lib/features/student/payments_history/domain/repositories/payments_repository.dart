import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/features/student/payments_history/domain/entities/payment_entity.dart';

abstract class PaymentsRepository {
  Future<Either<Failure, List<PaymentEntity>>> getUserPayments(String userId);
  Future<Either<Failure, PaymentEntity?>> getPaymentById(String paymentId);
}
