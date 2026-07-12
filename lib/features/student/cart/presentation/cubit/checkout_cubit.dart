import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lms_platform/core/base/base_state.dart';
import 'package:lms_platform/features/student/cart/domain/entities/cart_entity.dart';
import 'package:lms_platform/features/student/cart/domain/entities/payment_method_entity.dart';
import 'package:lms_platform/features/student/cart/domain/repositories/cart_repository.dart';
import 'package:lms_platform/features/student/cart/domain/usecases/checkout_usecase.dart';
import 'checkout_state.dart';

/// Checkout Cubit
class CheckoutCubit extends Cubit<CheckoutState> {
  final CheckoutUseCase checkoutUseCase;
  final CartRepository cartRepository;

  CheckoutCubit({
    required this.checkoutUseCase,
    required this.cartRepository,
  }) : super(const CheckoutState());

  String? _currentUserId;

  /// Initialize checkout with cart data
  Future<void> initCheckout(String userId, CartEntity cart) async {
    _currentUserId = userId;
    emit(state.copyWith(
      status: StateStatus.success,
      cart: cart,
      savedPaymentMethods: const [],
      selectedPaymentMethod: PaymentMethodType.manual,
      clearSavedMethodId: true,
    ));
  }

  /// Select payment method type
  void selectPaymentMethod(PaymentMethodType method) {
    emit(state.copyWith(
      selectedPaymentMethod: method,
      clearSavedMethodId: true,
    ));
  }

  /// Select saved payment method
  void selectSavedPaymentMethod(String methodId) {
    emit(state.copyWith(
      selectedPaymentMethod: PaymentMethodType.manual,
      selectedSavedMethodId: methodId,
    ));
  }

  /// Process checkout as a manual payment request.
  Future<void> processCheckout({Map<String, dynamic>? cardDetails}) async {
    if (_currentUserId == null) return;
    emit(state.copyWith(isProcessing: true));

    final result = await checkoutUseCase(
      CheckoutParams(
        userId: _currentUserId!,
        paymentMethod: PaymentMethodType.manual,
        couponId: state.cart?.appliedCoupon?.id,
        couponCode: state.cart?.appliedCoupon?.code,
        couponDiscountTotal: state.cart?.discountAmount ?? 0,
      ),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isProcessing: false,
        failure: failure,
      )),
      (order) => emit(state.copyWith(
        isProcessing: false,
        order: order,
      )),
    );
  }

  /// Reset checkout state
  void reset() {
    emit(const CheckoutState());
  }

  /// Stop processing indicator
  void stopProcessing() {
    emit(state.copyWith(isProcessing: false));
  }
}
