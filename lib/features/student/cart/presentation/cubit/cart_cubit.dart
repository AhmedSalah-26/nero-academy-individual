import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_platform/core/base/base_state.dart';
import 'package:lms_platform/core/models/course_commerce_models.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/features/student/cart/domain/entities/cart_entity.dart';
import 'package:lms_platform/features/student/cart/domain/entities/cart_item_entity.dart';
import 'package:lms_platform/features/student/cart/domain/usecases/get_cart_usecase.dart';
import 'package:lms_platform/features/student/cart/domain/usecases/add_to_cart_usecase.dart';
import 'package:lms_platform/features/student/cart/domain/usecases/remove_from_cart_usecase.dart';
import 'package:lms_platform/features/student/cart/domain/usecases/apply_coupon_usecase.dart';
import 'package:lms_platform/features/student/cart/domain/usecases/remove_coupon_usecase.dart';
import 'package:lms_platform/features/student/cart/domain/repositories/cart_repository.dart';
import 'cart_state.dart';

/// Cart Cubit - Singleton to share cart state across screens
class CartCubit extends Cubit<CartState> {
  final GetCartUseCase getCartUseCase;
  final AddToCartUseCase addToCartUseCase;
  final RemoveFromCartUseCase removeFromCartUseCase;
  final ApplyCouponUseCase applyCouponUseCase;
  final RemoveCouponUseCase removeCouponUseCase;
  final CartRepository cartRepository;

  CartCubit({
    required this.getCartUseCase,
    required this.addToCartUseCase,
    required this.removeFromCartUseCase,
    required this.applyCouponUseCase,
    required this.removeCouponUseCase,
    required this.cartRepository,
  }) : super(const CartState());

  String? _currentUserId;

  /// Get current user ID
  String? get currentUserId => _currentUserId;

  /// Set user ID without loading cart (for quick add to cart)
  void setUserId(String userId) {
    AppLogger.i('🛒 [CartCubit] Setting userId: $userId');
    _currentUserId = userId;
  }

  /// Load cart
  Future<void> loadCart(String userId) async {
    AppLogger.i('🛒 [CartCubit] Loading cart for user: $userId');
    _currentUserId = userId;

    // Load directly without shimmer - show result immediately
    final result = await getCartUseCase(GetCartParams(userId: userId));

    result.fold(
      (failure) {
        AppLogger.e('[CartCubit] Failed to load cart: ${failure.message}');
        emit(state.copyWith(
          status: StateStatus.error,
          failure: failure,
        ));
      },
      (cart) {
        AppLogger.success('[CartCubit] Cart loaded: ${cart.itemsCount} items');
        emit(state.copyWith(
          status: StateStatus.success,
          cart: cart,
        ));
        // Load recommended courses
        _loadRecommendedCourses(userId);
      },
    );
  }

  /// Load recommended courses for upsell
  Future<void> _loadRecommendedCourses(String userId) async {
    final result = await cartRepository.getRecommendedCourses(
      userId: userId,
      limit: 5,
    );

    result.fold(
      (_) {}, // Ignore errors for recommendations
      (courses) => emit(state.copyWith(recommendedCourses: courses)),
    );
  }

  /// Add course to cart with optimistic update
  Future<bool> addToCart(
    String courseId, {
    CoursePricingOption? pricingOption,
  }) async {
    AppLogger.i(
        '🛒 [CartCubit] Adding to cart - courseId: $courseId, userId: $_currentUserId');

    if (_currentUserId == null) {
      AppLogger.e('[CartCubit] Cannot add to cart: userId is null!');
      return false;
    }

    // Check if already in cart
    if (isInCart(courseId)) {
      AppLogger.w('[CartCubit] Course already in cart');
      return true;
    }

    emit(state.copyWith(isAddingToCart: true, clearAddToCartError: true));

    final result = await addToCartUseCase(
      AddToCartParams(
        userId: _currentUserId!,
        courseId: courseId,
        pricingOption: pricingOption,
      ),
    );

    return result.fold(
      (failure) {
        AppLogger.e('[CartCubit] Failed to add to cart: ${failure.message}');
        emit(state.copyWith(
          isAddingToCart: false,
          addToCartError: failure.message,
        ));
        return false;
      },
      (item) {
        AppLogger.success('[CartCubit] Added to cart successfully: ${item.id}');
        // Add item to cart locally
        final List<CartItemEntity> updatedItems = [
          ...(state.cart?.items ?? <CartItemEntity>[]),
          item,
        ];
        final updatedCart = CartEntity(
          id: state.cart?.id ?? _currentUserId!,
          userId: _currentUserId!,
          items: updatedItems,
          appliedCoupon: state.cart?.appliedCoupon,
        );
        emit(state.copyWith(
          cart: updatedCart,
          isAddingToCart: false,
        ));
        AppLogger.i('[CartCubit] Cart now has ${updatedCart.itemsCount} items');
        return true;
      },
    );
  }

  /// Remove item from cart
  Future<void> removeFromCart(String cartItemId) async {
    if (_currentUserId == null) return;
    emit(state.copyWith(
      isRemovingItem: true,
      removingItemId: cartItemId,
      clearRemoveItemError: true,
    ));

    final result = await removeFromCartUseCase(
      RemoveFromCartParams(userId: _currentUserId!, cartItemId: cartItemId),
    );

    result.fold(
      (failure) {
        AppLogger.e(
            '[CartCubit] Failed to remove item from cart: ${failure.message}');
        emit(state.copyWith(
          isRemovingItem: false,
          removingItemId: null,
          removeItemError: failure.message,
        ));
      },
      (_) {
        // Remove item locally
        final updatedItems =
            state.cart?.items.where((item) => item.id != cartItemId).toList() ??
                [];
        final updatedCart = CartEntity(
          id: state.cart?.id ?? _currentUserId!,
          userId: _currentUserId!,
          items: updatedItems,
          appliedCoupon: state.cart?.appliedCoupon,
        );
        emit(state.copyWith(
          cart: updatedCart,
          isRemovingItem: false,
          removingItemId: null,
        ));
      },
    );
  }

  /// Apply coupon
  Future<void> applyCoupon(String couponCode) async {
    if (_currentUserId == null) return;
    emit(state.copyWith(isApplyingCoupon: true, clearCouponError: true));

    final result = await applyCouponUseCase(
      ApplyCouponParams(userId: _currentUserId!, couponCode: couponCode),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isApplyingCoupon: false,
        couponError: failure.message,
      )),
      (coupon) {
        final updatedCart = CartEntity(
          id: state.cart?.id ?? _currentUserId!,
          userId: _currentUserId!,
          items: state.cart?.items ?? [],
          appliedCoupon: coupon,
        );
        emit(state.copyWith(
          cart: updatedCart,
          isApplyingCoupon: false,
        ));
      },
    );
  }

  /// Remove coupon
  Future<void> removeCoupon() async {
    if (_currentUserId == null) return;

    final result = await removeCouponUseCase(
      RemoveCouponParams(userId: _currentUserId!),
    );

    result.fold(
      (_) {}, // Ignore errors
      (_) {
        final updatedCart = CartEntity(
          id: state.cart?.id ?? _currentUserId!,
          userId: _currentUserId!,
          items: state.cart?.items ?? [],
          appliedCoupon: null,
        );
        emit(state.copyWith(cart: updatedCart));
      },
    );
  }

  /// Clear all items from cart
  Future<void> clearCart() async {
    if (_currentUserId == null) return;

    AppLogger.i('🛒 [CartCubit] Clearing cart for user: $_currentUserId');
    // Don't show loading state when clearing - just clear items directly

    final result = await cartRepository.clearCart(_currentUserId!);

    result.fold(
      (failure) {
        AppLogger.e('[CartCubit] Failed to clear cart: ${failure.message}');
        emit(state.copyWith(
          status: StateStatus.error,
          failure: failure,
        ));
      },
      (_) {
        AppLogger.success('[CartCubit] Cart cleared successfully');
        final emptyCart = CartEntity(
          id: state.cart?.id ?? _currentUserId!,
          userId: _currentUserId!,
          items: const [],
          appliedCoupon: null,
        );
        emit(state.copyWith(
          status: StateStatus.success,
          cart: emptyCart,
        ));
      },
    );
  }

  /// Check if course is in cart
  bool isInCart(String courseId) {
    final result = state.cart?.containsCourse(courseId) ?? false;
    AppLogger.i('🛒 [CartCubit] isInCart($courseId) = $result');
    if (state.cart != null) {
      AppLogger.i(
          '🛒 [CartCubit] Cart items courseIds: ${state.cart!.items.map((e) => e.courseId).toList()}');
    }
    return result;
  }

  /// Clear coupon error
  void clearCouponError() {
    emit(state.copyWith(clearCouponError: true));
  }
}
