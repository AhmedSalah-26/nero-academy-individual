import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/cart/domain/entities/order_entity.dart';
import 'package:lms_platform/features/student/cart/domain/entities/payment_method_entity.dart';
import 'package:lms_platform/features/student/cart/domain/repositories/cart_repository.dart';

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
