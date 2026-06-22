import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/payments_repository.dart';
import '../datasources/payments_remote_data_source.dart';

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
