import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/cart_entity.dart';
import '../entities/cart_item_entity.dart';
import '../entities/coupon_entity.dart';
import '../../../../core/models/course_commerce_models.dart';
import '../entities/order_entity.dart';
import '../entities/payment_method_entity.dart';

/// Cart Repository - Abstract Contract
abstract class CartRepository {
  /// Get user's cart
  Future<Either<Failure, CartEntity>> getCart(String userId);

  /// Add course to cart
  Future<Either<Failure, CartItemEntity>> addToCart({
    required String userId,
    required String courseId,
    CoursePricingOption? pricingOption,
  });

  /// Remove item from cart
  Future<Either<Failure, void>> removeFromCart({
    required String userId,
    required String cartItemId,
  });

  /// Clear all items from cart
  Future<Either<Failure, void>> clearCart(String userId);

  /// Apply coupon to cart
  Future<Either<Failure, CouponEntity>> applyCoupon({
    required String userId,
    required String couponCode,
  });

  /// Remove coupon from cart
  Future<Either<Failure, void>> removeCoupon(String userId);

  /// Validate coupon
  Future<Either<Failure, CouponEntity>> validateCoupon(String couponCode);

  /// Get saved payment methods
  Future<Either<Failure, List<SavedPaymentMethodEntity>>>
      getSavedPaymentMethods(
    String userId,
  );

  /// Process checkout
  Future<Either<Failure, OrderEntity>> checkout({
    required String userId,
    required PaymentMethodType paymentMethod,
    String? savedPaymentMethodId,
    Map<String, dynamic>? cardDetails,
    String? couponId,
    String? couponCode,
    double couponDiscountTotal = 0,
  });

  /// Get recommended courses for upsell
  Future<Either<Failure, List<CartItemEntity>>> getRecommendedCourses({
    required String userId,
    int limit = 5,
  });

  /// Get cart count (quick check)
  Future<Either<Failure, int>> getCartCount(String userId);
}
