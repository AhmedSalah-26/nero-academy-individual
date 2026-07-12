import 'package:equatable/equatable.dart';
import 'package:lms_platform/core/base/base_state.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/features/student/cart/domain/entities/cart_entity.dart';
import 'package:lms_platform/features/student/cart/domain/entities/order_entity.dart';
import 'package:lms_platform/features/student/cart/domain/entities/payment_method_entity.dart';

/// Checkout State
class CheckoutState extends Equatable {
  final StateStatus status;
  final CartEntity? cart;
  final List<SavedPaymentMethodEntity> savedPaymentMethods;
  final PaymentMethodType selectedPaymentMethod;
  final String? selectedSavedMethodId;
  final OrderEntity? order;
  final Failure? failure;
  final bool isProcessing;

  const CheckoutState({
    this.status = StateStatus.initial,
    this.cart,
    this.savedPaymentMethods = const [],
    this.selectedPaymentMethod = PaymentMethodType.card,
    this.selectedSavedMethodId,
    this.order,
    this.failure,
    this.isProcessing = false,
  });

  bool get isLoading => status == StateStatus.loading;
  bool get isSuccess => status == StateStatus.success;
  bool get isError => status == StateStatus.error;
  String? get errorMessage => failure?.message;

  double get total => cart?.total ?? 0;
  double get subtotal => cart?.subtotal ?? 0;
  double get discountAmount => cart?.discountAmount ?? 0;
  String get currency => cart?.currency ?? 'EGP';
  int get itemsCount => cart?.itemsCount ?? 0;

  bool get hasOrder => order != null;
  bool get isOrderSuccessful => order?.isSuccessful ?? false;

  CheckoutState copyWith({
    StateStatus? status,
    CartEntity? cart,
    List<SavedPaymentMethodEntity>? savedPaymentMethods,
    PaymentMethodType? selectedPaymentMethod,
    String? selectedSavedMethodId,
    OrderEntity? order,
    Failure? failure,
    bool? isProcessing,
    bool clearSavedMethodId = false,
  }) {
    return CheckoutState(
      status: status ?? this.status,
      cart: cart ?? this.cart,
      savedPaymentMethods: savedPaymentMethods ?? this.savedPaymentMethods,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
      selectedSavedMethodId: clearSavedMethodId
          ? null
          : (selectedSavedMethodId ?? this.selectedSavedMethodId),
      order: order ?? this.order,
      failure: failure,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }

  @override
  List<Object?> get props => [
        status,
        cart,
        savedPaymentMethods,
        selectedPaymentMethod,
        selectedSavedMethodId,
        order,
        failure,
        isProcessing,
      ];
}
