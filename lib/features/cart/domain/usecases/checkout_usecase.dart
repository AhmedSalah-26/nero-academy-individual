import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/order_entity.dart';
import '../entities/payment_method_entity.dart';
import '../repositories/cart_repository.dart';

/// Checkout Use Case
class CheckoutUseCase extends UseCaseWithParams<OrderEntity, CheckoutParams> {
  final CartRepository repository;

  CheckoutUseCase(this.repository);

  @override
  Future<Either<Failure, OrderEntity>> call(CheckoutParams params) {
    return repository.checkout(
      userId: params.userId,
      paymentMethod: params.paymentMethod,
      savedPaymentMethodId: params.savedPaymentMethodId,
      cardDetails: params.cardDetails,
      couponId: params.couponId,
      couponCode: params.couponCode,
      couponDiscountTotal: params.couponDiscountTotal,
    );
  }
}

/// Checkout Parameters
class CheckoutParams {
  final String userId;
  final PaymentMethodType paymentMethod;
  final String? savedPaymentMethodId;
  final Map<String, dynamic>? cardDetails;
  final String? couponId;
  final String? couponCode;
  final double couponDiscountTotal;

  const CheckoutParams({
    required this.userId,
    required this.paymentMethod,
    this.savedPaymentMethodId,
    this.cardDetails,
    this.couponId,
    this.couponCode,
    this.couponDiscountTotal = 0,
  });
}
