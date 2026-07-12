import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/features/student/payments_history/domain/entities/payment_entity.dart';
import 'package:lms_platform/features/student/payments_history/domain/repositories/payments_repository.dart';
import 'package:lms_platform/features/student/payments_history/data/datasources/payments_remote_data_source.dart';

class PaymentsRepositoryImpl implements PaymentsRepository {
  final PaymentsRemoteDataSource remoteDataSource;

  PaymentsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<PaymentEntity>>> getUserPayments(
      String userId) async {
    try {
      final payments = await remoteDataSource.getUserPayments(userId);
      return Right(payments);
    } catch (e) {
      return const Left(ServerFailure('Unable to load orders right now.'));
    }
  }

  @override
  Future<Either<Failure, PaymentEntity?>> getPaymentById(
      String paymentId) async {
    try {
      final payment = await remoteDataSource.getPaymentById(paymentId);
      return Right(payment);
    } catch (e) {
      return const Left(
          ServerFailure('Unable to load order details right now.'));
    }
  }
}
