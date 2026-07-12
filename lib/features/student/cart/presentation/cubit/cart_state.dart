import 'package:equatable/equatable.dart';
import 'package:lms_platform/core/base/base_state.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/features/student/cart/domain/entities/cart_entity.dart';
import 'package:lms_platform/features/student/cart/domain/entities/cart_item_entity.dart';
import 'package:lms_platform/features/student/cart/domain/entities/coupon_entity.dart';

/// Cart State
class CartState extends Equatable {
  final StateStatus status;
  final CartEntity? cart;
  final List<CartItemEntity> recommendedCourses;
  final Failure? failure;
  final bool isRemovingItem;
  final String? removingItemId;
  final String? removeItemError;
  final bool isApplyingCoupon;
  final String? couponError;
  final bool isAddingToCart;
  final String? addToCartError;

  const CartState({
    this.status = StateStatus.initial,
    this.cart,
    this.recommendedCourses = const [],
    this.failure,
    this.isRemovingItem = false,
    this.removingItemId,
    this.removeItemError,
    this.isApplyingCoupon = false,
    this.couponError,
    this.isAddingToCart = false,
    this.addToCartError,
  });

  bool get isLoading => status == StateStatus.loading;
  bool get isSuccess => status == StateStatus.success;
  bool get isError => status == StateStatus.error;
  String? get errorMessage => failure?.message;

  bool get isEmpty => cart?.isEmpty ?? true;
  int get itemsCount => cart?.itemsCount ?? 0;
  double get subtotal => cart?.subtotal ?? 0;
  double get total => cart?.total ?? 0;
  double get discountAmount => cart?.discountAmount ?? 0;
  CouponEntity? get appliedCoupon => cart?.appliedCoupon;
  bool get hasCoupon => appliedCoupon != null;

  CartState copyWith({
    StateStatus? status,
    CartEntity? cart,
    List<CartItemEntity>? recommendedCourses,
    Failure? failure,
    bool? isRemovingItem,
    String? removingItemId,
    String? removeItemError,
    bool? isApplyingCoupon,
    String? couponError,
    bool? isAddingToCart,
    String? addToCartError,
    bool clearCouponError = false,
    bool clearAddToCartError = false,
    bool clearRemoveItemError = false,
  }) {
    return CartState(
      status: status ?? this.status,
      cart: cart ?? this.cart,
      recommendedCourses: recommendedCourses ?? this.recommendedCourses,
      failure: failure,
      isRemovingItem: isRemovingItem ?? this.isRemovingItem,
      removingItemId: removingItemId ?? this.removingItemId,
      removeItemError: clearRemoveItemError
          ? null
          : (removeItemError ?? this.removeItemError),
      isApplyingCoupon: isApplyingCoupon ?? this.isApplyingCoupon,
      couponError: clearCouponError ? null : (couponError ?? this.couponError),
      isAddingToCart: isAddingToCart ?? this.isAddingToCart,
      addToCartError:
          clearAddToCartError ? null : (addToCartError ?? this.addToCartError),
    );
  }

  @override
  List<Object?> get props => [
        status,
        cart,
        recommendedCourses,
        failure,
        isRemovingItem,
        removingItemId,
        removeItemError,
        isApplyingCoupon,
        couponError,
        isAddingToCart,
        addToCartError,
      ];
}
